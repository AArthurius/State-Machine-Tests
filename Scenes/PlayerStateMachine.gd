extends "res://Scenes/stateMachine.gd"

@onready var label: Label = $"../Label"
@onready var jump_buffer_timer: Timer = $"../Timers/Jump Buffer timer"
@onready var sprite: AnimatedSprite2D = $"../Sprite"
@onready var dash_cd: Timer = $"../Timers/Dash CD"
@onready var attack_hitbox: Area2D = $"../AttackHitbox"
@onready var crouch_attack_hitbox: Area2D = $"../Crouch Attack Hitbox"


var dash_in_cooldown: = false
var dash_timer = 0.0

const DASH_TIME = 0.5

func _process(delta: float) -> void:
	label.text = str(parent.velocity)
	#label.text = #str_Current_State() #Current player state
	#label.text = str(jump_buffer_timer.time_left)

func str_Current_State():
	match state:
		0:
			return "ATTACK"
		1:
			return "ATTACK 2"
		2:
			return "CROUCH ATTACK"
		3:
			return "CROUCH IDLE"
		4:
			return "CROUCH TRANSITION"
		5:
			return "CROUCH WALK"
		6:
			return "DASH"
		7:
			return "DEATH"
		8:
			return "FALL TRANSITION"
		9:
			return "FALLING"
		10:
			return "HIT"
		11:
			return "IDLE"
		12:
			return "JUMP"
		13:
			return "ROLL"
		14:
			return "RUN"
		15:
			return "SLIDE"
		16:
			return "SLIDE TRANSITION"
		17:
			return "TURN AROUND"
		18:
			return "WALL CLIMBING"
		19:
			return "WALL RANG"
		20:
			return "WALL SLIDE"

func _ready():
	add_state("attack") 
	add_state("attack_2")
	add_state("crouch_attack")
	add_state("crouch_idle")
	add_state("crouch_transition")
	add_state("crouch_walk")
	add_state("dash")
	add_state("death")
	add_state("fall_transition")
	add_state("falling")
	add_state("hit") 
	add_state("idle") 
	add_state("jump")
	add_state("roll")
	add_state("run")
	add_state("slide")
	add_state("slide_transition")
	add_state("turn_around")
	add_state("wall_climb")
	add_state("wall_rang")
	add_state("wall_slide") 
	call_deferred("set_state", states.idle)

func _input(event):
	#Move sideways
	parent.direction = Input.get_axis("A", "D")
	#Jump
	if Input.is_action_pressed("W"):
		jump_buffer_timer.start()

func _state_logic(delta):
	if parent.dead == true:
		return
	#flip sprite to match
	if state != states.wall_slide:
		if parent.velocity.x < 0:
			sprite.flip_h = true
			sprite.offset.x = -3
			attack_hitbox.position.x = -33
			crouch_attack_hitbox.position.x = -29
		elif parent.velocity.x > 0:
			sprite.flip_h = false
			sprite.offset.x = 4
			attack_hitbox.position.x = 33
			crouch_attack_hitbox.position.x = 29
	else:
		if parent.velocity.x < 0:
			sprite.flip_h = false
			sprite.offset.x = 4
		elif parent.velocity.x > 0:
			sprite.flip_h = true
			sprite.offset.x = -3
	
	parent._apply_gravity(delta)
	parent._apply_movement(delta)

