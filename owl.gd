extends Sprite2D

var move_speed: float = 300.0

func _process(delta):
	var input_vector = Vector2.ZERO

	# WASD input
	if Input.is_action_pressed("ui_up"):    # default = W / Up arrow
		input_vector.y -= 1
	if Input.is_action_pressed("ui_down"):  # default = S / Down arrow
		input_vector.y += 1
	if Input.is_action_pressed("ui_left"):  # default = A / Left arrow
		input_vector.x -= 1
	if Input.is_action_pressed("ui_right"): # default = D / Right arrow
		input_vector.x += 1

	# Normalize so diagonal movement isn’t faster
	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()

	# Move owl
	position += input_vector * move_speed * delta
