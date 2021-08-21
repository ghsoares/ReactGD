extends Node

class_name DictionaryMethods

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
					"change_type": 0,
					"value": compute_diff({}, objB[k])
				}
			else:
				diff[k] = {
					"change_type": 0,
					"value": objB[k]
				}
		elif objA.has(k) && !objB.has(k):
			if objA[k] is Dictionary:
				diff[k] = {
					"change_type": 1,
					"value": compute_diff(objA[k], {})
				}
			else:
				diff[k] = {
					"change_type": 1,
					"value": objA[k]
				}
		elif objA.has(k) && objB.has(k):
			if objA[k] is Dictionary:
				if objA[k].hash() != objB[k].hash():
					diff[k] = {
						"change_type": 2,
						"prev_value": objA[k],
						"value": compute_diff(objA[k], objB[k])
					}
			else:
				if objA[k] != objB[k]:
					diff[k] = {
						"change_type": 2,
						"prev_value": objA[k],
						"value": objB[k]
					}
	
	return diff
