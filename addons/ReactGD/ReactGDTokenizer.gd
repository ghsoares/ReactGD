extends Node

class_name ReactGDTokenizer

enum PROP_TYPE {
	Prop = 0,
	Signal = 1,
	Ref = 2,
	Theming = 3
}

class Tokenizer:
	var tokens := {}
	
	func add_token(token_name: String, token: String) -> void:
		var t := RegEx.new()
		t.compile(token)
		tokens[token_name] = t
	
	func tokenize(s: String) -> Array:
		var res := []
		var total_tokens := 0
		var s_len := s.length()
		
		var i := 0
		while i < s_len:
			var best_match_name: String = ""
			var best_match :RegExMatch = null
			var best_match_start :int = s_len
			
			for t in tokens:
				var token_match :RegExMatch = tokens[t].search(s, i)
				if !token_match: continue
				
				if !best_match:
					best_match_name = t
					best_match = token_match
					best_match_start = token_match.get_start()
				else:
					var match_start = token_match.get_start()
					if match_start <= best_match_start:
						best_match_name = t
						best_match = token_match
						best_match_start = match_start
			
			if !best_match: break
			
			res.append({
				"name": best_match_name,
				"match": best_match
			})
			i = best_match.get_end()
		
		return res

static func find_literal_close(i: int, tokens: Array, open_name: String, close_name: String) -> int:
	var count := 0
	for j in range(i, tokens.size()):
		if tokens[j].name == open_name: count += 1
		if tokens[j].name == close_name:
			count -= 1
			if count == 0: return j
	return -1

static func split_layered(s: String, split_char: String, layer_open_chars: String, layer_close_chars: String) -> Array:
	var res := []
	var curr := ""
	
	var count := 0
	for c in s:
		if c in layer_open_chars: count += 1
		if c in layer_close_chars: count -= 1
		if c == split_char:
			if count == 0:
				res.append(curr)
				curr = ""
		else:
			curr += c
	
	res.append(curr)
	
	return res

static func parse_tags(code: String) -> Array:
	var tokenizer := Tokenizer.new()
	tokenizer.add_token("symbol", "\\w+")
	tokenizer.add_token("tag_start_open", "<")
	tokenizer.add_token("tag_end_open", "</")
	tokenizer.add_token("tag_close", ">")
	tokenizer.add_token("tag_single_close", "/>")
	tokenizer.add_token("par_open", "\\(")
	tokenizer.add_token("par_close", "\\)")
	
	var tokens := tokenizer.tokenize(code)
	var num_tokens := tokens.size()
	var i := 0
	
	var tags := []
	
	while i < num_tokens:
		if tokens[i].name == "tag_start_open":
			var j := i + 1
			var closed := false
			var par_count := 0
			while j < num_tokens:
				if tokens[j].name == "par_open":
					par_count += 1
				elif tokens[j].name == "par_close":
					par_count -= 1
				if par_count == 0:
					if tokens[j].name == "tag_close" || tokens[j].name == "tag_single_close":
						closed = true
						break
				j += 1
			if closed:
				if tokens[i + 1].name == "symbol":
					var class_n = tokens[i + 1].match.get_string()
					var tag = code.substr(
						tokens[i].match.get_start(),
						tokens[j].match.get_end() - tokens[i].match.get_start()
					)
					
					tags.append({
						"tag_type": "tag_start" if tokens[j].name == "tag_close" else "tag_single",
						"tag_code": tag,
						"tag_class": class_n
					})
		elif tokens[i].name == "tag_end_open":
			var j := i + 1
			var closed := false
			while j < num_tokens:
				if tokens[j].name == "tag_close":
					closed = true
					break
				j += 1
			if closed:
				if tokens[i + 1].name == "symbol":
					var class_n = tokens[i + 1].match.get_string()
					var tag = code.substr(
						tokens[i].match.get_start(),
						tokens[j].match.get_end() - tokens[i].match.get_start()
					)
					
					tags.append({
						"tag_type": "tag_end",
						"tag_code": tag,
						"tag_class": class_n
					})
		i += 1
	
	return tags

