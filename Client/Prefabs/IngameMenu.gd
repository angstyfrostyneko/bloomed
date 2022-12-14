extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not is_network_master():
		return
	
	if Input.is_action_just_pressed("open_menu"):
		if self.visible:
			hide()
		else:
			show()

func show():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	self.visible = true

func hide():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	self.visible = false

func _on_LeaveButton_pressed():
	NetworkManager.reset_network()
	get_tree().change_scene('res://Menu/ConnectMenu.tscn')


func _on_CloseButton_pressed():
	hide()
