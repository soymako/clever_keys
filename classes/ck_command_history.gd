extends Node
class_name CKCommandHistory

var commands:Array[String]
var currentIndex:int = 0:
	set(v):
		if v < 0:
			v = commands.size()-1
		if v > commands.size()-1:
			v = 0
		currentIndex = v
		pass

func getHistory(index:int)->String:
	var targetString:String = ""
	if commands.size() > 0: targetString = commands[currentIndex]
	return targetString

func addCommand(command:String)->void:
	commands.append(command)
	pass
