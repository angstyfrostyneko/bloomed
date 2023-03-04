extends PopupPanel

@onready var actionName := $ActionName
@onready var actionButton := $ActionButton
@onready var popup := $PopupPanel
@onready var popupLabel := $PopupPanel/Label
@onready var grid := $ScrollContainer/VBoxContainer/GridContainer

var current_label := actionName
var current_button := actionButton


func _ready():
	for action_name in InputMap.get_actions():
		var events = InputMap.action_get_events(action_name)
		if events.size() == 0:
			continue
		var key_name: InputEvent = events[0]
		
		var label: Label = actionName.duplicate()
		var button: Button = actionButton.duplicate()
		
		label.visible = true
		label.text = action_name
		
		button.visible = true
		button.text = key_name.as_text()
		# warning-ignore:return_value_discarded
		button.connect("button_down",Callable(self,"on_button_clicked").bind(label, button))
		
		grid.add_child(label, true)
		grid.add_child(button, true)


func on_button_clicked(label: Label, button: Button):
	popupLabel.text = "Enter an action for " + label.text + "..."
	popup.popup_centered()
	current_label = label
	current_button = button


func _input(event):
	if popup.visible and event is InputEventKey:
		var action: String = current_label.text
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
		InputMap.action_add_event(action, event)
		current_button.text = event.as_text()
		popup.visible = false


func _on_ReturnButton_down():
	visible = false
