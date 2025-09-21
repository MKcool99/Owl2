extends Node2D

# --- UI references ---
@onready var equation_input: LineEdit = $EquationUI/EquationInput
@onready var plot_button: Button = $EquationUI/PlotButton
@onready var clear_button: Button = $EquationUI/ClearButton
@onready var graph_container: Node2D = $GraphContainer
@onready var owl: PathFollow2D = $GraphPath/Owl
@onready var graph_path: Path2D = $GraphPath

# --- Owl settings ---
const OWL_SPEED = 400.0
var owl_following = false
var owl_progress = 0.0
var total_path_length = 0.0

# --- Graph settings ---
const GRAPH_WIDTH = 1152
const GRAPH_HEIGHT = 648
const GRAPH_SCALE = 50
const LINE_WIDTH = 2.0
const AXIS_COLOR = Color(0.5, 0.5, 0.5, 0.8)
const GRID_COLOR = Color(0.3, 0.3, 0.3, 0.5)

# --- Graph storage ---
var current_graphs: Array[Line2D] = []
var axis_lines: Array[Line2D] = []
var grid_lines: Array[Line2D] = []
var current_path_points: PackedVector2Array = []

# --- Origin offsets (centered) ---
var ORIGIN_X = GRAPH_WIDTH / 2
var ORIGIN_Y = GRAPH_HEIGHT / 2

# --- Math constants ---
const PI = 3.141592653589793
const E = 2.718281828459045

func _ready():
	# Connect UI
	plot_button.pressed.connect(_on_plot_button_pressed)
	clear_button.pressed.connect(_on_clear_button_pressed)
	equation_input.text_submitted.connect(_on_equation_submitted)

	# Ensure Path2D has a Curve2D
	if not graph_path.curve:
		graph_path.curve = Curve2D.new()

	# Draw coordinate system
	_draw_coordinate_system()

	# Hide the owl initially
	owl.visible = false

func _process(delta):
	if owl_following and total_path_length > 0 and owl.can_move:
		owl_progress += OWL_SPEED * delta
		var ratio = owl_progress / total_path_length
		if ratio >= 1.0:
			ratio = 1.0
			owl_following = false
		owl.progress_ratio = ratio

# --- Coordinate system ---
func _draw_coordinate_system():
	# Clear old lines
	for line in axis_lines + grid_lines:
		line.queue_free()
	axis_lines.clear()
	grid_lines.clear()

	# --- Axes ---
	var x_axis = Line2D.new()
	x_axis.width = 1.5
	x_axis.default_color = AXIS_COLOR
	x_axis.add_point(Vector2(0, ORIGIN_Y))
	x_axis.add_point(Vector2(GRAPH_WIDTH, ORIGIN_Y))
	graph_container.add_child(x_axis)
	axis_lines.append(x_axis)

	var y_axis = Line2D.new()
	y_axis.width = 1.5
	y_axis.default_color = AXIS_COLOR
	y_axis.add_point(Vector2(ORIGIN_X, 0))
	y_axis.add_point(Vector2(ORIGIN_X, GRAPH_HEIGHT))
	graph_container.add_child(y_axis)
	axis_lines.append(y_axis)

	# --- Grid lines ---
	var spacing = GRAPH_SCALE

	# Vertical lines right
	var x = ORIGIN_X + spacing
	while x < GRAPH_WIDTH:
		var line = Line2D.new()
		line.width = 0.5
		line.default_color = GRID_COLOR
		line.add_point(Vector2(x, 0))
		line.add_point(Vector2(x, GRAPH_HEIGHT))
		graph_container.add_child(line)
		grid_lines.append(line)
		x += spacing

	# Vertical lines left
	x = ORIGIN_X - spacing
	while x > 0:
		var line = Line2D.new()
		line.width = 0.5
		line.default_color = GRID_COLOR
		line.add_point(Vector2(x, 0))
		line.add_point(Vector2(x, GRAPH_HEIGHT))
		graph_container.add_child(line)
		grid_lines.append(line)
		x -= spacing

	# Horizontal lines up
	var y = ORIGIN_Y + spacing
	while y < GRAPH_HEIGHT:
		var line = Line2D.new()
		line.width = 0.5
		line.default_color = GRID_COLOR
		line.add_point(Vector2(0, y))
		line.add_point(Vector2(GRAPH_WIDTH, y))
		graph_container.add_child(line)
		grid_lines.append(line)
		y += spacing

	# Horizontal lines down
	y = ORIGIN_Y - spacing
	while y > 0:
		var line = Line2D.new()
		line.width = 0.5
		line.default_color = GRID_COLOR
		line.add_point(Vector2(0, y))
		line.add_point(Vector2(GRAPH_WIDTH, y))
		graph_container.add_child(line)
		grid_lines.append(line)
		y -= spacing

