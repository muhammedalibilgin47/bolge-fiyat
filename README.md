# Bölge Fiyat: iOS uygulaması

Oyunların hangi ülkenin mağazasında daha ucuz olduğunu gösteren SwiftUI uygulaması.
Liquid Glass tasarımı var ve Pro abonelik ekranı şimdilik ödemesiz 7 günlük deneme olarak çalışıyor.
Uygulamada 33 oyun, 12 bölge ve 4 platform (PlayStation, Xbox, Steam, Nintendo) var.

## Mac'e gerek kalmadan .ipa almak (GitHub ile, ücretsiz)

1. **github.com**'da ücretsiz bir hesap aç.
2. Sağ üstten **+ → New repository** seç. Bir isim ver (ör. `bolge-fiyat`) ve **Public** işaretle, böylece derleme ücretsiz olur. Ardından **Create repository** de.
3. Açılan sayfada **uploading an existing file** bağlantısına tıkla. Bu klasörün **içindeki her şeyi** (`BolgeFiyat` klasörü, `project.yml`, `README.md` ve `.github` klasörü) sürükleyip bırak. Sonra **Commit changes** de.
   - `.github` klasörü gizli olduğu için yüklenmeyebilir. Öyle olursa **Add file → Create new file** seç, dosya adına `.github/workflows/build-ipa.yml` yaz ve bu klasördeki aynı dosyanın içeriğini yapıştırıp kaydet.
4. Üstteki **Actions** sekmesine gir. Sorarsa iş akışlarını etkinleştir. Soldan **iOS .ipa oluştur** seç, sağdaki **Run workflow** düğmesine bas.
5. Derleme 5-10 dakika sürer. Bitince çalışmanın içine gir. En altta, **Artifacts** bölümünde **BolgeFiyat-ipa** var. Onu indir. İnen zip'in içinden `BolgeFiyat.ipa` çıkar.

## Sideloadly ile iPhone'a yüklemek

1. iPhone'u bilgisayara kabloyla bağla ve Sideloadly'yi aç.
2. `BolgeFiyat.ipa` dosyasını Sideloadly'ye sürükle, Apple ID'ni yaz ve **Start**'a bas.
3. iPhone'da şu iki ayarı yap:
   - **Ayarlar → Gizlilik ve Güvenlik → Geliştirici Modu**'nu aç. Bu ayar iOS 16 ve sonrasında gerekir.
   - **Ayarlar → Genel → VPN ve Cihaz Yönetimi**'nde kendi Apple ID'ne **güven**.
4. Ücretsiz Apple ID ile yüklenen uygulama 7 gün çalışır. Süre dolunca Sideloadly ile tekrar yüklemen gerekir.

## Notlar

- **Liquid Glass**, iOS 26 ve sonrasında gerçek cam efektiyle görünür. Daha eski iOS sürümlerinde aynı ekranlar buzlu cam görünümünde açılır. Uygulama iOS 17 ve sonrasında çalışır.
- **Pro abonelikte henüz ödeme yok.** "7 gün ücretsiz başlat" düğmesi Pro'yu telefonda yerel olarak açar. Gerçek ödeme almak için bir ödeme sağlayıcısı (iyzico, Stripe gibi) ve sunucu gerekir.
  - Ücretsiz sürümde açık olanlar: en ucuz bölge ve Türkiye fiyatı.
  - Pro'da açılanlar: tüm bölgeler, tüm sürümler, platform karşılaştırma ve istek listesi.
- **Fiyatlar** `BolgeFiyat/Resources/games.json` dosyasında. Bu fiyatlar Kasım 2026 mağaza verileridir ve indirimler dahil değildir. Fiyatları güncellemek için bu dosyayı değiştirip derlemeyi tekrar çalıştırman yeterli.
