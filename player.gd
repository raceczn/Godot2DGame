extends CharacterBody2D

@export var speed = 400
@export var gravity = 30
@export var jump_force = 500

@onready var anim_player = $AnimationPlayer
@onready var sprite = $Sprite2D  

var walk_timer := 0.0  
const RUN_THRESHOLD := 1.5
var is_running := false
var is_pushing := false
var is_attacking := false

var can_double_jump := false

# Dash detection vars
var did_dash := false

func _physics_process(delta):
	is_pushing = false  # Reset at start of frame
	did_dash = false    # Reset dash flag

	# Dash via input map
	if Input.is_action_just_pressed("dash"):
		anim_player.play("dash")
		if sprite.flip_h:
			velocity.x = -speed * 2  # reduced from 4 to 2
		else:
			velocity.x = speed * 2   # reduced from 4 to 2
		did_dash = true

	# Slash attack logic
	if Input.is_action_just_pressed("attack") and !is_attacking:
		anim_player.play("slash_attack")
		is_attacking = true

	if is_attacking:
		if not anim_player.is_playing() or anim_player.current_animation != "slash_attack":
			is_attacking = false
		return

	# Apply gravity
	if !is_on_floor():
		velocity.y += gravity
		if velocity.y > 1000:
			velocity.y = 1000

	# Reset double jump when grounded
	if is_on_floor():
		can_double_jump = true

	# Jump and Double Jump logic
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = -jump_force
			anim_player.play("jump")
		elif can_double_jump:
			velocity.y = -jump_force
			anim_player.play("double_jump")
			can_double_jump = false

	# Horizontal movement
	var horizontal_direction = Input.get_axis("move_left", "move_right")
	velocity.x = speed * horizontal_direction

	# Flip the sprite
	if horizontal_direction != 0:
		sprite.flip_h = horizontal_direction < 0

	# Move the character
	move_and_slide()

	# Push rigid bodies
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		if collider is RigidBody2D:
			var push_dir = collision.get_normal() * -1.0
			collider.apply_central_impulse(push_dir * 50)
			if horizontal_direction != 0:
				is_pushing = true

	# Track walk/run
	if horizontal_direction != 0:
		walk_timer += delta
		is_running = walk_timer >= RUN_THRESHOLD
	else:
		is_running = false
		walk_timer = 0

	# Animation logic
	if !is_on_floor():
		# animation already handled in jump section
		pass
	elif is_pushing:
		anim_player.play("push")
	elif Input.is_action_pressed("move_down") and horizontal_direction != 0:
		anim_player.play("slide")
		# walk_timer = 0  # ← removed to preserve run after sliding
	elif did_dash:
		pass  # already playing dash, don't override
	elif horizontal_direction != 0:
		anim_player.play("run" if is_running else "walk")
	else:
		anim_player.play("idle")
		walk_timer = 0

	print("Velocity:", velocity, " CanDoubleJump:", can_double_jump)
