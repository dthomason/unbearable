extends Node2D

var lobby = "res://Levels/lobby.tscn"
var level1 = "res://Levels/Level01.tscn"

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
	var player_color = $Menu/ColorPickerButton.color
	var player_name = str($Menu/Name.text)
	var player_info = {
		'name': player_name,
		'color': player_color,
	}
	
	peer.create_client("localhost", port)
	multiplayer.multiplayer_peer = peer
	Players.info[peer.get_unique_id()] = player_info
	join_lobby()

func _on_host_pressed():
	var peer = ENetMultiplayerPeer.new()
	var port = str($Menu/Port.text).to_int()
	var player_color = $Menu/ColorPickerButton.color
	var player_name = str($Menu/Name.text)
	var player_info = {
		'name': player_name,
		'color': player_color,
	}
	
	peer.create_server(port)
	
	# Start as server.
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer server.")
		return
	
	multiplayer.multiplayer_peer = peer
	Players.info[1] = player_info
	$StartGame.visible = true
	join_lobby()

func join_lobby():
	# Hide the UI and unpause to start the game.
	$Menu.hide()
	
	# Clients will instantiate the level via the spawner.
	if multiplayer.is_server():
		change_level.call_deferred(load(lobby))

# Call this function deferred and only on the main authority (server).
func change_level(scene: PackedScene):
	# Remove old level if any.
	var level = $Level
	for c in level.get_children():
		level.remove_child(c)
		c.queue_free()
	# Add new level.
	level.add_child(scene.instantiate())
	

func _on_start_game_pressed():
	change_level.call_deferred(load(level1))
