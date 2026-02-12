@tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("GUIPresser", "Node", preload("gui_presser.gd"), preload("GUIPresser.svg"))

func _exit_tree():
	remove_custom_type("GUIPresser")
