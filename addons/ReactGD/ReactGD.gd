tool
extends Node

# Creates a react node tree from a base node
func create_tree(base_node: Node) -> ReactGDNodeTree:
	# Creates the instance
	var tree	:= ReactGDNodeTree.new()

	# Set the node tree base node
	tree.base_node = base_node

	# Assign to the tree root
	get_tree().root.call_deferred("add_child", tree, true)

	# Return the instance
	return tree

# Deletes a react node tree
func free_tree(tree: ReactGDNodeTree) -> void:
	# Just queue free it
	tree.queue_free()
