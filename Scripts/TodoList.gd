tool
extends ReactComponent

const fonts_path := "res://Fonts/JetBrains/fonts/ttf/"
const font_jetbrains_regular := "res://Fonts/JetBrains/fonts/ttf/JetBrainsMono-Regular.ttf"
const font_jetbrains_bold := "res://Fonts/JetBrains/fonts/ttf/JetBrainsMono-Bold.ttf"
const font_jetbrains_light := "res://Fonts/JetBrains/fonts/ttf/JetBrainsMono-Light.ttf"
const font_jetbrains_extrabold := "res://Fonts/JetBrains/fonts/ttf/JetBrainsMono-ExtraBold.ttf"

class InputField:
	tool
	extends ReactComponent
	
	var theming := {
		"input_field": {
			"styles": {
				["normal", StyleBoxFlat]: {
					"bg_color": Color(0.439216, 0.337255, 0.556863, 0),
					"border_width": 2.0,
					"border_color": Color(0.439216, 0.337255, 0.556863),
					"corner_radius": 4.0,
					"content_margin_horizontal": 16.0,
					"content_margin_vertical": 8.0
				},
			},
			"fonts": {
				"font": {
					"size": 16.0,
					"use_filter": true,
					"src": font_jetbrains_regular
				}
			}
		},
		"add_button": {
			"colors": {
				"font_color": Color.black,
				"font_color_hover": Color.black,
				"font_color_pressed": Color.black
			},
			"styles": {
				["normal", StyleBoxFlat]: {
					"bg_color": Color(0.439216, 0.337255, 0.556863),
					"corner_radius": 8.0
				},
				["hover", StyleBoxFlat]: {
					"bg_color": Color(0.439216, 0.337255, 0.556863),
					"corner_radius": 8.0
				},
				["pressed", StyleBoxFlat]: {
					"bg_color": Color(0.439216, 0.337255, 0.556863),
					"corner_radius": 8.0
				}
			},
			"fonts": {
				"font": {
					"size": 24.0,
					"use_filter": true,
					"src": font_jetbrains_bold
				}
			}
		}
	}
	var input_field: LineEdit
	
	signal task_add(task_name)
	
	func on_button_pressed() -> void:
		var task_name := input_field.text
		if task_name == "": return
		emit_signal("task_add", task_name)
		input_field.text = ""
	
	"""
	func render() -> Dictionary:
		return {
			[LineEdit, "InputField"]: {
				"props": {
					"placeholder_text": "Insert task title here",
					"size_flags_horizontal": Control.SIZE_EXPAND_FILL
				},
				"ref": "input_field",
				"theme": theming.input_field
			},
			[Control, "Separator"]: {
				"props": {
					"rect_min_size": Vector2(16.0, 0.0)
				}
			},
			[Button, "AddButton"]: {
				"props": {
					"text": "+",
					"rect_min_size": Vector2(40.0, 40.0),
					"size_flags_vertical": Control.SIZE_SHRINK_CENTER
				},
				"signals": {
					"pressed": "on_button_pressed"
				},
				"theme": theming.add_button
			}
		}
	"""
	static func get_base(): return HBoxContainer

class Task:
	tool
	extends ReactComponent
	
	signal task_done_toggle(id, val)
	signal task_remove(id)
	
	var theming := {
		"task_number": {
			"fonts": {
				"font": {
					"size": 16.0,
					"use_filter": true,
					"src": font_jetbrains_light
				}
			}
		},
		"checkbox": {
			"styles": {
				["normal", StyleBoxFlat]: {
					"bg_color": Color(0.439216, 0.337255, 0.556863, 0),
					"border_width": 2.0,
					"border_color": Color(0.439216, 0.337255, 0.556863),
					"corner_radius": 4.0
				},
				["pressed", StyleBoxFlat]: {
					"bg_color": Color(0.439216, 0.337255, 0.556863, 1.0),
					"border_width": 2.0,
					"border_color": Color(0.439216, 0.337255, 0.556863),
					"corner_radius": 4.0
				},
				["hover", StyleBoxFlat]: {
					"bg_color": Color(0.439216, 0.337255, 0.556863, 0.5),
					"border_width": 2.0,
					"border_color": Color(0.439216, 0.337255, 0.556863),
					"corner_radius": 4.0
				},
			}
		},
		"task_name": {
			"fonts": {
				"font": {
					"size": 16.0,
					"use_filter": true,
					"src": font_jetbrains_light
				}
			}
		},
		"remove_button": {
			"styles": {
				["normal", StyleBoxFlat]: {
					"bg_color": Color(0.631373, 0.168627, 0.309804),
					"corner_radius": 4.0
				},
				["pressed", StyleBoxFlat]: {
					"bg_color": Color(0.466667, 0.117647, 0.356863),
					"corner_radius": 4.0
				},
				["hover", StyleBoxFlat]: {
					"bg_color": Color(0.929412, 0.160784, 0.396078),
					"corner_radius": 4.0
				}
			}
		}
	}
	
	var task_id: int
	var task_name: String
	var task_done: bool
	
	func on_task_done_toggle(val: bool) -> void:
		emit_signal("task_done_toggle", task_id, val)
	
	func on_task_remove() -> void:
		emit_signal("task_remove", task_id)
	
	"""
	func render() -> Array:
		return {
			[HBoxContainer, "HBox"]: {
				"children": {
					[Label, "Number"]: {
						"props": {
							"text": str(task_id + 1)
						},
						"theme": theming.task_number
					},
					[Control, "Separator1"]: {
						"props": {
							"rect_min_size": Vector2(8, 0)
						}
					},
					[Button, "CheckBox"]: {
						"props": {
							"toggle_mode": true,
							"pressed": task_done,
							"rect_min_size": Vector2(22, 22)
						},
						"signals": {
							"toggled": "on_task_done_toggle"
						},
						"theme": theming.checkbox
					},
					[Control, "Separator2"]: {
						"props": {
							"rect_min_size": Vector2(8, 0)
						}
					},
					[Label, "TaskName"]: {
						"props": {
							"size_flags_horizontal": Control.SIZE_EXPAND_FILL,
							"text": task_name
						},
						"theme": theming.task_name
					},
					[Button, "RemoveButton"]: {
						"props": {
							"text": "X",
							"rect_min_size": Vector2(22, 22),
							"visible": task_done
						},
						"signals": {
							"pressed": "on_task_remove"
						},
						"theme": theming.remove_button
					}
				}
			}
		}
	"""
	
	static func get_base(): return PanelContainer

