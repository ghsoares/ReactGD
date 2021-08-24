extends Node

class_name ReactComponent

var id: String
var path: String
var state: Dictionary
var props: Dictionary
var parent_component: Node
var tree

func set_state(new_state: Dictionary) -> void:
	ReactGDDictionaryMethods.merge_dict(state, new_state)
	tree._add_component_to_update(self)

func do_transition(final_val, duration: float, trans_type: int = 0, ease_type: int = 2, delay: float = 0.0):
	return tree.do_transition(final_val, duration, trans_type, ease_type, delay)

func do_shake(peak_val, final_val, duration: float, trans_type: int = 0, ease_type: int = 2, delay: float = 0.0):
	return tree.do_shake(peak_val, final_val, duration, trans_type, ease_type, delay)

func construct() -> void:
	self.state = {}

func render() -> Dictionary:
	return {}

func get_class() -> String: return "ReactComponent"





