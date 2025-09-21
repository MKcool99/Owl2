extends Node2D

# References to UI elements
@onready var equation_input: LineEdit = $EquationUI/EquationInput
@onready var plot_button: Button = $EquationUI/PlotButton
@onready var clear_button: Button = $EquationUI/ClearButton
@onready var graph_container: Node2D = $GraphContainer
@onready var owl: PathFollow2D = $GraphPath/Owl
@onready var graph_path: Path2D = $GraphPath

# Owl settings
const OWL_SPEED = 150.0 # pixels per second
var owl_is_moving = false
var total_path_length = 0.0

var graph_scale_y = GRAPH_SCALE_X

# Graph settings
const GRAPH_WIDTH = 1152  # Screen width
const GRAPH_HEIGHT = 648  # Screen height

const GRAPH_SCALE_X = 50    # Pixels per unit
const LINE_COLOR = Color.CYAN
const LINE_WIDTH = 2.0
const AXIS_COLOR = Color(0.5, 0.5, 0.5, 0.8)
const GRID_COLOR = Color(0.3, 0.3, 0.3, 0.5)

# Mathematical constants
const PI = 3.141592653589793
const E = 2.718281828459045

# Store current graphs for clearing
var current_graphs: Array[Line2D] = []
var axis_lines: Array[Line2D] = []
var grid_lines: Array[Line2D] = []

var current_path_points: PackedVector2Array = []
var owl_progress = 0.0
var owl_following = false

var ai_owl_scene: PackedScene = preload("res://ai_owl.tscn")
var ai_owl: Node2D = null
@onready var ai_function_label: Label = $EquationUI/AIFunctionLabel

func _ready():
	# Connect button signals
	plot_button.pressed.connect(_on_plot_button_pressed)
	clear_button.pressed.connect(_on_clear_button_pressed)
	
	# Connect enter key in input field
	equation_input.text_submitted.connect(_on_equation_submitted)
	
	# Ensure the Path2D has a Curve2D resource
	if not graph_path.curve:
		graph_path.curve = Curve2D.new()
	
	# Draw coordinate system
	_draw_coordinate_system()
	
	# Hide the owl initially
	owl.visible = false

	# Add a new label for the AI function
	ai_function_label = Label.new()
	ai_function_label.position = Vector2(10, 65)
	ai_function_label.text = "AI Owl Function: "
	$EquationUI.add_child(ai_function_label)

func _process(delta):
	if owl_following and total_path_length > 0:
		owl_progress += OWL_SPEED * delta
		var ratio = owl_progress / total_path_length
		if ratio >= 1.0:
			ratio = 1.0
			owl_following = false
		# Move owl along the path using progress_ratio property
		owl.progress_ratio = ratio

func _draw_coordinate_system():
	# Clear existing axis and grid lines
	for line in axis_lines + grid_lines:
		line.queue_free()
	axis_lines.clear()
	grid_lines.clear()
	
	var origin_y = GRAPH_HEIGHT / 2.0
	
	# Draw main axes (origin at center-left)
	var x_axis = Line2D.new()
	x_axis.width = 1.5
	x_axis.default_color = AXIS_COLOR
	x_axis.add_point(Vector2(0, origin_y))
	x_axis.add_point(Vector2(GRAPH_WIDTH, origin_y))
	graph_container.add_child(x_axis)
	axis_lines.append(x_axis)
	
	var y_axis = Line2D.new()
	y_axis.width = 1.5
	y_axis.default_color = AXIS_COLOR
	y_axis.add_point(Vector2(0, 0))
	y_axis.add_point(Vector2(0, GRAPH_HEIGHT))
	graph_container.add_child(y_axis)
	axis_lines.append(y_axis)
	
	# Draw grid lines
	var grid_spacing_x = GRAPH_SCALE_X
	
	# Vertical grid lines
	var x = grid_spacing_x
	while x < GRAPH_WIDTH:
		var line = Line2D.new()
		line.width = 0.5
		line.default_color = GRID_COLOR
		line.add_point(Vector2(x, 0))
		line.add_point(Vector2(x, GRAPH_HEIGHT))
		graph_container.add_child(line)
		grid_lines.append(line)
		x += grid_spacing_x
	
	# Horizontal grid lines (from center up and down)
	var y_up = origin_y - graph_scale_y
	while y_up > 0:
		var line = Line2D.new()
		line.width = 0.5
		line.default_color = GRID_COLOR
		line.add_point(Vector2(0, y_up))
		line.add_point(Vector2(GRAPH_WIDTH, y_up))
		graph_container.add_child(line)
		grid_lines.append(line)
		y_up -= graph_scale_y

	var y_down = origin_y + graph_scale_y
	while y_down < GRAPH_HEIGHT:
		var line = Line2D.new()
		line.width = 0.5
		line.default_color = GRID_COLOR
		line.add_point(Vector2(0, y_down))
		line.add_point(Vector2(GRAPH_WIDTH, y_down))
		graph_container.add_child(line)
		grid_lines.append(line)
		y_down += graph_scale_y

func _on_plot_button_pressed():
	_plot_equation()

func _on_clear_button_pressed():
	graph_scale_y = GRAPH_SCALE_X
	_clear_graphs()
	_draw_coordinate_system()

func _on_equation_submitted(text: String):
	_plot_equation()

func _clear_graphs():
	# Remove all current graph lines
	for graph in current_graphs:
		graph.queue_free()
	current_graphs.clear()
	
	# Clear the path for the owl
	current_path_points.clear()
	graph_path.curve.clear_points()
	owl.visible = false
	owl_following = false
	owl_progress = 0.0
	total_path_length = 0.0


