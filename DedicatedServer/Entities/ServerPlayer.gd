extends Player
class_name ServerPlayer

onready var game_root: GameWorld = get_node('/root/GameRoot')

func _ready():
	pass

remote func server_get_player_snapshot(snapshot_data: PoolByteArray):
	var snapshot = PlayerSnapshot.new().decode(snapshot_data)
	snapshot.tick = game_root.tick_clock
	rpc_unreliable('client_get_player_snapshot', snapshot.encode())
