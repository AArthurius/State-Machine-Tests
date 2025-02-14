extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var jump_buffer_timer: Timer = $"Timers/Jump Buffer timer"
@onready var after_image_timer: Timer = $"Timers/After Image Timer"
@onready var modulate_damage: Timer = $"Timers/Modulate Damage"
@onready var ground_and_walls: TileMapLayer = $"../TileMap/Ground and Walls"

const AFTER_IMAGE = preload("res://Scenes/after_image.tscn")


var health = 100
var dead = false
var direction = 0
var player_state
var jumped = false
var coyote_timer = 0.0
var crouched: bool = false
var sliding: bool = false
var roll: bool = false
var dash: bool = false
var wall_slide:bool = false
var ledge_right = false
var ledge_left = false
var wall_rang_right = false
var wall_rang_left = false

const COYOTE_TIME = 0.1
const MAX_SPEED = 300
const MAX_CROUCH_SPEED = 150
const JUMP_VELOCITY = -400.0
const ACC = 1200 
const SLIDING_DEACC = 400
const CROUCH_ACC = 800
const GRAVITY = 1500
const JUMP_GRAVITY = 1000
const WALL_SLIDE_GRAVITY = 150

func _process(delta: float) -> void:
	ledge()
	if health <= 0:
		dead = true

func ledge():
	var player_coords = ground_and_walls.local_to_map(global_position)
	var top_left_cell = ground_and_walls.get_neighbor_cell(player_coords, 11)
	var top_right_cell = ground_and_walls.get_neighbor_cell(player_coords, 15)
	
	
	if ground_and_walls.get_cell_tile_data(top_left_cell) != null: 
		ledge_left = ground_and_walls.get_cell_tile_data(top_left_cell).get_custom_data("Ledge")
		return top_left_cell
	else:
		ledge_left = false
	if ground_and_walls.get_cell_tile_data(top_right_cell) != null:
		ledge_right = ground_and_walls.get_cell_tile_data(top_right_cell).get_custom_data("Ledge")
		return top_right_cell
	else:
		ledge_right = false

func _apply_movement(delta):
	#coyote time
	if is_on_floor():
		jumped = false
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta
	
	coyote_timer = clamp(coyote_timer, 0, COYOTE_TIME)
	
	#Left and right movement
	
	if !sliding and !roll and !dash:
		if direction != 0:
			if !crouched:
				#Run
				velocity.x = velocity.x + (direction * ACC) * delta
			else:
				#Crouch walk
				velocity.x = velocity.x + (direction * CROUCH_ACC) * delta
	elif dash or roll:
		velocity.x = sign(velocity.x) * 300
	
	#Desaceleration
	if !roll and !dash:
		if direction == 0 and !sliding:
			if velocity.x > 0:
				velocity.x = velocity.x - (ACC * delta)
				velocity.x = clamp(velocity.x, 0, MAX_SPEED)
			else:
				velocity.x = velocity.x + (ACC * delta)
				velocity.x = clamp(velocity.x, -MAX_SPEED, 0)
			
		elif sliding:
			if velocity.x > 0:
				velocity.x = velocity.x - (SLIDING_DEACC * delta)
				velocity.x = clamp(velocity.x, 0, MAX_SPEED)
			else:
				velocity.x = velocity.x + (SLIDING_DEACC * delta)
				velocity.x = clamp(velocity.x, -MAX_SPEED, 0)
	
	
	#Clamp Speed
	if !crouched:
		velocity.x = clamp(velocity.x, -MAX_SPEED, MAX_SPEED)
	else:
		velocity.x = clamp(velocity.x, -MAX_CROUCH_SPEED, MAX_CROUCH_SPEED)
	
	#Jumping
	if (coyote_timer > 0 or is_on_floor()) and jump_buffer_timer.time_left > 0 and !jumped and !roll:
		coyote_timer = 0
		jumped = true
		jump_buffer_timer.stop()
		velocity.y = JUMP_VELOCITY

func _apply_gravity(delta):
	#Gravity
	if !is_on_floor():
		if velocity.y < 0:
			velocity.y += JUMP_GRAVITY * delta
		else:
			velocity.y += GRAVITY * delta
		
		if wall_slide:
			velocity.y = clamp(velocity.y, WALL_SLIDE_GRAVITY, WALL_SLIDE_GRAVITY)
	
	
	velocity.y = clamp(velocity.y, JUMP_VELOCITY, MAX_SPEED)
	
	move_and_slide()

func _on_after_image_timer_timeout() -> void:
	if dash:
		var after_image: Sprite2D = AFTER_IMAGE.instantiate()
		after_image.position = position
		after_image.offset = sprite.offset
		after_image.flip_h = sprite.flip_h
		after_image.set_texture(sprite.get_sprite_frames().get_frame_texture(sprite.animation, sprite.get_frame()))
		$"..".add_child(after_image)

func take_damage(amount):
	if health > 0:
		modulate_damage.start()
		sprite.modulate = Color.RED
	health = health - amount

func _on_modulate_damage_timeout() -> void:
	sprite.modulate = Color(1, 1, 1, 1)
