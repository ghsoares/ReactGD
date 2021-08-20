extends Node

class_name ReactGDTokenizer

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
		for t in tokens:
			var token_reg :RegEx = tokens[t]
			var t_id := 0
			var i := 0
			while i < s_len:
				var token_match :RegExMatch = token_reg.search(s, i)
				if !token_match: break
				
				if t_id >= total_tokens:
					res.append({})
					total_tokens += 1
				
				res[t_id][t] = token_match
				
				i += token_match.get_string().length()
				t_id += 1
			
		return res

static func gdx(code: String) -> String:
	code = code.replace("\n", " ")
	
	code = code.substr(2, code.length() - 3)
	var tokenizer := Tokenizer.new()
	tokenizer.add_token("tag_open", "<(\\w+)([^>/]*)>")
	tokenizer.add_token("single_tag", "<(\\w+)([^>/]*)/>")
	tokenizer.add_token("tag_close", "</(\\w+)([^>/]*)>")
	
	var tokenized := tokenizer.tokenize(code)
	
	var recursive_tree := []
	var num_tokens := tokenized.size()
	
	var i := 0
	
	while i < num_tokens:
		var tokens :Dictionary = tokenized[i]
		
		if tokens.has("tag_open"):
			var open_class = tokens["tag_open"].get_string(1).dedent()
			var props = tokens["tag_open"].get_string(2).dedent()
			var close_tokens :Dictionary = tokenized[(num_tokens - 1) - i]
			if close_tokens.has("tag_close"):
				var close_class = tokens["tag_close"].get_string(1).dedent()
				if open_class == close_class:
					tokenized.remove((num_tokens - 1) - i)
					tokenized.remove(i)
					num_tokens -= 2
					
					print(open_class, ": ", props)
					continue
		elif tokens.has("single_tag"):
			var open_class = tokens["single_tag"].get_string(1).dedent()
			var props = tokens["single_tag"].get_string(2).dedent()
			
			tokenized.remove(i)
			num_tokens -= 1
			
			print(open_class, ": ", props)
		
		i += 1
	
	return ""

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
