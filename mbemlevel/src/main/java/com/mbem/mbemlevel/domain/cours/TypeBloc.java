package com.mbem.mbemlevel.domain.cours;

/**
 * Types de blocs de contenu pédagogique d'une leçon.
 * Chaque leçon est composée d'une liste ordonnée de BlocContenu.
 */
public enum TypeBloc {
    TEXTE_HTML,    // Contenu riche : titres, paragraphes, listes, tableaux, gras
    IMAGE,         // Image avec alt text et légende optionnelle
    VIDEO_YOUTUBE, // Embed YouTube via lien
    VIDEO_VIMEO,   // Embed Vimeo via lien
    PDF_EMBED,     // PDF affiché inline dans la page (stocké MinIO)
    CODE,          // Bloc de code avec coloration syntaxique
    CALLOUT        // Encadré informatif : INFO, ASTUCE, ATTENTION, IMPORTANT
}
