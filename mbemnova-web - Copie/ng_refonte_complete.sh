#!/usr/bin/env bash
# ============================================================
# MbemNova · REFONTE COMPLÈTE — Conformité API + UX Pro
# ============================================================
# Ce script corrige et complète TOUT :
#   1. models/index.ts   — DTOs 100% identiques à l'API Java
#   2. mock.data.ts      — Données riches + MockSwitcher
#   3. Services          — Tous les endpoints exposés
#   4. mock.interceptor  — Bascule automatique useMock=true/false
#   5. app.ts + app.html — Header public ≠ header connecté
#   6. course-player     — Style HackTheBox / W3Schools
#   7. Mock Switcher UI  — Changer de profil en 1 clic (dev)
# ============================================================
set -euo pipefail
G='\033[0;32m'; B='\033[0;34m'; Y='\033[1;33m'; N='\033[0m'
ok()  { echo -e "${G}  ✓${N} $1"; }
sec() { echo -e "\n${B}▸ $1${N}"; }

[[ ! -f "angular.json" ]] && echo "Lancez depuis la racine" && exit 1

mkdir -p src/app/core/{models,services,guards,interceptors}
mkdir -p src/app/features/learner/course-player
mkdir -p src/app/shared/components/mock-switcher
mkdir -p src/app/layouts

echo -e "\n${B}══════════════════════════════════════════${N}"
echo -e "${B}  MbemNova · Refonte Complète              ${N}"
echo -e "${B}══════════════════════════════════════════${N}\n"

# ============================================================
# 1. MODELS — DTOs 100% identiques à l'API Java
# ============================================================
sec "1/7 — models/index.ts (DTOs exacts API)"

cat > src/app/core/models/index.ts << 'EOF'
// ============================================================
// MbemNova · Models TypeScript
// 100% identiques aux records Java des scripts s07–s23
// ============================================================

// ── Enveloppes API ─────────────────────────────────────────
export interface ApiResponse<T> {
  success:   boolean;
  data:      T | null;
  message:   string;
  timestamp: string;
}
export interface PageResponse<T> {
  content: T[]; page: number; size: number;
  totalElements: number; totalPages: number;
  first: boolean; last: boolean;
}

// ── Enums Java ─────────────────────────────────────────────
export type UserRole        = 'APPRENANT' | 'FORMATEUR' | 'ADMIN' | 'SUPER_ADMIN';
export type StatutCompte    = 'ACTIF' | 'SUSPENDU' | 'INACTIF';
export type NiveauCours     = 'DEBUTANT' | 'INTERMEDIAIRE' | 'AVANCE';
export type Modalite        = 'PRESENTIEL' | 'MEET' | 'HYBRIDE';
export type ModePaiement    = 'CASH' | 'MOBILE_MONEY' | 'VIREMENT' | 'ONLINE';
export type StatutPaiement  = 'RECU' | 'PARTIEL' | 'EN_ATTENTE' | 'RETARD' | 'ANNULE';
export type TypeRendu       = 'TEXTE' | 'FICHIER' | 'LIEN';
export type TypeNotif       = 'PAIEMENT_ECHEANCE'|'PAIEMENT_RETARD'|'PAIEMENT_RECU'
  |'COURS_DEBLOQUE'|'DEVOIR_PUBLIE'|'DEVOIR_CORRIGE'|'REPONSE_COMMUNAUTE'
  |'PARRAINAGE_ACTIF'|'TIRAGE_RESULTAT'|'CERTIFICAT_GENERE'|'COMPTE_SUSPENDU'|'SYSTEME';
export type StatutMoratoire = 'EN_ATTENTE' | 'ACCORDE' | 'REFUSE';
export type StatutTirage    = 'OUVERT' | 'CLOTURE' | 'GAGNANT_SELECTIONNE';

// ── Auth (s07) ─────────────────────────────────────────────
export interface AuthResponse {
  userId: string; prenom: string; email: string; role: UserRole;
  accessToken: string; refreshToken: string; expiresAt: string; suspended: boolean;
}
export interface UserProfile {
  userId: string; prenom: string; email: string; role: UserRole;
  photoUrl: string|null; statut: StatutCompte;
}
export interface ConnexionRequest  { email: string; motDePasse: string; rememberMe: boolean; }
export interface InscriptionRequest{ prenom: string; email: string; motDePasse: string; referralCode?: string; }
export interface ResetPasswordRequest      { email: string; }
export interface NouveauMotDePasseRequest  { token: string; nouveauMotDePasse: string; confirmation: string; }

// ── CoursResponse (s21/s23 — thumbnail + durée totale) ─────
export interface CoursResponse {
  id: string; titre: string; descriptionCourte: string;
  niveau: NiveauCours; langue: string;
  imageCouvertureThumbnail: string|null;  // 400px pour les cartes
  nbApprenants: number; noteMoyenne: number|null; nbAvis: number;
  nbLecons: number; dureeTotaleMinutes: number;
  prixFcfa: number; seuilPaiement: number;
  statut: string; slug: string;
}

// ── CoursDetailResponse (s21 — arbre complet) ──────────────
export interface CoursDetailResponse {
  id: string; titre: string; descriptionCourte: string; descriptionLongue: string;
  niveau: NiveauCours; langue: string;
  imageCouverture: string|null; imageCouvertureThumbnail: string|null; slug: string;
  nbModules: number; nbLecons: number; dureeTotaleMinutes: number;
  nbApprenants: number; noteMoyenne: number|null; nbAvis: number;
  prixFcfa: number; seuilPaiement: number;
  modules: ModuleDetail[];
  sessionsDisponibles: SessionSommaireResponse[];
  progressionApprenant: ProgressionApprenanteResponse|null;
}
export interface ModuleDetail {
  id: string; titre: string; sortOrder: number; lecons: LeconDetail[];
}
export interface LeconDetail {
  id: string; moduleId: string; titre: string;
  typeContenu: 'TEXTE'|'VIDEO'|'PDF'|'QCM';
  contenu: string|null; videoUrl: string|null; pdfUrl: string|null;
  dureeMinutes: number; sortOrder: number;
  aQuiz: boolean; xpReward: number;
  estTerminee: boolean; estVerrouille: boolean;
}
export interface SessionSommaireResponse {
  id: string; dateDebut: string; dateFin: string;
  modalite: Modalite; lieuOuLien: string|null;
  placesDisponibles: number; capaciteMax: number;
}
export interface ProgressionApprenanteResponse {
  pourcentage: number; estPaye: boolean; seuilAtteint: boolean;
  xpGagne: number; derniereLeconTitre: string|null;
}

// ── Progression (s09) ──────────────────────────────────────
export interface ProgressionResponse {
  id: string; coursId: string; pourcentage: number;
  estPaye: boolean; xpGagne: number; seuilAtteint: boolean;
  estTermine: boolean; dateDebut: string; dateCompletion: string|null;
}
export interface TerminerLeconRequest {
  leconId: string; nbLeconsTotales: number; nbLeconsTerminees: number; xpLecon: number;
}

// ── QCM (s20) ──────────────────────────────────────────────
export interface ValiderQCMRequest { leconId: string; reponse: string; }  // reponse: 'A'|'B'|'C'|'D'
export interface ResultatQCMResponse {
  estCorrect: boolean; scoreObtenu: number;
  bonneReponse: string; explication: string; leconValidee: boolean;
}

// ── Paiements (s10) ────────────────────────────────────────
export interface PaiementResponse {
  id: string; apprenantId: string; coursId: string;
  montantTotal: string; montantPaye: string;
  mode: ModePaiement; statut: StatutPaiement;
  accesActive: boolean; dateActivation: string|null;
  tranches?: TrancheResponse[];
}
export interface TrancheResponse {
  id: string; paiementId: string; montant: string;
  echeance: string; estPayee: boolean; datePaiement: string|null;
}
export interface EnregistrerPaiementRequest {
  apprenantId: string; coursId: string; montantRecu: number;
  mode: ModePaiement; nbTranches: number; montantTranche: number;
  echeances: string[]; noteInterne?: string;
}

// ── Moratoire (s20 — DemanderMoratoireRequest) ─────────────
export interface DemanderMoratoireRequest {
  paiementId: string;
  raison: 'DIFFICULTES_FINANCIERES'|'PROBLEME_SANTE'|'AUTRE';
  explication: string; nouvelleDateSouhaitee: string;
}
export interface TraiterMoratoireRequest { decision: 'ACCORDE'|'REFUSE'; justification?: string; }

// ── Sessions (s11) ─────────────────────────────────────────
export interface SessionResponse {
  id: string; coursId: string; titre: string; modalite: Modalite;
  dateDebut: string; dateFin: string; capaciteMax: number;
  nbInscrits: number; placesRestantes: number;
  lienReunion: string|null; lieu: string|null; estActive: boolean;
}
export interface CreneauResponse {
  id: string; sessionId: string; jourSemaine: string;
  heureDebut: string; dureeMinutes: number;
  capaciteMax: number; placesRestantes: number;
}
export interface ChoisirCreneauxRequest { creneauIds: string[]; }

// ── Devoirs (s11 / s21) ────────────────────────────────────
export interface DevoirResponse {
  id: string; sessionId: string; titre: string; consignes: string;
  dateLimite: string; dureeEstimeeHeures: number;
  typeRendu: TypeRendu; estVerrouille: boolean; createdAt: string;
}
export interface DevoirSuiviResponse {
  devoir: DevoirResponse;
  rendu: RenduResponse|null;
  statut: 'NON_COMMENCE'|'EN_COURS'|'SOUMIS'|'CORRIGE'|'EN_RETARD';
}
export interface RenduResponse {
  id: string; devoirId: string; apprenantId: string;
  contenu: string; lienFichier: string|null;
  soumisLe: string; note: number|null; commentaire: string|null; corrigeLe: string|null;
}
export interface SoumettreRenduRequest  { devoirId: string; contenu: string; lienFichier?: string; }
export interface CorrigerRenduRequest   { renduId: string; note: number; commentaire: string; }

// ── Avis cours (s20 — S4) ──────────────────────────────────
export interface AvisCoursResponse {
  id: string; apprenantId: string; note: number;
  commentaire: string|null; createdAt: string;
  prenomApprenant?: string;
}
export interface LaissserAvisRequest { note: number; commentaire?: string; }

// ── Notifications (s12) ────────────────────────────────────
export interface NotificationResponse {
  id: string; type: TypeNotif; titre: string;
  contenu: string; estLue: boolean; createdAt: string; lienAction: string|null;
}

// ── Communauté (s12) ───────────────────────────────────────
export interface MessageResponse {
  id: string; auteurId: string; parentId: string|null;
  contenu: string; estQuestion: boolean; estResolu: boolean;
  nbLikes: number; createdAt: string;
  auteurPrenom?: string; reponses?: MessageResponse[];
}
export interface PostMessageRequest { coursId: string; contenu: string; parentId?: string; estQuestion: boolean; }

// ── Certificats (s12) ──────────────────────────────────────
export interface CertificatResponse {
  id: string; coursId: string; codeVerification: string;
  lienPdf: string; dateEmission: string;
  coursTitre?: string; coursNiveau?: NiveauCours;
}

// ── Profil Talent (s12 / s21) ──────────────────────────────
export interface ProfilTalentResponse {
  id: string; prenom: string; nom: string; telephone: string|null;
  disponiblePourEmploi: boolean;
  lienPortfolio: string|null; lienLinkedin: string|null;
  lienGithub: string|null; lienCv: string|null; bio: string|null;
  xpTotal: number; streakJours: number;
  certificats: CertificatResponse[]; rang?: number;
}
export interface MettreAJourProfilRequest {
  bio?: string; titreProfessionnel?: string; ville?: string;
  lienLinkedin?: string; lienGithub?: string;
  disponiblePourEmploi?: boolean; competences?: string[];
}

// ── Gamification / Classement (s13) ───────────────────────
export interface LeaderboardEntry {
  rang: number; userId: string; prenom: string;
  xpTotal: number; streakJours: number; estMoi?: boolean;
}
export interface DrawResponse {
  id: string; prixTicketFcfa: number; dateDrawFormatee: string;
  formationGagnanteTitre: string; formationGagnantePrix: string;
  nbTicketsVendus: number; statut: StatutTirage; gagnantPrenom?: string;
}
export interface TicketResponse { id: string; drawId: string; numero: string; acheteLe: string; }

// ── Parrainage (s15) ───────────────────────────────────────
export interface ParrainageMonLienResponse { lienParrainage: string; codeParrainage: string; }
export interface FilleulResponse { prenom: string; email: string; estActif: boolean; rejointLe: string; }
export interface ReferralResponse {
  lienParrainage: string; codeParrainage: string;
  nbFilleulsInvites: number; nbFilleulsActifs: number;
  xpGagneParrainage: number; filleuls: FilleulResponse[];
}

// ── Admin (s13) ────────────────────────────────────────────
export interface StatistiquesResponse {
  totalApprenants: number; apprenantsActifs: number;
  paiementsEnAttente: number; paiementsEnRetard: number;
  revenusTotal: number; revenus: string;
}
export interface InscriptionManuelleRequest { prenom: string; nom: string; email: string; telephone: string; coursId?: string; }
export interface AssignerRoleRequest { userId: string; nouveauRole: UserRole; motDePasseAdmin: string; }
export interface CreerCoursRequest { titre: string; description: string; niveau: NiveauCours; categorieId?: string; prixFcfa: number; seuilPaiement: number; }
export interface ApprenantAdminView {
  id: string; prenom: string; nom: string; email: string;
  telephone: string|null; statut: StatutCompte;
  xpTotal: number; nbCoursInscrits: number; inscritLe: string;
}
export type LoadingState = 'idle'|'loading'|'success'|'error';
EOF
ok "models/index.ts — 100% identique API Java"

# ============================================================
# 2. MOCK DATA — Données riches, tous profils testables
# ============================================================
sec "2/7 — mock.data.ts (données riches + tous profils)"

cat > src/app/core/services/mock.data.ts << 'EOF'
// ============================================================
// MbemNova · Mock Data — 4 profils testables
// Modifier MOCK_CURRENT_USER pour changer de profil
// ============================================================
import type {
  AuthResponse, UserProfile, CoursResponse, CoursDetailResponse,
  ProgressionResponse, PaiementResponse, SessionResponse, DevoirSuiviResponse,
  MessageResponse, NotificationResponse, ProfilTalentResponse, LeaderboardEntry,
  DrawResponse, ReferralResponse, StatistiquesResponse, ApprenantAdminView,
  AvisCoursResponse, RenduResponse,
} from '../models';

// ── 4 profils disponibles ──────────────────────────────────
export const MOCK_PROFILES: Record<string, AuthResponse> = {
  APPRENANT: {
    userId: 'u-001', prenom: 'Jean-Paul', email: 'jeanpaul.mbemba@gmail.com',
    role: 'APPRENANT', accessToken: 'mock.apprenant', refreshToken: 'mock.refresh',
    expiresAt: new Date(Date.now() + 86_400_000).toISOString(), suspended: false,
  },
  FORMATEUR: {
    userId: 'u-fmt', prenom: 'Alice', email: 'alice.fouda@mbemnova.com',
    role: 'FORMATEUR', accessToken: 'mock.formateur', refreshToken: 'mock.refresh',
    expiresAt: new Date(Date.now() + 86_400_000).toISOString(), suspended: false,
  },
  ADMIN: {
    userId: 'u-adm', prenom: 'Serge', email: 'serge.admin@mbemnova.com',
    role: 'ADMIN', accessToken: 'mock.admin', refreshToken: 'mock.refresh',
    expiresAt: new Date(Date.now() + 86_400_000).toISOString(), suspended: false,
  },
  SUPER_ADMIN: {
    userId: 'u-sad', prenom: 'MbemNova', email: 'root@mbemnova.com',
    role: 'SUPER_ADMIN', accessToken: 'mock.super', refreshToken: 'mock.refresh',
    expiresAt: new Date(Date.now() + 86_400_000).toISOString(), suspended: false,
  },
};

