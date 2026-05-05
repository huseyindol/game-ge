extends Node
## AnalyticsManager — Arka plan veri toplama servisi (Autoload Singleton).
##
## SORUMLULUKLAR:
##   • Tepki süresi ölçümü (her seviyede sessiz kronometre)
##   • Doğru / yanlış sayıları (toplam ve seviye bazında)
##   • Streak takibi: en uzun doğru ve en uzun yanlış serisi
##   • Kalıcı saklama: user://analytics.json
##
## KURALLAR (UX):
##   • Oyun ekranında HİÇBİR sayaç gösterilmez. Bu servis sessizdir.
##   • Yalnızca ParentPanel verileri okur (read-only API üzerinden).
##
## OLAYLAR (signal):
##   stats_updated — herhangi bir sayım değiştiğinde yayınlanır.

signal stats_updated

const SAVE_PATH := "user://analytics.json"
const TAG := "AnalyticsManager"

# ---------- Toplu sayımlar ----------
var total_correct: int = 0
var total_wrong: int = 0

# ---------- Streak ----------
var current_correct_streak: int = 0
var current_wrong_streak: int = 0
var longest_correct_streak: int = 0
var longest_wrong_streak: int = 0

# ---------- Seviye bazında detay ----------
# { level_id: { "correct": int, "wrong": int, "response_times_ms": Array[int] } }
var level_attempts: Dictionary = {}

# ---------- Tepki süresi (private) ----------
var _level_start_ms: int = 0
var _active_level_id: int = -1
var _session_start_ms: int = 0


func _ready() -> void:
	_session_start_ms = Time.get_ticks_msec()
	_load_from_disk()
	Log.info(TAG, "Analytics hazır. Toplam D/Y: %d/%d" % [total_correct, total_wrong])


# =====================================================================
#  LIFECYCLE — LevelManager tarafından çağrılır
# =====================================================================

## Yeni bir seviye açıldığında çağrılır. Sessiz kronometre başlar.
func start_level_timer(level_id: int) -> void:
	if level_id <= 0:
		Log.warn(TAG, "start_level_timer: geçersiz level_id=%d" % level_id)
		return
	_active_level_id = level_id
	_level_start_ms = Time.get_ticks_msec()
	_ensure_level_record(level_id)
	Log.debug(TAG, "Kronometre başladı (level=%d)" % level_id)


## Çocuk bir seçim yaptığında çağrılır.
func record_response(level_id: int, is_correct: bool) -> void:
	if level_id != _active_level_id:
		Log.warn(TAG, "record_response: aktif seviye %d, gelen %d" % [_active_level_id, level_id])
	var elapsed_ms: int = Time.get_ticks_msec() - _level_start_ms
	if elapsed_ms < 0:
		elapsed_ms = 0  # defansif: sistem saati değişmiş olabilir.

	_ensure_level_record(level_id)
	var rec: Dictionary = level_attempts[level_id]
	rec.response_times_ms.append(elapsed_ms)

	if is_correct:
		total_correct += 1
		rec.correct += 1
		current_correct_streak += 1
		current_wrong_streak = 0
		longest_correct_streak = maxi(longest_correct_streak, current_correct_streak)
	else:
		total_wrong += 1
		rec.wrong += 1
		current_wrong_streak += 1
		current_correct_streak = 0
		longest_wrong_streak = maxi(longest_wrong_streak, current_wrong_streak)

	Log.info(TAG, "Cevap kaydedildi: level=%d correct=%s ms=%d streak(D/Y)=%d/%d" % [
		level_id, str(is_correct), elapsed_ms,
		current_correct_streak, current_wrong_streak,
	])

	stats_updated.emit()
	_save_to_disk()


# =====================================================================
#  HESAPLANAN ÖZELLİKLER (ParentPanel tarafından okunur)
# =====================================================================

func get_accuracy_percent() -> float:
	var total := total_correct + total_wrong
	if total == 0:
		return 0.0
	return (float(total_correct) / float(total)) * 100.0


