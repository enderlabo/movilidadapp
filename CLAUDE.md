# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project overview

**tarifario_movilidad** — Cross-platform Flutter app (mobile · web · desktop) that calculates freight transport tariffs for a scaffolding company operating in Peru. It computes fuel cost (loaded outbound + empty return), tolls, and PEN→USD conversion, then saves the quotation history to Firestore.

> **Current state:** The domain and presentation layers are largely complete. The data layer (repository implementations) has NOT been written yet. Firebase init and `InjectionContainer.init()` are commented out in `main.dart`. All screens still use placeholder routes. The app compiles and shows the UI shell but produces no real data.

---

## Commands

```bash
# Run on connected device / Chrome
flutter run

# Run on Chrome specifically
flutter run -d chrome

# Build for Windows
flutter build windows

# Static analysis
flutter analyze

# Regenerate Freezed / Riverpod / json_serializable code (do this after editing any @freezed or @riverpod class)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for code generation during development
dart run build_runner watch --delete-conflicting-outputs

# Run all unit tests
flutter test test/unit/
```

---

## Architecture

### Layer overview

```
lib/
├── core/               — shared across features
│   ├── error/          — Failure sealed union (dartz Either)
│   ├── network/        — LocalCache (SharedPreferences wrapper)
│   ├── theme/          — AppTheme + GlassCard widget
│   └── utils/          — PlatformUtils (isMobile/isDesktop detection)
├── features/           — one folder per vertical feature
│   ├── vehicles/       — Vehicle entity + IVehicleRepository
│   ├── routes/         — RouteResult, Waypoint, IRouteRepository
│   ├── tariff/         — core business: TariffCalculatorService, use cases, TariffScreen
│   └── tolls/          — toll catalog, TollMatcherService, TollMatchingViewModel
├── injection/          — GetIt InjectionContainer
├── router/             — go_router AppRouter + AppRoutes constants
└── main.dart
```

Each feature follows Clean Architecture:
```
feature/
├── domain/
│   ├── entities/       — @freezed, immutable, pure Dart
│   ├── repositories/   — abstract interface class (never imported by other features directly)
│   ├── usecases/       — one use case = one operation, returns Either<Failure, T>
│   └── services/       — pure domain logic, no I/O (TariffCalculatorService, TollMatcherService)
├── data/               — NOT YET IMPLEMENTED
│   ├── datasources/    — Firestore + local (SharedPreferences via LocalCache)
│   ├── models/         — @freezed + json_serializable
│   └── repositories/   — implements domain interfaces
└── presentation/
    ├── viewmodels/     — @riverpod class extending _$ClassName (code-generated)
    ├── screens/        — ConsumerWidget pages
    └── widgets/        — reusable ConsumerWidget components
```

### Key design decisions

**Error handling:** All repository and use-case return types are `Either<Failure, T>` from `dartz`. Failures are a `@freezed` sealed union in `core/error/failures.dart`. Exceptions must never escape the data layer.

**State management:** Riverpod with `@riverpod` code generation. ViewModels are `@riverpod class X extends _$X` with a `TariffState`/`TollState` Freezed union as the `state`. Input fields (origin, destination, vehicle) are stored in a secondary `_input` field separate from the UI state to avoid rebuilds on every keystroke.

**Dependency injection:** GetIt (`sl` singleton). Providers in viewmodels throw `UnimplementedError` and are overridden in `InjectionContainer.init()`. The DI wiring order is: external → data layer → domain services → use cases.

**Platform-adaptive map:** `MapWidget` branches on `kIsWeb`: native uses `google_maps_flutter` SDK; web uses `HtmlElementView` with the Google Maps JS API. The domain layer is unaware of which is active.

**Toll workflow:** When Maps returns detected tolls, `TollMatcherService` cross-references them against the Firestore toll catalog using Haversine proximity (≤0.5 km radius) + fuzzy name matching. Unconfirmed tolls trigger a `TollReviewSheet` bottom sheet where the manager corrects amounts before the final tariff is calculated.

