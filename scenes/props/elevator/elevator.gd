class_name Elevator
extends GameScene

var current_floor: int = 0
@onready var _door: ElevatorDoor = $ElevatorDoor
@onready var _anim: AnimationPlayer = $AnimationPlayer


func reset_elevator():
	select_floor(0)
	_door.open()
	if _door.other_door:
		_door.other_door.open()


func call_to_floor(value: int):
	if current_floor == value:
		return
	
	_door.close()
	if _door.other_door:
		_door.other_door.close()
	await _door.closed

	# await animate_move(current_floor, value)
	print("Moving from %d to %d" % [current_floor, value])
	select_floor(value)

	_door.open()
	if _door.other_door:
		_door.other_door.open()


func animate_move(from: int, to: int):
	var low = from
	var high = to
	var reverse = false
	if to < from:
		low = to
		high = from
		reverse = true

	var animations: Array[String]
	for i in range(abs(high - low)):
		var j = low + i
		animations.append("%d_%d" % [j, j+1])
	if reverse:
		animations.reverse()

	for animation in animations:
		assert(_anim.has_animation(animation), "Elevator %s is missing animation '%s'" % [name, animation])
		if reverse:
			_anim.play_backwards(animation)
		else:
			_anim.play(animation)
		await _anim.animation_finished


func select_floor(value: int):
	current_floor = value
	var other_portal = GameManager.get_portal(dynamic_connections[value])
	_door.set_other_door(other_portal.get_parent())
	_door.other_door.set_other_door(_door)
