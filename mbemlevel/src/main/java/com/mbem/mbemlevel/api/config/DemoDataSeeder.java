package com.mbem.mbemlevel.api.config;

import com.mbem.mbemlevel.domain.shared.enums.*;
import com.mbem.mbemlevel.domain.cours.TypeBloc;
import com.mbem.mbemlevel.infrastructure.persistence.entity.*;
import com.mbem.mbemlevel.infrastructure.persistence.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

@Component
@RequiredArgsConstructor
@Slf4j
public class DemoDataSeeder implements CommandLineRunner {

    private final UtilisateurJpaRepository userRepo;
    private final CoursJpaRepository coursRepo;
    private final LeconJpaRepository leconRepo;
    private final BlocContenuJpaRepository blocRepo;
    private final QCMJpaRepository qcmRepo;
    private final ProgressionJpaRepository progressionRepo;
    private final PaiementJpaRepository paiementRepo;
    private final TrancheJpaRepository trancheRepo;
    private final MoratoireJpaRepository moratoireRepo;
    private final XpHistoriqueJpaRepository xpHistoriqueRepo;
    private final PasswordEncoder passwordEncoder;

    @Override
    @Transactional
    public void run(String... args) throws Exception {
        UUID f1Id = UUID.fromString("f1f1f1f1-f1f1-f1f1-f1f1-f1f1f1f1f1f1");
        if (userRepo.existsById(f1Id)) {
            log.info("[SEEDER] Les données de démonstration SmartLearn existent déjà. Initialisation ignorée.");
            return;
        }

        log.info("[SEEDER] Début de la génération des données de démonstration SmartLearn...");

        String defaultHashedPassword = passwordEncoder.encode("Demo@123");

        // 1. Création des 2 Formateurs
        UtilisateurJpaEntity formateur1 = UtilisateurJpaEntity.builder()
            .id(f1Id)
            .prenom("Alexandre")
            .nom("Gomez")
            .email("formateur.dev@mbemnova.com")
            .motDePasseHache(defaultHashedPassword)
            .emailVerifie(true)
            .role(Role.FORMATEUR)
            .statut(StatutApprenant.ACTIF)
            .tentativesEchouees(0)
            .xpTotal(0)
            .streakJours(0)
            .disponiblePourEmploi(false)
            .specialite("Développement Web & Mobile")
            .biographie("Ingénieur logiciel avec 10 ans d'expérience dans les architectures web modernes et mobiles (Angular, React, Node.js, Flutter).")
            .noteGlobale(new BigDecimal("4.8"))
            .createdAt(LocalDateTime.now())
            .updatedAt(LocalDateTime.now())
            .build();

        UUID f2Id = UUID.fromString("f2f2f2f2-f2f2-f2f2-f2f2-f2f2f2f2f2f2");
        UtilisateurJpaEntity formateur2 = UtilisateurJpaEntity.builder()
            .id(f2Id)
            .prenom("Sophie")
            .nom("Martin")
            .email("formateur.design@mbemnova.com")
            .motDePasseHache(defaultHashedPassword)
            .emailVerifie(true)
            .role(Role.FORMATEUR)
            .statut(StatutApprenant.ACTIF)
            .tentativesEchouees(0)
            .xpTotal(0)
            .streakJours(0)
            .disponiblePourEmploi(false)
            .specialite("Design UI/UX & Produit")
            .biographie("Designer produit et UI/UX passionnée, experte en design systems, Figma et en méthodologies de recherche utilisateur.")
            .noteGlobale(new BigDecimal("4.9"))
            .createdAt(LocalDateTime.now())
            .updatedAt(LocalDateTime.now())
            .build();

        userRepo.save(formateur1);
        userRepo.save(formateur2);

        // Catégories existantes
        UUID catBureautique = UUID.fromString("11111111-1111-1111-1111-111111111111");
        UUID catDataIA = UUID.fromString("22222222-2222-2222-2222-222222222222");
        UUID catDesign = UUID.fromString("33333333-3333-3333-3333-333333333333");
        UUID catDev = UUID.fromString("44444444-4444-4444-4444-444444444444");
        UUID catMarketing = UUID.fromString("55555555-5555-5555-5555-555555555555");
        UUID catReseau = UUID.fromString("66666666-6666-6666-6666-666666666666");

        // 2. Création des formations
        List<CoursJpaEntity> courses = new ArrayList<>();
        
        // Formateur 1 Courses
        UUID c1Id = UUID.fromString("c1c1c1c1-c1c1-c1c1-c1c1-c1c1c1c1c1c1");
        courses.add(createCourse(c1Id, "Angular Moderne & RxJS", "Maîtriser Angular de A à Z avec les Signaux, RxJS et les dernières fonctionnalités.", 
            "Découvrez la puissance d'Angular pour concevoir des applications web hautement interactives, réactives et performantes.", NiveauCours.AVANCE, catDev, f1Id, "angular-moderne-rxjs", 15000, 0.3));

        UUID c2Id = UUID.fromString("c2c2c2c2-c2c2-c2c2-c2c2-c2c2c2c2c2c2");
        courses.add(createCourse(c2Id, "Développement Mobile avec Flutter", "Créez des applications natives iOS et Android à partir d'une seule base de code.",
            "Découvrez le SDK Flutter et le langage Dart pour concevoir des applications mobiles esthétiques et fluides.", NiveauCours.INTERMEDIAIRE, catDev, f1Id, "developpement-mobile-flutter", 20000, 0.25));

        UUID c3Id = UUID.fromString("c3c3c3c3-c3c3-c3c3-c3c3-c3c3c3c3c3c3");
        courses.add(createCourse(c3Id, "IA Générative et Python pour la Data", "Introduction pratique à l'analyse de données et à l'intégration d'API d'IA générative.",
            "Apprenez à manipuler les données avec Pandas et NumPy, puis intégrez des grands modèles de langage (LLM) dans vos programmes.", NiveauCours.DEBUTANT, catDataIA, f1Id, "ia-generative-python-data", 0, 1.0)); // 100% Free

        UUID c4Id = UUID.fromString("c4c4c4c4-c4c4-c4c4-c4c4-c4c4c4c4c4c4");
        courses.add(createCourse(c4Id, "Excel Avancé pour Analystes Financiers", "Optimisez vos modélisations financières grâce aux fonctions complexes et macros.",
            "Devenez un expert d'Excel en apprenant à manipuler les données financières complexes avec les meilleures pratiques de calcul.", NiveauCours.AVANCE, catBureautique, f1Id, "excel-analystes-financiers", 10000, 0.3));

        UUID c5Id = UUID.fromString("c5c5c5c5-c5c5-c5c5-c5c5-c5c5c5c5c5c5");
        courses.add(createCourse(c5Id, "Fondations de la Cybersécurité", "Comprendre et sécuriser les réseaux face aux menaces modernes.",
            "Apprenez les bases de la sécurité informatique, de la protection des infrastructures à la prévention des vulnérabilités web.", NiveauCours.DEBUTANT, catReseau, f1Id, "fondations-cybersecurite", 25000, 0.2));

        // Formateur 2 Courses
        UUID c6Id = UUID.fromString("c6c6c6c6-c6c6-c6c6-c6c6-c6c6c6c6c6c6");
        courses.add(createCourse(c6Id, "Créer un Design System avec Figma", "Concevez des composants réutilisables, scalables et des architectures UI cohérentes.",
            "Maîtrisez les concepts fondamentaux des Design Systems sous Figma : variables, auto layout avancés et composants interactifs.", NiveauCours.AVANCE, catDesign, f2Id, "creer-design-system-figma", 18000, 0.3));

        UUID c7Id = UUID.fromString("c7c7c7c7-c7c7-c7c7-c7c7-c7c7c7c7c7c7");
        courses.add(createCourse(c7Id, "Design UI/UX pour Débutants", "Les principes fondamentaux de l'expérience utilisateur et de l'interface.",
            "Découvrez la différence entre UI et UX, concevez des wireframes, et apprenez à structurer des interfaces conviviales.", NiveauCours.DEBUTANT, catDesign, f2Id, "design-uiux-debutants", 12000, 0.4));

        UUID c8Id = UUID.fromString("c8c8c8c8-c8c8-c8c8-c8c8-c8c8c8c8c8c8");
        courses.add(createCourse(c8Id, "Stratégie de Marketing Digital Moderne", "Développez votre visibilité en ligne grâce au SEO et aux campagnes publicitaires payantes.",
            "Découvrez comment planifier, exécuter et analyser des campagnes de marketing digital impactantes sur Google et les réseaux sociaux.", NiveauCours.INTERMEDIAIRE, catMarketing, f2Id, "strategie-marketing-digital", 15000, 0.3));

        UUID c9Id = UUID.fromString("c9c9c9c9-c9c9-c9c9-c9c9-c9c9c9c9c9c9");
        courses.add(createCourse(c9Id, "Community Management et Réseaux Sociaux", "Animez et développez des communautés engagées en ligne.",
            "Devenez un as des réseaux sociaux en apprenant à élaborer des calendriers éditoriaux, créer du contenu interactif et gérer les crises.", NiveauCours.DEBUTANT, catMarketing, f2Id, "community-management-reseaux", 0, 1.0)); // 100% Free

        UUID c10Id = UUID.fromString("c10c10c1-10c1-10c1-10c1-10c10c10c10c");
        courses.add(createCourse(c10Id, "Outils Collaboratifs pour Équipes Hybrides", "Maîtriser Slack, Teams, Miro et Notion pour maximiser la productivité collective.",
            "Apprenez à configurer et optimiser vos espaces collaboratifs virtuels pour faciliter la communication et la gestion de projets à distance.", NiveauCours.INTERMEDIAIRE, catBureautique, f2Id, "outils-collaboratifs-equipes", 8000, 0.5));

        coursRepo.saveAll(courses);

        // 3. Génération des Leçons & Contenus Riches (3 par cours)
        List<LeconJpaEntity> lecons = new ArrayList<>();
        List<BlocContenuJpaEntity> blocs = new ArrayList<>();
        List<QCMJpaEntity> qcms = new ArrayList<>();

        // Map to keep track of lesson UUIDs for progression references
        Map<String, List<UUID>> courseToLessonsMap = new HashMap<>();

        for (CoursJpaEntity c : courses) {
            List<UUID> lIds = new ArrayList<>();
            for (int i = 1; i <= 3; i++) {
                UUID lId = UUID.randomUUID();
                lIds.add(lId);
                boolean estPreview = (i == 1 || (i == 2 && c.getSeuilPaiement().doubleValue() >= 0.4));
                
                String titreLecon = getTitreLeconCoherent(c.getTitre(), i);
                String descLecon = "Dans cette leçon, nous allons aborder la partie " + i + " de notre formation \"" + c.getTitre() + "\".";
                
                LeconJpaEntity lecon = LeconJpaEntity.builder()
                    .id(lId)
                    .coursId(c.getId())
                    .titre(titreLecon)
                    .descriptionCourte(descLecon)
                    .ordre(i)
                    .dureeMinutes(15 + i * 5)
                    .xpValeur(50)
                    .estPreview(estPreview)
                    .aQCM(i == 1) // On crée un QCM sur la leçon 1 de chaque cours
                    .createdAt(LocalDateTime.now())
                    .updatedAt(LocalDateTime.now())
                    .build();

                lecons.add(lecon);

                // Bloc de contenu riche
                String richHtml = getRichHtmlPedagogique(c.getTitre(), titreLecon, i);
                BlocContenuJpaEntity bloc = BlocContenuJpaEntity.builder()
                    .id(UUID.randomUUID())
                    .leconId(lId)
                    .typeBloc(TypeBloc.TEXTE_HTML)
                    .ordre(1)
                    .contenuHtml(richHtml)
                    .createdAt(LocalDateTime.now())
                    .updatedAt(LocalDateTime.now())
                    .build();
                
                blocs.add(bloc);

                // QCM (seulement sur la 1ère leçon pour tester)
                if (i == 1) {
                    QCMJpaEntity qcm = createQcmForLesson(lId, c.getTitre());
                    qcms.add(qcm);
                }
            }
            courseToLessonsMap.put(c.getId().toString(), lIds);
        }

        leconRepo.saveAll(lecons);
        blocRepo.saveAll(blocs);
        qcmRepo.saveAll(qcms);


        // 4. Création des 2 Apprenants
        UUID a1Id = UUID.fromString("a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1");
        UtilisateurJpaEntity apprenant1 = UtilisateurJpaEntity.builder()
            .id(a1Id)
            .prenom("Jean")
            .nom("Dupont")
            .email("apprenant.jean@mbemnova.com")
            .motDePasseHache(defaultHashedPassword)
            .emailVerifie(true)
            .role(Role.APPRENANT)
            .statut(StatutApprenant.ACTIF)
            .tentativesEchouees(0)
            .xpTotal(550) // Somme des XP gagnés ci-dessous
            .streakJours(3)
            .disponiblePourEmploi(true)
            .createdAt(LocalDateTime.now())
            .updatedAt(LocalDateTime.now())
            .build();

        UUID a2Id = UUID.fromString("a2a2a2a2-a2a2-a2a2-a2a2-a2a2a2a2a2a2");
        UtilisateurJpaEntity apprenant2 = UtilisateurJpaEntity.builder()
            .id(a2Id)
            .prenom("Marie")
            .nom("Curie")
            .email("apprenant.marie@mbemnova.com")
            .motDePasseHache(defaultHashedPassword)
            .emailVerifie(true)
            .role(Role.APPRENANT)
            .statut(StatutApprenant.ACTIF)
            .tentativesEchouees(0)
            .xpTotal(400) // Somme des XP gagnés ci-dessous
            .streakJours(5)
            .disponiblePourEmploi(false)
            .createdAt(LocalDateTime.now())
            .updatedAt(LocalDateTime.now())
            .build();

        userRepo.save(apprenant1);
        userRepo.save(apprenant2);


        // 5. Inscriptions, Progressions & Paiements pour APPRENANT 1 (Jean Dupont)
        // Formation 1: "Angular Moderne & RxJS" -> Commencée, Payée (accès total), Progression 66.7%
        List<UUID> c1Lessons = courseToLessonsMap.get(c1Id.toString());
        ProgressionJpaEntity p1 = ProgressionJpaEntity.builder()
            .id(UUID.randomUUID())
            .apprenantId(a1Id)
            .coursId(c1Id)
            .pourcentage(66.7)
            .estPaye(true)
            .xpGagne(100) // 2 leçons complétées (2 * 50 XP)
            .dateDebut(LocalDateTime.now().minusDays(5))
            .seuilPaiementCours(0.3)
            .leconsTerminees(c1Lessons.get(0).toString() + "," + c1Lessons.get(1).toString())
            .createdAt(LocalDateTime.now())
            .updatedAt(LocalDateTime.now())
            .build();
        progressionRepo.save(p1);

        PaiementJpaEntity pay1 = PaiementJpaEntity.builder()
            .id(UUID.randomUUID())
            .apprenantId(a1Id)
            .coursId(c1Id)
            .montantTotal(15000)
            .montantPaye(15000)
            .modePaiement(ModePaiement.CASH)
            .statut(StatutPaiement.PAYE)
            .accesActive(true)
            .dateActivation(LocalDateTime.now().minusDays(4))
            .createdAt(LocalDateTime.now().minusDays(4))
            .updatedAt(LocalDateTime.now().minusDays(4))
            .build();
        paiementRepo.save(pay1);

        // Formation 3: "IA Générative et Python pour la Data" -> Terminée (100%), Gratuite
        List<UUID> c3Lessons = courseToLessonsMap.get(c3Id.toString());
        ProgressionJpaEntity p2 = ProgressionJpaEntity.builder()
            .id(UUID.randomUUID())
            .apprenantId(a1Id)
            .coursId(c3Id)
            .pourcentage(100.0)
            .estPaye(true)
            .xpGagne(350) // 3 leçons (150 XP) + 200 XP bonus fin de formation
            .dateDebut(LocalDateTime.now().minusDays(10))
            .dateCompletion(LocalDateTime.now().minusDays(2))
            .seuilPaiementCours(1.0)
            .leconsTerminees(c3Lessons.get(0).toString() + "," + c3Lessons.get(1).toString() + "," + c3Lessons.get(2).toString())
            .createdAt(LocalDateTime.now())
            .updatedAt(LocalDateTime.now())
            .build();
        progressionRepo.save(p2);

        // Formation 4: "Excel Avancé pour Analystes Financiers" -> Commencée, non payée (seuil atteint), Progression 33.3%, en moratoire
        List<UUID> c4Lessons = courseToLessonsMap.get(c4Id.toString());
        ProgressionJpaEntity p3 = ProgressionJpaEntity.builder()
            .id(UUID.randomUUID())
            .apprenantId(a1Id)
            .coursId(c4Id)
            .pourcentage(33.3)
            .estPaye(false)
            .xpGagne(50) // 1 leçon complétée (50 XP)
            .dateDebut(LocalDateTime.now().minusDays(15))
            .seuilPaiementCours(0.3)
            .leconsTerminees(c4Lessons.get(0).toString())
            .createdAt(LocalDateTime.now())
            .updatedAt(LocalDateTime.now())
            .build();
        progressionRepo.save(p3);

        PaiementJpaEntity pay3 = PaiementJpaEntity.builder()
            .id(UUID.randomUUID())
            .apprenantId(a1Id)
            .coursId(c4Id)
            .montantTotal(10000)
            .montantPaye(3000)
            .modePaiement(ModePaiement.CASH)
            .statut(StatutPaiement.EN_ATTENTE)
            .accesActive(false)
            .createdAt(LocalDateTime.now().minusDays(15))
            .updatedAt(LocalDateTime.now().minusDays(15))
            .build();
        paiementRepo.save(pay3);

        // Tranches de paiement pour Excel (Plan de paiement échelonné)
        TrancheJpaEntity t1_c4 = TrancheJpaEntity.builder()
            .id(UUID.randomUUID())
            .paiementId(pay3.getId())
            .numero(1)
            .montant(3000)
            .dateEcheance(LocalDate.now().minusDays(15))
            .dateReglement(LocalDate.now().minusDays(15))
            .statut(StatutPaiement.PAYE)
            .createdAt(LocalDateTime.now().minusDays(15))
            .updatedAt(LocalDateTime.now().minusDays(15))
            .build();
        
        TrancheJpaEntity t2_c4 = TrancheJpaEntity.builder()
            .id(UUID.randomUUID())
            .paiementId(pay3.getId())
            .numero(2)
            .montant(3500)
            .dateEcheance(LocalDate.now().plusDays(15))
            .statut(StatutPaiement.EN_ATTENTE)
            .createdAt(LocalDateTime.now().minusDays(15))
            .updatedAt(LocalDateTime.now().minusDays(15))
            .build();

        TrancheJpaEntity t3_c4 = TrancheJpaEntity.builder()
            .id(UUID.randomUUID())
            .paiementId(pay3.getId())
            .numero(3)
            .montant(3500)
            .dateEcheance(LocalDate.now().plusDays(45))
            .statut(StatutPaiement.EN_ATTENTE)
            .createdAt(LocalDateTime.now().minusDays(15))
            .updatedAt(LocalDateTime.now().minusDays(15))
            .build();
        
        trancheRepo.saveAll(List.of(t1_c4, t2_c4, t3_c4));

        // Moratoires pour Apprenant 1
        MoratoireJpaEntity mor1 = MoratoireJpaEntity.builder()
            .id(UUID.randomUUID())
            .paiementId(pay3.getId())
            .raison("Difficultés financières passagères en raison d'un retard de bourse d'études.")
            .nouvelleDate(LocalDate.now().plusDays(20))
            .nouvelleDateSouhaitee(LocalDate.now().plusDays(20))
            .nouvelleDateAccordee(LocalDate.now().plusDays(20))
            .statut("APPROUVE")
            .dateDecision(LocalDateTime.now().minusDays(5))
            .createdAt(LocalDateTime.now().minusDays(10))
            .updatedAt(LocalDateTime.now().minusDays(5))
            .build();

        MoratoireJpaEntity mor2 = MoratoireJpaEntity.builder()
            .id(UUID.randomUUID())
            .paiementId(pay3.getId())
            .raison("Attente d'un virement salaire de job étudiant.")
            .nouvelleDate(LocalDate.now().plusDays(10))
            .nouvelleDateSouhaitee(LocalDate.now().plusDays(10))
            .statut("EN_ATTENTE")
            .createdAt(LocalDateTime.now().minusDays(1))
            .updatedAt(LocalDateTime.now().minusDays(1))
            .build();

        moratoireRepo.save(mor1);
        moratoireRepo.save(mor2);

        // Historique des XP sur les 7 derniers jours pour APPRENANT 1 (Total: 550 XP)
        saveXpLog(a1Id, 50, 5);  // J-5 (Leçon 1 de IA)
        saveXpLog(a1Id, 50, 4);  // J-4 (Leçon 2 de IA)
        saveXpLog(a1Id, 50, 3);  // J-3 (Leçon 1 de Angular)
        saveXpLog(a1Id, 250, 2); // J-2 (Leçon 3 de IA + 200 XP Bonus Completion)
        saveXpLog(a1Id, 50, 1);  // J-1 (Leçon 2 de Angular)
        saveXpLog(a1Id, 100, 0); // Aujourd'hui (Leçon 1 de Excel + autre gain)


        // 6. Inscriptions, Progressions & Paiements pour APPRENANT 2 (Marie Curie)
        // Formation 6: "Créer un Design System avec Figma" -> Commencée, non payée, Progression 33.3%, moratoire refusé (en retard!)
        List<UUID> c6Lessons = courseToLessonsMap.get(c6Id.toString());
        ProgressionJpaEntity p4 = ProgressionJpaEntity.builder()
            .id(UUID.randomUUID())
            .apprenantId(a2Id)
            .coursId(c6Id)
            .pourcentage(33.3)
            .estPaye(false)
            .xpGagne(50) // 1 leçon complétée
            .dateDebut(LocalDateTime.now().minusDays(10))
            .seuilPaiementCours(0.3)
            .leconsTerminees(c6Lessons.get(0).toString())
            .createdAt(LocalDateTime.now())
            .updatedAt(LocalDateTime.now())
            .build();
        progressionRepo.save(p4);

        PaiementJpaEntity pay4 = PaiementJpaEntity.builder()
            .id(UUID.randomUUID())
            .apprenantId(a2Id)
            .coursId(c6Id)
            .montantTotal(18000)
            .montantPaye(6000)
            .modePaiement(ModePaiement.CASH)
            .statut(StatutPaiement.EN_RETARD)
            .accesActive(false)
            .createdAt(LocalDateTime.now().minusDays(10))
            .updatedAt(LocalDateTime.now().minusDays(1))
            .build();
        paiementRepo.save(pay4);

        // Tranches de paiement pour Figma
        TrancheJpaEntity t1_c6 = TrancheJpaEntity.builder()
            .id(UUID.randomUUID())
            .paiementId(pay4.getId())
            .numero(1)
            .montant(6000)
            .dateEcheance(LocalDate.now().minusDays(10))
            .dateReglement(LocalDate.now().minusDays(10))
            .statut(StatutPaiement.PAYE)
            .createdAt(LocalDateTime.now().minusDays(10))
            .updatedAt(LocalDateTime.now().minusDays(10))
            .build();

        TrancheJpaEntity t2_c6 = TrancheJpaEntity.builder()
            .id(UUID.randomUUID())
            .paiementId(pay4.getId())
            .numero(2)
            .montant(6000)
            .dateEcheance(LocalDate.now().minusDays(1))
            .statut(StatutPaiement.EN_RETARD)
            .createdAt(LocalDateTime.now().minusDays(10))
            .updatedAt(LocalDateTime.now().minusDays(1))
            .build();

        TrancheJpaEntity t3_c6 = TrancheJpaEntity.builder()
            .id(UUID.randomUUID())
            .paiementId(pay4.getId())
            .numero(3)
            .montant(6000)
            .dateEcheance(LocalDate.now().plusDays(20))
            .statut(StatutPaiement.EN_ATTENTE)
            .createdAt(LocalDateTime.now().minusDays(10))
            .updatedAt(LocalDateTime.now().minusDays(10))
            .build();
        
        trancheRepo.saveAll(List.of(t1_c6, t2_c6, t3_c6));

        // Moratoire refusé pour Marie
        MoratoireJpaEntity mor3 = MoratoireJpaEntity.builder()
            .id(UUID.randomUUID())
            .paiementId(pay4.getId())
            .raison("Demande de report de l'échéance de 30 jours.")
            .nouvelleDate(LocalDate.now().plusDays(30))
            .nouvelleDateSouhaitee(LocalDate.now().plusDays(30))
            .statut("REFUSE")
            .justificationRefus("Délai de report trop long (max 15 jours autorisés).")
            .dateDecision(LocalDateTime.now().minusDays(1))
            .createdAt(LocalDateTime.now().minusDays(2))
            .updatedAt(LocalDateTime.now().minusDays(1))
            .build();
        moratoireRepo.save(mor3);

        // Formation 7: "Design UI/UX pour Débutants" -> Terminée (100%), Payée, Progression 100%
        List<UUID> c7Lessons = courseToLessonsMap.get(c7Id.toString());
        ProgressionJpaEntity p5 = ProgressionJpaEntity.builder()
            .id(UUID.randomUUID())
            .apprenantId(a2Id)
            .coursId(c7Id)
            .pourcentage(100.0)
            .estPaye(true)
            .xpGagne(350) // 3 leçons complétées (150 XP) + 200 XP bonus completion
            .dateDebut(LocalDateTime.now().minusDays(8))
            .dateCompletion(LocalDateTime.now().minusDays(3))
            .seuilPaiementCours(0.4)
            .leconsTerminees(c7Lessons.get(0).toString() + "," + c7Lessons.get(1).toString() + "," + c7Lessons.get(2).toString())
            .createdAt(LocalDateTime.now())
            .updatedAt(LocalDateTime.now())
            .build();
        progressionRepo.save(p5);

        PaiementJpaEntity pay5 = PaiementJpaEntity.builder()
            .id(UUID.randomUUID())
            .apprenantId(a2Id)
            .coursId(c7Id)
            .montantTotal(12000)
            .montantPaye(12000)
            .modePaiement(ModePaiement.ONLINE)
            .statut(StatutPaiement.PAYE)
            .accesActive(true)
            .dateActivation(LocalDateTime.now().minusDays(6))
            .createdAt(LocalDateTime.now().minusDays(6))
            .updatedAt(LocalDateTime.now().minusDays(6))
            .build();
        paiementRepo.save(pay5);

        // Historique des XP sur les 7 derniers jours pour APPRENANT 2 (Total: 400 XP)
        saveXpLog(a2Id, 50, 6);  // J-6 (Leçon 1 de Design UI/UX)
        saveXpLog(a2Id, 50, 4);  // J-4 (Leçon 2 de Design UI/UX)
        saveXpLog(a2Id, 250, 3); // J-3 (Leçon 3 de Design UI/UX + 200 XP Bonus)
        saveXpLog(a2Id, 50, 2);  // J-2 (Leçon 1 de Figma)

        log.info("[SEEDER] Génération des données de démonstration terminée avec succès !");
        
        // Affichage console clair des accès
        log.info("--------------------------------------------------------------------------------");
        log.info("[DEMO ACCESS] Formateurs générés :");
        log.info("  1. Email: formateur.dev@mbemnova.com     | Mot de passe: Demo@123");
        log.info("  2. Email: formateur.design@mbemnova.com  | Mot de passe: Demo@123");
        log.info("[DEMO ACCESS] Apprenants générés :");
        log.info("  1. Email: apprenant.jean@mbemnova.com    | Mot de passe: Demo@123");
        log.info("  2. Email: apprenant.marie@mbemnova.com   | Mot de passe: Demo@123");
        log.info("--------------------------------------------------------------------------------");
    }

