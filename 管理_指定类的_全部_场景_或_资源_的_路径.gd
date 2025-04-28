## 提供用于管理和操作继承自指定类的场景或资源的编辑器下文件路径或指定起始节点下节点路径的工具方法。
## 注意： 该工具仅适用于文件名与类名一致的类。
## 注意： 类名大小写敏感，大小写错误会直接导致继承检查失败。
class_name 管理_指定类的_全部_场景_或_资源_的_路径

const 每帧_操作次数:=42
const 扫描时_忽略隐藏目录:= true


#region 主要方法

static func 打印_指定目录下_指定类_及其派生类_文件的_路径(类名: String, 是_场景: bool = true, 检查根目录: String = "res://"):
	if 类名.is_empty():
		push_warning("请先设置要查找的类名")
		return
	
	var 文件列表 = 获取_指定目录下_指定类_及其派生类_文件的_路径(类名, 是_场景,检查根目录)
	if 文件列表.is_empty():
		print("未找到继承自 %s 的 %s 文件" % [类名, ".tscn" if 是_场景 else ".tres"])
	else:
		print("找到 %d 个继承自 %s 的 %s 文件:" % [文件列表.size(), 类名, ".tscn" if 是_场景 else ".tres"])
		for 文件路径 in 文件列表:
			print(" - ", 文件路径)

# 保存为JSON文件功能
static func 保存为_JSON文件(类名: String, 是_场景: bool = true, 文件名_去除_后缀: bool = true, 保存文件名: String ="", 保存目录: String = "", 检查根目录: String = "res://"):
	if 类名 == null or 类名.is_empty():
		push_error("获取_所有派生类文件的_路径失败: 参数'基类'为null或空字符串")
	if 保存文件名 == null or 保存文件名.is_empty():
		push_error("获取_所有派生类文件的_路径失败: 参数'保存文件名'为null或空字符串")
	if 保存目录 == null or 保存目录.is_empty():
		push_error("获取_所有派生类文件的_路径失败: 参数'保存目录'为null或空字符串")
	
	if not DirAccess.dir_exists_absolute(保存目录):
		push_error("文件将保存到的目录并不存在，请先设置要保存的位置")
		return
	if 类名.is_empty():
		push_warning("请先设置要查找的类名")
		return
	
	var 文件列表 = 获取_指定目录下_指定类_及其派生类_文件的_路径(类名, 是_场景, 检查根目录)
	if 文件列表.is_empty():
		push_warning("未找到可保存的文件")
		return
	
	var 路径字典 = {}
	for 文件路径 in 文件列表:
		var 文件名 = 文件路径.get_file()
		# 根据设置处理文件名
		if 文件名_去除_后缀:  # 去除后缀
			文件名 = 文件名.get_basename()
		路径字典[文件名] = 文件路径
	
	var 保存路径 = 保存目录.path_join(保存文件名)
	var 文件 = FileAccess.open(保存路径, FileAccess.WRITE)
	if 文件:
		文件.store_string(JSON.stringify(路径字典, "\t"))
		文件.close()
		print("文件路径字典已保存到: %s" % 保存路径)
	else:
		push_error("无法保存文件到: %s" % 保存路径)


## 获取场景中所有继承自指定类的节点路径
## 参数：
##   - 基类名: 要查找的基类名称（String）
##   - 场景根节点: 从哪个节点开始搜索（Node），默认为当前场景根
##   - 特定路径: 只搜索该节点路径下的子节点（String），默认为空表示全场景
## 返回：包含所有匹配节点路径的数组（Array[String]）
static func 获取_指定节点下_所有_指定类_及其派生类_节点的_路径(基类名: String, 起始节点: Node) -> Array[String]:
	var 结果路径数组: Array[String] = []
	
	if not 起始节点:
		push_error("起始节点为 null，请检查输入")
		return 结果路径数组

	# 递归遍历场景树
	var _遍历节点 :=(
		func(当前节点: Node, 递归自身: Callable):
			if _检查_场景_继承链(当前节点, 基类名):
				var 节点路径 = 当前节点.get_path()
				结果路径数组.append(str(节点路径))

			for 子节点 in 当前节点.get_children():
				递归自身.call(子节点, 递归自身)
			)

	_遍历节点.call(起始节点, _遍历节点)
	return 结果路径数组


