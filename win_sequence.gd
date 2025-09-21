extends Area2D

var is_winning = false

func _on_body_entered(body):
	if body.name == "Owl" and not is_winning:
		is_winning = true
		var owl = get_node("/root/level5/GraphPath/Owl")
		var camera = get_viewport().get_camera_2d()
		
		if owl and camera:
			# Zoom into the owl
			var tween = create_tween()
			tween.tween_property(camera, "zoom", Vector2(4, 4), 2.0).set_trans(Tween.TRANS_LINEAR)
			
			# Wait for the zoom to finish
			await tween.finished
			
			# Change to the win screen
			get_tree().change_scene_to_file("res://win_screen.tscn")
