# TODO: determine kill animation from level
# Ice level = "Freeze"
# Fire Level = "Burn"
# Acid Level = "Erode"
# Air Level = "Pop"
# Electric Level = "Shock"
# Water Level = "Liquify"
extends CharacterBody2D

var excluded_from_coloring : Array[String] = [ "Shadow", "Mouth", "EyeRight", "EyeLeft", "Tummy" ]
var input_direction : Vector2 = Vector2.ZERO
var look_direction = Vector2(1,0)
var move_speed : float = 600.0
var kill_target : CharacterBody2D
var is_ghost = false

@export var is_alive : bool = true
@export var player_color : Color = Color(1,1,1)

var killer_id : int = 1
var player_id : int

@onready var anim_state = $AnimationPlayer
@onready var body_parts = $Body
@onready var camera : Camera2D = $Camera
@onready var label_name : Label = $PlayerName
@onready var label_state : Label = $PlayerState
@onready var label_multi : Label = $MultiState
@onready var sync = $MultiplayerSynchronizer

func _ready():
	label_name.text = "Name: " + str(name)
	sync.set_multiplayer_authority(str(name).to_int())
	camera.enabled = sync.is_multiplayer_authority()
	label_state.text = "Server: " + str(multiplayer.is_server())
	label_multi.text = "Authority: " + str(sync.is_multiplayer_authority())
	var instance = multiplayer.get_instance_id()
	print("INSTANCE: " +str(instance))
	
func set_color(color: Color, body = body_parts, exclude = excluded_from_coloring):
	if sync.is_multiplayer_authority():
		for e in body.get_children():
			if !exclude.has(str(e.name)):
				e.self_modulate = color
				set_color(color, e, exclude)

func _physics_process(_delta):
	if not sync.is_multiplayer_authority(): return
		
	get_special_keys()
	
	input_direction = get_input_direction()
	set_look_direction(look_direction * input_direction)
	
	if input_direction != Vector2.ZERO and is_alive:
		anim_state.play("Walk")
	if input_direction == Vector2.ZERO and is_alive:
		anim_state.play("Idle")
	if not is_alive:
		anim_state.play("Burn")
	if not is_alive and is_ghost:
		anim_state.play("Ghost")
		
	# Sync for Multi Player
	global_position += input_direction.normalized()
	sync.position = global_position

	# Update velocity
	velocity = input_direction.normalized() * move_speed

	# Actually move character
	move_and_slide()
	

func get_special_keys():
	if not sync.is_multiplayer_authority(): return
	
	if Input.is_action_pressed("effect_tester"):
		kill_target.kill_player.rpc()

func get_input_direction():
	if not sync.is_multiplayer_authority(): return
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).normalized()

func set_look_direction(value):
	if not value.x:
		return
	var new_look_direction = Vector2(value.x, 0)
	sync.x_transform = new_look_direction
	body_parts.transform.x = new_look_direction

func show_kill_button(body: CharacterBody2D):
	var is_authority = sync.is_multiplayer_authority()
	var is_killer = str(name).to_int() == killer_id
	var is_not_self = self.name != body.name
	
	return is_authority and is_killer and is_not_self
	
func _on_kill_zone_body_entered(body):
	$KillPlayer.visible = show_kill_button(body)
	
	if str(body.name).to_int() != killer_id:
		kill_target = body
		
func _on_kill_zone_body_exited(body):
	$KillPlayer.visible = false
	
func _on_kill_player_pressed():
	kill_target.kill_player.rpc_id(kill_target.get_multiplayer_authority())
	

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "Burn":
		kill_target.is_ghost = true

@rpc('any_peer')
func kill_player():
	kill_target.is_alive = false
