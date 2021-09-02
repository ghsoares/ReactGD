extends Object

class TokenizedString:
	# All the tokenized string tokens
	var tokens: Array = []
	var num_tokens: int
	
	# Returns the token at given index, returns a empty token
	# if index is out of range, so it fails silently
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
	
	# Couple of functions that returns a property of a token
	# for better readability
	
	# Name
	func get_token_name(i: int) -> String:
		return get_token(i).name
	
	# String
	func get_token_string(i: int) -> String:
		return get_token(i).string
	
	# Start
	func get_token_start(i: int) -> int:
		return get_token(i).start
	
	# End
	func get_token_end(i: int) -> int:
		return get_token(i).end
	
	# Indentation
	func get_token_indent(i: int) -> int:
		return get_token(i).indent
	
	# Line
	func get_token_line(i: int) -> int:
		return get_token(i).line
	
	# Column
	func get_token_column(i: int) -> int:
		return get_token(i).column
	
	# Get the close token of a open token
	func get_token_close(i: int) -> int:
		var count := 0
		while i < num_tokens:
			if get_token_name(i).ends_with("_open"):
				count += 1
			elif get_token_name(i).ends_with("_close"):
				count -= 1
				if count == 0:
					return i
			
			i += 1
		return -1 
	
	# Throws an error at a given token line and column
	func throw_error(token_id: int, error_message: String) -> void:
		var line := get_token_line(token_id)
		var column := get_token_column(token_id)
		error_message = "Parsing error at line " + str(line + 1) + ": \n" + error_message
		assert(false, error_message)
	
	# Returns a substring from the start of a token to the end of another token
	func substr(string: String, token_from: int, token_to: int) -> String:
		var start := get_token_start(token_from)
		var end := get_token_end(token_to)
		return string.substr(
			start, end - start
		)
	
	# Pops the first token
	func pop_front():
		num_tokens -= 1
		return tokens.pop_front()
	
	# Pops the last token
	func pop_back():
		num_tokens -= 1
		return tokens.pop_back()

class_name ReactGDTokenizer

# Token expressions
var expressions: Array
# Tokens to be ignored
var ignore_expressions: Array

func _init() -> void:
	expressions = []
	ignore_expressions = []
	# Initialize default tokens
	add_token_expressions({
		"tab": ['\\t', '    '],
		"new_line": '\\r?\\n',
		"comment": '#.*'
	})
	add_ignore_expression("comment")

# Adds a expression given the name and the regex string
func add_token_expression(token_name: String, expression) -> void:
	# An array contains multiple tokens that leads to the same token
	if expression is Array:
		for e in expression:
			var r := RegEx.new()
			r.compile(e)
			expressions.append({
				"name": token_name,
				"exp": r
			})
	else:
		var r := RegEx.new()
		r.compile(expression)
		expressions.append({
			"name": token_name,
			"exp": r
		})

# Adds multiple expressions
func add_token_expressions(expressions: Dictionary) -> void:
	for token_name in expressions.keys():
		var expression = expressions[token_name]
		add_token_expression(token_name, expression)

# Set the expression name as ignored, so this token is not returned
# when a string is tokenized
func add_ignore_expression(token_name: String) -> void:
	ignore_expressions.append(token_name)

# Main tokenization function, takes a string and returns a object
# will all the relevant info about the tokenization
func tokenize(s: String, line: int = 0, column: int = 0, indent: int = 0) -> TokenizedString:
	var res := TokenizedString.new()
	var total_tokens := 0
	var s_len := s.length()
	
	#var prev_token := {}
	
	var i := 0
	while i < s_len:
		# Finds the best match
		var best_match_name: String = ""
		var best_match :RegExMatch = null
		var best_match_start :int = s_len
		
		for e in expressions:
			var token_match :RegExMatch = e.exp.search(s, i)
			if !token_match: continue
			
			# First expression checked
			if !best_match:
				best_match_name = e.name
				best_match = token_match
				best_match_start = token_match.get_start()
			else:
				var match_start = token_match.get_start()
				# This is the best match only if it's start is less or equal
				# the current best match
				if match_start <= best_match_start:
					best_match_name = e.name
					best_match = token_match
					best_match_start = match_start
		
		# No more tokens found, break
		if !best_match: break
		
		# This token adds indentation
		if best_match_name == "tab":
			indent += 1
		# This token adds a new line
		elif best_match_name == "new_line":
			indent = 0
			column = 0
			line += 1
		else:
			# Set the token info
			if not best_match_name in ignore_expressions:
				var new_token := {
					"name": best_match_name,
					"string": best_match.get_string(),
					"start": best_match.get_start(),
					"end": best_match.get_end(),
					"indent": indent,
					"line": line,
					"column": column
				}
				res.tokens.append(new_token)
				res.num_tokens += 1
				#prev_token = new_token
		
		# Increment column based on position end
		column += best_match.get_end() - i
		# Increment string offset
		i = best_match.get_end()
	
	return res

# Replace a string inside a range to a new string
static func replace_range(string: String, replace_to: String, from: int, to: int) -> String:
	var start := string.substr(0, from)
	var end := string.substr(to)
	return start + replace_to + end