    private CoursJpaEntity createCourse(UUID id, String titre, String descCourte, String descLongue,
                                         NiveauCours niveau, UUID catId, UUID formateurId, String slug, 
                                         long prix, double seuil) {
        return CoursJpaEntity.builder()
            .id(id)
            .titre(titre)
            .descriptionCourte(descCourte)
            .descriptionLongue(descLongue)
            .niveau(niveau)
            .categorieId(catId)
            .formateurId(formateurId)
            .slug(slug)
            .imageCouverture("https://picsum.photos/seed/" + slug + "/800/450")
            .imageCouvertureThumbnail("https://picsum.photos/seed/" + slug + "/200/150")
            .langue("fr")
            .nbModules(1)
            .nbLecons(3)
            .dureeTotaleMinutes(60)
            .nbApprenants(12 + (int)(Math.random() * 50))
            .noteMoyenne(4.5 + (Math.random() * 0.5))
            .nbAvis(5 + (int)(Math.random() * 15))
            .seuilPaiement(BigDecimal.valueOf(seuil))
            .prixFcfa(prix)
            .statut("PUBLIE")
            .estActif(true)
            .createdAt(LocalDateTime.now())
            .updatedAt(LocalDateTime.now())
            .build();
    }

    private String getTitreLeconCoherent(String titreCours, int index) {
        if (titreCours.contains("Angular")) {
            if (index == 1) return "Introduction aux Signaux Angular";
            if (index == 2) return "Gestion d'état réactive avec RxJS";
            return "Optimisation du rendu avec OnPush";
        } else if (titreCours.contains("Flutter")) {
            if (index == 1) return "Introduction au langage Dart";
            if (index == 2) return "Widgets Stateless et Stateful";
            return "Gestion d'état globale avec Provider";
        } else if (titreCours.contains("IA Générative")) {
            if (index == 1) return "Manipulation de données avec Pandas";
            if (index == 2) return "Visualisation avec Matplotlib";
            return "Appels d'API OpenAI et LangChain";
        } else if (titreCours.contains("Excel")) {
            if (index == 1) return "Fonctions RECHERCHEV, INDEX et EQUIV";
            if (index == 2) return "Création de Tableaux Croisés Dynamiques";
            return "Automatisation avec VBA";
        } else if (titreCours.contains("Cybersécurité")) {
            if (index == 1) return "Sécurité des protocoles SSH et HTTPS";
            if (index == 2) return "Failles web courantes (OWASP Top 10)";
            return "Configuration de Pare-feu et VPN";
        } else if (titreCours.contains("Figma")) {
            if (index == 1) return "Composants, instances et variantes Figma";
            if (index == 2) return "Mise en page réactive avec Auto Layout";
            return "Variables et design tokens de couleur";
        } else if (titreCours.contains("Design UI/UX")) {
            if (index == 1) return "Fondements et différences UI vs UX";
            if (index == 2) return "Création de maquettes fil de fer (Wireframes)";
            return "Méthodologie des tests utilisateurs";
        } else if (titreCours.contains("Marketing")) {
            if (index == 1) return "SEO et référencement naturel";
            if (index == 2) return "Lancer des campagnes Google Ads";
            return "Analyse d'audience avec GA4";
        } else if (titreCours.contains("Community")) {
            if (index == 1) return "Établir un calendrier éditorial";
            if (index == 2) return "Techniques d'engagement de communauté";
            return "Gestion de crise sur les réseaux";
        } else {
            if (index == 1) return "Prendre en main Slack et MS Teams";
            if (index == 2) return "Organisation de projets Notion";
            return "Brainstorming virtuel avec Miro";
        }
    }

