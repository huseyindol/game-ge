extends Node
## AudioManager — Tüm ses çıktılarının tek noktası (Autoload Singleton).
##
## Ses dosyası yoksa TTS (sistem sesi sentezi) ile fallback yapar.

const TAG := "AudioManager"

const SFX := {
	"correct": "res://assets/sfx/correct.ogg",
	"wrong":   "res://assets/sfx/boing.ogg",
	"win":     "res://assets/sfx/win.ogg",
	"click":   "res://assets/sfx/click.ogg",
}

var _player: AudioStreamPlayer
var _word_player: AudioStreamPlayer
var _tts_voice_id: String = ""


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	add_child(_player)

	_word_player = AudioStreamPlayer.new()
	_word_player.bus = "Master"
	add_child(_word_player)

	_init_tts()
	Log.info(TAG, "AudioManager hazır.")


func _init_tts() -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		Log.warn(TAG, "Bu platformda TTS desteklenmiyor.")
		return
	var voices := DisplayServer.tts_get_voices()
	for v in voices:
		if v.language.begins_with("tr"):
			_tts_voice_id = v.id
			Log.debug(TAG, "Türkçe TTS sesi: %s" % v.id)
			return
	if voices.size() > 0:
		_tts_voice_id = voices[0].id
		Log.warn(TAG, "Türkçe ses bulunamadı, varsayılan: %s" % _tts_voice_id)


## Sabit SFX adı ile çal.
func play_sfx(name: String) -> void:
	var path: String = SFX.get(name, "")
	if path.is_empty():
		Log.warn(TAG, "Bilinmeyen SFX: %s" % name)
		return
	_play_path(_player, path)


## Yanlış SFX sonrası kısa gecikmeyle kelimeyi okur (üst üste binmez).
func play_wrong_then_speak(label_tr: String) -> void:
	play_sfx("wrong")
	if label_tr.is_empty():
		return
	var tree: SceneTree = get_tree()
	if tree == null:
		speak_word(label_tr)
		return
	var t := tree.create_timer(0.55)
	t.timeout.connect(func () -> void:
		speak_word(label_tr)
	, CONNECT_ONE_SHOT)


## Ses dosyası varsa çal, yoksa TTS ile seslendir.
func play_or_speak(sfx_path: String, fallback_text: String) -> void:
	if not sfx_path.is_empty() and ResourceLoader.exists(sfx_path):
		_play_path(_word_player, sfx_path)
	else:
		_speak_tts(fallback_text)


## Kelimeyi sistem TTS ile seslendir.
func speak_word(text: String) -> void:
	_speak_tts(text)


func _speak_tts(text: String) -> void:
	if OS.has_feature("web"):
		_speak_tts_web(text)
		return
	if _tts_voice_id.is_empty():
		Log.warn(TAG, "TTS sesi yok, atlanıyor: %s" % text)
		return
	if DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()
	DisplayServer.tts_speak(text, _tts_voice_id, 90, 0.9, 1.0)
	Log.debug(TAG, "TTS: %s" % text)


## HTML5: DisplayServer TTS yok; tarayıcı SpeechSynthesis kullan.
func _speak_tts_web(text: String) -> void:
	var payload: String = JSON.stringify(text)
	var js: String = "(function(){var t=%s;if('speechSynthesis'in window){speechSynthesis.cancel();var u=new SpeechSynthesisUtterance(t);u.lang='tr-TR';speechSynthesis.speak(u);}})();" % payload
	JavaScriptBridge.eval(js)
	Log.debug(TAG, "Web TTS: %s" % text)


func _play_path(player: AudioStreamPlayer, path: String) -> void:
	if not ResourceLoader.exists(path):
		Log.warn(TAG, "Ses dosyası bulunamadı: %s" % path)
		return
	var stream: AudioStream = load(path)
	if stream == null:
		Log.warn(TAG, "Ses yüklenemedi: %s" % path)
		return
	player.stream = stream
	player.play()
