-- =============================================================================
-- MbemNova V21 — Add VIDEO to type_bloc check constraint
-- =============================================================================

ALTER TABLE blocs_contenu DROP CONSTRAINT IF EXISTS blocs_contenu_type_bloc_check;
ALTER TABLE blocs_contenu ADD CONSTRAINT blocs_contenu_type_bloc_check 
CHECK (type_bloc IN ('TEXTE_HTML', 'IMAGE', 'VIDEO_YOUTUBE', 'VIDEO_VIMEO', 'VIDEO', 'PDF_EMBED', 'CODE', 'CALLOUT'));
