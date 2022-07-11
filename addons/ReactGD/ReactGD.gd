tool
extends Node

# Create a react node tree
func create_tree(node: Node) -> ReactGDVirtualNodeTree:
	# Create the tree
	var tree	:= ReactGDVirtualNodeTree.new(node)

	# Add as child of node
	node.add_child(tree, true)
	
	# Return the tree
	return tree


