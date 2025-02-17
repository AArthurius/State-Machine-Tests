extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var jump_buffer_timer: Timer = $"Timers/Jump Buffer timer"
@onready var after_image_timer: Timer = $"Timers/After Image Timer"
@onready var modulate_damage: Timer = $"Timers/Modulate Damage"
@onready var ground_and_walls: TileMapLayer = $"../TileMap/Ground and Walls"
@onready var standing_shape: CollisionShape2D = $"Standing Shape"
@onready var crouch_shape: CollisionShape2D = $"Crouch Shape"



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
var is_attacking = false

const JUMP_DEACC = 300
const ATTACK_DEACC = 2000
const COYOTE_TIME = 0.1
const MAX_SPEED = 300
const MAX_CROUCH_SPEED = 150
const MAX_ABSOLUTE_SPEED = 600 #True max speed, can't achieve by moving normally
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
	if !sliding and !roll and !dash and !is_attacking:
		if direction != 0:
			if !crouched and (abs(velocity.x) < MAX_SPEED or sign(direction) != sign(velocity.x)):
				#Run
				velocity.x = move_toward(velocity.x, direction *  MAX_SPEED, ACC * delta)
			elif (abs(velocity.x) < MAX_SPEED or sign(direction) != sign(velocity.x)):
				#Crouch walk
				velocity.x = move_toward(velocity.x, direction *  MAX_CROUCH_SPEED, ACC * delta)
	elif dash or roll:
		velocity.x = sign(velocity.x) * MAX_SPEED
	
	#Desaceleration
	if !roll and !dash:
		if (abs(velocity.x) > MAX_SPEED or direction == 0) and !sliding and !is_attacking and is_on_floor():
			if velocity.x > 0:
				velocity.x = velocity.x - (ACC * delta)
				velocity.x = clamp(velocity.x, 0, MAX_ABSOLUTE_SPEED)
			else:
				velocity.x = velocity.x + (ACC * delta)
				velocity.x = clamp(velocity.x, -MAX_ABSOLUTE_SPEED, 0)
		elif !is_on_floor():
			if velocity.x > 0:
				velocity.x = velocity.x - (JUMP_DEACC * delta)
				velocity.x = clamp(velocity.x, 0, MAX_ABSOLUTE_SPEED)
			else:
				velocity.x = velocity.x + (JUMP_DEACC * delta)
				velocity.x = clamp(velocity.x, -MAX_ABSOLUTE_SPEED, 0)
		elif sliding or !is_on_floor():
			if velocity.x > 0:
				velocity.x = velocity.x - (SLIDING_DEACC * delta)
				velocity.x = clamp(velocity.x, 0, MAX_ABSOLUTE_SPEED)
			else:
				velocity.x = velocity.x + (SLIDING_DEACC * delta)
				velocity.x = clamp(velocity.x, -MAX_ABSOLUTE_SPEED, 0)
		elif is_attacking:
			if velocity.x > 0:
				velocity.x = velocity.x - (ATTACK_DEACC * delta)
				velocity.x = clamp(velocity.x, 0, MAX_ABSOLUTE_SPEED)
			else:
				velocity.x = velocity.x + (ATTACK_DEACC * delta)
				velocity.x = clamp(velocity.x, -MAX_ABSOLUTE_SPEED, 0)
	
	#Clamp velocity
	velocity.x = clamp(velocity.x, -MAX_ABSOLUTE_SPEED, MAX_ABSOLUTE_SPEED)
	
	#Jumping
	if jump_buffer_timer.time_left > 0 and !jumped and !roll and !is_attacking:
		coyote_timer = 0
		jumped = true
		jump_buffer_timer.stop()
		if is_on_floor() or  coyote_timer > 0:
			velocity.y += JUMP_VELOCITY
		elif is_on_wall() and direction == 1:
			velocity.y = JUMP_VELOCITY
			velocity.x = -MAX_SPEED
		elif is_on_wall() and direction == -1:
			velocity.y = JUMP_VELOCITY
			velocity.x = MAX_SPEED

func _apply_gravity(delta):
	#Gravity
	if !is_on_floor():
		if velocity.y < 0:
			velocity.y += JUMP_GRAVITY * delta
		else:
			velocity.y += GRAVITY * delta
		
		if wall_slide:
			velocity.y = clamp(velocity.y, 0, WALL_SLIDE_GRAVITY)
	
	
	velocity.y = clamp(velocity.y, JUMP_VELOCITY, -JUMP_VELOCITY)
	
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

func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	body.take_damage(10)
	print(body)

func on_crouch():
	standing_shape.disabled = true
	crouch_shape.disabled = false

func on_stand():
	standing_shape.disabled = false
	crouch_shape.disabled = true

func can_stand() -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	query.set_shape(standing_shape.shape)
	query.transform = standing_shape.global_transform
	query.collision_mask = collision_mask
	var results = space_state.intersect_shape(query)
	for i in range(results.size() - 1, -1, -1):
		var collider = results[i].collider
		var shape = results[i].shape
		if collider is CollisionObject2D && collider.is_shape_owner_one_way_collision_enabled(shape):
			results.remove[i]
		elif collider is TileMapLayer:
			var tile_id = collider.get_cellv(results[i].metadata)
			if collider.tile_set.tile_get_shape_one_way(tile_id, 0):
				results.remove(i)
	return results.size() == 0
