extends CharacterBody2D

@export var speed = 400
@export var gravity = 30
@export var jump_force = 500
@export var dash_speed = 800
@export var dash_duration = 0.2  

@onready var anim_player = $AnimationPlayer
@onready var sprite = $Sprite2D  

var walk_timer := 0.0  
const RUN_THRESHOLD := 1.5
var is_running := false
var is_pushing := false
var is_attacking := false
var can_double_jump := false

# Dash state
var is_dashing := false
var dash_time_left := 0.0
var dash_direction := 0

func _physics_process(delta):
	is_pushing = false

	# DASH
	if is_dashing:
		dash_time_left -= delta
		velocity.x = dash_direction * dash_speed
		velocity.y = 0

		if dash_time_left <= 0:
			is_dashing = false
	else:
		# ATTACKS
		if Input.is_action_just_pressed("attack2") and !is_attacking:
			anim_player.play("attack2")
			is_attacking = true

		elif Input.is_action_just_pressed("attack") and !is_attacking:
			anim_player.play("slash_attack")
			is_attacking = true

		if is_attacking:
			if not anim_player.is_playing():
				is_attacking = false
			return

		# Gravity
		if !is_on_floor():
			velocity.y += gravity
			if velocity.y > 1000:
				velocity.y = 1000

		# Reset double jump
		if is_on_floor():
			can_double_jump = true

		# Jump / Double Jump
		if Input.is_action_just_pressed("jump"):
			if is_on_floor():
				velocity.y = -jump_force
				anim_player.play("jump")
			elif can_double_jump:
				velocity.y = -jump_force
				anim_player.play("double_jump")
				can_double_jump = false

		# Horizontal input
		var horizontal_direction = Input.get_axis("move_left", "move_right")
		velocity.x = speed * horizontal_direction

		# Dash Input
		if Input.is_action_just_pressed("dash"):
			is_dashing = true
			dash_time_left = dash_duration
			dash_direction = -1 if sprite.flip_h else 1
			anim_player.play("dash")
			return

		# Flip sprite
		if horizontal_direction != 0:
			sprite.flip_h = horizontal_direction < 0

		# Walk/run tracking
		if horizontal_direction != 0:
			walk_timer += delta
			is_running = walk_timer >= RUN_THRESHOLD
		else:
			is_running = false
			walk_timer = 0

	# Move the character
	move_and_slide()

	# Push logic
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		if collider is RigidBody2D:
			var push_dir = collision.get_normal() * -1.0
			collider.apply_central_impulse(push_dir * 50)
			is_pushing = true

	# Animations
	if is_dashing:
		anim_player.play("dash")
	elif !is_on_floor():
		pass
	elif is_pushing:
		anim_player.play("push")
	elif Input.is_action_pressed("move_down") and velocity.x != 0:
		anim_player.play("slide")
	elif abs(velocity.x) > 0:
		anim_player.play("run" if is_running else "walk")
	else:
		anim_player.play("idle")

	print("Velocity:", velocity, " Dashing:", is_dashing, " DoubleJump:", can_double_jump)
