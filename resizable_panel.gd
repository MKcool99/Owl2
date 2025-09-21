extends PanelContainer

var dragging = false
var drag_start_pos = Vector2()
var original_size = Vector2()
var resize_margin = 10
var resize_direction = Vector2()

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var mouse_pos = get_local_mouse_position()
				if is_on_border(mouse_pos):
					dragging = true
					drag_start_pos = get_global_mouse_position()
					original_size = size
					resize_direction = get_resize_direction(mouse_pos)
			else:
				dragging = false
	elif event is InputEventMouseMotion:
		var mouse_pos = get_local_mouse_position()
		if dragging:
			var mouse_delta = get_global_mouse_position() - drag_start_pos
			var new_size = original_size + mouse_delta * resize_direction
			size = new_size.max(custom_minimum_size)
		elif is_on_border(mouse_pos):
			var direction = get_resize_direction(mouse_pos)
			if abs(direction.x) > 0 and abs(direction.y) > 0:
				mouse_default_cursor_shape = CURSOR_ARROW
			elif abs(direction.x) > 0:
				mouse_default_cursor_shape = CURSOR_HSIZE
			else:
				mouse_default_cursor_shape = CURSOR_VSIZE
		else:
			mouse_default_cursor_shape = CURSOR_ARROW

func is_on_border(pos):
	return pos.x < resize_margin or pos.x > size.x - resize_margin or \
		   pos.y < resize_margin or pos.y > size.y - resize_margin

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
