extends Node

class_name ReactGDPathUtility

static func global_path(
	path: String, curr_path: String
):
	curr_path = curr_path.replace("res://", "")
	var final_path := PoolStringArray([])
	while true:
		if path.begins_with("./"):
			final_path = curr_path.split("/")
			path = path.substr(2, path.length() - 2)
		elif path.begins_with("../"):
			final_path.remove(final_path.size() - 1)
			path = path.substr(3, path.length() - 3)
		else:
			var splited = path.split("/")
			var first = splited[0]
			final_path.append(first)
			
			splited.remove(0)
			if splited.size() == 0: break
			path = splited.join("/")
	return "res://" + final_path.join("/")


static func get_file_path(path: String):
	path = path.replace("res://", "")
	var splitted_path = path.split("/")
	splitted_path = Array(splitted_path).slice(0, splitted_path.size() - 2)
	return "res://" + PoolStringArray(splitted_path).join("/")
