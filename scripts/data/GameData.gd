extends Node
## GameData — 23 seviyenin statik konfigürasyonu (Autoload).
##
## Data-driven tasarım: Yeni seviye eklemek = sadece bu listeye satır eklemek.
## Hiçbir yerde "if level == 5" tarzı sert kodlama YOK.
##
## Seviye tipleri:
##   "color_circle"  — renkli daire seçenekleri  (1-3)
##   "color_text"    — renk adı yazıları         (4-7)
##   "color_mixed"   — daire + yazı karma 6 adet (8-9)
##   "animal"        — hayvan görseli            (10-15)
##   "fruit"         — meyve görseli             (16-23, 8 adet)

const TOTAL_LEVELS := 23
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

# 23 seviyenin tanımı. target alanı yalnız doğrulama; oyunda oturum başına atanır.
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
	# 16-23: Meyveler (8 adet — havuzdaki her meyve bir kez)
	{"id": 16, "type": "fruit", "target": "apple", "choices": 4},
	{"id": 17, "type": "fruit", "target": "banana", "choices": 4},
	{"id": 18, "type": "fruit", "target": "strawberry", "choices": 4},
	{"id": 19, "type": "fruit", "target": "orange", "choices": 4},
	{"id": 20, "type": "fruit", "target": "grape", "choices": 4},
	{"id": 21, "type": "fruit", "target": "watermelon", "choices": 4},
	{"id": 22, "type": "fruit", "target": "pear", "choices": 4},
	{"id": 23, "type": "fruit", "target": "cherry", "choices": 4},
]


## Oturum sırası: renk (9) + hayvan (6) + meyve (8); blok içi sıra rastgele.
## Aynı oturumda aynı soru (type + target tekrar etmez); alt tipler ayrı (ör. color_circle:MAVİ ≠ color_text:MAVİ).
## `id` 1..TOTAL_LEVELS oturum sırasına göre atanır.
func build_shuffled_run_levels() -> Array[Dictionary]:
	var color_levels: Array[Dictionary] = []
	var animal_levels: Array[Dictionary] = []
	var fruit_levels: Array[Dictionary] = []
	for lv in LEVELS:
		var d: Dictionary = lv.duplicate(true)
		match String(d.type):
			"color_circle", "color_text", "color_mixed":
				color_levels.append(d)
			"animal":
				animal_levels.append(d)
			"fruit":
				fruit_levels.append(d)
			_:
				Log.error("GameData", "Bilinmeyen seviye tipi (karıştırma): %s" % d.type)
	color_levels.shuffle()
	animal_levels.shuffle()
	fruit_levels.shuffle()
	var out: Array[Dictionary] = []
	out.append_array(color_levels)
	out.append_array(animal_levels)
	out.append_array(fruit_levels)
	var n_col := color_levels.size()
	var n_ani := animal_levels.size()
	_assign_color_segment_no_adjacent_same_target(out.slice(0, n_col))
	_assign_unique_targets_in_segment(out.slice(n_col, n_col + n_ani))
	_assign_unique_targets_in_segment(out.slice(n_col + n_ani, out.size()))
	for i in out.size():
		out[i].id = i + 1
	return out


## Renk bloklarında üst üste aynı renk (hedef) gelmesin; tip başına tekrarsız.
func _assign_color_segment_no_adjacent_same_target(levels: Array) -> void:
	if levels.is_empty():
		return
	var used_circle: Dictionary = {}
	var used_text: Dictionary = {}
	var used_mixed: Dictionary = {}
	var last := ""
	for item in levels:
		if not item is Dictionary:
			continue
		var d: Dictionary = item
		var t := String(d.type)
		var used: Dictionary
		match t:
			"color_circle":
				used = used_circle
			"color_text":
				used = used_text
			"color_mixed":
				used = used_mixed
			_:
				Log.error("GameData", "Renk segmentinde beklenmeyen tip: %s" % t)
				return
		var all_k: Array = COLORS.keys()
		var cand: Array = all_k.filter(func(k): return not used.has(k) and String(k) != last)
		if cand.is_empty():
			cand = all_k.filter(func(k): return not used.has(k))
		if cand.is_empty():
			Log.error("GameData", "Renk hedefi atanamıyor (tip=%s)." % t)
			return
		cand.shuffle()
		var pick := String(cand[0])
		d.target = pick
		used[pick] = true
		last = pick


func _assign_unique_targets_in_segment(levels: Array) -> void:
	if levels.is_empty():
		return
	var by_type: Dictionary = {}
	for item in levels:
		if not item is Dictionary:
			continue
		var d: Dictionary = item
		var t := String(d.type)
		if not by_type.has(t):
			by_type[t] = []
		by_type[t].append(d)
	for t in by_type:
		_assign_unique_from_pool(by_type[t], _pool_for_level_type(t))


func _pool_for_level_type(t: String) -> Dictionary:
	match t:
		"color_circle", "color_text", "color_mixed":
			return COLORS
		"animal":
			return ANIMALS
		"fruit":
			return FRUITS
	return {}


## Havuzdan karışık, tekrarsız hedef ata (sayı > havuz ise hata).
func _assign_unique_from_pool(levels: Array, pool: Dictionary) -> void:
	var n: int = levels.size()
	var keys: Array = pool.keys()
	if keys.size() < n:
		Log.error("GameData", "Tekrarsız soru için havuz yetersiz: %d soru, %d aday." % [n, keys.size()])
		return
	keys.shuffle()
	for i in n:
		var lv_item: Variant = levels[i]
		if lv_item is Dictionary:
			(lv_item as Dictionary).target = String(keys[i])


func _ready() -> void:
	# Veri bütünlüğü kontrolleri (defansif).
	assert(LEVELS.size() == TOTAL_LEVELS,
		"GameData: LEVELS dizisi %d olmalı, %d bulundu" % [TOTAL_LEVELS, LEVELS.size()])
	for i in LEVELS.size():
		var lv: Dictionary = LEVELS[i]
		assert(lv.id == i + 1, "GameData: Seviye id %d olmalı" % (i + 1))
		assert(_is_valid_target(lv), "GameData: Geçersiz target '%s' (seviye %d)" % [lv.target, lv.id])
	Log.info("GameData", "%d seviye doğrulandı." % TOTAL_LEVELS)


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


## Tıklanan seçeneğin Türkçe adı (yanlış cevap sesli geri bildirimi).
func get_choice_tr(level: Dictionary, key: String) -> String:
	match level.type:
		"color_circle", "color_text", "color_mixed":
			if COLORS.has(key):
				return COLORS[key].tr
		"animal":
			if ANIMALS.has(key):
				return ANIMALS[key].tr
		"fruit":
			if FRUITS.has(key):
				return FRUITS[key].tr
	return ""


## Prompt label'ın rengi (renkli seviyelerde target rengi, diğerlerinde siyah).
func get_prompt_color(level: Dictionary) -> Color:
	match level.type:
		"color_circle", "color_text", "color_mixed":
			return COLORS[level.target].hex
		_:
			return Color("#073B4C")
