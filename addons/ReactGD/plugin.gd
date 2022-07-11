tool
extends EditorPlugin

# Called when the node enters the tree
func _enter_tree() -> void:
	# Add ReactGD singleton
	add_autoload_singleton("ReactGD", "res://addons/ReactGD/ReactGD.gd")

# Called when the node exits the tree
func _exit_tree() -> void:
	# Remove ReactGD singleton
	remove_autoload_singleton("ReactGD")
