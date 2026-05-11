# Instagram Graph API — Technical Reference for Hubso

> **Documento di riferimento tecnico** per l'implementazione delle API Instagram/Meta in Hubso.
> Ultimo aggiornamento: 2026-05-08

---

## Indice

1. [Panoramica API](#panoramica-api)
2. [Prerequisiti](#prerequisiti)
3. [Flusso OAuth 2.0](#flusso-oauth-20)
4. [Endpoint Principali](#endpoint-principali)
5. [Rate Limiting](#rate-limiting)
6. [Gestione Token](#gestione-token)
7. [Errori Comuni](#errori-comuni)
8. [Schema Dati](#schema-dati)
9. [Checklist Implementazione](#checklist-implementazione)

---

## Panoramica API

Meta offre **due API Instagram** con scopi diversi:

| API | Scopo | Account Richiesto | Dati Analytics |
|---|---|---|---|
| **Instagram Graph API** | Analytics, insights, gestione | Business/Creator + Facebook Page | ✅ Sì |
| **Instagram Basic Display API** | Lettura profilo personale | Personale | ❌ No |

**Hubso usa Instagram Graph API** — unica che fornisce metriche di engagement, reach, follower.

**Base URL:** `https://graph.facebook.com/v19.0/`

---

## Prerequisiti

Per ogni utente che collega un account Instagram:

1. **Account Instagram Business o Creator** — Account personali NON funzionano
2. **Pagina Facebook collegata** — L'account Business deve essere collegato a una Facebook Page
3. **Ruolo Admin sulla Pagina** — L'utente deve essere admin della Facebook Page collegata
4. **App Facebook configurata** — Richiede App ID, App Secret, OAuth redirect URI

---

## Flusso OAuth 2.0

### Step 1: Generare URL di Autorizzazione

```
GET https://www.facebook.com/v19.0/dialog/oauth
  ?client_id={APP_ID}
  &redirect_uri=https://hubso.io/api/v1/auth/meta/callback
  &scope=instagram_basic,pages_read_engagement
  &state={CSRF_TOKEN}
  &response_type=code
```

**Scope necessari per Hubso MVP:**
- `instagram_basic` — Lettura profilo, media, insights
- `pages_read_engagement` — Accesso alle metriche della pagina collegata

**Scope opzionali (futuro):**
- `instagram_content_publish` — Pubblicazione post da Hubso
- `instagram_manage_insights` — Insights avanzati (richiede review Meta)

### Step 2: Gestire il Callback

Meta reindirizza a:
```
https://hubso.io/api/v1/auth/meta/callback?code=AQC...&state=xyz
```

**Validazioni da fare:**
- Verificare che `state` combaci con quello generato
- Verificare presenza del parametro `code`

### Step 3: Scambiare Code per Access Token

```typescript
const response = await fetch('https://graph.facebook.com/v19.0/oauth/access_token', {
  method: 'POST',
  headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  body: new URLSearchParams({
    client_id: process.env.META_APP_ID,
    client_secret: process.env.META_APP_SECRET,
    redirect_uri: 'https://hubso.io/api/v1/auth/meta/callback',
    code: authorizationCode,
  }),
});

const { access_token, expires_in } = await response.json();
// access_token: valido ~60 giorni
// expires_in: secondi alla scadenza
```

### Step 4: Ottenere Long-Lived Token

Il token iniziale dura ~1 ora. Scambiarlo per uno a lungo termine:

```typescript
const response = await fetch(
  `https://graph.facebook.com/v19.0/oauth/access_token?` +
  `grant_type=fb_exchange_token&` +
  `client_id=${appId}&` +
  `client_secret=${appSecret}&` +
  `fb_exchange_token=${shortLivedToken}`
);

const { access_token, expires_in } = await response.json();
// Long-lived token: valido 60 giorni
```

### Step 5: Risalire all'Instagram Business Account ID

Dopo avere il token, ottenere l'ID Instagram Business collegato alla pagina:

```typescript
// A. Ottieni le pagine Facebook dell'utente
const pagesRes = await fetch(
  `https://graph.facebook.com/v19.0/me/accounts?access_token=${token}`
);
const { data: pages } = await pagesRes.json();
// pages[0].id = Facebook Page ID

// B. Dalla pagina, ottieni l'account Instagram Business
const igRes = await fetch(
  `https://graph.facebook.com/v19.0/${pageId}?` +
  `fields=instagram_business_account&access_token=${token}`
);
const { instagram_business_account } = await igRes.json();
// instagram_business_account.id = Instagram Business Account ID
```

### Step 6: Salvare nel Database

```typescript
await prisma.socialAccount.create({
  data: {
    platform: 'instagram',
    accountId: instagramBusinessAccountId,
    pageId: facebookPageId,
    accessToken: encrypt(longLivedToken), // AES-256-GCM
    tokenExpiresAt: new Date(Date.now() + expiresIn * 1000),
    userId: currentUser.id,
  },
});
```

---

## Endpoint Principali

### Account Insights

```
GET /{ig-business-id}/insights
  ?metric={METRIC_LIST}
  &period={day|week|days_28|lifetime}
  &since={YYYY-MM-DD}
  &until={YYYY-MM-DD}
  &access_token={TOKEN}
```

**Metriche disponibili:**

| Metrica | Descrizione | Periodo |
|---|---|---|
| `follower_count` | Numero follower | day, lifetime |
| `impressions` | Impression totali | day, week, days_28 |
| `reach` | Utenti unici raggiunti | day, week, days_28 |
| `profile_views` | Visite al profilo | day, week, days_28 |
| `website_clicks` | Click sul link in bio | day, week, days_28 |
| `email_contacts` | Click su email | day, week, days_28 |
| `phone_call_clicks` | Click su telefono | day, week, days_28 |
| `text_message_clicks` | Click su SMS | day, week, days_28 |
| `get_directions_clicks` | Click su indicazioni | day, week, days_28 |

**Esempio risposta:**
```json
{
  "data": [
    {
      "name": "impressions",
      "period": "day",
      "values": [
        {
          "value": 1250,
          "end_time": "2026-05-06T07:00:00+0000"
        },
        {
          "value": 1890,
          "end_time": "2026-05-07T07:00:00+0000"
        }
      ],
      "title": "Impressions",
      "description": "Total number of times this profile has been seen"
    }
  ]
}
```

### Media (Post) List

```
GET /{ig-business-id}/media
  ?fields=id,caption,media_type,media_url,permalink,timestamp,like_count,comments_count
  &limit=25
  &access_token={TOKEN}
```

**Campi disponibili:**
- `id` — ID del media
- `caption` — Didascalia
- `media_type` — `IMAGE`, `VIDEO`, `CAROUSEL_ALBUM`, `REELS`
- `media_url` — URL del contenuto (immagine/video)
- `permalink` — Link pubblico al post
- `timestamp` — Data pubblicazione (ISO 8601)
- `like_count` — Numero like
- `comments_count` — Numero commenti

### Media Insights

```
GET /{media-id}/insights
  ?metric=engagement,impressions,reach,saved,video_views
  &access_token={TOKEN}
```

**Metriche per media:**

| Metrica | Tipo Media | Descrizione |
|---|---|---|
| `engagement` | Tutti | Like + commenti + salvataggi + condivisioni |
| `impressions` | Tutti | Volte mostrato |
| `reach` | Tutti | Utenti unici |
| `saved` | Tutti | Salvataggi |
| `video_views` | VIDEO, REELS | Visualizzazioni video |
| `plays` | REELS | Riproduzioni |
| `shares` | Tutti | Condivisioni |
| `total_interactions` | Tutti | Interazioni totali |

### Stories

```
GET /{ig-business-id}/stories
  ?fields=id,caption,media_type,media_url,permalink,timestamp
  &access_token={TOKEN}
```

**Nota:** Le stories sono disponibili solo per 24 ore dopo la pubblicazione.

### Story Insights

```
GET /{story-id}/insights
  ?metric=exits,impressions,reach,replies,taps_forward,taps_back
  &access_token={TOKEN}
```

---

## Rate Limiting

### Limiti Attuali (v19.0)

| Tipo | Limite | Reset |
|---|---|---|
| **Calls per User** | 200 chiamate/ora per utente | Ora solare |
| **Business Use Case** | 100 chiamate/60s per token | 60 secondi |

**Header nelle risposte:**
```
x-app-usage: {"call_count": 28, "total_cputime": 15, "total_time": 12}
```

- `call_count` — % del limite orario consumato
- `total_cputime` — % CPU time consumato
- `total_time` — % tempo totale consumato

### Strategie per Hubso

1. **Cache Redis (15 min)** — Non rifare chiamate per dati già recenti
2. **Batch con field expansion** — Prendere più dati in una chiamata
3. **Exponential backoff** — 1s → 2s → 4s → 8s su 429
4. **Background jobs** — Raccolta dati in cron, non in request utente
5. **Monitoraggio header** — Rallentare prima di hitare il limite

---

## Gestione Token

### Durata Token

| Tipo | Durata | Refresh |
|---|---|---|
| Short-lived | ~1 ora | Scambio per long-lived |
| Long-lived | 60 giorni | Uso implicito (si resetta a 60gg) |

**IMPORTANTE:** Instagram Graph API non supporta refresh token classico OAuth2.

### Strategia Hubso

1. **Tracciare scadenza** — Campo `tokenExpiresAt` nel DB
2. **Email reminder** — 7 giorni prima della scadenza
3. **Re-autenticazione** — Bottone "Riconnetti account" che rifà OAuth
4. **Uso del token** — Ogni chiamata API resetta la scadenza a 60 giorni

### Revoca

L'utente può revocare i permessi in qualsiasi momento:
- Dalle impostazioni Instagram: `Settings > Apps and Websites`
- Il token diventa immediatamente invalido
- Hubso deve gestire l'errore `#190` e richiedere nuova autenticazione

---

## Errori Comuni

| Codice | Messaggio | Causa | Soluzione |
|---|---|---|---|
| `#4` | Application request limit reached | Rate limit hit | Backoff + cache |
| `#10` | Application does not have permission | Scope mancante | Verificare scope OAuth |
| `#13` | User has not authorized application | Utente ha revocato | Re-autenticazione |
| `#17` | API User request limit reached | User rate limit | Backoff |
| `#24` | Page not found | Pagina scollegata | Verificare collegamento |
| `#25` | Missing Permissions | Ruolo insufficiente | Admin richiesto |
| `#32` | Page request limit reached | Page rate limit | Backoff |
| `#100` | Invalid parameter | Parametro errato | Verificare richiesta |
| `#190` | Access token has expired | Token scaduto | Re-autenticazione |
| `#200` | Permissions error | Permessi insufficienti | Verificare scope |
| `#368` | The action attempted has been deemed abusive | Comportamento sospetto | Controllare pattern chiamate |

---

## Schema Dati

### Prisma Schema — SocialAccount

```prisma
model SocialAccount {
  id            String    @id @default(uuid())
  platform      String    // "instagram"
  accountId     String    @map("account_id") // Instagram Business ID
  pageId        String?   @map("page_id")    // Facebook Page ID
  accountName   String?   @map("account_name")
  accountHandle String?   @map("account_handle") // @username
  
  // Token (cifrato)
  accessToken   String    @map("access_token")
  tokenExpiresAt DateTime? @map("token_expires_at")
  
  // Stato
  isActive      Boolean   @default(true) @map("is_active")
  lastSyncedAt  DateTime? @map("last_synced_at")
  
  // Relazioni
  userId        String    @map("user_id")
  user          User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  createdAt     DateTime  @default(now()) @map("created_at")
  updatedAt     DateTime  @updatedAt @map("updated_at")
  
  @@map("social_accounts")
}
```

### DTO — Meta OAuth Callback

```typescript
// hubso-api/src/auth/dto/meta-callback.dto.ts
export class MetaCallbackDto {
  code: string;
  state: string;
}
```

### DTO — Social Account Response

```typescript
// hubso-api/src/social-accounts/dto/social-account.dto.ts
export class SocialAccountDto {
  id: string;
  platform: string;
  accountName: string;
  accountHandle: string;
  isActive: boolean;
  lastSyncedAt: Date | null;
}
```

---

## Checklist Implementazione

### Setup Iniziale

- [ ] Registrare app su [developers.facebook.com](https://developers.facebook.com)
- [ ] Aggiungere "Instagram Graph API" ai prodotti dell'app
- [ ] Configurare OAuth redirect URI (`https://hubso.io/api/v1/auth/meta/callback`)
- [ ] Impostare App ID e App Secret in `.env`
- [ ] Sottomettere app per Business Verification (se necessario)

### Backend

- [ ] Creare endpoint `POST /api/v1/auth/meta/initiate` — Genera URL OAuth
- [ ] Creare endpoint `GET /api/v1/auth/meta/callback` — Gestisce callback
- [ ] Implementare scambio code → token
- [ ] Implementare short-lived → long-lived token
- [ ] Implementare risalita Page ID → Instagram Business ID
- [ ] Cifrare token con AES-256-GCM prima del salvataggio
- [ ] Implementare endpoint `GET /api/v1/accounts/{id}/metrics`
- [ ] Implementare endpoint `GET /api/v1/accounts/{id}/media`
- [ ] Implementare cache Redis per i dati API
- [ ] Implementare exponential backoff per rate limit
- [ ] Implementare cron job per sincronizzazione periodica
- [ ] Implementare notifica scadenza token (7gg prima)

### Frontend

- [ ] Creare pagina "Connetti Instagram"
- [ ] Bottone "Connetti con Meta" — Apre popup OAuth
- [ ] Gestire callback e mostrare stato connessione
- [ ] Mostrare lista account collegati
- [ ] Implementare bottone "Riconnetti" per token scaduti
- [ ] Implementare bottone "Scollega" per rimozione account

### Testing

- [ ] Mockare le risposte Meta API nei test
- [ ] Testare flusso OAuth completo
- [ ] Testare gestione errori (token scaduto, rate limit)
- [ ] Testare cifratura/decifratura token

---

## Risorse Utili

- [Meta for Developers](https://developers.facebook.com/)
- [Instagram Graph API Reference](https://developers.facebook.com/docs/instagram-api/reference)
- [Graph API Explorer](https://developers.facebook.com/tools/explorer) — Testare le chiamate API
- [Access Token Debugger](https://developers.facebook.com/tools/debug/accesstoken/) — Verificare token
- [Meta App Review](https://developers.facebook.com/docs/app-review) — Processo di approvazione

---

## Note per Hubso

**Per l'MVP (30 FR, 7 settimane):**
- Supportare solo 1 account Instagram per utente
- Focus su: follower_count, impressions, reach, engagement
- Cache di 15 minuti per tutti i dati
- Sincronizzazione in background ogni 6 ore
- Notifica scadenza token via email

**Per la Growth Phase:**
- Supporto multi-account
- Metriche avanzate (stories, Reels insights)
- Esportazione dati (CSV, PDF)
- Confronto account multipli