extends Node2D

var player_count = 0


func _ready():
		# Start paused.
#	get_tree().paused = true
	# You can save bandwidth by disabling server relay and peer notifications.
	multiplayer.server_relay = false

	# Automatically start the server in headless mode.
	if DisplayServer.get_name() == "headless":
		print("Automatically starting dedicated server.")
		_on_host_pressed.call_deferred()

func _on_join_pressed():
	var peer = ENetMultiplayerPeer.new()
	var port = str($Menu/Port.text).to_int()
	
	peer.create_client("localhost", port)
	multiplayer.multiplayer_peer = peer
	start_game()

func _on_host_pressed():
	var peer = ENetMultiplayerPeer.new()
	var port = str($Menu/Port.text).to_int()
	
	peer.create_server(port)
	
	# Start as server.
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer server.")
		return
	
	multiplayer.multiplayer_peer = peer
#	peer.peer_connected.connect(func(id): add_player(id))
	start_game()

func start_game():
	# Hide the UI and unpause to start the game.
	$Menu.hide()
	# Only change level on the server.
	# Clients will instantiate the level via the spawner.
	if multiplayer.is_server():
		change_level.call_deferred(load("res://Levels/lobby.tscn"))

# Call this function deferred and only on the main authority (server).
func change_level(scene: PackedScene):
	# Remove old level if any.
	var level = $Level
	for c in level.get_children():
		level.remove_child(c)
		c.queue_free()
	# Add new level.
	level.add_child(scene.instantiate())
