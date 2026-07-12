import {
  ChangeDetectionStrategy, Component, inject,
  signal, computed, input, OnInit, ViewChild, ElementRef, PLATFORM_ID,
} from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { CommonModule, isPlatformBrowser } from '@angular/common';
import { CommunityService } from '../../../core/services/community.service';
import { ToastService }     from '../../../core/services/toast.service';
import { AuthService }      from '../../../core/services/auth.service';
import type { MessageResponse } from '../../../core/models';
import { MOCK_MESSAGES } from '../../../core/services/mock.data';

// ── Palette couleurs déterministe pour avatars ──
const AVATAR_PALETTE = [
  '#2563eb', // blue-600
  '#0284c7', // sky-600
  '#0891b2', // cyan-600
  '#059669', // emerald-600
  '#7c3aed', // violet-600
  '#db2777', // pink-600
  '#dc2626', // red-600
  '#d97706', // amber-600
];

@Component({
  selector: 'app-community',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, RouterLink, CommonModule],
  templateUrl: './community.html',
  styleUrl: './community.css',
})
export class CommunityComponent implements OnInit {
  readonly coursId = input<string>('');

  readonly #svc        = inject(CommunityService);
  readonly #toast      = inject(ToastService);
  readonly #auth       = inject(AuthService);
  readonly #fb         = inject(FormBuilder);
  readonly #platformId = inject(PLATFORM_ID);

  @ViewChild('composerRef') composerRef?: ElementRef<HTMLTextAreaElement>;

  // ── State ──
  readonly messages     = signal<MessageResponse[]>(MOCK_MESSAGES);
  readonly loading      = signal(true);
  readonly activeReply  = signal<string | null>(null);
  readonly qLoading     = signal(false);
  readonly rLoading     = signal(false);
  readonly composerFocused = signal(false);
  readonly activeFilter = signal<'all' | 'resolved' | 'open'>('all');

  qSubmitted = false;

  // ── Auth ──
  readonly authorName    = computed(() => this.#auth.currentUser()?.prenom ?? 'Vous');
  readonly authorInitial = computed(() => (this.#auth.currentUser()?.prenom ?? 'V').charAt(0).toUpperCase());

  // ── Filtres sidebar ──
  readonly filters: { key: 'all' | 'resolved' | 'open'; label: string; icon: string }[] = [
    {
      key: 'all',
      label: 'Toutes les discussions',
      icon: 'M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z',
    },
    {
      key: 'open',
      label: 'Sans réponse',
      icon: 'M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z',
    },
    {
      key: 'resolved',
      label: 'Résolues',
      icon: 'M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z',
    },
  ];

  readonly sideStats = computed(() => [
    { label: 'Discussions',    value: this.messages().length },
    { label: 'Résolues',       value: this.messages().filter(m => m.estResolu).length },
    { label: 'Sans réponse',   value: this.messages().filter(m => !(m.reponses?.length)).length },
  ]);

  // ── Messages filtrés ──
  readonly filteredMessages = computed(() => {
    const all = this.messages();
    switch (this.activeFilter()) {
      case 'resolved': return all.filter(m => m.estResolu);
      case 'open':     return all.filter(m => !(m.reponses?.length));
      default:         return all;
    }
  });

  // ── Forms ──
  readonly questionForm = this.#fb.nonNullable.group({
    contenu: ['', [Validators.required, Validators.minLength(10)]],
  });
  readonly replyForm = this.#fb.nonNullable.group({
    contenu: ['', [Validators.required, Validators.minLength(2)]],
  });

  // ── Lifecycle ──
  ngOnInit(): void {
    if (!this.coursId()) {
      this.loading.set(false);
      return;
    }
    this.#svc.getQuestions(this.coursId()).subscribe({
      next: r => {
        if (r.success && r.data?.content?.length) this.messages.set(r.data.content);
        this.loading.set(false);
      },
      error: () => { this.loading.set(false); },
    });
  }

  // ── Actions ──

  focusComposer(): void {
    if (isPlatformBrowser(this.#platformId)) {
      this.composerRef?.nativeElement.focus();
    }
  }

  setFilter(key: 'all' | 'resolved' | 'open'): void {
    this.activeFilter.set(key);
  }

  toggleReply(id: string): void {
    this.activeReply.set(this.activeReply() === id ? null : id);
    this.replyForm.reset();
  }

  submitQuestion(): void {
    this.qSubmitted = true;
    if (this.questionForm.invalid || !this.coursId()) return;
    this.qLoading.set(true);
    this.#svc.publier(this.coursId(), {
      coursId: this.coursId(),
      contenu: this.questionForm.getRawValue().contenu,
      estQuestion: true,
    }).subscribe({
      next: r => {
        this.qLoading.set(false);
        this.questionForm.reset();
        this.qSubmitted = false;
        if (r.success && r.data) {
          this.messages.update(list => [r.data!, ...list]);
          this.#toast.success('Question publiée !', 'Les apprenants et le formateur ont été notifiés.');
        }
      },
      error: () => { this.qLoading.set(false); },
    });
  }

  submitReply(parent: MessageResponse): void {
    if (this.replyForm.invalid) return;
    this.rLoading.set(true);
    this.#svc.publier(this.coursId(), {
      coursId: this.coursId(),
      contenu: this.replyForm.getRawValue().contenu,
      parentId: parent.id,
      estQuestion: false,
    }).subscribe({
      next: r => {
        this.rLoading.set(false);
        if (r.success && r.data) {
          const user = this.#auth.currentUser();
          const rep: MessageResponse = {
            ...r.data,
            auteurPrenom: user?.prenom ?? 'Moi',
          };
          this.messages.update(list =>
            list.map(m => m.id === parent.id ? { ...m, reponses: [...(m.reponses ?? []), rep] } : m)
          );
          this.replyForm.reset();
          this.activeReply.set(null);
          this.#toast.success('Réponse publiée !');
        }
      },
      error: () => { this.rLoading.set(false); },
    });
  }

  // ── Helpers ──

  timeAgo(iso: string): string {
    const ms   = Date.now() - new Date(iso).getTime();
    const mins = Math.floor(ms / 60_000);
    const hrs  = Math.floor(ms / 3_600_000);
    const days = Math.floor(ms / 86_400_000);
    if (days >= 1)  return `il y a ${days}j`;
    if (hrs >= 1)   return `il y a ${hrs}h`;
    return `il y a ${mins}min`;
  }

  /** Couleur déterministe basée sur le prénom */
  avatarColor(prenom: string): string {
    const idx = (prenom.charCodeAt(0) ?? 0) % AVATAR_PALETTE.length;
    return AVATAR_PALETTE[idx];
  }
}