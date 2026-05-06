extends Node
## GameData — 24 seviyenin statik konfigürasyonu (Autoload).
##
## Data-driven tasarım: Yeni seviye eklemek = sadece bu listeye satır eklemek.
## Hiçbir yerde "if level == 5" tarzı sert kodlama YOK.
##
## Seviye tipleri:
##   "color_circle"  — renkli daire seçenekleri  (1-3)
##   "color_text"    — renk adı yazıları         (4-7)
##   "color_mixed"   — daire + yazı karma 6 adet (8-9)
##   "animal"        — hayvan görseli            (10-15)
##   "fruit"         — meyve görseli             (16-24)

const TOTAL_LEVELS := 24
const MAX_LIVES := 5

# Renk paleti (4 yaşa hitap eden parlak/yumuşak tonlar).
const COLORS := {
	"red": {"hex": Color("#EF476F"), "tr": "KIRMIZI"},
	"blue": {"hex": Color("#118AB2"), "tr": "MAVİ"},
	"yellow": {"hex": Color("#FFD166"), "tr": "SARI"},
	"green": {"hex": Color("#06D6A0"), "tr": "YEŞİL"},
	"purple": {"hex": Color("#9B5DE5"), "tr": "MOR"},
	"orange": {"hex": Color("#F78C1F"), "tr": "TURUNCU"},
	"pink": {"hex": Color("#F7A8C4"), "tr": "PEMBE"},
	"black": {"hex": Color("#2B2D42"), "tr": "SİYAH"},
}

const ANIMALS := {
	"cat": {"tr": "KEDİ", "emoji": "🐱", "img": "res://assets/images/animals/cat.jpeg", "sfx": "res://assets/sfx/cat.ogg"},
	"dog": {"tr": "KÖPEK", "emoji": "🐶", "img": "res://assets/images/animals/dog.jpeg", "sfx": "res://assets/sfx/dog.ogg"},
	"cow": {"tr": "İNEK", "emoji": "🐄", "img": "res://assets/images/animals/cow.jpeg", "sfx": "res://assets/sfx/cow.ogg"},
	"sheep": {"tr": "KOYUN", "emoji": "🐑", "img": "res://assets/images/animals/sheep.jpeg", "sfx": "res://assets/sfx/sheep.ogg"},
	"horse": {"tr": "AT", "emoji": "🐴", "img": "res://assets/images/animals/horse.jpeg", "sfx": "res://assets/sfx/horse.ogg"},
	"rabbit": {"tr": "TAVŞAN", "emoji": "🐰", "img": "res://assets/images/animals/rabbit.jpeg", "sfx": "res://assets/sfx/rabbit.ogg"},
	"bird": {"tr": "KUŞ", "emoji": "🐦", "img": "res://assets/images/animals/bird.jpeg", "sfx": "res://assets/sfx/bird.ogg"},
	"fish": {"tr": "BALIK", "emoji": "🐟", "img": "res://assets/images/animals/fish.jpeg", "sfx": "res://assets/sfx/fish.ogg"},
}

const FRUITS := {
	"apple": {"tr": "ELMA", "emoji": "🍎", "img": "res://assets/images/fruits/apple.jpeg", "sfx": "res://assets/sfx/apple.ogg"},
	"banana": {"tr": "MUZ", "emoji": "🍌", "img": "res://assets/images/fruits/banana.jpeg", "sfx": "res://assets/sfx/banana.ogg"},
	"strawberry": {"tr": "ÇİLEK", "emoji": "🍓", "img": "res://assets/images/fruits/strawberry.jpeg", "sfx": "res://assets/sfx/strawberry.ogg"},
	"orange": {"tr": "PORTAKAL", "emoji": "🍊", "img": "res://assets/images/fruits/orange.jpeg", "sfx": "res://assets/sfx/orange.ogg"},
	"grape": {"tr": "ÜZÜM", "emoji": "🍇", "img": "res://assets/images/fruits/grape.jpeg", "sfx": "res://assets/sfx/grape.ogg"},
	"watermelon": {"tr": "KARPUZ", "emoji": "🍉", "img": "res://assets/images/fruits/watermelon.jpeg", "sfx": "res://assets/sfx/watermelon.ogg"},
	"pear": {"tr": "ARMUT", "emoji": "🍐", "img": "res://assets/images/fruits/pear.jpeg", "sfx": "res://assets/sfx/pear.ogg"},
	"cherry": {"tr": "KİRAZ", "emoji": "🍒", "img": "res://assets/images/fruits/cherry.jpeg", "sfx": "res://assets/sfx/cherry.ogg"},
}

