# Proje Hafıza Notları

Her önemli işlem sonrası bu dosya güncellenir.
Yeni session başlamadan önce mutlaka oku — aynı araştırmayı tekrar yapma.

---

## [2026-05-05] — Proje Kurulum & İlk Fix

### Yapılanlar
1. **Logger parser hatası düzeltildi**
   - Hata: `Error at (94,5): Static function "info()" not found in base "GDScriptNativeClass"`
   - Kök neden: `Logger.gd`'de `class_name Logger` eksikti; Godot statik analizörü singleton'ı sınıf referansı olarak görüyordu
   - Fix: `Logger.gd` satır 1'e `class_name Logger` eklendi
   - Dosya: `scripts/autoload/Logger.gd`

2. **Karpathy prensipleri entegre edildi**
   - Kaynak: `github.com/forrestchang/andrej-karpathy-skills`
   - `CLAUDE.md` oluşturuldu (proje kökünde)
   - 4 prensip: Düşün, Sadelik, Cerrahi Değişiklik, Hedef Odaklı

3. **Token minimizasyon sistemi kuruldu**
   - `.claude/commands/minimize.md` → `/minimize` slash komutu
   - `.claude/commands/memory.md` → `/memory` slash komutu
   - `.claude/commands/status.md` → `/status` slash komutu

4. **Hafıza sistemi kuruldu**
   - `.claude/memory/notes.md` ← bu dosya
   - CLAUDE.md'de `@.claude/memory/notes.md` ile import edildi

---

## [2026-05-05] — Logger → Log Yeniden Adlandırma

### Yapılanlar
- `class_name Logger` eklenmesi yeni hata yarattı: `Class "Logger" hides a native class`
- Godot 4.6'nın **kendi native `Logger` sınıfı** var — aynı adda class_name yasak
- Çözüm: autoload adı `Log` olarak değiştirildi
  - `project.godot`: `Logger=` → `Log=`
  - `Logger.gd`: `class_name Logger` kaldırıldı, iç referanslar `Log` → güncellendi
  - 6 script dosyasında `Logger.` → `Log.` tümü güncellendi
- **Kural**: Godot native sınıf adlarıyla (Logger, Node, Object, vb.) aynı class_name kullanma

### Bilinen Durumlar
- Ses dosyaları henüz eklenmedi → AudioManager uyarı log'u verir ama çökmez
- Görsel asset'lar (hayvan/meyve resimleri) eksik → placeholder kullanılır
- Analytics verileri `user://analytics.json`'da tutulur (Godot user data)

### Keşfedilen Mimari
- 5 autoload singleton (Logger → GameData → Analytics → Audio → Level)
- 24 seviye: 3 renk-daire, 4 renk-yazı, 2 renk-karışık, 6 hayvan, 9 meyve
- LevelManager sinyal odaklı → UI bağımsız
- Çocuk UI'ı saf; ebeveyn istatistikleri WinScene'den açılan panelde

---

## Şablon: Yeni Not Ekleme

```
## [YYYY-MM-DD] — [Konu Başlığı]

### Yapılanlar
- ...

### Öğrenilenler / Dikkat Edilecekler
- ...
```
