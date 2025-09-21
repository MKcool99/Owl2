extends Area2D

@export var owl_node: NodePath
@export var camera_node: NodePath

var is_winning = false

func _on_body_entered(body):
	if body.get_parent().name == "Owl" and not is_winning:
		is_winning = true
		var owl = get_node(owl_node)
		var camera = get_node(camera_node)
		
		if owl and camera:
			# Zoom into the owl
			var tween = create_tween()
			tween.tween_property(camera, "zoom", Vector2(4, 4), 2.0).set_trans(Tween.TRANS_LINEAR)
			
			# Wait for the zoom to finish
			await tween.finished
			
			# Change to the win screen
			get_tree().change_scene_to_file("res://win_screen.tscn")