## 获取指定根目录（默认为“res://”文件夹）下所有继承自指定类的文件。
## 是_场景 为true时，查询场景(PackedScene)，否则查询资源(Resource)，不可混淆。
static func 获取_指定目录下_指定类_及其派生类_文件的_路径(基类: String, 是_场景: bool = true, 根目录: String = "res://") -> Array[String]:
	if 基类 == null or 基类.is_empty():
		push_error("获取_所有派生类文件的_路径失败: 参数'基类'为null或空字符串")
	
	var 结果: Array[String] = []
	var 文件列表: Array[String] = []
	
	# 递归扫描指定的根目录(默认为“res://”目录)
	_扫描目录(根目录, 文件列表)
	
	for 文件_路径 in 文件列表:
		if (是_场景 and !文件_路径.ends_with(".tscn")) or (!是_场景 and !文件_路径.ends_with(".tres")):
			continue
			
		var 资源 = ResourceLoader.load(文件_路径)
		if not 资源:
			continue
			
		# 处理场景文件
		if 是_场景 and 资源 is PackedScene:
			var 实例 = 资源.instantiate()
			if _检查_场景_继承链(实例, 基类):
				结果.append(文件_路径)
			实例.queue_free()
		
		# 处理资源文件
		elif !是_场景 and 资源 is Resource:
			if _检查_资源_继承链(资源, 基类):
				结果.append(文件_路径)

	return 结果

#endregion


#region 异步方法

static func 异步_打印_指定目录下_指定类_及其派生类_文件的_路径(类名: String, 是_场景: bool = true, 检查根目录: String = "res://"):
	if 类名.is_empty():
		push_warning("请先设置要查找的类名")
		return

	var 文件列表 = await 异步_获取_指定目录下_指定类_及其派生类_文件的_路径(类名, 是_场景, 检查根目录)
	if 文件列表.is_empty():
		print("未找到继承自 %s 的 %s 文件" % [类名, ".tscn" if 是_场景 else ".tres"])
	else:
		print("找到 %d 个继承自 %s 的 %s 文件:" % [文件列表.size(), 类名, ".tscn" if 是_场景 else ".tres"])
		for i in 文件列表.size():
			print(" - ", 文件列表[i])
			if i % 每帧_操作次数 == 0:
				await HistoriaRivero.帧_更新


static func 异步_打印_指定节点下_所有_指定类_及其派生类_节点的_路径(类名: String, 起始节点: Node):
	if 类名.is_empty():
		push_warning("请先设置要查找的类名")
		return

	var _节点路径列表 := await 异步_获取_指定节点下_所有_指定类_及其派生类_节点的_路径(类名, 起始节点)
	if _节点路径列表.is_empty():
		print_rich("[color=gray]未找到任何节点[/color]")
		return

	# 构建树状结构：每层是 { "子节点名": { "_打印": bool, "children": {} } }
	var 树状结构 = {}

	for _节点路径 in _节点路径列表:
		var 路径部分 = _节点路径.split("/", false)
		var 当前层级 = 树状结构

		for i in range(路径部分.size()):
			var 部分 = 路径部分[i]
			if 部分.is_empty():
				continue

			if not 当前层级.has(部分):
				当前层级[部分] = {"_打印": false, "_路径": "/".join(路径部分.slice(0, i+1))}
			
			# 如果是目标节点，标记为可打印
			if i == 路径部分.size() - 1:
				当前层级[部分]["_打印"] = true

			# 进入下一层
			if not 当前层级[部分].has("children"):
				当前层级[部分]["children"] = {}
			当前层级 = 当前层级[部分]["children"]

	# 彩色打印函数
	var 打印树 := func(子树: Dictionary, 缩进: String, 递归自身: Callable):
		var 键列表 = 子树.keys()
		键列表.sort()
		var 总数 := 键列表.size()

		for i in range(总数):
			var 键 = 键列表[i]
			if 键 in ["_打印", "_路径", "children"]:
				continue
				
			var 节点信息 = 子树[键]
			var 是最后 = (i == 总数 - 1)
			var 前缀 = 缩进 + ("└── " if 是最后 else "├── ")
			
			# 彩色输出
			if 节点信息.get("_打印", false):
				print_rich(前缀 + "[color=white]" + 键 + "[/color]")
			else:
				print_rich(前缀 + "[color=web_gray]" + 键 + "[/color]")

			var 新缩进 = 缩进 + ("    " if 是最后 else "│   ")
			递归自身.call(节点信息.get("children", {}), 新缩进, 递归自身)
	
	print_rich("[color=yellow]🌳 节点结构:[/color]")
	await 打印树.call(树状结构, "", 打印树)

	print_rich("\n[color=yellow]🧾 所有匹配的节点路径:[/color]")
	for i in range(_节点路径列表.size()):
		print_rich(" - [color=white]" + _节点路径列表[i] + "[/color]")