var theming := {
	"title1": {
		"fonts": {
			"font": {
				"size": 24.0,
				"use_filter": true,
				"src": fonts_path + "JetBrainsMono-ExtraBold.ttf"
			}
		}
	},
	"title2": {
		"fonts": {
			"font": {
				"size": 20.0,
				"use_filter": true,
				"src": fonts_path + "JetBrainsMono-Bold.ttf"
			}
		}
	},
	"task_frame": {
		"styles": {
			["panel", StyleBoxFlat]: {
				"bg_color": Color(0.141176, 0.121569, 0.2),
				"corner_radius": 8.0,
				"content_margin": 8.0
			}
		},
	},
	"empty_list": {
		"fonts": {
			"font": {
				"size": 32.0,
				"use_filter": true,
				"src": font_jetbrains_extrabold
			}
		}
	}
}

func construct() -> void:
	self.state = {
		"tasks": []
	}

func on_task_add(task_name: String) -> void:
	self.set_state({
		"tasks": self.state.tasks + [{
			"name": task_name,
			"done": false
		}]
	})

func on_task_done_toggle(task_id: int, val: bool) -> void:
	var tasks :Array = self.state.tasks
	
	tasks[task_id].done = val
	
	self.set_state({
		"tasks": tasks
	})

func on_task_remove(task_id: int) -> void:
	var tasks :Array = self.state.tasks
	
	tasks.remove(task_id)
	
	self.set_state({
		"tasks": tasks
	})

"""
func render() -> Dictionary:
	var tasks :Array= self.state.tasks
	var tasks_children := {}
	
	if tasks.empty():
		tasks_children = {
			[Label, "EmptyList"]: {
				"props": {
					"text": "Nothing to do right now...",
					"size_flags_vertical": Control.SIZE_EXPAND_FILL,
					"align": Label.ALIGN_CENTER,
					"valign": Label.VALIGN_CENTER
				},
				"theme": theming.empty_list
			}
		}
	else:
		for i in range(tasks.size()):
			var task = tasks[i]
			tasks_children[[Task, "Task" + str(i + 1)]] = {
				"props": {
					"task_id": i,
					"task_name": task.name,
					"task_done": task.done
				},
				"signals": {
					"task_done_toggle": "on_task_done_toggle",
					"task_remove": "on_task_remove"
				},
				"theme": theming.task_frame
			}
	
	return {
		[VBoxContainer, "VBox"]: {
			"children": {
				[Label, "Title1"]: {
					"props": {
						"text": "Todo list",
					},
					"theme": theming.title1
				},
				[Control, "Separator1"]: {
					"props": {
						"rect_min_size": Vector2(0, 16)
					}
				},
				[Label, "Title2"]: {
					"props": {
						"text": "New task",
					},
					"theme": theming.title2
				},
				[InputField, "InputField"]: {
					"signals": {
						"task_add": "on_task_add"
					}
				},
				[Control, "Separator2"]: {
					"props": {
						"rect_min_size": Vector2(0, 16)
					}
				},
				[ScrollContainer, "Scroll"]: {
					"props": {
						"horizontal_enabled": false,
						"size_flags_vertical": Control.SIZE_EXPAND_FILL
					},
					"children": {
						[VBoxContainer, "TaskList"]: {
							"props": {
								"size_flags_horizontal": Control.SIZE_EXPAND_FILL,
								"size_flags_vertical": Control.SIZE_EXPAND_FILL
							},
							"children": tasks_children
						}
					}
				}
			}
		}
	}
"""


