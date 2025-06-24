class_name TodoMVCItem extends VBoxContainer

@onready var normal_mode_container := %NormalMode as PanelContainer
@onready var edit_mode_container := %EditMode as PanelContainer
@onready var completed_checkbox := %Completed as CheckBox
@onready var content_label := %Content as RichTextLabel
@onready var remove_button := %Remove as Button
@onready var edit_input := %Edit as LineEdit

signal checked_toggled()

var checked: bool:
	set(value):
		if completed_checkbox.button_pressed != value: # 防死循环
			completed_checkbox.button_pressed = value
	get:
		return completed_checkbox.button_pressed

var content: String:
	set(value):
		content = value
		if completed_checkbox.button_pressed:
			content_label.text = "[s]%s[/s]" % value
		else:
			content_label.text = value

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	content_label.gui_input.connect(_on_double_clicking_content)
	remove_button.pressed.connect(_on_remove_pressed)
	edit_input.editing_toggled.connect(func(toggled_on: bool):
		if not toggled_on:
			_on_edit_submitted()
	)
	completed_checkbox.toggled.connect(func(_toggled_on: bool):
		content = content
		checked_toggled.emit()
	)

func _on_mouse_entered() -> void:
	remove_button.visible = true

func _on_mouse_exited() -> void:
	remove_button.visible = false

func _on_remove_pressed() -> void:
	queue_free()

func _on_double_clicking_content(event: InputEvent) -> void:
	if event is InputEventMouseButton and \
	event.button_index == MOUSE_BUTTON_LEFT and \
	event.double_click == true:
		normal_mode_container.visible = false
		edit_mode_container.visible = true
		edit_input.text = content
		edit_input.grab_focus()
		edit_input.select_all()
		get_window().set_input_as_handled() # 阻止双击事件向下传递，被失焦函数捕获到

func _on_edit_submitted() -> void:
	normal_mode_container.visible = true
	edit_mode_container.visible = false
	if edit_input.text.is_empty():
		edit_input.text = content
	else:
		content = edit_input.text
