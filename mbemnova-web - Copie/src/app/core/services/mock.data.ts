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
    id: 'u-001', userId: 'u-001', nom: 'Mbemba', prenom: 'Jean-Paul', email: 'jeanpaul.mbemba@gmail.com',
    role: 'APPRENANT', accessToken: 'mock.apprenant', refreshToken: 'mock.refresh',
    expiresAt: new Date(Date.now() + 86_400_000).toISOString(), suspended: false,
  },
  FORMATEUR: {
    id: 'u-fmt', userId: 'u-fmt', nom: 'Fouda', prenom: 'Alice', email: 'alice.fouda@mbemnova.com',
    role: 'FORMATEUR', accessToken: 'mock.formateur', refreshToken: 'mock.refresh',
    expiresAt: new Date(Date.now() + 86_400_000).toISOString(), suspended: false,
  },
  ADMIN: {
    id: 'u-adm', userId: 'u-adm', nom: 'Serge', prenom: 'Serge', email: 'serge.admin@mbemnova.com',
    role: 'ADMIN', accessToken: 'mock.admin', refreshToken: 'mock.refresh',
    expiresAt: new Date(Date.now() + 86_400_000).toISOString(), suspended: false,
  },
  SUPER_ADMIN: {
    id: 'u-sad', userId: 'u-sad', nom: 'Nova', prenom: 'MbemNova', email: 'root@mbemnova.com',
    role: 'SUPER_ADMIN', accessToken: 'mock.super', refreshToken: 'mock.refresh',
    expiresAt: new Date(Date.now() + 86_400_000).toISOString(), suspended: false,
  },
};

// ← CHANGER ICI pour tester un autre profil
export let MOCK_AUTH: AuthResponse = MOCK_PROFILES['APPRENANT'];

export const MOCK_USER: UserProfile = {
  id: MOCK_AUTH.userId,
  userId: MOCK_AUTH.userId,
  nom: MOCK_AUTH.nom,
  prenom: MOCK_AUTH.prenom,
  email: MOCK_AUTH.email,
  role: MOCK_AUTH.role,
  photoUrl: null,
  statut: 'ACTIF',
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
    statut: 'PUBLIE',
    description: 'Description complète du cours.', // ← ajouter
    prixAffichage: '25 000 FCFA',
    domaine: 'Développement Web'
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
    statut: 'PUBLIE',
    description: 'Description complète du cours.',   // ← ajouter
prixAffichage: '25 000 FCFA',                    // ← ajouter (adapter le montant)
    domaine: 'Développement Web'
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
    statut: 'PUBLIE',
    description: 'Description complète du cours.',   // ← ajouter
prixAffichage: '25 000 FCFA',                    // ← ajouter (adapter le montant)
    domaine: 'Data Science'
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
    statut: 'PUBLIE',
    description: 'Description complète du cours.',   // ← ajouter
prixAffichage: '25 000 FCFA',                    // ← ajouter (adapter le montant)
    domaine: 'Développement Web'
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
    statut: 'PUBLIE',
    description: 'Description complète du cours.',   // ← ajouter
prixAffichage: '25 000 FCFA',                    // ← ajouter (adapter le montant)
    domaine: 'Design'
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
    statut: 'PUBLIE',
     description: 'Description complète du cours.',   // ← ajouter
prixAffichage: '25 000 FCFA',  
    domaine: 'Réseaux & Sécurité'
  },
];

