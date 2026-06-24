import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-privacy-policy',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink],
  template: `
<div class="min-h-screen bg-white">
  <!-- Header -->
  <div class="bg-slate-900 py-14">
    <div class="container max-w-4xl">
      <nav class="flex items-center gap-2 text-sm text-slate-400 mb-6" aria-label="Fil d'Ariane">
        <a routerLink="/" class="hover:text-white transition-colors">Accueil</a>
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M9 18l6-6-6-6"/></svg>
        <span class="text-white">Politique de confidentialité</span>
      </nav>
      <h1 class="text-3xl font-black text-white mb-2">Politique de confidentialité</h1>
      <p class="text-slate-400">Dernière mise à jour : janvier 2025</p>
    </div>
  </div>

  <!-- Contenu -->
  <div class="container max-w-4xl py-14">
    <div class="prose prose-slate max-w-none">

      <!-- Intro -->
      <div class="card p-6 mb-8 bg-blue-50 border-blue-200">
        <p class="text-sm text-blue-900 leading-relaxed">
          <strong>MbemNova</strong> s'engage à protéger la vie privée de ses utilisateurs.
          Cette politique décrit comment nous collectons, utilisons et protégeons vos données
          personnelles conformément aux lois en vigueur en Afrique Centrale.
        </p>
      </div>

      <!-- Données collectées -->
      <section class="mb-10">
        <h2 class="h2 mb-5">1. Données collectées</h2>
        <div class="overflow-x-auto">
          <table class="w-full border-collapse">
            <thead>
              <tr class="bg-slate-900 text-white">
                <th class="px-4 py-3 text-left text-sm font-semibold rounded-tl-lg">Donnée</th>
                <th class="px-4 py-3 text-left text-sm font-semibold">Moment de collecte</th>
                <th class="px-4 py-3 text-left text-sm font-semibold">Finalité</th>
                <th class="px-4 py-3 text-left text-sm font-semibold rounded-tr-lg">Conservation</th>
              </tr>
            </thead>
            <tbody>
              @for (row of dataTable; track row.data; let i = $index) {
                <tr [class]="i % 2 === 0 ? 'bg-white' : 'bg-slate-50'">
                  <td class="px-4 py-3 text-sm font-medium text-slate-900 border-b border-slate-100">{{ row.data }}</td>
                  <td class="px-4 py-3 text-sm text-slate-600 border-b border-slate-100">{{ row.when }}</td>
                  <td class="px-4 py-3 text-sm text-slate-600 border-b border-slate-100">{{ row.why }}</td>
                  <td class="px-4 py-3 text-sm text-slate-600 border-b border-slate-100">{{ row.duration }}</td>
                </tr>
              }
            </tbody>
          </table>
        </div>
      </section>

      <!-- Droits -->
      <section class="mb-10">
        <h2 class="h2 mb-5">2. Vos droits</h2>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          @for (right of rights; track right.title) {
            <div class="card p-5">
              <div class="flex items-center gap-3 mb-2">
                <span class="text-2xl" aria-hidden="true">{{ right.icon }}</span>
                <h3 class="font-semibold text-slate-900 text-sm">{{ right.title }}</h3>
              </div>
              <p class="text-sm text-slate-500 leading-relaxed">{{ right.desc }}</p>
            </div>
          }
        </div>
      </section>

      <!-- Sécurité -->
      <section class="mb-10">
        <h2 class="h2 mb-5">3. Sécurité des données</h2>
        <div class="space-y-3">
          @for (item of security; track item) {
            <div class="flex items-start gap-3">
              <div class="w-5 h-5 rounded-full bg-green-100 flex items-center justify-center shrink-0 mt-0.5">
                <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#16a34a" stroke-width="3" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>
              </div>
              <p class="text-sm text-slate-700">{{ item }}</p>
            </div>
          }
        </div>
      </section>

      <!-- Cookies -->
      <section class="mb-10">
        <h2 class="h2 mb-5">4. Cookies</h2>
        <div class="space-y-3">
          @for (cookie of cookies; track cookie.name) {
            <div class="border border-slate-200 rounded-xl p-4">
              <div class="flex items-center justify-between mb-1">
                <h3 class="font-semibold text-sm text-slate-900">{{ cookie.name }}</h3>
                <span [class]="cookie.required ? 'badge-green' : 'badge-amber'">
                  {{ cookie.required ? 'Obligatoire' : 'Optionnel' }}
                </span>
              </div>
              <p class="text-xs text-slate-500">{{ cookie.desc }}</p>
            </div>
          }
        </div>
      </section>

      <!-- Contact -->
      <section class="card p-6 bg-slate-50 border-slate-200">
        <h2 class="h3 mb-3">5. Contact</h2>
        <p class="text-sm text-slate-600 mb-2">
          Pour toute question relative à vos données personnelles :
        </p>
        <p class="text-sm">
          📧 <a href="mailto:privacy@mbemnova.com" class="link font-medium">privacy&#64;mbemnova.com</a>
        </p>
        <p class="text-sm text-slate-500 mt-2">Délai de réponse garanti : 30 jours ouvrables.</p>
      </section>
    </div>

    <div class="mt-10 text-center">
      <a routerLink="/auth/inscription" class="btn-primary btn-lg">
        Je comprends et je m'inscris
      </a>
    </div>
  </div>
</div>
  `,
})
export class PrivacyPolicyComponent {
  readonly dataTable = [
    { data: 'Prénom, Nom',         when: 'Inscription',          why: 'Personnalisation, certificats',    duration: 'Durée compte + 2 ans' },
    { data: 'Email',               when: 'Inscription',          why: 'Authentification, notifications', duration: 'Durée du compte' },
    { data: 'Téléphone',           when: 'Progressif',           why: 'WhatsApp, relances paiement',     duration: 'Durée du compte' },
    { data: 'Mot de passe (haché)',when: 'Inscription',          why: 'Authentification',                duration: 'Durée du compte' },
    { data: 'Adresse IP',          when: 'Chaque connexion',     why: 'Sécurité, prévention fraude',     duration: '90 jours' },
    { data: 'Progression cours',   when: 'Pendant apprentissage',why: 'Service principal',               duration: 'Durée du compte' },
    { data: 'Données de paiement', when: 'Lors du paiement',     why: 'Facturation, comptabilité',       duration: '10 ans (obligation légale)' },
    { data: 'CV uploadé',          when: 'Si l\'apprenant le fait',why: 'Profil talent, recrutement',    duration: 'Jusqu\'à suppression' },
    { data: 'Messages communauté', when: 'Pendant utilisation',  why: 'Service communauté',              duration: 'Durée du compte' },
  ];

