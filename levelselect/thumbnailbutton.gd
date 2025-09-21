extends TextureButton

const NORMAL_SCALE := Vector2(0.5, 0.5)
const HOVER_SCALE := Vector2(0.6, 0.6)
const DURATION := 0.2

var tween: Tween

func _ready() -> void:
	scale = NORMAL_SCALE
	z_index = 0  # default layer
	tween = create_tween()
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))

func _on_mouse_entered() -> void:
	z_index = 100  # bring to front (higher = drawn above lower values)
	tween.kill()
	tween = create_tween()
	tween.tween_property(self, "scale", HOVER_SCALE, DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_mouse_exited() -> void:
	z_index = 0  # reset
	tween.kill()
	tween = create_tween()
	tween.tween_property(self, "scale", NORMAL_SCALE, DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_pressed_1() -> void:
	get_tree().change_scene_to_file("res://level_1.tscn")

func _on_pressed_2() -> void:
	get_tree().change_scene_to_file("res://level_2.tscn")

func _on_pressed_3() -> void:
	get_tree().change_scene_to_file("res://level_3.tscn")

func _on_pressed_4() -> void:
	get_tree().change_scene_to_file("res://level_4.tscn")

func _on_pressed_5() -> void:
	get_tree().change_scene_to_file("res://level_5.tscn")
