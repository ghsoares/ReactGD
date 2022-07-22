extends Reference
class_name ReactGDTreeData

# The key of the data
var key

# The type of the data
var type

# The properties of the data
var props: Dictionary

# The signals of the data
var signals: Dictionary

# The children of the data
var children: Dictionary

# Create the data
func _init(from: Dictionary = {}) -> void:
	# Get the key
	self.key = from.get("key", null)

	# Get the type
	self.type = from.get("type", null)
	
	# Get the properties
	self.props = from.get("props", {})

	# Get the signals
	self.signals = from.get("signals", {})

	# Get the children
	var children = from.get("children", {})

	# Children is a array
	if children is Array:
		# Create the children dictionary
		self.children = {}

		# The child index
		var idx	:= 0

		# For each child
		for c in children:
			# Get the child key
			var k = c.key

			# Key is null
			if k == null:
				k = idx
			
			# Set the child key
			c.key = str(k)

			# Set the children from key
			self.children[c.key] = c

			# Increment the child index
			idx += 1
	# Children is a dictionary
	elif children is Dictionary:
		self.children = children
