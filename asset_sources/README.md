# asset_sources/

Uygulamaya **gömülmeyen** kaynak görseller. `assets/images` PNG'leri buradadır;
uygulama bunları CDN'den (Bunny, `mochifast.b-cdn.net/app-images/`) cihaz başına
bir kez indirir ve `Library/Caches` (iOS) / `cacheDir` (Android) altında saklar.
Kod: `lib/core/remote_images/`, araç: `tool/remote_images.dart`.

## Yeni görsel eklemek

1. PNG'yi `asset_sources/images/` altına koy.
2. `dart run tool/remote_images.dart` → `AppImages.<ad>` sabiti üretilir.
3. Kodda kullan: `AppImages.ornekGorsel.image(...)`, `.provider()`, `.path`
   (ya da `appImage('assets/images/ornek_gorsel.png')`).
4. Yükle: `BUNNY_STORAGE_PASSWORD=… dart run tool/remote_images.dart --upload`
   - Yalnızca kodda kullanılan görseller WebP'ye çevrilip yüklenir.
   - Dosyalar içerik hash'iyle adlandırılır: CDN'de olanlar tekrar yüklenmez,
     değişen görsel yeni dosya olur (önbellek temizlemeye gerek yok).
   - Manifest (`assets/remote_images/manifest.json`) uygulamayla birlikte gider;
     yeni sürümde değişen görseller cihazda yeniden indirilir, eskiler silinir.

## İnternetsiz gereken görseller

Açılış ekranı gibi indirme bitmeden gereken görseller `tool/remote_images.json`
→ `bundled` listesine eklenir; WebP'ye çevrilip `assets/images/bundled/` altında
uygulamaya gömülür (kullanım yine `AppImages.<ad>`).
