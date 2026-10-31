<p align="center">
  <img src="Resources/AppIcon-preview.png" width="128" alt="Kâmus">
</p>

<h1 align="center">Kâmus</h1>

<p align="center">
  macOS menü çubuğundan anında Türkçe sözlük araması.<br>
  Aradığınız her kelimeyi yerel veritabanına kaydeder — zamanla kendi çevrimdışı sözlüğünüz oluşur.
</p>

---

## Özellikler

- **Menü çubuğundan anında erişim** — Dock'ta yer kaplamaz, `⌃⌘L` ile her yerden açılır.
- **Seçili kelimeyi otomatik arar** — herhangi bir uygulamada bir kelime seçip kısayola basın, tanımı doğrudan gelir.
- **Yerel sözlük veritabanı** — her başarılı arama SQLite'a kaydedilir. Kayıtlı kelimeler anında açılır ve **internet olmadan da** çalışır; arka planda sessizce güncellenir.
- **Değiştirilebilir kısayol** — ayarlar panelindeki kaydediciden istediğiniz kombinasyonu atayabilirsiniz.
- **Türkçeye doğru davranır** — büyük/küçük harf dönüşümü `tr_TR` kurallarıyla yapılır, "Işık" ile "ışık" aynı kayda düşer.
- **API anahtarı gerektirmez.**

## Kurulum

Gereksinimler: macOS 12+, Xcode komut satırı araçları.

```bash
git clone https://github.com/mapetek/kamus.git
cd kamus
./build.sh
cp -r Kamus.app /Applications/
open /Applications/Kamus.app
```

`build.sh`, sisteminizde bir "Apple Development" sertifikası varsa uygulamayı onunla imzalar. Bu önemli: imza sabit kaldığı için verdiğiniz sistem izinleri her yeniden derlemede sıfırlanmaz. Sertifika yoksa ad-hoc imzaya düşer ve izinleri her derlemeden sonra yeniden vermeniz gerekir.

## İzinler

Uygulama iki sistem izni ister; ikisi de **isteğe bağlıdır**, vermezseniz uygulama çalışmaya devam eder:

| İzin | Ne için | Verilmezse |
|---|---|---|
| Erişilebilirlik | Başka uygulamalardaki seçili kelimeyi okumak | Kelimeyi elle yazarsınız |
| Input Monitoring | Global kısayolu her uygulamada yakalamak | Kısayol yalnızca uygulama öndeyken çalışır |

İzinler System Settings → Privacy & Security altından verilir; ayarlar panelindeki **Ayarları Aç** düğmesi doğrudan oraya götürür.

> **İzni verdiğiniz hâlde "gerekli" görünüyorsa:** macOS izin kaydını uygulamanın kod imzasına bağlar. Uygulama farklı bir imzayla yeniden derlenip kurulduğunda eski kayıt geçersiz kalır ama listedeki anahtar açık görünmeye devam eder. Çözüm: listeden Kamus'u **"−" ile kaldırın**, uygulamayı yeniden başlatın ve izni bir kez daha verin.

## Kullanım

- `⌃⌘L` — pencereyi aç/kapat (ayarlardan değiştirilebilir).
- Bir kelime seçip kısayola basın — seçili kelime otomatik aranır.
- Menü çubuğundaki simgeye tıklayarak da açabilirsiniz.

## Yerel veritabanı

Her başarılı arama, TDK'dan gelen **ham yanıtla birlikte** şuraya kaydedilir:

```
~/Library/Application Support/Kamus/dictionary.sqlite
```

Ham yanıt saklandığı için uygulamanın bugün göstermediği alanlar da korunur. Biriktirdiklerinizi doğrudan sorgulayabilirsiniz:

```bash
sqlite3 ~/Library/Application\ Support/Kamus/dictionary.sqlite \
  "SELECT word, search_count, datetime(last_searched_at,'unixepoch','localtime') FROM words ORDER BY last_searched_at DESC LIMIT 20;"
```

