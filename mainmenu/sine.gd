extends Sprite2D

var speed := 100.0
var amplitude := 30.0
var frequency := 0.10

func _ready():
	position.x = 0
	position.y = 300
	speed = randf_range(70, 200)
	amplitude = randf_range(10, 100)
	frequency = randf_range(0.08, 0.20)

func _process(delta):
	position.x += speed * delta
	position.y = 300 + amplitude * sin(frequency * position.x)
	if (position.x > 1300):
		position.x = -300
		
		speed = randf_range(70, 200)
		amplitude = randf_range(10, 100)
		frequency = randf_range(0.08, 0.20)
