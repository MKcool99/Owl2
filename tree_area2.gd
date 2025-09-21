extends "res://area_2d.gd"

# Function attached to the tree Area2D
func _on_area_entered(area: Area2D) -> void:
	print("Overlapping with Area2D: ", area.name)
	#get_tree().change_scene_to_file("res://level_2.tscn")
	var rect := ColorRect.new()
	rect.color = Color.BLACK
	rect.size = Vector2(10000, 10000)
	rect.position = Vector2(-5500, -5000)
	rect.modulate.a = 0.0  # start transparent
	add_child(rect)  # add on top of the current scene
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.z_index = 999
	var tween = create_tween()
	tween.tween_property(rect, "modulate:a", 1.0, 0.5) # 0.5s fade
	await tween.finished
	get_tree().call_deferred("change_scene_to_file", "res://level_3.tscn")
	tween = create_tween()
	tween.tween_property(rect, "modulate:a", 0.0, 0.5)
	await tween.finished
	rect.queue_free()
