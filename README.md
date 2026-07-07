# On the Go

Peer-to-peer package delivery for Kenya — senders post packages, travelers
already heading that way carry them for a fee. Flutter, Android-first.

## Run it

```bash
flutter pub get
flutter run          # or: flutter build apk --debug
```

The MVP runs fully self-contained — no API keys, no backend. Sign in with any
Kenyan phone number and any 6-digit OTP.

## Demo flows

- **Traveler:** Home map → tap a price pin (or a card in the bottom sheet) →
  Claim delivery → Mark as picked up → watch the package move → Mark as
  delivered → rate the sender.
- **Sender:** Send a package (orange button) → fill the form → Post package →
  a demo traveler claims after ~5 s, picks up, and drives the route while you
  track live → Confirm receipt → rate the traveler.

## Architecture (mossbets conventions)

- **GetX** for state, routing, and DI: `GetMaterialApp` + `AppRoutes`/`AppPages`,
  one controller + binding per module, `Obx` views.
- **Singleton service:** `core/services/delivery_service.dart`
  (`factory → _instance`) owns the package board, lifecycle transitions
  (Posted → Claimed → Picked Up → In Transit → Delivered → Confirmed), and the
  demo simulation timers. Snackbar notifications stand in for FCM.
- **Modules:** `auth` (Google sign-in), `home` (discovery map), `package_details`
  (claim), `post_package` (sender form), `delivery` (traveler active view),
  `tracking` (sender live view), `profile`, `rating`.
- **Stylized map:** `widgets/stylized_map.dart` paints the pale street canvas
  from the design board and positions pins by normalized (0..1) coordinates.

## Swapping in production services

| Demo piece | Production replacement (PRD §6) |
|---|---|
| `StylizedMap` + normalized offsets | `google_maps_flutter`, Places, Directions (lat/lng) |
| `DeliveryService` timers | REST + WebSocket, or Firestore listeners |
| `Get.snackbar` notices | Firebase Cloud Messaging |
| — | Google sign-in via Firebase Auth (done) |
| Static "you are here" dot | `geolocator` foreground updates during active delivery |

Location privacy: traveler position is shared only with the sender of the
active claimed package, and sharing stops at delivery.
