@tool
extends Resource
class_name CKHarpoon

signal FileAdded(name:String)
signal FileRemoved(name:String)


@export var scripts:Dictionary[StringName, String]

func _save()->void:
	ResourceSaver.save(self, CK.HARPOON_PATH)
	pass

func getFilesList()->Array:
	return scripts.keys()

func _fileExists(_name:StringName)->bool:
	return scripts.has(_name)


func addFile(_name:StringName, path:String)->void:
	scripts[_name] = path
	FileAdded.emit(_name)
	_save()
	pass

func removeFile(_name:StringName)->void:
	if _fileExists(_name): scripts.erase(_name)
	FileRemoved.emit(_name)
	_save()
	pass

func openFile(_name:StringName)->void:
	if !_fileExists(_name): return
	var path:String = scripts[_name]
	
	var res:Resource = ResourceLoader.load(path)
	
	if res:
		EditorInterface.edit_resource(res)
	
	
	
	pass
