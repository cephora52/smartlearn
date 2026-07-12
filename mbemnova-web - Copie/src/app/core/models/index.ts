// ============================================================
// MbemNova · Models TypeScript
// 100% identiques aux records Java des scripts s07–s23
// ============================================================

// ── Enveloppes API ─────────────────────────────────────────
export interface ApiResponse<T> {
  success: boolean;
  data: T | null;
  message: string;
  timestamp: string;
}
export interface PageResponse<T> {
  content: T[];
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
  first: boolean;
  last: boolean;
}

// ── Enums Java ─────────────────────────────────────────────
export type UserRole = 'APPRENANT' | 'FORMATEUR' | 'ADMIN' | 'SUPER_ADMIN';
export type StatutCompte = 'ACTIF' | 'SUSPENDU' | 'INACTIF';
export type NiveauCours = 'DEBUTANT' | 'INTERMEDIAIRE' | 'AVANCE';
export type Modalite = 'PRESENTIEL' | 'MEET' | 'HYBRIDE';
export type ModePaiement = 'CASH' | 'MOBILE_MONEY' | 'VIREMENT' | 'ONLINE';
export type StatutPaiement = 'RECU' | 'PARTIEL' | 'EN_ATTENTE' | 'RETARD' | 'ANNULE';
export type TypeRendu = 'TEXTE' | 'FICHIER' | 'LIEN';
export type TypeNotif =
  | 'PAIEMENT_ECHEANCE'
  | 'PAIEMENT_RETARD'
  | 'PAIEMENT_RECU'
  | 'COURS_DEBLOQUE'
  | 'DEVOIR_PUBLIE'
  | 'DEVOIR_CORRIGE'
  | 'REPONSE_COMMUNAUTE'
  | 'PARRAINAGE_ACTIF'
  | 'TIRAGE_RESULTAT'
  | 'CERTIFICAT_GENERE'
  | 'COMPTE_SUSPENDU'
  | 'SYSTEME';
export type StatutMoratoire = 'EN_ATTENTE' | 'ACCORDE' | 'REFUSE';
export type StatutTirage = 'OUVERT' | 'CLOTURE' | 'GAGNANT_SELECTIONNE';

// ── Auth (s07) ─────────────────────────────────────────────
export interface AuthResponse {
  id: string;
  userId: string;
  nom: string;
  prenom: string;
  email: string;
  role: UserRole;
  accessToken: string;
  refreshToken: string;
  expiresAt: string;
  suspended: boolean;
}
export interface UserProfile {
  id: string;
  userId: string;
  nom: string;
  prenom: string;
  email: string;
  role: UserRole;
  photoUrl: string | null;
  statut: StatutCompte;
}
export interface ConnexionRequest {
  email: string;
  motDePasse: string;
  rememberMe: boolean;
}
export interface InscriptionRequest {
  nom: string;
  prenom: string;
  email: string;
  telephone: string;
  motDePasse: string;
  confirmationMotDePasse: string;
  role: string;
  referralCode?: string;
}
export interface ResetPasswordRequest {
  email: string;
}
export interface NouveauMotDePasseRequest {
  token: string;
  nouveauMotDePasse: string;
  confirmation: string;
}

// ── CoursResponse (s21/s23 — thumbnail + durée totale) ─────
export interface CoursResponse {
  id: string;
  titre: string;
  domaine: string;
  descriptionCourte: string;
  description: string;
  prixAffichage: string;
  niveau: NiveauCours;
  langue: string;
  imageCouvertureThumbnail: string | null; // 400px pour les cartes
  imageCouverture?: string | null;
  nbApprenants: number;
  noteMoyenne: number | null;
  nbAvis: number;
  nbLecons: number;
  dureeTotaleMinutes: number;
  prixFcfa: number;
  seuilPaiement: number;
  statut: string;
  slug: string;
  formateurNom?: string;
  categorieNom?: string;
}

