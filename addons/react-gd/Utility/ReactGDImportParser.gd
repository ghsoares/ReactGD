extends Object

class_name ReactGDImportParser

var source_path: String


func parse(code: String) -> String:
	var tokenizer := ReactGDTokenizer.new()
	
	tokenizer.add_token("symbol", '[\\w.:]+')
	tokenizer.add_token("string", '"[^"]*"')
	
	var tokenized := tokenizer.tokenize(code)
	
	var i := 0
	while i < tokenized.num_tokens:
		if tokenized.get_token(i).string == "import":
			assert(
				tokenized.get_token(i + 1).name == "string",
				"Expected a string path at line " + str(tokenized.get_token(i).line)
			)
			assert(
				tokenized.get_token(i + 2).string == "as",
				"Expected 'as' symbol at line " + str(tokenized.get_token(i).line)
			)
			assert(
				tokenized.get_token(i + 3).name == "symbol",
				"Expected the imported class name " + str(tokenized.get_token(i).line)
			)
			
			var substr := tokenized.slice_string(
				code, i, i + 3
			)
			
			var path: String = tokenized.get_token(i + 1).string
			var name: String = tokenized.get_token(i + 3).string
			path = path.substr(1, path.length() - 2)
			
			path = ReactGDPathUtility.global_path(path, source_path)
			
			var import_code := 'var ' + name + ' = load("' + path + '")'
			
			code = code.replace(substr, import_code)
			
			i += 4
		else:
			i += 1
	
	return code


