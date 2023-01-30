extends Node



@export var position:Vector2:
	set(val):
		if is_multiplayer_authority():
			position = val
		else:
			get_parent().position = val

@export var x_transform:Vector2:
	set(val):
		if is_multiplayer_authority():
			x_transform = val
		else:
			get_parent().get_node("Body").transform.x = val
			
