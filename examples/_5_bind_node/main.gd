extends Control

# 示例5：深层绑定

const DataTree = Gdvm.DataTree
const WriterPackTree = Gdvm.WriterPackTree

func _ready() -> void:
	var tree := DataTree.new({
		"left": "Left",
		"top_right": "Top Right",
		"bottom_right": "Bottom Right",
	})
	var root := tree.get_root()
	var _writers := WriterPackTree.new(root, {
		base = get_tree().current_scene,
		options = {
			"left": WriterPackTree.opts({
				"path": "Panel/Label:text"
			}),
			"top_right": WriterPackTree.opts({
				"path": "Panel/Panel/LabelUpper:text"
			}),
			"bottom_right": WriterPackTree.opts({
				"path": "Panel/Panel/LabelLower:text"
			}),
		}
	})