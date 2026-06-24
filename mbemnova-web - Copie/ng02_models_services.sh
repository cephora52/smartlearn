#!/usr/bin/env bash
# ============================================================
# MbemNova · Script 02/16 · Models + Services + Guards
# ============================================================
# Contenu :
#   core/models/index.ts       → DTOs miroir exact API Java
#   core/services/mock.data.ts → données test réalistes
#   core/services/token.service.ts
#   core/services/api.service.ts  (retry 3x backoff expo)
#   core/services/auth.service.ts (signals SSR-safe)
#   core/services/toast.service.ts
#   core/services/course.service.ts
#   core/services/progression.service.ts
#   core/services/payment.service.ts
#   core/services/session.service.ts
#   core/services/assignment.service.ts
#   core/services/community.service.ts
#   core/services/talent.service.ts
#   core/services/notification.service.ts
#   core/services/admin.service.ts
#   core/interceptors/auth.interceptor.ts
#   core/interceptors/error.interceptor.ts
#   core/interceptors/mock.interceptor.ts
#   core/guards/auth.guard.ts
#   core/guards/role.guard.ts
#   core/guards/guest.guard.ts
#
# Usage : chmod +x ng02_models_services.sh && ./ng02_models_services.sh
# ============================================================
set -euo pipefail

G='\033[0;32m'; B='\033[0;34m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'
ok()  { echo -e "${G}  ✓${N} $1"; }
sec() { echo -e "\n${B}▸ $1${N}"; }
err() { echo -e "${R}  ✗${N} $1" >&2; exit 1; }

[[ ! -f "angular.json" ]] && err "Lancez depuis la racine du projet Angular"

CORE="src/app/core"
mkdir -p \
  "${CORE}/models" \
  "${CORE}/services" \
  "${CORE}/interceptors" \
  "${CORE}/guards"

echo -e "\n${B}══════════════════════════════════════════${N}"
echo -e "${B}  MbemNova · 02 · Models + Services       ${N}"
echo -e "${B}══════════════════════════════════════════${N}\n"

# ============================================================
# 1. MODELS — Miroir EXACT des records Java
#    Source : scripts s07_jwt_securite, s08_api_security,
#             s09_cours_progression, s10_paiement,
#             s11_session_devoir, s12_certificat_talent,
#             s13_admin_gamification
# ============================================================
sec "1/7 — core/models/index.ts"

cat > "${CORE}/models/index.ts" << 'EOF'
// ============================================================
// MbemNova · Models TypeScript
// Miroir EXACT des records Java — ne pas modifier sans changer l'API
// ============================================================

// ── Enveloppes API ─────────────────────────────────────────

/** Miroir : ApiResponse<T> */
export interface ApiResponse<T> {
  success:   boolean;
  data:      T | null;
  message:   string;
  timestamp: string;   // ISO 8601
}

/** Miroir : PageResponse<T> */
export interface PageResponse<T> {
  content:       T[];
  page:          number;
  size:          number;
  totalElements: number;
  totalPages:    number;
  first:         boolean;
  last:          boolean;
}

/** Miroir : ErrorResponse */
export interface ErrorResponse {
  status:    number;
  code:      string;
  message:   string;
  details:   string[];
  timestamp: string;
}

// ── Auth (S02, S03, S27) ───────────────────────────────────

/** Rôles — miroir enum Java UserRole */
export type UserRole = 'APPRENANT' | 'FORMATEUR' | 'ADMIN' | 'SUPER_ADMIN';

/** Statuts compte — miroir enum Java StatutCompte */
export type StatutCompte = 'ACTIF' | 'SUSPENDU' | 'INACTIF';

/**
 * Miroir : AuthResponse
 * Champs : UUID userId, String prenom, String email, String role,
 *          String accessToken, String refreshToken,
 *          LocalDateTime expiresAt, Boolean suspended
 */
export interface AuthResponse {
  userId:       string;
  prenom:       string;
  email:        string;
  role:         UserRole;
  accessToken:  string;
  refreshToken: string;
  expiresAt:    string;   // ISO 8601
  suspended:    boolean;
}

/** Profil utilisateur (décodé JWT + /auth/me) */
export interface UserProfile {
  userId:   string;
  prenom:   string;
  email:    string;
  role:     UserRole;
  photoUrl: string | null;
  statut:   StatutCompte;
}

/**
 * Miroir : InscriptionRequest
 * Champs : String prenom, String email, String motDePasse
 */
export interface InscriptionRequest {
  prenom:       string;
  email:        string;
  motDePasse:   string;
  referralCode?: string;   // Enrichissement front — code parrainage S15
}

/**
 * Miroir : ConnexionRequest
 * Champs : boolean rememberMe (email + motDePasse implicites)
 */
export interface ConnexionRequest {
  email:      string;
  motDePasse: string;
  rememberMe: boolean;
}

/** Miroir : RefreshTokenRequest */
export interface RefreshTokenRequest {
  refreshToken: string;
}

/** Miroir : ResetPasswordRequest */
export interface ResetPasswordRequest {
  email: string;
}

/**
 * Miroir : NouveauMotDePasseRequest
 * Utilisé S27 étape 2
 */
export interface NouveauMotDePasseRequest {
  token:             string;
  nouveauMotDePasse: string;
  confirmation:      string;
}

// ── Cours + Progression (S04, S05, S06, S07) ──────────────

/** Niveaux — miroir enum Java NiveauCours */
export type NiveauCours = 'DEBUTANT' | 'INTERMEDIAIRE' | 'AVANCE';

/**
 * Miroir : CoursResponse
 * Champs : UUID id, String titre, String description, NiveauCours niveau,
 *          String imageCouverture, long prixFcfa, String prixAffichage,
 *          int nbApprenants, Double noteMoyenne, int nbAvis,
 *          Double seuilPaiement, boolean estActif, String slug
 */
export interface CoursResponse {
  id:              string;
  titre:           string;
  description:     string;
  niveau:          NiveauCours;
  imageCouverture: string | null;
  prixFcfa:        number;
  prixAffichage:   string;        // Ex: "25 000 FCFA"
  nbApprenants:    number;
  noteMoyenne:     number | null;
  nbAvis:          number;
  seuilPaiement:   number;        // 0.0–1.0 → % gratuit
  estActif:        boolean;
  slug:            string;
}

/**
 * Miroir : ProgressionResponse
 * Champs : UUID id, UUID coursId, double pourcentage, boolean estPaye,
 *          int xpGagne, boolean seuilAtteint, boolean estTermine,
 *          LocalDateTime dateDebut, LocalDateTime dateCompletion
 */
export interface ProgressionResponse {
  id:             string;
  coursId:        string;
  pourcentage:    number;    // 0–100
  estPaye:        boolean;
  xpGagne:        number;
  seuilAtteint:   boolean;   // Mur de paiement S07
  estTermine:     boolean;
  dateDebut:      string;
  dateCompletion: string | null;
}

/**
 * Miroir : TerminerLeconRequest
 * (UUID leconId + contexte progression)
 */
export interface TerminerLeconRequest {
  leconId:           string;
  nbLeconsTotales:   number;
  nbLeconsTerminees: number;
  xpLecon:           number;
}

/** Module d'un cours (enrichissement front) */
export interface ModuleResponse {
  id:          string;
  coursId:     string;
  titre:       string;
  sortOrder:   number;
  lecons:      LeconResponse[];
}

/** Leçon d'un module (enrichissement front) */
export interface LeconResponse {
  id:             string;
  moduleId:       string;
  titre:          string;
  contenu:        string | null;
  videoUrl:       string | null;
  pdfUrl:         string | null;
  dureeMinutes:   number;
  sortOrder:      number;
  aQuiz:          boolean;
  xpReward:       number;
  estTerminee?:   boolean;   // État côté apprenant
}

// ── Paiements (S07, S08, S16, S17, S18) ───────────────────

/** Miroir enum Java ModePaiement */
export type ModePaiement = 'CASH' | 'MOBILE_MONEY' | 'VIREMENT' | 'ONLINE';

/** Miroir enum Java StatutPaiement */
export type StatutPaiement = 'RECU' | 'PARTIEL' | 'EN_ATTENTE' | 'RETARD' | 'ANNULE';

/**
 * Miroir : PaiementResponse
 * Champs : UUID id, UUID apprenantId, UUID coursId,
 *          String montantTotal, String montantPaye,
 *          ModePaiement mode, StatutPaiement statut,
 *          boolean accesActive, LocalDateTime dateActivation
 */
export interface PaiementResponse {
  id:             string;
  apprenantId:    string;
  coursId:        string;
  montantTotal:   string;
  montantPaye:    string;
  mode:           ModePaiement;
  statut:         StatutPaiement;
  accesActive:    boolean;
  dateActivation: string | null;
  tranches?:      TrancheResponse[];
}

export interface TrancheResponse {
  id:           string;
  paiementId:   string;
  montant:      string;
  echeance:     string;
  estPayee:     boolean;
  datePaiement: string | null;
}

/**
 * Miroir : EnregistrerPaiementRequest
 * Champs : UUID apprenantId, UUID coursId, BigDecimal montantRecu,
 *          ModePaiement mode, int nbTranches, BigDecimal montantTranche,
 *          List<LocalDate> echeances, String noteInterne
 */
export interface EnregistrerPaiementRequest {
  apprenantId:    string;
  coursId:        string;
  montantRecu:    number;
  mode:           ModePaiement;
  nbTranches:     number;
  montantTranche: number;
  echeances:      string[];
  noteInterne?:   string;
}

/** Demande moratoire — S17 */
export interface MoratoireRequest {
  paiementId:             string;
  raison:                 'DIFFICULTES_FINANCIERES' | 'PROBLEME_SANTE' | 'AUTRE';
  explication:            string;
  nouvelleDateSouhaitee:  string;   // ISO 8601
}

// ── Sessions + Devoirs (S09, S10, S11, S20, S22, S23) ──────

