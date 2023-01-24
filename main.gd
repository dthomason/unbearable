extends Node2D

var multiplayer_peer = ENetMultiplayerPeer.new()

@onready var menu = $Menu

func _on_join_pressed():
	var port = str($Menu/Port.text).to_int()
	multiplayer_peer.create_client("localhost", port)
	multiplayer.multiplayer_peer = multiplayer_peer
	menu.visible = false

func _on_host_pressed():
	var port = str($Menu/Port.text).to_int()
	multiplayer_peer.create_server(port)
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer_peer.peer_connected.connect(func(id): add_player(id))
	menu.visible = false
	add_player()


func add_player(id=1):
	var player = preload("res://Characters/Player/player.tscn").instantiate()
	player.name = str(id)
	add_child(player)
	