// ← CHANGER ICI pour tester un autre profil
export let MOCK_AUTH: AuthResponse = MOCK_PROFILES['APPRENANT'];

export const MOCK_USER: UserProfile = {
  userId: MOCK_AUTH.userId, prenom: MOCK_AUTH.prenom,
  email: MOCK_AUTH.email, role: MOCK_AUTH.role,
  photoUrl: null, statut: 'ACTIF',
};

// Fonction pour changer de profil (appelée par MockSwitcher)
export function switchProfile(role: keyof typeof MOCK_PROFILES): void {
  MOCK_AUTH = MOCK_PROFILES[role];
}

// ── Cours liste ────────────────────────────────────────────
export const MOCK_COURS: CoursResponse[] = [
  {
    id: 'c-001', slug: 'dev-web-html-css-js',
    titre: 'Développement Web : HTML, CSS & JavaScript',
    descriptionCourte: 'Maîtrisez les fondamentaux du web avec des projets adaptés au contexte camerounais.',
    niveau: 'DEBUTANT', langue: 'Français',
    imageCouvertureThumbnail: null,
    prixFcfa: 25000, seuilPaiement: 0.30,
    nbApprenants: 142, noteMoyenne: 4.7, nbAvis: 38,
    nbLecons: 24, dureeTotaleMinutes: 720,
    statut: 'PUBLIE', slug: 'dev-web-html-css-js',
  },
  {
    id: 'c-002', slug: 'react-nodejs-fullstack',
    titre: 'React & Node.js — Application Full-Stack',
    descriptionCourte: 'Construisez des applications web modernes. Portfolio de projets inclus.',
    niveau: 'INTERMEDIAIRE', langue: 'Français',
    imageCouvertureThumbnail: null,
    prixFcfa: 45000, seuilPaiement: 0.25,
    nbApprenants: 87, noteMoyenne: 4.9, nbAvis: 21,
    nbLecons: 36, dureeTotaleMinutes: 1080,
    statut: 'PUBLIE', slug: 'react-nodejs-fullstack',
  },
  {
    id: 'c-003', slug: 'python-data-science',
    titre: 'Python & Data Science pour l\'Afrique',
    descriptionCourte: 'Analysez des données africaines avec Python, pandas et matplotlib.',
    niveau: 'DEBUTANT', langue: 'Français',
    imageCouvertureThumbnail: null,
    prixFcfa: 30000, seuilPaiement: 0.30,
    nbApprenants: 203, noteMoyenne: 4.8, nbAvis: 67,
    nbLecons: 28, dureeTotaleMinutes: 840,
    statut: 'PUBLIE', slug: 'python-data-science',
  },
  {
    id: 'c-004', slug: 'android-kotlin',
    titre: 'Mobile Android avec Kotlin',
    descriptionCourte: 'De zéro à la publication sur le Play Store en 8 semaines.',
    niveau: 'INTERMEDIAIRE', langue: 'Français',
    imageCouvertureThumbnail: null,
    prixFcfa: 35000, seuilPaiement: 0.30,
    nbApprenants: 56, noteMoyenne: 4.5, nbAvis: 14,
    nbLecons: 32, dureeTotaleMinutes: 960,
    statut: 'PUBLIE', slug: 'android-kotlin',
  },
  {
    id: 'c-005', slug: 'ui-ux-figma',
    titre: 'UI/UX Design avec Figma',
    descriptionCourte: 'Créez des interfaces modernes. Design thinking, prototypage, tests utilisateurs.',
    niveau: 'DEBUTANT', langue: 'Français',
    imageCouvertureThumbnail: null,
    prixFcfa: 20000, seuilPaiement: 0.40,
    nbApprenants: 178, noteMoyenne: 4.6, nbAvis: 45,
    nbLecons: 20, dureeTotaleMinutes: 600,
    statut: 'PUBLIE', slug: 'ui-ux-figma',
  },
  {
    id: 'c-006', slug: 'devops-docker',
    titre: 'DevOps & Cloud : Docker + CI/CD',
    descriptionCourte: 'Automatisez vos déploiements. Docker, GitHub Actions, VPS.',
    niveau: 'AVANCE', langue: 'Français',
    imageCouvertureThumbnail: null,
    prixFcfa: 50000, seuilPaiement: 0.20,
    nbApprenants: 34, noteMoyenne: 4.9, nbAvis: 8,
    nbLecons: 40, dureeTotaleMinutes: 1200,
    statut: 'PUBLIE', slug: 'devops-docker',
  },
];

// ── CoursDetail (arbre complet) ────────────────────────────
export const MOCK_COURS_DETAIL: CoursDetailResponse = {
  id: 'c-001', titre: 'Développement Web : HTML, CSS & JavaScript',
  descriptionCourte: 'Maîtrisez les fondamentaux du web.',
  descriptionLongue: `
## À qui s'adresse cette formation ?

Cette formation s'adresse aux **débutants complets** souhaitant apprendre le développement web depuis zéro.
Aucune connaissance préalable en programmation n'est requise.

## Ce que vous apprendrez

- Créer des pages HTML structurées et accessibles
- Mettre en forme avec CSS (Flexbox, Grid, animations)
- Rendre vos pages interactives avec JavaScript
- Créer un projet complet : site vitrine professionnel
- Déployer votre site en ligne gratuitement

## Pourquoi cette formation ?

Basée sur des exemples concrets du contexte camerounais, avec des projets pratiques
que vous pourrez montrer à vos futurs employeurs dès la fin de la formation.
  `.trim(),
  niveau: 'DEBUTANT', langue: 'Français',
  imageCouverture: null, imageCouvertureThumbnail: null,
  slug: 'dev-web-html-css-js',
  nbModules: 3, nbLecons: 8, dureeTotaleMinutes: 240,
  nbApprenants: 142, noteMoyenne: 4.7, nbAvis: 38,
  prixFcfa: 25000, seuilPaiement: 0.30,
  sessionsDisponibles: [
    { id: 's-001', dateDebut: new Date(Date.now() + 7*86400000).toISOString(), dateFin: new Date(Date.now() + 37*86400000).toISOString(), modalite: 'MEET', lieuOuLien: 'https://meet.google.com/mbem-dev', placesDisponibles: 7, capaciteMax: 20 },
    { id: 's-002', dateDebut: new Date(Date.now() + 14*86400000).toISOString(), dateFin: new Date(Date.now() + 44*86400000).toISOString(), modalite: 'PRESENTIEL', lieuOuLien: 'Centre MbemNova, Akwa — Douala', placesDisponibles: 0, capaciteMax: 15 },
  ],
  progressionApprenant: { pourcentage: 37, estPaye: false, seuilAtteint: false, xpGagne: 120, derniereLeconTitre: 'CSS : mise en forme' },
  modules: [
    {
      id: 'mod-01', titre: 'Module 1 — Introduction au Web', sortOrder: 1,
      lecons: [
        { id: 'l-01', moduleId: 'mod-01', titre: 'Comment fonctionne Internet ?', typeContenu: 'TEXTE',
          contenu: `<h2>Comment fonctionne Internet ?</h2>
<p>Internet est un réseau mondial de milliards d'appareils connectés entre eux. Chaque appareil possède une <strong>adresse IP</strong> unique, comme une adresse postale.</p>
<h3>Le modèle Client-Serveur</h3>
<p>Quand vous tapez <code>mbemnova.com</code> dans votre navigateur :</p>
<ol>
<li>Votre navigateur (le <strong>client</strong>) envoie une requête HTTP</li>
<li>Un <strong>serveur</strong> reçoit la requête et renvoie du HTML</li>
<li>Votre navigateur affiche la page</li>
</ol>
<h3>Les protocoles essentiels</h3>
<ul>
<li><strong>HTTP/HTTPS</strong> — transfert de pages web</li>
<li><strong>DNS</strong> — traduction des noms de domaine</li>
<li><strong>TCP/IP</strong> — transport fiable des données</li>
</ul>
<div class="tip">💡 <strong>Exemple africain :</strong> Mobile Money utilise ces mêmes protocoles pour sécuriser vos transferts.</div>`,
          videoUrl: null, pdfUrl: null, dureeMinutes: 6, sortOrder: 1, aQuiz: true, xpReward: 10, estTerminee: true, estVerrouille: false },
        { id: 'l-02', moduleId: 'mod-01', titre: 'HTML : structure d\'une page', typeContenu: 'TEXTE',
          contenu: `<h2>HTML — HyperText Markup Language</h2>
<p>Le HTML est le <strong>squelette</strong> de toute page web. Il structure le contenu avec des balises.</p>
<h3>Structure de base</h3>
<pre><code>&lt;!DOCTYPE html&gt;
&lt;html lang="fr"&gt;
  &lt;head&gt;
    &lt;title&gt;Ma page MbemNova&lt;/title&gt;
  &lt;/head&gt;
  &lt;body&gt;
    &lt;h1&gt;Bonjour Douala !&lt;/h1&gt;
    &lt;p&gt;Mon premier site web.&lt;/p&gt;
  &lt;/body&gt;
&lt;/html&gt;</code></pre>
<div class="tip">💡 Créez ce fichier et ouvrez-le dans votre navigateur !</div>`,
          videoUrl: null, pdfUrl: null, dureeMinutes: 8, sortOrder: 2, aQuiz: true, xpReward: 10, estTerminee: true, estVerrouille: false },
        { id: 'l-03', moduleId: 'mod-01', titre: 'CSS : mise en forme', typeContenu: 'TEXTE',
          contenu: `<h2>CSS — Cascading Style Sheets</h2>
<p>Le CSS donne du <strong>style</strong> à votre HTML : couleurs, polices, espacement, mise en page.</p>
<h3>La syntaxe CSS</h3>
<pre><code>/* sélecteur { propriété: valeur } */
h1 {
  color: #2563eb;
  font-size: 2rem;
  text-align: center;
}
.carte {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 4px 6px rgba(0,0,0,0.07);
}</code></pre>`,
          videoUrl: null, pdfUrl: null, dureeMinutes: 7, sortOrder: 3, aQuiz: false, xpReward: 10, estTerminee: false, estVerrouille: false },
      ]
    },
    {
      id: 'mod-02', titre: 'Module 2 — JavaScript Fondamentaux', sortOrder: 2,
      lecons: [
        { id: 'l-04', moduleId: 'mod-02', titre: 'Variables et types de données', typeContenu: 'TEXTE',
          contenu: `<h2>Variables en JavaScript</h2>
<p>Une variable est une <strong>boîte</strong> qui stocke une valeur.</p>
<pre><code>// const : valeur immuable (préféré)
const ville = "Douala";
const prix  = 25000;

// let : valeur modifiable
let score = 0;
score = score + 10;

// Types de données
const texte   = "Bonjour";      // String
const nombre  = 42;             // Number
const vrai    = true;           // Boolean
const tableau = [1, 2, 3];      // Array
const objet   = { nom: "Jean"}; // Object</code></pre>
<div class="tip">💡 <strong>Règle :</strong> Utilisez <code>const</code> par défaut. <code>let</code> seulement si vous devez réassigner.</div>`,
          videoUrl: null, pdfUrl: null, dureeMinutes: 5, sortOrder: 1, aQuiz: true, xpReward: 10, estTerminee: false, estVerrouille: false },
        { id: 'l-05', moduleId: 'mod-02', titre: 'Fonctions', typeContenu: 'TEXTE',
          contenu: `<h2>Les fonctions en JavaScript</h2>
<p>Une fonction est un bloc de code <strong>réutilisable</strong>.</p>
<pre><code>function saluer(prenom) {
  return "Bonjour " + prenom + " !";
}

// Appel
const message = saluer("Jean-Paul");
console.log(message); // "Bonjour Jean-Paul !"

// Fonction fléchée (moderne)
const calculer = (a, b) => a + b;
console.log(calculer(5, 3)); // 8</code></pre>`,
          videoUrl: null, pdfUrl: null, dureeMinutes: 8, sortOrder: 2, aQuiz: true, xpReward: 10, estTerminee: false, estVerrouille: false },
      ]
    },
    {
      id: 'mod-03', titre: 'Module 3 — Projet Pratique', sortOrder: 3,
      lecons: [
        { id: 'l-06', moduleId: 'mod-03', titre: 'Projet : Site vitrine complet', typeContenu: 'TEXTE',
          contenu: '<p>Contenu du projet pratique...</p>',
          videoUrl: null, pdfUrl: null, dureeMinutes: 30, sortOrder: 1, aQuiz: false, xpReward: 30, estTerminee: false, estVerrouille: true },
        { id: 'l-07', moduleId: 'mod-03', titre: 'Déploiement sur Netlify', typeContenu: 'TEXTE',
          contenu: '<p>Déployer votre site gratuitement...</p>',
          videoUrl: null, pdfUrl: null, dureeMinutes: 15, sortOrder: 2, aQuiz: false, xpReward: 20, estTerminee: false, estVerrouille: true },
        { id: 'l-08', moduleId: 'mod-03', titre: 'Révision et quiz final', typeContenu: 'QCM',
          contenu: null, videoUrl: null, pdfUrl: null, dureeMinutes: 10, sortOrder: 3, aQuiz: true, xpReward: 30, estTerminee: false, estVerrouille: true },
      ]
    }
  ],
};

// QCM par leçon
export const MOCK_QCM: Record<string, { question: string; options: Record<string, string>; bonneReponse: string; explication: string }> = {
  'l-01': {
    question: 'Quel protocole est utilisé pour transférer des pages web ?',
    options: { A: 'HTTP/HTTPS', B: 'FTP', C: 'SMTP', D: 'SSH' },
    bonneReponse: 'A',
    explication: 'HTTP (HyperText Transfer Protocol) est le protocole standard pour transférer des pages web entre serveur et navigateur.',
  },
  'l-02': {
    question: 'Quelle balise HTML définit le titre principal visible sur la page ?',
    options: { A: '<title>', B: '<header>', C: '<h1>', D: '<main>' },
    bonneReponse: 'C',
    explication: '<h1> définit le titre principal visible. <title> définit le titre dans l\'onglet du navigateur.',
  },
  'l-04': {
    question: 'Quelle est la différence entre `const` et `let` ?',
    options: { A: '`const` ne peut pas être réassigné', B: '`let` est plus rapide', C: 'Aucune différence', D: '`const` est pour les chaînes' },
    bonneReponse: 'A',
    explication: '`const` crée une liaison immuable : la variable ne peut pas être réassignée. Utilisez `const` par défaut !',
  },
  'l-05': {
    question: 'Que retourne `saluer("Marie")` si la fonction est `const saluer = n => "Bonjour " + n` ?',
    options: { A: '"Bonjour n"', B: '"Bonjour Marie"', C: 'undefined', D: 'Erreur' },
    bonneReponse: 'B',
    explication: 'La fonction reçoit "Marie" comme paramètre n, puis retourne "Bonjour " + "Marie" = "Bonjour Marie".',
  },
};

// ── Progression ────────────────────────────────────────────
export const MOCK_PROGRESSION: ProgressionResponse = {
  id: 'p-001', coursId: 'c-001', pourcentage: 37, estPaye: false,
  xpGagne: 120, seuilAtteint: false, estTermine: false,
  dateDebut: new Date(Date.now() - 7 * 86_400_000).toISOString(), dateCompletion: null,
};

