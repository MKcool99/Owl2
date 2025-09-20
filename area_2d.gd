extends Area2D

func _ready():
	connect("area_entered", Callable(self, "_on_area_entered"))
	connect("area_exited", Callable(self, "_on_area_exited"))

func _on_area_entered(area: Area2D) -> void:
	print("Overlap started with: ", area.name)
	# Do something here when the owl overlaps another object

func _on_area_exited(area: Area2D) -> void:
	print("Overlap ended with: ", area.name)
