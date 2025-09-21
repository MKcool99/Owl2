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

			# Calculate offset for zoom target (slightly left and down)
			var offset = Vector2(-10, 7) * owl.scale
			var zoom_target = owl.global_position + offset

			# Tween 1: Move camera to offset position
			var move_tween = create_tween()
			move_tween.tween_property(camera, "global_position", zoom_target, 0.5).set_trans(Tween.TRANS_LINEAR)
			await move_tween.finished

			# Tween 2: Zoom and fade
			var fade_tween = create_tween()
			transition_rect.visible = true
			transition_rect.modulate = Color(1, 1, 1, 0)
			fade_tween.tween_property(transition_rect, "modulate", Color(0.098, 0.09, 0.18, 1), 6.0).set_trans(Tween.TRANS_LINEAR)

			var zoom_tween = create_tween()
			zoom_tween.tween_property(camera, "zoom", Vector2(30, 30), 2.0).set_trans(Tween.TRANS_LINEAR)
			zoom_tween.tween_property(camera, "zoom", Vector2(500, 500), 4.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

			await fade_tween.finished
			await zoom_tween.finished
			
			# Change to the win screen
			get_tree().change_scene_to_file("res://win_screen.tscn")
