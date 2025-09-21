@tool
extends Node

signal ClearLineEdit()
signal LogMade(log:LogResource)
signal LogsCleared()



var logs:Array[LogResource] = []

const CONFIG_PATH:String = "res://addons/clever_keys/config/completions.tres"
const HARPOON_PATH:String = "res://addons/clever_keys/config/harpoon.tres"
const DEFAULT_LABEL_SETTINGS = preload("res://addons/clever_keys/config/default.tres")

signal CurrentDirChanged(newDir:String)

var api:CKAPI = CKAPI.new()

var currentDir:String = "res://":
	set(v):
		currentDir = v
		CurrentDirChanged.emit(currentDir)

var targetScene:PackedScene = preload("res://addons/clever_keys/scenes/ck_window_scene.tscn")

var macros:CKMacros = CKMacros.new()

signal UIChanged(instance:CKWindow)
var uiInstance:CKWindow:
	set(v):
		uiInstance = v
		UIChanged.emit(uiInstance)

var pressed:bool = false

var canClose:bool = false

var config:CleverKeysConfig
var harpoon:CKHarpoon

var toggled:bool = false:
	set(v):
		toggled = v

func getCompletions()->Dictionary[String, String]:
	return config.completions if config != null else []

func clearLogs()->void:
	logs.clear()
	LogsCleared.emit()
	pass



func onEcho(args:PackedStringArray):
	var content:String = ""
	for _a:String in args:
		content += String(_a)
	makeLogContent(content)
	pass

func helpCommand()->void:
	var content:String ="
	=== Help ===
	echo: echo args...
		?: Repeats the args
	clear:
		?: clears the Log
	+file: +file <path> <extending class?> <class name?>\
		?: creates a file on the desired path
		Alias: +f, file
	add_completion: add_completion <alias> <result>
		?: create custom completions
		Alias: +ac / -ac (-ac is remove_completion, works the same)
	harpoon: harpoon <add / remove / open> <name>
		?: registers, removes or opens the saved resource
		Alias:
			-ha -> harpoon add
			-hr -> harpoon remove
			-ho -> harpoon open
	ck_ws: changes the window size -> CleverKeys_WindowSize
		?: ck_ws <X> <Y>
	
	: -> Goes to line
		?: \": 10\" <--- this goes to line 10 on the current opened script
	
	"
	makeLogContentAndColor(Color.ORANGE, content)
	pass

func onCommandsCommand()->void:
	var content:String = "
	-> ck_window_size <x> <y>
	-> ck_scale <factor>
	-> ck_split_offset <offset>
	
	-> +file <path> <extending class?> <class name?>
	-> echo <args>
	-> clear
	-> add_completion <alias> <result>
	-> remove_completion <alias>
	
	-> -ho <name> // open harpoon file
	-> -ha <name> // add harpoon file
	-> -hr <name> // remove harpoon file
	-> : <Line> // goto line
	
	-> help
	
	-> ls <path?> / list <path?>
	-> cd <path>
	
	"
		
	makeLogContentAndColor(Color.ORANGE, content)
	pass

func onChangeDirectoryCommand(args: PackedStringArray) -> void:
	if args.size() == 0:
		printerr("Falta la ruta.")
		return

	var target := args[0]

	var newDir: String
	if target == "..":
		newDir = currentDir.get_base_dir()
	elif target.begins_with("res://") or target.begins_with("user://"):
		newDir = target
	else:
		newDir = currentDir.path_join(target)

	newDir = ProjectSettings.globalize_path(newDir)
	newDir = ProjectSettings.localize_path(newDir)

	if DirAccess.dir_exists_absolute(newDir):
		currentDir = newDir
	#else:

func onListCommand(args:PackedStringArray)->void:
	var targetPath:String = args[0] if args.size() > 0 else currentDir
	var content:String = "list --> %s\n" %targetPath
	var directories := DirAccess.get_directories_at(targetPath)
	directories.sort()
	var files := DirAccess.get_files_at(targetPath)
	for d:String in directories:
		content += "    %s    📁\n"%d
	for f:String in files:
		content += "    %s    📄\n"%f
	makeLogContent(content)
	pass

func handleMacroCommand(args:PackedStringArray)->void:
	if args.size() == 0: return	
	var alias:String = args[0]
	
	var target:String = macros.getMacro(alias)
	
	api.addTextOnCaret(api.getCurrentScriptTextEditor(), target)
	
	pass





