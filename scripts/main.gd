extends Node2D

# ==================== 游戏配置 ====================
const GRID_SIZE: int = 20
const COLS: int = 24
const ROWS: int = 24
const BASE_MOVE_INTERVAL: float = 0.15
const MIN_MOVE_INTERVAL: float = 0.05
const SPEED_STEP: int = 5
const SPEED_DECREMENT: float = 0.01

# ==================== 游戏状态变量 ====================
var snake: Array[Vector2i] = []
var direction: Vector2i = Vector2i(1, 0)
var next_direction: Vector2i = Vector2i(1, 0)
var food_pos: Vector2i = Vector2i(15, 10)
var score: int = 0
var high_score: int = 0
var paused: bool = false
var game_over: bool = false
var move_timer: float = 0.0
var move_interval: float = BASE_MOVE_INTERVAL

# ==================== UI 节点引用 ====================
var snake_segments: Array[ColorRect] = []
var food_rect: ColorRect
var grid_container: Node

# 暂停菜单节点
var pause_overlay: ColorRect
var pause_panel: VBoxContainer
var continue_btn: Button
var restart_btn: Button
var pause_high_score_label: Label

@onready var score_label: Label = $ScoreLabel
@onready var message_label: Label = $MessageLabel
@onready var high_score_label: Label = $HighScoreLabel

# ==================== 音效播放 ====================
var eat_player: AudioStreamPlayer
var gameover_player: AudioStreamPlayer
var newrecord_player: AudioStreamPlayer

func _ready() -> void:
	randomize()
	load_high_score()
	init_game()
	setup_grid()
	setup_pause_menu()
	spawn_food()
	update_ui()
	high_score_label.text = "最高分: %d" % high_score
	message_label.text = ""

	# 加载音效文件
	setup_audio()

func setup_audio() -> void:
	# 创建播放器
	eat_player = AudioStreamPlayer.new()
	gameover_player = AudioStreamPlayer.new()
	newrecord_player = AudioStreamPlayer.new()
	add_child(eat_player)
	add_child(gameover_player)
	add_child(newrecord_player)

	# 加载WAV文件
	# 使用项目目录下的 user_sounds 文件夹
		# 使用 FileAccess 加载 WAV 原始数据
	var eat_file = FileAccess.open("sounds/eat.wav", FileAccess.READ)
	var gameover_file = FileAccess.open("sounds/gameover.wav", FileAccess.READ)
	var newrecord_file = FileAccess.open("sounds/newrecord.wav", FileAccess.READ)

	if eat_file:
		var eat_data = eat_file.get_buffer(eat_file.get_length())
		var eat_stream = AudioStreamWAV.new()
		eat_stream.data = eat_data
		eat_stream.mix_rate = 44100
		eat_player.stream = eat_stream
		eat_file.close()
	if gameover_file:
		var gameover_data = gameover_file.get_buffer(gameover_file.get_length())
		var gameover_stream = AudioStreamWAV.new()
		gameover_stream.data = gameover_data
		gameover_stream.mix_rate = 44100
		gameover_player.stream = gameover_stream
		gameover_file.close()
	if newrecord_file:
		var newrecord_data = newrecord_file.get_buffer(newrecord_file.get_length())
		var newrecord_stream = AudioStreamWAV.new()
		newrecord_stream.data = newrecord_data
		newrecord_stream.mix_rate = 44100
		newrecord_player.stream = newrecord_stream
		newrecord_file.close()

# 播放吃食物音效
func play_eat_sound() -> void:
	if eat_player and eat_player.stream:
		eat_player.play()

# 播放游戏结束音效
func play_gameover_sound() -> void:
	if gameover_player and gameover_player.stream:
		gameover_player.play()

# 播放新纪录音效
func play_newrecord_sound() -> void:
	if newrecord_player and newrecord_player.stream:
		newrecord_player.play()

# 从文件加载最高分
func load_high_score() -> void:
	var save_file = ConfigFile.new()
	var err = save_file.load("user://snake_highscore.save")
	if err == OK:
		high_score = save_file.get_value("snake", "high_score", 0)
	else:
		high_score = 0

