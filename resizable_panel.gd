extends PanelContainer

# Resizing variables
var is_resizing = false
var resize_margin = 10
var resize_direction = Vector2()

# Dragging variables
var is_dragging = false
var drag_start_pos = Vector2()
var original_position = Vector2()
var original_size = Vector2()

# Font scaling variables
var original_font_sizes = {}
var initial_size = Vector2.ZERO

func _ready():
	# A small delay to ensure the node is fully initialized
	await get_tree().create_timer(0.1).timeout
	initial_size = size
	store_original_font_sizes(self)

func store_original_font_sizes(node):
	for child in node.get_children():
		if child is Control:
			if child.has_theme_font_size("font_size"):
				var font_size = child.get_theme_font_size("font_size")
				if font_size > 0:
					original_font_sizes[child] = font_size
		if child.get_child_count() > 0:
			store_original_font_sizes(child)

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var mouse_pos = get_local_mouse_position()
			if is_on_border(mouse_pos):
				is_resizing = true
				is_dragging = false
				drag_start_pos = get_global_mouse_position()
				original_size = size
				resize_direction = get_resize_direction(mouse_pos)
			else:
				is_dragging = true
				is_resizing = false
				drag_start_pos = get_global_mouse_position()
				original_position = position
		else:
			is_resizing = false
			is_dragging = false
			mouse_default_cursor_shape = CURSOR_ARROW

	elif event is InputEventMouseMotion:
		var mouse_pos = get_local_mouse_position()
		if is_resizing:
			var mouse_delta = get_global_mouse_position() - drag_start_pos
			var new_size = original_size + mouse_delta * resize_direction
			size = new_size.max(custom_minimum_size)
			update_font_sizes()
		elif is_dragging:
			position = original_position + get_global_mouse_position() - drag_start_pos
		elif is_on_border(mouse_pos):
			var direction = get_resize_direction(mouse_pos)
			if direction.x != 0 and direction.y != 0:
				if (direction.x > 0 and direction.y > 0) or (direction.x < 0 and direction.y < 0):
					mouse_default_cursor_shape = CURSOR_BDIAGSIZE
				else:
					mouse_default_cursor_shape = CURSOR_FDIAGSIZE
			elif direction.x != 0:
				mouse_default_cursor_shape = CURSOR_HSIZE
			elif direction.y != 0:
				mouse_default_cursor_shape = CURSOR_VSIZE
		else:
			mouse_default_cursor_shape = CURSOR_ARROW

func is_on_border(pos):
	return pos.x >= 0 and pos.x < resize_margin or pos.x < size.x and pos.x > size.x - resize_margin or \
		   pos.y >= 0 and pos.y < resize_margin or pos.y < size.y and pos.y > size.y - resize_margin

func get_resize_direction(pos):
	var dir = Vector2()
	if pos.x < resize_margin:
		dir.x = -1
	elif pos.x > size.x - resize_margin:
		dir.x = 1
	
	if pos.y < resize_margin:
		dir.y = -1
	elif pos.y > size.y - resize_margin:
		dir.y = 1
		
	return dir

func update_font_sizes():
	if initial_size.y == 0: return # Avoid division by zero
	var scale_factor = size.y / initial_size.y
	for node in original_font_sizes:
		var original_font_size = original_font_sizes[node]
		var new_font_size = max(1, int(original_font_size * scale_factor))
		node.add_theme_font_size_override("font_size", new_font_size)