// ── Paiements ──────────────────────────────────────────────
export const MOCK_PAIEMENTS: PaiementResponse[] = [{
  id: 'pay-001', apprenantId: 'u-001', coursId: 'c-001',
  montantTotal: '25 000 FCFA', montantPaye: '15 000 FCFA',
  mode: 'CASH', statut: 'PARTIEL', accesActive: true,
  dateActivation: new Date(Date.now() - 14 * 86_400_000).toISOString(),
  tranches: [
    { id: 't1', paiementId: 'pay-001', montant: '15 000 FCFA', echeance: new Date(Date.now() - 14*86400000).toISOString(), estPayee: true, datePaiement: new Date(Date.now() - 14*86400000).toISOString() },
    { id: 't2', paiementId: 'pay-001', montant: '10 000 FCFA', echeance: new Date(Date.now() + 16*86400000).toISOString(), estPayee: false, datePaiement: null },
  ],
}];

// ── Sessions ───────────────────────────────────────────────
export const MOCK_SESSIONS = [
  { id: 's-001', coursId: 'c-001', titre: 'Dev Web — Session Juin 2025', modalite: 'MEET' as const,
    dateDebut: new Date(Date.now() + 7*86400000).toISOString(), dateFin: new Date(Date.now() + 37*86400000).toISOString(),
    capaciteMax: 20, nbInscrits: 13, placesRestantes: 7,
    lienReunion: 'https://meet.google.com/mbem-dev', lieu: null, estActive: true },
  { id: 's-002', coursId: 'c-001', titre: 'Dev Web — Présentiel Douala', modalite: 'PRESENTIEL' as const,
    dateDebut: new Date(Date.now() + 14*86400000).toISOString(), dateFin: new Date(Date.now() + 44*86400000).toISOString(),
    capaciteMax: 15, nbInscrits: 15, placesRestantes: 0,
    lienReunion: null, lieu: 'Centre MbemNova, Akwa — Douala', estActive: true },
];

// ── Devoirs ────────────────────────────────────────────────
export const MOCK_DEVOIRS_SUIVI: DevoirSuiviResponse[] = [
  {
    devoir: { id: 'd-001', sessionId: 's-001', titre: 'TP1 — Page de profil responsive', consignes: 'Créez une page HTML/CSS présentant votre profil professionnel. Responsive mobile-first.', dateLimite: new Date(Date.now() + 5*86400000).toISOString(), dureeEstimeeHeures: 4, typeRendu: 'LIEN', estVerrouille: false, createdAt: new Date(Date.now() - 2*86400000).toISOString() },
    rendu: null, statut: 'EN_COURS',
  },
  {
    devoir: { id: 'd-002', sessionId: 's-001', titre: 'TP2 — JavaScript interactif', consignes: 'Ajoutez un formulaire de contact avec validation JavaScript.', dateLimite: new Date(Date.now() + 12*86400000).toISOString(), dureeEstimeeHeures: 6, typeRendu: 'LIEN', estVerrouille: true, createdAt: new Date(Date.now() - 86400000).toISOString() },
    rendu: null, statut: 'NON_COMMENCE',
  },
];

// ── Avis cours ─────────────────────────────────────────────
export const MOCK_AVIS: AvisCoursResponse[] = [
  { id: 'av-1', apprenantId: 'u-002', note: 5, commentaire: 'Excellente formation ! Les exemples camerounais rendent tout très concret. J\'ai pu créer mon site en 3 semaines.', createdAt: new Date(Date.now() - 15*86400000).toISOString(), prenomApprenant: 'Diane K.' },
  { id: 'av-2', apprenantId: 'u-003', note: 4, commentaire: 'Très bon contenu, bien structuré. Le formateur répond rapidement dans la communauté.', createdAt: new Date(Date.now() - 8*86400000).toISOString(), prenomApprenant: 'Patrick N.' },
  { id: 'av-3', apprenantId: 'u-004', note: 5, commentaire: 'Parfait pour démarrer. Les QCM aident vraiment à mémoriser. Je recommande !', createdAt: new Date(Date.now() - 3*86400000).toISOString(), prenomApprenant: 'Yvonne B.' },
];

// ── Messages communauté ────────────────────────────────────
export const MOCK_MESSAGES: MessageResponse[] = [
  { id: 'm-001', auteurId: 'u-003', parentId: null, auteurPrenom: 'Patrick N.',
    contenu: 'Comment centrer un div en CSS ? Margin auto ne marche pas dans mon cas.',
    estQuestion: true, estResolu: false, nbLikes: 3,
    createdAt: new Date(Date.now() - 86_400_000).toISOString(),
    reponses: [
      { id: 'm-001-r1', auteurId: 'u-fmt', parentId: 'm-001', auteurPrenom: 'Alice F. (Formatrice)',
        contenu: 'Pour centrer horizontalement et verticalement avec Flexbox : `display: flex; align-items: center; justify-content: center;` sur le parent.',
        estQuestion: false, estResolu: false, nbLikes: 8, createdAt: new Date(Date.now() - 3600000).toISOString() }
    ] },
  { id: 'm-002', auteurId: 'u-002', parentId: null, auteurPrenom: 'Diane K.',
    contenu: 'Quelle est la vraie différence entre `let` et `const` ? Le cours ne l\'explique pas clairement.',
    estQuestion: true, estResolu: true, nbLikes: 8,
    createdAt: new Date(Date.now() - 2 * 86_400_000).toISOString(),
    reponses: [
      { id: 'm-002-r1', auteurId: 'u-fmt', parentId: 'm-002', auteurPrenom: 'Alice F. (Formatrice)',
        contenu: '`const` = référence immuable (ne peut pas être réassignée). `let` = peut être réassignée. En pratique : utilisez `const` par défaut, `let` seulement si vous réassignez.',
        estQuestion: false, estResolu: false, nbLikes: 12, createdAt: new Date(Date.now() - 2*86400000 + 3600000).toISOString() }
    ] },
];

// ── Notifications ──────────────────────────────────────────
export const MOCK_NOTIFICATIONS: NotificationResponse[] = [
  { id: 'n-001', type: 'DEVOIR_PUBLIE', estLue: false, titre: 'Nouveau devoir publié', contenu: 'Alice Fouda a publié : "TP1 — Page de profil responsive"', createdAt: new Date(Date.now() - 3600000).toISOString(), lienAction: '/app/devoirs' },
  { id: 'n-002', type: 'PAIEMENT_ECHEANCE', estLue: false, titre: 'Échéance dans 7 jours', contenu: 'Ta prochaine tranche de 10 000 FCFA est prévue dans 7 jours.', createdAt: new Date(Date.now() - 7200000).toISOString(), lienAction: '/app/paiements' },
  { id: 'n-003', type: 'PARRAINAGE_ACTIF', estLue: true, titre: 'Filleul actif !', contenu: 'Rodrigue vient de terminer son premier module. +200 XP pour toi !', createdAt: new Date(Date.now() - 2*86400000).toISOString(), lienAction: '/app/parrainage' },
  { id: 'n-004', type: 'DEVOIR_CORRIGE', estLue: true, titre: 'Devoir corrigé — 16/20', contenu: 'Ton TP1 a été corrigé. Note : 16/20. Bravo !', createdAt: new Date(Date.now() - 3*86400000).toISOString(), lienAction: '/app/devoirs' },
];

// ── Profil talent ──────────────────────────────────────────
export const MOCK_PROFIL: ProfilTalentResponse = {
  id: 'u-001', prenom: 'Jean-Paul', nom: 'Mbemba',
  telephone: '+237 691 23 45 67', disponiblePourEmploi: true,
  lienPortfolio: null, lienLinkedin: null, lienGithub: null, lienCv: null,
  bio: 'Passionné de développement web. En formation sur MbemNova depuis 3 mois.',
  xpTotal: 2980, streakJours: 9, rang: 5,
  certificats: [{
    id: 'cert-001', coursId: 'c-003', codeVerification: 'MBEM-2025-JP-PY42',
    lienPdf: '/api/v1/certificats/cert-001/pdf',
    dateEmission: new Date(Date.now() - 30 * 86_400_000).toISOString(),
    coursTitre: 'Python & Data Science', coursNiveau: 'DEBUTANT',
  }],
};

// ── Leaderboard ────────────────────────────────────────────
export const MOCK_LEADERBOARD: LeaderboardEntry[] = [
  { rang: 1, userId: 'L1', prenom: 'Serge M.',     xpTotal: 4200, streakJours: 21 },
  { rang: 2, userId: 'L2', prenom: 'Diane K.',     xpTotal: 3850, streakJours: 18 },
  { rang: 3, userId: 'L3', prenom: 'Patrick N.',   xpTotal: 3610, streakJours: 15 },
  { rang: 4, userId: 'L4', prenom: 'Marie-Claire', xpTotal: 3200, streakJours: 12 },
  { rang: 5, userId: 'u-001', prenom: 'Jean-Paul', xpTotal: 2980, streakJours: 9, estMoi: true },
  { rang: 6, userId: 'L6', prenom: 'Esther B.',    xpTotal: 2750, streakJours: 7 },
];

export const MOCK_DRAW: DrawResponse = {
  id: 'draw-001', prixTicketFcfa: 2000, dateDrawFormatee: '1er juin 2025',
  formationGagnanteTitre: 'React & Node.js Full-Stack', formationGagnantePrix: '45 000 FCFA',
  nbTicketsVendus: 47, statut: 'OUVERT',
};

export const MOCK_REFERRAL: ReferralResponse = {
  lienParrainage: 'https://mbemnova.com/inscription?ref=JPMBEMBA42',
  codeParrainage: 'JPMBEMBA42', nbFilleulsInvites: 3, nbFilleulsActifs: 2, xpGagneParrainage: 400,
  filleuls: [
    { prenom: 'Rodrigue', email: 'r***@yahoo.fr',  estActif: true,  rejointLe: new Date(Date.now()-20*86400000).toISOString() },
    { prenom: 'Yvonne',   email: 'y***@gmail.com', estActif: true,  rejointLe: new Date(Date.now()-10*86400000).toISOString() },
    { prenom: 'Fabrice',  email: 'f***@gmail.com', estActif: false, rejointLe: new Date(Date.now()-3*86400000).toISOString() },
  ],
};

export const MOCK_STATS: StatistiquesResponse = {
  totalApprenants: 247, apprenantsActifs: 189,
  paiementsEnAttente: 12, paiementsEnRetard: 5,
  revenusTotal: 3_750_000, revenus: '3 750 000 FCFA',
};

export const MOCK_APPRENANTS: ApprenantAdminView[] = [
  { id: 'u-001', prenom: 'Jean-Paul', nom: 'Mbemba',  email: 'jeanpaul@gmail.com', telephone: '+237 691 23 45 67', statut: 'ACTIF',    xpTotal: 2980, nbCoursInscrits: 2, inscritLe: new Date(Date.now()-45*86400000).toISOString() },
  { id: 'u-002', prenom: 'Diane',     nom: 'Kamga',   email: 'diane@yahoo.fr',     telephone: '+237 677 89 01 23', statut: 'ACTIF',    xpTotal: 3850, nbCoursInscrits: 1, inscritLe: new Date(Date.now()-30*86400000).toISOString() },
  { id: 'u-003', prenom: 'Rodrigue',  nom: 'Ekambi',  email: 'rod@gmail.com',      telephone: null,               statut: 'SUSPENDU', xpTotal:  450, nbCoursInscrits: 1, inscritLe: new Date(Date.now()-60*86400000).toISOString() },
  { id: 'u-004', prenom: 'Yvonne',    nom: 'Beyala',  email: 'yv@gmail.com',       telephone: '+237 655 44 33 22', statut: 'ACTIF',    xpTotal: 1200, nbCoursInscrits: 3, inscritLe: new Date(Date.now()-20*86400000).toISOString() },
  { id: 'u-005', prenom: 'Samuel',    nom: 'Owona',   email: 'sam@hotmail.com',    telephone: '+237 688 77 66 55', statut: 'ACTIF',    xpTotal: 2500, nbCoursInscrits: 2, inscritLe: new Date(Date.now()-15*86400000).toISOString() },
];
EOF
ok "mock.data.ts — données riches + switchProfile()"

# ============================================================
# 3. SERVICES — Tous les endpoints API couverts
# ============================================================
sec "3/7 — Services (QCM, avis, liste-attente, parrainage, moratoire)"

cat > src/app/core/services/course.service.ts << 'EOF'
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type { ApiResponse, PageResponse, CoursResponse, CoursDetailResponse, AvisCoursResponse, LaissserAvisRequest } from '../models';

@Injectable({ providedIn: 'root' })
export class CourseService {
  readonly #api = inject(ApiService);

  // GET /api/v1/cours
  getAll(p?: Record<string,string|number>): Observable<ApiResponse<PageResponse<CoursResponse>>> {
    return this.#api.getPage<CoursResponse>('/cours', p);
  }
  // GET /api/v1/cours/{coursId}
  getById(id: string): Observable<ApiResponse<CoursDetailResponse>> {
    return this.#api.get<CoursDetailResponse>(`/cours/${id}`);
  }
  // GET /api/v1/cours/slug/{slug}
  getBySlug(slug: string): Observable<ApiResponse<CoursDetailResponse>> {
    return this.#api.get<CoursDetailResponse>(`/cours/slug/${slug}`);
  }
  // GET /api/v1/cours/{coursId}/avis  (S4)
  getAvis(coursId: string): Observable<ApiResponse<AvisCoursResponse[]>> {
    return this.#api.get<AvisCoursResponse[]>(`/cours/${coursId}/avis`);
  }
  // POST /api/v1/cours/{coursId}/avis  (S4)
  laisserAvis(coursId: string, req: LaissserAvisRequest): Observable<ApiResponse<string>> {
    return this.#api.post<string>(`/cours/${coursId}/avis`, req);
  }
  // POST /api/v1/cours/{coursId}/liste-attente  (S4)
  rejoindreListeAttente(coursId: string, sessionId?: string): Observable<ApiResponse<null>> {
    const params = sessionId ? `?sessionId=${sessionId}` : '';
    return this.#api.post<null>(`/cours/${coursId}/liste-attente${params}`, {});
  }
}
EOF

cat > src/app/core/services/progression.service.ts << 'EOF'
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type { ApiResponse, PageResponse, ProgressionResponse, TerminerLeconRequest } from '../models';

@Injectable({ providedIn: 'root' })
export class ProgressionService {
  readonly #api = inject(ApiService);
  // POST /api/v1/progression/cours/{coursId}/commencer  (S5)
  commencer(coursId: string): Observable<ApiResponse<ProgressionResponse>> {
    return this.#api.post<ProgressionResponse>(`/progression/cours/${coursId}/commencer`, {});
  }
  // POST /api/v1/progression/cours/{coursId}/terminer-lecon  (S6)
  terminerLecon(coursId: string, req: TerminerLeconRequest): Observable<ApiResponse<ProgressionResponse>> {
    return this.#api.post<ProgressionResponse>(`/progression/cours/${coursId}/terminer-lecon`, req);
  }
  // GET /api/v1/progression
  getAll(): Observable<ApiResponse<PageResponse<ProgressionResponse>>> {
    return this.#api.getPage<ProgressionResponse>('/progression');
  }
  // GET /api/v1/progression/cours/{coursId}
  getByCours(coursId: string): Observable<ApiResponse<ProgressionResponse>> {
    return this.#api.get<ProgressionResponse>(`/progression/cours/${coursId}`);
  }
}
EOF

