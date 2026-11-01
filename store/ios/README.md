# Kâmus iOS mağaza paketi

27 Ekim 2026 — sürüm 1.0.0, bundle ID `cloud.bakedapps.kamus`.

## Hazır materyaller

- `../../metadata/app-info/tr.json`: uygulama adı, alt başlık ve gizlilik bağlantısı.
- `../../metadata/version/1.0.0/tr.json`: açıklama, anahtar kelimeler, tanıtım metni ve destek bağlantısı.
- `../../screenshots/upload/tr/iphone/`: sıralı 4 PNG, 1242 × 2688, IPHONE_65.
- `../../screenshots/upload/tr/ipad/`: sıralı 4 PNG, 2064 × 2752, IPAD_PRO_3GEN_129.
- `../../screenshots/review/index.html`: ham ve çerçeveli görsellerin karşılaştırması.
- `app-setup.json`: yeni uygulama kaydı ve inceleme notları için bilgiler.
- `web/kamus/`: canlı destek/gizlilik sayfalarının kaynak kopyası. Asıl site kaynağı: `/Users/akif/Developer/Projects/ptech/bakedappsstore/kamus/`.

Türkçe ve İngilizce sayfalar yayında:
- https://bakedapps.cloud/kamus/support/tr/
- https://bakedapps.cloud/kamus/privacy/tr/
- https://bakedapps.cloud/kamus/support/
- https://bakedapps.cloud/kamus/privacy/

## Doğrulama

Simülatör derlemesi başarılı. Paketlenen 97.821 sözcüklük SQLite sözlüğünde `PRAGMA quick_check` sonucu `ok`. Gerçek iPhone ve iPad simülatör ekranları AXe ile yakalandı ve Koubou 0.20.0 ile çerçevelendi. Her iki görsel setinde asc doğrulaması: 4/4 hazır, hata/uyarı yok. Metadata karakter sınırları ve canlı URL kontrolü başarılı.

İlk sürümde kullanılmayan Yenilikler alanı `whats-new-tr.txt` dosyasına ayrı bir taslak olarak kaydedildi.

## Tekrar üretme

1. `python3 scripts/generate_xcodeproj.py` — sıkıştırılmış kaynak sözlüğü açar ve Xcode projesini üretir.
2. Xcode ile Kamus şemasını simülatöre derleyip yükleyin.
3. `python3 scripts/capture_appstore.py --udid UDID --family iphone` (iPad için `--family ipad`). Betik yalnızca simülatör örnek arama/favori verileri üretir. iPad koordinatları 13 inç dikey simülatör içindir.
4. Python 3.12+ sanal ortamında `pip install koubou==0.20.0`; `kou setup-frames`.
5. `asc screenshots frame --config .asc/frame-iphone.yaml` ve `.asc/frame-ipad.yaml`. Koubou cihaz klasörlerindeki PNG dosyalarını `screenshots/upload/tr/` altında ilgili aile klasörüne kopyalayın. YAML içindeki mutlak kaynak yollarını farklı makinede güncelleyin.
6. `asc metadata validate --dir metadata --check-urls` ve `asc screenshots validate` ile iki seti kontrol edin.

Yerel screenshot otomasyonu asc tarafından deneysel olarak sunulur. Asıl yakalama betiği AXe'yi doğrudan kullanır; `.asc/screenshots.json` yalnızca temel ana ekran yakalama planıdır.

## App Store Connect’te kalanlar

- Mehmet Akif Petek hesabında uygulama oluşturuldu: **6827496588**. Sürüm **1.0.0**, yayın türü **MANUAL**; incelemeye gönderilmedi.
- Türkçe metadata dry-run sonrasında uygulandı. Başvuru ve Eğitim kategorileri kaydedildi.
- Bundle ID `2WTR75JQ4D`, takım `4XL3AE57HT`. Oturum çerezleri veya giriş bilgileri dışarı alınmadı.
- **8/8 ekran görüntüsü Apple tarafında COMPLETE**: iPhone ve iPad setleri yüklendi, sıralama doğrulandı. Sonuçlar `iphone-upload.json`, `ipad-upload.json` ve `screenshots-remote.json` dosyalarında.
- Yaş derecelendirmesi: argo, yetişkin konuları, alkol/madde ve silah referansları seyrek/hafif; sosyal medya, reklam, sohbet, kumar ve sınırsız web erişimi yok olarak kaydedildi. Apple sınıflandırması uygulanır.
- Fiyat ücretsiz; tüm ülkeler ve yeni ülkeler için kullanılabilirlik ayarlandı. İnceleme iletişim bilgileri kullanıcının onayıyla Vefa’dan kopyalandı, inceleme notları kaydedildi ve giriş gereksinimi kapatıldı.
- İçerik hakları: kullanıcı “üçüncü taraf içerik kullanıyor” işaretinin kaldırılmasını istedi. API’ye `contentRightsDeclaration: null` gönderildi; Apple bunu `DOES_NOT_USE_THIRD_PARTY_CONTENT` olarak döndürdü. Mevcut uygulama paketinde TDK sözlük verisi bulunduğu için bu beyan ile paket içeriği arasında yayın öncesi çözülmesi gereken bir tutarsızlık var.
- App Privacy etiketleri henüz yayımlanmadı; TDK çevrimiçi sorgularının sağlayıcı tarafındaki saklama davranışı doğrulanmadan “veri toplanmıyor” sonucu varsayılmadı. Gizlilik sayfasında çevrimiçi TDK sorguları anlatılır; yalnızca yerel saklanan veriler geliştiriciye toplanan veri sayılmaz. Beyanlar App Store formu üzerinden ayrıca tamamlanır.
- Dağıtım imzalı Release arşivi/IPA, fiziksel cihaz testi ve build yüklemesi henüz yapılmadı. İncelemeye gönderilmedi.

