extends Control

func _ready():
	var timer = Timer.new()
	timer.set_wait_time(7.5)
	timer.set_one_shot(true)
	timer.connect("timeout", self._on_timer_timeout)
	add_child(timer)
	timer.start()

func _on_timer_timeout():
	get_tree().change_scene_to_file("res://main.tscn")