func handleCommand(option:String, args:PackedStringArray, full:String)->void:
	if history: history.addCommand(full)
	match option:
		"-m": handleMacroCommand(args)
		"ck_scale": if args.size() > 0: config.scale = abs(float(args[0]))
		"ck_split_offset": if args.size() > 0: config.ck_split_offset = abs(float(args[0]))
		"cd": onChangeDirectoryCommand(args)
		"ls": onListCommand(args)
		"list": onListCommand(args)
		"echo": onEcho(args)
		"clear": clearLogs()
		"commands": onCommandsCommand()
		"+file":_handleFileCommand(args)
		"+f":_handleFileCommand(args)
		"file": _handleFileCommand(args)
		"add_completion": _handleAddCompletion(args)
		"remove_completion": _handleRemoveCompletion(args)
		"harpoon": handleScriptCommand(args)
		"-ho":
			if args.size() >0 and !args[0].is_empty():
				scriptCommand_Open(args[0] as StringName)
		"-ha":
			if args.size() >0 and !args[0].is_empty():
				scriptCommand_Add(args[0] as StringName)
		"-hr":
			if args.size() >0 and !args[0].is_empty():
				scriptCommand_Remove(args[0] as StringName)
		"ck_window_size": ckWindowSize(args)
		":": handleGotoLine(args)
		"help": helpCommand()
	ClearLineEdit.emit()
	if is_instance_valid(uiInstance):
		uiInstance.getFocus()

	pass

func ckWindowSize(args:PackedStringArray)->void:
	if args.size() < 2:
		makeLogErr("Wrong use of command!\nExample: ck_ws 500 600\nUsage?:\n	arg1 = Window X\n	arg2 = Window Y")
		return
	
	var x:String = args[0]
	var y:String = args[1]
	
	if x == ".": x = str(config.window_size.x)
	if y == ".": y = str(config.window_size.y)
	
	config.setSize(abs(int(x)), abs(int(y)))
	canClose = false
	pass


func handleScriptCommand(args:PackedStringArray)->void:
	# script <add / remove / open> <name>
	#				0				1
	#print("args: %s" %args.size())
	if args.size() <= 1 || args[1].is_empty():
		#error
		return
	
	var option:String = args[0]
	var targetName:StringName = StringName(args[1])
	
	#print("option: %s\ntargetName: %s" %[option, targetName])
	
	match option:
		"add": scriptCommand_Add(targetName)
		"remove": scriptCommand_Remove(targetName)
		"open": scriptCommand_Open(targetName)
	
	
	pass
func scriptCommand_Open(targetName:StringName)->void:
	harpoon.openFile(targetName)
	pass
func scriptCommand_Remove(targetName:StringName)->void:
	harpoon.removeFile(targetName)
	makeLogContent("File deleted")
	canClose = false
	pass



func scriptCommand_Add(targetName:StringName)->void:
	var path:String = EditorInterface.get_script_editor().get_current_script().resource_path
	harpoon.addFile(targetName, path)
	makeLogContent("Added")
	canClose = false
	pass

func handleGotoLine(args:PackedStringArray)->void:
	var targetLine:int = abs(int(args[0])) 
	
	
	EditorInterface.get_script_editor().goto_line(targetLine-1)
	destroyUI()
	pass

var history:CKCommandHistory = CKCommandHistory.new()

func _ready() -> void:
	self.add_child(api)
	self.add_child(history)
	self.add_child(macros)
	
	config = ResourceLoader.load(CONFIG_PATH) as CleverKeysConfig
	harpoon = _getHarpoonResource()
	
	pass

func _getHarpoonResource()->CKHarpoon:
	var h:CKHarpoon = ResourceLoader.load(HARPOON_PATH)
	if h == null:
		h = CKHarpoon.new()
		ResourceSaver.save(h, HARPOON_PATH)
	return h

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton: destroyUI()
	pass

func _process(delta) -> void:
	pressed = Input.is_key_pressed(KEY_F3) || Input.is_key_pressed(KEY_CTRL) and Input.is_key_pressed(KEY_SHIFT) and Input.is_key_pressed(KEY_C)
	if Input.is_key_pressed(Key.KEY_ESCAPE) or Input.is_key_pressed(Key.KEY_CTRL) and Input.is_key_pressed(KEY_SHIFT) and Input.is_key_pressed(Key.KEY_C): destroyUI()
	if pressed:
		createIU()
	pass

