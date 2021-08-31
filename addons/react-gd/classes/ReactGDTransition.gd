extends Object

class_name ReactGDTransition

var _frames: Array
var _props: Array
var _hash: int
var _velocity: float
var _current_time: float
var _prev_time: float

func _init() -> void:
	_frames = []
	_props = []
	_hash = 0
	_velocity = 1.0
	_current_time = 0.0
	_prev_time = 0.0

func go_to(data: Dictionary):
	var target = data.target
	var duration :float = data.duration
	var prop :String = data.get("prop", "")
	var trans_type :int = data.get("trans_type", 0)
	var ease_type :int = data.get("ease_type", 0)
	
	if prop != "" and not prop in _props:
		_props.append(prop)
	
	duration /= _velocity
	
	_frames.append({
		"prop": prop,
		"time": _prev_time,
		"final_value": target,
		"duration": duration,
		"trans_type": trans_type,
		"ease_type": ease_type
	})
	_current_time += duration
	_prev_time = _current_time
	return self

func punch(data: Dictionary):
	var peak = data.peak
	var target = data.target
	var duration :float = data.duration
	var prop :String = data.get("prop", "")
	var trans_type :int = data.get("trans_type", 0)
	var ease_type :int = data.get("ease_type", 0)
	
	if prop != "" and not prop in _props:
		_props.append(prop)
	
	duration /= _velocity
	
	_frames.append({
		"prop": prop,
		"time": _prev_time,
		"final_value": peak,
		"duration": duration * .5,
		"trans_type": trans_type,
		"ease_type": ease_type
	})
	_frames.append({
		"prop": prop,
		"time": _prev_time + duration * .5,
		"final_value": target,
		"duration": duration * .5,
		"trans_type": trans_type,
		"ease_type": ease_type
	})
	_current_time += duration
	_prev_time = _current_time
	return self

func shake(data: Dictionary):
	var peak_min = data.peak_min
	var peak_max = data.peak_max
	var target = data.target
	var duration :float = data.duration
	var cycles :int = data.get("cycles", 1)
	var fade_curve :float = data.get("fade_curve", 1.0)
	var prop :String = data.get("prop", "")
	var trans_type :int = data.get("trans_type", 0)
	var ease_type :int = data.get("ease_type", 0)
	
	if prop != "" and not prop in _props:
		_props.append(prop)
	
	duration /= _velocity
	
	var spacing := duration / (cycles + 1)
	var is_max := true
	
	for i in range(cycles + 1):
		var t = float(i) / cycles
		var peak = peak_max if is_max else peak_min
		_frames.append({
			"prop": prop,
			"time": _prev_time + spacing * i,
			"final_value": lerp(peak, target, t),
			"duration": spacing,
			"trans_type": trans_type,
			"ease_type": ease_type
		})
		is_max = !is_max
	
	_current_time += duration
	_prev_time = _current_time
	return self

func delay(secs: float):
	_current_time += secs / _velocity
	_prev_time = _current_time
	return self

func time(time: float):
	_current_time = time / _velocity
	_prev_time = _current_time
	return self

func append(time: float):
	_prev_time = time / _velocity
	return self

func velocity(vel: float):
	_velocity = vel
	return self

func persist(enable: bool):
	# Even when a transition property don't change, 
	# you can set it to persist based on another value,
	# so it always plays on render
	if enable:
		_hash = OS.get_ticks_msec()
	else:
		_hash = 0
	return self

static func sort_frames(frame_a: Dictionary, frame_b: Dictionary) -> bool:
	return frame_a.time < frame_b.time







