# Piano di Implementazione — Hubso

> Documento di tracciamento delle fasi di sviluppo. Aggiornato ad ogni completamento settimanale.
> **Inizio:** 2026-05-10 | **Durata:** 10 settimane (7 MVP + 3 buffer)

---

## Legend

| Stato | Icona |
|---|---|
| Completata | ✅ |
| In corso | 🔄 |
| Non iniziata | ⬜ |
| Bloccata | 🛑 |

---

## Week 0 — Setup Fondamentali (2026-05-10)

**Goal:** Infrastruttura pronta per lo sviluppo.

| # | Task | Stato | File/Output |
|---|---|---|---|
| 0.1 | Completa Step 8 Architecture | ✅ | `architecture.md` frontmatter aggiornato |
| 0.2 | CI Pipeline GitHub Actions | ✅ | `.github/workflows/ci.yml` |
| 0.3 | Prisma Schema completo | ✅ | `prisma/schema.prisma` (5 modelli) |
| 0.4 | Prisma Service + Module | ✅ | `src/prisma/prisma.service.ts` |
| 0.5 | Docker Compose (DB + Cache) | ✅ | `docker-compose.yml` |
| 0.6 | Prisma Migration Init | ✅ | `migrations/20260510114434_init/` |
| 0.7 | Environment files | ✅ | `.env.example` (backend + frontend) |

**Risultato:** Database sincronizzato, CI pronta, Prisma generato.

---

## Week 1 — Autenticazione Base (2026-05-11 → 2026-05-17)

**Goal:** Utenti possono registrarsi, loggarsi, ricevere email di reset.

| # | Task | Stato | Note |
|---|---|---|---|
| 1.1 | Auth Module NestJS | ⬜ | Register, Login, Logout |
| 1.2 | Password Hashing (bcrypt) | ⬜ | 12 rounds |
| 1.3 | JWT Access + Refresh Token | ⬜ | Access 15min, Refresh 7gg |
| 1.4 | HttpOnly Cookie Auth | ⬜ | Secure, SameSite=Strict |
| 1.5 | JWT Auth Guard | ⬜ | Protegge tutte le route |
| 1.6 | Roles Guard (ADMIN/VIEWER) | ⬜ | RBAC base |
| 1.7 | Password Reset via Email | ⬜ | Resend, token 1h |
| 1.8 | Angular Login Page | ⬜ | Reactive Forms, validation |
| 1.9 | Angular Register Page | ⬜ | Email, password, name |
| 1.10 | Angular Auth Service (Signals) | ⬜ | Stato auth globale |
| 1.11 | Auth Interceptor | ⬜ | Gestione 401, redirect |
| 1.12 | Account Deletion (GDPR) | ⬜ | Cancellazione completa dati |

