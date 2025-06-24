extends Control

const DataNodeList = Gdvm.DataNodeList
const DataNodeBool = Gdvm.DataNodeBool
const DataNodeInt = Gdvm.DataNodeInt
const DataTree = Gdvm.DataTree
const ObserverPackTree = Gdvm.ObserverPackTree
const WriterPackTree = Gdvm.WriterPackTree

# 示例6 Todo MVC

# 功能：
# 添加 √
# 编辑文本 √
# 勾选（标为已完成，下划线特效）√
# 去选 √
# 删掉一个 √
# 删除所有已完成 √
# 过滤显示（全部、未完成、已完成）√
# 全选/取消 √
# 统计还剩多少未完成 √
# 无项目时，不显示全选和底栏 √

const ItemTemplate = preload("./item.tscn")

var data_tree: DataTree
var observers: ObserverPackTree
var writers: WriterPackTree

# header
var all_checked: bool:
	set(value):
		select_all_checkbox.set_pressed_no_signal(value)
	get:
		return select_all_checkbox.button_pressed
@onready var new_item_line_edit := %NewItem as LineEdit
@onready var select_all_checkbox := %SelectAll as CheckBox
# body
@onready var todos_container := %Todos as VBoxContainer
# footer
@onready var footer := %Footer as PanelContainer
var items_count: int:
	set(value):
		items_count = value
		if items_count > 0:
			select_all_checkbox.visible = true
			footer.visible = true
		else:
			select_all_checkbox.visible = false
			footer.visible = false
var items_left: int:
	set(value):
		items_left = value
		items_left_label.text = "%s item%s left" % [items_left, "s" if items_left > 1 else ""]
@onready var items_left_label := %ItemsLeft as Label
enum FilterState {
	ALL,
	ACTIVE,
	COMPLETED,
}
var filter: FilterState:
	set(value):
		filter = value
		match value:
			FilterState.ALL:
				todos_container.get_children().map(func(item: TodoMVCItem) -> void:
					item.visible = true
				)
			FilterState.ACTIVE:
				todos_container.get_children().map(func(item: TodoMVCItem) -> void:
					if item.checked:
						item.visible = false
					else:
						item.visible = true
				)
			FilterState.COMPLETED:
				todos_container.get_children().map(func(item: TodoMVCItem) -> void:
					if item.checked:
						item.visible = true
					else:
						item.visible = false
				)
	get:
		return filter
@onready var filter_all_button := %Filter/All as Button
@onready var filter_active_button := %Filter/Active as Button
@onready var filter_completed_button := %Filter/Completed as Button
@onready var clear_completed_button := %ClearCompleted as Button

func _ready() -> void:
	new_item_line_edit.text_submitted.connect(_on_new_item_line_edit_text_submitted)

	data_tree = DataTree.new(DataTree.opts({
		"data": {
			"checked": [false],
		},
		"computed": [
			{
				"dependencies": ["checked"],
				"outputs": {
					"items_count": 0,
					"items_left": 0,
					"all_checked": false
				},
				"computer": func(dependencies: Dictionary, outputs: Dictionary) -> void:
					var items := dependencies["checked"] as Array
					var items_size := items.size()
					var completed_count := items.count(true)
					(outputs["items_count"] as DataNodeInt).render(items_size)
					(outputs["items_left"] as DataNodeInt).render(items_size - completed_count)
					(outputs["all_checked"] as DataNodeBool).render(completed_count == items_size)
					}
		],
	}))
	observers = ObserverPackTree.new({
		"base": self,
		"options": {
			"checked": ObserverPackTree.opts({
				"type": ObserverPackTree.NODE,
				"path": "Panel/Container/Todos",
				"children": ObserverPackTree.opts({
					"path": ":checked",
					"changed": func(source: Object, _property_path: NodePath) -> Signal:
						return (source as TodoMVCItem).checked_toggled
						})
			})
		}
	})
	data_tree.observe(observers)
	writers = WriterPackTree.new(data_tree.get_root(), {
		"base": self,
		"options": {
			"checked": WriterPackTree.opts({
				"type": WriterPackTree.NODE,
				"path": "Panel/Container/Todos",
				"children": WriterPackTree.opts({
					"path": ":checked",
				})
			}),
			"items_count": 0,
			"items_left": 0,
			"all_checked": false,
		}
	})

	select_all_checkbox.toggled.connect(func(toggled_on: bool):
		var checked_data_nodes := (data_tree.get_root().checked as DataNodeList).get_element_nodes()
		if toggled_on:
			checked_data_nodes.map(func(item: DataNodeBool) -> void:
				item.render(true)
			)
		else:
			checked_data_nodes.map(func(item: DataNodeBool) -> void:
				item.render(false)
			)
	)
	filter_all_button.pressed.connect(func() -> void:
		filter = FilterState.ALL
	)
	filter_active_button.pressed.connect(func() -> void:
		filter = FilterState.ACTIVE
	)
	filter_completed_button.pressed.connect(func() -> void:
		filter = FilterState.COMPLETED
	)
	clear_completed_button.pressed.connect(_clear_completed)
	
func _on_new_item_line_edit_text_submitted(new_text: String) -> void:
	if not new_text.is_empty():
		var todo := ItemTemplate.instantiate()
		todos_container.add_child(todo)
		todo.content = new_text
		new_item_line_edit.text = ""
		if filter == FilterState.COMPLETED:
			todo.visible = false
	new_item_line_edit.release_focus()

func _clear_completed() -> void:
	# 因为content不在DataNode里，所以直接删data_node里的项不会更新content，造成错位
	# 如果需要保证content也同步，就要建立对应的DataNode以及读者写者绑定。
	# 这个例子只是为了展示不这么做会是什么效果，才这么实现。
	todos_container.get_children().filter(func(item: TodoMVCItem) -> bool:
		return item.checked
	).map(func(item: TodoMVCItem) -> void:
		item.queue_free()
	)