// ── CoursDetailResponse (s21 — arbre complet) ──────────────
export interface CoursDetailResponse {
  id: string;
  titre: string;
  descriptionCourte: string;
  descriptionLongue: string;
  description: string;
  prixAffichage: string;
  niveau: NiveauCours;
  langue: string;
  imageCouverture: string | null;
  imageCouvertureThumbnail: string | null;
  slug: string;
  statut: string;
  nbModules: number;
  nbLecons: number;
  dureeTotaleMinutes: number;
  nbApprenants: number;
  noteMoyenne: number | null;
  nbAvis: number;
  prixFcfa: number;
  seuilPaiement: number;
  modules: ModuleDetail[];
  sessionsDisponibles: SessionSommaireResponse[];
  progressionApprenant: ProgressionApprenanteResponse | null;
  formateurNom?: string;
  categorieNom?: string;
}
export interface ModuleDetail {
  id: string;
  titre: string;
  sortOrder: number;
  lecons: LeconDetail[];
}
export interface LeconDetail {
  id: string;
  moduleId: string;
  titre: string;
  typeContenu: 'TEXTE' | 'VIDEO' | 'PDF' | 'QCM';
  contenu: string | null;
  videoUrl: string | null;
  pdfUrl: string | null;
  dureeMinutes: number;
  sortOrder: number;
  aQuiz: boolean;
  xpReward: number;
  estTerminee: boolean;
  estVerrouille: boolean;
  qcm?: any;
}
export interface SessionSommaireResponse {
  id: string;
  dateDebut: string;
  dateFin: string;
  modalite: Modalite;
  lieuOuLien: string | null;
  placesDisponibles: number;
  capaciteMax: number;
}
export interface ProgressionApprenanteResponse {
  pourcentage: number;
  estPaye: boolean;
  seuilAtteint: boolean;
  xpGagne: number;
  derniereLeconTitre: string | null;
}

// ── Progression (s09) ──────────────────────────────────────
export interface ProgressionResponse {
  id: string;
  coursId: string;
  pourcentage: number;
  estPaye: boolean;
  xpGagne: number;
  seuilAtteint: boolean;
  estTermine: boolean;
  dateDebut: string;
  dateCompletion: string | null;
}
export interface TerminerLeconRequest {
  leconId: string;
  nbLeconsTotales: number;
  nbLeconsTerminees: number;
  xpLecon: number;
}

// ── QCM (s20) ──────────────────────────────────────────────
export interface ValiderQCMRequest {
  leconId: string;
  reponse: string;
} // reponse: 'A'|'B'|'C'|'D'
export interface ResultatQCMResponse {
  estCorrect: boolean;
  scoreObtenu: number;
  bonneReponse: string;
  explication: string;
  leconValidee: boolean;
}

// ── Paiements (s10) ────────────────────────────────────────
export interface PaiementResponse {
  id: string;
  apprenantId: string;
  coursId: string;
  montantTotal: string;
  montantPaye: string;
  mode: ModePaiement;
  statut: StatutPaiement;
  accesActive: boolean;
  dateActivation: string | null;
  tranches?: TrancheResponse[];
}
export interface TrancheResponse {
  id: string;
  paiementId: string;
  montant: string;
  echeance: string;
  estPayee: boolean;
  datePaiement: string | null;
}
export interface EnregistrerPaiementRequest {
  apprenantId: string;
  coursId: string;
  montantRecu: number;
  mode: ModePaiement;
  nbTranches: number;
  montantTranche: number;
  echeances: string[];
  noteInterne?: string;
}

// ── Moratoire (s20 — DemanderMoratoireRequest) ─────────────
export interface DemanderMoratoireRequest {
  paiementId: string;
  raison: 'DIFFICULTES_FINANCIERES' | 'PROBLEME_SANTE' | 'AUTRE';
  explication: string;
  nouvelleDateSouhaitee: string;
}
export interface TraiterMoratoireRequest {
  decision: 'ACCORDE' | 'REFUSE';
  justification?: string;
}

// ── Sessions (s11) ─────────────────────────────────────────
export interface SessionResponse {
  id: string;
  coursId: string;
  titre: string;
  modalite: Modalite;
  dateDebut: string;
  dateFin: string;
  capaciteMax: number;
  nbInscrits: number;
  placesRestantes: number;
  lienReunion: string | null;
  lieu: string | null;
  estActive: boolean;
}
export interface CreneauResponse {
  id: string;
  sessionId: string;
  jourSemaine: string;
  heureDebut: string;
  heureFin: string;
  dureeMinutes: number;
  capaciteMax: number;
  placesRestantes: number;
}
export interface ChoisirCreneauxRequest {
  creneauIds: string[];
}

// ── Devoirs (s11 / s21) ────────────────────────────────────
export interface DevoirResponse {
  id: string;
  sessionId: string;
  titre: string;
  consignes: string;
  dateLimite: string;
  dureeEstimeeHeures: number;
  typeRendu: TypeRendu;
  estVerrouille: boolean;
  createdAt: string;
}
export interface DevoirSuiviResponse {
  devoir: DevoirResponse;
  rendu: RenduResponse | null;
  statut: 'NON_COMMENCE' | 'EN_COURS' | 'SOUMIS' | 'CORRIGE' | 'EN_RETARD';
}
export interface RenduResponse {
  id: string;
  devoirId: string;
  apprenantId: string;
  contenu: string;
  lienFichier: string | null;
  soumisLe: string;
  note: number | null;
  commentaire: string | null;
  corrigeLe: string | null;
}
export interface SoumettreRenduRequest {
  devoirId: string;
  contenu: string;
  lienFichier?: string;
}
export interface CorrigerRenduRequest {
  renduId: string;
  note: number;
  commentaire: string;
}