func destroyUI()->bool:
	if is_instance_valid(uiInstance) and canClose:
		uiInstance.queue_free()
		return true
	canClose = true
	return false



func createIU()->void:
	if is_instance_valid(uiInstance) || uiInstance != null: return
	if destroyUI(): return
	uiInstance = targetScene.instantiate() as CKWindow
	add_child(uiInstance)
	pass

func _handleAddCompletion(args:PackedStringArray)->void:
	if args.size() < 2: return
	var alias:String = args[0] 
	var completion:String = args[1]
	var result := config.addCompletion(alias, completion)
	if result == Error.OK: makeLogContentAndPrefix(":", "New completion added!\nAlias:%s\nCompletion:%s" %[alias, completion])
	else: makeLog(Color.RED, true, ":", "New completion added!\nAlias:%s\nCompletion:%s" %[alias, completion])
	
	pass

func _handleRemoveCompletion(args:PackedStringArray)->void:
	if args.size() < 2: return
	var alias:String = args[0]
	var result := config.removeCompletion(alias)
	
	if result == Error.OK: makeLogContentAndColor(Color.ORANGE, "Completion removed: %s" %alias)
	else: makeLog(Color.RED, true, ":", "Alias DOES NOT Exists!: %s" %alias)
	pass

func _handleFileCommand(args:PackedStringArray) -> void:
	if args.size() == 0: return
	var rawPath:String = args[0]
	var fullPath:String
	if rawPath.begins_with("res://"):
		fullPath = rawPath
	else:
		fullPath = currentDir.rstrip("/") + "/" + rawPath

	var dirPath:String = fullPath.get_base_dir()
	var fileName:String = fullPath.get_file()

	print("Full path: %s" % fullPath)

	var extending:String = ""
	var className:String = ""

	if fileName.get_extension() == "gd":
		extending = "extends Node"
		className = "#class_name CustomClass"

	if args.size() > 1:
		extending = "extends %s" % args[1]
	if args.size() > 2:
		className = "class_name %s" % args[2]

	ensure_dirs(dirPath)

	if !FileAccess.file_exists(fullPath):
		var file := FileAccess.open(fullPath, FileAccess.WRITE)
		if file:
			file.store_string("%s\n%s\n\n\n" % [extending, className])
			file.close()

	EditorInterface.edit_resource(load(fullPath))
	destroyUI()



func ensure_dirs(path: String) -> void:
	path = path.replace("\\", "/")
	
	var base := ""
	if path.begins_with("res://"):
		base = "res://"
		path = path.substr(6)
	elif path.begins_with("user://"):
		base = "user://"
		path = path.substr(7)

	path = path.trim_suffix("/")

	var parts = path.split("/")
	var current = base
	for part in parts:
		if part == "":
			continue
		current = current.path_join(part)
		if !DirAccess.dir_exists_absolute(current):
			var err = DirAccess.make_dir_absolute(current)
			if err != OK:
				push_error("No se pudo crear carpeta: %s (Error %s)" % [current, err])
	EditorInterface.get_resource_filesystem().scan()

func makeLog(color:Color = Color.WHITE, showPrefix:bool = true, prefix:String = "[Log]", content:String = "")->void:
	var log:LogResource = LogResource.new(color, "[%s]: %s" %[prefix, content] if showPrefix else content)
	logs.append(log)
	LogMade.emit(log)
	pass

func makeLogErr(content:String)->void:
	makeLog(Color.RED, true, "[Err]", content)
	pass

func makeLogContentAndPrefix(prefix:String = "[Log]", content:String = "")->void:
	var log:LogResource = LogResource.new(Color.WHITE, "[%s]: %s" %[prefix, content])
	logs.append(log)
	LogMade.emit(log)
	pass

func makeLogContent(content:String = "")->void:
	var log:LogResource = LogResource.new(Color.WHITE, content)
	logs.append(log)
	LogMade.emit(log)
	pass

func makeLogContentAndColor(color:Color, content:String = "")->void:
	var log:LogResource = LogResource.new(color, content)
	logs.append(log)
	LogMade.emit(log)
	pass
