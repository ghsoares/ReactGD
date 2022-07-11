extends Node
class_name ReactGDNode

# Previous render data
var __render_data: Dictionary

# Is dirty
var __dirty: bool

# The tree root
var __root: Node

# The actual parent
var __parent: Node

# The actual node
var __node: Node

# The node tween
var __tw: SceneTreeTween

# Called when this node is initialized
func _init() -> void:
	# Set render data to empty dictionary
	__render_data = {}

	# Set dirty to true
	__dirty = true

# Called when this node receives a notification
func _notification(what: int) -> void:
	# Check the notification type
	match what:
		# Ready
		NOTIFICATION_READY:
			__ready()
		# Process
		NOTIFICATION_PROCESS:
			__process()

# Internal function called when the node is ready
func __ready() -> void:
	
	pass

# Internal function called when the node is processed
func __process() -> void:
	pass