func get_wrong_percent() -> float:
	var total := total_correct + total_wrong
	if total == 0:
		return 0.0
	return (float(total_wrong) / float(total)) * 100.0


func get_average_response_ms() -> float:
	var sum_ms: int = 0
	var count: int = 0
	for lvl_id in level_attempts.keys():
		var times: Array = level_attempts[lvl_id].response_times_ms
		for t in times:
			sum_ms += int(t)
			count += 1
	if count == 0:
		return 0.0
	return float(sum_ms) / float(count)


## Ebeveyn paneli için tek seferde tüm veriyi getir.
func get_summary() -> Dictionary:
	return {
		"total_correct": total_correct,
		"total_wrong": total_wrong,
		"accuracy_percent": snappedf(get_accuracy_percent(), 0.1),
		"wrong_percent": snappedf(get_wrong_percent(), 0.1),
		"avg_response_ms": snappedf(get_average_response_ms(), 1.0),
		"avg_response_sec": snappedf(get_average_response_ms() / 1000.0, 0.01),
		"longest_correct_streak": longest_correct_streak,
		"longest_wrong_streak": longest_wrong_streak,
		"levels_played": level_attempts.size(),
		"session_duration_sec": snappedf(
			float(Time.get_ticks_msec() - _session_start_ms) / 1000.0, 1.0),
	}


## Tüm sayımları sıfırla (örn. "Tekrar Dene" akışı için opsiyonel).
func reset_all() -> void:
	total_correct = 0
	total_wrong = 0
	current_correct_streak = 0
	current_wrong_streak = 0
	longest_correct_streak = 0
	longest_wrong_streak = 0
	level_attempts.clear()
	_level_start_ms = 0
	_active_level_id = -1
	_session_start_ms = Time.get_ticks_msec()
	Log.info(TAG, "Tüm istatistikler sıfırlandı.")
	stats_updated.emit()
	_save_to_disk()


# =====================================================================
#  PERSISTANS
# =====================================================================

func _save_to_disk() -> void:
	var payload := {
		"total_correct": total_correct,
		"total_wrong": total_wrong,
		"current_correct_streak": current_correct_streak,
		"current_wrong_streak": current_wrong_streak,
		"longest_correct_streak": longest_correct_streak,
		"longest_wrong_streak": longest_wrong_streak,
		"level_attempts": level_attempts,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		Log.error(TAG, "Kaydetme başarısız (%s) hata=%d" % [SAVE_PATH, FileAccess.get_open_error()])
		return
	f.store_string(JSON.stringify(payload, "  "))
	f.close()


func _load_from_disk() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		Log.info(TAG, "Kayıt yok, sıfırdan başlıyor.")
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		Log.error(TAG, "Yükleme başarısız (%s)" % SAVE_PATH)
		return
	var raw := f.get_as_text()
	f.close()

	var parsed = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		Log.warn(TAG, "Kayıt dosyası bozuk, sıfırlanıyor.")
		return

	total_correct          = int(parsed.get("total_correct", 0))
	total_wrong            = int(parsed.get("total_wrong", 0))
	current_correct_streak = int(parsed.get("current_correct_streak", 0))
	current_wrong_streak   = int(parsed.get("current_wrong_streak", 0))
	longest_correct_streak = int(parsed.get("longest_correct_streak", 0))
	longest_wrong_streak   = int(parsed.get("longest_wrong_streak", 0))

	var attempts = parsed.get("level_attempts", {})
	if typeof(attempts) == TYPE_DICTIONARY:
		# JSON anahtarları string döner — int'e çevir.
		for k in attempts.keys():
			var lvl_id := int(k)
			level_attempts[lvl_id] = attempts[k]
			# Eski format/eksik alan koruması.
			if not level_attempts[lvl_id].has("response_times_ms"):
				level_attempts[lvl_id]["response_times_ms"] = []


# =====================================================================
#  Yardımcılar
# =====================================================================

func _ensure_level_record(level_id: int) -> void:
	if not level_attempts.has(level_id):
		level_attempts[level_id] = {
			"correct": 0,
			"wrong": 0,
			"response_times_ms": [],
		}
