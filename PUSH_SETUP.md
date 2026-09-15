# Notifications Push — FCM + Supabase Edge Function

## Principe d'architecture

La **Supabase Edge Function `push`** (Deno, `.supabase/functions/push/index.ts`)
sert de serveur central :

```
┌───────────────────┐                        ┌───────────────────────────┐
│  App Flutter      │  1. token FCM          │   Supabase (Postgres)     │
│  (Android / iOS)  │───────────────────────▶│  • push_subscriptions    │
│                   │  (push_subscriptions)  │  • notifications         │
│                   │                        └────────────▲────────────┘
│                   │  2. après publication :            │
│                   │     functions.invoke('push')        │ 4. insert
│                   │──────────────┐                      │
└───────────────────┘              ▼                      │
                       ┌─────────────────────┐            │
                       │ Edge Function push  │────────────┘
                       │  • vérifie le JWT   │
                       │  • lit les tokens   │  3. API FCM HTTP v1
                       │    FCM destinataires│──────────┐
                       └─────────────────────┘          ▼
                                                   ┌─────────┐         ┌──────────┐
                                                   │   FCM   │────────▶│  Appareils│
                                                   └─────────  5.     │  Android /
                                                                      │  iOS       │
                                                                      └──────────┘
```

- Chaque appareil enregistre son **token FCM** dans `push_subscriptions`
  (au démarrage, au login, au refresh du token) — via
  `lib/services/push_service.dart`.
- Après une publication, l'app appelle la fonction `push` avec les
  destinataires (les autres membres de la famille).
- La fonction **vérifie le JWT Supabase** de l'expéditeur, récupère les
  tokens FCM, envoie le push via l'**API HTTP v1 de FCM** (Google) et
  enregistre une ligne dans `notifications` → le **badge de la cloche**
  reflète le vrai nombre de non-lus.
- La fonction parle à Google avec une **clé service account** stockée en
  secret Supabase : la clé ne circule jamais dans l'app.

## Mise en place (une seule fois)

### 1. Projet Firebase

1. [console.firebase.google.com](https://console.firebase.google.com) →
   **Ajouter un projet** (ex. `familly-blog`).
2. **App Android** (icône `A`) :
   - Package : `com.example.familly_blog`
   - Télécharger `google-services.json` → le placer dans
     `android/app/google-services.json`
3. **App iOS** (icône ) :
   - Bundle ID : `com.example.famillyBlog`
   - Télécharger `GoogleService-Info.plist` → le placer dans
     `ios/Runner/GoogleService-Info.plist`
   - Dans Xcode : **Signing & Capabilities** → **+ Capability** →
     **Push Notifications**
4. Noter le **Project ID** (Paramètres du projet → Vos apps → "Project ID").
5. **Push iOS (APNs)** :
   - [developer.apple.com](https://developer.apple.com/account/resources/keys/list)
     → Keys → **+** → **Apple Push Notifications** (Production) →
     télécharger la clé `.p8`
   - Firebase → Paramètres du projet → **Cloud Messaging** → section
     *Apple APNs authentication key* → uploader le `.p8` + Key ID + Team ID
   (pour Android, rien à faire : c automatique via google-services.json)

### 2. Supabase

1. Exécuter la migration **`lib/migrations/002_push_notifications.sql`**
   (Dashboard → SQL Editor, ou `supabase db push`).
2. Générer un **service account** Firebase :
   Paramètres du projet → Service accounts → *Générer une nouvelle clé
   privée* → JSON téléchargé.
3. Renseigner les secrets (Dashboard → Project Settings → Edge Functions →
   **Secrets**, ou CLI après `supabase link`) :
   ```bash
   supabase secrets set FCM_PROJECT_ID="votre-firebase-project-id"
   supabase secrets set FCM_SERVICE_ACCOUNT="$(cat service-account.json)"
   ```
4. Déployer la fonction :
   ```bash
   supabase functions deploy push
   ```
   ou via le Dashboard : **Edge Functions** → *New function* → nom `push` →
   coller le code de `.supabase/functions/push/index.ts` → *Deploy*.

### 3. App

```bash
flutter pub get
```

- Au premier lancement, l'app demande la **permission notifications**.
- FCM ne fonctionne que sur **appareil physique** (ou émulateur avec
  Google Play services).

## Test manuel

1. Installer l'app sur 2 appareils (ou téléphone + émulateur Google Play).
2. Se connecter avec 2 comptes de la famille.
3. Publier un message depuis l'appareil A → l'appareil B reçoit
   « *X a partagé un nouveau message* » et le badge de la cloche s'incrémente.
4. Taper la cloche sur l'appareil B → liste des notifications →
   « Tout marquer lu ».

## Ajouter d'autres déclencheurs (comment, message privé, événement)

Même pattern : appeler la fonction juste après l'insert Supabase.
**Ne jamais inclure l'expéditeur dans `user_ids`.**

```dart
await _supabase.functions.invoke('push', body: {
  'title': 'Nouvelle réponse',
  'body': '$authorName a répondu à votre publication',
  'type': 'comment',
  'ref_id': messageId,
  'user_ids': [postAuthorId],
});
```

## Dépannage

| Symptôme | Piste |
|---|---|
| 401 depuis l'app | Utilisateur non connecté (pas de JWT) |
| `sent: 0, recipients: 0` | Le destinataire n'a pas de token FCM enregistré (app jamais ouverte depuis l'installation, permission refusée, pas encore connecté) |
| FCM 403 | Service account sans accès au projet Firebase, ou `FCM_PROJECT_ID` erroné |
| FCM 404 par token | Token mort → la fonction le supprime d'elle-même, redémarrer l'app du destinataire |
| Rien sur iOS | Clé APNs non configurée, capability Push manquante dans Xcode, ou profil non signé avec la capability |
