# Eğitici Eşleştirme Oyunu (Godot 4.x)

Okul öncesi (4 yaş) çocuklara yönelik, **24 seviyelik** 2D eşleştirme oyunu.
Renkleri, hayvanları ve meyveleri öğretir; arka planda öğrenme metriklerini
toplar ve final ekranındaki **Ebeveyn Paneli**'nde sunar.

## Klasör yapısı

```
scenes/
  Main.tscn              # Açılış
  LevelScene.tscn        # 24 seviyenin tek sahnesi
  Choice.tscn            # Seçim butonu (instance edilebilir)
  WinScene.tscn          # Final + konfeti + Ebeveyn ikonu
  GameOverScene.tscn     # 5 can bitince
  ParentPanel.tscn       # İstatistik paneli
scripts/
  autoload/              # Singleton'lar
    Logger.gd
    AnalyticsManager.gd
    AudioManager.gd
    LevelManager.gd
  data/
    GameData.gd          # 24 seviye konfigürasyonu (data-driven)
  ui/                    # Sahne scriptleri
  fx/                    # (gelecek efektler)
assets/
  images/animals/        # PNG'ler buraya konulmalı
  images/fruits/         # PNG'ler buraya konulmalı
  sfx/                   # OGG ses dosyaları
  fonts/                 # Bubble fontları
```

## Autoload Singleton'ları

| Singleton | Sorumluluk |
|-----------|-----------|
| `Logger` | Merkezi log (konsol + `user://game.log`) |
| `GameData` | 24 seviyenin statik konfigürasyonu, renk/hayvan/meyve katalogu |
| `AnalyticsManager` | Tepki süresi, doğru/yanlış, streak hesabı, `user://analytics.json` |
| `AudioManager` | Tüm SFX ve hayvan/meyve seslerinin tek noktası |
| `LevelManager` | Seviye geçişi, can mekaniği, sinyaller |

## Veri akışı

```
LevelScene._ready()
   → LevelManager.enter_current_level()
        → AnalyticsManager.start_level_timer(id)
        → emit level_started
   → Choice.pressed → LevelScene._on_choice_chose
        → LevelManager.submit_answer(key)
             → AnalyticsManager.record_response(id, is_correct)
             → emit answer_evaluated
             → doğru ise next_level / yanlışsa lose_life
```

## Ebeveyn Paneli

Final ekranı (24. seviye sonrası) sağ alttaki 👪 ikonuna basılınca açılır.
Veriler `LevelManager.get_parent_summary()` üzerinden çekilir; UI hiçbir
zaman doğrudan `AnalyticsManager` ile konuşmaz.

Gösterilen metrikler:
- Doğruluk oranı (%) ve yanlış oranı (%)
- Toplam doğru / yanlış sayısı
- Ortalama tepki süresi (sn)
- En uzun doğru / yanlış serisi
- Oynanan seviye / 24
- Oturum süresi

## Asset eksikliği toleransı

Hayvan/meyve görseli veya ses dosyası bulunmazsa oyun çökmez:
`Logger.warn` ile uyarı yazılır, görsel yerine yalnızca yazı, ses yerine
varsayılan tıklama çalar. Bu sayede oyun, asset'ler eklenmeden de derlenip
çalışabilir.

## Kayıt dosyaları

- `user://analytics.json` — istatistikler (oturumlar arası taşınır)
- `user://game.log` — log

`AnalyticsManager.reset_all()` ile sıfırlanabilir.
