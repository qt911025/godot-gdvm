extends Control

const DataNode = Gdvm.DataNode
const DataNodeVariant = Gdvm.DataNodeVariant
const DataNodeList = Gdvm.DataNodeList
const Writer = Gdvm.Writer
const WriterProperty = Gdvm.WriterProperty
const WriterNode = Gdvm.WriterNode

# 示例3：节点数组

@onready var label_container: VBoxContainer = $Panel/VBoxContainer
@onready var timer: Timer = $Timer

var vm: DataNodeList
var writer: WriterNode

func _ready() -> void:
	var sideshow_texts: Array[String] = Array([
		"Hello World!",
		"This is Gdvm!",
		"A MVVM framework for Godot!"
	], TYPE_STRING, "", null)

	vm = DataNodeList.new(TYPE_STRING, func() -> DataNodeVariant: return DataNodeVariant.new(""))
	
	writer = WriterNode.new(label_container, vm, WriterNode.ChildSubWriter.new(
		func(source_data_node: DataNode) -> Node:
			var new_label := Label.new()
			new_label.add_theme_font_size_override("font_size", 64)
			new_label.text = source_data_node.value()
			return new_label
			,
		func(source_data_node: DataNode, target_child: Node) -> Array:
			return [WriterProperty.new(target_child, ^"text", source_data_node)]
	))

	timer.timeout.connect(_on_timer_timeout)
	timer.start()

	vm.render(sideshow_texts)
	_on_timer_timeout()

func _on_timer_timeout() -> void:
	prints("shuffling...")
	vm.shuffle()
