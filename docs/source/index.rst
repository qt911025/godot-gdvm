GDVM 文档
=====================

**GDVM** 是基于 **Godot 4 游戏引擎** 的以上版本的MVVM/MVC工具集，实现结构化数据的映射更新。

**GDVM** 主要用于UI的数据映射，却不止用于UI。

**GDVM** 的用法类似古早版本的Vue.js，通过简单的配置建立数据模型与目标对象的绑定。

.. toctree::
   :hidden:
   :maxdepth: 1
   :caption: 简单入门

   getting-started/getting-gdvm
   getting-started/quick-start

.. toctree::
   :hidden:
   :maxdepth: 1
   :caption: 教程

   tutorials/introducing-data-node
   tutorials/introducing-observer
   tutorials/introducing-writer
   tutorials/advanced-data-node
   tutorials/advanced-observer
   tutorials/advanced-writer
   tutorials/binding
   tutorials/binding-data-tree
   tutorials/binding-observer-pack
   tutorials/binding-writer-pack

.. toctree::
   :hidden:
   :maxdepth: 1
   :caption: API

   api/data-node

.. toctree::
   :hidden:
   :maxdepth: 1
   :caption: 原理
   :glob:

   theory/tree-like-data-structure
   theory/relationship
   theory/gdvm-style-data-type
   theory/extendable-observer-and-writer-pack
   theory/tips-about-two-way-data-binding