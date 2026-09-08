# fastingapp

Intermittent fasting app. Mimari, `FLUTTER_ARCHITECTURE.md (1).docx` dokümanına
göre kurulmuştur: **feature-first + katmanlı** (Presentation / Domain / Data /
Core).

## Teknolojiler

- **State:** BLoC (`flutter_bloc`) — event/state/bloc 3 dosya kuralı
- **Routing:** `go_router` (shell route + auth guard)
- **Network:** `dio` (interceptor zinciri + generic `NetworkManager`)
- **DI:** `get_it` (+ `injectable`)
- **Serialization:** `json_serializable` (`.g.dart`)
- **Assets/renk:** `flutter_gen` (`ColorName`, `Assets`)
- **Lint:** `very_good_analysis`

## Kod üretimi (zorunlu ilk adım)

Model, renk, asset ve lokalizasyon dosyaları build_runner ile üretilir:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Katmanlar

| Katman | Konum | Sorumluluk |
| --- | --- | --- |
| Presentation | `lib/presentation/` | View + BLoC (UI state, kullanıcı aksiyonu) |
| Domain | `lib/domain/` | Repository'ler (iş kuralları, veri koordinasyonu) |
| Data | `lib/data/` | API modelleri (DTO), JSON serileştirme |
| Core | `lib/core/` | Network, router, manager, theme, shared widget |

## Yeni feature ekleme

Doküman bölüm 22'deki checklist takip edilir: Model → Repository → Event →
State → BLoC → DI → View → Mixin → Widgets → part kaydı → Route → Test.

> Not: Bu commit yalnızca **mimari iskelettir**; ekran tasarımları (Figma)
> henüz uygulanmamıştır.
