extends SubViewport

var running: bool = false
var elapsed: float = 0
var score: int = 0
var hud: SclGui
var lander: SclLander
var terrain: SclTerrain

func _ready():
	hud = $HUD
	lander = $SclLander
	terrain = $SclTerrain

func _process(delta: float):
	if running:
		elapsed += delta
		hud.set_time(elapsed)
		hud.set_altitude(_ship_altitude())
		hud.set_horizontal_speed(lander.speed.x)
		hud.set_vertical_speed(-lander.speed.y)

func _ship_altitude():
	return terrain.height_at(lander.position.x) - lander.position.y

func start_game():
	running = true
	lander.running = true
	terrain.build_terrain(size, 384, 128)

func _reset():
	running = false
	elapsed = 0
	score = 0
	lander.reset(size * 0.5)