/** Miroir enum Java Modalite */
export type Modalite = 'PRESENTIEL' | 'MEET' | 'HYBRIDE';

/**
 * Miroir : SessionResponse
 * Champs : UUID id, UUID coursId, String titre, Modalite modalite,
 *          LocalDate dateDebut, LocalDate dateFin,
 *          int capaciteMax, int nbInscrits, int placesRestantes,
 *          String lienReunion, String lieu, boolean estActive
 */
export interface SessionResponse {
  id:              string;
  coursId:         string;
  titre:           string;
  modalite:        Modalite;
  dateDebut:       string;
  dateFin:         string;
  capaciteMax:     number;
  nbInscrits:      number;
  placesRestantes: number;
  lienReunion:     string | null;
  lieu:            string | null;
  estActive:       boolean;
}

/**
 * Miroir : DevoirResponse
 * Champs : UUID id, UUID sessionId, String titre, String consignes,
 *          LocalDateTime dateRemise, String lienRessources, boolean estVerrouille
 */
export interface DevoirResponse {
  id:             string;
  sessionId:      string;
  titre:          string;
  consignes:      string;
  dateRemise:     string;
  lienRessources: string | null;
  estVerrouille:  boolean;
  rendu?:         RenduResponse;
}

export interface RenduResponse {
  id:          string;
  devoirId:    string;
  apprenantId: string;
  contenu:     string;
  lienFichier: string | null;
  soumisLe:    string;
  note:        number | null;   // /20
  commentaire: string | null;
  corrigeLe:   string | null;
}

/** Miroir : InscrireSessionRequest */
export interface InscrireSessionRequest {
  coursId: string;
}

/**
 * Miroir : EnvoyerDevoirRequest
 * Champs : UUID sessionId, UUID moduleId, String titre,
 *          String consignes, LocalDateTime dateRemise,
 *          String lienRessources
 */
export interface EnvoyerDevoirRequest {
  sessionId:       string;
  moduleId?:       string;
  titre:           string;
  consignes:       string;
  dateRemise:      string;
  lienRessources?: string;
  typeRendu:       'TEXTE' | 'FICHIER' | 'LIEN';
}

/**
 * Miroir : SoumettreRenduRequest
 * Champs : UUID devoirId, String contenu, String lienFichier
 */
export interface SoumettreRenduRequest {
  devoirId:    string;
  contenu:     string;
  lienFichier?: string;
}

/**
 * Miroir : CorrigerRenduRequest
 * Champs : UUID renduId, double note, String commentaire
 */
export interface CorrigerRenduRequest {
  renduId:          string;
  note:             number;
  commentaire:      string;
  pointsForts?:     string;
  pointsAmeliorer?: string;
}

export interface CreneauResponse {
  id:              string;
  sessionId:       string;
  jourSemaine:     string;
  heureDebut:      string;
  heureFin:        string;
  placesRestantes: number;
}

// ── Talents + Certificats (S13, S14) ──────────────────────

/**
 * Miroir : CertificatResponse
 * Champs : UUID id, UUID coursId, String codeVerification,
 *          String lienPdf, LocalDateTime dateEmission
 */
export interface CertificatResponse {
  id:               string;
  coursId:          string;
  codeVerification: string;
  lienPdf:          string;
  dateEmission:     string;
  coursTitre?:      string;   // Enrichi front
  coursNiveau?:     NiveauCours;
}

/**
 * Miroir : ProfilTalentResponse
 * Champs : UUID id, String prenom, String nom, String telephone,
 *          boolean disponiblePourEmploi,
 *          String lienPortfolio, String lienLinkedin,
 *          String lienGithub, String lienCv,
 *          String bio, int xpTotal, int streakJours,
 *          List<CertificatResponse> certificats
 */
export interface ProfilTalentResponse {
  id:                   string;
  prenom:               string;
  nom:                  string;
  telephone:            string | null;
  disponiblePourEmploi: boolean;
  lienPortfolio:        string | null;
  lienLinkedin:         string | null;
  lienGithub:           string | null;
  lienCv:               string | null;
  bio:                  string | null;
  xpTotal:              number;
  streakJours:          number;
  certificats:          CertificatResponse[];
  rang?:                number;
}

export interface UpdateProfilRequest {
  bio?:                   string;
  disponiblePourEmploi?:  boolean;
  lienPortfolio?:         string;
  lienLinkedin?:          string;
  lienGithub?:            string;
}

// ── Communauté + Notifications (S12) ──────────────────────

/** Miroir enum Java TypeNotification */
export type TypeNotification =
  | 'PAIEMENT_ECHEANCE' | 'PAIEMENT_RETARD'   | 'PAIEMENT_RECU'
  | 'COURS_DEBLOQUE'    | 'DEVOIR_PUBLIE'      | 'DEVOIR_CORRIGE'
  | 'REPONSE_COMMUNAUTE'| 'PARRAINAGE_ACTIF'   | 'TIRAGE_RESULTAT'
  | 'CERTIFICAT_GENERE' | 'COMPTE_SUSPENDU'    | 'SYSTEME';

/**
 * Miroir : NotificationResponse
 * Champs : UUID id, TypeNotification type, String titre,
 *          String contenu, boolean estLue,
 *          LocalDateTime createdAt, String lienAction
 */
export interface NotificationResponse {
  id:         string;
  type:       TypeNotification;
  titre:      string;
  contenu:    string;
  estLue:     boolean;
  createdAt:  string;
  lienAction: string | null;
}

/**
 * Miroir : MessageResponse
 * Champs : UUID id, UUID auteurId, UUID parentId,
 *          String contenu, boolean estQuestion, boolean estResolu,
 *          int nbLikes, LocalDateTime createdAt
 */
export interface MessageResponse {
  id:          string;
  auteurId:    string;
  parentId:    string | null;
  contenu:     string;
  estQuestion: boolean;
  estResolu:   boolean;
  nbLikes:     number;
  createdAt:   string;
  auteurPrenom?: string;
  reponses?:   MessageResponse[];
}

/**
 * Miroir : PostMessageRequest
 * Champs : UUID parentId (null = question, non-null = réponse)
 */
export interface PostMessageRequest {
  coursId:     string;
  contenu:     string;
  parentId?:   string;
  estQuestion: boolean;
}

// ── Gamification (S15, S24) ────────────────────────────────

export interface LeaderboardEntry {
  rang:        number;
  userId:      string;
  prenom:      string;
  xpTotal:     number;
  streakJours: number;
  estMoi?:     boolean;
}

export interface DrawResponse {
  id:                      string;
  prixTicketFcfa:          number;
  dateDrawFormatee:        string;
  formationGagnanteTitre:  string;
  formationGagnantePrix:   string;
  nbTicketsVendus:         number;
  statut:                  'OUVERT' | 'CLOTURE' | 'GAGNANT_SELECTIONNE';
  gagnantPrenom?:          string;
  gagnantVille?:           string;
}

export interface TicketResponse {
  id:        string;
  drawId:    string;
  numero:    string;
  acheteLe:  string;
}

export interface ReferralResponse {
  lienParrainage:      string;
  codeParrainage:      string;
  nbFilleulsInvites:   number;
  nbFilleulsActifs:    number;
  xpGagneParrainage:   number;
  filleuls:            FilleulResponse[];
}

export interface FilleulResponse {
  prenom:     string;
  email:      string;
  estActif:   boolean;
  rejointLe:  string;
}

// ── Admin (S21, S25, S26) ──────────────────────────────────

/**
 * Miroir : StatistiquesResponse
 * Champs : long totalApprenants, long apprenantsActifs,
 *          long paiementsEnAttente, long paiementsEnRetard,
 *          long revenusTotal, String revenus
 */
export interface StatistiquesResponse {
  totalApprenants:    number;
  apprenantsActifs:   number;
  paiementsEnAttente: number;
  paiementsEnRetard:  number;
  revenusTotal:       number;
  revenus:            string;
}

export interface AlerteAdmin {
  type:    'RETARD' | 'MORATOIRE' | 'INSCRIPTION' | 'COURS_ATTENTE';
  message: string;
  count:   number;
  lien:    string;
}

/**
 * Miroir : InscriptionManuelleRequest
 * Champs : String prenom, String nom, String email, String telephone
 */
export interface InscriptionManuelleRequest {
  prenom:    string;
  nom:       string;
  email:     string;
  telephone: string;
  coursId?:  string;
}

/**
 * Miroir : AssignerRoleRequest
 * Champs : UUID userId, UserRole nouveauRole, String motDePasseAdmin
 */
export interface AssignerRoleRequest {
  userId:          string;
  nouveauRole:     UserRole;
  motDePasseAdmin: string;
}

/**
 * Miroir : CreerCoursRequest
 * Champs : String titre, String description, NiveauCours niveau,
 *          UUID categorieId, double seuilPaiement
 */
export interface CreerCoursRequest {
  titre:         string;
  description:   string;
  niveau:        NiveauCours;
  categorieId?:  string;
  prixFcfa:      number;
  seuilPaiement: number;   // 0.0–1.0
}

export interface ApprenantAdminView {
  id:              string;
  prenom:          string;
  nom:             string;
  email:           string;
  telephone:       string | null;
  statut:          StatutCompte;
  xpTotal:         number;
  nbCoursInscrits: number;
  inscritLe:       string;
}

// ── Types utilitaires ──────────────────────────────────────
export type LoadingState = 'idle' | 'loading' | 'success' | 'error';
EOF
ok "core/models/index.ts"

# ============================================================
# 2. MOCK DATA — Données test réalistes (contexte Cameroun)
# ============================================================
sec "2/7 — core/services/mock.data.ts"

cat > "${CORE}/services/mock.data.ts" << 'EOF'
// ============================================================
// MbemNova · Données mock réalistes
// Contexte : Cameroun (Douala, Yaoundé, Bafoussam)
// Montants en FCFA · Prénoms locaux
// ============================================================
import type {
  AuthResponse, UserProfile, CoursResponse, ProgressionResponse,
  PaiementResponse, SessionResponse, DevoirResponse, MessageResponse,
  NotificationResponse, ProfilTalentResponse, LeaderboardEntry,
  DrawResponse, ReferralResponse, StatistiquesResponse, ApprenantAdminView,
} from '../models';

