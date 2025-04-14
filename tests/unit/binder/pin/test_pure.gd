extends GutTest

const Utils = Gdvm.Utils

const PurePin = preload("res://addons/gdvm/binder/pin/pure.gd")
const RawPin = Gdvm.Pin
const DataNodeVariant = Gdvm.DataNodeVariant
const DataNodeString = Gdvm.DataNodeString
const DataNodeStruct = Gdvm.DataNodeStruct
const DataNodeList = Gdvm.DataNodeList
const DataNodeNode = Gdvm.DataNodeNode

# var test_pin: PurePin
# var test_raw_pin: RawPin

# func before_each():
# 		test_pin = PurePin.new()
# 		test_raw_pin = RawPin.new({
# 			data = "test_data"
# 		})

func test_build_variant_type():
	var rc := RefCounted.new()
	var pin := RawPin.build(rc)
	var result := PurePin.build(pin)
	assert_true(result is PurePin.PurePinVariant)
	assert_true(result.to_data_node() is DataNodeVariant)

func test_build_strict_type():
	var pin := RawPin.build("example_string")
	var result := PurePin.build(pin)
	assert_true(result is PurePin.PurePinStrict)
	assert_true(result.to_data_node() is DataNodeString)

func test_build_struct_type():
	var pin := RawPin.build({
		"foo": 42,
	})
	var result := PurePin.build(pin)
	assert_true(result is PurePin.PurePinStruct)
	assert_true(result.to_data_node() is DataNodeStruct)

func test_build_list_type():
	var pin := RawPin.build([1])
	var result := PurePin.build(pin)
	assert_true(result is PurePin.PurePinList)
	assert_true(result.to_data_node() is DataNodeList)

func test_build_node_type():
	var pin := RawPin.new({
		"properties": {
			"foo": 42,
		},
		"children": [1],
	})
	var result := PurePin.build(pin)
	assert_true(result is PurePin.PurePinNode)
	assert_true(result.to_data_node() is DataNodeNode)
