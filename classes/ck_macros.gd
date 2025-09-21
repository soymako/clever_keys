extends Node
class_name CKMacros

const MACROS = preload("res://addons/clever_keys/config/macros.json")


func getMacro(key:String)->String:
	var dic := _loadMacroFile()
	if dic.has(key): return dic[key]
	return ""

func getAllKeys()->Array:
	return _loadMacroFile().keys()

func _loadMacroFile()->Dictionary:
	return JSON.parse_string(MACROS.get_parsed_text())
