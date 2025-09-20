extends Sprite2D

# Quadratic function parameters
var a: float = .002
var b: float = -1
var c: float = 200

var speed: float = 100
var time: float = 0

# Control flag: only true after key is pressed
var is_flying: bool = false

func _process(delta):
	# Wait for key press to start flying
	if not is_flying and Input.is_action_just_pressed("Enter"):
		is_flying = true

	# If flying, move along the quadratic path
	if is_flying:
		time += delta * speed
		var x_position = time
		var y_position = a * x_position * x_position + b * x_position + c
		position = Vector2(x_position, y_position)
		
		# Optional: stop flying if off-screen
		if x_position > 1000:
			is_flying = false
