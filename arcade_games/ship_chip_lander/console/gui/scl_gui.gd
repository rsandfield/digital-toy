class_name SclGui
extends MarginContainer

func set_score(value: String):
    ($HBoxContainer/game/score_display as Label).text = value

func set_time(value: float):
    var minutes = value / 60 as int
    var seconds = fmod(value, 60) as int
    ($HBoxContainer/game/time_display as Label).text = str(minutes) + ":" + str(seconds)

func set_fuel(value: int):
    ($HBoxContainer/game/fuel_display as Label).text = str(value)

func set_altitude(value: int):
    ($HBoxContainer/vectors/altitude_display as Label).text = str(value)

func set_horizontal_speed(value: int):
    ($HBoxContainer/vectors/horizontal_display as Label).text = str(abs(value))
    ($HBoxContainer/vectors/vertical_arrow as Label).text = _arrow(value, "→", "←")

func set_vertical_speed(value: int):
    ($HBoxContainer/vectors/vertical_display as Label).text = str(abs(value))
    ($HBoxContainer/vectors/vertical_arrow as Label).text = _arrow(value, "↑", "↓")

func _arrow(value: int, pos: String, neg:String) -> String:
    if value > 0:
        return pos
    if value < 0:
        return neg
    return " "