// ── Auth ──────────────────────────────────────────────────
export const MOCK_AUTH: AuthResponse = {
  userId: 'u-001', prenom: 'Jean-Paul', email: 'jeanpaul.mbemba@gmail.com',
  role: 'APPRENANT', accessToken: 'mock.jwt.access', refreshToken: 'mock.jwt.refresh',
  expiresAt: new Date(Date.now() + 86_400_000).toISOString(), suspended: false,
};

export const MOCK_USER: UserProfile = {
  userId: 'u-001', prenom: 'Jean-Paul', email: 'jeanpaul.mbemba@gmail.com',
  role: 'APPRENANT', photoUrl: null, statut: 'ACTIF',
};

export const MOCK_USER_ADMIN: UserProfile = {
  userId: 'u-admin', prenom: 'Admin', email: 'admin@mbemnova.com',
  role: 'ADMIN', photoUrl: null, statut: 'ACTIF',
};

// ── Cours ─────────────────────────────────────────────────
export const MOCK_COURS: CoursResponse[] = [
  {
    id: 'c-001', slug: 'dev-web-html-css-js',
    titre: 'Développement Web : HTML, CSS & JavaScript',
    description: 'Maîtrisez les fondamentaux du web. Créez vos premiers sites interactifs. Formation adaptée au contexte camerounais avec des exemples concrets.',
    niveau: 'DEBUTANT', imageCouverture: null,
    prixFcfa: 25000, prixAffichage: '25 000 FCFA',
    nbApprenants: 142, noteMoyenne: 4.7, nbAvis: 38, seuilPaiement: 0.30, estActif: true,
  },
  {
    id: 'c-002', slug: 'react-nodejs-fullstack',
    titre: 'React & Node.js — Application Full-Stack',
    description: 'Construisez des applications web modernes. React côté client, Node.js côté serveur. Portfolio de projets inclus.',
    niveau: 'INTERMEDIAIRE', imageCouverture: null,
    prixFcfa: 45000, prixAffichage: '45 000 FCFA',
    nbApprenants: 87, noteMoyenne: 4.9, nbAvis: 21, seuilPaiement: 0.25, estActif: true,
  },
  {
    id: 'c-003', slug: 'python-data-science',
    titre: 'Python & Data Science pour l\'Afrique',
    description: 'Analysez des données africaines avec Python, pandas et matplotlib. Études de cas basés sur des données locales réelles.',
    niveau: 'DEBUTANT', imageCouverture: null,
    prixFcfa: 30000, prixAffichage: '30 000 FCFA',
    nbApprenants: 203, noteMoyenne: 4.8, nbAvis: 67, seuilPaiement: 0.30, estActif: true,
  },
  {
    id: 'c-004', slug: 'android-kotlin',
    titre: 'Mobile Android avec Kotlin',
    description: 'Développez vos premières apps Android. De zéro à la publication sur le Play Store en 8 semaines.',
    niveau: 'INTERMEDIAIRE', imageCouverture: null,
    prixFcfa: 35000, prixAffichage: '35 000 FCFA',
    nbApprenants: 56, noteMoyenne: 4.5, nbAvis: 14, seuilPaiement: 0.30, estActif: true,
  },
  {
    id: 'c-005', slug: 'ui-ux-figma',
    titre: 'UI/UX Design avec Figma',
    description: 'Créez des interfaces modernes et accessibles. Design thinking, prototypage, tests utilisateurs.',
    niveau: 'DEBUTANT', imageCouverture: null,
    prixFcfa: 20000, prixAffichage: '20 000 FCFA',
    nbApprenants: 178, noteMoyenne: 4.6, nbAvis: 45, seuilPaiement: 0.40, estActif: true,
  },
  {
    id: 'c-006', slug: 'devops-docker',
    titre: 'DevOps & Cloud : Docker + CI/CD',
    description: 'Automatisez vos déploiements. Docker, GitHub Actions, VPS. Pour les développeurs qui veulent livrer vite.',
    niveau: 'AVANCE', imageCouverture: null,
    prixFcfa: 50000, prixAffichage: '50 000 FCFA',
    nbApprenants: 34, noteMoyenne: 4.9, nbAvis: 8, seuilPaiement: 0.20, estActif: true,
  },
];

// ── Progression ───────────────────────────────────────────
export const MOCK_PROGRESSION: ProgressionResponse = {
  id: 'p-001', coursId: 'c-001', pourcentage: 45,
  estPaye: false, xpGagne: 120, seuilAtteint: false, estTermine: false,
  dateDebut: new Date(Date.now() - 7 * 86_400_000).toISOString(), dateCompletion: null,
};

// ── Paiements ─────────────────────────────────────────────
export const MOCK_PAIEMENTS: PaiementResponse[] = [
  {
    id: 'pay-001', apprenantId: 'u-001', coursId: 'c-001',
    montantTotal: '25 000 FCFA', montantPaye: '15 000 FCFA',
    mode: 'CASH', statut: 'PARTIEL', accesActive: true,
    dateActivation: new Date(Date.now() - 14 * 86_400_000).toISOString(),
    tranches: [
      { id: 't1', paiementId: 'pay-001', montant: '15 000 FCFA',
        echeance: new Date(Date.now() - 14 * 86_400_000).toISOString(),
        estPayee: true, datePaiement: new Date(Date.now() - 14 * 86_400_000).toISOString() },
      { id: 't2', paiementId: 'pay-001', montant: '10 000 FCFA',
        echeance: new Date(Date.now() + 16 * 86_400_000).toISOString(),
        estPayee: false, datePaiement: null },
    ],
  },
];

// ── Sessions ──────────────────────────────────────────────
export const MOCK_SESSIONS: SessionResponse[] = [
  {
    id: 's-001', coursId: 'c-001', titre: 'Dev Web — Session Juin 2025',
    modalite: 'MEET',
    dateDebut: new Date(Date.now() + 7 * 86_400_000).toISOString(),
    dateFin:   new Date(Date.now() + 37 * 86_400_000).toISOString(),
    capaciteMax: 20, nbInscrits: 13, placesRestantes: 7,
    lienReunion: 'https://meet.google.com/mbem-nova-dev', lieu: null, estActive: true,
  },
  {
    id: 's-002', coursId: 'c-001', titre: 'Dev Web — Présentiel Douala',
    modalite: 'PRESENTIEL',
    dateDebut: new Date(Date.now() + 14 * 86_400_000).toISOString(),
    dateFin:   new Date(Date.now() + 44 * 86_400_000).toISOString(),
    capaciteMax: 15, nbInscrits: 15, placesRestantes: 0,
    lienReunion: null, lieu: 'Centre MbemNova, Akwa — Douala', estActive: true,
  },
];

// ── Devoirs ───────────────────────────────────────────────
export const MOCK_DEVOIRS: DevoirResponse[] = [
  {
    id: 'd-001', sessionId: 's-001',
    titre: 'TP1 — Page de profil responsive',
    consignes: 'Créez une page HTML/CSS présentant votre profil professionnel. Elle doit être responsive et fonctionner sur mobile (100px minimum).',
    dateRemise: new Date(Date.now() + 5 * 86_400_000).toISOString(),
    lienRessources: null, estVerrouille: false,
  },
];

// ── Communauté ────────────────────────────────────────────
export const MOCK_MESSAGES: MessageResponse[] = [
  {
    id: 'm-001', auteurId: 'u-003', parentId: null, auteurPrenom: 'Patrick N.',
    contenu: 'Comment centrer un div en CSS ? Margin auto ne marche pas dans mon cas.',
    estQuestion: true, estResolu: false, nbLikes: 3,
    createdAt: new Date(Date.now() - 86_400_000).toISOString(), reponses: [],
  },
  {
    id: 'm-002', auteurId: 'u-002', parentId: null, auteurPrenom: 'Diane K.',
    contenu: 'Quelle est la vraie différence entre `let` et `const` ? Les deux semblent pareil.',
    estQuestion: true, estResolu: true, nbLikes: 8,
    createdAt: new Date(Date.now() - 2 * 86_400_000).toISOString(),
    reponses: [
      {
        id: 'm-003', auteurId: 'u-004', parentId: 'm-002', auteurPrenom: 'Alice F.',
        contenu: '`const` = référence immuable (tu ne peux pas réassigner). `let` = variable qui peut changer. En pratique : utilise `const` par défaut, `let` seulement si tu dois réassigner.',
        estQuestion: false, estResolu: false, nbLikes: 12,
        createdAt: new Date(Date.now() - 2 * 86_400_000 + 3_600_000).toISOString(),
      },
    ],
  },
];

// ── Notifications ─────────────────────────────────────────
export const MOCK_NOTIFICATIONS: NotificationResponse[] = [
  { id: 'n-001', type: 'DEVOIR_PUBLIE', estLue: false,
    titre: 'Nouveau devoir publié',
    contenu: 'Alice Fouda a publié : "TP1 — Page de profil responsive"',
    createdAt: new Date(Date.now() - 3_600_000).toISOString(), lienAction: '/app/devoirs' },
  { id: 'n-002', type: 'PAIEMENT_ECHEANCE', estLue: false,
    titre: 'Échéance dans 7 jours',
    contenu: 'Ta prochaine tranche de 10 000 FCFA est prévue le ' +
      new Date(Date.now() + 7 * 86_400_000).toLocaleDateString('fr-FR'),
    createdAt: new Date(Date.now() - 7_200_000).toISOString(), lienAction: '/app/paiements' },
  { id: 'n-003', type: 'PARRAINAGE_ACTIF', estLue: true,
    titre: 'Filleul actif !',
    contenu: 'Rodrigue vient de terminer son premier module. +50 XP pour toi !',
    createdAt: new Date(Date.now() - 2 * 86_400_000).toISOString(), lienAction: '/app/parrainage' },
  { id: 'n-004', type: 'DEVOIR_CORRIGE', estLue: true,
    titre: 'Devoir corrigé — 16/20',
    contenu: 'Ton TP1 a été corrigé. Note : 16/20. Bravo, excellent travail !',
    createdAt: new Date(Date.now() - 3 * 86_400_000).toISOString(), lienAction: '/app/devoirs' },
];

