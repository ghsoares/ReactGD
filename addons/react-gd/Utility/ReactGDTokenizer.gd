class_name ReactGDTokenizer

var tokens := []
var ignore_tokens := []

func add_token(token_name: String, token: String) -> void:
	var t := RegEx.new()
	t.compile(token)
	tokens.append({
		"name": token_name,
		"regex": t
	})

func add_ignore_token(token_name: String) -> void:
	ignore_tokens.append(token_name)

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
		
		if not best_match_name in ignore_tokens:
			res.append({
				"name": best_match_name,
				"match": best_match
			})
		
		i = best_match.get_end()
	
	return res