# 24 seviyenin tanımı. (level_id, type, target_key, distractor_keys, num_choices)
# distractor_keys boş bırakılırsa LevelManager rastgele seçer.
const LEVELS: Array[Dictionary] = [
	# 1-3: Renkler — Şekil
	{"id": 1, "type": "color_circle", "target": "red", "choices": 4},
	{"id": 2, "type": "color_circle", "target": "blue", "choices": 4},
	{"id": 3, "type": "color_circle", "target": "yellow", "choices": 4},
	# 4-7: Renkler — Metin
	{"id": 4, "type": "color_text", "target": "green", "choices": 4},
	{"id": 5, "type": "color_text", "target": "red", "choices": 4},
	{"id": 6, "type": "color_text", "target": "purple", "choices": 4},
	{"id": 7, "type": "color_text", "target": "orange", "choices": 4},
	# 8-9: Renkler — Karma (6 seçenek)
	{"id": 8, "type": "color_mixed", "target": "blue", "choices": 6},
	{"id": 9, "type": "color_mixed", "target": "pink", "choices": 6},
	# 10-15: Hayvanlar
	{"id": 10, "type": "animal", "target": "cat", "choices": 4},
	{"id": 11, "type": "animal", "target": "dog", "choices": 4},
	{"id": 12, "type": "animal", "target": "cow", "choices": 4},
	{"id": 13, "type": "animal", "target": "sheep", "choices": 4},
	{"id": 14, "type": "animal", "target": "horse", "choices": 4},
	{"id": 15, "type": "animal", "target": "rabbit", "choices": 4},
	# 16-24: Meyveler
	{"id": 16, "type": "fruit", "target": "apple", "choices": 4},
	{"id": 17, "type": "fruit", "target": "banana", "choices": 4},
	{"id": 18, "type": "fruit", "target": "strawberry", "choices": 4},
	{"id": 19, "type": "fruit", "target": "orange", "choices": 4},
	{"id": 20, "type": "fruit", "target": "grape", "choices": 4},
	{"id": 21, "type": "fruit", "target": "watermelon", "choices": 4},
	{"id": 22, "type": "fruit", "target": "pear", "choices": 4},
	{"id": 23, "type": "fruit", "target": "cherry", "choices": 4},
	{"id": 24, "type": "fruit", "target": "apple", "choices": 4},
]


func _ready() -> void:
	# Veri bütünlüğü kontrolleri (defansif).
	assert(LEVELS.size() == TOTAL_LEVELS,
		"GameData: LEVELS dizisi %d olmalı, %d bulundu" % [TOTAL_LEVELS, LEVELS.size()])
	for i in LEVELS.size():
		var lv: Dictionary = LEVELS[i]
		assert(lv.id == i + 1, "GameData: Seviye id %d olmalı" % (i + 1))
		assert(_is_valid_target(lv), "GameData: Geçersiz target '%s' (seviye %d)" % [lv.target, lv.id])
	Log.info("GameData", "24 seviye doğrulandı.")


func _is_valid_target(lv: Dictionary) -> bool:
	match lv.type:
		"color_circle", "color_text", "color_mixed":
			return COLORS.has(lv.target)
		"animal":
			return ANIMALS.has(lv.target)
		"fruit":
			return FRUITS.has(lv.target)
	return false


## Verilen seviye için (target, distractors) anahtar listesi döndürür.
## distractor_keys deterministik değil — her seviyede rastgele.
func build_choice_keys(level: Dictionary) -> Array[String]:
	var pool: Dictionary
	match level.type:
		"color_circle", "color_text", "color_mixed":
			pool = COLORS
		"animal":
			pool = ANIMALS
		"fruit":
			pool = FRUITS
		_:
			Log.error("GameData", "Bilinmeyen seviye tipi: %s" % level.type)
			return []

	var keys: Array[String] = []
	keys.append(level.target)
	var others: Array = pool.keys().filter(func(k): return k != level.target)
	others.shuffle()
	var needed: int = level.choices - 1
	for i in needed:
		if i >= others.size():
			break
		keys.append(others[i])
	keys.shuffle()
	return keys


## Bir seviye için Türkçe görünür ad (prompt label).
func get_display_name(level: Dictionary) -> String:
	match level.type:
		"color_circle", "color_text", "color_mixed":
			return COLORS[level.target].tr
		"animal":
			return ANIMALS[level.target].tr
		"fruit":
			return FRUITS[level.target].tr
	return "?"


## Prompt label'ın rengi (renkli seviyelerde target rengi, diğerlerinde siyah).
func get_prompt_color(level: Dictionary) -> Color:
	match level.type:
		"color_circle", "color_text", "color_mixed":
			return COLORS[level.target].hex
		_:
			return Color("#073B4C")
