extends Node

class_name ReactComponent

var id: String
var state: Dictionary
var props: Dictionary
var parent_component
var tree

func set_state(new_state: Dictionary) -> void:
	ReactGDDictionaryMethods.merge_dict(state, new_state)
	tree.set_dirty()

func construct() -> void:
	self.state = {}
	self.props = {}

func render() -> Dictionary:
	return {}

func get_class() -> String: return "ReactComponent"

