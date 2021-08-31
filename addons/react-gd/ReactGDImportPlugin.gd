tool
extends EditorImportPlugin

enum Presets { DEFAULT }

func get_importer_name() -> String:
	return "ReactGD.GDXScript"

func get_visible_name() -> String:
	return "GDXScript"

func get_recognized_extensions() -> Array:
	return ["gdx"]

func get_save_extension() -> String:
	return "gd"

func get_resource_type() -> String:
	return "GDScript"

func get_preset_count() -> int:
	return Presets.size()

func get_preset_name(preset: int) -> String:
	match preset:
		Presets.DEFAULT:
			return "Default"
		_:
			return "Unknown"

func get_import_options(preset: int) -> Array:
	match preset:
		Presets.DEFAULT:
			return [{
				"name": "unfold_blocks",
				"default_value": false,
				"hint_string": "Tells if the result gdx blocks should be unfolded in folded"
			}]
		_:
			return []

func get_option_visibility(option: String, options: Dictionary) -> bool:
	return true

func import(source_file: String, save_path: String, options, platform_variants, gen_files):
	var file := File.new()
	if file.open(source_file, File.READ) != OK:
		return FAILED
	
	var script := GDScript.new()
	var source = file.get_as_text()
	var source_folder = ReactGDPathUtility.get_file_path(source_file)
	
	var GDX_parser := ReactGDXParser.new()
	#var transition_parser := ReactGDTransitionParser.new()
	var import_parser := ReactGDImportParser.new()
	GDX_parser.sed = source_file
	GDX_parser.unfold_blocks = options.unfold_blocks
	import_parser.source_path = source_folder
	
	source = GDX_parser.parse(source)
	#source = transition_parser.parse(source)
	source = import_parser.parse(source)
	
	script.source_code = source
	
	var filename := save_path + "." + get_save_extension()
	return ResourceSaver.save(filename, script)









