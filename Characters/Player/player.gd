# TODO: determine kill animation from level
# Ice level = "Freeze"
# Fire Level = "Burn"
# Acid Level = "Erode"
# Air Level = "Pop"
# Electric Level = "Shock"
# Water Level = "Liquify"
extends CharacterBody2D

enum PLAYER_STATE { IDLE, MOVING, DYING, DEAD }
var state_names = ["Idle", "Moving", "Dying", "Dead"]

var look_direction = Vector2(1,0)
var input_direction : Vector2 = Vector2.ZERO
var state : PLAYER_STATE = PLAYER_STATE.IDLE
var excluded_from_coloring : Array[String] = [ "Shadow", "Mouth", "EyeRight", "EyeLeft", "Tummy" ]

@export var move_speed : float = 600.0
@export var player_color : Color = Color(1,1,1)

@onready var anim_state = $AnimationTree["parameters/playback"]
@onready var body_parts = $Body
@onready var camera : Camera2D = $Camera
@onready var sync = $MultiplayerSynchronizer
@onready var player_name : Label = $PlayerName
@onready var player_state : Label = $PlayerState

func _ready():
	player_name.text = str(name)
	sync.set_multiplayer_authority(str(name).to_int())
	camera.current = sync.is_multiplayer_authority()
	
	# Set player color
#	sync.player_color = player_color
#	set_color(sync.player_color)

func set_color(color: Color, body = body_parts, exclude = excluded_from_coloring):
	if sync.is_multiplayer_authority():
		for e in body.get_children():
			if !exclude.has(str(e.name)):
				e.self_modulate = color
				set_color(color, e, exclude)

func _physics_process(_delta):
	if sync.is_multiplayer_authority():
		if state == PLAYER_STATE.DEAD:
			return
			
		input_direction = get_input_direction()
		
		if input_direction:
			state = PLAYER_STATE.MOVING
		elif Input.is_action_pressed("effect_tester"):
			state = PLAYER_STATE.DEAD
		else:
			state = PLAYER_STATE.IDLE
				
		# Sync for Multi Player
		global_position += input_direction.normalized()
		sync.position = global_position

		# Update velocity
		velocity = input_direction.normalized() * move_speed

		# Actually move character
		move_and_slide()

		# Set current state
		react_to_state()


func get_special_keys():
	if Input.is_action_pressed("effect_tester"):
		print("SHOULD BE DYING")
		state = PLAYER_STATE.DEAD

func react_to_state():
	player_state.text = state_names[state]
	match state:
		PLAYER_STATE.DEAD:
			player_state.text = "Dead"
			anim_state.travel("Burn")
		PLAYER_STATE.MOVING:
			player_state.text = "Moving"
			set_look_direction(look_direction * input_direction)
			anim_state.travel("Walk")
		PLAYER_STATE.IDLE:
			player_state.text = "Idle"
			anim_state.travel("Idle")
	
func get_input_direction():
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)

func set_look_direction(value):
	if not value.x:
		return
	var new_look_direction = Vector2(value.x, 0)
	sync.x_transform = new_look_direction
	body_parts.transform.x = new_look_direction



