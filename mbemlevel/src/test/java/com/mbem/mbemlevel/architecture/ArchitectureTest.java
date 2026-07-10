package com.mbem.mbemlevel.architecture;
import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.lang.ArchRule;
import org.junit.jupiter.api.Test;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.*;
import static com.tngtech.archunit.library.Architectures.layeredArchitecture;
/**
 * Tests d'architecture ArchUnit — valident le respect de l'architecture hexagonale.
 * Exécutés à chaque build : mvn test -Dtest=ArchitectureTest
 *
 * RÈGLES VÉRIFIÉES :
 *   1. La couche Domain ne dépend d'aucune couche externe (Spring, JPA, etc.)
 *   2. Les Controllers ne parlent pas directement aux Repositories JPA
 *   3. Les Entités JPA ne sont pas dans le package domain
 */
class ArchitectureTest {

    private static final JavaClasses CLASSES = new ClassFileImporter()
        .withImportOption(ImportOption.Predefined.DO_NOT_INCLUDE_TESTS)
        .importPackages("com.mbem.mbemlevel");

    @Test
    void domainNeDependPasDeSpring() {
        ArchRule rule = noClasses()
            .that().resideInAPackage("..domain..")
            .should().dependOnClassesThat()
                .resideInAnyPackage(
                    "org.springframework..",
                    "jakarta.persistence..",
                    "com.mbem.mbemlevel.infrastructure..",
                    "com.mbem.mbemlevel.api..")
            .because("La couche Domain doit être indépendante de tout framework");
        rule.check(CLASSES);
    }

    @Test
    void controllersNeParlentPasDirectementAuxRepositoriesJpa() {
        ArchRule rule = noClasses()
            .that().resideInAPackage("..api.controller..")
            .should().dependOnClassesThat()
                .resideInAPackage("..infrastructure.persistence.repository..")
            .because("Les Controllers passent par les Use Cases — jamais directement aux JPA Repos");
        rule.check(CLASSES);
    }

    @Test
    void entitesJpaNeSontPasDansLeDomain() {
        ArchRule rule = noClasses()
            .that().resideInAPackage("..domain..")
            .should().beAnnotatedWith("jakarta.persistence.Entity")
            .because("Le Domain ne doit pas contenir d'entités JPA");
        rule.check(CLASSES);
    }

    @Test
    void architectureHexagonale() {
        layeredArchitecture().consideringOnlyDependenciesInLayers()
            .layer("API").definedBy("..api..")
            .layer("Application").definedBy("..application..")
            .layer("Domain").definedBy("..domain..")
            .layer("Infrastructure").definedBy("..infrastructure..")
            .whereLayer("Domain").mayNotAccessAnyLayer()
            .whereLayer("Application").mayOnlyAccessLayers("Domain", "Infrastructure", "API")
            .whereLayer("API").mayOnlyAccessLayers("Application", "Domain", "Infrastructure")
            .check(CLASSES);
    }
}
