extends "res://area_2d.gd"

func _on_area_entered(area: Area2D) -> void:
	print("Overlapping with Area2D: ", area.name)
	#get_tree().change_scene_to_file("res://level_2.tscn")
	get_tree().reload_current_scene()