// ── Profil talent ─────────────────────────────────────────
export const MOCK_PROFIL: ProfilTalentResponse = {
  id: 'u-001', prenom: 'Jean-Paul', nom: 'Mbemba',
  telephone: '+237 691 23 45 67', disponiblePourEmploi: true,
  lienPortfolio: null, lienLinkedin: null, lienGithub: null, lienCv: null,
  bio: 'Passionné de développement web et mobile. En formation sur MbemNova depuis 3 mois. Cherche un stage ou emploi à Douala.',
  xpTotal: 2980, streakJours: 9, rang: 5,
  certificats: [
    { id: 'cert-001', coursId: 'c-003', codeVerification: 'MBEM-2025-JP-PY42',
      lienPdf: '/api/v1/certificats/cert-001/pdf',
      dateEmission: new Date(Date.now() - 30 * 86_400_000).toISOString(),
      coursTitre: 'Python & Data Science', coursNiveau: 'DEBUTANT' },
  ],
};

// ── Leaderboard ───────────────────────────────────────────
export const MOCK_LEADERBOARD: LeaderboardEntry[] = [
  { rang: 1, userId: 'L1', prenom: 'Serge M.',     xpTotal: 4200, streakJours: 21 },
  { rang: 2, userId: 'L2', prenom: 'Diane K.',     xpTotal: 3850, streakJours: 18 },
  { rang: 3, userId: 'L3', prenom: 'Patrick N.',   xpTotal: 3610, streakJours: 15 },
  { rang: 4, userId: 'L4', prenom: 'Marie-Claire', xpTotal: 3200, streakJours: 12 },
  { rang: 5, userId: 'u-001', prenom: 'Jean-Paul', xpTotal: 2980, streakJours: 9, estMoi: true },
  { rang: 6, userId: 'L6', prenom: 'Esther B.',    xpTotal: 2750, streakJours: 7 },
  { rang: 7, userId: 'L7', prenom: 'Samuel O.',    xpTotal: 2500, streakJours: 5 },
  { rang: 8, userId: 'L8', prenom: 'Nadège T.',    xpTotal: 2200, streakJours: 4 },
];

// ── Tirage ────────────────────────────────────────────────
export const MOCK_DRAW: DrawResponse = {
  id: 'draw-001', prixTicketFcfa: 2000,
  dateDrawFormatee: '1er juin 2025',
  formationGagnanteTitre: 'React & Node.js Full-Stack',
  formationGagnantePrix: '45 000 FCFA',
  nbTicketsVendus: 47, statut: 'OUVERT',
};

// ── Parrainage ────────────────────────────────────────────
export const MOCK_REFERRAL: ReferralResponse = {
  lienParrainage: 'https://mbemnova.com/inscription?ref=JPMBEMBA42',
  codeParrainage: 'JPMBEMBA42',
  nbFilleulsInvites: 3, nbFilleulsActifs: 2, xpGagneParrainage: 400,
  filleuls: [
    { prenom: 'Rodrigue', email: 'r***@yahoo.fr',  estActif: true,  rejointLe: new Date(Date.now() - 20 * 86_400_000).toISOString() },
    { prenom: 'Yvonne',   email: 'y***@gmail.com', estActif: true,  rejointLe: new Date(Date.now() - 10 * 86_400_000).toISOString() },
    { prenom: 'Fabrice',  email: 'f***@gmail.com', estActif: false, rejointLe: new Date(Date.now() - 3  * 86_400_000).toISOString() },
  ],
};

// ── Stats admin ───────────────────────────────────────────
export const MOCK_STATS: StatistiquesResponse = {
  totalApprenants: 247, apprenantsActifs: 189,
  paiementsEnAttente: 12, paiementsEnRetard: 5,
  revenusTotal: 3_750_000, revenus: '3 750 000 FCFA',
};

export const MOCK_APPRENANTS_ADMIN: ApprenantAdminView[] = [
  { id: 'u-001', prenom: 'Jean-Paul', nom: 'Mbemba',  email: 'jeanpaul@gmail.com', telephone: '+237 691 23 45 67', statut: 'ACTIF',    xpTotal: 2980, nbCoursInscrits: 2, inscritLe: new Date(Date.now() - 45 * 86_400_000).toISOString() },
  { id: 'u-002', prenom: 'Diane',     nom: 'Kamga',   email: 'diane@yahoo.fr',     telephone: '+237 677 89 01 23', statut: 'ACTIF',    xpTotal: 3850, nbCoursInscrits: 1, inscritLe: new Date(Date.now() - 30 * 86_400_000).toISOString() },
  { id: 'u-003', prenom: 'Rodrigue',  nom: 'Ekambi',  email: 'rod@gmail.com',      telephone: null,               statut: 'SUSPENDU', xpTotal:  450, nbCoursInscrits: 1, inscritLe: new Date(Date.now() - 60 * 86_400_000).toISOString() },
  { id: 'u-004', prenom: 'Yvonne',    nom: 'Beyala',  email: 'yv@gmail.com',       telephone: '+237 655 44 33 22', statut: 'ACTIF',    xpTotal: 1200, nbCoursInscrits: 3, inscritLe: new Date(Date.now() - 20 * 86_400_000).toISOString() },
  { id: 'u-005', prenom: 'Samuel',    nom: 'Owona',   email: 'sam@hotmail.com',    telephone: '+237 688 77 66 55', statut: 'ACTIF',    xpTotal: 2500, nbCoursInscrits: 2, inscritLe: new Date(Date.now() - 15 * 86_400_000).toISOString() },
];
EOF
ok "core/services/mock.data.ts"

# ============================================================
# 3. SERVICES CORE
# ============================================================
sec "3/7 — Services (token, api, auth, toast)"

# ── token.service.ts ─────────────────────────────────────
cat > "${CORE}/services/token.service.ts" << 'EOF'
import { Injectable, signal } from '@angular/core';

/**
 * TokenService — JWT uniquement en mémoire (signal privé).
 *
 * SÉCURITÉ :
 * • Access token → signal en mémoire : invisible aux XSS.
 *   Disparaît à la fermeture de l'onglet (voulu).
 * • Refresh token → cookie httpOnly géré par Spring Boot.
 *   Angular ne le lit jamais.
 */
@Injectable({ providedIn: 'root' })
export class TokenService {
  readonly #token = signal<string | null>(null);

