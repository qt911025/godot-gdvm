extends Control

# const BindNode = Gdvm.BindNode

# # 示例5：绑定
# var gdvm: BindNode

const DataNodeVariant = Gdvm.DataNodeVariant
const WriterProperty = Gdvm.WriterProperty

@onready var text_label: Label = $Panel/Label
@onready var timer: Timer = $Timer

var vm: DataNodeVariant
var writer: WriterProperty

var sideshow_texts: Array[String] = Array([
	"Hello World!",
	"This is Gdvm!",
	"A MVVM framework for Godot!"
], TYPE_STRING, "", null)

var current_playing: int = 0

func _ready() -> void:
	vm = DataNodeVariant.new(sideshow_texts[current_playing])
	writer = WriterProperty.new(text_label, ^"text", vm)

	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func _on_timer_timeout() -> void:
	current_playing = (current_playing + 1) % sideshow_texts.size()
	vm.render(sideshow_texts[current_playing])