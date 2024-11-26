class_name MathHelper

static func nonzero_sign(value):
    var s = sign(value)
    if s == 0:
        s = 1
    return s