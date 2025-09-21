@tool
extends Window
class_name CKWindow

@export var le:LineEdit

var currentArgIndex:int = 0


var hasSuggestion:bool = false
var suggestedComplete:String = ""

func _ready() -> void:
	le.grab_focus()
	if le:
		le.text_changed.connect(onTextChanged)
		le.text_submitted.connect(onTextSet)
	
	le.edit()

	
	self.grab_focus()
	self.always_on_top = true
	self.borderless = true
	self.close_requested.connect(func():
		self.queue_free()
		pass)
	CK.ClearLineEdit.connect(func():
		le.text = ""
		pass)
	
	CK.LogMade.connect(func(log:LogResource):
		%logContainer.add_child(log.getLabel())
		get_tree().create_timer(.1).timeout.connect(func():
			%logScroll.scroll_vertical += %logScroll.get_v_scroll_bar().max_value
			pass)
		pass)
	
	CK.LogsCleared.connect(func():
		for _c:Node in %logContainer.get_children():
			_c.queue_free()
			pass
		pass)
	
	%SplitContainer.drag_ended.connect(func():
		var value:float = %SplitContainer.split_offset
		CK.config.ck_split_offset = value
		pass)
	
	
	
	CK.config.CK_ScaleChanged.connect(updateScale)
	CK.config.CK_SplitOffsetChanged.connect(updateSplitOffset)
	
	CK.harpoon.FileAdded.connect(func(s:String): addLabelTo(%HarpoonList, s))
	CK.harpoon.FileRemoved.connect(func(s:String): addLabelTo(%HarpoonList, s))
	
	CK.CurrentDirChanged.connect(updateCurrentDirLabel)
	
	CK.config.CKSizeChanged.connect(func(v:Vector2i):
		self.size = v
		print("size: %s" %v)
		pass)

	loadPos()

	loadConfig()
	
	le.keep_editing_on_text_submit = true
	get_tree().create_timer(.001).timeout.connect(func():
		%logScroll.scroll_vertical += %logScroll.get_v_scroll_bar().max_value
		pass)
	
	updateCurrentDirLabel(CK.currentDir)
	
	loadLogs()
	loadHarpoonFiles()
	le.gui_input.connect(func(e):
		#print("e: %s" %e)
		pass)
	
	self.show()
	
	le.focus_mode = Control.FOCUS_ALL
	
	CK.history.currentIndex = CK.history.commands.size()
	updateSplitOffset(CK.config.ck_split_offset)
	updateScale(CK.config.scale)

func updateSplitOffset(v:float)->void:
	%SplitContainer.split_offset = v
	pass

func updateScale(v:float)->void:
	self.content_scale_factor = v
	pass

func updateCurrentDirLabel(dir:String)->void:
	%currentDir.text = "📁 > %s"%dir
	pass

	pass

func _unhandled_input(event: InputEvent) -> void:
	#print("test")
	pass

func loadPos()->void:
	var s:Vector2i = CK.config.window_size
	self.size = s
	
	var base:Control = EditorInterface.get_base_control()
	
	var editor_size: Vector2i = base.size
	var editorPos:Vector2i = base.get_screen_position()
	var center: Vector2i = editorPos + (editor_size - s) / 2
	self.position = center
	pass

func loadConfig()->void:
	self.size = CK.config.window_size
	pass

func addLabelTo(target:Node, text:String)->void:
	if target != null:
		var l:Label = Label.new()
		l.label_settings = CK.DEFAULT_LABEL_SETTINGS
		l.text = text
		l.grab_focus()
		target.add_child(l)
	pass


func loadHarpoonFiles()->void:
	for f:String in CK.harpoon.getFilesList():
		var l:Label = Label.new()
		l.text = f
		l.label_settings = CK.DEFAULT_LABEL_SETTINGS
		%HarpoonList.add_child(l)

	pass

func _process(delta: float) -> void:
	pass

func loadLogs()->void:
	for _log:LogResource in CK.logs:
		%logContainer.add_child(_log.getLabel())
	pass

