# CLAUDE.md — Eğitici Eşleştirme Oyunu (game-ge)

Bu dosya her session başında otomatik okunur. Projeyle ilgili tüm bağlam, kurallar ve geçmiş notlar buradadır.

---

## 1. Karpathy Prensipleri (Temel Davranış Kuralları)

> Kaynak: github.com/forrestchang/andrej-karpathy-skills

### Kodlamadan Önce Düşün
- Varsayımlarını açıkça belirt. Emin değilsen sor.
- Birden fazla yorum varsa hepsini sun — sessizce seçme.
- Daha basit bir yaklaşım varsa söyle.
- Belirsizlik varsa dur, neyin karanlık olduğunu adlandır, sor.

### Önce Sadelik
- Yalnızca istenen problemi çözen minimum kod.
- İstenmeyen özellik, soyutlama veya "esneklik" ekleme.
- 200 satırla yapılabilecek şey 50 satırla yapılabiliyorsa yeniden yaz.

### Cerrahi Değişiklikler
- Yalnızca zorunlu olanı değiştir.
- Komşu kodu "iyileştirme", yorum veya format değiştirme.
- Kendi değişiklerinin oluşturduğu artık import/değişken/fonksiyonu temizle.
- İlgisiz ölü kodu fark edersen belirt — silme.

### Hedef Odaklı Çalışma
- Her görevi doğrulanabilir hedefe dönüştür.
- Çok adımlı görevlerde kısa plan sun:
  ```
  1. [Adım] → doğrula: [kontrol]
  2. [Adım] → doğrula: [kontrol]
  ```

---

## 2. Proje Bağlamı

**Proje:** 4 yaş grubu için Türkçe eğitici eşleştirme oyunu (Godot 4.6)  
**Dil:** GDScript · Türkçe UI & log mesajları  
**Motor:** Godot 4.6 stable, GL Compatibility renderer  
**Ana Sahne:** `res://scenes/Main.tscn`

### Autoload Sırası (project.godot'ta kayıtlı)
| Ad | Dosya | Görev |
|----|-------|-------|
| Logger | `scripts/autoload/Logger.gd` | Merkezi loglama (DEBUG/INFO/WARN/ERROR) |
| GameData | `scripts/data/GameData.gd` | 24 seviye statik config |
| AnalyticsManager | `scripts/autoload/AnalyticsManager.gd` | Sessiz metrik toplama |
| AudioManager | `scripts/autoload/AudioManager.gd` | Tüm SFX tek noktadan |
| LevelManager | `scripts/autoload/LevelManager.gd` | Oyun durumu ve sinyal yayıcı |

### Klasör Yapısı
```
scenes/          # .tscn sahne dosyaları
scripts/
  autoload/      # Singleton GD scriptler
  data/          # GameData.gd (seviye konfigürasyonu)
  ui/            # Sahne kontrolcüleri
.claude/
  commands/      # Özel slash komutları
  memory/        # Session notları (hafıza)
```

### Kritik Tasarım Kararları
- **Veri odaklı**: Yeni seviye = `GameData.LEVELS`'a yeni satır
- **MVC**: LevelManager durum tutar; UI sinyal dinler
- **Asset toleransı**: Eksik ses/görsel → uyarı log'u, oyun devam eder
- **Sessiz analytics**: Çocuk arayüzü metrik göstermez; ebeveyn panelinde görünür
- **Türkçe**: Tüm string'ler, log mesajları, SFX etiketleri Türkçe

### Yapılmaması Gerekenler
- `Logger.info()` yerine `print()` kullanma — her zaman Logger kullan
- Yeni autoload eklerken `project.godot`'ta sıralamayı bozma (Logger ilk olmalı)
- `GameData.LEVELS` dışında seviye verisi tanımlama
- Çocuk UI'ında analytics metriği gösterme

---

## 3. Token Tasarrufu Kuralları

- Kısa cevap yeterince açıklayıcıysa uzun cevap yazma
- Kod bloklarını yalnızca değişen kısımlar için göster
- Araştırmayı tekrar yapma — önce `.claude/memory/` klasörünü oku
- Onaylı plan varsa açıklama eklemeden direkt uygula

---

## 4. Hafıza Sistemi

Her önemli işlem sonrası `.claude/memory/notes.md` güncellenir.  
Session başında bu dosyayı oku — araştırmayı tekrar yapma.

```
@.claude/memory/notes.md
```

---

## 5. Slash Komutları

| Komut | Açıklama |
|-------|----------|
| `/minimize` | Token-minimal mod: kısa cevap, sadece değişen kod |
| `/memory` | Hafıza notlarını göster |
| `/status` | Proje durumu özeti |
