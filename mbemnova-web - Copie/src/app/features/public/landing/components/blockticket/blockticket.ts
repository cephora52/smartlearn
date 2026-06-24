import { ChangeDetectorRef, Component, inject, PLATFORM_ID, signal } from '@angular/core';
import { DrawResponse } from '../../../../../core/models';
import { MOCK_DRAW } from '../../../../../core/services/mock.data';
import { CommonModule, isPlatformBrowser } from '@angular/common';



interface CountdownUnit {
  value: string;
  label: string;
}
 
interface Particle {
  x: number;
  y: number;
  size: number;
  delay: number;
  duration: number;
  color: string;
}
 
interface MiniAvatar {
  i: string;
  bg: string;
}
 

@Component({
  selector: 'app-blockticket',
  imports: [CommonModule],
  templateUrl: './blockticket.html',
  styleUrl: './blockticket.css',
})
export class Blockticket {

  readonly #cdr = inject(ChangeDetectorRef);
 
  // ── State ──
  readonly draw = signal<DrawResponse>(MOCK_DRAW);
  visible = true;

  private platformId = inject(PLATFORM_ID);

private isBrowser = isPlatformBrowser(this.platformId);
 
  countdown: CountdownUnit[] = [
    { value: '00', label: 'jours' },
    { value: '00', label: 'heures' },
    { value: '00', label: 'min' },
    { value: '00', label: 'sec' },
  ];
 
  // ── Decoration ──
  readonly particles: Particle[] = this.#generateParticles(18);
 
  readonly miniAvatars: MiniAvatar[] = [
    { i: 'A', bg: '#d97706' },
    { i: 'K', bg: '#b45309' },
    { i: 'S', bg: '#92400e' },
    { i: 'F', bg: '#78350f' },
  ];
 
  private countdownInterval: ReturnType<typeof setInterval> | null = null;
  private readonly DISMISS_KEY = 'mbemx_ticket_dismissed';
 
  // ── Lifecycle ──
 
ngOnInit(): void {
  if (this.isBrowser) {
    if (sessionStorage.getItem(this.DISMISS_KEY) === 'true') {
      this.visible = false;
      this.#cdr.markForCheck();
      return;
    }
  }
  this.#startCountdown();
}
  ngOnDestroy(): void {
    if (this.countdownInterval) clearInterval(this.countdownInterval);
  }
 
  // ── Actions ──
 
  dismiss(): void {
    // Store in sessionStorage → banner hidden for this session
    // On next visit (new tab/session), it shows again if ticket not bought
    sessionStorage.setItem(this.DISMISS_KEY, 'true');
    this.visible = false;
    this.#cdr.markForCheck();
  }
 
  // ── Countdown ──
 
 #startCountdown(): void {
  if (!this.isBrowser) return; // ← ajoute cette ligne
  const target = this.#getDrawTarget();
  this.#tick(target);
  this.countdownInterval = setInterval(() => {
    this.#tick(target);
    this.#cdr.markForCheck();
  }, 1000);
}
 
  #getDrawTarget(): Date {
    // Try to parse draw().dateDrawFormatee — fallback to end of current month
    try {
      const raw = this.draw().dateDrawFormatee;
      if (raw) {
        const parsed = new Date(raw);
        if (!isNaN(parsed.getTime())) return parsed;
      }
    } catch {}
    // Fallback: last day of current month 23:59:59
    const now = new Date();
    return new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);
  }
 
  #tick(target: Date): void {
    const now = new Date();
    const diff = Math.max(0, target.getTime() - now.getTime());
 
    const days    = Math.floor(diff / 86_400_000);
    const hours   = Math.floor((diff % 86_400_000) / 3_600_000);
    const minutes = Math.floor((diff % 3_600_000) / 60_000);
    const seconds = Math.floor((diff % 60_000) / 1_000);
 
    this.countdown = [
      { value: String(days).padStart(2, '0'),    label: 'jours' },
      { value: String(hours).padStart(2, '0'),   label: 'heures' },
      { value: String(minutes).padStart(2, '0'), label: 'min' },
      { value: String(seconds).padStart(2, '0'), label: 'sec' },
    ];
  }
 
  // ── Particles generator ──
 
  #generateParticles(n: number): Particle[] {
    const colors = [
      'rgba(251,191,36,0.5)',
      'rgba(245,158,11,0.4)',
      'rgba(217,119,6,0.3)',
      'rgba(251,191,36,0.2)',
    ];
    return Array.from({ length: n }, () => ({
      x:        Math.random() * 100,
      y:        Math.random() * 100,
      size:     Math.random() * 3 + 1,
      delay:    Math.random() * 6,
      duration: Math.random() * 8 + 6,
      color:    colors[Math.floor(Math.random() * colors.length)],
    }));
  }
}