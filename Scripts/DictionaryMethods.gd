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

static func compute_diff(dictA: Dictionary, dictB: Dictionary) -> Dictionary:
	var diff := {}
	
	var keys := array_union(dictA.keys(), dictB.keys())
	
	for k in keys:
		if !dictA.has(k) && dictB.has(k):
			if dictB[k] is Dictionary:
				diff[k] = {
					"change_type": 0,
					"value": compute_diff({}, dictB[k])
				}
			else:
				diff[k] = {
					"change_type": 0,
					"value": dictB[k]
				}
		elif dictA.has(k) && !dictB.has(k):
			if dictA[k] is Dictionary:
				diff[k] = {
					"change_type": 1,
					"value": compute_diff(dictA[k], {})
				}
			else:
				diff[k] = {
					"change_type": 1,
					"value": dictA[k]
				}
		elif dictA.has(k) && dictB.has(k):
			if dictA[k] is Dictionary:
				if dictA[k].hash() != dictB[k].hash():
					diff[k] = {
						"change_type": 2,
						"value": compute_diff(dictA[k], dictB[k])
					}
			else:
				if dictA[k] != dictB[k]:
					diff[k] = {
						"change_type": 2,
						"prev_value": dictA[k],
						"value": dictB[k]
					}
	
	return diff
