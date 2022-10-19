extends Node

const SNAKE = 0
const APPLE = 1

var apple_pos

const SNAKE_START = [Vector2(5,10),Vector2(4,10),Vector2(3,10)]

const DIR_UP = Vector2(0, -1)
const DIR_DOWN = Vector2(0, 1)
const DIR_LEFT = Vector2(-1, 0)
const DIR_RIGHT = Vector2(1, 0)

const MAX_CELL = 20

const BLOCK_BODY = Vector2(8, 0)
const BLOCK_HEAD_RIGHT = Vector2(2, 0)
const BLOCK_HEAD_LEFT = Vector2(3, 1)
const BLOCK_HEAD_DOWN = Vector2(3, 0)
const BLOCK_HEAD_UP = Vector2(2, 1)
const BLOCK_TAIL_RIGHT = Vector2(1, 0)
const BLOCK_TAIL_LEFT = Vector2(0, 0)
const BLOCK_TAIL_DOWN = Vector2(1, 1)
const BLOCK_TAIL_UP = Vector2(0, 1)
const BLOCK_BODY_H = Vector2(4, 0)
const BLOCK_BODY_V = Vector2(4, 1)
const BLOCK_BODY_UL = Vector2(5, 0)
const BLOCK_BODY_UR = Vector2(6, 0)
const BLOCK_BODY_DL = Vector2(5, 1)
const BLOCK_BODY_DR = Vector2(6, 1)

var snake_body = SNAKE_START
var snake_direction = DIR_RIGHT
var add_apple = false

func _ready():
	apple_pos = place_apple()

func place_apple():
	randomize()
	var x = randi() % MAX_CELL
	var y = randi() % MAX_CELL
	return Vector2(x, y)

func draw_apple():
	$SnakeApple.set_cell(apple_pos.x, apple_pos.y, APPLE)

func draw_snake():
#	for block in snake_body:
#		$SnakeApple.set_cell(block.x, block.y, SNAKE, false, false, false, BLOCK_BODY)
	for block_index in snake_body.size():
		var block_piece = BLOCK_BODY

		var block = snake_body[block_index]
		
		if block_index == 0:
			# Head
			var direction = relation2(snake_body[0], snake_body[1])
			
			if direction == DIR_RIGHT:
				block_piece = BLOCK_HEAD_LEFT
			if direction == DIR_LEFT:
				block_piece = BLOCK_HEAD_RIGHT
			if direction == DIR_UP:
				block_piece = BLOCK_HEAD_DOWN
			if direction == DIR_DOWN:
				block_piece = BLOCK_HEAD_UP

		elif block_index == snake_body.size() - 1:
			# Tail
			var direction = relation2(snake_body[-1], snake_body[-2])
			
			if direction == DIR_RIGHT:
				block_piece = BLOCK_TAIL_LEFT
			if direction == DIR_LEFT:
				block_piece = BLOCK_TAIL_RIGHT
			if direction == DIR_UP:
				block_piece = BLOCK_TAIL_DOWN
			if direction == DIR_DOWN:
				block_piece = BLOCK_TAIL_UP
		
		else:
			var previous_direction = relation2(snake_body[block_index + 1], block)
			var next_direction = relation2(snake_body[block_index - 1], block)			
			
			if previous_direction.x == next_direction.x:
				block_piece = BLOCK_BODY_V
			elif previous_direction.y == next_direction.y:
				block_piece = BLOCK_BODY_H
			else:
				if check_direction(previous_direction, next_direction, -1, -1):
					block_piece = BLOCK_BODY_UL
				if check_direction(previous_direction, next_direction, 1, 1):
					block_piece = BLOCK_BODY_DR
				if check_direction(previous_direction, next_direction, -1, 1):
					block_piece = BLOCK_BODY_DL
				if check_direction(previous_direction, next_direction, 1, -1):
					block_piece = BLOCK_BODY_UR
					
		$SnakeApple.set_cell(block.x, block.y, SNAKE, false, false, false, block_piece)

func check_direction(prev: Vector2, next: Vector2, val1: int, val2: int):
	return prev.x == val1 and next.y == val2 or prev.y == val2 and next.x == val1

func relation2(first_block: Vector2, second_block: Vector2):
	return second_block - first_block
	
func move_snake():
	var chop = 2
	
	if add_apple:
		chop = 1

	delete_tiles(SNAKE)
	# Get copy minus the last item
	var body_copy = snake_body.slice(0, snake_body.size() - chop)

	var new_head = body_copy[0] + snake_direction
	
	body_copy.insert(0, new_head)
	
	snake_body = body_copy
	
	add_apple = false

func delete_tiles(id:int):
	var cells = $SnakeApple.get_used_cells_by_id(id)
	for cell in cells:
		$SnakeApple.set_cell(cell.x, cell.y, -1)

func _input(event):
	if Input.is_action_just_pressed("ui_up"):
		if not snake_direction == DIR_DOWN:
			snake_direction = DIR_UP
	if Input.is_action_just_pressed("ui_right"):
		if not snake_direction == DIR_LEFT:
			snake_direction = DIR_RIGHT
	if Input.is_action_just_pressed("ui_left"):
		if not snake_direction == DIR_RIGHT:
			snake_direction = DIR_LEFT
	if Input.is_action_just_pressed("ui_down"):
		if not snake_direction == DIR_UP:
			snake_direction = DIR_DOWN

func check_apple_eaten():
	if apple_pos == snake_body[0]:
		apple_pos = place_apple()
		add_apple = true
		set_score(snake_body.size() - (SNAKE_START.size() - 1))
		$CrunchSound.play()

func check_game_over():
	var head = snake_body[0]
	
	# snake leaves screen
	if head.x >= MAX_CELL or head.x < 0 or head.y >= MAX_CELL or head.y < 0:
		reset()
	
	# snake bites tail
	for block in snake_body.slice(1, snake_body.size() - 1):
		if block == head:
			reset()

func reset():
	snake_body = SNAKE_START
	snake_direction = DIR_RIGHT
	set_score(0)

func set_score(score: int):
	get_tree().call_group('score_group', 'update_score', score)

func _on_SnakeTick_timeout():
	move_snake()
	draw_apple()
	draw_snake()
	check_apple_eaten()
	
func _process(delta):
	check_game_over()
	if apple_pos in snake_body:
		apple_pos = place_apple()
