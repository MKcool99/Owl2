extends Node2D

# Change scenes on keypress (temporary)
func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_C):
		get_tree().change_scene_to_file("res://mainmenu/mainmenu.tscn")

# References to UI elements
@onready var equation_input: LineEdit = $EquationUI/EquationInput
@onready var plot_button: Button = $EquationUI/PlotButton
@onready var clear_button: Button = $EquationUI/ClearButton
@onready var graph_container: Node2D = $GraphContainer

# Graph settings
const GRAPH_WIDTH = 1152  # Screen width
const GRAPH_HEIGHT = 648  # Screen height

const GRAPH_SCALE = 50    # Pixels per unit
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

func _ready():
	# Connect button signals
	plot_button.pressed.connect(_on_plot_button_pressed)
	clear_button.pressed.connect(_on_clear_button_pressed)
	
	# Connect enter key in input field
	equation_input.text_submitted.connect(_on_equation_submitted)
	
	# Draw coordinate system
	_draw_coordinate_system()

func _draw_coordinate_system():
	# Clear existing axis and grid lines
	for line in axis_lines + grid_lines:
		line.queue_free()
	axis_lines.clear()
	grid_lines.clear()
	
	var center_x = GRAPH_WIDTH / 2.0
	var center_y = GRAPH_HEIGHT / 2.0
	
	# Draw main axes
	var x_axis = Line2D.new()
	x_axis.width = 1.5
	x_axis.default_color = AXIS_COLOR
	x_axis.add_point(Vector2(0, center_y))
	x_axis.add_point(Vector2(GRAPH_WIDTH, center_y))
	graph_container.add_child(x_axis)
	axis_lines.append(x_axis)
	
	var y_axis = Line2D.new()
	y_axis.width = 1.5
	y_axis.default_color = AXIS_COLOR
	y_axis.add_point(Vector2(center_x, 0))
	y_axis.add_point(Vector2(center_x, GRAPH_HEIGHT))
	graph_container.add_child(y_axis)
	axis_lines.append(y_axis)
	
	# Draw grid lines
	var grid_spacing = GRAPH_SCALE  # One unit spacing
	
	# Vertical grid lines
	var x = center_x
	while x < GRAPH_WIDTH:
		x += grid_spacing
		if x < GRAPH_WIDTH:
			var line = Line2D.new()
			line.width = 0.5
			line.default_color = GRID_COLOR
			line.add_point(Vector2(x, 0))
			line.add_point(Vector2(x, GRAPH_HEIGHT))
			graph_container.add_child(line)
			grid_lines.append(line)
	
	x = center_x
	while x > 0:
		x -= grid_spacing
		if x > 0:
			var line = Line2D.new()
			line.width = 0.5
			line.default_color = GRID_COLOR
			line.add_point(Vector2(x, 0))
			line.add_point(Vector2(x, GRAPH_HEIGHT))
			graph_container.add_child(line)
			grid_lines.append(line)
	
	# Horizontal grid lines
	var y = center_y
	while y < GRAPH_HEIGHT:
		y += grid_spacing
		if y < GRAPH_HEIGHT:
			var line = Line2D.new()
			line.width = 0.5
			line.default_color = GRID_COLOR
			line.add_point(Vector2(0, y))
			line.add_point(Vector2(GRAPH_WIDTH, y))
			graph_container.add_child(line)
			grid_lines.append(line)
	
	y = center_y
	while y > 0:
		y -= grid_spacing
		if y > 0:
			var line = Line2D.new()
			line.width = 0.5
			line.default_color = GRID_COLOR
			line.add_point(Vector2(0, y))
			line.add_point(Vector2(GRAPH_WIDTH, y))
			graph_container.add_child(line)
			grid_lines.append(line)

func _on_plot_button_pressed():
	_plot_equation()

func _on_clear_button_pressed():
	_clear_graphs()

func _on_equation_submitted(text: String):
	_plot_equation()

func _clear_graphs():
	# Remove all current graph lines
	for graph in current_graphs:
		graph.queue_free()
	current_graphs.clear()
	
	# Redraw coordinate system
	_draw_coordinate_system()

func _plot_equation():
	var equation = equation_input.text.strip_edges()
	if equation.is_empty():
		return
	
	# Create new Line2D for this graph
	var line = Line2D.new()
	line.width = LINE_WIDTH
	
	# Use different colors for multiple graphs
	var colors = [Color.CYAN, Color.YELLOW, Color.MAGENTA, Color.GREEN, Color.ORANGE, Color.RED]
	line.default_color = colors[current_graphs.size() % colors.size()]
	line.antialiased = true
	
	# Generate points for the graph
	var points: PackedVector2Array = []
	var x_min = -GRAPH_WIDTH / (2.0 * GRAPH_SCALE)
	var x_max = GRAPH_WIDTH / (2.0 * GRAPH_SCALE)
	var step = (x_max - x_min) / 1000.0  # 1000 points for smooth curve
	
	var previous_y = NAN
	var segment_points: PackedVector2Array = []
	
	for i in range(1001):
		var x = x_min + i * step
		var y = _evaluate_equation(equation, x)
		
		if not is_nan(y) and not is_inf(y):
			# Convert mathematical coordinates to screen coordinates
			var screen_x = GRAPH_WIDTH / 2.0 + x * GRAPH_SCALE
			var screen_y = GRAPH_HEIGHT / 2.0 - y * GRAPH_SCALE
			
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

func _evaluate_equation(equation: String, x: float) -> float:
	# Simple equation parser - replace x with the actual value
	var expr = equation.replace("x", str(x))
	
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
