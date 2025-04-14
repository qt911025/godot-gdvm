extends Control

# # 示例4：观察者

const DataNodeString = Gdvm.DataNodeString
const WriterProperty = Gdvm.WriterProperty
const Observer = Gdvm.Observer

@onready var text_label: Label = $Panel/Label
@onready var text_edit: TextEdit = $Panel/TextEdit
# @onready var timer: Timer = $Timer

var vm: DataNodeString
var writer: WriterProperty
var observer: Observer

func _ready() -> void:
	vm = DataNodeString.new("")
	writer = WriterProperty.new(text_label, ^"text", vm)
	observer = Observer.new(text_edit, ^"text", vm, text_edit.text_changed)