func _plot_equation():
	var equation = equation_input.text.strip_edges()
	if equation.is_empty():
		return

	graph_scale_y = GRAPH_SCALE_X # Reset to default scale

	_clear_graphs() # Clear previous graphs
	_draw_coordinate_system() # Redraw with new scale
	
	# Create new Line2D for this graph
	var line = Line2D.new()
	line.width = LINE_WIDTH
	
	# Use different colors for multiple graphs
	var colors = [Color.CYAN, Color.YELLOW, Color.MAGENTA, Color.GREEN, Color.ORANGE, Color.RED]
	line.default_color = colors[current_graphs.size() % colors.size()]
	line.antialiased = true
	
	# Generate points for the graph
	var points: PackedVector2Array = []
	var x_min = 0
	var x_max = GRAPH_WIDTH / GRAPH_SCALE_X
	var step = (x_max - x_min) / 1000.0  # 1000 points for smooth curve
	
	var previous_y = NAN
	var segment_points: PackedVector2Array = []
	
	for i in range(1001):
		var x = x_min + i * step
		var y = _evaluate_equation(equation, x)
		
		if not is_nan(y) and not is_inf(y):
			# Convert mathematical coordinates to screen coordinates (origin at center-left)
			var screen_x = x * GRAPH_SCALE_X
			var screen_y = (GRAPH_HEIGHT / 2.0) - y * graph_scale_y
			
			# Check for discontinuities (large jumps in y values)
			if not is_nan(previous_y) and abs(y - previous_y) > 10:
				# Add current segment and start new one
				if segment_points.size() > 1:
					line.points = segment_points
					graph_container.add_child(line)
					current_graphs.append(line)
					
					# Create new line for next segment
					line = Line2D.new()
					line.width = LINE_WIDTH
					line.default_color = colors[current_graphs.size() % colors.size()]
					line.antialiased = true
				segment_points.clear()
			
			# Only add points that are reasonably visible on screen
			if screen_y >= -200 and screen_y <= GRAPH_HEIGHT + 200:
				segment_points.append(Vector2(screen_x, screen_y))
		else:
			# Handle discontinuity
			if segment_points.size() > 1:
				line.points = segment_points
				graph_container.add_child(line)
				current_graphs.append(line)
				
				# Create new line for next segment
				line = Line2D.new()
				line.width = LINE_WIDTH
				line.default_color = colors[current_graphs.size() % colors.size()]
				line.antialiased = true
			segment_points.clear()
		
		previous_y = y
	
	# Add final segment
	if segment_points.size() > 1:
		line.points = segment_points
		graph_container.add_child(line)
		current_graphs.append(line)
		
		# Update the main path for the owl
		current_path_points.append_array(segment_points)

	# Set the curve for the Path2D
	if current_path_points.size() > 1:
		graph_path.curve.clear_points()
		for p in current_path_points:
			graph_path.curve.add_point(p)
		
		# Calculate total path length
		total_path_length = 0.0
		for i in range(1, current_path_points.size()):
			total_path_length += current_path_points[i-1].distance_to(current_path_points[i])
			
		# Start the owl
		owl.progress_ratio = 0.0
		owl.visible = true
		owl_following = true
		owl_progress = 0.0


func _evaluate_equation(equation: String, x: float) -> float:
	# Wrap x in parentheses to handle negative values correctly
	var expr = equation.replace("x", "(" + str(x) + ")")
	
	# Handle common mathematical functions
	expr = _replace_math_functions(expr)
	
	# Use Godot's Expression class to evaluate
	var expression = Expression.new()
	var error = expression.parse(expr)
	
	if error != OK:
		print("Error parsing equation: ", expression.get_error_text())
		return NAN
	
	var result = expression.execute()
	if expression.has_execute_failed():
		return NAN
	
	return float(result)

func _replace_math_functions(expr: String) -> String:
	# Replace mathematical functions with Godot equivalents
	expr = expr.replace("sin(", "sin(")
	expr = expr.replace("cos(", "cos(")
	expr = expr.replace("tan(", "tan(")
	expr = expr.replace("asin(", "asin(")
	expr = expr.replace("acos(", "acos(")
	expr = expr.replace("atan(", "atan(")
	expr = expr.replace("sqrt(", "sqrt(")
	expr = expr.replace("abs(", "abs(")
	expr = expr.replace("floor(", "floor(")
	expr = expr.replace("ceil(", "ceil(")
	expr = expr.replace("round(", "round(")
	expr = expr.replace("ln(", "log(")
	expr = expr.replace("log(", "log(")
	expr = expr.replace("exp(", "exp(")
	expr = expr.replace("^", "**")  # Power operator
	expr = expr.replace("pi", str(PI))
	expr = expr.replace("e", str(E))
	
	# Handle some common mathematical patterns
	expr = expr.replace("**0.5", "**0.5")  # Square root as power
	
	return expr

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_BACKSPACE:
		_spawn_ai_owl()

func _spawn_ai_owl():
	if ai_owl and is_instance_valid(ai_owl):
		ai_owl.queue_free()

	ai_owl = ai_owl_scene.instantiate()
	add_child(ai_owl)

	var start_y = randf_range(100, GRAPH_HEIGHT - 100)
	ai_owl.start_moving(Vector2(0, start_y), Vector2(GRAPH_WIDTH, GRAPH_HEIGHT))

	ai_owl.collided_with_player.connect(_on_ai_owl_collision)
	ai_owl.function_changed.connect(_on_ai_owl_function_changed)

	# Update the function label
	ai_function_label.text = "AI Owl Function: " + ai_owl.get_current_function()

func _on_ai_owl_function_changed(new_function):
	ai_function_label.text = "AI Owl Function: " + str(new_function)

func _on_ai_owl_collision():
	# Handle game over or other logic
	print("Player owl was caught!")
	get_tree().reload_current_scene()
