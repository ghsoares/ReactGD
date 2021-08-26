extends Node

func _ready() -> void:
	var dictA := {
		"type": Label,
		"props": {
			"text": "Something"
		}
	}
	var dictB := {
		"type": Label,
		"props": {
			"text": "Anotherthing"
		}
	}
	
	print(DictionaryMethods.diff(dictA, dictB))
	pass # Replace with function body.

