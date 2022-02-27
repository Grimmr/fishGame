extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var maxV = 100.0
var V = 0

# Called when the node enters the scene tree for the first time.
func _process(delta):
	scale.x = V/maxV

func updateMax(v):
	maxV = v
	
func updateValue(v):
	V = v
	
func updateValueDelta(v):
	V += v
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