  set(t: string):   void { this.#token.set(t); }
  get():  string | null  { return this.#token(); }
  clear():          void { this.#token.set(null); }
  has():         boolean { return this.#token() !== null; }

  /** Décodage payload JWT (sans vérification signature — côté serveur uniquement) */
  decode(token: string): Record<string, unknown> | null {
    try {
      const p = token.split('.')[1];
      if (!p) return null;
      const pad = p + '='.repeat((4 - p.length % 4) % 4);
      return JSON.parse(atob(pad)) as Record<string, unknown>;
    } catch { return null; }
  }

  /** Vérifie expiration côté client (marge 30s) */
  isExpired(token: string): boolean {
    const p = this.decode(token);
    if (!p || typeof p['exp'] !== 'number') return true;
    return Date.now() / 1000 > (p['exp'] as number) - 30;
  }
}
EOF

# ── api.service.ts ────────────────────────────────────────
cat > "${CORE}/services/api.service.ts" << 'EOF'
import { Injectable, inject, signal } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, throwError, timer } from 'rxjs';
import { retry, timeout, catchError } from 'rxjs/operators';
import { environment } from '@env/environment';
import type { ApiResponse, PageResponse } from '../models';

const BASE    = environment.apiUrl;
const TIMEOUT = 30_000;

export interface PageParams {
  page?: number;
  size?: number;
  sort?: string;
  [key: string]: string | number | boolean | undefined;
}

/**
 * ApiService — couche HTTP de base.
 *
 * Fonctionnalités :
 * • Retry automatique 3× avec backoff exponentiel (1s → 2s → 4s)
 *   sur erreurs réseau + 5xx. Jamais de retry sur 4xx.
 * • Timeout 30s configurable par requête.
 * • Signal `loading` global pour les barres de chargement.
 */
@Injectable({ providedIn: 'root' })
export class ApiService {
  readonly #http = inject(HttpClient);

  /** Nombre de requêtes actives — pour le loading global */
  #active = 0;
  readonly loading = signal(false);

  get<T>(path: string, params?: PageParams): Observable<ApiResponse<T>> {
    return this.#req<T>('GET', path, null, params);
  }

  getPage<T>(path: string, params?: PageParams): Observable<ApiResponse<PageResponse<T>>> {
    return this.#req<PageResponse<T>>('GET', path, null, params);
  }

  post<T>(path: string, body: unknown): Observable<ApiResponse<T>> {
    return this.#req<T>('POST', path, body);
  }

  put<T>(path: string, body: unknown): Observable<ApiResponse<T>> {
    return this.#req<T>('PUT', path, body);
  }

  patch<T>(path: string, body: unknown): Observable<ApiResponse<T>> {
    return this.#req<T>('PATCH', path, body);
  }

  delete<T>(path: string): Observable<ApiResponse<T>> {
    return this.#req<T>('DELETE', path, null);
  }

  #req<T>(
    method: string,
    path: string,
    body: unknown,
    params?: PageParams,
  ): Observable<ApiResponse<T>> {
    this.#inc();

    let httpParams = new HttpParams();
    if (params) {
      Object.entries(params).forEach(([k, v]) => {
        if (v !== undefined && v !== null) httpParams = httpParams.set(k, String(v));
      });
    }

    return this.#http
      .request<ApiResponse<T>>(method, `${BASE}${path}`, {
        body:   body ?? undefined,
        params: httpParams,
      })
      .pipe(
        timeout(TIMEOUT),
        retry({
          count: 3,
          delay: (err: { status?: number }, n: number) => {
            // 4xx → pas de retry
            if (err?.status && err.status >= 400 && err.status < 500) {
              return throwError(() => err);
            }
            return timer(Math.pow(2, n - 1) * 1000);
          },
        }),
        catchError(err => { this.#dec(); return throwError(() => err); }),
      );
  }

  #inc(): void { this.#active++; this.loading.set(true); }
  #dec(): void {
    this.#active = Math.max(0, this.#active - 1);
    if (!this.#active) this.loading.set(false);
  }
}
EOF

# ── toast.service.ts ──────────────────────────────────────
cat > "${CORE}/services/toast.service.ts" << 'EOF'
import { Injectable, signal } from '@angular/core';

export type ToastType = 'success' | 'error' | 'warning' | 'info';

export interface Toast {
  id:       string;
  type:     ToastType;
  title:    string;
  message?: string;
  duration: number;
}

/**
 * ToastService — notifications non-intrusives.
 * Max 3 toasts simultanés. Auto-dismiss configurable.
 * Compatible SSR (signal côté serveur retourne []).
 */
@Injectable({ providedIn: 'root' })
export class ToastService {
  readonly toasts = signal<Toast[]>([]);

  show(type: ToastType, title: string, message?: string, duration = 4000): void {
    const id = Math.random().toString(36).slice(2, 9);
    this.toasts.update(list => [...list.slice(-2), { id, type, title, message, duration }]);
    if (duration > 0) setTimeout(() => this.dismiss(id), duration);
  }

  success(title: string, message?: string): void { this.show('success', title, message); }
  error(title: string, message?: string):   void { this.show('error', title, message, 6000); }
  warning(title: string, message?: string): void { this.show('warning', title, message); }
  info(title: string, message?: string):    void { this.show('info', title, message); }

  dismiss(id: string): void { this.toasts.update(l => l.filter(t => t.id !== id)); }
}
EOF

# ── auth.service.ts ───────────────────────────────────────
cat > "${CORE}/services/auth.service.ts" << 'EOF'
import {
  Injectable, inject, signal, computed, PLATFORM_ID,
} from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { Router } from '@angular/router';
import { Observable, tap, catchError, throwError } from 'rxjs';
import { ApiService }   from './api.service';
import { TokenService } from './token.service';
import { ToastService } from './toast.service';
import type {
  AuthResponse, UserProfile, UserRole,
  InscriptionRequest, ConnexionRequest, ApiResponse,
} from '../models';

const DASHBOARDS: Record<UserRole, string> = {
  APPRENANT:   '/app',
  FORMATEUR:   '/instructor',
  ADMIN:       '/admin',
  SUPER_ADMIN: '/admin',
};

/**
 * AuthService — gestion complète de l'authentification.
 *
 * État via signals Angular :
 *   currentUser     → profil ou null
 *   isAuthenticated → computed
 *   userRole        → computed
 *   isAdmin         → computed
 *
 * Persistance : sessionStorage (pas localStorage — sécurité XSS).
 * Disparaît à la fermeture du navigateur.
 */
@Injectable({ providedIn: 'root' })
export class AuthService {
  readonly #api    = inject(ApiService);
  readonly #token  = inject(TokenService);
  readonly #router = inject(Router);
  readonly #toast  = inject(ToastService);
  readonly #plat   = inject(PLATFORM_ID);

  readonly currentUser     = signal<UserProfile | null>(this.#restore());
  readonly isAuthenticated = computed(() => this.currentUser() !== null);
  readonly userRole        = computed<UserRole | null>(() => this.currentUser()?.role ?? null);
  readonly isAdmin         = computed(() =>
    this.userRole() === 'ADMIN' || this.userRole() === 'SUPER_ADMIN'
  );
  readonly isSuspended     = computed(() => this.currentUser()?.statut === 'SUSPENDU');

  constructor() {
    if (isPlatformBrowser(this.#plat) && !this.currentUser()) {
      this.#silentRefresh();
    }
  }

  // ── S02 : Inscription ─────────────────────────────────
  register(req: InscriptionRequest): Observable<ApiResponse<AuthResponse>> {
    return this.#api.post<AuthResponse>('/auth/register', req).pipe(
      tap(r => { if (r.success && r.data) this.#onSuccess(r.data); }),
    );
  }

  // ── S03 : Connexion ───────────────────────────────────
  login(req: ConnexionRequest): Observable<ApiResponse<AuthResponse>> {
    return this.#api.post<AuthResponse>('/auth/login', req).pipe(
      tap(r => { if (r.success && r.data) this.#onSuccess(r.data); }),
    );
  }

  // ── Déconnexion ───────────────────────────────────────
  logout(): void {
    this.#api.post('/auth/logout', {}).subscribe({ error: () => {} });
    this.#clear();
    this.#router.navigate(['/auth/connexion']);
  }

  // ── Refresh token (auto depuis intercepteur) ──────────
  refreshToken(): Observable<ApiResponse<{ accessToken: string }>> {
    return this.#api
      .post<{ accessToken: string }>('/auth/refresh', {})
      .pipe(
        tap(r => { if (r.success && r.data) this.#token.set(r.data.accessToken); }),
        catchError(err => {
          this.#clear();
          this.#router.navigate(['/auth/connexion']);
          return throwError(() => err);
        }),
      );
  }

  // ── Redirection post-auth ─────────────────────────────
  redirectToDashboard(): void {
    const r = this.userRole();
    this.#router.navigateByUrl(r ? DASHBOARDS[r] : '/');
  }

  // ── Privé ─────────────────────────────────────────────
  #onSuccess(a: AuthResponse): void {
    this.#token.set(a.accessToken);
    const u: UserProfile = {
      userId: a.userId, prenom: a.prenom, email: a.email,
      role: a.role, photoUrl: null, statut: 'ACTIF',
    };
    this.currentUser.set(u);
    if (isPlatformBrowser(this.#plat)) {
      sessionStorage.setItem('mn_u', JSON.stringify(u));
    }
  }

  #clear(): void {
    this.#token.clear();
    this.currentUser.set(null);
    if (isPlatformBrowser(this.#plat)) sessionStorage.removeItem('mn_u');
  }

  #restore(): UserProfile | null {
    try {
      if (typeof window === 'undefined') return null;
      const s = sessionStorage.getItem('mn_u');
      return s ? (JSON.parse(s) as UserProfile) : null;
    } catch { return null; }
  }

  #silentRefresh(): void {
    this.#api.post<{ accessToken: string }>('/auth/refresh', {}).subscribe({
      next: r => {
        if (r.success && r.data) {
          this.#token.set(r.data.accessToken);
          this.#api.get<UserProfile>('/auth/me').subscribe({
            next: me => {
              if (me.success && me.data) {
                this.currentUser.set(me.data);
                if (isPlatformBrowser(this.#plat)) {
                  sessionStorage.setItem('mn_u', JSON.stringify(me.data));
                }
              }
            },
          });
        }
      },
      error: () => { /* Silence — pas de session active */ },
    });
  }
}
EOF
ok "Services : token · api · toast · auth"

# ── Services feature ──────────────────────────────────────
sec "4/7 — Services feature (cours, progression, paiement, ...)"

cat > "${CORE}/services/course.service.ts" << 'EOF'
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type { ApiResponse, PageResponse, CoursResponse } from '../models';

@Injectable({ providedIn: 'root' })
export class CourseService {
  readonly #api = inject(ApiService);

  // GET /api/v1/cours — S04 catalogue
  getAll(params?: { categorie?: string; niveau?: string; q?: string; page?: number; size?: number }):
    Observable<ApiResponse<PageResponse<CoursResponse>>> {
    return this.#api.getPage<CoursResponse>('/cours', params);
  }

  // GET /api/v1/cours/{id}
  getById(id: string): Observable<ApiResponse<CoursResponse>> {
    return this.#api.get<CoursResponse>(`/cours/${id}`);
  }

  // GET /api/v1/cours/slug/{slug} — S04 détail
  getBySlug(slug: string): Observable<ApiResponse<CoursResponse>> {
    return this.#api.get<CoursResponse>(`/cours/slug/${slug}`);
  }
}
EOF

cat > "${CORE}/services/progression.service.ts" << 'EOF'
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type { ApiResponse, PageResponse, ProgressionResponse, TerminerLeconRequest } from '../models';

@Injectable({ providedIn: 'root' })
export class ProgressionService {
  readonly #api = inject(ApiService);

  // POST /api/v1/progression/cours/{coursId}/commencer — S05
  commencer(coursId: string): Observable<ApiResponse<ProgressionResponse>> {
    return this.#api.post<ProgressionResponse>(`/progression/cours/${coursId}/commencer`, {});
  }

  // POST /api/v1/progression/cours/{coursId}/terminer-lecon — S06
  terminerLecon(coursId: string, req: TerminerLeconRequest): Observable<ApiResponse<ProgressionResponse>> {
    return this.#api.post<ProgressionResponse>(`/progression/cours/${coursId}/terminer-lecon`, req);
  }

  // GET /api/v1/progression — toutes les progressions
  getAll(): Observable<ApiResponse<PageResponse<ProgressionResponse>>> {
    return this.#api.getPage<ProgressionResponse>('/progression');
  }

  // GET /api/v1/progression/cours/{coursId}
  getByCours(coursId: string): Observable<ApiResponse<ProgressionResponse>> {
    return this.#api.get<ProgressionResponse>(`/progression/cours/${coursId}`);
  }
}
EOF

cat > "${CORE}/services/payment.service.ts" << 'EOF'
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type {
  ApiResponse, PageResponse, PaiementResponse,
  EnregistrerPaiementRequest, MoratoireRequest,
} from '../models';

@Injectable({ providedIn: 'root' })
export class PaymentService {
  readonly #api = inject(ApiService);

  // GET paiements de l'apprenant connecté — S16
  getMes(): Observable<ApiResponse<PageResponse<PaiementResponse>>> {
    return this.#api.getPage<PaiementResponse>('/paiements');
  }

  // POST /api/v1/paiements — Admin enregistre paiement cash — S08
  enregistrer(req: EnregistrerPaiementRequest): Observable<ApiResponse<PaiementResponse>> {
    return this.#api.post<PaiementResponse>('/paiements', req);
  }

  // POST /api/v1/paiements/apprenants/{id}/suspendre — S18
  suspendre(apprenantId: string): Observable<ApiResponse<null>> {
    return this.#api.post<null>(`/paiements/apprenants/${apprenantId}/suspendre`, {});
  }

  // POST /api/v1/paiements/apprenants/{id}/reactiver — S18
  reactiver(apprenantId: string): Observable<ApiResponse<null>> {
    return this.#api.post<null>(`/paiements/apprenants/${apprenantId}/reactiver`, {});
  }

  // POST moratoire — S17
  demanderMoratoire(req: MoratoireRequest): Observable<ApiResponse<null>> {
    return this.#api.post<null>('/paiements/moratoire', req);
  }
}
EOF

cat > "${CORE}/services/session.service.ts" << 'EOF'
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type {
  ApiResponse, PageResponse, SessionResponse,
  InscrireSessionRequest, CreneauResponse,
} from '../models';

@Injectable({ providedIn: 'root' })
export class SessionService {
  readonly #api = inject(ApiService);

  // GET /api/v1/sessions/cours/{coursId} — S09
  getByCours(coursId: string): Observable<ApiResponse<PageResponse<SessionResponse>>> {
    return this.#api.getPage<SessionResponse>(`/sessions/cours/${coursId}`);
  }

  // POST /api/v1/sessions/{sessionId}/inscrire — S09
  inscrire(sessionId: string, req: InscrireSessionRequest): Observable<ApiResponse<SessionResponse>> {
    return this.#api.post<SessionResponse>(`/sessions/${sessionId}/inscrire`, req);
  }

  // GET créneaux — S10
  getCreneaux(sessionId: string): Observable<ApiResponse<CreneauResponse[]>> {
    return this.#api.get<CreneauResponse[]>(`/sessions/${sessionId}/creneaux`);
  }
}
EOF

cat > "${CORE}/services/assignment.service.ts" << 'EOF'
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type {
  ApiResponse, PageResponse, DevoirResponse, RenduResponse,
  EnvoyerDevoirRequest, SoumettreRenduRequest, CorrigerRenduRequest,
} from '../models';

@Injectable({ providedIn: 'root' })
export class AssignmentService {
  readonly #api = inject(ApiService);

  // GET /api/v1/devoirs — S11
  getMes(): Observable<ApiResponse<PageResponse<DevoirResponse>>> {
    return this.#api.getPage<DevoirResponse>('/devoirs');
  }

  // POST /api/v1/devoirs/sessions/{sessionId} — S22 (formateur)
  publier(sessionId: string, req: EnvoyerDevoirRequest): Observable<ApiResponse<DevoirResponse>> {
    return this.#api.post<DevoirResponse>(`/devoirs/sessions/${sessionId}`, req);
  }

  // POST /api/v1/devoirs/soumettre — S11 (apprenant)
  soumettre(req: SoumettreRenduRequest): Observable<ApiResponse<null>> {
    return this.#api.post<null>('/devoirs/soumettre', req);
  }

  // PATCH /api/v1/devoirs/rendus/{renduId}/corriger — S23 (formateur)
  corriger(renduId: string, req: CorrigerRenduRequest): Observable<ApiResponse<null>> {
    return this.#api.patch<null>(`/devoirs/rendus/${renduId}/corriger`, req);
  }

  // GET rendus d'une session (formateur)
  getRendus(sessionId: string): Observable<ApiResponse<PageResponse<RenduResponse>>> {
    return this.#api.getPage<RenduResponse>(`/devoirs/sessions/${sessionId}/rendus`);
  }
}
EOF

cat > "${CORE}/services/community.service.ts" << 'EOF'
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type {
  ApiResponse, PageResponse, MessageResponse, PostMessageRequest,
} from '../models';

@Injectable({ providedIn: 'root' })
export class CommunityService {
  readonly #api = inject(ApiService);

  // GET /api/v1/communaute/cours/{coursId}/questions — S12
  getQuestions(coursId: string, params?: { page?: number; size?: number }):
    Observable<ApiResponse<PageResponse<MessageResponse>>> {
    return this.#api.getPage<MessageResponse>(`/communaute/cours/${coursId}/questions`, params);
  }

  // GET /api/v1/communaute/messages/{parentId}/reponses — S12
  getReponses(parentId: string): Observable<ApiResponse<MessageResponse[]>> {
    return this.#api.get<MessageResponse[]>(`/communaute/messages/${parentId}/reponses`);
  }

  // POST /api/v1/communaute/cours/{coursId}/messages — S12
  publier(coursId: string, req: PostMessageRequest): Observable<ApiResponse<MessageResponse>> {
    return this.#api.post<MessageResponse>(`/communaute/cours/${coursId}/messages`, req);
  }
}
EOF

cat > "${CORE}/services/talent.service.ts" << 'EOF'
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type {
  ApiResponse, PageResponse, ProfilTalentResponse, UpdateProfilRequest,
  CertificatResponse, LeaderboardEntry, ReferralResponse, DrawResponse, TicketResponse,
} from '../models';

@Injectable({ providedIn: 'root' })
export class TalentService {
  readonly #api = inject(ApiService);

  // GET /api/v1/talents/me — S14
  getMe(): Observable<ApiResponse<ProfilTalentResponse>> {
    return this.#api.get<ProfilTalentResponse>('/talents/me');
  }

  // GET /api/v1/talents/{apprenantId} — profil public
  getPublic(id: string): Observable<ApiResponse<ProfilTalentResponse>> {
    return this.#api.get<ProfilTalentResponse>(`/talents/${id}`);
  }

  // PATCH profil — S14
  update(req: UpdateProfilRequest): Observable<ApiResponse<ProfilTalentResponse>> {
    return this.#api.patch<ProfilTalentResponse>('/talents/me', req);
  }

  // POST /api/v1/certificats/cours/{coursId}/generer — S13
  genererCertificat(coursId: string): Observable<ApiResponse<CertificatResponse>> {
    return this.#api.post<CertificatResponse>(`/certificats/cours/${coursId}/generer`, {});
  }

  // GET /api/v1/certificats/verify/{code} — vérification publique
  verifierCertificat(code: string): Observable<ApiResponse<CertificatResponse>> {
    return this.#api.get<CertificatResponse>(`/certificats/verify/${code}`);
  }

  // GET classement
  getLeaderboard(params?: { page?: number; size?: number }):
    Observable<ApiResponse<PageResponse<LeaderboardEntry>>> {
    return this.#api.getPage<LeaderboardEntry>('/classement', params);
  }

  // GET parrainage — S15
  getParrainage(): Observable<ApiResponse<ReferralResponse>> {
    return this.#api.get<ReferralResponse>('/parrainage');
  }

  // GET tirage — S24
  getTirage(): Observable<ApiResponse<DrawResponse>> {
    return this.#api.get<DrawResponse>('/tirage');
  }

  // POST acheter ticket — S24
  acheterTicket(drawId: string): Observable<ApiResponse<TicketResponse>> {
    return this.#api.post<TicketResponse>('/tirage', { drawId });
  }
}
EOF

cat > "${CORE}/services/notification.service.ts" << 'EOF'
import { Injectable, inject, signal, computed } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type {
  ApiResponse, PageResponse, NotificationResponse,
} from '../models';

@Injectable({ providedIn: 'root' })
export class NotificationService {
  readonly #api = inject(ApiService);

  readonly unreadCount = signal(0);
  readonly hasUnread   = computed(() => this.unreadCount() > 0);

  // GET /api/v1/notifications
  getAll(): Observable<ApiResponse<PageResponse<NotificationResponse>>> {
    return this.#api.getPage<NotificationResponse>('/notifications');
  }

  // GET /api/v1/notifications/unread
  getUnreadCount(): Observable<ApiResponse<{ count: number }>> {
    return this.#api.get<{ count: number }>('/notifications/unread');
  }

  // PATCH /api/v1/notifications/read-all
  markAllRead(): Observable<ApiResponse<null>> {
    return this.#api.patch<null>('/notifications/read-all', {});
  }
}
EOF

cat > "${CORE}/services/admin.service.ts" << 'EOF'
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type {
  ApiResponse, PageResponse, StatistiquesResponse, ApprenantAdminView,
  InscriptionManuelleRequest, AssignerRoleRequest, CreerCoursRequest, DrawResponse,
} from '../models';

@Injectable({ providedIn: 'root' })
export class AdminService {
  readonly #api = inject(ApiService);

  // GET /api/v1/admin/statistiques — S25
  getStats(): Observable<ApiResponse<StatistiquesResponse>> {
    return this.#api.get<StatistiquesResponse>('/admin/statistiques');
  }

  // GET /api/v1/admin/apprenants — S21
  getApprenants(params?: { q?: string; page?: number; size?: number }):
    Observable<ApiResponse<PageResponse<ApprenantAdminView>>> {
    return this.#api.getPage<ApprenantAdminView>('/admin/apprenants', params);
  }

  // POST /api/v1/admin/apprenants — S21 inscription manuelle
  inscrire(req: InscriptionManuelleRequest): Observable<ApiResponse<ApprenantAdminView>> {
    return this.#api.post<ApprenantAdminView>('/admin/apprenants', req);
  }

  // POST /api/v1/admin/utilisateurs/role — S26
  assignerRole(req: AssignerRoleRequest): Observable<ApiResponse<null>> {
    return this.#api.post<null>('/admin/utilisateurs/role', req);
  }

  // POST /api/v1/admin/cours — S19
  creerCours(req: CreerCoursRequest): Observable<ApiResponse<{ id: string }>> {
    return this.#api.post<{ id: string }>('/admin/cours', req);
  }

  // POST /api/v1/admin/cours/{id}/publier
  publierCours(coursId: string): Observable<ApiResponse<null>> {
    return this.#api.post<null>(`/admin/cours/${coursId}/publier`, {});
  }

  // POST /api/v1/admin/tirage — S24
  configurerTirage(config: Partial<DrawResponse>): Observable<ApiResponse<DrawResponse>> {
    return this.#api.post<DrawResponse>('/admin/tirage', config);
  }
}
EOF
ok "Services feature : course · progression · payment · session · assignment · community · talent · notification · admin"

# ============================================================
# 4. INTERCEPTEURS
# ============================================================
sec "5/7 — Intercepteurs (mock, auth, error)"

# ── mock.interceptor.ts ───────────────────────────────────
cat > "${CORE}/interceptors/mock.interceptor.ts" << 'EOF'
import { HttpInterceptorFn, HttpResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { of, delay } from 'rxjs';
import { environment } from '@env/environment';
import {
  MOCK_AUTH, MOCK_COURS, MOCK_PROGRESSION, MOCK_PAIEMENTS,
  MOCK_SESSIONS, MOCK_DEVOIRS, MOCK_MESSAGES, MOCK_NOTIFICATIONS,
  MOCK_PROFIL, MOCK_LEADERBOARD, MOCK_DRAW, MOCK_REFERRAL,
  MOCK_STATS, MOCK_APPRENANTS_ADMIN, MOCK_USER,
} from '../services/mock.data';

const DELAY = 380;   // ms — simule connexion lente

function wrap<T>(data: T, message = 'OK') {
  return { success: true, data, message, timestamp: new Date().toISOString() };
}
function wrapPage<T>(items: T[], total?: number) {
  return wrap({
    content: items, page: 0, size: items.length,
    totalElements: total ?? items.length,
    totalPages: 1, first: true, last: true,
  });
}

/**
 * MockInterceptor — intercepte toutes les requêtes /api/v1/* quand
 * environment.useMock = true.
 *
 * Pour basculer vers l'API réelle :
 *   src/environments/environment.ts → useMock: false
 *   (aucun autre fichier à modifier)
 *
 * AUTO_FALLBACK : si useMock = false mais que l'API retourne
 *   une liste vide, le MockInterceptor prend le relais pour
 *   ne jamais afficher une page vide en développement.
 */
export const mockInterceptor: HttpInterceptorFn = (req, next) => {
  if (!environment.useMock) return next(req);

  const path   = req.url.split('/api/v1')[1] ?? '';
  const method = req.method;

  // ── Auth ──────────────────────────────────────────────
  if (method === 'POST' && path.includes('/auth/login'))
    return of(new HttpResponse({ status: 200, body: wrap(MOCK_AUTH, 'Connexion réussie') })).pipe(delay(DELAY));
  if (method === 'POST' && path.includes('/auth/register'))
    return of(new HttpResponse({ status: 200, body: wrap(MOCK_AUTH, 'Compte créé') })).pipe(delay(DELAY));
  if (method === 'POST' && path.includes('/auth/refresh'))
    return of(new HttpResponse({ status: 200, body: wrap({ accessToken: 'mock.new.jwt' }) })).pipe(delay(100));
  if (method === 'POST' && (path.includes('/auth/logout') || path.includes('/auth/reset-password') || path.includes('/auth/new-password')))
    return of(new HttpResponse({ status: 200, body: wrap(null, 'OK') })).pipe(delay(DELAY));
  if (method === 'GET' && path === '/auth/me')
    return of(new HttpResponse({ status: 200, body: wrap(MOCK_USER) })).pipe(delay(100));

  // ── Cours ─────────────────────────────────────────────
  if (method === 'GET' && (path === '/cours' || path.startsWith('/cours?')))
    return of(new HttpResponse({ status: 200, body: wrapPage(MOCK_COURS, 6) })).pipe(delay(DELAY));
  if (method === 'GET' && path.startsWith('/cours/slug/'))
    return of(new HttpResponse({ status: 200, body: wrap(MOCK_COURS[0]) })).pipe(delay(DELAY));
  if (method === 'GET' && path.match(/^\/cours\/[^/]+$/))
    return of(new HttpResponse({ status: 200, body: wrap(MOCK_COURS[0]) })).pipe(delay(DELAY));

  // ── Progression ───────────────────────────────────────
  if (method === 'POST' && path.includes('/commencer'))
    return of(new HttpResponse({ status: 200, body: wrap({ ...MOCK_PROGRESSION, pourcentage: 0 }, 'Progression initialisée') })).pipe(delay(DELAY));
  if (method === 'POST' && path.includes('/terminer-lecon'))
    return of(new HttpResponse({ status: 200, body: wrap({ ...MOCK_PROGRESSION, pourcentage: 50, xpGagne: 130 }, '+10 XP !') })).pipe(delay(DELAY));
  if (method === 'GET' && path.startsWith('/progression/cours/'))
    return of(new HttpResponse({ status: 200, body: wrap(MOCK_PROGRESSION) })).pipe(delay(200));
  if (method === 'GET' && (path === '/progression' || path.startsWith('/progression?')))
    return of(new HttpResponse({ status: 200, body: wrapPage([MOCK_PROGRESSION]) })).pipe(delay(DELAY));

  // ── Paiements ─────────────────────────────────────────
  if (method === 'GET' && (path === '/paiements' || path.startsWith('/paiements?')))
    return of(new HttpResponse({ status: 200, body: wrapPage(MOCK_PAIEMENTS) })).pipe(delay(DELAY));
  if (method === 'POST' && path === '/paiements')
    return of(new HttpResponse({ status: 200, body: wrap(MOCK_PAIEMENTS[0], 'Paiement enregistré. Accès activé.') })).pipe(delay(DELAY));
  if (method === 'POST' && (path.includes('/suspendre') || path.includes('/reactiver') || path.includes('/moratoire')))
    return of(new HttpResponse({ status: 200, body: wrap(null, 'Opération effectuée') })).pipe(delay(DELAY));

  // ── Sessions ──────────────────────────────────────────
  if (method === 'GET' && path.startsWith('/sessions'))
    return of(new HttpResponse({ status: 200, body: wrapPage(MOCK_SESSIONS) })).pipe(delay(DELAY));
  if (method === 'POST' && path.includes('/inscrire'))
    return of(new HttpResponse({ status: 200, body: wrap(MOCK_SESSIONS[0], 'Inscription confirmée') })).pipe(delay(DELAY));

  // ── Devoirs ───────────────────────────────────────────
  if (method === 'GET' && (path === '/devoirs' || path.startsWith('/devoirs?')))
    return of(new HttpResponse({ status: 200, body: wrapPage(MOCK_DEVOIRS) })).pipe(delay(DELAY));
  if (method === 'POST' && path.startsWith('/devoirs/sessions/'))
    return of(new HttpResponse({ status: 200, body: wrap(MOCK_DEVOIRS[0], 'Devoir publié') })).pipe(delay(DELAY));
  if (method === 'POST' && path === '/devoirs/soumettre')
    return of(new HttpResponse({ status: 200, body: wrap(null, 'Rendu soumis') })).pipe(delay(DELAY));
  if (method === 'PATCH' && path.includes('/corriger'))
    return of(new HttpResponse({ status: 200, body: wrap(null, 'Correction enregistrée') })).pipe(delay(DELAY));

  // ── Communauté ────────────────────────────────────────
  if (method === 'GET' && path.includes('/communaute'))
    return of(new HttpResponse({ status: 200, body: wrapPage(MOCK_MESSAGES) })).pipe(delay(DELAY));
  if (method === 'POST' && path.includes('/communaute'))
    return of(new HttpResponse({ status: 200, body: wrap(MOCK_MESSAGES[1], 'Message publié') })).pipe(delay(DELAY));

  // ── Notifications ─────────────────────────────────────
  if (method === 'GET' && path === '/notifications')
    return of(new HttpResponse({ status: 200, body: wrapPage(MOCK_NOTIFICATIONS, 4) })).pipe(delay(200));
  if (method === 'GET' && path === '/notifications/unread')
    return of(new HttpResponse({ status: 200, body: wrap({ count: 2 }) })).pipe(delay(100));
  if (method === 'PATCH' && path === '/notifications/read-all')
    return of(new HttpResponse({ status: 200, body: wrap(null, 'Lu') })).pipe(delay(200));

  // ── Talents + Certificats ─────────────────────────────
  if (method === 'GET' && path === '/talents/me')
    return of(new HttpResponse({ status: 200, body: wrap(MOCK_PROFIL) })).pipe(delay(DELAY));
  if (method === 'GET' && path.match(/^\/talents\/.+$/))
    return of(new HttpResponse({ status: 200, body: wrap(MOCK_PROFIL) })).pipe(delay(DELAY));
  if (method === 'PATCH' && path === '/talents/me')
    return of(new HttpResponse({ status: 200, body: wrap(MOCK_PROFIL, 'Profil mis à jour') })).pipe(delay(DELAY));
  if (method === 'POST' && path.includes('/certificats/cours/'))
    return of(new HttpResponse({ status: 200, body: wrap(MOCK_PROFIL.certificats[0], 'Félicitations !') })).pipe(delay(DELAY));
  if (method === 'GET' && path.includes('/certificats/verify/'))
    return of(new HttpResponse({ status: 200, body: wrap({ ...MOCK_PROFIL.certificats[0], prenomApprenant: 'Jean-Paul', nomApprenant: 'Mbemba' }) })).pipe(delay(DELAY));

  // ── Classement + Tirage + Parrainage ──────────────────
  if (method === 'GET' && path === '/classement')
    return of(new HttpResponse({ status: 200, body: wrapPage(MOCK_LEADERBOARD, 247) })).pipe(delay(DELAY));
  if (method === 'GET' && path === '/tirage')
    return of(new HttpResponse({ status: 200, body: wrap(MOCK_DRAW) })).pipe(delay(DELAY));
  if (method === 'POST' && path === '/tirage')
    return of(new HttpResponse({ status: 200, body: wrap({ id: 'ticket-new', drawId: 'draw-001', numero: 'MB-0048', acheteLe: new Date().toISOString() }, 'Ticket acheté ! N° MB-0048') })).pipe(delay(DELAY));
  if (method === 'GET' && path === '/parrainage')
    return of(new HttpResponse({ status: 200, body: wrap(MOCK_REFERRAL) })).pipe(delay(DELAY));

  // ── Admin ─────────────────────────────────────────────
  if (method === 'GET' && path === '/admin/statistiques')
    return of(new HttpResponse({ status: 200, body: wrap(MOCK_STATS) })).pipe(delay(DELAY));
  if (method === 'GET' && path.startsWith('/admin/apprenants'))
    return of(new HttpResponse({ status: 200, body: wrapPage(MOCK_APPRENANTS_ADMIN, 247) })).pipe(delay(DELAY));
  if (method === 'POST' && path === '/admin/apprenants')
    return of(new HttpResponse({ status: 200, body: wrap(MOCK_APPRENANTS_ADMIN[0], 'Apprenant inscrit') })).pipe(delay(DELAY));
  if (method === 'POST' && path === '/admin/utilisateurs/role')
    return of(new HttpResponse({ status: 200, body: wrap(null, 'Rôle mis à jour') })).pipe(delay(DELAY));
  if (method === 'POST' && path === '/admin/cours')
    return of(new HttpResponse({ status: 200, body: wrap({ id: 'c-new' }, 'Cours créé en brouillon') })).pipe(delay(DELAY));
  if (method === 'POST' && path.includes('/admin/cours/') && path.includes('/publier'))
    return of(new HttpResponse({ status: 200, body: wrap(null, 'Cours publié') })).pipe(delay(DELAY));
  if (method === 'POST' && path === '/admin/tirage')
    return of(new HttpResponse({ status: 200, body: wrap(MOCK_DRAW, 'Tirage configuré') })).pipe(delay(DELAY));

  // ── Fallback : laisser passer vers l'API réelle ───────
  return next(req);
};
EOF

# ── auth.interceptor.ts ───────────────────────────────────
cat > "${CORE}/interceptors/auth.interceptor.ts" << 'EOF'
import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError, switchMap, throwError } from 'rxjs';
import { TokenService } from '../services/token.service';
import { AuthService }  from '../services/auth.service';

// Évite les boucles de refresh concurrent
let isRefreshing = false;

const NO_AUTH = ['/auth/login', '/auth/register', '/auth/refresh',
                 '/auth/reset-password', '/auth/new-password'];

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const token = inject(TokenService);
  const auth  = inject(AuthService);

  const skip = NO_AUTH.some(p => req.url.includes(p));
  const tk   = token.get();

  // Ajouter le Bearer token si présent
  const authReq = (tk && !skip)
    ? req.clone({ setHeaders: { Authorization: `Bearer ${tk}` } })
    : req;

  return next(authReq).pipe(
    catchError(err => {
      if (err.status === 401 && !skip && !isRefreshing) {
        isRefreshing = true;
        return auth.refreshToken().pipe(
          switchMap(() => {
            isRefreshing = false;
            const newTk  = token.get();
            const retry  = newTk
              ? req.clone({ setHeaders: { Authorization: `Bearer ${newTk}` } })
              : req;
            return next(retry);
          }),
          catchError(e => { isRefreshing = false; return throwError(() => e); }),
        );
      }
      return throwError(() => err);
    }),
  );
};
EOF

# ── error.interceptor.ts ──────────────────────────────────
cat > "${CORE}/interceptors/error.interceptor.ts" << 'EOF'
import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError, throwError } from 'rxjs';
import { ToastService } from '../services/toast.service';

/** Messages par code HTTP (conformes aux réponses Spring Boot ErrorResponse) */
const HTTP_MESSAGES: Record<number, string> = {
  400: 'Données invalides. Vérifiez votre saisie.',
  403: 'Vous n\'avez pas les droits pour cette action.',
  404: 'Ressource introuvable.',
  409: 'Conflit : cette ressource existe déjà.',
  422: 'Données non traitables.',
  429: 'Trop de requêtes. Réessayez dans quelques secondes.',
  500: 'Erreur serveur. Notre équipe a été informée.',
  502: 'Serveur temporairement indisponible.',
  503: 'Service momentanément indisponible.',
};

export const errorInterceptor: HttpInterceptorFn = (req, next) => {
  const toast = inject(ToastService);

  return next(req).pipe(
    catchError(err => {
      // 401 géré par auth.interceptor (refresh + redirect)
      if (err.status === 401) return throwError(() => err);

      const status: number = err.status ?? 0;
      // Préférer le message de l'API (ErrorResponse.message) si disponible
      const msg = err.error?.message || HTTP_MESSAGES[status] || 'Une erreur est survenue.';

      // Erreurs réseau (status 0 = timeout, connexion refusée)
      if (status === 0) {
        toast.error('Connexion impossible', 'Vérifiez votre connexion internet et réessayez.');
      } else {
        toast.error(msg);
      }

      return throwError(() => err);
    }),
  );
};
EOF
ok "Intercepteurs : mock · auth · error"

# ============================================================
# 5. GUARDS
# ============================================================
sec "6/7 — Guards"

cat > "${CORE}/guards/auth.guard.ts" << 'EOF'
import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from '../services/auth.service';

/** Protège les routes authentifiées. Redirige vers /auth/connexion avec returnUrl. */
export const authGuard: CanActivateFn = (route) => {
  const auth   = inject(AuthService);
  const router = inject(Router);

  if (auth.isAuthenticated()) return true;

  const returnUrl = '/' + route.url.map(s => s.path).join('/');
  return router.createUrlTree(['/auth/connexion'], {
    queryParams: { returnUrl },
  });
};
EOF

cat > "${CORE}/guards/role.guard.ts" << 'EOF'
import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from '../services/auth.service';

/**
 * Vérifie que l'utilisateur a un des rôles requis.
 * Usage dans les routes : data: { roles: ['ADMIN', 'SUPER_ADMIN'] }
 */
export const roleGuard: CanActivateFn = (route) => {
  const auth   = inject(AuthService);
  const router = inject(Router);

  const required: string[] = route.data['roles'] ?? [];
  const role = auth.userRole();

  if (role && required.includes(role)) return true;

  // Redirige vers le dashboard selon le rôle courant
  auth.redirectToDashboard();
  return false;
};
EOF

cat > "${CORE}/guards/guest.guard.ts" << 'EOF'
import { inject } from '@angular/core';
import { CanActivateFn } from '@angular/router';
import { AuthService } from '../services/auth.service';

/** Empêche les utilisateurs connectés d'accéder aux pages auth. */
export const guestGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  if (!auth.isAuthenticated()) return true;
  auth.redirectToDashboard();
  return false;
};
EOF
ok "Guards : auth · role · guest"

# ============================================================
# 6. APP.ROUTES.SERVER.TS
# ============================================================
sec "7/7 — app.routes.server.ts"

cat > src/app/app.routes.server.ts << 'EOF'
import { RenderMode, ServerRoute } from '@angular/ssr';

/**
 * Configuration SSR des routes.
 * • CLIENT : rendu côté client uniquement (pages protégées, états dynamiques)
 * • SERVER : rendu côté serveur (SEO — pages publiques)
 * • PRERENDER : pré-rendu au build
 */
export const serverRoutes: ServerRoute[] = [
  // Pages publiques — rendu serveur pour le SEO
  { path: '',               renderMode: RenderMode.Prerender },
  { path: 'catalogue',      renderMode: RenderMode.Server },
  { path: 'cours/:slug',    renderMode: RenderMode.Server },
  { path: 'politique-confidentialite', renderMode: RenderMode.Prerender },
  { path: 'certificat/verifier/:code', renderMode: RenderMode.Server },

  // Pages auth — côté client uniquement
  { path: 'auth/**',        renderMode: RenderMode.Client },

  // Espaces connectés — côté client uniquement
  { path: 'app/**',         renderMode: RenderMode.Client },
  { path: 'instructor/**',  renderMode: RenderMode.Client },
  { path: 'admin/**',       renderMode: RenderMode.Client },

  // Fallback
  { path: '**',             renderMode: RenderMode.Client },
];
EOF
ok "app.routes.server.ts"

echo ""
echo -e "${G}══════════════════════════════════════════════${N}"
echo -e "${G}  Script 02 terminé ✓                         ${N}"
echo -e "${G}══════════════════════════════════════════════${N}"
echo ""
echo -e "  ${G}✓${N}  models/index.ts       (tous les DTOs Java → TS)"
echo -e "  ${G}✓${N}  mock.data.ts          (données Cameroun réalistes)"
echo -e "  ${G}✓${N}  token.service.ts      (JWT mémoire, SSR-safe)"
echo -e "  ${G}✓${N}  api.service.ts        (retry 3x backoff expo)"
echo -e "  ${G}✓${N}  toast.service.ts      (notifications signal)"
echo -e "  ${G}✓${N}  auth.service.ts       (signals SSR-safe)"
echo -e "  ${G}✓${N}  course / progression / payment / session"
echo -e "  ${G}✓${N}  assignment / community / talent / notification / admin"
echo -e "  ${G}✓${N}  intercepteurs : mock · auth · error"
echo -e "  ${G}✓${N}  guards : auth · role · guest"
echo -e "  ${G}✓${N}  app.routes.server.ts  (SSR render modes)"
echo ""
echo -e "  ${Y}→ Prochaine étape : ./ng03_app_shell.sh${N}"
echo ""
