extends Sprite2D

# Speed at which the image moves
var move_speed : int = 200

func _ready():
	# Initial setup if necessary
	pass

func _process(delta):
	# Get input direction
	var move_direction = Vector2.ZERO
	
	if Input.is_action_pressed("space"):
		move_direction.x += 1
	if Input.is_action_pressed("ui_left"):
		move_direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		move_direction.y += 1
	if Input.is_action_pressed("ui_up"):
		move_direction.y -= 1
	
	# Normalize direction to avoid faster movement diagonally
	move_direction = move_direction.normalized()

	# Move the sprite
	position += move_direction * move_speed * delta
