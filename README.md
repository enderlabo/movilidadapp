# Tarifario de Movilidad — Empresa de Andamios

App Flutter multiplataforma (mobile · web · desktop) para calcular tarifas de transporte
incluyendo combustible (ida con carga + vuelta vacía), peajes y conversión de moneda.

---

## Stack técnico

| Capa | Tecnología |
|------|-----------|
| Estado | Riverpod + StateNotifier |
| DI | GetIt |
| Dominio | Dartz (Either), Freezed, use cases |
| Navegación | go_router |
| Maps (mobile) | google_maps_flutter |
| Maps (web) | Google Maps JS API via HtmlElementView |
| Base de datos | Cloud Firestore |
| Cache offline | Hive Flutter |
| HTTP | Dio + Retrofit |
| Conectividad | connectivity_plus |

---

## Arquitectura

```
lib/
├── core/               ← compartido entre features
│   ├── error/          ← Failure types (dartz Either)
│   ├── network/        ← connectivity, dio client
│   ├── theme/          ← glassmorphism, AppTheme, GlassCard
│   └── utils/          ← currency, formatters
│
├── features/           ← feature-first, cada feature es autónoma
│   ├── vehicles/       ← CRUD de vehículos (5 camiones)
│   ├── routes/         ← integración Google Maps, geocoding
│   ├── tariff/         ← lógica de cálculo, TariffCalculatorService
│   └── history/        ← historial de cotizaciones
│
├── injection/          ← GetIt, registro de dependencias
├── router/             ← go_router, rutas nombradas
└── main.dart
```

Cada feature sigue Clean Architecture:
```
feature/
├── domain/
│   ├── entities/       ← Freezed, inmutables
│   ├── repositories/   ← interfaces (abstract interface class)
│   ├── usecases/       ← orquestación, un use case = una operación
│   └── services/       ← lógica de negocio pura (sin I/O)
├── data/
│   ├── datasources/    ← remote (Firestore, Maps) + local (Hive)
│   ├── models/         ← Freezed + json_serializable
│   └── repositories/   ← implementaciones de las interfaces
└── presentation/
    ├── viewmodels/     ← Riverpod StateNotifier
    ├── screens/        ← pantallas
    └── widgets/        ← componentes reutilizables
```

---

## Fórmula de tarifa

```
combustible_ida    = (distancia_km / rendimiento_cargado) × precio_galon
combustible_vuelta = (distancia_km / rendimiento_vacio) × precio_galon
peajes             = estimado Maps API (o ajuste manual de la jefa)
total_soles        = combustible_ida + combustible_vuelta + peajes
total_dolares      = total_soles / tipo_cambio_SBS
```

**Por defecto: todo vehículo sale del almacén con carga.**

---

## Variables de entorno (.env)

```env
GOOGLE_MAPS_API_KEY=tu_clave_aqui
GOOGLE_MAPS_API_KEY_WEB=tu_clave_web_aqui
```

---

## Fuentes de datos externas

| Dato | Fuente | Frecuencia |
|------|--------|-----------|
| Precio galón | OSINERGMIN (scraping) | Diaria |
| Tipo de cambio | SBS API | Diaria |
| Peajes estimados | Google Routes API | Por consulta |
| Rutas | Google Maps Routes API | Por consulta |

---

## Correr tests

```bash
flutter test test/unit/
```

---

## Generar código (Freezed + Riverpod)

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Principios aplicados

- **SOLID**: cada clase tiene una responsabilidad, depende de abstracciones.
- **KISS**: `TariffCalculatorService` es código Dart puro sin dependencias.
- **DRY**: fórmula de combustible en un único lugar; `GlassCard` reutilizable.
