extends Node
class_name CKAPI

signal APILoaded()


var ui:CKWindow = null

func _ready() -> void:
	CK.UIChanged.connect(func(v:CKWindow):
		ui = v
		pass)
	print_rich("[color=gold][CK][/color]: [color=green]API LOADED![/color]")
	APILoaded.emit()
	pass

func getUI()->CKWindow:
	return ui

func addTextOnCaret(target:TextEdit, text:String)->void:
	if target:
		target.insert_text_at_caret(text)
	
	pass



func getCurrentScriptTextEditor(target:Node = EditorInterface.get_script_editor().get_current_editor())->TextEdit:
	for _c:Node in target.get_children():
		if _c is TextEdit:
			print("LO TENGO?: %s" %_c); #TODO
			return _c as TextEdit
		else:
			var result := getCurrentScriptTextEditor(_c)
			if result != null:
				return result
		
	return null
