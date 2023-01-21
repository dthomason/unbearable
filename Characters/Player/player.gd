# TODO: determine kill animation from level
# Ice level = "Freeze"
# Fire Level = "Burn"
# Acid Level = "Erode"
# Air Level = "Pop"
# Electric Level = "Shock"
# Water Level = "Liquify"
extends CharacterBody2D

enum PLAYER_STATE { IDLE, MOVE, DEAD }

var look_direction = Vector2(1,0)
var input_direction : Vector2 = Vector2.ZERO
var state : PLAYER_STATE = PLAYER_STATE.IDLE
var excluded : Array[String] = [ "Shadow", "Mouth", "EyeRight", "EyeLeft", "Tummy" ]

@export var move_speed : float = 600.0
@export var colored : Color = Color(1, 1, 1)

@onready var anim_state = $AnimationTree["parameters/playback"]
@onready var body_parts = $Body

func _ready():
	set_color(body_parts, colored, excluded)
	
func set_color(body: Node2D, color: Color, exclude: Array[String]):
	for e in body.get_children():
		if !exclude.has(str(e.name)):
			e.self_modulate = color
			set_color(e, color, exclude)

func _physics_process(delta):
	if state == PLAYER_STATE.DEAD:
		return
		
	input_direction = get_input_direction()
		
	# Update velocity
	velocity = input_direction.normalized() * move_speed
	
	# Actually move character
	move_and_slide()
	
	# Set current state
	pick_new_state()
	
	## TESTING FUNC ONLY
	get_special_keys()
	
func get_special_keys():
	if Input.is_action_pressed("Trigger_Effect"):
		anim_state.travel("Burn")
		state = PLAYER_STATE.DEAD
	
func pick_new_state():
	if state == PLAYER_STATE.DEAD:
		return
	if input_direction:
		set_look_direction(look_direction * input_direction)
		anim_state.travel("Walk")
		state = PLAYER_STATE.MOVE
	else:
		anim_state.travel("Idle")
		state = PLAYER_STATE.IDLE

func get_input_direction():
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)

func set_look_direction(value):
	if not value.x:
		return
	body_parts.transform.x = Vector2(value.x, 0)
	