    private String getRichHtmlPedagogique(String titreCours, String titreLecon, int index) {
        return "<h3>Cours : " + titreCours + "</h3>" +
            "<h4>Leçon " + index + " : " + titreLecon + "</h4>" +
            "<p>Bienvenue dans cette leçon dédiée à l'apprentissage pratique. Nous allons aborder les concepts clés de manière structurée.</p>" +
            "<h5>1. Introduction aux fondamentaux</h5>" +
            "<p>Il est indispensable de maîtriser les bases théoriques avant de passer à la pratique. Les approches modernes privilégient l'apprentissage actif. Nous allons explorer les meilleures techniques recommandées par les experts du domaine.</p>" +
            "<h5>2. Exemple pratique pas-à-pas</h5>" +
            "<p>Considérons la mise en situation suivante pour illustrer notre propos. La mise en application directe permet de consolider l'acquisition des compétences.</p>" +
            "<pre><code>// Exemple d'illustration\n" +
            "const data = { status: 'success', value: 42 };\n" +
            "console.log('Concept validé !', data);\n" +
            "</code></pre>" +
            "<h5>3. Résumé de la session</h5>" +
            "<p>En conclusion, retenez que ce module constitue le socle indispensable pour la suite de votre parcours. Prenez le temps de relire et de vous exercer régulièrement.</p>";
    }

