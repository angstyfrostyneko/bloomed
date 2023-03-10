extends PanelContainer

@onready var game_root : ClientMain = get_node('/root/GameRoot')

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$VBoxContainer/FPSLabel.text = 'FPS: ' + str(Engine.get_frames_per_second())
	$VBoxContainer/PingLabel.text = 'Ping: ' + str(int(game_root.latency)) + 'ms'
