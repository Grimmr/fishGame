extends Node2D

var WaterScene = preload("res://Water.tscn")
var rng = RandomNumberGenerator.new()
var sound = 0

export var width = 5
export var height = 10
var gridSize = 40 
var randArray = [0,0,1,1,2,2,3,3,4,4,10]
var cooldown = 0
var board = []

enum direction {H, V}


var dummy

func _ready():
	rng.randomize()
	$MachineNoise.play()
	$Radar.play()
	dummy = WaterScene.instance()
	dummy.setType(999)
	setupBoard()
	print(findMatches())

var count = 0	
func _process(delta):
	HandleLiftPieces()
	clearFish()
	clearAllMatches()


func setupBoard():
	for x in range(width):
		board.append([])
		for y in range(height):
			board[x].append(null)
			createWater(x, y, y)

func clearFish():
	for x in range(width):
		if board[x][0] != null:
			if board[x][0].getType() == 10:
				remove(x,0)

func findMatches():
	var out = []
	#vertical
	for x in range(width):
		var last = -1
		var start = Vector2(x, 0)
		for y in range(height+1):
			if y == height || board[x][y] == null || board[x][y].getType() != last:
				if(y - start.y >= 3 && last != 999):
					out.append(matchData.new(direction.V, start, Vector2(x, y-1)))
				elif(y < height):
					if(board[x][y] == null):
						last = -1
					else:
						last = board[x][y].getType()
				start = Vector2(x, y)
	#horizontal
	for y in range(height):
		var last = -1
		var start = Vector2(0, y)
		for x in range(width+1):
			if x == width || board[x][y] == null || board[x][y].getType() != last:
				if(x - start.x >= 3 && last != 999):
					out.append(matchData.new(direction.H, start, Vector2(x-1, y)))
				if x < width:
					if(board[x][y] == null):
						last = -1
					else:
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
		sound = randi() % 3
		match sound:
			0:
				$WaterSound1.play()
			1:
				$WaterSound2.play()
			2:
				$WaterSound3.play()
			_:
				$WaterSound4.play()

func HandleLiftPieces():
	for x in range(width):
		#lift
		for y in range(1, height):
			if(board[x][y-1] == null && board[x][y] != null && board[x][y] != dummy):
				moveTileBy(board[x][y], 0, -1)
				board[x][y] = null
		#new
		if board[x][height-1] == null:
			createWater(x, height-1, 0)

func createWater(x, y, offset = 0):
	var newWater = WaterScene.instance()
	newWater.setType(randArray[rng.randi() % randArray.size()])
	newWater.position.x = x*gridSize 
	newWater.position.y = (height+offset)*gridSize
	newWater.connect("arrived", self, "onArival")
	add_child(newWater)
	moveTileTo(newWater, x, y)
	return newWater
			

func remove(x, y):
	remove_child(board[x][y])
	board[x][y] = null
	
func swapPieceRight(target):
	if(target.x < 0 || target.x >= width-1 || target.y < 0 || target.y >= height):
		return false
	if(board[target.x+1][target.y] == null || board[target.x][target.y] == null):
		return false
	if(board[target.x+1][target.y].getType() == 999 || board[target.x][target.y].getType() == 999):
		return false
	board[target.x+1][target.y].moveBy(-gridSize, 0)
	board[target.x][target.y].moveBy(gridSize, 0)
	#set dummies
	board[target.x][target.y] = dummy
	board[target.x+1][target.y] = dummy
	if cooldown > 0:
		cooldown -= 1
	return true

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

func moveTileTo(tile, x, y):
	if(tile.getType() == 999):
		return
	var gridPos = tile.position / gridSize
	if gridPos.x < width && gridPos.x >= 0 && gridPos.y < height && gridPos.y >= 0:
		board[gridPos.x][gridPos.y] = dummy
	board[x][y] = dummy
	tile.moveTo(x*gridSize, y*gridSize)

func moveTileBy(tile, x, y):
	var gridPos = tile.position / gridSize
	moveTileTo(tile, gridPos.x + x, gridPos.y + y)

func onArival(tile, from, to):
	var location = to/gridSize
	board[location.x][location.y] = tile
	

func _input(event):
	if event.is_action_pressed("gemGame_Swap"):
		swapPieceRight(get_local_mouse_position() / gridSize)
	if event.is_action("debug"):
		print("-------------------")
		print(board)
		print(findMatches())
	if event.is_action("gemGame_Remove"):
		var target = get_local_mouse_position() / gridSize
		if (cooldown == 0 && board[target.x][target.y] != null):
			if board[target.x][target.y].getType() == 10:
				remove(target.x, target.y)
				cooldown = 10

