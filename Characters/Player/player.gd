# TODO: determine kill animation from level
# Ice level = "Freeze"
# Fire Level = "Burn"
# Acid Level = "Erode"
# Air Level = "Pop"
# Electric Level = "Shock"
# Water Level = "Liquify"
extends CharacterBody2D

enum PLAYER_STATE { IDLE, MOVING, DEAD }

var excluded_from_coloring : Array[String] = [ "Shadow", "Mouth", "EyeRight", "EyeLeft", "Tummy" ]
var input_direction : Vector2 = Vector2.ZERO
var look_direction = Vector2(1,0)
var move_speed : float = 600.0
var kill_target : CharacterBody2D
var is_alive : bool = true

@export var player_color : Color = Color(1,1,1)
@export var player_state : PLAYER_STATE = PLAYER_STATE.IDLE
@export var killer_id : int = 1

@onready var anim_state = $AnimationTree["parameters/playback"]
@onready var body_parts = $Body
@onready var camera : Camera2D = $Camera
@onready var label_name : Label = $PlayerName
@onready var label_state : Label = $PlayerState
@onready var sync = $MultiplayerSynchronizer


func _ready():
	label_name.text = str(name)
	sync.set_multiplayer_authority(str(name).to_int())
	camera.current = sync.is_multiplayer_authority()
	
func set_color(color: Color, body = body_parts, exclude = excluded_from_coloring):
	if sync.is_multiplayer_authority():
		for e in body.get_children():
			if !exclude.has(str(e.name)):
				e.self_modulate = color
				set_color(color, e, exclude)

func _physics_process(_delta):
	if player_state == PLAYER_STATE.DEAD:
		return
	if sync.is_multiplayer_authority():
		input_direction = get_input_direction()
		
		if input_direction:
			set_look_direction(look_direction * input_direction)
			anim_state.travel("Walk")
		else:
			if is_alive:
				anim_state.travel("Idle")
				
			
		# Sync for Multi Player
		global_position += input_direction.normalized()
		sync.position = global_position

		# Update velocity
		velocity = input_direction.normalized() * move_speed

		# Actually move character
		move_and_slide()

func get_special_keys():
	if Input.is_action_pressed("effect_tester"):
		is_alive = false
		anim_state.travel("Burn")

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

func show_kill_button(body: CharacterBody2D):
	var is_authority = sync.is_multiplayer_authority()
	var is_killer = sync.get_multiplayer_authority() == killer_id
	var body_not_self = body.name != self.name
	
	var kill_opportunity =  is_authority and is_killer and body_not_self
	
	if kill_opportunity:
		kill_target = body

	return kill_opportunity

func _on_kill_zone_body_entered(body):
	$KillPlayer.visible = show_kill_button(body)

func _on_kill_zone_body_exited(body):
	$KillPlayer.visible = false

func _on_kill_player_pressed():
	var killer_screen = kill_target.get_node("AnimationTree")
	killer_screen["parameters/playback"].travel("Burn")
