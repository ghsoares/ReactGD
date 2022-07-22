extends Reference
class_name ReactGDTween

# Tween steps
var steps		:= []

# A variable that tells that tween is valid
var is_valid	:= false

# Set the ease of the tween
func set_ease(ease_type: int = 0):
	steps.append({
		"method": "set_ease",
		"ease": ease_type
	})

	return self

# Set the transition of the tween
func set_trans(trans_type: int = 0):
	steps.append({
		"method": "set_trans",
		"trans": trans_type
	})

	return self

# Tween property
func tween_property(data: Dictionary):
	steps.append({
		"method": "tween_property",
		"property": data.property,
		"final_val": data.final_val,
		"duration": data.duration,
		"as_relative": data.get("as_relative", false),
		"from": data.get("from", null),
		"from_current": data.get("from_current", false),
		"delay": data.get("delay", null),
		"ease": data.get("ease", null),
		"trans": data.get("trans", null)
	})
	is_valid = true
	return self

# Parallel tween
func parallel():
	steps.append({
		"method": "parallel"
	})
	return self

# Apply tween
func apply_tween(node: Node) -> void:
	# If not valid, return
	if not is_valid:
		return

	# Create the tween
	var tw	:= node.create_tween()

	# For each step
	for step in steps:
		# Match the method
		match step.method:
			# Tween property
			"tween_property":
				var tw_prop	:= tw.tween_property(node, step.property, step.final_val, step.duration)
				if step.as_relative:
					tw_prop.as_relative()
				if step.from_current:
					tw_prop.from_current()
				if step.from != null:
					tw_prop.from(step.from)
				if step.delay != null:
					tw_prop.set_delay(step.delay)
				if step.ease != null:
					tw_prop.set_ease(step.ease)
				if step.trans != null:
					tw_prop.set_trans(step.trans)
			# Set ease
			"set_ease":
				tw.set_ease(step.ease)
			# Set transition
			"set_trans":
				tw.set_trans(step.trans)
			# Parallel
			"parallel":
				tw.parallel()