extends MultiplayerSynchronizer

# Synchronized property.
@export var direction := Vector2()

# Synchronized property.
#@export var position := Vector2()
#@export var direction := Vector2()
#
func _ready():
	# Only process for the local player
	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())


#@export var position:Vector2:
#	set(val):
#		if is_multiplayer_authority():
#			position = val
#		else:
#			get_parent().position = val

#@export var x_transform:Vector2:
#	set(val):
#		if is_multiplayer_authority():
#			x_transform = val
#		else:
#			get_parent().get_node("Body").transform.x = val
			

func _process(delta):
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()