static func parse_tag(tag: Dictionary) -> Dictionary:
	var tokenizer := Tokenizer.new()
	var tag_type :String = tag.tag_type
	var tag_code :String = tag.tag_code
	var tag_class :String = tag.tag_class
	
	if tag_type == "tag_start":
		tag_code = tag_code.substr(1, tag_code.length() - 2)
	elif tag_type == "tag_single":
		tag_code = tag_code.substr(1, tag_code.length() - 3)
	elif tag_type == "tag_end":
		tag_code = tag_code.substr(2, tag_code.length() - 3)
	
	tokenizer.add_token("symbol", "\\w+")
	tokenizer.add_token("prop_assign", ":")
	tokenizer.add_token("integer", "\\d+")
	tokenizer.add_token("integer", "0x[0-9a-g]+")
	tokenizer.add_token("integer", "0b[0-1]+")
	tokenizer.add_token("float", "\\d+.\\d+")
	tokenizer.add_token("float", "\\d+.\\d+e[+-]?\\d+")
	tokenizer.add_token("string", "\"[^\"]+\"")
	tokenizer.add_token("multiline_string", "\"\"\"[^\"\"\"]+\"\"\"")
	tokenizer.add_token("node_path", "\\@\"[^\"]+\"")
	tokenizer.add_token("get_node", "\\$\"[^\"]+\"")
	tokenizer.add_token("par_open", "\\(")
	tokenizer.add_token("par_close", "\\)")
	tokenizer.add_token("array_open", "\\[")
	tokenizer.add_token("array_close", "\\]")
	tokenizer.add_token("dict_open", "\\{")
	tokenizer.add_token("dict_close", "\\}")
	
	var tokens := tokenizer.tokenize(tag_code)
	var num_tokens := tokens.size()
	var i := 1
	
	var props := []
	var theme := ""
	
	while i < num_tokens:
		var is_prop := false
		var prop_name := ""
		var prop_type :int = PROP_TYPE.Prop
		var prop_value
		
		if (i + 1) < num_tokens && tokens[i].name == "symbol" && tokens[i + 1].name == "prop_assign":
			is_prop = true
			prop_name = tokens[i].match.get_string()
			prop_value = tokens[i + 2]
			if prop_name == "theme":
				prop_type = PROP_TYPE.Theming
			elif prop_name == "ref":
				prop_type = PROP_TYPE.Ref
		elif (i + 2) < num_tokens && tokens[i].name == "symbol" && tokens[i + 1].name == "symbol" && tokens[i + 2].name == "prop_assign":
			is_prop = true
			match tokens[i].match.get_string():
				"signal": prop_type = PROP_TYPE.Signal
			prop_name = tokens[i + 1].match.get_string()
			prop_value = tokens[i + 3]
		
		if is_prop:
			var skip = i + 1
			
			match prop_type:
				PROP_TYPE.Prop, PROP_TYPE.Theming, PROP_TYPE.Ref:
					match prop_value.name:
						"array_open":
							var end = find_literal_close(i + 2, tokens, "array_open", "array_close")
							if end != -1:
								prop_value = tag_code.substr(
									prop_value.match.get_start(), tokens[end].match.get_end() -
									prop_value.match.get_start()
								)
								skip = end + 1
						"dict_open":
							var end = find_literal_close(i + 2, tokens, "dict_open", "dict_close")
							if end != -1:
								prop_value = tag_code.substr(
									prop_value.match.get_start(), tokens[end].match.get_end() -
									prop_value.match.get_start()
								)
								skip = end + 1
						"par_open":
							var end = find_literal_close(i + 2, tokens, "par_open", "par_close")
							if end != -1:
								prop_value = tag_code.substr(
									prop_value.match.get_start(), tokens[end].match.get_end() -
									prop_value.match.get_start()
								)
								skip = end + 1
						_:
							prop_value = prop_value.match.get_string()
				PROP_TYPE.Signal:
					match prop_value.name:
						"symbol":
							prop_value = "\"" + prop_value.match.get_string() + "\""
							skip = i + 2
						"par_open":
							var end = find_literal_close(i + 2, tokens, "par_open", "par_close")
							if end != -1:
								prop_value = tag_code.substr(
									prop_value.match.get_start(), tokens[end].match.get_end() -
									prop_value.match.get_start()
								)
								
								var args = split_layered(prop_value.substr(1, prop_value.length() - 2), ",", "[{(", ")}]")
								match args.size():
									1:
										prop_value = '"' + args[0] + '"'
									2:
										prop_value = str({
											'"target"': '"' + args[0] + '"',
											'"binds"': args[1]
										})
									3:
										prop_value = str({
											'"target"': '"' + args[0] + '"',
											'"binds"': args[1],
											'"flags"': args[2]
										})
								
								skip = end + 1
			
			props.append({
				"name": prop_name,
				"value": prop_value,
				"type": prop_type
			})
			
			i = skip
			continue
		
		i += 1
	
	return {
		"tag_type": tag_type,
		"tag_class": tag_class,
		"props": props
	}

