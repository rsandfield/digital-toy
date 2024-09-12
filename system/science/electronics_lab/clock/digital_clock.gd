class_name DigitalCLock
extends Node3D

@onready var _textMesh: TextMesh = ($Text as MeshInstance3D).mesh as TextMesh

func _process(_delta):
	var time = Time.get_time_dict_from_system()
	_textMesh.text = "%0*d:%0*d" % [2, time["hour"], 2, time["minute"]]