cat > src/app/core/services/qcm.service.ts << 'EOF'
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type { ApiResponse, ValiderQCMRequest, ResultatQCMResponse } from '../models';

@Injectable({ providedIn: 'root' })
export class QcmService {
  readonly #api = inject(ApiService);
  // POST /api/v1/qcm/lecons/{leconId}/valider  (S6)
  valider(leconId: string, req: ValiderQCMRequest): Observable<ApiResponse<ResultatQCMResponse>> {
    return this.#api.post<ResultatQCMResponse>(`/qcm/lecons/${leconId}/valider`, req);
  }
}
EOF

cat > src/app/core/services/payment.service.ts << 'EOF'
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type { ApiResponse, PageResponse, PaiementResponse, EnregistrerPaiementRequest, DemanderMoratoireRequest, TraiterMoratoireRequest } from '../models';

@Injectable({ providedIn: 'root' })
export class PaymentService {
  readonly #api = inject(ApiService);
  getMes(): Observable<ApiResponse<PageResponse<PaiementResponse>>> { return this.#api.getPage<PaiementResponse>('/paiements'); }
  enregistrer(req: EnregistrerPaiementRequest): Observable<ApiResponse<PaiementResponse>> { return this.#api.post<PaiementResponse>('/paiements', req); }
  suspendre(id: string): Observable<ApiResponse<null>> { return this.#api.post<null>(`/paiements/apprenants/${id}/suspendre`, {}); }
  reactiver(id: string): Observable<ApiResponse<null>> { return this.#api.post<null>(`/paiements/apprenants/${id}/reactiver`, {}); }
  // POST /api/v1/moratoires  (S17)
  demanderMoratoire(req: DemanderMoratoireRequest): Observable<ApiResponse<string>> { return this.#api.post<string>('/moratoires', req); }
  // PATCH /api/v1/moratoires/{id}/decider  (S17 admin)
  deciderMoratoire(id: string, req: TraiterMoratoireRequest): Observable<ApiResponse<null>> { return this.#api.patch<null>(`/moratoires/${id}/decider`, req); }
}
EOF

cat > src/app/core/services/session.service.ts << 'EOF'
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type { ApiResponse, PageResponse, SessionResponse, CreneauResponse, ChoisirCreneauxRequest } from '../models';

@Injectable({ providedIn: 'root' })
export class SessionService {
  readonly #api = inject(ApiService);
  getByCours(coursId: string): Observable<ApiResponse<PageResponse<SessionResponse>>> { return this.#api.getPage<SessionResponse>(`/sessions/cours/${coursId}`); }
  inscrire(sessionId: string, req: { coursId: string }): Observable<ApiResponse<SessionResponse>> { return this.#api.post<SessionResponse>(`/sessions/${sessionId}/inscrire`, req); }
  // GET /api/v1/sessions/{sessionId}/creneaux  (S10)
  getCreneaux(sessionId: string): Observable<ApiResponse<CreneauResponse[]>> { return this.#api.get<CreneauResponse[]>(`/sessions/${sessionId}/creneaux`); }
  // POST /api/v1/sessions/{sessionId}/creneaux  (S10)
  choisirCreneaux(sessionId: string, req: ChoisirCreneauxRequest): Observable<ApiResponse<null>> { return this.#api.post<null>(`/sessions/${sessionId}/creneaux`, req); }
}
EOF

cat > src/app/core/services/assignment.service.ts << 'EOF'
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type { ApiResponse, PageResponse, DevoirSuiviResponse, SoumettreRenduRequest, CorrigerRenduRequest } from '../models';

@Injectable({ providedIn: 'root' })
export class AssignmentService {
  readonly #api = inject(ApiService);
  // GET /api/v1/devoirs/mes-devoirs  (S11)
  getMes(): Observable<ApiResponse<PageResponse<DevoirSuiviResponse>>> { return this.#api.getPage<DevoirSuiviResponse>('/devoirs/mes-devoirs'); }
  // POST /api/v1/devoirs/soumettre  (S11)
  soumettre(req: SoumettreRenduRequest): Observable<ApiResponse<null>> { return this.#api.post<null>('/devoirs/soumettre', req); }
  // PATCH /api/v1/devoirs/rendus/{id}/corriger  (S23)
  corriger(renduId: string, req: CorrigerRenduRequest): Observable<ApiResponse<null>> { return this.#api.patch<null>(`/devoirs/rendus/${renduId}/corriger`, req); }
  // GET /api/v1/devoirs/sessions/{sessionId}/tableau-bord  (S23 formateur)
  getTableauBord(sessionId: string): Observable<ApiResponse<any>> { return this.#api.get<any>(`/devoirs/sessions/${sessionId}/tableau-bord`); }
}
EOF

cat > src/app/core/services/community.service.ts << 'EOF'
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type { ApiResponse, PageResponse, MessageResponse, PostMessageRequest } from '../models';

@Injectable({ providedIn: 'root' })
export class CommunityService {
  readonly #api = inject(ApiService);
  // GET /api/v1/communaute/cours/{coursId}/questions
  getQuestions(coursId: string, p?: Record<string,string|number>): Observable<ApiResponse<PageResponse<MessageResponse>>> { return this.#api.getPage<MessageResponse>(`/communaute/cours/${coursId}/questions`, p); }
  // GET /api/v1/communaute/messages/{parentId}/reponses
  getReponses(parentId: string): Observable<ApiResponse<MessageResponse[]>> { return this.#api.get<MessageResponse[]>(`/communaute/messages/${parentId}/reponses`); }
  // POST /api/v1/communaute/cours/{coursId}/messages
  publier(coursId: string, req: PostMessageRequest): Observable<ApiResponse<MessageResponse>> { return this.#api.post<MessageResponse>(`/communaute/cours/${coursId}/messages`, req); }
  // POST /api/v1/communaute/messages/{messageId}/signaler
  signaler(messageId: string): Observable<ApiResponse<null>> { return this.#api.post<null>(`/communaute/messages/${messageId}/signaler`, {}); }
}
EOF

cat > src/app/core/services/talent.service.ts << 'EOF'
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type { ApiResponse, PageResponse, ProfilTalentResponse, MettreAJourProfilRequest, CertificatResponse, LeaderboardEntry, DrawResponse, TicketResponse, ParrainageMonLienResponse, FilleulResponse } from '../models';

@Injectable({ providedIn: 'root' })
export class TalentService {
  readonly #api = inject(ApiService);
  // GET /api/v1/talents/me
  getMe(): Observable<ApiResponse<ProfilTalentResponse>> { return this.#api.get<ProfilTalentResponse>('/talents/me'); }
  // GET /api/v1/talents/{apprenantId}
  getPublic(id: string): Observable<ApiResponse<ProfilTalentResponse>> { return this.#api.get<ProfilTalentResponse>(`/talents/${id}`); }
  // PUT /api/v1/talents/me  (S14 — PUT pas PATCH dans s21)
  update(req: MettreAJourProfilRequest): Observable<ApiResponse<ProfilTalentResponse>> { return this.#api.put<ProfilTalentResponse>('/talents/me', req); }
  // POST /api/v1/certificats/cours/{coursId}/generer  (S13)
  genererCertificat(coursId: string): Observable<ApiResponse<CertificatResponse>> { return this.#api.post<CertificatResponse>(`/certificats/cours/${coursId}/generer`, {}); }
  // GET /api/v1/certificats/verify/{code}
  verifierCertificat(code: string): Observable<ApiResponse<any>> { return this.#api.get<any>(`/certificats/verify/${code}`); }
  // GET /api/v1/classement
  getLeaderboard(p?: Record<string,string|number>): Observable<ApiResponse<PageResponse<LeaderboardEntry>>> { return this.#api.getPage<LeaderboardEntry>('/classement', p); }
  // GET /api/v1/tirage
  getTirage(): Observable<ApiResponse<DrawResponse>> { return this.#api.get<DrawResponse>('/tirage'); }
  // POST /api/v1/tirage
  acheterTicket(drawId: string): Observable<ApiResponse<TicketResponse>> { return this.#api.post<TicketResponse>('/tirage', { drawId }); }
  // GET /api/v1/parrainage/mon-lien  (S15)
  getMonLien(): Observable<ApiResponse<ParrainageMonLienResponse>> { return this.#api.get<ParrainageMonLienResponse>('/parrainage/mon-lien'); }
  // GET /api/v1/parrainage/mes-filleuls  (S15)
  getMesFilleuls(): Observable<ApiResponse<FilleulResponse[]>> { return this.#api.get<FilleulResponse[]>('/parrainage/mes-filleuls'); }
}
EOF

cat > src/app/core/services/notification.service.ts << 'EOF'
import { Injectable, inject, signal, computed } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type { ApiResponse, PageResponse, NotificationResponse } from '../models';

@Injectable({ providedIn: 'root' })
export class NotificationService {
  readonly #api = inject(ApiService);
  readonly unreadCount = signal(0);
  readonly hasUnread   = computed(() => this.unreadCount() > 0);

  // GET /api/v1/notifications
  getAll(): Observable<ApiResponse<PageResponse<NotificationResponse>>> { return this.#api.getPage<NotificationResponse>('/notifications'); }
  // GET /api/v1/notifications/unread
  getUnreadCount(): Observable<ApiResponse<{count:number}>> { return this.#api.get<{count:number}>('/notifications/unread'); }
  // PATCH /api/v1/notifications/read-all
  markAllRead(): Observable<ApiResponse<null>> { return this.#api.patch<null>('/notifications/read-all', {}); }
}
EOF

cat > src/app/core/services/admin.service.ts << 'EOF'
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type { ApiResponse, PageResponse, StatistiquesResponse, ApprenantAdminView, InscriptionManuelleRequest, AssignerRoleRequest, DrawResponse } from '../models';

@Injectable({ providedIn: 'root' })
export class AdminService {
  readonly #api = inject(ApiService);
  getStats(): Observable<ApiResponse<StatistiquesResponse>> { return this.#api.get<StatistiquesResponse>('/admin/statistiques'); }
  getApprenants(p?: Record<string,string|number>): Observable<ApiResponse<PageResponse<ApprenantAdminView>>> { return this.#api.getPage<ApprenantAdminView>('/admin/apprenants', p); }
  inscrire(req: InscriptionManuelleRequest): Observable<ApiResponse<ApprenantAdminView>> { return this.#api.post<ApprenantAdminView>('/admin/apprenants', req); }
  assignerRole(req: AssignerRoleRequest): Observable<ApiResponse<null>> { return this.#api.post<null>('/admin/utilisateurs/role', req); }
  creerCours(req: any): Observable<ApiResponse<{id:string}>> { return this.#api.post<{id:string}>('/admin/cours', req); }
  publierCours(id: string): Observable<ApiResponse<null>> { return this.#api.post<null>(`/admin/cours/${id}/publier`, {}); }
  configurerTirage(config: Partial<DrawResponse>): Observable<ApiResponse<DrawResponse>> { return this.#api.post<DrawResponse>('/admin/tirage', config); }
  // DELETE /api/v1/utilisateurs/me
  supprimerMonCompte(): Observable<ApiResponse<null>> { return this.#api.delete<null>('/utilisateurs/me'); }
  // GET /api/v1/utilisateurs/me/export
  exporterMesDonnees(): Observable<ApiResponse<any>> { return this.#api.get<any>('/utilisateurs/me/export'); }
}
EOF
ok "Services — tous les endpoints API couverts"

# ============================================================
# 4. MOCK INTERCEPTOR — bascule automatique useMock
# ============================================================
sec "4/7 — mock.interceptor.ts (bascule automatique)"

cat > src/app/core/interceptors/mock.interceptor.ts << 'EOF'
import { HttpInterceptorFn, HttpResponse } from '@angular/common/http';
import { of, delay } from 'rxjs';
import { environment } from '../../../environments/environment';
import {
  MOCK_AUTH, MOCK_COURS, MOCK_COURS_DETAIL, MOCK_PROGRESSION,
  MOCK_PAIEMENTS, MOCK_SESSIONS, MOCK_DEVOIRS_SUIVI, MOCK_MESSAGES,
  MOCK_AVIS, MOCK_NOTIFICATIONS, MOCK_PROFIL, MOCK_LEADERBOARD,
  MOCK_DRAW, MOCK_REFERRAL, MOCK_STATS, MOCK_APPRENANTS, MOCK_QCM,
} from '../services/mock.data';

const D = 350; // délai réseau simulé (ms)
const ok = <T>(data: T, msg = 'OK') => ({ success: true, data, message: msg, timestamp: new Date().toISOString() });
const page = <T>(items: T[], total?: number) => ok({ content: items, page: 0, size: items.length, totalElements: total ?? items.length, totalPages: 1, first: true, last: true });

/**
 * MockInterceptor
 *
 * BASCULE AUTOMATIQUE :
 *   environment.useMock = true  → toutes les requêtes retournent les données mock
 *   environment.useMock = false → les requêtes passent vers l'API Spring Boot
 *
 * Pour changer : modifier src/environments/environment.ts
 *   useMock: false → npm start → connecté à l'API réelle
 */
export const mockInterceptor: HttpInterceptorFn = (req, next) => {
  if (!environment.useMock) return next(req);

  const p = req.url.split('/api/v1')[1] ?? '';
  const m = req.method;

  // ── Auth ──────────────────────────────────────────────────
  if (m === 'POST' && p.includes('/auth/login'))          return r(ok(MOCK_AUTH, 'Connexion réussie'));
  if (m === 'POST' && p.includes('/auth/register'))       return r(ok(MOCK_AUTH, 'Compte créé'));
  if (m === 'POST' && p.includes('/auth/refresh'))        return r(ok({ accessToken: 'mock.refreshed' }));
  if (m === 'POST' && p.includes('/auth/logout'))         return r(ok(null, 'Déconnecté'));
  if (m === 'POST' && p.includes('/auth/reset-password')) return r(ok(null, 'Email envoyé si compte existant'));
  if (m === 'POST' && p.includes('/auth/new-password'))   return r(ok(null, 'Mot de passe mis à jour'));
  if (m === 'GET'  && p === '/auth/me')                   return r(ok({ userId: MOCK_AUTH.userId, prenom: MOCK_AUTH.prenom, email: MOCK_AUTH.email, role: MOCK_AUTH.role, photoUrl: null, statut: 'ACTIF' }));

  // ── Cours ──────────────────────────────────────────────────
  if (m === 'GET' && (p === '/cours' || p.startsWith('/cours?')))         return r(page(MOCK_COURS, 6));
  if (m === 'GET' && p.startsWith('/cours/slug/'))                        return r(ok(MOCK_COURS_DETAIL));
  if (m === 'GET' && p.match(/^\/cours\/[^/]+$/) && !p.includes('/avis') && !p.includes('/liste')) return r(ok(MOCK_COURS_DETAIL));
  if (m === 'GET' && p.includes('/avis'))                                 return r(ok(MOCK_AVIS));
  if (m === 'POST' && p.includes('/avis'))                                return r(ok('av-new', 'Merci pour ton avis !'));
  if (m === 'POST' && p.includes('/liste-attente'))                       return r(ok(null, 'Tu es sur la liste d\'attente.'));

  // ── Progression ────────────────────────────────────────────
  if (m === 'POST' && p.includes('/commencer'))           return r(ok({ ...MOCK_PROGRESSION, pourcentage: 0 }, 'Progression initialisée'));
  if (m === 'POST' && p.includes('/terminer-lecon'))      return r(ok({ ...MOCK_PROGRESSION, pourcentage: MOCK_PROGRESSION.pourcentage + 12, xpGagne: MOCK_PROGRESSION.xpGagne + 10 }, '+10 XP !'));
  if (m === 'GET'  && p.startsWith('/progression/cours')) return r(ok(MOCK_PROGRESSION));
  if (m === 'GET'  && p.startsWith('/progression'))       return r(page([MOCK_PROGRESSION]));

  // ── QCM ───────────────────────────────────────────────────
  if (m === 'POST' && p.includes('/qcm/lecons/')) {
    const body = req.body as { leconId: string; reponse: string } | null;
    const leconId = p.split('/lecons/')[1]?.split('/')[0] ?? '';
    const qcm = MOCK_QCM[leconId];
    if (qcm && body) {
      const estCorrect = body.reponse === qcm.bonneReponse;
      return r(ok({ estCorrect, scoreObtenu: estCorrect ? 100 : 0, bonneReponse: qcm.bonneReponse, explication: qcm.explication, leconValidee: estCorrect }, estCorrect ? '✓ Bonne réponse !' : '✗ Pas tout à fait.'));
    }
    return r(ok({ estCorrect: true, scoreObtenu: 100, bonneReponse: 'A', explication: 'Mock réponse.', leconValidee: true }));
  }

  // ── Paiements ──────────────────────────────────────────────
  if (m === 'GET'  && (p === '/paiements' || p.startsWith('/paiements?'))) return r(page(MOCK_PAIEMENTS));
  if (m === 'POST' && p === '/paiements')                                   return r(ok(MOCK_PAIEMENTS[0], 'Paiement enregistré. Accès activé.'));
  if (m === 'POST' && p.includes('/suspendre'))                             return r(ok(null, 'Compte suspendu'));
  if (m === 'POST' && p.includes('/reactiver'))                             return r(ok(null, 'Compte réactivé'));
  // Moratoires
  if (m === 'POST' && p === '/moratoires')                                  return r(ok('mor-new', 'Demande soumise. L\'équipe te répondra rapidement.'));
  if (m === 'PATCH' && p.includes('/moratoires/') && p.includes('/decider')) return r(ok(null, 'Décision enregistrée'));

  // ── Sessions + Créneaux ────────────────────────────────────
  if (m === 'GET'  && p.startsWith('/sessions'))                           return r(page(MOCK_SESSIONS));
  if (m === 'POST' && p.includes('/inscrire'))                             return r(ok(MOCK_SESSIONS[0], 'Inscription confirmée'));
  if (m === 'GET'  && p.includes('/creneaux'))                             return r(ok([
    { id: 'cr-1', sessionId: 's-001', jourSemaine: 'LUNDI',    heureDebut: '09:00', dureeMinutes: 120, capaciteMax: 10, placesRestantes: 5 },
    { id: 'cr-2', sessionId: 's-001', jourSemaine: 'MERCREDI', heureDebut: '14:00', dureeMinutes: 120, capaciteMax: 10, placesRestantes: 3 },
    { id: 'cr-3', sessionId: 's-001', jourSemaine: 'SAMEDI',   heureDebut: '10:00', dureeMinutes: 120, capaciteMax: 10, placesRestantes: 0 },
  ]));
  if (m === 'POST' && p.includes('/creneaux'))                             return r(ok(null, 'Créneaux enregistrés. Rappel J-1 activé.'));

  // ── Devoirs ────────────────────────────────────────────────
  if (m === 'GET'  && p.includes('/mes-devoirs'))                          return r(page(MOCK_DEVOIRS_SUIVI));
  if (m === 'POST' && p === '/devoirs/soumettre')                          return r(ok(null, 'Rendu soumis'));
  if (m === 'PATCH' && p.includes('/corriger'))                            return r(ok(null, 'Correction enregistrée'));
  if (m === 'GET'  && p.includes('/tableau-bord'))                         return r(ok({ total: 5, corriges: 3, enAttente: 2 }));

  // ── Communauté ─────────────────────────────────────────────
  if (m === 'GET'  && p.includes('/communaute') && p.includes('/questions')) return r(page(MOCK_MESSAGES));
  if (m === 'GET'  && p.includes('/reponses'))                               return r(ok(MOCK_MESSAGES[0].reponses ?? []));
  if (m === 'POST' && p.includes('/communaute'))                             return r(ok(MOCK_MESSAGES[1], 'Message publié'));
  if (m === 'POST' && p.includes('/signaler'))                               return r(ok(null, 'Message signalé'));

  // ── Notifications ──────────────────────────────────────────
  if (m === 'GET'  && p === '/notifications')                               return r(page(MOCK_NOTIFICATIONS));
  if (m === 'GET'  && p === '/notifications/unread')                        return r(ok({ count: MOCK_NOTIFICATIONS.filter(n => !n.estLue).length }));
  if (m === 'PATCH' && p === '/notifications/read-all')                     return r(ok(null, 'Lu'));

  // ── Talents + Certificats + Classement ────────────────────
  if (m === 'GET'  && p === '/talents/me')                                  return r(ok(MOCK_PROFIL));
  if (m === 'GET'  && p.match(/^\/talents\/.+$/))                          return r(ok(MOCK_PROFIL));
  if (m === 'PUT'  && p === '/talents/me')                                  return r(ok(MOCK_PROFIL, 'Profil mis à jour'));
  if (m === 'POST' && p.includes('/certificats/cours/'))                    return r(ok(MOCK_PROFIL.certificats[0], 'Félicitations ! Certificat généré.'));
  if (m === 'GET'  && p.includes('/certificats/verify/'))                   return r(ok({ ...MOCK_PROFIL.certificats[0], prenomApprenant: 'Jean-Paul', nomApprenant: 'Mbemba' }));
  if (m === 'GET'  && p === '/classement')                                  return r(page(MOCK_LEADERBOARD, 247));

  // ── Tirage + Parrainage ─────────────────────────────────────
  if (m === 'GET'  && p === '/tirage')                                       return r(ok(MOCK_DRAW));
  if (m === 'POST' && p === '/tirage')                                       return r(ok({ id: 'ticket-new', drawId: 'draw-001', numero: 'MB-0048', acheteLe: new Date().toISOString() }, 'Ticket acheté ! N° MB-0048'));
  if (m === 'GET'  && p === '/parrainage/mon-lien')                          return r(ok({ lienParrainage: MOCK_REFERRAL.lienParrainage, codeParrainage: MOCK_REFERRAL.codeParrainage }));
  if (m === 'GET'  && p === '/parrainage/mes-filleuls')                      return r(ok(MOCK_REFERRAL.filleuls));

  // ── Admin ──────────────────────────────────────────────────
  if (m === 'GET'  && p === '/admin/statistiques')                          return r(ok(MOCK_STATS));
  if (m === 'GET'  && p.startsWith('/admin/apprenants'))                    return r(page(MOCK_APPRENANTS, 247));
  if (m === 'POST' && p === '/admin/apprenants')                            return r(ok(MOCK_APPRENANTS[0], 'Apprenant inscrit'));
  if (m === 'POST' && p === '/admin/utilisateurs/role')                     return r(ok(null, 'Rôle mis à jour'));
  if (m === 'POST' && p === '/admin/cours')                                 return r(ok({ id: 'c-new' }, 'Cours créé en brouillon'));
  if (m === 'POST' && p.includes('/publier'))                               return r(ok(null, 'Cours publié'));
  if (m === 'POST' && p === '/admin/tirage')                                return r(ok(MOCK_DRAW, 'Tirage configuré'));

  // ── Utilisateurs (RGPD) ────────────────────────────────────
  if (m === 'DELETE' && p === '/utilisateurs/me')                           return r(ok(null, 'Compte supprimé'));
  if (m === 'GET'    && p === '/utilisateurs/me/export')                    return r(ok({ message: 'Export en cours, tu recevras un email.' }));

  // Fallback → passer à l'API réelle
  return next(req);
};

function r<T>(body: T) {
  return of(new HttpResponse({ status: 200, body })).pipe(delay(D));
}
EOF
ok "mock.interceptor.ts — couverture 100% endpoints"

# ============================================================
# 5. MOCK SWITCHER — Composant UI changement de profil (DEV)
# ============================================================
sec "5/7 — MockSwitcherComponent"

cat > src/app/shared/components/mock-switcher/mock-switcher.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject,
  signal, PLATFORM_ID, OnInit,
} from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { Router } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';
import { MOCK_PROFILES, switchProfile } from '../../../core/services/mock.data';
import type { UserRole } from '../../../core/models';

/**
 * MockSwitcherComponent — visible UNIQUEMENT en mode mock (DEV).
 *
 * Permet de switcher entre les 4 profils en 1 clic :
 *   APPRENANT · FORMATEUR · ADMIN · SUPER_ADMIN
 *
 * Placé en bas à gauche de l'écran — ne gêne pas l'UI.
 */
@Component({
  selector: 'app-mock-switcher',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (visible()) {
      <div class="fixed bottom-4 left-4 z-[490] animate-fade-up"
           role="complementary" aria-label="Sélecteur de profil (développement)">

        @if (open()) {
          <!-- Panel profils -->
          <div class="mb-2 bg-slate-900 border border-slate-700 rounded-2xl p-3
                      shadow-2xl min-w-52 animate-slide-right">
            <p class="text-xs font-semibold text-slate-400 uppercase tracking-wide mb-2.5 px-1">
              🎭 Changer de profil
            </p>
            <div class="space-y-1">
              @for (p of profiles; track p.role) {
                <button (click)="switchTo(p.role)"
                        [class]="'w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm
                                  transition-colors text-left '
                                  + (currentRole() === p.role
                                  ? 'bg-blue-600 text-white'
                                  : 'text-slate-300 hover:bg-slate-800')">
                  <span class="text-lg shrink-0" aria-hidden="true">{{ p.icon }}</span>
                  <div class="flex-1 min-w-0">
                    <p class="font-semibold truncate">{{ p.label }}</p>
                    <p class="text-xs opacity-70 truncate">{{ p.email }}</p>
                  </div>
                  @if (currentRole() === p.role) {
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                         stroke="currentColor" stroke-width="3" aria-label="Profil actif">
                      <polyline points="20 6 9 17 4 12"/>
                    </svg>
                  }
                </button>
              }
            </div>
            <div class="border-t border-slate-700 mt-2.5 pt-2.5 px-1">
              <p class="text-xs text-slate-500 leading-relaxed">
                Données mock actives.<br>
                Pour l'API réelle : <code class="text-amber-400">useMock: false</code>
              </p>
            </div>
          </div>
        }

        <!-- Bouton toggle -->
        <button (click)="open.set(!open())"
                class="flex items-center gap-2 px-3 py-2 rounded-xl text-xs font-semibold
                       shadow-lg border transition-all"
                [class]="open()
                  ? 'bg-slate-700 border-slate-600 text-white'
                  : 'bg-amber-100 border-amber-300 text-amber-800 hover:bg-amber-200'"
                aria-label="Ouvrir le sélecteur de profil">
          <div class="w-2 h-2 rounded-full bg-amber-500 animate-pulse shrink-0" aria-hidden="true"></div>
          <span>{{ currentIcon() }} {{ currentRole() }}</span>
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor"
               stroke-width="2.5" class="transition-transform"
               [class.rotate-180]="open()" aria-hidden="true">
            <polyline points="6 9 12 15 18 9"/>
          </svg>
        </button>
      </div>
    }
  `,
})
export class MockSwitcherComponent implements OnInit {
  readonly #auth     = inject(AuthService);
  readonly #router   = inject(Router);
  readonly #platform = inject(PLATFORM_ID);

  readonly visible    = signal(false);
  readonly open       = signal(false);
  readonly currentRole = () => this.#auth.currentUser()?.role ?? 'APPRENANT';

  readonly profiles = [
    { role: 'APPRENANT'  as UserRole, label: 'Apprenant',   icon: '🎓', email: 'jeanpaul@gmail.com' },
    { role: 'FORMATEUR'  as UserRole, label: 'Formateur',   icon: '👨‍🏫', email: 'alice@mbemnova.com' },
    { role: 'ADMIN'      as UserRole, label: 'Admin',       icon: '🛡️', email: 'serge@mbemnova.com' },
    { role: 'SUPER_ADMIN'as UserRole, label: 'Super Admin', icon: '👑', email: 'root@mbemnova.com' },
  ];

  currentIcon(): string {
    return this.profiles.find(p => p.role === this.currentRole())?.icon ?? '👤';
  }

  ngOnInit(): void {
    if (!isPlatformBrowser(this.#platform)) return;
    // Visible seulement si useMock est actif
    import('../../../../environments/environment').then(env => {
      this.visible.set(env.environment.useMock === true);
    }).catch(() => {});
  }

  switchTo(role: UserRole): void {
    switchProfile(role);
    const authData = MOCK_PROFILES[role];
    // Forcer la mise à jour du signal currentUser
    (this.#auth as any).currentUser.set({
      userId: authData.userId, prenom: authData.prenom,
      email: authData.email, role: authData.role,
      photoUrl: null, statut: 'ACTIF',
    });
    this.open.set(false);
    // Redirection vers le dashboard du rôle
    const routes: Record<UserRole, string> = {
      APPRENANT: '/app', FORMATEUR: '/instructor',
      ADMIN: '/admin', SUPER_ADMIN: '/admin',
    };
    this.#router.navigateByUrl(routes[role]);
  }
}
EOF
ok "mock-switcher.component.ts"

# ============================================================
# 6. COURSE PLAYER — Style HackTheBox/W3Schools
# ============================================================
sec "6/7 — course-player.component.ts (HTB-style)"

cat > src/app/features/learner/course-player/course-player.component.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject,
  signal, computed, input, OnInit, OnDestroy, PLATFORM_ID,
} from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { RouterLink } from '@angular/router';
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';
import { CourseService }      from '../../../core/services/course.service';
import { ProgressionService } from '../../../core/services/progression.service';
import { QcmService }         from '../../../core/services/qcm.service';
import { ToastService }       from '../../../core/services/toast.service';
import type { CoursDetailResponse, ModuleDetail, LeconDetail } from '../../../core/models';
import { MOCK_COURS_DETAIL, MOCK_QCM } from '../../../core/services/mock.data';

@Component({
  selector: 'app-course-player',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  styles: [`
    /* Prose styles pour le contenu des leçons */
    .lesson-content h2 { font-size: 1.4rem; font-weight: 700; color: #e2e8f0; margin: 1.5rem 0 0.75rem; }
    .lesson-content h3 { font-size: 1.1rem; font-weight: 600; color: #cbd5e1; margin: 1.25rem 0 0.5rem; }
    .lesson-content p  { color: #94a3b8; line-height: 1.75; margin-bottom: 1rem; }
    .lesson-content ul, .lesson-content ol { color: #94a3b8; padding-left: 1.5rem; margin-bottom: 1rem; line-height: 1.75; }
    .lesson-content li { margin-bottom: 0.25rem; }
    .lesson-content strong { color: #e2e8f0; font-weight: 600; }
    .lesson-content code {
      background: #1e293b; color: #7dd3fc;
      padding: 0.15rem 0.4rem; border-radius: 4px;
      font-family: 'JetBrains Mono', monospace; font-size: 0.875rem;
    }
    .lesson-content pre {
      background: #0f172a; border: 1px solid #1e293b;
      border-radius: 10px; padding: 1.25rem 1.5rem;
      overflow-x: auto; margin: 1.25rem 0;
    }
    .lesson-content pre code { background: none; color: #7dd3fc; padding: 0; }
    .lesson-content .tip {
      background: #1e293b; border-left: 3px solid #2563eb;
      padding: 0.75rem 1rem; border-radius: 0 8px 8px 0;
      color: #94a3b8; margin: 1.25rem 0;
    }
  `],
  template: `
<div class="flex flex-col h-screen bg-slate-950 overflow-hidden">

  <!-- ── TOP BAR (style HackTheBox) ────────────────────── -->
  <header class="h-14 bg-slate-900 border-b border-slate-800 flex items-center px-4 gap-3 shrink-0 z-30">
    <!-- Back + titre -->
    <a routerLink="/catalogue"
       class="flex items-center gap-1.5 text-slate-400 hover:text-white transition-colors text-sm shrink-0">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
      <span class="hidden sm:inline">Catalogue</span>
    </a>
    <div class="w-px h-5 bg-slate-700" aria-hidden="true"></div>
    <h1 class="text-sm font-semibold text-slate-200 flex-1 truncate">
      @if (detail()) { {{ detail()!.titre }} }
      @else { <span class="shimmer h-4 rounded w-48 inline-block"></span> }
    </h1>

    <!-- Progression globale -->
    @if (progression()) {
      <div class="flex items-center gap-2.5 shrink-0">
        <div class="w-32 h-1.5 bg-slate-700 rounded-full overflow-hidden hidden sm:block">
          <div class="h-full bg-blue-500 rounded-full transition-all duration-500"
               [style.width.%]="progression()!.pourcentage"></div>
        </div>
        <span class="text-xs font-bold text-blue-400">{{ progression()!.pourcentage }}%</span>
      </div>
    }

    <!-- XP gagné -->
    @if (totalXP() > 0) {
      <div class="flex items-center gap-1.5 bg-amber-500/10 border border-amber-500/20
                  rounded-lg px-2.5 py-1 shrink-0">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="#f59e0b" aria-hidden="true"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
        <span class="text-xs font-bold text-amber-400">{{ totalXP() }} XP</span>
      </div>
    }

    <!-- Burger mobile -->
    <button (click)="sidebarOpen.set(!sidebarOpen())"
            class="lg:hidden p-1.5 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition-colors"
            [attr.aria-expanded]="sidebarOpen()" aria-label="Sommaire">
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
        <line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/>
      </svg>
    </button>
  </header>

  <!-- ── CORPS ──────────────────────────────────────────── -->
  <div class="flex flex-1 overflow-hidden">

    <!-- ── SIDEBAR MODULES (style HTB) ───────────────────── -->
    <aside [class]="'w-72 xl:w-80 bg-slate-900 border-r border-slate-800 flex flex-col overflow-y-auto shrink-0 '
                   + 'fixed inset-y-14 left-0 z-20 transition-transform duration-300 lg:static lg:inset-auto lg:translate-x-0 '
                   + (sidebarOpen() ? 'translate-x-0' : '-translate-x-full')"
           aria-label="Sommaire du cours">

      <!-- Header sidebar -->
      <div class="p-4 border-b border-slate-800">
        <p class="text-xs font-semibold text-slate-400 uppercase tracking-wide">Contenu du cours</p>
        @if (detail()) {
          <p class="text-xs text-slate-500 mt-1">
            {{ detail()!.nbLecons }} leçons · {{ Math.floor(detail()!.dureeTotaleMinutes / 60) }}h{{ detail()!.dureeTotaleMinutes % 60 ? detail()!.dureeTotaleMinutes % 60 + 'min' : '' }}
          </p>
        }
      </div>

      @if (!detail()) {
        <div class="p-4 space-y-3">
          @for (_ of [1,2,3]; track $_) {
            <div class="shimmer h-8 rounded-lg"></div>
          }
        </div>
      }

      @if (detail()) {
        <nav class="flex-1 py-2" aria-label="Modules et leçons">
          @for (mod of detail()!.modules; track mod.id; let mi = $index) {
            <div class="mb-1">
              <!-- En-tête module -->
              <button (click)="toggleModule(mod.id)"
                      class="flex items-center gap-2.5 w-full px-4 py-3 text-left
                             hover:bg-slate-800/50 transition-colors group"
                      [attr.aria-expanded]="isModuleOpen(mod.id)">
                <!-- Icône complété/non -->
                <div [class]="'w-5 h-5 rounded-full border-2 flex items-center justify-center shrink-0 transition-colors '
                              + (isModuleComplete(mod)
                              ? 'bg-green-500 border-green-500'
                              : 'border-slate-600 group-hover:border-slate-500')">
                  @if (isModuleComplete(mod)) {
                    <svg width="9" height="9" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="3.5" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
                  }
                </div>
                <span class="text-xs font-semibold text-slate-300 flex-1 leading-snug">
                  {{ mi + 1 }}. {{ mod.titre }}
                </span>
                <!-- Stats module -->
                <span class="text-xs text-slate-600 shrink-0">
                  {{ mod.lecons.filter(l => l.estTerminee).length }}/{{ mod.lecons.length }}
                </span>
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#64748b"
                     stroke-width="2" class="shrink-0 transition-transform"
                     [class.rotate-180]="isModuleOpen(mod.id)" aria-hidden="true">
                  <polyline points="6 9 12 15 18 9"/>
                </svg>
              </button>

              <!-- Leçons -->
              @if (isModuleOpen(mod.id)) {
                <div class="ml-0 border-l-2 border-slate-800 ml-6 pl-0 pb-1">
                  @for (lecon of mod.lecons; track lecon.id; let li = $index) {
                    <button (click)="!lecon.estVerrouille && selectLecon(lecon)"
                            [disabled]="lecon.estVerrouille"
                            class="flex items-center gap-2.5 w-full pl-5 pr-3 py-2.5 text-left
                                   text-xs transition-colors"
                            [class]="activeLecon()?.id === lecon.id
                              ? 'bg-blue-600/20 text-blue-300 border-r-2 border-blue-500'
                              : lecon.estVerrouille
                              ? 'text-slate-600 cursor-not-allowed'
                              : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/30'"
                            [attr.aria-current]="activeLecon()?.id === lecon.id ? 'true' : null">

                      <!-- Icône état -->
                      @if (lecon.estTerminee) {
                        <div class="w-4 h-4 rounded-full bg-green-500/20 flex items-center justify-center shrink-0">
                          <svg width="8" height="8" viewBox="0 0 24 24" fill="none" stroke="#22c55e" stroke-width="3" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
                        </div>
                      } @else if (activeLecon()?.id === lecon.id) {
                        <div class="w-4 h-4 rounded-full bg-blue-500/20 flex items-center justify-center shrink-0">
                          <div class="w-2 h-2 bg-blue-400 rounded-full animate-pulse"></div>
                        </div>
                      } @else if (lecon.estVerrouille) {
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="shrink-0" aria-label="Verrouillée">
                          <rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>
                        </svg>
                      } @else {
                        <!-- Icône type contenu -->
                        @if (lecon.typeContenu === 'VIDEO') {
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="shrink-0" aria-hidden="true"><polygon points="5 3 19 12 5 21 5 3"/></svg>
                        } @else if (lecon.typeContenu === 'QCM') {
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="shrink-0" aria-hidden="true"><circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
                        } @else {
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="shrink-0" aria-hidden="true"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
                        }
                      }

                      <span class="flex-1 leading-snug">{{ lecon.titre }}</span>

                      <!-- Durée + XP -->
                      <div class="flex items-center gap-1.5 shrink-0 text-slate-600">
                        <span>{{ lecon.dureeMinutes }}m</span>
                      </div>
                    </button>
                  }
                </div>
              }
            </div>
          }
        </nav>
      }
    </aside>

    <!-- Backdrop mobile -->
    @if (sidebarOpen()) {
      <div class="fixed inset-0 bg-black/60 z-10 lg:hidden"
           (click)="sidebarOpen.set(false)" aria-hidden="true"></div>
    }

    <!-- ── CONTENU LEÇON ──────────────────────────────────── -->
    <main class="flex-1 overflow-y-auto bg-slate-950 min-w-0" id="lesson-content">

      <!-- MUR DE PAIEMENT (S7) -->
      @if (showPaywall()) {
        <div class="flex items-center justify-center min-h-full p-6">
          <div class="max-w-lg w-full text-center animate-scale-in">
            <!-- Illustration -->
            <div class="w-24 h-24 rounded-3xl bg-blue-600/10 border border-blue-500/20
                        flex items-center justify-center mx-auto mb-6">
              <svg width="44" height="44" viewBox="0 0 24 24" fill="none" stroke="#3b82f6" stroke-width="1.5" aria-hidden="true">
                <rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>
                <circle cx="12" cy="16" r="1.5" fill="#3b82f6"/>
              </svg>
            </div>
            <h2 class="text-2xl font-black text-white mb-3">Continuez votre apprentissage</h2>
            <p class="text-slate-400 mb-2">
              Vous avez complété <span class="text-blue-400 font-bold">{{ progression()?.pourcentage ?? 0 }}%</span> du cours gratuitement.
            </p>
            <p class="text-slate-500 text-sm mb-8">Débloquez le reste pour obtenir votre certificat.</p>

            <div class="bg-slate-900 border border-slate-800 rounded-2xl p-6 mb-6 text-left">
              <div class="flex items-center justify-between mb-4">
                <div>
                  <p class="text-2xl font-black text-white">{{ detail()?.prixFcfa | number:'1.0-0' }} FCFA</p>
                  <p class="text-xs text-slate-500">Accès complet à vie</p>
                </div>
                <span class="badge-green">Certifiant</span>
              </div>
              <ul class="space-y-2">
                @for (av of paywallAvantages; track av) {
                  <li class="flex items-center gap-2 text-sm text-slate-400">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#22c55e" stroke-width="2.5" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
                    {{ av }}
                  </li>
                }
              </ul>
            </div>

            <div class="flex flex-col gap-3">
              <a routerLink="/app/paiements" class="btn-primary w-full justify-center py-3 text-base font-semibold">
                Débloquer l'accès complet
              </a>
              <button (click)="showPaywall.set(false)"
                      class="text-sm text-slate-500 hover:text-slate-300 transition-colors">
                Revoir les leçons gratuites
              </button>
            </div>
          </div>
        </div>
      }

      <!-- WELCOME / INTRO -->
      @if (!showPaywall() && !activeLecon()) {
        <div class="flex items-center justify-center min-h-full p-6">
          <div class="text-center max-w-md animate-fade-up">
            <div class="w-20 h-20 rounded-2xl bg-blue-600/10 border border-blue-500/20
                        flex items-center justify-center mx-auto mb-5">
              <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="#3b82f6" stroke-width="1.5" aria-hidden="true">
                <path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"/>
                <path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"/>
              </svg>
            </div>
            <h2 class="text-xl font-bold text-white mb-2">Prêt à apprendre ?</h2>
            <p class="text-sm text-slate-400 mb-6">Sélectionnez une leçon dans le sommaire pour commencer.</p>
            <button (click)="startFirstLecon()"
                    class="btn-primary px-6 py-2.5">
              Commencer la première leçon
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
            </button>
          </div>
        </div>
      }

      <!-- LEÇON ACTIVE -->
      @if (!showPaywall() && activeLecon()) {
        <div class="max-w-3xl mx-auto px-6 py-8 pb-20">

          <!-- Breadcrumb leçon -->
          <div class="flex items-center gap-2 text-xs text-slate-500 mb-6">
            <span>{{ activeModuleTitle() }}</span>
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M9 18l6-6-6-6"/></svg>
            <span class="text-slate-400">Leçon {{ activeLeconIndex() + 1 }}</span>
            <div class="ml-auto flex items-center gap-3 text-slate-500">
              <span class="flex items-center gap-1">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                {{ activeLecon()!.dureeMinutes }}min
              </span>
              <span class="flex items-center gap-1 text-amber-400">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="#f59e0b" aria-hidden="true"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
                +{{ activeLecon()!.xpReward }} XP
              </span>
            </div>
          </div>

          <!-- Titre leçon -->
          <h2 class="text-2xl font-black text-white mb-8 leading-tight">
            {{ activeLecon()!.titre }}
          </h2>

          <!-- Contenu texte -->
          @if (activeLecon()!.contenu && activeLecon()!.typeContenu !== 'QCM') {
            <div class="lesson-content mb-8" [innerHTML]="safeContent()"></div>
          }

          <!-- Lecteur vidéo -->
          @if (activeLecon()!.videoUrl) {
            <div class="aspect-video rounded-xl overflow-hidden bg-black mb-8 border border-slate-800">
              <iframe [src]="safeVideoUrl()" class="w-full h-full"
                      allowfullscreen [title]="activeLecon()!.titre" loading="lazy"></iframe>
            </div>
          }

          <!-- ── QCM (S6) ───────────────────────────────── -->
          @if (activeLecon()!.aQuiz && currentQCM()) {
            <div class="bg-slate-900 border border-slate-800 rounded-2xl p-6 mb-8">
              <div class="flex items-center gap-2 mb-5">
                <div class="w-7 h-7 rounded-lg bg-blue-600/20 flex items-center justify-center">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#60a5fa" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
                </div>
                <span class="text-sm font-bold text-slate-200">Quiz de validation</span>
                @if (qcmResult()) {
                  <span [class]="'ml-auto badge ' + (qcmResult()!.estCorrect ? 'badge-green' : 'badge-red')">
                    {{ qcmResult()!.estCorrect ? '✓ Correct' : '✗ Incorrect' }}
                  </span>
                }
              </div>

              <p class="text-base font-medium text-white mb-5 leading-relaxed">
                {{ currentQCM()!.question }}
              </p>

              <div class="space-y-2.5" role="radiogroup" [attr.aria-label]="'Options'">
                @for (entry of qcmOptions(); track entry.key) {
                  <button (click)="!selectedAnswer() && submitQCM(entry.key)"
                          [disabled]="!!selectedAnswer()"
                          class="w-full flex items-center gap-3.5 px-4 py-3.5 rounded-xl
                                 border-2 text-left text-sm font-medium transition-all"
                          [class]="optionClass(entry.key)"
                          [attr.aria-pressed]="selectedAnswer() === entry.key">
                    <!-- Lettre option -->
                    <div [class]="'w-7 h-7 rounded-lg flex items-center justify-center shrink-0 text-xs font-black '
                                  + optionLetterClass(entry.key)">
                      {{ entry.key }}
                    </div>
                    <span class="flex-1">{{ entry.value }}</span>
                    <!-- Icône résultat -->
                    @if (selectedAnswer() && qcmResult()) {
                      @if (entry.key === qcmResult()!.bonneReponse) {
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#22c55e" stroke-width="2.5" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
                      } @else if (entry.key === selectedAnswer() && !qcmResult()!.estCorrect) {
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="2.5" aria-hidden="true"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                      }
                    }
                  </button>
                }
              </div>

              <!-- Explication -->
              @if (qcmResult()) {
                <div [class]="'mt-4 p-4 rounded-xl text-sm leading-relaxed border '
                              + (qcmResult()!.estCorrect
                              ? 'bg-green-500/10 border-green-500/30 text-green-300'
                              : 'bg-red-500/10 border-red-500/30 text-red-300')">
                  <p class="font-bold mb-1">
                    {{ qcmResult()!.estCorrect ? '✓ Bonne réponse !' : '✗ Pas tout à fait.' }}
                  </p>
                  <p class="text-slate-400">{{ qcmResult()!.explication }}</p>
                </div>
              }
            </div>
          }

          <!-- ── NAVIGATION ─────────────────────────────── -->
          @if (!activeLecon()!.aQuiz || qcmResult()?.leconValidee || !currentQCM()) {
            <div class="flex items-center justify-between gap-4 pt-6 border-t border-slate-800">
              <button (click)="prevLecon()" [disabled]="!hasPrev()"
                      class="btn bg-slate-800 hover:bg-slate-700 text-slate-300 border border-slate-700 btn-sm"
                      [class.opacity-30]="!hasPrev()">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>
                Précédent
              </button>

              <!-- Bouton marquer terminée -->
              @if (!activeLecon()!.estTerminee) {
                <button (click)="marquerTerminee()" [disabled]="completing()">
                  <span [class]="'btn btn-primary px-6 ' + (completing() ? 'opacity-70' : '')">
                    @if (completing()) {
                      <svg class="animate-spin" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
                    }
                    Marquer comme terminée
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
                  </span>
                </button>
              } @else {
                <span class="flex items-center gap-2 text-sm font-semibold text-green-400">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
                  Terminée
                </span>
              }

              @if (hasNext()) {
                <button (click)="nextLecon()"
                        class="btn bg-slate-800 hover:bg-slate-700 text-slate-300 border border-slate-700 btn-sm">
                  Suivante
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
                </button>
              }
            </div>
          }

          <!-- Retry QCM -->
          @if (qcmResult() && !qcmResult()!.estCorrect && !qcmResult()!.leconValidee) {
            <div class="text-center pt-4">
              <button (click)="retryQCM()" class="text-sm text-blue-400 hover:text-blue-300 transition-colors">
                ↺ Réessayer le quiz
              </button>
            </div>
          }
        </div>
      }
    </main>
  </div>

  <!-- XP Burst (célébration) -->
  @if (showXP()) {
    <div class="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2
                pointer-events-none z-50 animate-scale-in"
         role="status" aria-live="polite">
      <div class="bg-amber-500 text-slate-900 rounded-2xl px-8 py-5 shadow-2xl text-center font-black">
        <p class="text-4xl mb-1">+{{ lastXP() }} XP</p>
        <p class="text-sm opacity-80">Leçon terminée ! 🎉</p>
      </div>
    </div>
  }
</div>
  `,
})
export class CoursePlayerComponent implements OnInit, OnDestroy {
  readonly slug = input<string>('');

  readonly #courseSvc   = inject(CourseService);
  readonly #progressSvc = inject(ProgressionService);
  readonly #qcmSvc      = inject(QcmService);
  readonly #toast       = inject(ToastService);
  readonly #sanitizer   = inject(DomSanitizer);
  readonly #platform    = inject(PLATFORM_ID);
  readonly Math         = Math;

  readonly detail      = signal<CoursDetailResponse | null>(MOCK_COURS_DETAIL);
  readonly progression = signal<{ pourcentage: number; xpGagne: number } | null>(
    { pourcentage: 37, xpGagne: 120 }
  );
  readonly activeLecon  = signal<LeconDetail | null>(null);
  readonly sidebarOpen  = signal(false);
  readonly openModules  = signal<Set<string>>(new Set(['mod-01']));
  readonly showPaywall  = signal(false);
  readonly completing   = signal(false);
  readonly showXP       = signal(false);
  readonly lastXP       = signal(0);
  readonly totalXP      = computed(() => this.progression()?.xpGagne ?? 0);

  // QCM
  readonly selectedAnswer = signal<string | null>(null);
  readonly qcmResult      = signal<{ estCorrect: boolean; bonneReponse: string; explication: string; leconValidee: boolean } | null>(null);

  #xpTimer?: ReturnType<typeof setTimeout>;
  readonly paywallAvantages = ['Accès à toutes les leçons', 'Certificat officiel', 'Communauté d\'entraide', 'Accès à vie'];

  readonly safeContent = computed((): SafeHtml => {
    const c = this.activeLecon()?.contenu ?? '';
    return this.#sanitizer.bypassSecurityTrustHtml(c);
  });
  readonly safeVideoUrl = computed(() => {
    return this.#sanitizer.bypassSecurityTrustResourceUrl(this.activeLecon()?.videoUrl ?? '');
  });
  readonly currentQCM = computed(() => {
    const id = this.activeLecon()?.id;
    return id ? MOCK_QCM[id] ?? null : null;
  });
  readonly qcmOptions = computed(() => {
    const q = this.currentQCM();
    if (!q) return [];
    return Object.entries(q.options).map(([key, value]) => ({ key, value }));
  });
  readonly activeModuleTitle = computed(() => {
    const l = this.activeLecon();
    return l ? this.detail()?.modules.find(m => m.id === l.moduleId)?.titre ?? '' : '';
  });
  readonly activeLeconIndex = computed(() => {
    const l = this.activeLecon();
    if (!l) return 0;
    const mod = this.detail()?.modules.find(m => m.id === l.moduleId);
    return mod?.lecons.findIndex(x => x.id === l.id) ?? 0;
  });
  readonly hasPrev = computed(() => {
    const { mi, li } = this.#pos();
    return li > 0 || mi > 0;
  });
  readonly hasNext = computed(() => {
    const mods = this.detail()?.modules ?? [];
    const { mi, li } = this.#pos();
    return li < (mods[mi]?.lecons.length ?? 0) - 1 || mi < mods.length - 1;
  });

  ngOnInit(): void {
    const s = this.slug();
    if (s) {
      this.#courseSvc.getBySlug(s).subscribe({
        next: r => { if (r.success && r.data) this.detail.set(r.data); },
      });
      this.#progressSvc.commencer(this.detail()?.id ?? 'c-001').subscribe({
        next: r => {
          if (r.success && r.data) {
            this.progression.set({ pourcentage: r.data.pourcentage, xpGagne: r.data.xpGagne });
            if (r.data.seuilAtteint && !r.data.estPaye) this.showPaywall.set(true);
          }
        },
      });
    }
  }

  ngOnDestroy(): void {
    if (this.#xpTimer) clearTimeout(this.#xpTimer);
    // Restaurer scroll body
    if (isPlatformBrowser(this.#platform)) document.body.style.overflow = '';
  }

  selectLecon(l: LeconDetail): void {
    this.activeLecon.set(l);
    this.sidebarOpen.set(false);
    this.selectedAnswer.set(null);
    this.qcmResult.set(null);
    if (isPlatformBrowser(this.#platform)) {
      document.getElementById('lesson-content')?.scrollTo({ top: 0, behavior: 'smooth' });
    }
  }

  startFirstLecon(): void {
    const first = this.detail()?.modules[0]?.lecons[0];
    if (first) this.selectLecon(first);
  }

  toggleModule(id: string): void {
    this.openModules.update(s => { const n = new Set(s); n.has(id) ? n.delete(id) : n.add(id); return n; });
  }
  isModuleOpen(id: string): boolean { return this.openModules().has(id); }
  isModuleComplete(mod: ModuleDetail): boolean { return mod.lecons.length > 0 && mod.lecons.every(l => l.estTerminee); }

  submitQCM(answer: string): void {
    if (this.selectedAnswer()) return;
    this.selectedAnswer.set(answer);
    const lecon = this.activeLecon();
    if (!lecon) return;

    // Appel API QCM
    this.#qcmSvc.valider(lecon.id, { leconId: lecon.id, reponse: answer }).subscribe({
      next: r => {
        if (r.success && r.data) {
          this.qcmResult.set({
            estCorrect:   r.data.estCorrect,
            bonneReponse: r.data.bonneReponse,
            explication:  r.data.explication,
            leconValidee: r.data.leconValidee,
          });
        }
      },
    });
  }

  retryQCM(): void { this.selectedAnswer.set(null); this.qcmResult.set(null); }

  marquerTerminee(): void {
    const lecon = this.activeLecon();
    if (!lecon || lecon.estTerminee || this.completing()) return;
    this.completing.set(true);
    const mods = this.detail()?.modules ?? [];
    const total = mods.reduce((s, m) => s + m.lecons.length, 0);
    const done  = mods.reduce((s, m) => s + m.lecons.filter(l => l.estTerminee).length, 0);

    this.#progressSvc.terminerLecon(this.detail()?.id ?? 'c-001', {
      leconId: lecon.id, nbLeconsTotales: total, nbLeconsTerminees: done + 1, xpLecon: lecon.xpReward,
    }).subscribe({
      next: r => {
        this.completing.set(false);
        // Mise à jour locale
        this.detail.update(d => {
          if (!d) return d;
          return { ...d, modules: d.modules.map(m => ({ ...m, lecons: m.lecons.map(l => l.id === lecon.id ? { ...l, estTerminee: true } : l) })) };
        });
        this.activeLecon.update(l => l ? { ...l, estTerminee: true } : l);
        if (r.success && r.data) {
          this.progression.set({ pourcentage: r.data.pourcentage, xpGagne: r.data.xpGagne });
          if (r.data.seuilAtteint && !r.data.estPaye) { this.showPaywall.set(true); return; }
        }
        // Célébration XP
        this.lastXP.set(lecon.xpReward);
        this.showXP.set(true);
        this.#xpTimer = setTimeout(() => this.showXP.set(false), 2000);
        this.#toast.success(`+${lecon.xpReward} XP`, 'Leçon terminée !');
        if (this.hasNext()) setTimeout(() => this.nextLecon(), 1000);
      },
      error: () => { this.completing.set(false); },
    });
  }

  prevLecon(): void {
    const { mi, li } = this.#pos(); const mods = this.detail()?.modules ?? [];
    if (li > 0) this.selectLecon(mods[mi].lecons[li - 1]);
    else if (mi > 0) { const prev = mods[mi-1]; this.selectLecon(prev.lecons[prev.lecons.length - 1]); }
  }
  nextLecon(): void {
    const { mi, li } = this.#pos(); const mods = this.detail()?.modules ?? [];
    if (li < mods[mi].lecons.length - 1) this.selectLecon(mods[mi].lecons[li + 1]);
    else if (mi < mods.length - 1) this.selectLecon(mods[mi + 1].lecons[0]);
  }

  #pos(): { mi: number; li: number } {
    const l = this.activeLecon(); if (!l) return { mi: 0, li: 0 };
    const mods = this.detail()?.modules ?? [];
    const mi = mods.findIndex(m => m.id === l.moduleId);
    const li = mods[Math.max(0,mi)]?.lecons.findIndex(x => x.id === l.id) ?? 0;
    return { mi: Math.max(0, mi), li };
  }

  optionClass(key: string): string {
    const sel = this.selectedAnswer(); const res = this.qcmResult();
    if (!sel) return 'border-slate-700 bg-slate-800/50 text-slate-300 hover:border-blue-500/50 hover:bg-blue-500/10';
    if (key === res?.bonneReponse) return 'border-green-500/60 bg-green-500/10 text-green-300';
    if (key === sel && !res?.estCorrect) return 'border-red-500/60 bg-red-500/10 text-red-300';
    return 'border-slate-800 bg-slate-900/30 text-slate-600';
  }
  optionLetterClass(key: string): string {
    const sel = this.selectedAnswer(); const res = this.qcmResult();
    if (!sel) return 'bg-slate-700 text-slate-300';
    if (key === res?.bonneReponse) return 'bg-green-500/30 text-green-400';
    if (key === sel && !res?.estCorrect) return 'bg-red-500/30 text-red-400';
    return 'bg-slate-800 text-slate-600';
  }
}
EOF
ok "course-player.component.ts (dark mode HTB-style)"

# ============================================================
# 7. APP.TS + APP.HTML — Header public ≠ header apprenant
# ============================================================
sec "7/7 — app.ts + app.html (headers séparés)"

cat > src/app/app.ts << 'EOF'
import {
  ChangeDetectionStrategy, Component, inject,
  computed, signal, OnInit, PLATFORM_ID,
} from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { RouterOutlet, RouterLink, RouterLinkActive, Router } from '@angular/router';
import { AuthService }        from './core/services/auth.service';
import { ToastService, Toast }from './core/services/toast.service';
import { ApiService }         from './core/services/api.service';
import { NotificationService }from './core/services/notification.service';
import { MockSwitcherComponent } from './shared/components/mock-switcher/mock-switcher.component';

@Component({
  selector: 'app-root',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterOutlet, RouterLink, RouterLinkActive, MockSwitcherComponent],
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App implements OnInit {
  readonly auth     = inject(AuthService);
  readonly toastSvc = inject(ToastService);
  readonly api      = inject(ApiService);
  readonly notifSvc = inject(NotificationService);
  readonly router   = inject(Router);
  readonly #plat    = inject(PLATFORM_ID);

  readonly isAuth    = this.auth.isAuthenticated;
  readonly user      = this.auth.currentUser;
  readonly role      = this.auth.userRole;
  readonly isAdmin   = this.auth.isAdmin;
  readonly loading   = this.api.loading;
  readonly toasts    = this.toastSvc.toasts;
  readonly hasUnread = this.notifSvc.hasUnread;
  readonly menuOpen  = signal(false);
  readonly userMenuOpen = signal(false);

  // Navigation selon rôle (pour header connecté)
  readonly navLinks = computed(() => {
    const r = this.role();
    if (!r) return [];
    const maps: Record<string, { label: string; href: string }[]> = {
      APPRENANT: [
        { label: 'Mon espace',  href: '/app' },
        { label: 'Classement',  href: '/app/classement' },
        { label: 'Parrainage',  href: '/app/parrainage' },
        { label: 'Tirage',      href: '/app/tirage' },
      ],
      FORMATEUR: [
        { label: 'Dashboard',   href: '/instructor' },
        { label: 'Sessions',    href: '/instructor/sessions' },
        { label: 'Correction',  href: '/instructor/correction' },
      ],
      ADMIN: [
        { label: 'Dashboard',   href: '/admin' },
        { label: 'Apprenants',  href: '/admin/apprenants' },
        { label: 'Paiements',   href: '/admin/paiements' },
        { label: 'Rôles',       href: '/admin/roles' },
      ],
      SUPER_ADMIN: [
        { label: 'Dashboard',   href: '/admin' },
        { label: 'Apprenants',  href: '/admin/apprenants' },
        { label: 'Paiements',   href: '/admin/paiements' },
        { label: 'Rôles',       href: '/admin/roles' },
      ],
    };
    return maps[r] ?? [];
  });

  ngOnInit(): void {
    if (isPlatformBrowser(this.#plat)) {
      window.addEventListener('mn:error', (e: Event) => {
        this.toastSvc.error(((e as CustomEvent).detail as { message: string }).message);
      });
    }
  }

  logout(): void { this.menuOpen.set(false); this.userMenuOpen.set(false); this.auth.logout(); }
  closeAll(): void { this.menuOpen.set(false); this.userMenuOpen.set(false); }
  toggleMenu(): void { this.menuOpen.update(v => !v); this.userMenuOpen.set(false); }
  toggleUserMenu(): void { this.userMenuOpen.update(v => !v); this.menuOpen.set(false); }

  toastBg(t: Toast['type']): string { return { success:'bg-green-50 border-green-200', error:'bg-red-50 border-red-200', warning:'bg-amber-50 border-amber-200', info:'bg-blue-50 border-blue-200' }[t]; }
  toastIcon(t: Toast['type']): string { return { success:'✓', error:'✕', warning:'⚠', info:'ℹ' }[t]; }
  toastIconBg(t: Toast['type']): string { return { success:'bg-green-100 text-green-700', error:'bg-red-100 text-red-700', warning:'bg-amber-100 text-amber-700', info:'bg-blue-100 text-blue-700' }[t]; }
  toastText(t: Toast['type']): string { return { success:'text-green-900', error:'text-red-900', warning:'text-amber-900', info:'text-blue-900' }[t]; }
}
EOF

cat > src/app/app.html << 'APPHTML'
<!-- MbemNova App Shell — Header PUBLIC ≠ Header CONNECTÉ -->

<!-- Barre loading -->
@if (loading()) {
  <div class="fixed top-0 left-0 right-0 z-[500] h-0.5 bg-blue-100 overflow-hidden" role="progressbar" aria-label="Chargement">
    <div class="h-full bg-blue-600" style="animation:loadingBar 1.5s ease-in-out infinite;"></div>
  </div>
}

<!-- ══════════════════════════════════════════════════════════ -->
<!--  HEADER PUBLIC (non connecté) — logo + liens catalogue    -->
<!-- ══════════════════════════════════════════════════════════ -->
@if (!isAuth()) {
  <header class="sticky top-0 z-40 bg-white border-b border-slate-100">
    <nav class="container flex items-center h-16 gap-3" aria-label="Navigation publique">

      <!-- Logo -->
      <a routerLink="/" class="flex items-center gap-2 group shrink-0 mr-4" aria-label="MbemNova — Accueil">
        <svg width="36" height="36" viewBox="0 0 36 36" fill="none" class="group-hover:scale-105 transition-transform duration-200" aria-hidden="true">
          <circle cx="18" cy="18" r="18" fill="#2563eb"/>
          <path d="M8 26V11l10 8 10-8v15" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
          <circle cx="28" cy="10" r="3" fill="#f59e0b" class="animate-dot-pulse"/>
        </svg>
        <span class="font-bold text-lg text-slate-900 hidden xs:block">Mbem<span class="text-blue-600">Nova</span></span>
      </a>

      <!-- Liens nav publics -->
      <div class="hidden md:flex items-center gap-1 flex-1">
        <a routerLink="/catalogue"
           routerLinkActive="bg-blue-50 text-blue-700 font-semibold"
           class="px-3 py-2 rounded-lg text-sm text-slate-600 hover:bg-slate-50 hover:text-slate-900 transition-colors">
          Catalogue
        </a>
      </div>

      <div class="flex-1 md:flex-none"></div>

      <!-- CTA connexion / inscription -->
      <div class="flex items-center gap-2">
        <a routerLink="/auth/connexion" class="hidden sm:flex btn-ghost text-sm">Connexion</a>
        <a routerLink="/auth/inscription" class="btn-primary text-sm">Commencer</a>

        <!-- Burger mobile -->
        <button (click)="toggleMenu()" class="md:hidden p-2 rounded-lg text-slate-600 hover:bg-slate-100 transition-colors"
                [attr.aria-expanded]="menuOpen()" aria-label="Menu">
          @if (!menuOpen()) {
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg>
          } @else {
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
          }
        </button>
      </div>
    </nav>

    <!-- Menu mobile public -->
    @if (menuOpen()) {
      <div class="md:hidden border-t border-slate-100 bg-white animate-slide-down">
        <div class="container py-3 space-y-1">
          <a routerLink="/catalogue" (click)="closeAll()" class="flex items-center px-3 py-2.5 rounded-lg text-sm text-slate-700 hover:bg-slate-50">Catalogue</a>
          <a routerLink="/auth/connexion" (click)="closeAll()" class="flex items-center px-3 py-2.5 rounded-lg text-sm text-slate-700 hover:bg-slate-50">Connexion</a>
          <a routerLink="/auth/inscription" (click)="closeAll()" class="btn-primary w-full justify-center mt-2">Commencer gratuitement</a>
        </div>
      </div>
    }
  </header>
}

<!-- ══════════════════════════════════════════════════════════ -->
<!--  HEADER CONNECTÉ — navigation adaptée au rôle            -->
<!-- ══════════════════════════════════════════════════════════ -->
@if (isAuth()) {
  <header class="sticky top-0 z-40 bg-white border-b border-slate-100">
    <nav class="container flex items-center h-16 gap-2" aria-label="Navigation principale">

      <!-- Logo -->
      <a routerLink="/" class="flex items-center gap-2 group shrink-0 mr-3" aria-label="MbemNova — Accueil">
        <svg width="34" height="34" viewBox="0 0 36 36" fill="none" class="group-hover:scale-105 transition-transform duration-200" aria-hidden="true">
          <circle cx="18" cy="18" r="18" fill="#2563eb"/>
          <path d="M8 26V11l10 8 10-8v15" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
          <circle cx="28" cy="10" r="3" fill="#f59e0b" class="animate-dot-pulse"/>
        </svg>
        <span class="font-bold text-base text-slate-900 hidden sm:block">Mbem<span class="text-blue-600">Nova</span></span>
      </a>

      <!-- Navigation contextuelle par rôle -->
      <div class="hidden md:flex items-center gap-0.5 flex-1">
        @for (link of navLinks(); track link.href) {
          <a [routerLink]="link.href"
             routerLinkActive="bg-blue-50 text-blue-700 font-semibold"
             [routerLinkActiveOptions]="{ exact: link.href === '/app' || link.href === '/admin' || link.href === '/instructor' }"
             class="px-3 py-2 rounded-lg text-sm text-slate-600 hover:bg-slate-50 hover:text-slate-900 transition-colors duration-150">
            {{ link.label }}
          </a>
        }
      </div>

      <div class="flex-1 md:flex-none"></div>

      <!-- Actions droite (connecté) -->
      <div class="flex items-center gap-1.5">

        <!-- Cloche notifications -->
        <a routerLink="/app/notifications"
           class="relative p-2 rounded-lg text-slate-500 hover:bg-slate-100 transition-colors"
           aria-label="Notifications">
          <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
            <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/>
          </svg>
          @if (hasUnread()) {
            <span class="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full" aria-label="Nouvelles notifications"></span>
          }
        </a>

        <!-- Menu utilisateur -->
        <div class="relative">
          <button (click)="toggleUserMenu()"
                  class="flex items-center gap-2 pl-2 pr-2.5 py-1.5 rounded-lg hover:bg-slate-100 transition-colors"
                  [attr.aria-expanded]="userMenuOpen()" aria-haspopup="true">
            <div class="w-7 h-7 rounded-full bg-blue-600 flex items-center justify-center text-white text-xs font-bold shrink-0">
              {{ user()?.prenom?.charAt(0)?.toUpperCase() ?? '?' }}
            </div>
            <span class="hidden sm:block text-sm font-medium text-slate-700 max-w-20 truncate">{{ user()?.prenom }}</span>
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" class="text-slate-400 hidden sm:block" aria-hidden="true"><polyline points="6 9 12 15 18 9"/></svg>
          </button>

          @if (userMenuOpen()) {
            <div class="absolute right-0 top-full mt-1.5 w-52 bg-white rounded-xl border border-slate-200 shadow-lg py-1.5 z-50 animate-slide-down" role="menu">
              <!-- Rôle badge -->
              <div class="px-3 py-2 border-b border-slate-100 mb-1">
                <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide">
                  {{ role() === 'ADMIN' || role() === 'SUPER_ADMIN' ? 'Administrateur' : role() === 'FORMATEUR' ? 'Formateur' : 'Apprenant' }}
                </p>
                <p class="text-sm text-slate-900 font-medium truncate">{{ user()?.email }}</p>
              </div>

              @if (role() === 'APPRENANT') {
                <a routerLink="/app/profil" (click)="closeAll()" class="flex items-center gap-2.5 px-3 py-2 text-sm text-slate-700 hover:bg-slate-50 w-full" role="menuitem">
                  <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
                  Mon profil
                </a>
                <a routerLink="/app/paiements" (click)="closeAll()" class="flex items-center gap-2.5 px-3 py-2 text-sm text-slate-700 hover:bg-slate-50 w-full" role="menuitem">
                  <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><rect x="1" y="4" width="22" height="16" rx="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>
                  Mes paiements
                </a>
              }

              <div class="border-t border-slate-100 mt-1 pt-1">
                <button (click)="logout()" class="flex items-center gap-2.5 px-3 py-2 text-sm text-red-600 hover:bg-red-50 w-full transition-colors" role="menuitem">
                  <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
                  Se déconnecter
                </button>
              </div>
            </div>
          }
        </div>

        <!-- Burger mobile connecté -->
        <button (click)="toggleMenu()" class="md:hidden p-2 rounded-lg text-slate-600 hover:bg-slate-100 transition-colors"
                [attr.aria-expanded]="menuOpen()" aria-label="Menu">
          @if (!menuOpen()) {
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg>
          } @else {
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
          }
        </button>
      </div>
    </nav>

    <!-- Menu mobile connecté -->
    @if (menuOpen()) {
      <div class="md:hidden border-t border-slate-100 bg-white animate-slide-down">
        <div class="container py-3 space-y-0.5">
          @for (link of navLinks(); track link.href) {
            <a [routerLink]="link.href" (click)="closeAll()"
               class="flex items-center px-3 py-2.5 rounded-lg text-sm text-slate-700 hover:bg-slate-50">
              {{ link.label }}
            </a>
          }
          <div class="border-t border-slate-100 pt-2 mt-2">
            <a routerLink="/app/notifications" (click)="closeAll()" class="flex items-center px-3 py-2.5 rounded-lg text-sm text-slate-700 hover:bg-slate-50">
              Notifications
            </a>
            <button (click)="logout()" class="flex items-center px-3 py-2.5 rounded-lg text-sm text-red-600 hover:bg-red-50 w-full text-left">
              Se déconnecter
            </button>
          </div>
        </div>
      </div>
    }
  </header>
}

<!-- ── CONTENU PRINCIPAL ────────────────────────────── -->
<main class="min-h-[calc(100vh-64px)]">
  <router-outlet />
</main>

<!-- ── FOOTER (pages publiques uniquement) ─────────────── -->
@if (!isAuth()) {
  <footer class="bg-slate-900 text-slate-400">
    <div class="container py-12">
      <div class="grid grid-cols-2 md:grid-cols-4 gap-8 mb-10">
        <div class="col-span-2 md:col-span-1">
          <div class="flex items-center gap-2 mb-4">
            <svg width="30" height="30" viewBox="0 0 36 36" fill="none" aria-hidden="true">
              <circle cx="18" cy="18" r="18" fill="#3b82f6"/>
              <path d="M8 26V11l10 8 10-8v15" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
              <circle cx="28" cy="10" r="3" fill="#f59e0b"/>
            </svg>
            <span class="font-bold text-white">Mbem<span class="text-blue-400">Nova</span></span>
          </div>
          <p class="text-sm leading-relaxed mb-3">La référence EdTech de l'Afrique Centrale. Formations certifiantes, paiement en tranches.</p>
          <p class="text-xs">📍 Douala, Cameroun</p>
          <p class="text-xs mt-1">✉️ contact&#64;mbemnova.com</p>
        </div>
        <div>
          <h3 class="text-white font-semibold text-sm mb-3">Formations</h3>
          <ul class="space-y-2 text-sm">
            <li><a routerLink="/catalogue" class="hover:text-white transition-colors">Tout le catalogue</a></li>
            <li><a routerLink="/catalogue" class="hover:text-white transition-colors">Débutants</a></li>
            <li><a routerLink="/catalogue" class="hover:text-white transition-colors">Intermédiaires</a></li>
          </ul>
        </div>
        <div>
          <h3 class="text-white font-semibold text-sm mb-3">Plateforme</h3>
          <ul class="space-y-2 text-sm">
            <li><a routerLink="/auth/inscription" class="hover:text-white transition-colors">Inscription gratuite</a></li>
            <li><a routerLink="/auth/connexion" class="hover:text-white transition-colors">Connexion</a></li>
            <li><a routerLink="/certificat/verifier/demo" class="hover:text-white transition-colors">Vérifier un certificat</a></li>
          </ul>
        </div>
        <div>
          <h3 class="text-white font-semibold text-sm mb-3">Légal</h3>
          <ul class="space-y-2 text-sm">
            <li><a routerLink="/politique-confidentialite" class="hover:text-white transition-colors">Politique de confidentialité</a></li>
          </ul>
        </div>
      </div>
      <div class="border-t border-slate-800 pt-6 flex flex-col sm:flex-row items-center justify-between gap-2 text-xs">
        <p>© 2025 MbemNova. Tous droits réservés.</p>
        <p>Fait avec ❤️ pour la tech africaine</p>
      </div>
    </div>
  </footer>
}

<!-- ── TOASTS ───────────────────────────────────────────── -->
<div class="fixed bottom-4 right-4 z-[400] flex flex-col gap-2 max-w-xs w-full pointer-events-none"
     role="region" aria-live="polite" aria-label="Notifications">
  @for (t of toasts(); track t.id) {
    <div [class]="'flex items-start gap-3 p-3.5 rounded-xl border shadow-lg pointer-events-auto animate-slide-right ' + toastBg(t.type)" role="alert">
      <div [class]="'w-6 h-6 rounded-full flex items-center justify-center shrink-0 text-xs font-bold ' + toastIconBg(t.type)" aria-hidden="true">{{ toastIcon(t.type) }}</div>
      <div class="flex-1 min-w-0">
        <p [class]="'text-sm font-semibold leading-tight ' + toastText(t.type)">{{ t.title }}</p>
        @if (t.message) { <p [class]="'text-xs mt-0.5 opacity-80 ' + toastText(t.type)">{{ t.message }}</p> }
      </div>
      <button (click)="toastSvc.dismiss(t.id)" class="opacity-50 hover:opacity-100 transition-opacity shrink-0" [attr.aria-label]="'Fermer ' + t.title">
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" aria-hidden="true"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
      </button>
    </div>
  }
</div>

<!-- Backdrop pour fermer les dropdowns -->
@if (menuOpen() || userMenuOpen()) {
  <div class="fixed inset-0 z-30" (click)="closeAll()" aria-hidden="true"></div>
}

<!-- MockSwitcher (visible uniquement en mode mock/DEV) -->
<app-mock-switcher />
APPHTML

cat > src/app/app.css << 'EOF'
@keyframes loadingBar {
  0%   { transform: translateX(-100%) scaleX(0.3); }
  50%  { transform: translateX(0%) scaleX(0.8); }
  100% { transform: translateX(100%) scaleX(0.3); }
}
EOF

ok "app.ts + app.html — Header public ≠ header connecté"

echo ""
echo -e "${G}══════════════════════════════════════════════════════${N}"
echo -e "${G}  Refonte complète terminée ✓                         ${N}"
echo -e "${G}══════════════════════════════════════════════════════${N}"
echo ""
echo -e "  ${G}✓${N}  models/index.ts          — DTOs 100% identiques API Java"
echo -e "  ${G}✓${N}  mock.data.ts             — 4 profils + switchProfile()"
echo -e "  ${G}✓${N}  Services                 — QCM, avis, moratoire, parrainage, creneaux..."
echo -e "  ${G}✓${N}  mock.interceptor.ts      — couverture 100% endpoints"
echo -e "  ${G}✓${N}  mock-switcher.component  — bascule profils en 1 clic (DEV)"
echo -e "  ${G}✓${N}  course-player.component  — dark mode HTB-style"
echo -e "  ${G}✓${N}  app.ts + app.html        — header public ≠ header connecté"
echo ""
echo -e "  ${B}BASCULE MOCK ↔ API :${N}"
echo -e "    src/environments/environment.ts → ${Y}useMock: false${N}"
echo ""
echo -e "  ${B}TESTER LES 4 PROFILS :${N}"
echo -e "    Le badge 🎭 en bas à gauche → cliquer pour changer de profil"
echo ""
echo -e "  ${B}DÉMARRER :${N}"
echo -e "    npm install && npm start"
echo ""
