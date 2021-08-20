tool
extends EditorImportPlugin

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

func get_import_options(preset: int) -> Array:
	return []

func get_preset_count() -> int:
	return 0

func import(source_file: String, save_path: String, options, platform_variants, gen_files):
	var file := File.new()
	if file.open(source_file, File.READ) != OK:
		return FAILED
	
	var script := GDScript.new()
	var source = file.get_as_text()
	
	source = ReactGDTokenizer.parse(source)
	script.source_code = source
	
	var filename := save_path + "." + get_save_extension()
	return ResourceSaver.save(filename, script)

