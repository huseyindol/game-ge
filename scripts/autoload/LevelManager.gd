extends Node
## LevelManager — Oyun ana döngüsü ve seviye geçişleri (Autoload Singleton).
##
## SORUMLULUKLAR:
##   • Mevcut seviye no, kalan can sayısı (state)
##   • Seviyeye giriş / çıkış / tamamlama akışı
##   • UI sahnesini bilgilendirmek için sinyaller yayınlamak
##   • Ebeveyn paneli için AnalyticsManager.get_summary() çağrısını proxy etmek
##
## ÖNEMLİ:
##   Bu sınıf görsel ÜRETMEZ; yalnızca durum tutar ve sinyal yayınlar.
##   LevelScene, bu sinyalleri dinleyerek ekranı çizer. (MVC ayrımı.)

# =====================================================================
#  SİNYALLER  — UI bunları dinler
# =====================================================================
signal level_started(level: Dictionary, choice_keys: Array)
signal answer_evaluated(is_correct: bool, level: Dictionary, chosen_key: String)
signal life_lost(remaining_lives: int)
signal game_over          # 5 can bitti
signal game_won           # 24. seviye tamamlandı
signal lives_changed(remaining_lives: int)


const TAG := "LevelManager"
const LEVEL_SCENE_PATH := "res://scenes/LevelScene.tscn"
const WIN_SCENE_PATH   := "res://scenes/WinScene.tscn"
const GAME_OVER_PATH   := "res://scenes/GameOverScene.tscn"

# =====================================================================
#  STATE
# =====================================================================
var current_level_id: int = 1
var lives: int = GameData.MAX_LIVES
var _current_level: Dictionary = {}
var _current_choices: Array[String] = []
# Aynı seviyede birden çok yanlışta sadece 1 can düşsün diye:
var _life_lost_in_current_level: bool = false


func _ready() -> void:
	Logger.info(TAG, "LevelManager hazır.")


# =====================================================================
#  PUBLIC API — Sahne / butonlar tarafından çağrılır
# =====================================================================

## Yeni oyun. State sıfırlanır, ilk seviye yüklenir.
func start_new_game(reset_analytics: bool = false) -> void:
	current_level_id = 1
	lives = GameData.MAX_LIVES
	if reset_analytics:
		AnalyticsManager.reset_all()
	Logger.info(TAG, "Yeni oyun başladı. Can=%d" % lives)
	get_tree().change_scene_to_file(LEVEL_SCENE_PATH)


## LevelScene._ready() içinden çağrılır. Mevcut seviyeyi kurar ve sinyal yayınlar.
func enter_current_level() -> void:
	if current_level_id < 1 or current_level_id > GameData.TOTAL_LEVELS:
		Logger.error(TAG, "Geçersiz seviye id=%d" % current_level_id)
		return
	_current_level = GameData.LEVELS[current_level_id - 1].duplicate(true)
	_current_choices = GameData.build_choice_keys(_current_level)
	_life_lost_in_current_level = false

	Logger.info(TAG, "Seviye %d hazırlanıyor (type=%s, target=%s, choices=%d)" % [
		_current_level.id, _current_level.type,
		_current_level.target, _current_choices.size(),
	])

	# Analytics kronometresi başlasın.
	AnalyticsManager.start_level_timer(_current_level.id)

	level_started.emit(_current_level, _current_choices)
	lives_changed.emit(lives)


## Seçim yapıldığında UI tarafından çağrılır.
func submit_answer(chosen_key: String) -> void:
	if _current_level.is_empty():
		Logger.warn(TAG, "submit_answer: aktif seviye yok.")
		return

	var is_correct: bool = (chosen_key == _current_level.target)
	AnalyticsManager.record_response(_current_level.id, is_correct)

	answer_evaluated.emit(is_correct, _current_level, chosen_key)

	if is_correct:
		AudioManager.play_sfx("correct")
		Logger.info(TAG, "Doğru! Seviye %d tamamlandı." % _current_level.id)
		_advance_after_delay()
	else:
		AudioManager.play_sfx("wrong")
		_handle_wrong_answer()


# =====================================================================
#  YANLIŞ CEVAP / CAN MEKANİĞİ
# =====================================================================

func _handle_wrong_answer() -> void:
	# Aynı seviyede birden fazla yanlış olsa bile sadece 1 can düşer.
	if _life_lost_in_current_level:
		Logger.debug(TAG, "Aynı seviyede ek yanlış — can düşmez.")
		return
	_life_lost_in_current_level = true
	lives -= 1
	lives_changed.emit(lives)
	life_lost.emit(lives)
	Logger.info(TAG, "Can düştü: %d kaldı." % lives)
	if lives <= 0:
		_trigger_game_over()


func _trigger_game_over() -> void:
	Logger.info(TAG, "Oyun bitti — canlar tükendi.")
	game_over.emit()
	# Sahne değişimi için 1 saniye bekle (UI animasyonu görünsün).
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file(GAME_OVER_PATH)


# =====================================================================
#  SONRAKİ SEVİYE / KAZANIM
# =====================================================================

func _advance_after_delay() -> void:
	# Konfeti animasyonu için bekle.
	await get_tree().create_timer(1.6).timeout

	if current_level_id >= GameData.TOTAL_LEVELS:
		Logger.info(TAG, "Tüm seviyeler tamamlandı 🎉")
		game_won.emit()
		get_tree().change_scene_to_file(WIN_SCENE_PATH)
		return

	current_level_id += 1
	# Aynı sahneyi yeniden yükleyip enter_current_level çağıracağız.
	get_tree().change_scene_to_file(LEVEL_SCENE_PATH)


# =====================================================================
#  EBEVEYN PANELİ — UI proxy
# =====================================================================

## ParentPanel.gd bu fonksiyonu çağırır → AnalyticsManager'dan veri gelir.
func get_parent_summary() -> Dictionary:
	return AnalyticsManager.get_summary()


## HUD vb. okuyucu UI'lar için — read-only kopya döner.
func get_current_level() -> Dictionary:
	return _current_level.duplicate(true)