## Geliştirme

### macOS
```bash
swift build                    # hızlı derleme kontrolü
./build.sh                     # .app paketi üretir ve imzalar
python3 scripts/make_icon.py   # uygulama ikonunu yeniden üretir (Pillow gerekir)
```

### iOS & iPadOS
```bash
./scripts/build_ios.sh         # Xcode projesini üretir ve simülatör için derler
open Kamus.xcodeproj           # Xcode ile açar
```

iOS projesinde:
- **Kamus (iOS App):** Canlı arama, otomatik tamamlama, panodaki kelimeyi akıllı algılama, sesli telaffuz (TTS), Günün Kelimesi, favoriler ve arama geçmişi.
- **KamusActionExtension:** Herhangi bir uygulamada (Safari, Kitaplar, Notlar, WhatsApp) seçilen kelimeye basılı tutup Paylaş -> **"Kâmus'ta Ara"** seçilerek uygulamadan ayrılmadan anlamı getiren eklenti.
- **KamusWidgets:** WidgetKit ile Kilit Ekranı ve Ana Ekran için **Günün Kelimesi** ve **Hızlı Arama** widget'ları.

### Android
```bash
# Android Studio ile android/ dizinini açabilirsiniz:
open -a "Android Studio" android
```

Android projesinde (Kotlin + Jetpack Compose + Material 3):
- **Sistem Context Menüsü (`ACTION_PROCESS_TEXT`):** Herhangi bir uygulamada (Chrome, Twitter, PDF okuyucu, WhatsApp vb.) metin seçtiğinizde çıkan sistem menüsünde (`Kopyala | Paylaş | ... | Kâmus`) doğrudan yer alır.
- **Yarı Saydam Alt Çekmece (Floating Bottom Sheet):** `Kâmus` seçildiğinde mevcut uygulamadan çıkmadan şeffaf arka plan üzerinde anında kelime tanımını, telaffuzunu ve örneklerini getirir.
- **Kamus (Android App):** Modern Material 3 tasarımıyla canlı arama, otomatik tamamlama, sesli telaffuz (Android TTS `tr-TR`), Günün Kelimesi, favoriler, arama geçmişi ve tanım içerisindeki kelimeleri tek dokunuşla keşfetme.
- **Çevrimdışı SQLite Önbellek & Hedged Requests:** 2.5 sn üzeri geciken TDK isteklerine karşı otomatik paralel hedged request desteği ve yerel SQLite veritabanı.

Kaynaklar:
- `Sources/Kamus/`: macOS uygulaması ve ortak çekirdek (`TDKAPIClient.swift`, `DictionaryStore.swift`, `TurkishSpeechSpeaker.swift`).
- `iOS/`: iOS SwiftUI ana uygulaması, Action Extension ve WidgetKit.
- `android/`: Android Jetpack Compose projesi (`app/src/main/`).

## Lisans ve kaynak

[MIT](LICENSE) lisansıyla dağıtılır. © 2026 BakedApps.

Kelime verileri Türk Dil Kurumu'nun herkese açık `sozluk.gov.tr` servisinden alınır. **Bu bir Türk Dil Kurumu ürünü değildir**; kurumla resmî bir bağı veya kurumun onayı yoktur. Tüm sözlük içeriğinin hakları Türk Dil Kurumu'na aittir.

### Logo dosyaları

Logonun ana kaynağı proje kökündeki `kamus.png` dosyasıdır. Dosya değiştiğinde
Pillow kurulu bir Python ortamıyla `python3 scripts/make_icon.py` çalıştırın.
Bu komut macOS, iOS ve Android ikonlarını, ortak `Brand.xcassets` görsellerini,
paylaşım menüsündeki “Kâmus’ta Ara” simgesini ve tanıtım ikonunu günceller.
Paylaşım simgesi ve menü çubuğu için logonun şeffaf, tek renkli maskesi üretilir.
