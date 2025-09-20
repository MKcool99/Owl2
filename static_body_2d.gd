extends StaticBody2D

func _ready():
	# Connect overlap signals
	connect("area_entered", Callable(self, "_on_area_entered"))
	connect("area_exited", Callable(self, "_on_area_exited"))

func _on_area_entered(area: CollisionShape2D) -> void:
	print("Overlap started with: ", area.name)

func _on_area_exited(area: CollisionShape2D) -> void:
	print("Overlap ended with: ", area.name)
