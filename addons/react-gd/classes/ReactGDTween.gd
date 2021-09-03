extends Reference
class_name ReactGDTween

# All transition frames
var frames := []
# Current transition time, adds duration for
# each transition command
var curr_time := 0.0
# Current previous transition time, used when need to append
# frames into another time
var prev_time := 0.0
# Current transition velocity, multiplies posterior frames durations to
# that value
var velocity := 1.0
# Persist this tween, even if the transitions frames don't change from
# the previous frame, the tween should play
var persist := false

# All commands returns self instance, so
# transition chaining is supported

"""
To tween command, simply interpolate from current value to target value.
Need to receive:
	- "target": Target final value of the property
	- "duration": Duration of this transition frame
Can receive optionally:
	- "transition": Tween.TRANS_* enum value
	- "ease": Tween.EASE_* enum value
"""
func to(data: Dictionary):
	assert(data.has("target"), "Tween command don't have 'target'")
	assert(data.has("duration"), "Tween command don't have 'duration'")
	
	var target_value = data.target
	var duration = data.duration / velocity
	
	var trans_type = data.get("transition", 0)
	var ease_type = data.get("ease", 0)
	
	frames.append({
		"time": prev_time,
		"duration": duration,
		"target_value": target_value,
		"trans_type": trans_type,
		"ease_type": ease_type
	})
	
	if prev_time == curr_time:
		curr_time += duration
	
	prev_time = curr_time
	
	return self

"""
Punch tween command, interpolates from current value to peak value then back to rest value.
Need to receive:
	- "peak": Peak value of the property
	- "rest": Rest final value of the property
	- "duration": Duration of this transition frame
Can receive optionally:
	- "transition_peak": Tween.TRANS_* enum value for peak value
	- "transition_rest": Tween.TRANS_* enum value for rest value
	- "ease_peak": Tween.EASE_* enum value
	- "ease_rest": Tween.EASE_* enum value
"""
func punch(data: Dictionary):
	assert(data.has("peak"), "Tween command don't have 'peak'")
	assert(data.has("rest"), "Tween command don't have 'rest'")
	assert(data.has("duration"), "Tween command don't have 'duration'")
	
	var peak_value = data.peak
	var rest_value = data.rest
	var duration = data.duration / velocity
	
	var trans_type_peak = data.get("transition_peak", 0)
	var trans_type_rest = data.get("transition_rest", 0)
	var ease_type_peak = data.get("ease_peak", 0)
	var ease_type_rest = data.get("ease_rest", 0)
	# Shorthands
	if data.has("transition"):
		trans_type_peak = data.transition
		trans_type_rest = data.transition
	if data.has("ease"):
		ease_type_peak = data.ease
		ease_type_rest = data.ease
	
	frames.append({
		"time": prev_time,
		"duration": duration * .5,
		"target_value": peak_value,
		"trans_type": trans_type_peak,
		"ease_type": ease_type_peak
	})
	frames.append({
		"time": prev_time + duration * .5,
		"duration": duration * .5,
		"target_value": rest_value,
		"trans_type": trans_type_rest,
		"ease_type": ease_type_rest
	})
	
	if prev_time == curr_time:
		curr_time += duration
	
	prev_time = curr_time
	
	return self

"""
Delay tween command, adds time for the transition.
"""
func delay(time: float):
	curr_time += time / velocity
	prev_time += time / velocity
	return self

"""
Appends delay tween command, adds time for the transition for the next frame.
"""
func append_delay(time: float):
	prev_time += time / velocity
	return self

"""
Set the current transition time.
"""
func time(time: float):
	curr_time = time / velocity
	prev_time = time / velocity
	return self

"""
Append tween command, simply tells that the next frame will be at this time. But
the posterior frames will continue on previous time.
"""
func append(time: float):
	prev_time = time / velocity
	return self

"""
Set current velocity
"""
func velocity(vel: float):
	assert(vel > 0.0, "Velocity can't be less or equal zero.")
	velocity = vel
	return self

"""
Persist tween command
"""
func persist(val: bool = true):
	persist = val
	return self

"""
This function tests if this tween equals to another tween, as objects and Dictionaries
are automatically different if the reference is not equal, even if the contents are semantically
the same.
"""
func equals_tween(other):
	return self.frames.hash() == other.frames.hash() and not self.persist







