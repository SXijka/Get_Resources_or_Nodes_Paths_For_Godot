extends Node

## 仅仅是为了方便静态方法无需调用get_tree().process_frame便能直接获取物理帧更新消息。
signal 物理帧_更新

## 仅仅是为了方便静态方法无需调用get_tree().process_frame便能直接获取物理帧更新消息。
signal 帧_更新


func _ready() -> void:
    _更新_HistoriaRivero内_定义的_物理帧_及_帧_更新信号()


func _更新_HistoriaRivero内_定义的_物理帧_及_帧_更新信号()->void:

    var 更新_物理帧信号 := func()->void:物理帧_更新.emit()
    var 更新_帧信号 := func()->void:帧_更新.emit()

    if (not get_tree().process_frame.is_connected(更新_帧信号)):
        get_tree().process_frame.connect(更新_帧信号)
    if (not get_tree().physics_frame.is_connected(更新_物理帧信号)):
        get_tree().process_frame.connect(更新_物理帧信号)