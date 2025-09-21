extends Camera2D

@onready var tween := get_tree().create_tween()
@onready var owl = $"../Owl"

func focus_on_owl(owl: Node2D):
	# Kill any old tween if still running
	if tween.is_running():
		tween.kill()
	
	# Create a new tween
	tween = get_tree().create_tween()
	
	# Smooth zoom (ease-in)
	tween.tween_property(self, "zoom", Vector2(0.5, 0.5), 1.5) \
		.set_ease(Tween.EASE_IN) \
		.set_trans(Tween.TRANS_SINE)
	
	# Smooth move camera to owl’s position
	tween.tween_property(self, "global_position", owl.global_position, 1.5) \
		.set_ease(Tween.EASE_IN) \
		.set_trans(Tween.TRANS_SINE)

func _on_tree_area_area_entered(area: Area2D) -> void:
	focus_on_owl(owl)
