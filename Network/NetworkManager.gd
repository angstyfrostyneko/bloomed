extends Node

var username: String

const SERVER_ID := 1
const MAX_PLAYERS := 16
var is_server: bool

signal auth_finished
signal server_closed

var players = {}
const PLAYER_ID_FIELD := 'id'
const PLAYER_NAME_FIELD := 'name'


# Called when the node enters the scene tree for the first time.
func _ready():
	reset_network()
	get_tree().connect('server_disconnected', self, 'on_server_disconnected')

func reset_network():
	var peer = get_tree().network_peer
	if peer != null:
		peer.close_connection()
	
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

func start_hosting(accountInfo, port):
	self.is_server = true
	reset_network()
	
	self.username = accountInfo[PLAYER_NAME_FIELD]
	
	var peer = NetworkedMultiplayerENet.new()
	var result = peer.create_server(port, MAX_PLAYERS)
	if result == OK:
		get_tree().set_network_peer(peer)
		
		get_tree().connect('network_peer_connected', self, 'on_peer_connected')
		get_tree().connect('network_peer_disconnected', self, 'on_peer_disconnected')
		print('Server started.')
		
		on_player_connected(accountInfo)
		emit_signal('auth_finished')
		return true
	else:
		print('Failed to host game: %d' % result)
		return false

func join_game(accountInfo, serverIp: String, port: int):
	self.is_server = false
	self.reset_network()
	# warning-ignore:return_value_discarded
	get_tree().connect('connected_to_server', self, 'on_connected_to_server')
	
	self.username = accountInfo[PLAYER_NAME_FIELD]
	
	var peer = NetworkedMultiplayerENet.new()
	var result = peer.create_client(serverIp, port)
	
	if result == OK:
		get_tree().set_network_peer(peer)
		print('Connecting to server...')
		return yield(self, 'auth_finished')
	else:
		return false

func on_connected_to_server():
	print('Connected to server, authenticating')
	rpc_id(SERVER_ID, 'auth_request', get_tree().get_network_unique_id(), self.username)
	var auth_answer = yield(self, 'auth_response')

signal player_connected(playerData)
signal player_disconnected(id)

remote func on_player_connected(playerData):
	self.players[playerData[PLAYER_ID_FIELD]] = playerData
	
	emit_signal('player_connected', playerData)
	
	print('Total players: %d' % self.players.size())

remote func on_player_disconnected(id):
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
	for pid in self.players:
		if pid == get_tree().get_network_unique_id():
			self.on_player_connected(playerData)
		else:
			rpc_id(pid, 'on_player_connected', playerData)
		rpc_id(playerData[PLAYER_ID_FIELD], 'on_player_connected', self.players[pid])
	
	rpc_id(playerData[PLAYER_ID_FIELD], 'on_player_connected', playerData)

remote func auth_request(playerId: int, playerName: String):
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

remote func answer_auth(accepted, answer):
	print('Authentication answered: %s' % answer)
	emit_signal('auth_response', accepted, answer)
	
remote func finish_auth():
	emit_signal('auth_finished')
