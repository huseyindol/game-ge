extends Node
## AudioManager — Tüm ses çıktılarının tek noktası (Autoload Singleton).
##
## SFX dosyaları yoksa sessiz fallback (uyarı log'lanır, oyun durmaz).

const TAG := "AudioManager"

const SFX := {
	"correct": "res://assets/sfx/correct.ogg",
	"wrong":   "res://assets/sfx/boing.ogg",
	"win":     "res://assets/sfx/win.ogg",
	"click":   "res://assets/sfx/click.ogg",
}

var _player: AudioStreamPlayer
var _word_player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	add_child(_player)

	_word_player = AudioStreamPlayer.new()
	_word_player.bus = "Master"
	add_child(_word_player)

	Logger.info(TAG, "AudioManager hazır.")


## Sabit SFX adı ile çal.
func play_sfx(name: String) -> void:
	var path: String = SFX.get(name, "")
	if path.is_empty():
		Logger.warn(TAG, "Bilinmeyen SFX: %s" % name)
		return
	_play_path(_player, path)


## Hayvan/meyve sesi gibi runtime path için.
func play_word(path: String) -> void:
	if path.is_empty():
		return
	_play_path(_word_player, path)


func _play_path(player: AudioStreamPlayer, path: String) -> void:
	if not ResourceLoader.exists(path):
		Logger.warn(TAG, "Ses dosyası bulunamadı: %s" % path)
		return
	var stream: AudioStream = load(path)
	if stream == null:
		Logger.warn(TAG, "Ses yüklenemedi: %s" % path)
		return
	player.stream = stream
	player.play()
