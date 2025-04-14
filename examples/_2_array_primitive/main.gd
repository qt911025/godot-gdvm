extends Control

const DataNodeVariant = Gdvm.DataNodeVariant
const DataNodeList = Gdvm.DataNodeList
const WriterPropertyArray = Gdvm.WriterPropertyArray

# 示例2：简单数组

@onready var text_label: Label = $Panel/Label
@onready var timer: Timer = $Timer

class RenderTarget:
	var data: Array[String]
	func get_text() -> String:
		return "\n".join(data)

var vm: DataNodeList
var writer: WriterPropertyArray
var render_target: RenderTarget


func _ready() -> void:
	var sideshow_texts: Array[String] = Array([
		"Hello World!",
		"This is Gdvm!",
		"A MVVM framework for Godot!"
	], TYPE_STRING, "", null)

	vm = DataNodeList.new(TYPE_STRING, func() -> DataNodeVariant: return DataNodeVariant.new(""))
	render_target = RenderTarget.new()
	writer = WriterPropertyArray.new(render_target, ^"data", vm)

	timer.timeout.connect(_on_timer_timeout)
	timer.start()

	vm.render(sideshow_texts)
	_on_timer_timeout()

func _on_timer_timeout() -> void:
	prints("shuffling...")
	vm.shuffle()
	text_label.text = render_target.get_text()