// ── Avis cours (s20 — S4) ──────────────────────────────────
export interface AvisCoursResponse {
  id: string;
  apprenantId: string;
  note: number;
  commentaire: string | null;
  createdAt: string;
  prenomApprenant?: string;
}
export interface LaissserAvisRequest {
  note: number;
  commentaire?: string;
}

// ── Notifications (s12) ────────────────────────────────────
export interface NotificationResponse {
  id: string;
  type: TypeNotif;
  titre: string;
  contenu: string;
  estLue: boolean;
  createdAt: string;
  lienAction: string | null;
}

// ── Communauté (s12) ───────────────────────────────────────
export interface MessageResponse {
  id: string;
  auteurId: string;
  parentId: string | null;
  contenu: string;
  estQuestion: boolean;
  estResolu: boolean;
  nbLikes: number;
  createdAt: string;
  auteurPrenom?: string;
  reponses?: MessageResponse[];
}
export interface PostMessageRequest {
  coursId: string;
  contenu: string;
  parentId?: string;
  estQuestion: boolean;
}

// ── Certificats (s12) ──────────────────────────────────────
export interface CertificatResponse {
  id: string;
  coursId: string;
  codeVerification: string;
  lienPdf: string;
  dateEmission: string;
  coursTitre?: string;
  coursNiveau?: NiveauCours;
}

// ── Profil Talent (s12 / s21) ──────────────────────────────
export interface ProfilTalentResponse {
  id: string;
  prenom: string;
  nom: string;
  telephone: string | null;
  disponiblePourEmploi: boolean;
  lienPortfolio: string | null;
  lienLinkedin: string | null;
  lienGithub: string | null;
  lienCv: string | null;
  bio: string | null;
  xpTotal: number;
  streakJours: number;
  certificats: CertificatResponse[];
  rang?: number;
}
export interface MettreAJourProfilRequest {
  bio?: string;
  titreProfessionnel?: string;
  ville?: string;
  lienLinkedin?: string;
  lienGithub?: string;
  disponiblePourEmploi?: boolean;
  competences?: string[];
}

// ── Gamification / Classement (s13) ───────────────────────
export interface LeaderboardEntry {
  rang: number;
  userId: string;
  prenom: string;
  xpTotal: number;
  streakJours: number;
  estMoi?: boolean;
}
export interface DrawResponse {
  id: string;
  prixTicketFcfa: number;
  dateDrawFormatee: string;
  formationGagnanteTitre: string;
  formationGagnantePrix: string;
  nbTicketsVendus: number;
  statut: StatutTirage;
  gagnantPrenom?: string;
}
export interface TicketResponse {
  id: string;
  drawId: string;
  numero: string;
  acheteLe: string;
}

// ── Parrainage (s15) ───────────────────────────────────────
export interface ParrainageMonLienResponse {
  lienParrainage: string;
  codeParrainage: string;
}
export interface FilleulResponse {
  prenom: string;
  email: string;
  estActif: boolean;
  rejointLe: string;
}
export interface ReferralResponse {
  lienParrainage: string;
  codeParrainage: string;
  nbFilleulsInvites: number;
  nbFilleulsActifs: number;
  xpGagneParrainage: number;
  filleuls: FilleulResponse[];
}

// ── Admin (s13) ────────────────────────────────────────────
export interface StatistiquesResponse {
  totalApprenants: number;
  apprenantsActifs: number;
  paiementsEnAttente: number;
  paiementsEnRetard: number;
  revenusTotal: number;
  revenus: string;
}
export interface InscriptionManuelleRequest {
  prenom: string;
  nom: string;
  email: string;
  telephone: string;
  coursId?: string;
}
export interface AssignerRoleRequest {
  userId: string;
  nouveauRole: UserRole;
  motDePasseAdmin: string;
}
export interface CreerCoursRequest {
  titre: string;
  description: string;
  niveau: NiveauCours;
  categorieId?: string;
  prixFcfa: number;
  seuilPaiement: number;
}
export interface ApprenantAdminView {
  id: string;
  prenom: string;
  nom: string;
  email: string;
  telephone: string | null;
  statut: StatutCompte;
  xpTotal: number;
  nbCoursInscrits: number;
  inscritLe: string;
}
export type LoadingState = 'idle' | 'loading' | 'success' | 'error';
