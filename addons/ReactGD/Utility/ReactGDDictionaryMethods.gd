extends Node
class_name ReactGDDictionaryMethods

enum DIFF_TYPE {
	DIFF_ADDED = 0,
	DIFF_MODIFIED = 1,
	DIFF_REMOVED = 2,
	DIFF_UNCHANGED = 3
}

static func unfold_string(s: String, indent_str: String) -> String:
	var tokenizer := ReactGDTokenizer.new()
	tokenizer.add_token("char", ".")
	tokenizer.add_token("array_open", "\\[")
	tokenizer.add_token("array_close", "\\]")
	tokenizer.add_token("dict_open", "\\{")
	tokenizer.add_token("dict_close", "\\}")
	tokenizer.add_token("comma", ",")
	
	var tokens := tokenizer.tokenize(s)
	var num_tokens := tokens.size()
	
	var i := 0
	var res := ""
	var indent := 0
	
	while i < num_tokens:
		var val: String = tokens[i].match.get_string()
		
		match tokens[i].name:
			"dict_open", "array_open":
				indent += 1
				res += val.lstrip(" ").rstrip(" ") + "\n"
				res += indent_str.repeat(indent)
			"dict_close", "array_close":
				indent -= 1
				res += "\n" + indent_str.repeat(indent) + val.lstrip(" ").rstrip(" ")
			"comma":
				res += val.lstrip(" ").rstrip(" ") + "\n"
				res += indent_str.repeat(indent)
			_:
				if val == " ":
					res += val
				else:
					res += val.lstrip(" ").rstrip(" ")
		
		i += 1
	
	return res

static func path_get(dict: Dictionary, path: String, first_is_root: bool = false, default = null):
	if path == "":
		return dict
	
	var splitted :Array = path.split(".")
	var first = splitted.pop_front()
	if first_is_root:
		path = PoolStringArray(splitted).join(".")
		if path == "": return dict
		first = splitted.pop_front()
	
	if splitted.size() == 0:
		return dict.get(path, default)
	
	if dict.has(first) && dict[first] is Dictionary:
		return path_get(dict[first], PoolStringArray(splitted).join("."))
	else:
		return dict.get(path, default)

static func merge_dict(dictA: Dictionary, dictB: Dictionary) -> void:
	for key in dictB:
		if dictA.has(key):
			if dictA[key] is Dictionary:
				merge_dict(dictA[key], dictB[key])
			else:
				dictA[key] = dictB[key]
		else:
			dictA[key] = dictB[key]

static func array_union(arr1: Array, arr2: Array) -> Array:
	for val in arr2:
		if !arr1.has(val):
			arr1.append(val)
	return arr1

static func compute_diff(objA, objB) -> Dictionary:
	var diff := {}

	var keys := array_union(objA.keys(), objB.keys())
	
	for k in keys:
		if !objA.has(k) && objB.has(k):
			if objB[k] is Dictionary:
				diff[k] = {
					"change_type": DIFF_TYPE.DIFF_ADDED,
					"value": compute_diff({}, objB[k])
				}
			else:
				diff[k] = {
					"change_type": DIFF_TYPE.DIFF_ADDED,
					"value": objB[k]
				}
		elif objA.has(k) && !objB.has(k):
			if objA[k] is Dictionary:
				diff[k] = {
					"change_type": DIFF_TYPE.DIFF_REMOVED,
					"value": compute_diff(objA[k], {})
				}
			else:
				diff[k] = {
					"change_type": DIFF_TYPE.DIFF_REMOVED,
					"value": objA[k]
				}
		elif objA.has(k) && objB.has(k):
			if objA[k] is Dictionary:
				if objA[k].hash() != objB[k].hash():
					diff[k] = {
						"change_type": DIFF_TYPE.DIFF_MODIFIED,
						"prev_value": objA[k],
						"value": compute_diff(objA[k], objB[k])
					}
				else:
					diff[k] = {
						"change_type": DIFF_TYPE.DIFF_UNCHANGED,
						"value": objB[k]
					}
			else:
				if typeof(objA[k]) != typeof(objB[k]) || objA[k] != objB[k]:
					diff[k] = {
						"change_type": DIFF_TYPE.DIFF_MODIFIED,
						"prev_value": objA[k],
						"value": objB[k]
					}
				else:
					diff[k] = {
						"change_type": DIFF_TYPE.DIFF_UNCHANGED,
						"value": objB[k]
					}
	
	return diff