static func 异步_保存为_JSON文件(类名: String, 是_场景: bool = true, 文件名_去除_后缀: bool = true, 保存文件名: String = "", 保存目录: String = "", 检查根目录: String = "res://"):
	if 类名 == null or 类名.is_empty():
		push_error("获取_所有派生类文件的_路径失败: 参数'基类'为null或空字符串")
		return
	if 保存文件名 == null or 保存文件名.is_empty():
		push_error("获取_所有派生类文件的_路径失败: 参数'保存文件名'为null或空字符串")
		return
	if 保存目录 == null or 保存目录.is_empty():
		push_error("获取_所有派生类文件的_路径失败: 参数'保存目录'为null或空字符串")
		return

	if not DirAccess.dir_exists_absolute(保存目录):
		push_error("文件将保存到的目录并不存在，请先设置要保存的位置")
		return
	if 类名.is_empty():
		push_warning("请先设置要查找的类名")
		return

	var 文件列表 = await 异步_获取_指定目录下_指定类_及其派生类_文件的_路径(类名, 是_场景, 检查根目录)
	if 文件列表.is_empty():
		push_warning("未找到可保存的文件")
		return

	var 路径字典 = {}
	for i in 文件列表.size():
		var 文件路径 = 文件列表[i]
		var 文件名 = 文件路径.get_file()
		if 文件名_去除_后缀:
			文件名 = 文件名.get_basename()
		路径字典[文件名] = 文件路径

		if i % 每帧_操作次数 == 0:
			await HistoriaRivero.帧_更新

	var 保存路径 = 保存目录.path_join(保存文件名)
	var 文件 = FileAccess.open(保存路径, FileAccess.WRITE)
	if 文件:
		文件.store_string(JSON.stringify(路径字典, "\t"))
		文件.close()
		print("文件路径字典已保存到: %s" % 保存路径)
	else:
		push_error("无法保存文件到: %s" % 保存路径)


static func 异步_获取_指定节点下_所有_指定类_及其派生类_节点的_路径(基类名: String, 起始节点: Node) -> Array[String]:
	var 结果路径数组: Array[String] = []

	if not 起始节点:
		push_error("起始节点为 null，请检查输入")
		return 结果路径数组

	var _节点数引用 :Array[int]= [0]

	var _遍历节点 := (
		func(当前节点: Node, 递归自身: Callable):
			if _检查_场景_继承链(当前节点, 基类名):
				var 节点路径 = 当前节点.get_path()
				结果路径数组.append(str(节点路径))

			_节点数引用[0] = _节点数引用[0] + 1
			if _节点数引用[0] % 每帧_操作次数 == 0:
				await HistoriaRivero.帧_更新

			for 子节点 in 当前节点.get_children():
				await 递归自身.call(子节点, 递归自身)
	)

	await _遍历节点.call(起始节点, _遍历节点)
	return 结果路径数组


static func 默认_筛选器_全选(_文件路径: String)->bool:
	return true


