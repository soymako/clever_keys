@tool
extends EditorPlugin


func _enable_plugin() -> void:
	add_autoload_singleton("CK", "autoloads/ck_autoload.gd")
	DirAccess.make_dir_absolute("config")
	pass


func _disable_plugin() -> void:
	remove_autoload_singleton("CK")
pass


func _enter_tree() -> void:
  # Initialization of the plugin goes here.
	pass


func _exit_tree() -> void:
  # Clean-up of the plugin goes here.
	pass
