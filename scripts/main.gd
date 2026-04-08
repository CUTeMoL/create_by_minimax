extends Node2D

const GRID_SIZE = 20
const COLS = 24
const ROWS = 24
const MOVE_INTERVAL = 0.15

var snake: Array[Vector2i] = []
var direction: Vector2i = Vector2i(1, 0)
var next_direction: Vector2i = Vector2i(1, 0)
var food_pos: Vector2i = Vector2i(15, 10)
var score: int = 0
var paused: bool = false
var game_over: bool = false
var move_timer: float = 0.0

var snake_segments: Array[ColorRect] = []
var food_rect: ColorRect
var grid_container: Node

@onready var score_label: Label = $ScoreLabel
@onready var message_label: Label = $MessageLabel

func _ready() -> void:
	randomize()
	init_game()
	setup_grid()
	spawn_food()
	update_score_label()
	message_label.text = ""

func setup_grid() -> void:
	grid_container = Node.new()
	grid_container.name = "GridContainer"
	add_child(grid_container)

	var offset_x = (480 - COLS * GRID_SIZE) / 2.0
	var offset_y = (480 - ROWS * GRID_SIZE) / 2.0 + 50

	for x in range(COLS + 1):
		var line = ColorRect.new()
		line.size = Vector2(1, ROWS * GRID_SIZE)
		line.position = Vector2(offset_x + x * GRID_SIZE, offset_y)
		line.color = Color(0x1f, 0x2f, 0x50, 0.5)
		grid_container.add_child(line)

	for y in range(ROWS + 1):
		var line = ColorRect.new()
		line.size = Vector2(COLS * GRID_SIZE, 1)
		line.position = Vector2(offset_x, offset_y + y * GRID_SIZE)
		line.color = Color(0x1f, 0x2f, 0x50, 0.5)
		grid_container.add_child(line)

func get_grid_offset() -> Vector2:
	var offset_x = (480 - COLS * GRID_SIZE) / 2.0
	var offset_y = (480 - ROWS * GRID_SIZE) / 2.0 + 50
	return Vector2(offset_x, offset_y)

func init_game() -> void:
	for seg in snake_segments:
		if is_instance_valid(seg):
			seg.queue_free()
	snake_segments.clear()

	snake.clear()
	snake.append(Vector2i(10, 10))
	direction = Vector2i(1, 0)
	next_direction = Vector2i(1, 0)
	score = 0
	paused = false
	game_over = false
	move_timer = 0.0

	add_snake_segment(Vector2i(10, 10))

func add_snake_segment(pos: Vector2i) -> void:
	var seg = ColorRect.new()
	seg.size = Vector2(GRID_SIZE - 2, GRID_SIZE - 2)
	var offset = get_grid_offset()
	seg.position = Vector2(offset.x + pos.x * GRID_SIZE + 1, offset.y + pos.y * GRID_SIZE + 1)
	seg.color = Color(0x00, 0xff, 0x00)
	add_child(seg)
	snake_segments.append(seg)
	update_snake_color()

func update_snake_color() -> void:
	for i in range(snake_segments.size()):
		if is_instance_valid(snake_segments[i]):
			snake_segments[i].color = Color(0x00, 0xff, 0x00)

func update_snake_positions() -> void:
	var offset = get_grid_offset()
	for i in range(snake.size()):
		var pos = snake[i]
		if i < snake_segments.size() and is_instance_valid(snake_segments[i]):
			snake_segments[i].position = Vector2(
				offset.x + pos.x * GRID_SIZE + 1,
				offset.y + pos.y * GRID_SIZE + 1
			)

func spawn_food() -> void:
	if is_instance_valid(food_rect):
		food_rect.queue_free()

	var valid_positions: Array[Vector2i] = []
	for x in range(COLS):
		for y in range(ROWS):
			var pos = Vector2i(x, y)
			if not snake.has(pos):
				valid_positions.append(pos)

	if valid_positions.size() > 0:
		food_pos = valid_positions[randi() % valid_positions.size()]
		food_rect = ColorRect.new()
		food_rect.size = Vector2(GRID_SIZE - 2, GRID_SIZE - 2)
		var offset = get_grid_offset()
		food_rect.position = Vector2(
			offset.x + food_pos.x * GRID_SIZE + 1,
			offset.y + food_pos.y * GRID_SIZE + 1
		)
		food_rect.color = Color(0xe9, 0x45, 0x60)
		add_child(food_rect)

func _process(delta: float) -> void:
	if game_over:
		if Input.is_action_just_pressed("ui_accept"):
			init_game()
			spawn_food()
		return

	handle_input()

	if not paused:
		move_timer += delta
		if move_timer >= MOVE_INTERVAL:
			move_timer -= MOVE_INTERVAL
			update_game()

func handle_input() -> void:
	var new_dir = next_direction

	if Input.is_action_just_pressed("ui_up") and direction.y != 1:
		new_dir = Vector2i(0, -1)
	elif Input.is_action_just_pressed("ui_down") and direction.y != -1:
		new_dir = Vector2i(0, 1)
	elif Input.is_action_just_pressed("ui_left") and direction.x != 1:
		new_dir = Vector2i(-1, 0)
	elif Input.is_action_just_pressed("ui_right") and direction.x != -1:
		new_dir = Vector2i(1, 0)
	elif Input.is_action_just_pressed("ui_cancel"):
		paused = !paused
		if paused:
			message_label.text = "已暂停\n按 ESC 继续"
		else:
			message_label.text = ""

	next_direction = new_dir

func update_game() -> void:
	direction = next_direction
	var head = snake[0] + direction

	if head.x < 0 or head.x >= COLS or head.y < 0 or head.y >= ROWS:
		trigger_game_over()
		return

	if snake.has(head):
		trigger_game_over()
		return

	snake.insert(0, head)

	if head == food_pos:
		score += 10
		update_score_label()
		add_snake_segment(head)
		spawn_food()
	else:
		snake.pop_back()

	update_snake_positions()
	update_snake_color()

func trigger_game_over() -> void:
	game_over = true
	message_label.text = "游戏结束!\n按 Enter 重新开始"

func update_score_label() -> void:
	score_label.text = "得分: %d" % score