# 保存最高分到文件
func save_high_score() -> void:
	var save_file = ConfigFile.new()
	save_file.set_value("snake", "high_score", high_score)
	save_file.save("user://snake_highscore.save")

# ==================== 暂停菜单 ====================

# 创建暂停菜单UI
func setup_pause_menu() -> void:
	# 半透明黑色遮罩
	pause_overlay = ColorRect.new()
	pause_overlay.color = Color(0, 0, 0, 0.7)
	pause_overlay.set_size(Vector2(480, 520))
	pause_overlay.position = Vector2(0, 0)
	pause_overlay.visible = false
	add_child(pause_overlay)

	# 暂停面板容器
	pause_panel = VBoxContainer.new()
	pause_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	pause_panel.set_size(Vector2(200, 150))
	pause_panel.position = Vector2(140, 180)
	pause_overlay.add_child(pause_panel)

	# 标题
	var title = Label.new()
	title.text = "游戏暂停"
	title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	pause_panel.add_child(title)

	# 最高分标签
	pause_high_score_label = Label.new()
	pause_high_score_label.text = "最高分: %d" % high_score
	pause_high_score_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	pause_high_score_label.add_theme_font_size_override("font_size", 18)
	pause_panel.add_child(pause_high_score_label)

	# 间距
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 20
	pause_panel.add_child(spacer)

	# 继续按钮
	continue_btn = Button.new()
	continue_btn.text = "继续"
	continue_btn.custom_minimum_size = Vector2(150, 40)
	continue_btn.pressed.connect(_on_continue_pressed)
	pause_panel.add_child(continue_btn)

	# 重新开始按钮
	restart_btn = Button.new()
	restart_btn.text = "重新开始"
	restart_btn.custom_minimum_size = Vector2(150, 40)
	restart_btn.pressed.connect(_on_restart_pressed)
	pause_panel.add_child(restart_btn)

# 继续按钮回调
func _on_continue_pressed() -> void:
	paused = false
	pause_overlay.visible = false
	message_label.text = ""

# 重新开始按钮回调
func _on_restart_pressed() -> void:
	pause_overlay.visible = false
	init_game()
	spawn_food()
	update_ui()

# 显示暂停菜单
func show_pause_menu() -> void:
	paused = true
	pause_high_score_label.text = "最高分: %d" % high_score
	pause_overlay.visible = true
	message_label.text = "按 ESC 继续"

# ==================== 游戏逻辑 ====================

# 初始化游戏
func init_game() -> void:
	# 清理旧蛇身节点
	for seg in snake_segments:
		if is_instance_valid(seg):
			seg.queue_free()
	snake_segments.clear()

	# 重置蛇
	snake.clear()
	snake.append(Vector2i(10, 10))
	direction = Vector2i(1, 0)
	next_direction = Vector2i(1, 0)
	score = 0
	paused = false
	game_over = false
	move_timer = 0.0
	move_interval = BASE_MOVE_INTERVAL

	# 创建初始蛇身节点
	add_snake_segment(Vector2i(10, 10))

# 添加一个蛇身段
func add_snake_segment(pos: Vector2i) -> void:
	var seg = ColorRect.new()
	seg.size = Vector2(GRID_SIZE - 2, GRID_SIZE - 2)
	var offset = get_grid_offset()
	seg.position = Vector2(offset.x + pos.x * GRID_SIZE + 1, offset.y + pos.y * GRID_SIZE + 1)
	add_child(seg)
	snake_segments.append(seg)
	update_snake_color()

# 更新蛇身颜色（蛇头亮绿，蛇身深绿）
func update_snake_color() -> void:
	for i in range(snake_segments.size()):
		if is_instance_valid(snake_segments[i]):
			if i == 0:
				# 蛇头：亮绿色 #4ecca3
				snake_segments[i].color = Color("4ecca3")
			else:
				# 蛇身：深绿色 #3aa882
				snake_segments[i].color = Color("3aa882")

# 更新所有蛇身节点的位置
func update_snake_positions() -> void:
	var offset = get_grid_offset()
	for i in range(snake.size()):
		var pos = snake[i]
		if i < snake_segments.size() and is_instance_valid(snake_segments[i]):
			snake_segments[i].position = Vector2(
				offset.x + pos.x * GRID_SIZE + 1,
				offset.y + pos.y * GRID_SIZE + 1
			)

