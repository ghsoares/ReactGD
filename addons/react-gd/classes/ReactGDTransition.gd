extends Node

class_name ReactGDTransition

var _frames: Array
var _props: Array
var _hash: int
var _current_time: float
var _prev_time: float

func _init() -> void:
	_frames = []
	_props = []
	_hash = 0
	_current_time = 0.0
	_prev_time = 0.0

func one_shot(enable: bool):
	# Even when a transition property don't change, 
	# you can set it to persist based on another value,
	# so it always plays on render
	if !enable:
		_hash = OS.get_ticks_msec()
	else:
		_hash = 0
	return self

func go_towards(
	final_value, duration: float, prop: String = "",
	trans_type: int = 0, ease_type: int = 0
):
	if prop != "" and not prop in _props:
		_props.append(prop)
	
	_frames.append({
		"prop": prop,
		"time": _prev_time,
		"final_value": final_value,
		"duration": duration,
		"trans_type": trans_type,
		"ease_type": ease_type
	})
	_current_time += duration
	_prev_time = _current_time
	return self

func punch(
	peak_value, final_value, duration: float, prop: String = "",
	trans_type: int = 0, ease_type: int = 0
):
	if prop != "" and not prop in _props:
		_props.append(prop)
	
	_frames.append({
		"prop": prop,
		"time": _prev_time,
		"final_value": peak_value,
		"duration": duration * .5,
		"trans_type": trans_type,
		"ease_type": ease_type
	})
	_frames.append({
		"prop": prop,
		"time": _prev_time + duration * .5,
		"final_value": final_value,
		"duration": duration * .5,
		"trans_type": trans_type,
		"ease_type": ease_type
	})
	_current_time += duration
	_prev_time = _current_time
	return self

func shake(
	peak_value1, peak_value2, final_value, cycles: int, duration: float, prop: String = "",
	trans_type: int = 0, ease_type: int = 0
):
	if prop != "" and not prop in _props:
		_props.append(prop)
	
	var spacing := duration / (cycles + 1)
	var inverted := false
	for i in range(cycles):
		_frames.append({
			"prop": prop,
			"time": _prev_time + spacing * i,
			"final_value": peak_value2 if inverted else peak_value1,
			"duration": spacing,
			"trans_type": trans_type,
			"ease_type": ease_type
		})
		inverted = !inverted
	
	_frames.append({
		"prop": prop,
		"time": _prev_time + spacing * cycles,
		"final_value": final_value,
		"duration": spacing,
		"trans_type": trans_type,
		"ease_type": ease_type
	})
	_current_time += duration
	_prev_time = _current_time
	return self

func delay(secs: float):
	_current_time += secs
	_prev_time = _current_time
	return self

func set_time(time: float):
	_current_time = time
	_prev_time = _current_time
	return self

func append(time: float):
	_prev_time = time
	return self

"""
class MyCustomSorter:
	static func sort_ascending(a, b):
		if a[0] < b[0]:
			return true
		return false

var my_items = [[5, "Potato"], [9, "Rice"], [4, "Tomato"]]
my_items.sort_custom(MyCustomSorter, "sort_ascending")
print(my_items) # Prints [[4, Tomato], [5, Potato], [9, Rice]].

"""

static func sort_frames(frame_a: Dictionary, frame_b: Dictionary) -> bool:
	return frame_a.time < frame_b.time







