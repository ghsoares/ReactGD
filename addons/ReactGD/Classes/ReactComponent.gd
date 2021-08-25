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

func do_transition():
	return tree.do_transition()

func construct() -> void:
	self.state = {}

func render() -> Dictionary:
	return {}

func get_class() -> String: return "ReactComponent"





