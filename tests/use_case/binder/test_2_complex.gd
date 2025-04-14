extends GutTest
const Binder = Gdvm.Binder
const Pin = Gdvm.Pin

const DataNode = Gdvm.DataNode
const DataNodeList = Gdvm.DataNodeList
const DataNodeString = Gdvm.DataNodeString

class ObjWithArray:
	var array: Array

class SampleObj:
	var data: String = "init_data"

func test_bind_object_list_simple() -> void:
	var obj_1 := ObjWithArray.new()
	var binder := Binder.new(obj_1, {
		"data": Pin.new({
			"path": ":array",
			"data": ["example_string"],
		})
	})
	assert_true(binder.data is Gdvm.DataNodeList)
	assert_eq(binder.data.size(), 0)
	assert_eq(obj_1.array, [])
	binder.data.append_array(["foo", "bar"])
	assert_eq(binder.data.size(), 2)
	assert_eq_deep(binder.data.value(), ["foo", "bar"])
	assert_eq_deep(obj_1.array, ["foo", "bar"])

func test_bind_object_packed_list() -> void:
	var obj_1 := ObjWithArray.new()
	var binder := Binder.new(obj_1, {
		"data": Pin.new({
			"path": ":array",
			"data": PackedStringArray(),
		})
	})
	assert_true(binder.data is Gdvm.DataNodeList)
	assert_eq(binder.data.size(), 0)
	assert_eq(obj_1.array, [])
	binder.data.append_array(["foo", "bar"])
	assert_eq(binder.data.size(), 2)
	assert_eq_deep(binder.data.value(), ["foo", "bar"])
	assert_eq(obj_1.array.size(), 2)
	assert_eq_deep(obj_1.array, ["foo", "bar"])

func test_bind_object_list_with_object() -> void:
	var obj_1 := ObjWithArray.new()
	var binder := Binder.new(obj_1, {
		"data": Pin.new({
			"path": ":array",
			"data": [Pin.new({
				"type": TYPE_STRING,
				"alloc": func(source_data_node: DataNode) -> Object:
					var result := SampleObj.new()
					result.data = (source_data_node as DataNodeString).value()
					return result
					,
			})],
		})
	})
	assert_true(binder.data is Gdvm.DataNodeList)
	assert_eq(binder.data.size(), 0)
	assert_eq(obj_1.array, [])
	binder.data.append_array(["foo", "bar"])
	assert_eq(binder.data.size(), 2)
	assert_eq_deep(binder.data.value(), ["foo", "bar"])
	assert_eq(obj_1.array.size(), 2)
	assert_eq(obj_1.array[0].data, "foo")
	assert_eq(obj_1.array[1].data, "bar")

func test_bind_node() -> void:
	var node_1 := Control.new()
	node_1.name = "Foo"
	var node_2 := Label.new()
	node_2.name = "Bar"
	node_1.add_child(node_2)
	var binder := Binder.new(node_1, {
		"data": Pin.new({
			"data": [Pin.new({
				"pin_leaf_properties": true,
				"data": {
					"text": "example_string",
					"lang": Pin.new({
						"path": ":language",
						"data": "zh_Hans_CN",
					}),
				}
			})],
		})
	})
	assert_true(binder.data is DataNodeList)
	var root_dn := binder.data as DataNodeList
	assert_eq(root_dn.size(), 0)
	assert_eq(node_1.get_child_count(), 0)
	# assert_eq(is_instance_valid(node_2), false)
	binder.data.append_array([ {
		"text": "哇",
		"lang": "zh_Hans_CN",
	}, {
		"text": "Waaaagh",
		"lang": "en_US",
	}])
	assert_true(binder.data.get_element_nodes()[0] is Gdvm.DataNodeStruct)
	assert_eq(node_1.get_child_count(), 2)
	assert_eq(node_1.get_child(0).text, "哇")
	assert_eq(node_1.get_child(0).language, "zh_Hans_CN")
	assert_eq(node_1.get_child(1).text, "Waaaagh")
	assert_eq(node_1.get_child(1).language, "en_US")
	autoqfree(node_1)