    private QCMJpaEntity createQcmForLesson(UUID leconId, String titreCours) {
        String question;
        String optionsJson;
        String bonneReponse;
        String explication;

        if (titreCours.contains("Angular")) {
            question = "Quel nouvel outil réactif a été introduit en Angular 16 ?";
            optionsJson = "[{\"id\":\"A\",\"texte\":\"Les Observables\"},{\"id\":\"B\",\"texte\":\"Les Signaux\"},{\"id\":\"C\",\"texte\":\"Les Promises\"},{\"id\":\"D\",\"texte\":\"Les NgModules\"}]";
            bonneReponse = "B";
            explication = "Les signaux introduisent une réactivité fine en Angular sans passer par RxJS ou Zone.js pour la détection.";
        } else if (titreCours.contains("Flutter")) {
            question = "Quel est le langage de programmation principal de Flutter ?";
            optionsJson = "[{\"id\":\"A\",\"texte\":\"Java\"},{\"id\":\"B\",\"texte\":\"Swift\"},{\"id\":\"C\",\"texte\":\"Dart\"},{\"id\":\"D\",\"texte\":\"Kotlin\"}]";
            bonneReponse = "C";
            explication = "Flutter utilise exclusivement le langage Dart, développé par Google, pour compiler en natif.";
        } else if (titreCours.contains("IA Générative")) {
            question = "Quelle bibliothèque Python est spécialisée dans la manipulation de DataFrames ?";
            optionsJson = "[{\"id\":\"A\",\"texte\":\"Pandas\"},{\"id\":\"B\",\"texte\":\"NumPy\"},{\"id\":\"C\",\"texte\":\"Matplotlib\"},{\"id\":\"D\",\"texte\":\"Django\"}]";
            bonneReponse = "A";
            explication = "Pandas fournit la structure DataFrame idéale pour manipuler des données tabulaires.";
        } else if (titreCours.contains("Excel")) {
            question = "Quelle fonction permet de rechercher une valeur dans la première colonne d'un tableau ?";
            optionsJson = "[{\"id\":\"A\",\"texte\":\"INDEX\"},{\"id\":\"B\",\"texte\":\"RECHERCHEV\"},{\"id\":\"C\",\"texte\":\"EQUIV\"},{\"id\":\"D\",\"texte\":\"SOMME\"}]";
            bonneReponse = "B";
            explication = "RECHERCHEV recherche une valeur dans la colonne la plus à gauche et renvoie la valeur d'une autre colonne.";
        } else if (titreCours.contains("Cybersécurité")) {
            question = "Quel protocole chiffre les transferts de fichiers et connexions console à distance ?";
            optionsJson = "[{\"id\":\"A\",\"texte\":\"Telnet\"},{\"id\":\"B\",\"texte\":\"FTP\"},{\"id\":\"C\",\"texte\":\"SSH\"},{\"id\":\"D\",\"texte\":\"HTTP\"}]";
            bonneReponse = "C";
            explication = "SSH (Secure Shell) chiffre le canal de communication, contrairement à Telnet ou FTP.";
        } else if (titreCours.contains("Figma")) {
            question = "Quel outil Figma regroupe plusieurs variations d'un même composant ?";
            optionsJson = "[{\"id\":\"A\",\"texte\":\"Les Variantes\"},{\"id\":\"B\",\"texte\":\"Auto Layout\"},{\"id\":\"C\",\"texte\":\"Les Grilles\"},{\"id\":\"D\",\"texte\":\"Les Variables\"}]";
            bonneReponse = "A";
            explication = "Les variantes permettent de regrouper les déclinaisons (hover, active, etc.) d'un composant.";
        } else if (titreCours.contains("Design UI/UX")) {
            question = "Que signifie la partie UX dans le design produit ?";
            optionsJson = "[{\"id\":\"A\",\"texte\":\"User Interface\"},{\"id\":\"B\",\"texte\":\"User Experience\"},{\"id\":\"C\",\"texte\":\"User Integration\"},{\"id\":\"D\",\"texte\":\"Universal XML\"}]";
            bonneReponse = "B";
            explication = "UX signifie User Experience, c'est-à-dire le ressenti global de l'utilisateur lors de l'usage du produit.";
        } else if (titreCours.contains("Marketing")) {
            question = "Que signifie le SEO en marketing digital ?";
            optionsJson = "[{\"id\":\"A\",\"texte\":\"Search Engine Optimization\"},{\"id\":\"B\",\"texte\":\"Social Media Engagement\"},{\"id\":\"C\",\"texte\":\"Single Email Opt-in\"},{\"id\":\"D\",\"texte\":\"Sales Optimization\"}]";
            bonneReponse = "A";
            explication = "Le SEO désigne l'optimisation pour les moteurs de recherche (référencement naturel).";
        } else if (titreCours.contains("Community")) {
            question = "Quel document liste à l'avance les publications prévues sur les réseaux ?";
            optionsJson = "[{\"id\":\"A\",\"texte\":\"Le calendrier éditorial\"},{\"id\":\"B\",\"texte\":\"La charte graphique\"},{\"id\":\"C\",\"texte\":\"Le business plan\"},{\"id\":\"D\",\"texte\":\"Le rapport d'activité\"}]";
            bonneReponse = "A";
            explication = "Le calendrier éditorial permet de planifier et d'ordonner la production de contenu à l'avance.";
        } else {
            question = "Quel outil collaboratif virtuel simule un grand tableau blanc de brainstorming ?";
            optionsJson = "[{\"id\":\"A\",\"texte\":\"Slack\"},{\"id\":\"B\",\"texte\":\"Miro\"},{\"id\":\"C\",\"texte\":\"Notion\"},{\"id\":\"D\",\"texte\":\"MS Teams\"}]";
            bonneReponse = "B";
            explication = "Miro est une plateforme de tableau blanc collaboratif en ligne très prisée pour le brainstorming.";
        }

        return QCMJpaEntity.builder()
            .id(UUID.randomUUID())
            .leconId(leconId)
            .question(question)
            .optionsJson(optionsJson)
            .bonneReponse(bonneReponse)
            .explication(explication)
            .scorePoints(10)
            .ordre(1)
            .createdAt(LocalDateTime.now())
            .updatedAt(LocalDateTime.now())
            .build();
    }

    private void saveXpLog(UUID apprenantId, int xp, int daysAgo) {
        xpHistoriqueRepo.save(XpHistoriqueJpaEntity.builder()
            .id(UUID.randomUUID())
            .apprenantId(apprenantId)
            .xpGagne(xp)
            .dateGain(LocalDateTime.now().minusDays(daysAgo))
            .build());
    }
}
