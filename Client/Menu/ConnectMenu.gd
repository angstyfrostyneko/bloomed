extends Control

@onready var KeybindMenu: PopupPanel  = $KeybindMenu

var connecting = false

func _ready():
# warning-ignore:return_value_discarded
	NetworkManager.connect('auth_finished',Callable(self,'on_auth_finished'))
# warning-ignore:return_value_discarded
	multiplayer.connect('connection_failed',Callable(self,'on_connection_failed'))

func _on_ConnectButton_pressed():
	if connecting:
		return
	# Parse parameters from GUI
	var playerName := $Panel/VBoxContainer/PlayerNameField.text as String
	
	var ip := $Panel/VBoxContainer/ServerInfo/ServerIPContainer/ServerIPField.text as String
	var port := $Panel/VBoxContainer/ServerInfo/ServerPortContainer/ServerPortField.text as int
	
	self.connecting = true
	$Panel/VBoxContainer/Status.set_text('Connecting...')
	
	await NetworkManager.join_game({NetworkManager.PLAYER_NAME_FIELD: playerName}, ip, port)

func on_auth_finished():
# warning-ignore:return_value_discarded
	get_tree().change_scene_to_file('res://Client/ClientMain.tscn')

func on_connection_failed():
	self.connecting = false
	$Panel/VBoxContainer/ConnectingLabel.set_text('Failed to connect to server')

func _on_Host_pressed():
	var playerName := $Panel/VBoxContainer/PlayerNameField.text as String
	var port := $Panel/VBoxContainer/ServerInfo/ServerPortContainer/ServerPortField.text as int
	
	$Panel/VBoxContainer/Status.set_text('NOT WORKING...')


func _on_ConfigureKeybindings_down():
	KeybindMenu.popup_centered()