# 生成新食物（确保不在蛇身上）
func spawn_food() -> void:
	if is_instance_valid(food_rect):
		food_rect.queue_free()

	# 收集所有可用的空位置
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

# 创建网格背景
func setup_grid() -> void:
	grid_container = Node.new()
	grid_container.name = "GridContainer"
	add_child(grid_container)

	var offset_x = (480 - COLS * GRID_SIZE) / 2.0
	var offset_y = (480 - ROWS * GRID_SIZE) / 2.0 + 50

	# 垂直线
	for x in range(COLS + 1):
		var line = ColorRect.new()
		line.size = Vector2(1, ROWS * GRID_SIZE)
		line.position = Vector2(offset_x + x * GRID_SIZE, offset_y)
		line.color = Color(0x1f, 0x2f, 0x50, 0.5)
		grid_container.add_child(line)

	# 水平线
	for y in range(ROWS + 1):
		var line = ColorRect.new()
		line.size = Vector2(COLS * GRID_SIZE, 1)
		line.position = Vector2(offset_x, offset_y + y * GRID_SIZE)
		line.color = Color(0x1f, 0x2f, 0x50, 0.5)
		grid_container.add_child(line)

# 获取网格偏移量
func get_grid_offset() -> Vector2:
	var offset_x = (480 - COLS * GRID_SIZE) / 2.0
	var offset_y = (480 - ROWS * GRID_SIZE) / 2.0 + 50
	return Vector2(offset_x, offset_y)

# 更新 UI 显示
func update_ui() -> void:
	score_label.text = "得分: %d" % score
	high_score_label.text = "最高分: %d" % high_score

# ==================== 游戏主循环 ====================

func _process(delta: float) -> void:
	# 游戏结束时按 Enter 重新开始
	if game_over:
		if Input.is_action_just_pressed("ui_accept"):
			init_game()
			spawn_food()
		return

	handle_input()

	if not paused:
		move_timer += delta
		if move_timer >= move_interval:
			move_timer -= move_interval
			update_game()

# 处理键盘输入
func handle_input() -> void:
	var new_dir = next_direction

	# 方向键控制
	if Input.is_action_just_pressed("ui_up") and direction.y != 1:
		new_dir = Vector2i(0, -1)
	elif Input.is_action_just_pressed("ui_down") and direction.y != -1:
		new_dir = Vector2i(0, 1)
	elif Input.is_action_just_pressed("ui_left") and direction.x != 1:
		new_dir = Vector2i(-1, 0)
	elif Input.is_action_just_pressed("ui_right") and direction.x != -1:
		new_dir = Vector2i(1, 0)
	# ESC 暂停
	elif Input.is_action_just_pressed("ui_cancel"):
		show_pause_menu()

	next_direction = new_dir

# 更新游戏逻辑
func update_game() -> void:
	direction = next_direction
	var head = snake[0] + direction

	# 撞墙检测
	if head.x < 0 or head.x >= COLS or head.y < 0 or head.y >= ROWS:
		trigger_game_over()
		return

	# 撞自己检测
	if snake.has(head):
		trigger_game_over()
		return

	# 添加新蛇头
	snake.insert(0, head)

	# 吃食物检测
	if head == food_pos:
		score += 10
		update_ui()
		add_snake_segment(head)
		spawn_food()
		play_eat_sound()
		# 难度递增：每5个食物加速
		if score % (SPEED_STEP * 10) == 0 and move_interval > MIN_MOVE_INTERVAL:
			move_interval -= SPEED_DECREMENT
			move_interval = max(move_interval, MIN_MOVE_INTERVAL)
	else:
		# 没吃到食物，移除蛇尾
		snake.pop_back()

	update_snake_positions()
	update_snake_color()

# 游戏结束处理
func trigger_game_over() -> void:
	game_over = true
	play_gameover_sound()
	message_label.text = "游戏结束!\n按 Enter 重新开始"

	# 检查并更新最高分
	if score > high_score:
		high_score = score
		save_high_score()
		update_ui()
		play_newrecord_sound()
		message_label.text = "新纪录!\n按 Enter 重新开始"
