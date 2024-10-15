class_name DrawingSurface
extends StaticBody3D


enum Shape {
    CIRCLE,
    RECTANGLE,
}

@export var draw_group: String
@export var background_color: Color
@export var pixels_per_meter := 1000


var _image: Image
var _texture: ImageTexture
var _material: StandardMaterial3D

func _ready():
    var mesh_instance = $MeshInstance3D
    _material = StandardMaterial3D.new()
    mesh_instance.material_override = _material

    var size = (mesh_instance.mesh as QuadMesh).size * pixels_per_meter
    _image = Image.create_empty(size.x, size.y, false, Image.Format.FORMAT_RGBA8)
    _image.fill(background_color)
    _refresh()


func get_draw_group() -> String:
    return draw_group


func global_to_position(touched: Vector3) -> Vector2i:
    var local = to_local(touched) * pixels_per_meter
    return Vector2i(local.x, -local.y) + _image.get_size() / 2

func _refresh():
    _texture = ImageTexture.create_from_image(_image)
    _material.set("albedo_texture", _texture)


func _erase():
    _image.fill(background_color)


func draw_circle(origin: Vector2i, size: int, color: Color):
    var bounds = _image.get_size()
    for i in range (-size, size):
        for j in range (-size, size):
            var point = origin + Vector2i(i, j)
            if (
                point.x < 0 || point.x >= bounds.x ||
                point.y < 0 || point.y >= bounds.y
            ):
                continue
            if (i * i + j * j) < size * size:
                _image.set_pixelv(point, color)
    _refresh()


func draw_rectangle(origin: Vector2i, size: Vector2i, color: Color):
    var bounds = _image.get_size()
    var offset = origin - size / 2
    for i in range (size.x):
        for j in range (size.y):
            var point = offset + Vector2i(i, j)
            if (
                point.x < 0 || point.x >= bounds.x ||
                point.y < 0 || point.y >= bounds.y
            ):
                continue
            _image.set_pixelv(point, color)
    _refresh()