// ── CoursDetail (arbre complet) ────────────────────────────
export const MOCK_COURS_DETAIL: CoursDetailResponse = {
  id: 'c-001', titre: 'Développement Web : HTML, CSS & JavaScript',
  descriptionCourte: 'Maîtrisez les fondamentaux du web.',
   description: 'Formation complète pour maîtriser HTML, CSS et JavaScript avec des projets concrets adaptés au contexte camerounais.',
  prixAffichage: '25 000 FCFA', // ← nouveau
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
  niveau: 'DEBUTANT', langue: 'Français', statut: 'PUBLIE',
  imageCouverture: null, imageCouvertureThumbnail: null,
  slug: 'dev-web-html-css-js',
  nbModules: 3, nbLecons: 8, dureeTotaleMinutes: 240,
  nbApprenants: 142, noteMoyenne: 4.7, nbAvis: 38,
  prixFcfa: 25000, seuilPaiement: 0.30,
  sessionsDisponibles: [
    { id: 's-001', dateDebut: new Date(Date.now() + 7 * 86400000).toISOString(), dateFin: new Date(Date.now() + 37 * 86400000).toISOString(), modalite: 'MEET', lieuOuLien: 'https://meet.google.com/mbem-dev', placesDisponibles: 7, capaciteMax: 20 },
    { id: 's-002', dateDebut: new Date(Date.now() + 14 * 86400000).toISOString(), dateFin: new Date(Date.now() + 44 * 86400000).toISOString(), modalite: 'PRESENTIEL', lieuOuLien: 'Centre MbemNova, Akwa — Douala', placesDisponibles: 0, capaciteMax: 15 },
  ],
  progressionApprenant: { pourcentage: 37, estPaye: false, seuilAtteint: false, xpGagne: 120, derniereLeconTitre: 'CSS : mise en forme' },
  modules: [
    {
      id: 'mod-01', titre: 'Module 1 — Introduction au Web', sortOrder: 1,
      lecons: [
        {
          id: 'l-01', moduleId: 'mod-01', titre: 'Comment fonctionne Internet ?', typeContenu: 'TEXTE',
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
          videoUrl: null, pdfUrl: null, dureeMinutes: 6, sortOrder: 1, aQuiz: true, xpReward: 10, estTerminee: true, estVerrouille: false
        },
        {
          id: 'l-02', moduleId: 'mod-01', titre: 'HTML : structure d\'une page', typeContenu: 'TEXTE',
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
          videoUrl: null, pdfUrl: null, dureeMinutes: 8, sortOrder: 2, aQuiz: true, xpReward: 10, estTerminee: true, estVerrouille: false
        },
        {
          id: 'l-03', moduleId: 'mod-01', titre: 'CSS : mise en forme', typeContenu: 'TEXTE',
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
          videoUrl: null, pdfUrl: null, dureeMinutes: 7, sortOrder: 3, aQuiz: false, xpReward: 10, estTerminee: false, estVerrouille: false
        },
      ]
    },
    {
      id: 'mod-02', titre: 'Module 2 — JavaScript Fondamentaux', sortOrder: 2,
      lecons: [
        {
          id: 'l-04', moduleId: 'mod-02', titre: 'Variables et types de données', typeContenu: 'TEXTE',
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
          videoUrl: null, pdfUrl: null, dureeMinutes: 5, sortOrder: 1, aQuiz: true, xpReward: 10, estTerminee: false, estVerrouille: false
        },
        {
          id: 'l-05', moduleId: 'mod-02', titre: 'Fonctions', typeContenu: 'TEXTE',
          contenu: `<h2>Les fonctions en JavaScript</h2>
<p>Une fonction est un bloc de code <strong>réutilisable</strong>.</p>
<pre><code>function saluer(prenom) {
  return "Bonjour " + prenom + " !";
}

// Appel
const message = saluer("Jean-Paul");
// console.log(message); // "Bonjour Jean-Paul !"

// Fonction fléchée (moderne)
const calculer = (a, b) => a + b;
// console.log(calculer(5, 3)); // 8</code></pre>`,
          videoUrl: null, pdfUrl: null, dureeMinutes: 8, sortOrder: 2, aQuiz: true, xpReward: 10, estTerminee: false, estVerrouille: false
        },
      ]
    },
    {
      id: 'mod-03', titre: 'Module 3 — Projet Pratique', sortOrder: 3,
      lecons: [
        {
          id: 'l-06', moduleId: 'mod-03', titre: 'Projet : Site vitrine complet', typeContenu: 'TEXTE',
          contenu: '<p>Contenu du projet pratique...</p>',
          videoUrl: null, pdfUrl: null, dureeMinutes: 30, sortOrder: 1, aQuiz: false, xpReward: 30, estTerminee: false, estVerrouille: true
        },
        {
          id: 'l-07', moduleId: 'mod-03', titre: 'Déploiement sur Netlify', typeContenu: 'TEXTE',
          contenu: '<p>Déployer votre site gratuitement...</p>',
          videoUrl: null, pdfUrl: null, dureeMinutes: 15, sortOrder: 2, aQuiz: false, xpReward: 20, estTerminee: false, estVerrouille: true
        },
        {
          id: 'l-08', moduleId: 'mod-03', titre: 'Révision et quiz final', typeContenu: 'QCM',
          contenu: null, videoUrl: null, pdfUrl: null, dureeMinutes: 10, sortOrder: 3, aQuiz: true, xpReward: 30, estTerminee: false, estVerrouille: true
        },
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
