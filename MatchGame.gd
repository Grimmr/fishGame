extends Node2D

var TileScene = preload("res://Tile.tscn")
var rng = RandomNumberGenerator.new()
onready var chumUI = get_node("ChumUI")
onready var comboUI = get_node("BarUI")

export var width = 5
export var height = 4
var gridSize = 40 
var comboTime = 3.5

var board = []
var chumCount = 0
var combo = 0
var comboTimer = 0

enum direction {H, V}


var dummy

func _ready():
	rng.randomize()
	dummy = TileScene.instance()
	dummy.setType(999)
	setupBoard()
	comboUI.updateMax(comboTime)
	print(findMatches())
	

var count = 0	
func _process(delta):
	HandleLiftPieces()
	clearAllMatches()
	handleFishClear()
	chumUI.updateChum(chumCount) #update the chum UI
	if(combo > 0):
		comboTimer -= delta
		if(comboTimer <= 0):
			combo = 0
			comboTimer = 0
			print(combo)
		comboUI.updateValue(comboTimer)


func setupBoard():
	for x in range(width):
		board.append([])
		for y in range(height):
			board[x].append(null)
			createTile(x, y, y)

func findMatches():
	var out = []
	#vertical
	for x in range(width):
		var last = -1
		var start = Vector2(x, 0)
		for y in range(height+1):
			if y == height || board[x][y] == null || board[x][y].getType() != last || board[x][y].isFish():
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
			if x == width || board[x][y] == null || board[x][y].getType() != last || board[x][y].isFish():
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
		#handle combo effect
		if(board[m.start.x][m.start.y] != null && board[m.start.x][m.start.y].getType() < 100):
			combo += 1
			comboTimer = comboTime
			print(combo)
		for v in range(start, end+1):
			remove(m.start.x if m.type==direction.V else v, m.start.y if m.type==direction.H else v)

func HandleLiftPieces():
	for x in range(width):
		#lift
		for y in range(1, height):
			if(board[x][y-1] == null && board[x][y] != null && board[x][y] != dummy):
				moveTileBy(board[x][y], 0, -1)
				board[x][y] = null
		#new
		if board[x][height-1] == null:
			createTile(x, height-1, 0)

func sigmoid(x):
	return 1 / (1 + pow(2.71828, -x))

func createTile(x, y, offset = 0):
	var prob = sigmoid(combo/20.0) - .5
	if(prob < 1.0/20):
		prob = 1.0/20
	print(prob)
	if(rng.randf() > prob):
		var newWater = TileScene.instance()
		newWater.setType(rng.randi_range(0,4))
		newWater.position.x = x*gridSize 
		newWater.position.y = (height+offset)*gridSize
		newWater.connect("arrived", self, "onArival")
		add_child(newWater)
		moveTileTo(newWater, x, y)
		return newWater
	else:
		var newFish = TileScene.instance()
		newFish.setType(100)
		newFish.position.x = x*gridSize 
		newFish.position.y = (height+offset)*gridSize
		newFish.connect("arrived", self, "onArival")
		add_child(newFish)
		moveTileTo(newFish, x, y)
		return newFish

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
	

func handleFishClear():
	for y in range(height):
		for x in range(width):
			if y < 3 && board[x][y] != null && board[x][y].type >= 100 && board[x][y].type <= 399:
				chumCount += board[x][y].chumValue
				remove(x, y)

func _input(event):
	if event.is_action_pressed("gemGame_Swap"):
		swapPieceRight(get_local_mouse_position() / gridSize)
	if event.is_action("debug"):
		print("-------------------")
		print(board)
		print(findMatches())
