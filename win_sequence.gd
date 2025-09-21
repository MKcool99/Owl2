extends Area2D

@export var owl_node: NodePath
@export var camera_node: NodePath

@export var transition_rect_node: NodePath

var is_winning = false

func _on_area_entered(area):
	if area.is_in_group("player") and not is_winning:
		is_winning = true
		var owl = get_node(owl_node)
		var camera = get_node(camera_node)
		var transition_rect = get_node(transition_rect_node)
		
		if owl and camera and transition_rect:
			owl.can_move = false
			
			# Zoom and fade transition
			var tween = create_tween().set_parallel()
			tween.tween_property(camera, "zoom", Vector2(20, 20), 2.0).set_trans(Tween.TRANS_LINEAR)
			tween.tween_property(camera, "global_position", owl.global_position, 2.0).set_trans(Tween.TRANS_LINEAR)
			
			# Start the fade-in of the color rectangle after a delay
			var color_tween = create_tween()
			color_tween.tween_property(transition_rect, "visible", true, 0)
			color_tween.tween_property(transition_rect, "modulate", Color(0.098, 0.09, 0.18, 1), 1.0).set_delay(1.0)
			
			# Wait for both tweens to finish
			await tween.finished
			await color_tween.finished
			
			# Change to the win screen
			get_tree().change_scene_to_file("res://win_screen.tscn")
