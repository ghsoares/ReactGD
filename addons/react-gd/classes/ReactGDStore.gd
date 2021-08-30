extends Object

class_name ReactGDStore

signal changed

var subscriptions: Array
var reducer_func: FuncRef
var state

func _init(reducer: FuncRef) -> void:
	subscriptions = []
	reducer_func = reducer
	state = reducer.call_func({"type": "", "payload": null})

func dispatch(type: String, payload) -> void:
	state = reducer_func.call_func({"type": type, "payload": payload}, state)
	emit_signal("changed")

func subscribe(obj: Object, signal_name: String) -> void:
	if !is_connected("changed", obj, signal_name):
		connect("changed", obj, signal_name)

func unsubscribe(obj: Object, signal_name: String) -> void:
	if is_connected("changed", obj, signal_name):
		disconnect("changed", obj, signal_name)


