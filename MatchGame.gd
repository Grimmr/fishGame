extends Node2D

var WaterScene = preload("res://Water.tscn")
var rng = RandomNumberGenerator.new()

export var width = 5
export var height = 10
var gridSize = 40 

var board = []

enum direction {H, V}

enum {CLEAR, LIFT}
var state = CLEAR

func _ready():
	rng.randomize()
	setupBoard()
	print(findMatches())

var count = 0	
func _process(delta):
	count += delta
	if count >= 2 && count <= 10:
		if(state == CLEAR):
			state = LIFT
			count = 0
			clearAllMatches()
		elif(state == LIFT):
			HandleLiftPieces()
			count = 10

func setupBoard():
	for x in range(width):
		board.append([])
		for y in range(height):
			var newWater = WaterScene.instance()
			newWater.setType(rng.randi_range(0,3))
			newWater.position.x = x*gridSize + .5*gridSize
			newWater.position.y = y*gridSize + .5*gridSize
			add_child(newWater)
			board[x].append(newWater)

func findMatches():
	var out = []
	#vertical
	for x in range(width):
		var last = -1
		var start = Vector2(x, 0)
		for y in range(height+1):
			if y == height || board[x][y].getType() != last:
				if(y - start.y >= 3):
					out.append(matchData.new(direction.V, start, Vector2(x, y-1)))
				if(y < height):
					last = board[x][y].getType()
				start = Vector2(x, y)
	#horizontal
	for y in range(height):
		var last = -1
		var start = Vector2(0, y)
		for x in range(width+1):
			if x == width || board[x][y].getType() != last:
				if(x - start.x >= 3):
					out.append(matchData.new(direction.H, start, Vector2(x-1, y)))
				if x < width:
					last = board[x][y].getType()
				start = Vector2(x, y)
	return out 

func clearAllMatches():
	var matches = findMatches()
	for m in matches:
		var start = m.start.y if m.type==direction.V else m.start.x
		var end = m.end.y if m.type==direction.V else m.end.x
		for v in range(start, end+1):
			remove(m.start.x if m.type==direction.V else v, m.start.y if m.type==direction.H else v)

func shiftColumnOne(col, start):
	for y in range(start+1, height):
		var moving = board[col][y]
		board[col][y-1] = moving
		board[col][y] = null
		if moving != null:
			moving.moveTo(col*gridSize + .5*gridSize, (y-1)*gridSize + .5*gridSize)
			
func HandleLiftPieces():
	for x in range(width):
		for y in range(height-1, -1, -1):
			if(board[x][y] == null):
				shiftColumnOne(x, y)

func remove(x, y):
	remove_child(board[x][y])
	board[x][y] = null

class matchData:
	var type
	var start
	var end
	func _init(t, s, e):
		type = t
		start = s
		end = e
	
	func _to_string():
		return "|" + ("V" if type==direction.V else "H") + ", start: %s, end:%s|" % [start,end] 