**Output atteso:**
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/logout`
- `POST /api/v1/auth/refresh`
- `POST /api/v1/auth/forgot-password`
- `POST /api/v1/auth/reset-password`
- `DELETE /api/v1/auth/account`

---

## Week 2 — Instagram OAuth (2026-05-18 → 2026-05-24)

**Goal:** Connessione account Instagram, token cifrato, Business Account validation.

| # | Task | Stato | Note |
|---|---|---|---|
| 2.1 | Meta OAuth Initiate | ⬜ | URL autorizzazione, state CSRF |
| 2.2 | Meta OAuth Callback | ⬜ | Code exchange, long-lived token |
| 2.3 | Token Encryption (AES-256-GCM) | ⬜ | `TokenEncryptionService` |
| 2.4 | SocialAccount CRUD | ⬜ | Collega, scollega, lista |
| 2.5 | Business Account Validation | ⬜ | Controlla tipo account |
| 2.6 | Token Refresh Tracking | ⬜ | Campo `tokenExpiresAt` |
| 2.7 | Angular "Connect Instagram" Page | ⬜ | Bottone + stato |
| 2.8 | Angular Callback Handler | ⬜ | Gestione redirect Meta |
| 2.9 | Error Handling OAuth | ⬜ | Not-Business, denied, expired |
| 2.10 | Mock Meta API Fixtures | ⬜ | JSON per test CI |

**Output atteso:**
- `GET /api/v1/auth/meta/initiate`
- `GET /api/v1/auth/meta/callback`
- `GET /api/v1/social-accounts`
- `DELETE /api/v1/social-accounts/:id`
- Token cifrato in DB

---

## Week 3 — Dashboard Base (2026-05-25 → 2026-05-31)

**Goal:** Dashboard visiva con layout, mock data, skeleton screens.

| # | Task | Stato | Note |
|---|---|---|---|
| 3.1 | Dashboard Layout | ⬜ | Grid, sidebar, header |
| 3.2 | Metric Cards Component | ⬜ | Follower, engagement, reach |
| 3.3 | Media Table Component | ⬜ | Lista post con metriche |
| 3.4 | Stories Panel Component | ⬜ | Metriche stories 24h |
| 3.5 | Date Range Picker | ⬜ | 7/30/90 giorni |
| 3.6 | DashboardState Service | ⬜ | Signals per stato dashboard |
| 3.7 | Mock Metrics Service | ⬜ | Dati fake per sviluppo UI |
| 3.8 | Skeleton Screens | ⬜ | Loading states coerenti |
| 3.9 | Empty States | ⬜ | Nessun account, nessun dato |
| 3.10 | Responsive Layout | ⬜ | Desktop + tablet |

**Output atteso:**
- Dashboard page con layout completo
- Mock data funzionante
- Loading/empty states
- Responsive

---

## Week 4 — Meta API Reale (2026-06-01 → 2026-06-07)

**Goal:** Dati reali da Instagram, cache Redis, aggregazione.

| # | Task | Stato | Note |
|---|---|---|---|
| 4.1 | InstagramApiService | ⬜ | Chiamate a Meta Graph API |
| 4.2 | Cache Redis (15min TTL) | ⬜ | Chiave: `instagram:{id}:{metric}` |
| 4.3 | Metrics Endpoint Backend | ⬜ | Follower, engagement, stories |
| 4.4 | Historical Data Storage | ⬜ | Salvataggio giornaliero in DB |
| 4.5 | Growth Calculation | ⬜ | Percentuale crescita follower |
| 4.6 | Engagement Rate | ⬜ | (like + commenti) / follower |
| 4.7 | Exponential Backoff | ⬜ | Retry su 429 Meta |
| 4.8 | Graceful Degradation | ⬜ | Cache vecchia + messaggio utente |
| 4.9 | Sostituire Mock con API Reale | ⬜ | Frontend chiama dati veri |
| 4.10 | On-Demand Refresh | ⬜ | Bottone refresh (cooldown 5min) |

**Output atteso:**
- `GET /api/v1/dashboard/metrics`
- `GET /api/v1/dashboard/media`
- Dati reali da Instagram
- Cache funzionante

---

## Week 5 — Stripe + Team (2026-06-08 → 2026-06-14)

**Goal:** Pagamenti, trial, inviti team.

| # | Task | Stato | Note |
|---|---|---|---|
| 5.1 | Stripe Setup | ⬜ | Account Stripe, API keys |
| 5.2 | Subscription Model | ⬜ | Trial 30gg, piano unico |
| 5.3 | Stripe Checkout | ⬜ | Pagamento iniziale |
| 5.4 | Stripe Webhook | ⬜ | Gestione eventi pagamento |
| 5.5 | Trial Management | ⬜ | Scadenza, reminder |
| 5.6 | Grace Period | ⬜ | 3 giorni dopo scadenza |
| 5.7 | Team Invites | ⬜ | Admin invita Viewer via email |
| 5.8 | Accept Invite | ⬜ | Link con token, registrazione |
| 5.9 | RBAC Enforcement | ⬜ | Viewer non vede billing/settings |
| 5.10 | Billing Page | ⬜ | Gestione abbonamento |

**Output atteso:**
- `POST /api/v1/subscriptions/checkout`
- `POST /api/v1/webhooks/stripe`
- `POST /api/v1/team/invite`
- `POST /api/v1/team/accept`
- Pagamento funzionante

---

## Week 6 — Admin + Email + Onboarding (2026-06-15 → 2026-06-21)

**Goal:** Pannello admin, email transactional, onboarding.

| # | Task | Stato | Note |
|---|---|---|---|
| 6.1 | Admin Panel Backend | ⬜ | Lista utenti, metriche |
| 6.2 | Admin Panel Frontend | ⬜ | Tabella utenti, filtri |
| 6.3 | User Metrics API | ⬜ | DAU, MAU, conversion rate |
| 6.4 | Resend Integration | ⬜ | Configurazione API |
| 6.5 | Welcome Email | ⬜ | Dopo registrazione |
| 6.6 | Trial Reminder Email | ⬜ | 7gg, 3gg, 1gg prima scadenza |
| 6.7 | Password Reset Email | ⬜ | Link con token 1h |
| 6.8 | Onboarding Wizard | ⬜ | Step 1-2-3 dopo primo login |
| 6.9 | Landing Page SSR | ⬜ | SEO, CTA, demo |
| 6.10 | Error Pages | ⬜ | 404, 500, offline |

**Output atteso:**
- `GET /api/v1/admin/users`
- `GET /api/v1/admin/metrics`
- Email inviate da Resend
- Onboarding wizard

---

## Week 7 — Testing + Bugfix + Deploy Staging (2026-06-22 → 2026-06-28)

**Goal:** Qualità, deploy staging, smoke tests.

| # | Task | Stato | Note |
|---|---|---|---|
| 7.1 | Unit Tests Backend | ⬜ | Auth, OAuth, Dashboard services |
| 7.2 | E2E Tests Backend | ⬜ | Flussi critici API |
| 7.3 | Unit Tests Frontend | ⬜ | Componenti, services |
| 7.4 | E2E Tests Frontend | ⬜ | Playwright/Cypress |
| 7.5 | Performance Audit | ⬜ | Bundle size, query optimization |
| 7.6 | Security Audit | ⬜ | XSS, CSRF, SQL injection |
| 7.7 | Railway Deploy Staging | ⬜ | Ambiente di test |
| 7.8 | Smoke Tests | ⬜ | Flussi end-to-end su staging |
| 7.9 | Bugfix Round 1 | ⬜ | Fix bug critici |
| 7.10 | Documentazione API | ⬜ | OpenAPI/Swagger |

**Output atteso:**
- Staging deployato su Railway
- Test suite green
- Bugfix completati

---

## Week 8-10 — Buffer (2026-06-29 → 2026-07-19)

**Goal:** Polish, feature avanzate, preparazione produzione.

| # | Task | Stato | Note |
|---|---|---|---|
| 8.1 | RFC 7807 Problem Details | ⬜ | Evoluzione errori API |
| 8.2 | Caching Avanzato | ⬜ | Cache invalidation strategy |
| 8.3 | OpenAPI + Type Sharing | ⬜ | Tipi auto-generati per frontend |
| 8.4 | API Virtualization | ⬜ | Mock avanzato Instagram in CI |
| 8.5 | Correlation ID Logging | ⬜ | Tracciamento request end-to-end |
| 8.6 | Mobile Polish | ⬜ | Ottimizzazione mobile |
| 8.7 | Accessibility Audit | ⬜ | WCAG 2.1 AA |
| 8.8 | Analytics Tracking | ⬜ | Mixpanel/Plausible |
| 8.9 | Production Deploy | ⬜ | Railway production |
| 8.10 | Post-Mortem Document | ⬜ | Lezioni apprese |

**Output atteso:**
- Produzione live
- Documentazione completa
- Monitoraggio attivo

---

## Metriche di Avanzamento

| Settimana | Task Completati | Task Totali | Progresso |
|---|---|---|---|
| Week 0 | 7 | 7 | **100%** ✅ |
| Week 1 | 0 | 12 | 0% ⬜ |
| Week 2 | 0 | 10 | 0% ⬜ |
| Week 3 | 0 | 10 | 0% ⬜ |
| Week 4 | 0 | 10 | 0% ⬜ |
| Week 5 | 0 | 10 | 0% ⬜ |
| Week 6 | 0 | 10 | 0% ⬜ |
| Week 7 | 0 | 10 | 0% ⬜ |
| Week 8-10 | 0 | 10 | 0% ⬜ |
| **Totale** | **7** | **89** | **7.9%** |

---

## Note e Decisioni

**2026-05-10 (Week 0):**
- Prisma 7 richiede `prisma.config.ts` separato (non supporta più `url` nello schema)
- Docker compose usa `docker compose` (senza trattino) su questa macchina
- NestJS Prisma module creato in `src/prisma/`

**Prossima Sessione:**
- Iniziare Week 1 — Auth Base
- Priorità: Register/Login JWT con HttpOnly cookies
- Branch: `feature/week-1-auth`
