extends Node
## Log — Merkezi loglama servisi (Autoload Singleton, adı: "Log").
##
## Karpathy prensipleri:
##   - Tek sorumluluk: yalnızca log basar.
##   - Seviye bazlı filtreleme (DEBUG/INFO/WARN/ERROR).
##   - Konsol + opsiyonel dosya çıktısı (user://game.log).
##
## Not: class_name kullanılmaz — Godot 4.6 native "Log" sınıfıyla çakışır.
##      Autoload adı "Log" olarak kayıtlıdır (project.godot).
##
## Kullanım:
##   Log.info("LevelManager", "Seviye %d başladı" % id)

enum LogLevel { DEBUG, INFO, WARN, ERROR }

const LOG_FILE_PATH := "user://game.log"
const LEVEL_NAMES := ["DEBUG", "INFO", "WARN", "ERROR"]

@export var min_level: LogLevel = LogLevel.DEBUG
@export var write_to_file: bool = true

var _file: FileAccess = null


func _ready() -> void:
	if write_to_file:
		_file = FileAccess.open(LOG_FILE_PATH, FileAccess.WRITE)
		if _file == null:
			push_warning("Log: log dosyası açılamadı (%s)" % LOG_FILE_PATH)
	info("Log", "Log başlatıldı (min_level=%s)" % LEVEL_NAMES[min_level])


func debug(tag: String, msg: String) -> void:
	_log(LogLevel.DEBUG, tag, msg)


func info(tag: String, msg: String) -> void:
	_log(LogLevel.INFO, tag, msg)


func warn(tag: String, msg: String) -> void:
	_log(LogLevel.WARN, tag, msg)


func error(tag: String, msg: String) -> void:
	_log(LogLevel.ERROR, tag, msg)


func _log(level: LogLevel, tag: String, msg: String) -> void:
	if level < min_level:
		return
	var line := "[%s] [%s] %s — %s" % [
		Time.get_datetime_string_from_system(false, true),
		LEVEL_NAMES[level],
		tag,
		msg,
	]
	# Konsol
	if level == LogLevel.ERROR:
		printerr(line)
	else:
		print(line)
	# Dosya
	if _file != null:
		_file.store_line(line)
		_file.flush()


func _exit_tree() -> void:
	if _file != null:
		_file.close()
		_file = null