# --- UI callbacks ---
func _on_plot_button_pressed():
	_plot_equation()

func _on_clear_button_pressed():
	_clear_graphs()

func _on_equation_submitted(text: String):
	_plot_equation()

func _clear_graphs():
	for g in current_graphs:
		g.queue_free()
	current_graphs.clear()
	current_path_points.clear()
	graph_path.curve.clear_points()
	owl.visible = false
	owl_following = false
	owl_progress = 0.0
	total_path_length = 0.0
	_draw_coordinate_system()

# --- Graph plotting ---
func _plot_equation():
	_clear_graphs()
	var equation = equation_input.text.strip_edges()
	if equation.is_empty():
		return

	var line = Line2D.new()
	line.width = LINE_WIDTH
	var colors = [Color.CYAN, Color.YELLOW, Color.MAGENTA, Color.GREEN, Color.ORANGE, Color.RED]
	line.default_color = colors[current_graphs.size() % colors.size()]
	line.antialiased = true

	var x_min = -GRAPH_WIDTH / (2.0 * GRAPH_SCALE)
	var x_max = GRAPH_WIDTH / (2.0 * GRAPH_SCALE)
	var step = (x_max - x_min) / 1000.0
	var previous_y = NAN
	var segment_points: PackedVector2Array = []

	for i in range(1001):
		var x = x_min + i * step
		var y = _evaluate_equation(equation, x)
		if not is_nan(y) and not is_inf(y):
			var screen_x = ORIGIN_X + x * GRAPH_SCALE
			var screen_y = ORIGIN_Y - y * GRAPH_SCALE
			if not is_nan(previous_y) and abs(y - previous_y) > 10:
				if segment_points.size() > 1:
					line.points = segment_points
					graph_container.add_child(line)
					current_graphs.append(line)
					line = Line2D.new()
					line.width = LINE_WIDTH
					line.default_color = colors[current_graphs.size() % colors.size()]
					line.antialiased = true
				segment_points.clear()
			segment_points.append(Vector2(screen_x, screen_y))
		else:
			if segment_points.size() > 1:
				line.points = segment_points
				graph_container.add_child(line)
				current_graphs.append(line)
				line = Line2D.new()
				line.width = LINE_WIDTH
				line.default_color = colors[current_graphs.size() % colors.size()]
				line.antialiased = true
			segment_points.clear()
		previous_y = y

	if segment_points.size() > 1:
		line.points = segment_points
		graph_container.add_child(line)
		current_graphs.append(line)
		current_path_points.append_array(segment_points)

	if current_path_points.size() > 1:
		graph_path.curve.clear_points()
		for p in current_path_points:
			graph_path.curve.add_point(p)
		total_path_length = 0.0
		for i in range(1, current_path_points.size()):
			total_path_length += current_path_points[i-1].distance_to(current_path_points[i])
		owl.progress_ratio = 0.0
		owl.visible = true
		owl_following = true
		owl_progress = 0.0

# --- Equation evaluation ---
func _evaluate_equation(equation: String, x: float) -> float:
	var expr = equation.replace("x", "(" + str(x) + ")")
	expr = _replace_math_functions(expr)
	var expression = Expression.new()
	if expression.parse(expr) != OK:
		return NAN
	var result = expression.execute()
	if expression.has_execute_failed():
		return NAN
	return float(result)

func _replace_math_functions(expr: String) -> String:
	expr = expr.replace("^", "**")
	expr = expr.replace("pi", str(PI))
	expr = expr.replace("e", str(E))
	expr = expr.replace("ln(", "log(")
	# Add more replacements if needed
	return expr