func getFocus() -> void:
	pass


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if Input.is_key_pressed(KEY_TAB):
			triggerComplete()
		if Input.is_key_pressed(KEY_UP):
			getHistoryCommand(-1)
		if Input.is_key_pressed(KEY_DOWN):
			getHistoryCommand(1)
		
	pass

func getHistoryCommand(v:int)->void:
	CK.history.currentIndex += v
	var command:String = CK.history.getHistory(CK.history.currentIndex)
	if !command.is_empty():
		le.text = command
	
	pass

func triggerComplete() -> void:
	var args := le.text.split(" ", true)
	var currentWord := args[currentArgIndex - 1]

	if CK.getCompletions().has(currentWord):
		var target: String = CK.getCompletions()[currentWord]
		var start := le.text.rfind(currentWord)
		if start != -1:
			le.text = le.text.substr(0, start) + target + le.text.substr(start + currentWord.length())
			le.caret_column = start + target.length()
		return

	#var paths: PackedStringArray = %Directories.text.split(" ", true)
	#var closes: String = closest_match(currentWord, paths, 5)
	#if closes.is_empty():
		#return
#
	#var target: String = closes
	#var start := le.text.rfind(currentWord)
	#if start != -1:
		#le.text = le.text.substr(0, start) + target + le.text.substr(start + currentWord.length())
		## caret justo después de la palabra insertada
		#le.caret_column = start + target.length()









func onTextSet(text:String)->void:
	var rawArgs := text.split(" ", true)
	var option := rawArgs[0]
	var args := rawArgs.slice(1, 10)
	CK.handleCommand(option, args, text)
	CK.history.currentIndex = CK.history.commands.size()
	pass

func onFileRequest(args:PackedStringArray)->void:
	
	pass

func onTextChanged(text:String)->void:
	var args := text.split(" ", true)

	currentArgIndex = args.size()
	updateSuggestions(args[currentArgIndex-1], text.substr(text.length()-1, 1))

	pass

var previousValid:String = "res://"

func updateSuggestions(currentWord:String, currentLetter:String)->void:
	
	var args:PackedStringArray = le.text.split(" ")
	
	var directories:PackedStringArray = []
	if currentArgIndex > 1:
		var globalizedDir:String = ProjectSettings.globalize_path(CK.currentDir)
		directories = DirAccess.get_directories_at(globalizedDir)
	%SuggestionsLabel.text = ""
	%Directories.text = ""
	
	if args[0] == "-m" and currentArgIndex == 2:
		for _m:String in CK.macros.getAllKeys():
			%SuggestionsLabel.text += "%s " %_m
		pass
	
	for option in CK.getCompletions():
		if option[0] == currentLetter:
			$%SuggestionsLabel.text += "%s " %option
	for dir_name in directories:
		%Directories.text += "%s/ " % dir_name 
	pass
	
func levenshtein(s: String, t: String) -> int:
	var m = s.length()
	var n = t.length()
	var dp := []
	dp.resize(m + 1)
	for i in range(m + 1):
		dp[i] = []
		dp[i].resize(n + 1)

	for i in range(m + 1):
		dp[i][0] = i
	for j in range(n + 1):
		dp[0][j] = j

	for i in range(1, m + 1):
		for j in range(1, n + 1):
			var cost = 0 if s[i - 1] == t[j - 1] else 1
			dp[i][j] = min(
				dp[i - 1][j] + 1,       # eliminación
				dp[i][j - 1] + 1,       # inserción
				dp[i - 1][j - 1] + cost # sustitución
			)
	return dp[m][n]

func closest_match(word: String, candidates: PackedStringArray, maxSteps:int = 3) -> String:
	var best_match := ""
	var best_score := INF
	
	for c in candidates:
		var dist = levenshtein(word, c)
		if dist < best_score:
			best_score = dist
			best_match = c
	
	if best_score <= maxSteps:
		return best_match
	return ""
