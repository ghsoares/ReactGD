extends Object

class_name ReactGDDictionaryMethods

enum DIFF_TYPE {
	DIFF_ADDED = 0,
	DIFF_MODIFIED = 1,
	DIFF_REMOVED = 2,
	DIFF_UNCHANGED = 3
}

static func merge_dict(dictA: Dictionary, dictB: Dictionary):
	var keys := dictB.keys()
	for k in keys:
		dictA[k] = dictB[k]

"""
This function returns a string literal of a Dictionary,
instead of a json like JSON.print does
"""
static func stringify(obj, indent: String = " ", curr_indent: int = 0) -> String:
	var res := ""
	var line_break := "\n" if indent != "" else ""
	if obj is Array:
		res += "["
		for val in obj:
			res += line_break + indent.repeat(curr_indent)
			if val is Array or val is Dictionary:
				res += stringify(val, indent, curr_indent + 1) + ","
			else:
				res += str(val) + ","
		if !obj.empty():
			res += line_break + indent.repeat(curr_indent - 1)
		res += "]"
	elif obj is Dictionary:
		res += "{"
		for k in obj.keys():
			var val = obj[k]
			res += line_break + indent.repeat(curr_indent) + str(k) + ": "
			if val is Array or val is Dictionary:
				res += stringify(val, indent, curr_indent + 1) + ","
			else:
				res += str(val) + ","
		if !obj.empty():
			res += line_break + indent.repeat(curr_indent - 1)
		res += "}"
	return res

static func diff(objA: Dictionary, objB: Dictionary):
	var res := {}
	
	for k in objA.keys():
		if not objB.has(k):
			if objA[k] is Dictionary:
				res[k] = {
					"change_type": DIFF_TYPE.DIFF_REMOVED,
					"value": diff(objA[k], {})
				}
			else:
				res[k] = {
					"change_type": DIFF_TYPE.DIFF_REMOVED,
					"value": objA[k]
				}
	
	for k in objB.keys():
		if not objA.has(k):
			if objB[k] is Dictionary:
				res[k] = {
					"change_type": DIFF_TYPE.DIFF_ADDED,
					"value": diff({}, objB[k])
				}
			else:
				res[k] = {
					"change_type": DIFF_TYPE.DIFF_ADDED,
					"value": objB[k]
				}
		else:
			if objA[k] is Dictionary and objB[k] is Dictionary:
				if objA[k].hash() != objB[k].hash():
					res[k] = {
						"change_type": DIFF_TYPE.DIFF_MODIFIED,
						"prev_value": objA[k],
						"value": diff(objA[k], objB[k])
					}
				else:
					res[k] = {
						"change_type": DIFF_TYPE.DIFF_UNCHANGED,
						"value": objB[k]
					}
			elif objB[k] is Dictionary:
				res[k] = {
					"change_type": DIFF_TYPE.DIFF_MODIFIED,
					"prev_value": objA[k],
					"value": diff({}, objB[k])
				}
			else:
				if typeof(objA[k]) != typeof(objB[k]) or hash(objA[k]) != hash(objB[k]):
					res[k] = {
						"change_type": DIFF_TYPE.DIFF_MODIFIED,
						"prev_value": objA[k],
						"value": objB[k]
					}
				else:
					res[k] = {
						"change_type": DIFF_TYPE.DIFF_UNCHANGED,
						"value": objB[k]
					}
	
	return res
