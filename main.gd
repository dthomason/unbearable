extends Node2D

var multiplayer_peer = ENetMultiplayerPeer.new()

const PORT = 9999
const ADDRESS = "127.0.0.1"

var connected_peer_ids = []
var local_player
var local_ghost

@onready var menu = $Menu

func _on_host_pressed():
	$Menu.visible = false
	multiplayer_peer.create_server(PORT)
	multiplayer.multiplayer_peer = multiplayer_peer
	
	add_player(1)
	
	multiplayer_peer.peer_connected.connect(
		func(new_peer_id):
			await get_tree().create_timer(1).timeout
			rpc("add_newly_connected_player_character", new_peer_id)
			rpc_id(new_peer_id, "add_previously_connected_player_characters", connected_peer_ids)
			add_player(new_peer_id)
	)


func _on_join_pressed():
	$Menu.visible = false
	multiplayer_peer.create_client(ADDRESS, PORT)
	multiplayer.multiplayer_peer = multiplayer_peer

func add_player(peer_id):
	connected_peer_ids.append(peer_id)
	var player = preload("res://Characters/Player/player.tscn").instantiate()
	player.set_multiplayer_authority(peer_id)
	get_node("/root/Main/Network").add_child(player)
	if peer_id == multiplayer.get_unique_id():
		local_player = player

@rpc	
func add_newly_connected_player_character(new_peer_id):
	add_player(new_peer_id)
	
@rpc
func add_previously_connected_player_characters(peer_ids):
	for peer_id in peer_ids:
		add_player(peer_id)

func _on_message_input_text_submitted(new_text):
	local_player.rpc("display_message", new_text)
	$MessageInput.text = ""
	$MessageInput.release_focus()
	
