extends Area2D

func _ready():
	connect("area_entered", Callable(self, "_on_area_entered"))
	connect("area_exited", Callable(self, "_on_area_exited"))
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_area_entered(area: Area2D) -> void:
	print("Overlapping with Area2D: ", area.name)

func _on_area_exited(area: Area2D) -> void:
	print("Stopped overlapping with Area2D: ", area.name)

func _on_body_entered(body: Node) -> void:
	print("Collided with body: ", body.name)
