extends Node

class_name ReactGDDictionaryMethods

enum DIFF_TYPE {
	DIFF_ADDED = 0,
	DIFF_MODIFIED = 1,
	DIFF_REMOVED = 2,
	DIFF_UNCHANGED = 3
}

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

static func dest_diff(diff: Dictionary) -> Dictionary:
	if diff.change_type == DIFF_TYPE.DIFF_UNCHANGED:
		return diff
	
	if not diff.value is Dictionary:
		return diff.value
	
	var res := {}
	for k in diff.value.keys():
		if diff.value[k].change_type == DIFF_TYPE.DIFF_UNCHANGED:
			res[k] = diff.value[k]
		else:
			if diff.value[k] is Dictionary:
				res[k] = dest_diff(diff.value[k])
			else:
				res[k] = diff.value[k].value
	
	return res

"""
def dd(d1, d2, ctx=""):
	print "Changes in " + ctx
	for k in d1:
		if k not in d2:
			print k + " removed from d2"
	for k in d2:
		if k not in d1:
			print k + " added in d2"
			continue
		if d2[k] != d1[k]:
			if type(d2[k]) not in (dict, list):
				print k + " changed in d2 to " + str(d2[k])
			else:
				if type(d1[k]) != type(d2[k]):
					print k + " changed to " + str(d2[k])
					continue
				else:
					if type(d2[k]) == dict:
						dd(d1[k], d2[k], k)
						continue
"""