  readonly rights = [
    { icon: '👁️',  title: 'Droit d\'accès',      desc: 'Demandez la liste complète de vos données via les paramètres. Réponse sous 30 jours.' },
    { icon: '✏️',  title: 'Droit de rectification', desc: 'Modifiez vos données directement depuis votre profil (prénom, email, téléphone).' },
    { icon: '🗑️', title: 'Droit à l\'effacement', desc: 'Supprimez votre compte. Les données non légalement obligatoires sont effacées sous 30 jours.' },
    { icon: '🚫',  title: 'Droit d\'opposition',  desc: 'Désactivez les emails marketing et notifications non critiques dans vos paramètres.' },
    { icon: '📦',  title: 'Portabilité',          desc: 'Exportez toutes vos données (progression, certificats) en JSON ou PDF depuis votre profil.' },
    { icon: '⏸️',  title: 'Droit de limitation',  desc: 'Limitez le traitement de vos données en nous contactant à privacy@mbemnova.com.' },
  ];

  readonly security = [
    'Connexions HTTPS uniquement — chiffrement TLS 1.3',
    'Mots de passe hachés avec BCrypt (coût 12) — jamais stockés en clair',
    'Tokens JWT stockés en mémoire côté client — pas dans localStorage',
    'Rate limiting : 100 requêtes/minute par IP',
    'Sauvegardes automatiques chiffrées — rétention 30 jours',
    'Authentification 2FA recommandée pour les comptes admin',
    'Logs d\'audit pour toutes les actions sensibles (paiement, changement rôle)',
    'Protection OWASP Top 10 — XSS, CSRF, injection SQL',
  ];

  readonly cookies = [
    { name: 'Session JWT (refresh)',  required: true,  desc: 'Maintient votre connexion sécurisée. HttpOnly — non accessible au JavaScript.' },
    { name: 'Préférences interface',  required: false, desc: 'Mémorise vos préférences d\'affichage (thème, langue). Désactivable.' },
    { name: 'Analytics anonymisés',  required: false, desc: 'Mesure d\'audience anonymisée pour améliorer la plateforme. Désactivable.' },
  ];
}
