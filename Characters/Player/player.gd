# TODO: determine kill animation from level
# Ice level = "Freeze"
# Fire Level = "Burn"
# Acid Level = "Erode"
# Air Level = "Pop"
# Electric Level = "Shock"
# Water Level = "Liquify"
extends CharacterBody2D

var input_direction : Vector2 = Vector2.ZERO
var is_ghost : bool = false
var killer_id : int = 1
var look_direction = Vector2(1,0)
var move_speed : float = 600.0

@export var kill_target : CharacterBody2D
@export var is_alive : bool = true

@onready var anim_state = $AnimationPlayer

func _ready():
	name = str(get_multiplayer_authority())
	$PlayerName.text = name
	$Camera.enabled = is_multiplayer_authority()


func _physics_process(_delta):
	if is_multiplayer_authority():

		input_direction = get_input_direction()
		set_look_direction(look_direction * input_direction)

		# All animated states
		if input_direction != Vector2.ZERO and is_alive:
			anim_state.play("Walk")
		if input_direction == Vector2.ZERO and is_alive:
			anim_state.play("Idle")
		if !is_alive and !is_ghost:
			anim_state.play("Burn")
		if is_ghost:
			anim_state.play("Ghost")

		# Sync for Multi Player
		global_position += input_direction
		rpc("remote_set_position", global_position)

		# Update velocity
		velocity = input_direction * move_speed

		# Actually move character
		move_and_slide()


func get_special_keys():
	if Input.is_action_pressed("effect_tester"):
		is_alive = false

func get_input_direction():
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).normalized()

@rpc
func set_look_direction(value):
	if not value.x:
		return
	var new_look_direction = Vector2(value.x, 0)
	$Body.transform.x = new_look_direction


@rpc
func remote_set_position(authority_position):
	global_position = authority_position

@rpc
func display_message(message):
	$Message.text = str(message)

@rpc
func kill_player(player: CharacterBody2D):
	player.get_node("AnimationPlayer").play("Burn")
	player.is_alive = false

func is_killer(body: CharacterBody2D):
	return body.is_multiplayer_authority() and str(body.name).to_int() == killer_id

func _on_kill_zone_body_entered(body):
	if is_multiplayer_authority() and str(self.name).to_int() == killer_id and body.name != self.name:
		$KillPlayerButton.visible = true
	if body.is_multiplayer_authority() and str(body.name).to_int() != killer_id:
		kill_target = body

func _on_kill_zone_body_exited(body):
	$KillPlayerButton.visible = false

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "Burn" and is_multiplayer_authority():
		var remains = preload("res://Characters/Player/burned.tscn").instantiate()
		remains.position = position
		get_tree().get_root().get_node("Main").add_child(remains)
		is_ghost = true
	
@rpc
func _on_kill_player_button_pressed():
	kill_target.is_alive = false
