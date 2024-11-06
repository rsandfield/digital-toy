class_name Logger

# List of valid color names for the [color=<name>] tag:
# aqua
# black
# blue
# fuchsia
# gray
# green
# lime
# maroon
# navy
# purple
# red
# silver
# teal
# white
# yellow

var _color: String

func _init(color: String):
    _color = color

func print(msg):
    print_rich("[color=%s]%s[/color]" % [_color, msg])