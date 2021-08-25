extends Node

class_name ReactTransition

var data: Dictionary
var curr_time: float

func _init() -> void:
	self.data = {}
	self.curr_time = 0.0

func go_towards(final_val, duration: float, trans_type: int = 0, ease_type: int = 0):
	var size := data.keys().size()
	data[size] = {
		"time": curr_time,
		"final_value": final_val,
		"duration": duration,
		"trans_type": trans_type,
		"ease_type": ease_type
	}
	curr_time += duration
	return self

func shake(
	final_val, peak_min, peak_max, duration: float, cycles: int = 1,
	fade_curve: float = 1.0, trans_type: int = 0, ease_type: int = 0
):
	var size := data.keys().size()
	var spacing := duration / (cycles * 2.0 + 1.0)
	for i in range(0, cycles * 2, 2):
		var t = (i / 2) / float(cycles)
		t = ease(t, fade_curve)
		
		data[size + i] = {
			"time": curr_time,
			"final_value": lerp(peak_max, final_val, t * .5),
			"duration": spacing,
			"trans_type": trans_type,
			"ease_type": ease_type
		}
		curr_time += spacing
		
		data[size + i + 1] = {
			"time": curr_time,
			"final_value": lerp(peak_min, final_val, t * .5),
			"duration": spacing,
			"trans_type": trans_type,
			"ease_type": ease_type
		}
		curr_time += spacing
	
	data[size + cycles * 2] = {
		"time": curr_time,
		"final_value": final_val,
		"duration": spacing,
		"trans_type": trans_type,
		"ease_type": ease_type
	}
	curr_time += spacing
	
	return self

func delay(seconds: float):
	curr_time += seconds
	return self






