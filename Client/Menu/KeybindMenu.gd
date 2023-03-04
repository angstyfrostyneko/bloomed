extends PopupPanel

@onready var ActionName := $ActionName
@onready var ActionButton := $ActionButton
@onready var Popup := $PopupPanel
@onready var PopupLabel := $PopupPanel/Label
@onready var Grid := $ScrollContainer/VBoxContainer/GridContainer

var current_label := ActionName
var current_button := ActionButton


func _ready():
	for action_name in InputMap.get_actions():
		var key_name: InputEvent = InputMap.action_get_events(action_name)[0]
		
		var label: Label = ActionName.duplicate()
		var button: Button = ActionButton.duplicate()
		
		label.visible = true
		label.text = action_name
		
		button.visible = true
		button.text = key_name.as_text()
		# warning-ignore:return_value_discarded
		button.connect("button_down",Callable(self,"on_button_clicked").bind(label, button))
		
		Grid.add_child(label, true)
		Grid.add_child(button, true)


func on_button_clicked(label: Label, button: Button):
	PopupLabel.text = "Enter an action for " + label.text + "..."
	Popup.popup_centered()
	current_label = label
	current_button = button


func _input(event):
	if Popup.visible and event is InputEventKey:
		var action: String = current_label.text
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
		InputMap.action_add_event(action, event)
		current_button.text = event.as_text()
		Popup.visible = false


func _on_ReturnButton_down():
	visible = false