func _get_transition(delta):
	if (parent.dead or parent.health < 0) and state != states.death:
		return states.death
	match state:
		#Idle
		states.idle:
			parent.crouched = false
			if !parent.is_on_floor():
				if parent.velocity.y < 0:
					return states.jump
				elif parent.velocity.y >= 0:
					return states.falling
			elif parent.velocity.x != 0:
				return states.run
			elif Input.is_action_pressed("S"):
				return states.crouch_transition
			elif Input.is_action_pressed("M1"):
				return states.attack
		#Crouch Transition
		states.crouch_transition:
			parent.crouched = !parent.crouched
			if Input.is_action_pressed("S") and parent.sprite.get_frame() == 1:
				return states.crouch_idle
			elif parent.sprite.get_frame() == 1:
				return states.idle
			if !parent.is_on_floor():
				if parent.velocity.y < 0:
					return states.jump
				elif parent.velocity.y >= 0:
					return states.falling
			elif parent.velocity.x != 0:
				return states.run
		#Crouch Idle
		states.crouch_idle:
			parent.crouched = true
			if !Input.is_action_pressed("S") and parent.can_stand():
				return states.crouch_transition
			elif !parent.is_on_floor():
				if parent.velocity.y < 0:
					return states.jump
				elif parent.velocity.y >= 0:
					return states.falling
			elif parent.velocity.x != 0:
				return states.crouch_walk
			elif Input.is_action_pressed("M1"):
				return states.crouch_attack
		#Crouch walk
		states.crouch_walk:
			parent.crouched = true
			if !parent.is_on_floor():
				if parent.velocity.y < 0:
					return states.jump
				elif parent.velocity.y >= 0:
					return states.falling
			elif !Input.is_action_pressed("S"):
				parent.crouched = false
				return states.run
			elif parent.velocity.x == 0 and parent.direction == 0:
				return states.crouch_idle
			elif Input.is_action_pressed("M1"):
				return states.crouch_attack
		#Run
		states.run:
			parent.crouched = false
			if !parent.is_on_floor():
				if parent.velocity.y < 0:
					return states.jump
				elif parent.velocity.y >= 0:
					return states.falling 
			elif sign(parent.direction) != sign(parent.velocity.x) and abs(parent.velocity.x) > 100 and parent.direction != 0:
				return states.turn_around
			elif Input.is_action_pressed("M1"):
				return states.attack
			elif parent.velocity.x == 0 and parent.direction == 0:
				return states.idle
			elif Input.is_action_pressed("Alt") and !dash_in_cooldown:
				dash_timer = DASH_TIME
				return states.dash
			elif (parent.velocity.x > 200 or parent.velocity.x < -200) and Input.is_action_pressed("S"):
				return states.slide
			elif Input.is_action_pressed("Space") and parent.is_on_floor():
				return states.roll
		#Slide
		states.slide:
			parent.sliding = true
			if !parent.is_on_floor():
				parent.sliding = false
				if parent.velocity.y < 0:
					parent.velocity.x += sign(parent.velocity.x) * 200 #Jumps after a slide speed you up
					return states.jump
				elif parent.velocity.y >= 0:
					return states.falling 
			elif parent.velocity.x == 0:
				parent.sliding = false
				if Input.is_action_pressed("S"):
					return states.crouch_idle
				else:
					return states.slide_transition
		#Slide Transition
		states.slide_transition:
			parent.sliding = false
			if !parent.is_on_floor():
				if parent.velocity.y < 0:
					return states.jump
				elif parent.velocity.y >= 0:
					return states.falling 
			elif parent.sprite.get_frame() == 1:
				return states.idle
		#Turn Around
		states.turn_around:
			if !parent.is_on_floor():
				if parent.velocity.y < 0:
					return states.jump
				elif parent.velocity.y >= 0:
					return states.falling 
			if sign(parent.direction) == sign(parent.velocity.x):
				return states.idle
			elif parent.velocity.x == 0:
				return states.idle
			elif Input.is_action_pressed("M1"):
				return states.attack
		#Jump
		states.jump:
			parent.crouched = false
			parent.sliding = false
			if parent.is_on_floor():
				return states.idle
			elif parent.velocity.y >= 0:
				return states.fall_transition
		#Fall Transition
		states.fall_transition:
			if parent.is_on_floor():
				return states.idle
			elif parent.sprite.get_frame() == 1:
				return states.falling
		#Falling
		states.falling:
			parent.crouched = false
			if parent.is_on_floor():
				return states.idle
			elif parent.velocity.y < 0:
				return states.jump
			elif !parent.is_on_floor() and parent.is_on_wall() and parent.direction:
				return states.wall_slide
		#Roll
		states.roll:
			parent.roll = true
			if !parent.is_on_floor() and parent.velocity.y < 0:
				parent.roll = false
				return states.jump
			if sprite.get_frame() == 11:
				parent.roll = false
				return states.idle
		#Dash
		states.dash:
			dash_timer -= delta
			parent.dash = true
			if !parent.is_on_floor() and parent.velocity.y < 0:
				parent.dash = false
				return states.jump
			elif dash_timer < 0:
				parent.dash = false
				dash_in_cooldown = true
				dash_cd.start()
				return states.idle
		#Wall Slide
		states.wall_slide:
			parent.jumped = false
			parent.wall_slide = true
			if parent.is_on_floor():
				parent.wall_slide = false
				return states.idle
			elif parent.velocity.y < 0:
				parent.wall_slide = false
				return states.jump
			elif !parent.is_on_wall():
				parent.wall_slide = false
				return states.falling
		#Wall Climb
		states.wall_climb:
			pass
		#Attack
		states.attack:
			parent.is_attacking = true
			if sprite.get_frame() == 1 or sprite.get_frame() == 2:
				attack_hitbox.monitoring = true
			else:
				attack_hitbox.monitoring = false
			if Input.is_action_pressed("S") and Input.is_action_pressed("M1") and sprite.get_frame() == 3:
				return states.crouch_attack
			elif Input.is_action_pressed("M1") and sprite.get_frame() == 3:
				return states.attack_2
			elif sprite.get_frame() == 3:
				parent.is_attacking = false
				return states.idle
		#Attack2
		states.attack_2:
			parent.is_attacking = true
			if sprite.get_frame() == 2 or sprite.get_frame() == 3:
				attack_hitbox.monitoring = true
			else:
				attack_hitbox.monitoring = false
			if Input.is_action_pressed("S") and Input.is_action_pressed("M1") and sprite.get_frame() == 5:
				return states.crouch_attack
			elif Input.is_action_pressed("M1") and sprite.get_frame() == 5:
				return states.attack
			elif sprite.get_frame() == 5:
				parent.is_attacking = false
				return states.idle
		#Crouch Attack
		states.crouch_attack:
			parent.is_attacking = true
			if sprite.get_frame() == 1 or sprite.get_frame() == 2:
				crouch_attack_hitbox.monitoring = true
			else:
				crouch_attack_hitbox.monitoring = false
			if !Input.is_action_pressed("S") and Input.is_action_pressed("M1") and sprite.get_frame() == 3:
				return states.attack
			elif Input.is_action_pressed("M1") and sprite.get_frame() == 3:
				return states.crouch_attack
			elif sprite.get_frame() == 3:
				parent.is_attacking = false
				return states.crouch_idle
	return null

