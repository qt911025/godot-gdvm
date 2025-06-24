const WriterTreeTemplate = preload("./template.gd")
const WriterTreeOptions = preload("./options.gd")
const Utils = preload("../../../utils.gd")

# writer template

# 与最终的树同构（类似原来的compiler）
# 复制一个data_tree，如果保留观察树，模板会共享
# 不保存base，但代入base判定，不保存data_node（todo 不在生成时代入，看需要，决定是否实现预检查函数）
# base保存在data_tree中
# 在生成writer_tree阶段，会共同生成绑定data_node的writer_tree（writer版的compiler）

class TemplateLeaf:
	var type: WriterTreeOptions.Type
	## 观察路径
	## 普通叶子、List、Dict会自动补全，而Node必须显式指定
	var path: NodePath
	var sub_writer: WriterTreeOptions.SubWriter
	var children: WriterTreeTemplate

## 绑定信息
## key: 数据节点的DataNodeStruct路径，如果是空则表示根节点
## value: 写者树的叶子节点
var data: Dictionary[NodePath, TemplateLeaf]

## WriterTreeTemplate
func _init(tree_opts: WriterTreeOptions) -> void:
	_iterate_property(
		data,
		tree_opts,
		^"",
		^"",
		^"",
	)

## 深度优先遍历索引观察对象
static func _iterate_property(
	data: Dictionary,
	tree_opts: WriterTreeOptions,
	current_data_node_path: NodePath,
	last_ancestor_observe_path: NodePath, # 最近的一个显式指定的祖代观察路径
	temp_observe_path: NodePath, # 当这个节点未指定观察路径，会记录直到走到下一个显式指定的观察路径（这时清空），如果走到叶子则直接以这个路径补全。
	force_transform_link_path_into_property: bool = false, # 是否强制转换为property路径
) -> void:
	var is_leaf := true
	var has_properties := false
	var has_children := false

	# 哪些节点必须显式指定子写者？
	# 全都不是必须的，只有节点是要么必须有一个子写者要么必须有一个模板节点
	# 哪些节点必须没有子写者？

	match tree_opts.type:
		WriterTreeOptions.Type.NODE:
			if tree_opts.properties.size() > 0:
				has_properties = true
			has_children = true
		WriterTreeOptions.Type.PROPERTY_ARRAY, WriterTreeOptions.Type.PROPERTY_DICTIONARY:
			has_children = true
		WriterTreeOptions.Type.PROPERTY:
			if tree_opts.properties.size() > 0:
				has_properties = true
				is_leaf = false
	if is_leaf:
		var leaf := TemplateLeaf.new()
		leaf.type = tree_opts.type

		# 非根节点的Node必须显式指定观察路径
		assert(not leaf.type == WriterTreeOptions.Type.NODE or \
		current_data_node_path.is_empty() or not tree_opts.path.is_empty(),
		"WriterTreeOptions: non-root Node must assign path explicitly.")
		if tree_opts.path.is_empty():
			leaf.path = Utils.connect_link_path(last_ancestor_observe_path, temp_observe_path.get_as_property_path())
		else:
			var relative_observe_path := tree_opts.path
			if force_transform_link_path_into_property:
				relative_observe_path = Utils.convert_node_path_into_full_property_path(relative_observe_path)
			leaf.path = Utils.connect_link_path(last_ancestor_observe_path, relative_observe_path)
		# Node的观察路径必须没有属性路径
		assert(not leaf.type == WriterTreeOptions.Type.NODE or leaf.path.get_subname_count() == 0,
		"WriterTreeOptions: Node should not be in a property path. (%s)" % leaf.path)
		# 非Node写者必须有属性路径
		assert(leaf.type == WriterTreeOptions.Type.NODE or leaf.path.get_subname_count() > 0,
		"WriterTreeOptions: Non-node should be in a property path. (%s)" % leaf.path)

		if has_children:
			assert(is_instance_valid(tree_opts.children))
			leaf.children = WriterTreeTemplate.new(tree_opts.children)
			leaf.sub_writer = tree_opts.sub_writer
		data[current_data_node_path] = leaf
	if has_properties:
		if not tree_opts.path.is_empty():
			last_ancestor_observe_path = Utils.connect_link_path(last_ancestor_observe_path, tree_opts.path)
			temp_observe_path = ^""
		for key in tree_opts.properties:
			_iterate_property(
				data,
				tree_opts.properties[key],
				Utils.connect_data_node_path(current_data_node_path, NodePath(key)),
				last_ancestor_observe_path,
				Utils.connect_link_path(temp_observe_path, Utils.convert_node_path_into_full_property_path(NodePath(key))),
				force_transform_link_path_into_property if tree_opts.type != WriterTreeOptions.Type.NODE else true,
			)
