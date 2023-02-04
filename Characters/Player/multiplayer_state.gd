extends Node

@export var x_transform:Vector2:
	set(val):
		if is_multiplayer_authority():
			x_transform = val
		else:
			get_parent().get_node("Body").transform.x = val