static func find_close_tag(tags: Array, i: int, tag_class: String) -> int:
	var count := 0
	
	for j in range(i, tags.size()):
		if tags[j].tag_type == "tag_start":
			count += 1
		elif tags[j].tag_type == "tag_end":
			count -= 1
			if count == 0:
				if tags[j].tag_class == tag_class: return j
				return -1
	
	return -1

static func build_tree(tags: Array) -> Array:
	var tree := []
	
	var i := 0
	var num_tags := tags.size()
	
	while i < num_tags:
		var tag = tags[i]
		
		var tag_class = tag.tag_class
		var tag_type = tag.tag_type
		
		var node_props := {}
		var node_signals := {}
		var node_children := []
		var node_theme := ""
		var node_ref := ""
		var skipped := false
		var found := false
		
		if tag_type == "tag_single" || tag_type == "tag_start":
			for prop in tag.props:
				print(prop.type, ", ", prop.value)
				if prop.type == PROP_TYPE.Prop:
					node_props['"' + prop.name + '"'] = prop.value
				elif prop.type == PROP_TYPE.Signal:
					node_signals['"' + prop.name + '"'] = prop.value
				elif prop.type == PROP_TYPE.Theming:
					node_theme = prop.value
				elif prop.type == PROP_TYPE.Ref:
					node_ref = prop.value
			found = true
		
		if tag_type == "tag_start":
			var close_i = find_close_tag(tags, i, tag_class)
			if close_i != -1:
				var between = tags.slice(i + 1, close_i - 1)
				if !between.empty():
					node_children += build_tree(between)
					i = close_i + 1
					skipped = true
		
		if found:
			tree.append({
				'"type"': tag_class,
				'"props"': node_props,
				'"signals\"': node_signals,
				'"children\"': node_children,
				'"theme"': node_theme,
				'"ref"': node_ref
			})
		
		if !skipped: i += 1
	
	return tree

static func gdx(code: String) -> String:
	var comment_reg := RegEx.new()
	comment_reg.compile("#.*")
	code = comment_reg.sub(code, "", true)
	
	print(code)
	
	code = code.replace("\n", " ")
	code = code.substr(2, code.length() - 3)
	
	var tags := parse_tags(code)
	for i in range(tags.size()):
		tags[i] = parse_tag(tags[i])
	
	var tree = build_tree(tags)
	
	return str(tree)

static func parse(original: String) -> String:
	while true:
		var parsed := false
		var str_len := original.length()
		
		var start_pos := original.find("@(")
		if start_pos != -1:
			var end_pos := start_pos
			var open_count := 0
			
			for i in range(start_pos, str_len):
				if original[i] == "(":
					open_count += 1
				elif original[i] == ")":
					open_count -= 1
					if open_count == 0:
						end_pos = i
						break
			
			if open_count != 0:
				push_error("Syntax error!")
				return original
			
			var original_code := original.substr(start_pos, end_pos - start_pos + 1)
			var swap_code := gdx(original_code)
			
			original = original.replace(original_code, swap_code)
		
		if !parsed: break
	
	return original
