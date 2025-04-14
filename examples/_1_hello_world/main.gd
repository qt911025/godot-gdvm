extends Control

const DataNodeString = Gdvm.DataNodeString
const WriterProperty = Gdvm.WriterProperty


# 示例1：简单的绑定

@onready var text_label: Label = $Panel/Label
@onready var timer: Timer = $Timer

var vm: DataNodeString
var writer: WriterProperty

var sideshow_texts: Array[String] = Array([
	"Hello World!",
	"This is Gdvm!",
	"A MVVM framework for Godot!"
], TYPE_STRING, "", null)

var current_playing: int = 0

func _ready() -> void:
	vm = DataNodeString.new(sideshow_texts[current_playing])
	writer = WriterProperty.new(text_label, ^"text", vm)

	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func _on_timer_timeout() -> void:
	current_playing = (current_playing + 1) % sideshow_texts.size()
	vm.render(sideshow_texts[current_playing])