**Tariff formula:**
```
fuel_outbound  = distance_km / loaded_efficiency_km_per_gallon × price_per_gallon_soles
fuel_return    = distance_km / empty_efficiency_km_per_gallon  × price_per_gallon_soles
total_soles    = fuel_outbound + fuel_return + tolls_soles
total_usd      = total_soles / exchange_rate_pen_usd
```
This logic lives exclusively in `TariffCalculatorService` — do not duplicate it anywhere.

### Routing

Named routes are declared as constants in `AppRoutes` (`router/app_router.dart`). All screens are currently wired to `_PlaceholderScreen`; replace the `builder:` closures with real screens as they are implemented.

---

## Important implementation gaps (what to build next)

1. **Data layer** — create `features/*/data/` for each feature:
   - `TariffRepositoryImpl`: fetches fuel price from OSINERGMIN via Dio + caches with `LocalCache`; fetches exchange rate from SBS API.
   - `RouteRepositoryImpl`: calls Google Maps Routes API, implements `autocompleteAddress` and `geocodeAddress` for `AddressSearchField`.
   - `VehicleRepositoryImpl`: CRUD on Firestore `vehicles` collection.
   - `TollRepositoryImpl`: Firestore `tolls` collection with `createToll`, `updateTollTarifa`, `deactivateToll`.
   - `QuotationRepositoryImpl`: saves to Firestore `quotations` + mirrors to `LocalCache` for offline history.

2. **Wire Firebase** — run `flutterfire configure`, uncomment `Firebase.initializeApp()` and `InjectionContainer.init()` in `main.dart`.

3. **Replace placeholder routes** — connect `AppRoutes.home` and `AppRoutes.calcular` to `TariffScreen`.

4. **Integrate real GoogleMap** — uncomment `GoogleMap(...)` in `_NativeMapWidgetState` and implement the JS API factory registration in `main.dart` for `_WebMapWidget`.

---

## Known bugs / code issues

- `tariff_screen.dart` uses `state is _Success` and `state is _LoadingRoutes` — private Freezed-generated types are not accessible across file boundaries. Replace these with `state.whenOrNull(success: ...)` or `state.maybeWhen(...)`.
- `_ResultBottomSheet.quotation` is typed `dynamic` — should be `Quotation`.
- `TipoVehiculo` is defined in both `vehicles/domain/entities/vehicle.dart` and `tolls/domain/entities/toll.dart`. They are currently identical but will diverge (tolls follow SUTRAN classification). When implementing the data layer, map between them explicitly in the repository.
- `LocalCache` calls `SharedPreferences.getInstance()` on every read/write — inject a pre-resolved instance to avoid repeated async lookups.
- `CalculateTariffUseCase` uses `isLeft()` + a second `fold()` call instead of chaining with `flatMap`/`>>=`. When refactoring, prefer monadic chaining.

---

## Code generation

Freezed files (`*.freezed.dart`) and Riverpod generated files (`*.g.dart`) are checked into the repo. After editing any `@freezed` class or `@riverpod` provider, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Do not hand-edit `*.freezed.dart` or `*.g.dart` files.

---

## Environment variables

Stored in `.env` at the project root (included as a Flutter asset):

```
GOOGLE_MAPS_API_KEY=<mobile/desktop key>
GOOGLE_MAPS_API_KEY_WEB=<web key>
```

Access via `dotenv.env['GOOGLE_MAPS_API_KEY']`. The `.env` file is loaded in `main()` before `runApp`.

---

## External data sources

| Data | Source | Refresh |
|------|--------|---------|
| Fuel price (soles/gallon) | OSINERGMIN scraping via Dio | Daily background job |
| Exchange rate PEN→USD | SBS REST API | Daily background job |
| Estimated tolls | Google Maps Routes API | Per route request |
| Route polylines | Google Maps Routes API | Per route request |
| Address autocomplete | Google Places API (via IRouteRepository) | Per keystroke (≥3 chars) |
