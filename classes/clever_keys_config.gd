@tool
extends Resource
class_name CleverKeysConfig

signal CKSizeChanged(size:Vector2i)
signal CK_SplitOffsetChanged(v:float)
signal CK_ScaleChanged(v:float)


signal CompletionAdded(alias:String, completion:String)
signal CompletionRemoved(alias:String, completion:String)

@export var completions:Dictionary[String, String] = {
	"+f": "+file ",
	"file": "+file ",
	"r": "res://",
	"rss": "res://src/scripts",
	"rs": "res://scripts",
	"+ac": "add_completion ",
	"-ac": "remove_completion ",
	"-ha": "harpoon add ",
	"-hr": "harpoon remove ",
	"-ho": "harpoon open "
}



@export var window_size:Vector2i = Vector2i(760, 500):
	set(v):
		window_size = v
		CKSizeChanged.emit(v)
@export var scale:float = 1:
	set(v):
		if v <= .25: v = .25
		if v >= 10: v = 10
		
		scale = v
		CK_ScaleChanged.emit(scale)
@export var ck_split_offset:float = 600:
	set(v):
		ck_split_offset = v
		CK_SplitOffsetChanged.emit(ck_split_offset)

func setSize(x:int, y:int)->void:
	window_size = Vector2i(x,y)
	print("size setted")
	pass

func addCompletion(alias:String, result:String)->Error:
	if completions.has(alias): return Error.ERR_ALREADY_EXISTS
	completions[alias] = result
	return Error.OK

func removeCompletion(alias:String)->Error:
	if !completions.has(alias): return Error.ERR_DOES_NOT_EXIST
	completions.erase(alias)
	return Error.OK
