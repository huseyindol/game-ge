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
	Logger.info(TAG, "Analytics hazır. Toplam D/Y: %d/%d" % [total_correct, total_wrong])


# =====================================================================
#  LIFECYCLE — LevelManager tarafından çağrılır
# =====================================================================

## Yeni bir seviye açıldığında çağrılır. Sessiz kronometre başlar.
func start_level_timer(level_id: int) -> void:
	if level_id <= 0:
		Logger.warn(TAG, "start_level_timer: geçersiz level_id=%d" % level_id)
		return
	_active_level_id = level_id
	_level_start_ms = Time.get_ticks_msec()
	_ensure_level_record(level_id)
	Logger.debug(TAG, "Kronometre başladı (level=%d)" % level_id)


## Çocuk bir seçim yaptığında çağrılır.
func record_response(level_id: int, is_correct: bool) -> void:
	if level_id != _active_level_id:
		Logger.warn(TAG, "record_response: aktif seviye %d, gelen %d" % [_active_level_id, level_id])
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

	Logger.info(TAG, "Cevap kaydedildi: level=%d correct=%s ms=%d streak(D/Y)=%d/%d" % [
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


# =====================================================================
#  PEDAGOJİK GERİ BİLDİRİM (4 yaş gelişim standartları)
# =====================================================================
#
# AnalyticsManager veri toplar; BU bölüm verileri yorumlar.
# Mesajlar `const` olarak tutulur (kuralları kodda değil veride tutmak için).
# Eşikler tek noktada — magic number yok.

# --- Eşikler (4 yaş normatif aralıklar) ---
const FB_MIN_ATTEMPTS: int        = 4    # Bu cevap sayısının altında yargı yok.
const FB_HIGH_ACCURACY: float     = 85.0
const FB_GOOD_ACCURACY: float     = 80.0
const FB_LOW_ACCURACY: float      = 60.0
const FB_FAST_RT_SEC: float       = 3.0
const FB_IMPULSIVE_RT_SEC: float  = 1.5
const FB_SLOW_RT_SEC: float       = 3.5
const FB_HIGH_STREAK: int         = 15

# --- Mesaj sabitleri (i18n/A-B test için tek noktada toplandı) ---
const FB_IDEAL := \
	"Harika bir işitsel-görsel koordinasyon! Çocuğunuz duyduğu bilgiyi " + \
	"(Seçimsel Tepki Süresi) çok hızlı işliyor ve yüksek odaklanma " + \
	"becerisiyle doğru sonuca ulaşıyor."

const FB_IMPULSIVE := \
	"Çocuğunuz çok hızlı reflekslere sahip ancak karar verirken biraz " + \
	"aceleci davranıyor. Doğruluk oranını artırmak için, oyunu oynarken " + \
	"ona 'Önce resimlerin hepsine bir bakalım, sence hangisi?' diyerek " + \
	"yavaşlamasına ve dürtü kontrolü sağlamasına yardımcı olabilirsiniz."

const FB_METHODICAL := \
	"Çocuğunuz oldukça dikkatli ve metodik düşünüyor! Hızlı ve rastgele " + \
	"kararlar vermek yerine, seçenekleri iyice değerlendirip emin " + \
	"olduktan sonra doğru cevaba ulaşıyor. Bu yaş için harika bir " + \
	"analitik yaklaşım."

const FB_HIGH_STREAK_MSG := \
	"Mükemmel sürdürülebilir dikkat! Arka arkaya 15+ doğru cevap, " + \
	"çocuğunuzun rastgele tahmin yapmak yerine görsel hafızasını " + \
	"bilinçli olarak kullandığını gösteriyor."

const FB_DEFAULT := \
	"Çocuğunuz öğrenme yolculuğunda harika bir başlangıç yaptı. Onunla " + \
	"birlikte oynamaya devam ederek hem dil gelişimini hem de görsel " + \
	"hafızasını destekleyebilirsiniz. Her doğru cevap, sabırla pekişen " + \
	"yeni bir bilişsel köprüdür."

const FB_NOT_ENOUGH_DATA := \
	"Henüz değerlendirme için yeterli veri yok. Çocuğunuzla birkaç seviye " + \
	"daha oynadığınızda burada kişiselleştirilmiş bir gelişim özeti " + \
	"görebileceksiniz."


## Toplanan analitik verilere dayanarak 4 yaş çocuğu için bilimsel temelli,
## yapıcı bir geri bildirim metni döndürür.
##
## Önceliklendirme:
##   1. Veri yetersizse → uyarı metni
##   2. Streak ≥ 15 → "Sürdürülebilir Dikkat" insight'ı eklenir (öncelikli)
##   3. Bilişsel profil — IDEAL / IMPULSIVE / METHODICAL (sadece biri)
##   4. Hiçbir keskin profil yoksa → motive edici varsayılan
##
## Çoklu insight'lar `\n\n` ile birleştirilir. Saf fonksiyon — yan etki yok.
func get_pedagogical_feedback() -> String:
	var total: int = total_correct + total_wrong

	if total < FB_MIN_ATTEMPTS:
		Logger.debug(TAG, "Feedback: yetersiz veri (%d cevap)" % total)
		return FB_NOT_ENOUGH_DATA

	var accuracy: float = get_accuracy_percent()
	var avg_rt_sec: float = get_average_response_ms() / 1000.0

	Logger.debug(TAG, "Feedback giriş: acc=%.1f%% rt=%.2fs streak=%d total=%d" % [
		accuracy, avg_rt_sec, longest_correct_streak, total,
	])

	var insights: Array[String] = []

	# ---- Durum 4: Sürdürülebilir dikkat (öncelikli) ----
	if longest_correct_streak >= FB_HIGH_STREAK:
		insights.append(FB_HIGH_STREAK_MSG)

	# ---- Durum 1/2/3: Bilişsel profil — mutually exclusive ----
	var profile := _classify_cognitive_profile(accuracy, avg_rt_sec)
	if not profile.is_empty():
		insights.append(profile)

	# ---- Fallback: hiçbir keskin koşul tutmadıysa ----
	if insights.is_empty():
		insights.append(FB_DEFAULT)

	return "\n\n".join(insights)


## Bilişsel profil sınıflandırıcı — saf fonksiyon, test edilebilir.
## Eşleşme yoksa boş string döner ve fallback devreye girer.
func _classify_cognitive_profile(accuracy: float, avg_rt_sec: float) -> String:
	# Durum 1: İdeal — yüksek doğruluk + hızlı tepki
	if accuracy >= FB_HIGH_ACCURACY and avg_rt_sec <= FB_FAST_RT_SEC:
		return FB_IDEAL
	# Durum 2: Aceleci — düşük doğruluk + çok hızlı tepki
	if accuracy <= FB_LOW_ACCURACY and avg_rt_sec <= FB_IMPULSIVE_RT_SEC:
		return FB_IMPULSIVE
	# Durum 3: Metodik — yüksek doğruluk + yavaş tepki
	if accuracy >= FB_GOOD_ACCURACY and avg_rt_sec > FB_SLOW_RT_SEC:
		return FB_METHODICAL
	return ""


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
	Logger.info(TAG, "Tüm istatistikler sıfırlandı.")
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
		Logger.error(TAG, "Kaydetme başarısız (%s) hata=%d" % [SAVE_PATH, FileAccess.get_open_error()])
		return
	f.store_string(JSON.stringify(payload, "  "))
	f.close()


func _load_from_disk() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		Logger.info(TAG, "Kayıt yok, sıfırdan başlıyor.")
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		Logger.error(TAG, "Yükleme başarısız (%s)" % SAVE_PATH)
		return
	var raw := f.get_as_text()
	f.close()

	var parsed = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		Logger.warn(TAG, "Kayıt dosyası bozuk, sıfırlanıyor.")
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
