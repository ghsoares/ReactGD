extends Object

class_name ReactGDTransitionParser

func _get_info_scope_end(indent: int, i: int, tokens: Array) -> int:
	var num_tokens := tokens.size()
	var last_i := i
	
	while i < num_tokens:
		if tokens[i].indent > indent:
			last_i = i
		if tokens[i].indent <= indent:
			return last_i
		
		i += 1
	
	return -1

func _get_value_end(i: int, tokens: Array, same_line: bool = false) -> int:
	var num_tokens := tokens.size()
	
	var ignore := 0
	var indent :int = tokens[i].indent
	var line :int = tokens[i].line
	
	while i < num_tokens:
		if tokens[i].name.ends_with("_open"):
			ignore += 1
		elif tokens[i].name.ends_with("_close"):
			ignore -= 1
		if ignore <= 0:
			if tokens[i].name == "prop_assign":
				return i - 2
			elif tokens[i].indent < indent:
				return i - 1
			elif tokens[i].line != line and same_line:
				return i - 1
		
		i += 1
	
	return -1

func _parse_params(code: String, i: int, scope_end: int, tokenized: ReactGDTokenizer.TokenizedString) -> Dictionary:
	var params := {}
	
	while i <= scope_end:
		var end :int = tokenized.find_token_layered("prop_assign", i + 2, scope_end)
		if end == -1:
			end = scope_end
		else:
			end -= 2
		
		var params_name :String = tokenized.get_token(i).string
		var params_value :String = code.substr(
			tokenized.get_token(i + 2).start,
			tokenized.get_token(end).end - tokenized.get_token(i + 2).start
		).lstrip(" ").rstrip(" ")
		
		if params_name == "transition":
			params_name = "trans_type"
			params_value = "Tween.TRANS_" + params_value
		elif params_name == "ease":
			params_name == "ease_type"
			params_value = "Tween.EASE_" + params_value
		
		params['"' + params_name + '"'] = params_value
		
		i = end + 1
	
	return params

func _parse_frames(code: String) -> Array:
	var frames := []
	
	var tokenizer := ReactGDTokenizer.new()
	tokenizer.add_token("symbol", "[\\w.:]+")
	tokenizer.add_token("prop_assign", "=")
	
	tokenizer.add_token("integer", "[+-]?\\d+")
	tokenizer.add_token("float", "[+-]?\\d*\\.\\d+")
	
	tokenizer.add_token("string", "\"[^\"]*\"")
	tokenizer.add_token("multiline_string", "\"\"\"[^\"\"\"]*\"\"\"")
	tokenizer.add_token("node_path", "\\@\"[^\"]+\"")
	tokenizer.add_token("get_node", "\\$\"[^\"]+\"")
	tokenizer.add_token("par_open", "\\(")
	tokenizer.add_token("par_close", "\\)")
	tokenizer.add_token("array_open", "\\[")
	tokenizer.add_token("array_close", "\\]")
	tokenizer.add_token("dict_open", "\\{")
	tokenizer.add_token("dict_close", "\\}")
	
	var tokenized := tokenizer.tokenize(code)
	var transition_commands := ["go_to", "punch", "shake"]
	var time_commands := ["delay", "time", "append", "velocity", "persist"]
	
	var i := 0
	
	while i < tokenized.num_tokens:
		var skip := i + 2
		var command: String = tokenized.get_token(i).string
		var sub_prop_idx = command.find(":")
		var sub_prop: String
		if sub_prop_idx != -1:
			sub_prop = command.substr(sub_prop_idx, command.length() - sub_prop_idx)
			command = command.substr(0, sub_prop_idx)
		
		if command in transition_commands:
			var end := tokenized.get_scope_end(
				tokenized.get_token(i + 1).indent, i + 1
			)
			var command_info := _parse_params(code, i + 1, end, tokenized)
			command_info['"type"'] = '"' + command + '"'
			if sub_prop != "":
				command_info['"prop"'] = '"' + sub_prop + '"'
			frames.append(str(command_info))
			
			skip = end + 1
		elif command in time_commands:
			var end = i + 1
			var params_value :String = code.substr(
				tokenized.get_token(i + 1).start,
				tokenized.get_token(end).end - tokenized.get_token(i + 1).start
			).lstrip(" ").rstrip(" ")
			
			var command_info := {
				'"type"': '"' + command + '"',
				'"value"': params_value
			}
			frames.append(str(command_info))
			
			skip = end + 1
		
		i = skip

	return frames

func _parse_transition(code: String) -> String:
	# Removes all comments from code
	var comment_reg := RegEx.new()
	comment_reg.compile("#.*")
	code = comment_reg.sub(code, " ", true)
	
	var transition_data: Array = _parse_frames(code)
	
	return "_do_transition(" + str(transition_data) + ")"

func parse(code: String) -> String:
	var tokenizer := ReactGDTokenizer.new()
	# Any kind of symbol accessor, like self, self.foo, something, etc.
	tokenizer.add_token("symbol", "[\\w.:]+")
	# Comment line
	tokenizer.add_token("comment", "#.*")
	tokenizer.add_ignore_token("comment")
	# Single line strings like "a string"
	tokenizer.add_token("string", "\"[^\"]*\"")
	# Multiple line strings like
	# """A text
	# about apples"""
	tokenizer.add_token("multiline_string", "\"\"\"[^\"\"\"]*\"\"\"")
	tokenizer.add_token("tag_open", "<")
	tokenizer.add_token("tag_close", ">")
	# Open parentheses
	tokenizer.add_token("par_open", "\\(")
	# Close parentheses
	tokenizer.add_token("par_close", "\\)")
	
	while true:
		var parsed := false
		var tokenized := tokenizer.tokenize(code)
		
		var i := 0
		var j := -1
		var par_count := 0
		
		while i < tokenized.num_tokens:
			if tokenized.get_token(i).name == "symbol" and tokenized.get_token(i).string == "do_transition":
				j = i
				par_count = 0
			elif tokenized.get_token(i).name == "par_open":
				par_count += 1
			elif tokenized.get_token(i).name == "par_close":
				par_count -= 1
				if par_count == 0 and j != -1:
					var substr = code.substr(
						tokenized.get_token(j).start,
						tokenized.get_token(i).end - tokenized.get_token(j).start
					)
					var new_code = _parse_transition(substr)
					code = code.replace(substr, new_code)
					parsed = true
					j = -1
			
			i += 1
		
		if !parsed: break
	
	return code
