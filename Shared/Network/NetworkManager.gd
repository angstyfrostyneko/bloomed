extends Node

const SERVER_ID := 1
const MAX_PLAYERS := 16
var is_server: bool
var server_name: String

var players = {}
const PLAYER_ID_FIELD := 'id'
const PLAYER_NAME_FIELD := 'name'

var username: String

const INTERP_INTERVAL := 3
const TICKS_PER_SECOND := 60
const TICK_DELTA := 1.0/TICKS_PER_SECOND

signal auth_finished
signal server_closed


func _ready():
	reset_network()
	# warning-ignore:return_value_discarded
	multiplayer.connect('server_disconnected',Callable(self,'on_server_disconnected'))

func reset_network():
	var peer = multiplayer.multiplayer_peer
	if peer != null:
		peer.close()
	
	# Cleanup all state related to the game session
	self.players = {}

func on_peer_connected(id):
	print("Peer connected: " + str(id))
	
func on_peer_disconnected(id):
	print("Peer disconnected: " + str(id))
	self.on_player_disconnected(id)

func on_server_disconnected():
	self.reset_network()
	emit_signal('server_closed')

func start_hosting(port):
	self.is_server = true
	reset_network()
	
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_server(port, MAX_PLAYERS)
	if result == OK:
		multiplayer.multiplayer_peer = peer
		
		# warning-ignore:return_value_discarded
		multiplayer.connect('peer_connected',Callable(self,'on_peer_connected'))
		# warning-ignore:return_value_discarded
		multiplayer.connect('peer_disconnected',Callable(self,'on_peer_disconnected'))
		print('Server started.')
		
		emit_signal('auth_finished')
		return true
	else:
		print('Failed to host game: %d' % result)
		return false

func join_game(accountInfo, serverIp: String, port: int):
	self.is_server = false
	self.reset_network()
	# warning-ignore:return_value_discarded
	multiplayer.connect('connected_to_server',Callable(self,'on_connected_to_server'))
	
	self.username = accountInfo[PLAYER_NAME_FIELD]
	
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_client(serverIp, port)
	
	if result == OK:
		multiplayer.multiplayer_peer = peer
		print('Connecting to server...')
		return await self.auth_finished
	else:
		return false

func on_connected_to_server():
	print('Connected to server, authenticating')
	rpc_id(SERVER_ID, 'auth_request', multiplayer.get_unique_id(), self.username)
# warning-ignore:unused_variable
	var auth_answer = await self.auth_response

signal player_connected(playerData)
signal player_disconnected(id)

@rpc("any_peer") func on_player_connected(playerData):
	self.players[playerData[PLAYER_ID_FIELD]] = playerData
	
	emit_signal('player_connected', playerData)
	
	print('Total players: %d' % self.players.size())

@rpc("any_peer") func on_player_disconnected(id):
	if not (id in players):
		return
	print('%s disconnected.' % players[id][PLAYER_NAME_FIELD])
	self.players.erase(id)

	emit_signal('player_disconnected', id)
	print('Total players: %d' % self.players.size())


func can_login(playerId: int, playerName: String) -> bool:
	if playerId in self.players:
		return false
	for pid in self.players:
		if self.players[pid][PLAYER_NAME_FIELD] == playerName:
			return false
	return true

func sync_new_player(playerData):
	# Send new player to everyone else
	self.on_player_connected(playerData)
	for pid in self.players:
		rpc_id(pid, 'on_player_connected', playerData)
		rpc_id(playerData[PLAYER_ID_FIELD], 'on_player_connected', self.players[pid])
	
	rpc_id(playerData[PLAYER_ID_FIELD], 'on_player_connected', playerData)

@rpc("any_peer") func auth_request(playerId: int, playerName: String):
	print('Auth request from %d: %s' % [playerId, playerName])
	if not can_login(playerId, playerName):
		rpc_id(playerId, 'answer_auth', false, 'Account already connected')
		return
	
	var playerData = {PLAYER_ID_FIELD: playerId, PLAYER_NAME_FIELD: playerName}
	
	rpc_id(playerId, 'answer_auth', true, 'Authenticated')
	
	self.sync_new_player(playerData)
	
	rpc_id(playerId, 'finish_auth')

# Client Side
signal auth_response(accepted, answer)

@rpc("any_peer") func answer_auth(accepted, answer):
	print('Authentication answered: %s' % answer)
	emit_signal('auth_response', accepted, answer)
	
@rpc("any_peer") func finish_auth():
	emit_signal('auth_finished')

func is_host():
	return self.is_server
