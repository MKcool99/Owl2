extends Sprite2D

var time_passed := 0.0
var frequency := 0.5
var amplitude := 0.05

func _process(delta):
	time_passed += delta  # accumulate time
	rotation = amplitude*sin(frequency * time_passed * PI)  # smooth sine wave
