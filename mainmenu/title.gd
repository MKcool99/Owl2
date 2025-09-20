extends Sprite2D

var velocity : float =  20;

func _process(delta):
	skew += velocity * delta;
	print(skew);
