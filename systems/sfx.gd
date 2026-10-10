class_name Sfx
extends Node
## 占位音效：运行时合成 AudioStreamWAV（无音频资产依赖）。
## 发射/命中/击杀/受击四类；同类命中音最小播放间隔 0.05s 防叠加（设计文档 6.4）。

var players: Array[AudioStreamPlayer] = []
var streams: Dictionary = {}
var last_hit_play := -1.0
var time_now := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.volume_db = -16.0
		add_child(p)
		players.append(p)
	streams["fire"] = _tone(620.0, 180.0, 0.12, 0.5)
	streams["hit"] = _noise(0.07, 0.5)
	streams["kill"] = _tone(220.0, 60.0, 0.16, 0.6)
	streams["hurt"] = _tone(130.0, 85.0, 0.2, 0.55, true)
	EventBus.attack_fired.connect(func(_e, _i, _p, _d): play("fire"))
	EventBus.attack_hit.connect(_on_hit)
	EventBus.player_damaged.connect(func(_a, _h): play("hurt"))


func _process(delta: float) -> void:
	time_now += delta


func _on_hit(_attack_id: int, _target_id: int, _pos: Vector2, _element: int, killed: bool) -> void:
	if killed:
		play("kill")
	elif time_now - last_hit_play >= 0.05:
		last_hit_play = time_now
		play("hit")


func play(key: String) -> void:
	var s: AudioStreamWAV = streams.get(key)
	if s == null:
		return
	for p in players:
		if not p.playing:
			p.stream = s
			p.play()
			return


## 简单合成：频率滑音正弦/方波 + 线性衰减包络
func _tone(f0: float, f1: float, dur: float, vol: float, square := false) -> AudioStreamWAV:
	var rate := 22050
	var n := int(dur * rate)
	var phase := 0.0
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / rate
		var f := lerpf(f0, f1, t / dur)
		phase += TAU * f / rate
		var v := sin(phase)
		if square:
			v = signf(v) * 0.8 + 0.2 * v
		v *= vol * (1.0 - t / dur)
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	return _make_wav(data, rate)


func _noise(dur: float, vol: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(dur * rate)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / rate
		var v := Rng.randf_range(-1.0, 1.0) * vol * (1.0 - t / dur)
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	return _make_wav(data, rate)


func _make_wav(data: PackedByteArray, rate: int) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w
