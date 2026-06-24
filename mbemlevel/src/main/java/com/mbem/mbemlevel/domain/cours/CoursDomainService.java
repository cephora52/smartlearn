package com.mbem.mbemlevel.domain.cours;
import java.util.List;
/**
 * Règles métier liées aux cours qui dépassent un seul agrégat.
 * Stateless — injectable en Spring si besoin.
 */
import org.springframework.stereotype.Service;

@Service
public class CoursDomainService {
    /**
     * Calcule le % de progression d'un cours en fonction des leçons terminées.
     * @param nbLeconsTotales  Nombre total de leçons dans le cours
     * @param nbLeconsTerminees Nombre de leçons complétées par l'apprenant
     */
    public double calculerPourcentage(int nbLeconsTotales, int nbLeconsTerminees) {
        if (nbLeconsTotales <= 0) return 0.0;
        return Math.min(100.0, (double) nbLeconsTerminees / nbLeconsTotales * 100.0);
    }
    /** Un module est déverrouillé si tous les modules précédents sont complétés. */
    public boolean moduleDevraitEtreDeverrouille(int ordreModule,
                                                  int dernierModuleComplete) {
        return ordreModule <= dernierModuleComplete + 1;
    }
}
