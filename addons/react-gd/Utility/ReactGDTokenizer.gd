extends Object

class TokenizedString:
	var tokens: Array = []
	var num_tokens: int
	
	func find_template(template: Array, offset: int) -> Array:
		for i in range(offset, num_tokens):
			if tokens[i].name == template[0]:
				var found := true
				var last_i := -1
				for j in range(template.size()):
					var desired = template[j]
					if desired is Array:
						if not tokens[i + j].name in desired:
							found = false
							break
						else:
							last_i = i + j
					else:
						if tokens[i + j].name != desired:
							found = false
							break
						else:
							last_i = i + j
				if found:
					return [i, last_i]
		return [-1,-1]
	
	func find_token(token_name: String, offset: int) -> int:
		for i in range(offset, num_tokens):
			if get_token(i).name == token_name:
				return i
		return -1
	
	func find_token_layered(token_name: String, offset: int, end: int = -1) -> int:
		var layer := 0
		if end == -1: end = num_tokens
		for i in range(offset, end + 1):
			if get_token(i).name.ends_with("_open"):
				layer += 1
			elif get_token(i).name.ends_with("_close"):
				layer -= 1
			if layer == 0:
				if get_token(i).name == token_name:
					return i
		return -1
	
	func get_scope_end(indent: int, offset: int) -> int:
		for i in range(offset, num_tokens):
			if tokens[i].indent < indent:
				return i - 1
		return num_tokens - 1
	
	func slice_string(string: String, start: int, end: int) -> String:
		var sliced := string.substr(
			tokens[start].start,
			tokens[end].end - tokens[start].start
		)
		return sliced
	
	func get_token(i: int) -> Dictionary:
		if i < 0 or i >= num_tokens:
			return {
				"name": "",
				"string": "",
				"start": -1,
				"end": -1,
				"indent": -1,
				"line": -1,
				"column": -1
			}
		return tokens[i]
	
	func pop_front() -> Dictionary:
		num_tokens -= 1
		return tokens.pop_front()
	
	func pop_back() -> Dictionary:
		num_tokens -= 1
		return tokens.pop_back()


class_name ReactGDTokenizer

var tokens: Array
var ignore_tokens: Array

func _init() -> void:
	tokens = []
	ignore_tokens = []
	add_token("tab", "\\t")
	add_token("new_line", "\\r?\\n")

func add_token(token_name: String, token: String) -> void:
	var t := RegEx.new()
	t.compile(token)
	tokens.append({
		"name": token_name,
		"regex": t
	})

func add_tokens(tokens: Dictionary) -> void:
	for token_name in tokens.keys():
		var token_str: String = tokens[token_name]
		add_token(token_name, token_str)

func add_ignore_token(token_name: String) -> void:
	ignore_tokens.append(token_name)

func tokenize(s: String) -> TokenizedString:
	var res := TokenizedString.new()
	var total_tokens := 0
	var s_len := s.length()
	
	var i := 0
	var indent := 0
	var line := 0
	var colummn := 0
	while i < s_len:
		var best_match_name: String = ""
		var best_match :RegExMatch = null
		var best_match_start :int = s_len
		
		for t in tokens:
			var token_match :RegExMatch = t.regex.search(s, i)
			if !token_match: continue
			
			if !best_match:
				best_match_name = t.name
				best_match = token_match
				best_match_start = token_match.get_start()
			else:
				var match_start = token_match.get_start()
				if match_start <= best_match_start:
					best_match_name = t.name
					best_match = token_match
					best_match_start = match_start
		
		if !best_match: break
		
		if best_match_name == "tab":
			indent += 1
		elif best_match_name == "new_line":
			indent = 0
			colummn = 0
			line += 1
		else:
			if not best_match_name in ignore_tokens:
				res.tokens.append({
					"name": best_match_name,
					"string": best_match.get_string(),
					"start": best_match.get_start(),
					"end": best_match.get_end(),
					"indent": indent,
					"line": line,
					"column": colummn
				})
				res.num_tokens += 1
		
		colummn += best_match.get_end() - i
		i = best_match.get_end()
	
	return res