static func 异步_获取_指定目录下_指定类_及其派生类_文件的_路径(基类: String, 是_场景: bool = true, 根目录: String = "res://", 数量限制: int = -1, 筛选:Callable = 默认_筛选器_全选) -> PackedStringArray:
	var _已获取数量:= 0
	var 结果: Array[String] = []
	var 文件列表: Array[String] = []

	_扫描目录(根目录, 文件列表)

	for i in 文件列表.size():
		var 文件_路径 = 文件列表[i]
		if (是_场景 and !文件_路径.ends_with(".tscn")) or (!是_场景 and !文件_路径.ends_with(".tres")):
			continue

		var 资源 = ResourceLoader.load(文件_路径)
		if not 资源:
			continue

		if 是_场景 and 资源 is PackedScene:
			var 实例 = 资源.instantiate()
			if _检查_场景_继承链(实例, 基类):
				if 筛选 == 默认_筛选器_全选:
					结果.append(文件_路径)
					_已获取数量 += 1
				else:
					if not 筛选.call(文件_路径):
						continue
					结果.append(文件_路径)
					_已获取数量 += 1
					
		elif !是_场景 and 资源 is Resource:
			if _检查_资源_继承链(资源, 基类):
				if 筛选 == 默认_筛选器_全选:
					结果.append(文件_路径)
					_已获取数量 += 1
				else:
					if not 筛选.call(文件_路径):
						continue
					结果.append(文件_路径)
					_已获取数量 += 1
		
		if _已获取数量 >= 数量限制:
			break

		if i % 每帧_操作次数 == 0:
			await HistoriaRivero.帧_更新
	# if 数量限制 > 0: print_rich("[color=royal_blue]本次 异步_获取_指定目录下_指定类_及其派生类_文件的_路径 具有数量限制：%s[/color]"%数量限制)
	return 结果

#endregion


#region 辅助方法

# 递归扫描目录
static func _扫描目录(当前路径: String, 文件列表: Array[String]):
	if 扫描时_忽略隐藏目录 and (当前路径.split("/") as Array).any(func(dir:String):return dir.begins_with(".")):
		return

	var _路径列表 := ResourceLoader.list_directory(当前路径)
	if not _路径列表:
		push_warning("执行_扫描目录 失败: 无法打开目录 或 目录为空: %s" % 当前路径)
		return

	for _路径: String in _路径列表:
		var _完整路径 := 当前路径.path_join(_路径)
		if _路径.ends_with("/") and DirAccess.dir_exists_absolute(_完整路径):
			_扫描目录(_完整路径, 文件列表)
		else:
			文件列表.append(_完整路径)


# 检查对象的继承关系（用于场景实例）
static func _检查_场景_继承链(对象: Object, 基类名: String) -> bool:
	var 脚本 = 对象.get_script()
	#这一段没必要启用，启用后反而可能导致未挂载脚本的默认类型（如Control）节点的子节点被忽略。
	# if not 脚本:
	#     push_error("_检查_场景_继承链 失败: %s 的 %s 的脚本不存在，无法检查继承链。"%[(对象 as Node).scene_file_path ,对象])
	#     return false
	while 脚本:
		if 脚本.resource_path.ends_with("/%s.gd" % 基类名):
			return true
		if 脚本 and 脚本.has_method("get_base_script"):
			脚本 = 脚本.get_base_script()
		else:
			break
	
	# 检查原生类继承
	var 当前类 = 对象.get_class()
	while 当前类 != "":
		if 当前类 == 基类名:
			return true
		当前类 = ClassDB.get_parent_class(当前类)
	
	return false


# 检查资源的继承关系（用于资源文件）
static func _检查_资源_继承链(_资源: Resource, 基类名: String) -> bool:
	# 首先检查脚本继承
	var 脚本 = _资源.get_script()
	#这一段没必要启用，启用后反而可能导致未挂载脚本的默认类型（如Control）节点的子节点被忽略。
	# if not 脚本:
	#     push_error("_检查_场景_继承链 失败: %s 的 %s 的脚本不存在，无法检查继承链。"%[(对象 as Node).scene_file_path ,对象])
	#     return false
	while 脚本:
		if 脚本.resource_path.ends_with("/%s.gd" % 基类名):
			return true
		if 脚本 and 脚本.has_method("get_base_script"):
			脚本 = 脚本.get_base_script()
	
	# 检查资源本身的类继承
	var _资源类 = _资源.get_class()
	while _资源类 != "":
		if _资源类 == 基类名:
			return true
		_资源类 = ClassDB.get_parent_class(_资源类)
	
	return false

#endregion