## Web yayını

Mevcut `bakedapps` Docker Swarm servisi, `img-captain-bakedapps:2` tabanına yalnızca `/kamus` ekleyen `img-captain-bakedapps:kamus-20261027` imajına güncellendi. Vefa ve katalog tabandaki hâliyle korundu. Dağıtım bağlamı sunucuda `/root/deployments/kamus-web-20261027` altında. Geri dönüş: `docker service update --image img-captain-bakedapps:2 --no-resolve-image bakedapps`. Kaynak kopyası yukarıda belirtilen yerel site projesine de eklendi; commit/push yapılmadı.


### Güncel iPad görselleri — 28 Ekim 2026

Yeni â logosuyla iPad Pro 13 inç (M5) simülatöründen dört gerçek ekran yakalandı. App Store screenshot studio iPad destesine uygulandı: paylaşım uzantısı, Kâmus’ta Ara eylemi, sözlük araması ve favoriler. iPhone destesi korundu; Duo beklemede.

- Önizleme: `../../screenshots/v4-ipad/preview.jpg`
- Paket: `../../screenshots/v4-ipad/kamus-ipad-guncel-logo.zip`
- Çıktılar: `../../screenshots/v4-ipad/export/ios/ipad/`
- 2064×2752 ve 2048×2732 için dört dosyanın tamamı doğrulandı; hata veya uyarı yok.
- Yeni iPad seti kullanıcı incelemesi için hazır; App Store Connect’e yüklenmedi.


### App Store Connect yüklemesi — 28 Ekim 2026

Kullanıcı onayıyla güncel iPhone v3 ve iPad v4 görselleri yüklendi. Dört iPhone boyut setinde ve iPad 13 inç setinde dörder dosya COMPLETE olarak doğrulandı. Duo beklemede. Mağaza ana dili, uygulama bilgileri ve sürüm yerelleştirmeleri yalnızca `tr`; arşivin CFBundleDevelopmentRegion değeri `tr`.

Yeni â simgesini içeren 1.0.0 (1) derlemesi arşivlendi, App Store dağıtımı için dışa aktarıldı ve yüklendi. Apple işleme durumu VALID. Derleme `fa3a7150-2e8b-4720-8f6e-d4ec3d9697a6` sürüm kaydına bağlandı. App Store Connect Included Assets / App Icon önizlemesinde yeni logo doğrulandı.

Makbuzlar ve ekran kanıtları `store/ios/upload-20261028/` altında. İncelemeye gönderilmedi. Arayüzde export compliance hâlâ Missing Compliance; App Privacy daha önceki gibi tamamlanmadı.


### TestFlight 1.0.1 — 1 Kasım 2026

iPhone Duo düzeni, eşitlenmiş kenar boşlukları ve gri zemin çalışmalarını içeren 1.0.1 (build 2) arşivlendi, App Store dağıtımı için dışa aktarıldı ve yüklendi.

- Derleme `bf2df8b7-c2a7-4f33-931e-93d230e30d1d`, işleme durumu VALID, `minOsVersion 17.0`, IPA 13.692.607 bayt.
- `ITSAppUsesNonExemptEncryption = false` üç Info.plist'e eklendi; derlemede `usesNonExemptEncryption: false`. Export compliance kaynaklı "Missing Compliance" artık oluşmuyor.
- TestFlight: `internalBuildState READY_FOR_BETA_TESTING`, `autoNotifyEnabled true`. Yalnızca dâhili testediciler; dış beta inceleme başvurusu yapılmadı (`no beta app review submission found`). Uygulamanın hiçbir TestFlight grubu yok (API `betaGroups` toplamı 0), yani harici dağıtım hiç kurulmadı.
- What to Test notu `tr` yerelleştirmesi olarak derlemeye yazıldı (`betaBuildLocalizations` 87f38eaa-b790-4c94-80d9-35b6992ea6d4).
- 1.0.0 hâlâ WAITING_FOR_REVIEW (başvuru `a15a75e9-83d2-4b4b-a72f-150a50edc5c6`, 31 Ekim 2026 17:39Z). Apple aynı platformda ikinci bir yayınlanmamış sürüm kaydına izin vermediği için **1.0.1 App Store sürüm kaydı oluşturulamadı**; `asc versions create` bu durumda reddediliyor.
- Türkçe 1.0.1 sürüm notları `metadata/version/1.0.1/tr.json` içinde hazır ve `asc metadata validate --dir metadata --check-urls` doğrulamasından geçti (3 dosya, 0 hata/uyarı). 1.0.0 incelemesi sonuçlandığında sırayla çalıştırılır:
  1. `asc versions create --app 6827496588 --version 1.0.1 --platform IOS --copy-metadata-from 1.0.0 --if-exists skip`
  2. `asc metadata apply --app 6827496588 --version 1.0.1 --dir ./metadata` (önce `--dry-run`)
  3. build `bf2df8b7-c2a7-4f33-931e-93d230e30d1d` sürüm kaydına bağlanır; incelemeye gönderilmez.
