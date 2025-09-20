extends Resource
class_name LogResource

@export var color:Color = Color.WHITE
@export var content:String = ""

func _init(color:Color = Color.WHITE, content:String = "") -> void:
	self.color = color
	self.content = content


func getLabel()->Label:
	var label:Label = Label.new()
	label.text = content
	label.label_settings = CK.DEFAULT_LABEL_SETTINGS
	label.self_modulate = color
	return label
