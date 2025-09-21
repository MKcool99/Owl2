extends PathFollow2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_area: Area2D = $CollisionArea

var speed = 100.0
var current_function = ""
var path_points: PackedVector2Array = []
var current_point_index = 0

signal collided_with_player
signal function_changed(new_function)

func _ready():
	randomize()
	collision_area.body_entered.connect(_on_collision)

func _process(delta):
	if path_points.size() > 1:
		move(delta)

func start_moving(start_pos, screen_size):
	generate_random_function()
	emit_signal("function_changed", current_function)
	generate_path(start_pos, screen_size)
	self.position = path_points[0]
	current_point_index = 0

func generate_random_function():
	var terms = []
	var num_terms = randi() % 2 + 1  # 1 or 2 terms

	for i in range(num_terms):
		var term_type = randi() % 3
		var term = ""
		match term_type:
			0:  # sin
				var amp = randf_range(1, 5)
				var freq = randf_range(0.2, 2)
				term = "%s * sin(%s * x)" % [amp, freq]
			1:  # cos
				var amp = randf_range(1, 5)
				var freq = randf_range(0.2, 2)
				term = "%s * cos(%s * x)" % [amp, freq]
			2:  # polynomial
				var coeff = randf_range(0.1, 0.5)
				var power = randi() % 2 + 2  # x^2 or x^3
				term = "%s * x^%s" % [coeff, power]
		terms.append(term)
	
	current_function = " + ".join(terms)

func generate_path(start_pos, screen_size):
	path_points.clear()
	var x = 0
	while x < screen_size.x:
		var y = _evaluate_equation(current_function, x / 50.0) * 50.0
		path_points.append(Vector2(x, start_pos.y - y))
		x += 10

func move(delta):
	if current_point_index < path_points.size() - 1:
		var target = path_points[current_point_index + 1]
		self.position = self.position.move_toward(target, speed * delta)
		if self.position.distance_to(target) < 1.0:
			current_point_index += 1
	else:
		# Reached end of path, generate a new one
		start_moving(self.position, get_viewport_rect().size)

func _evaluate_equation(equation: String, x: float) -> float:
	var expr = equation.replace("x", "(" + str(x) + ")")
	expr = expr.replace("^", "**")
	
	var expression = Expression.new()
	var error = expression.parse(expr)
	
	if error != OK:
		return 0.0
	
	var result = expression.execute()
	if expression.has_execute_failed():
		return 0.0
	
	return float(result)

func _on_collision(body):
	if body.name == "Owl":
		emit_signal("collided_with_player")
		queue_free()

func get_current_function():
	return current_function
