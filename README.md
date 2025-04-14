# Godot View Model by GDScript

## 这是啥

一个 Godot 的插件
一个单向数据绑定工具集，可实现MVVM

支持列表！
惰性求值！

**Gdvm现在还处于测试版，API尚未稳定，在1.0发布前的更新都是颠覆性的，慎用！**

## 使用指南

Gdvm分为Core和Binder两个部分，Core提供了最基础的工具，但构建起来比较麻烦，有时实现一个简单功能需要的代码量比直接绑信号还多。

而Binder则是一个框架，可通过更简单的配置直接建立数据映射。

### Core

Gdvm并不包揽整个MVVM，而是重点实现VM，实现数据的单向关联。上游的数据改变，并自动触发下游的更新。

核心工具分为三类：Observer（观察者）、DataNode（数据节点）和Writer（写者）

如果你对性能没有太大要求，你可以直接用DataNode作为你的数据核心，不用Observer，直接修改DataNode即可。

Observer是DataNode观察Godot本身的工具，只要能获取到目标属性，以及更新信号，就可以建立被观察对象到DataNode的更新流。

Writer则是DataNode到Godot本身的更新流。

三者可以建立的关系有：
Observer -> DataNode
DataNode -> Writer
Writer -> DataNode

大多数Observer和Writer对绑定对象和数据节点是弱引用关系，可以尽量减少循环引用。
只需要释放掉Observer和Writer就可以解除绑定关系，**同理，要保持关系一定要用成员变量或者闭包保持对Observer和Writer的引用**。

使用例子见`examples`文件夹的例子以及`tests`文件夹里的测试用例，以后会更新完整的说明文档。

### Binder

Binder可以将特定格式的配置项生成DataNode树和Writer树，建立数据映射。*尚未实现Observer的关联*。


#### 1 最简单的例子

（Binder和Pin是Gdvm的类，Gdvm是名空间，所以使用时要加上`Gdvm.`，或者用常量引用）

```gdscript
var node_1 := Label.new()
var binder_1 := Binder.new(node_1, {
	"data": Pin.new({
		"data": "example_string",
		"path": ":text",
	})
})
```
这里，Binder.new的第一个参数是要绑定的对象，现在已知Label节点有`text`属性，所以需要将Path设置为`:text`。

这里要加`:`，指text是node_1的属性，如果不加，text会被视为是绑定到node_1下的名为`text`子节点。

**绑定节点的name属性可能会导致节点名字改变而无法找到绑定目标，但Gdvm不会禁止你这么做，只要你确定这是安全的就可以。**

`data`代表了要创建节点的默认值，要创建节点的数据类型会根据默认值自动识别，如果没有默认值，则应显式指定一个，设置在`type`属性里。

Gdvm自有一套定义类型的规则，这和Godot原生的有些出入：
1. null为无类型，对应Variant，注意Godot并没有Variant类型的数据，只有Variant类型的变量，当以null作为参数时，不作类型检查
2. int类型是其他原生类型，除了对象，而且在这个规则里，是永远不会取到TYPE_OBJECT的
3. StringName类型，是Godot的原生对象，包括Object本身，都是返回对应的类名字符串
4. Script类型，是派生的对象，不管是脚本文件还是类中类，都是返回对应的Script对象

Utils提供了一系列类型判定和转换的工具，可以看`Utils.gd`文件下的注释。

#### 2 简写
不绑则不需要写path，如果只有data，则可以直接省略掉Pin.new()
```gdscript
Pin.new({
	"data": "example_string",
})
```
等价于
```gdscript
"example_string"
```

#### 3 中继与自动绑叶子

为了不让path写得过长，可以在非叶子节点(data是字典)处绑一个路径，往下的节点只需要写后面的路径。
```gdscript
var binder_1 := Binder.new(node_1, {
	"data": Pin.new({
		"path": "Bar",
		"data": {
			"sub": Pin.new({
				"path": ":text",
				"data": "example_string",
			}),
		},
	})
})
```
这里假设node_1下有一个子节点，名为Bar，在根节点的path下绑定Bar后，后面的`:text`绑定的就是子节点`Bar`里的`text`属性。

同样可以以属性为中继，只需在开头加`:`，即可。假如把`Bar`改成`:abc`，则后面`:text`绑定的就是node_1的`abc`的`text`属性。

#### 4 列表与子写者

Gdvm支持列表，实现了列表元素的生成与销毁。这是用子写者的方式实现的。

要实现这个，你需要定义相关的生成与销毁函数，如果是子节点，可以不定义生成与销毁函数，只需提供一个子节点，Gdvm会自动将。