func _enter_state(new_state, old_state):
	match new_state:
			states.idle:
				parent.on_stand()
				sprite.play("Idle")
			states.run:
				parent.on_stand()
				sprite.play("Run")
			states.jump:
				parent.on_stand()
				sprite.play("Jump")
			states.fall_transition:
				sprite.play("Fall Transition")
			states.falling:
				parent.on_stand()
				sprite.play("Falling")
			states.turn_around:
				sprite.play("Turn Around")
			states.crouch_idle:
				parent.on_crouch()
				sprite.play("Crouch Idle")
			states.crouch_transition:
				sprite.play("Crouch Transition")
			states.crouch_walk:
				parent.on_crouch()
				sprite.play("Crouch Walk")
			states.slide:
				parent.on_crouch()
				sprite.play("Slide")
			states.slide_transition:
				sprite.play("Slide Transition End")
			states.roll:
				parent.on_crouch()
				sprite.play("Roll")
			states.dash:
				sprite.play("Dash")
			states.death:
				sprite.play("Death")
			states.wall_slide:
				parent.on_stand()
				sprite.play("Wall Slide")
			states.wall_rang:
				sprite.play("Wall Rang")
			states.wall_climb:
				sprite.play("Wall Climb No Mov")
			states.attack:
				parent.on_stand()
				sprite.play("Attack")
			states.attack_2:
				parent.on_stand()
				sprite.play("Attack 2")
			states.crouch_attack:
				parent.on_crouch()
				sprite.play("Crouch Attack")

func _exit_state(old_state, new_state):
	pass

func _on_dash_cd_timeout() -> void:
	dash_in_cooldown = false
