extends GutTest

const DataNodeBool = Gdvm.DataNodeBool

var bool_node: DataNodeBool

func before_each():
    bool_node = DataNodeBool.new(false)

func test_initialization():
    assert_eq(bool_node.value(), false)
    var true_node = DataNodeBool.new(true)
    assert_eq(true_node.value(), true)

func test_set_valid_values():
    # Test boolean values
    bool_node.render(true)
    assert_eq(bool_node.value(), true)
    
    bool_node.render(false)
    assert_eq(bool_node.value(), false)

    # Test integer conversion
    bool_node.render(1)
    assert_eq(bool_node.value(), true)
    
    bool_node.render(0)
    assert_eq(bool_node.value(), false)

    # Test float conversion
    bool_node.render(1.0)
    assert_eq(bool_node.value(), true)
    
    bool_node.render(0.0)
    assert_eq(bool_node.value(), false)

func test_data_node_conversion():
    var mock_node = DataNodeBool.new(true)
    bool_node.render(mock_node)
    assert_eq(bool_node.value(), true)
    
    mock_node.render(false)
    bool_node.render(mock_node)
    assert_eq(bool_node.value(), false)

func test_get_value():
    bool_node.render(true)
    assert_eq(bool_node.value(), true)
    
    bool_node.render(0)
    assert_eq(bool_node.value(), false)