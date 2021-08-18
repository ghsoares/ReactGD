extends ReactComponent

class Task:
	extends ReactComponent
	
	var task_name: String
	var completed: bool

func construct() -> void:
	self.state = {
		"tasks": []
	}

func render() -> Dictionary:
	return {
		[PanelContainer, "panel"]: {
			"props": {
				"size_flags_horizontal": SIZE_SHRINK_CENTER,
				"size_flags_vertical": SIZE_SHRINK_CENTER,
			},
		}
	}



