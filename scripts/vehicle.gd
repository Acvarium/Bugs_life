extends KinematicBody2D
var velocity = Vector2(0,0)
var max_speed = 100
const MAX_SPEED = 100
const MAX_FORCE = 0.5
var max_force = 0.5
var health = 75.0
var lifetime = 0
var max_lifetime = 300
var time_of_death 
var decomposition_time = 5
var food_container 
var pine = 0.05
var for_reproduction = 150
var dna = [3,-1,300, 50]
var main_node
var debug_vision = false
signal mult(dna)

var appearance = [
load("res://textures/bugs/0.png"),
load("res://textures/bugs/plus1.png"),
load("res://textures/bugs/plus2.png"),
load("res://textures/bugs/plus3.png"),
load("res://textures/bugs/plus4.png"),
load("res://textures/bugs/plus5.png")]

const COLORS = [
Color(1,1,1),						#Білий					0
Color(1,0,0),						#Червоний				1
Color(1.0, 0.5, 0.0),				#Помаранчеві			2
Color(0.65, 0.65, 0.0),				#Жовті					3
Color(0,0.6,0,1),					#Зелені					4
Color(0,1,1),						#Блакитний				5
Color(0,0,1),						#Сині					6
Color(0.65, 0.0, 0.65),				#Фіолетові				7
Color(0.2, 0.2, 0.9),				#Темно синій			8
Color(0.7, 0.2, 0.0),				#Коричневий				9
Color(1, 0.6, 0.1),					#Рожевий				10
Color(0.5, 1, 0.7),					#Ізумрудний				11
]

func _ready():
	randomize()
	main_node = get_tree().get_root().get_node("main")
	debug_vision = main_node.debug_vision
	self.connect('mult',main_node, "_multiply")
	add_to_group("vehicle")
	get_node("h_rot/health/dnaSS").set_text(str(dna[0]) + ', ' + str(dna[1]))
	get_node("h_rot/health/nameSS").set_text(get_name())
	set_fixed_process(true)
	food_container = main_node.get_node("food_container")
	get_node("Sprite").set_texture(appearance[abs(dna[0])])
	if dna[0] < 0:
		get_node("w").set_modulate(Color(1.0, 0.0, 0.0))
	if dna[1] >= 0:
		get_node("Sprite").set_modulate(COLORS[dna[1]])
	else:
		
		get_node("Sprite").set_modulate(COLORS[abs(dna[1]) + 6])


func _fixed_process(delta):
	lifetime += delta 
	if main_node.debug_vision != debug_vision:
		debug_vision = main_node.debug_vision
		update()
	if time_of_death:
#		var c = COLORS[dna[1]]
#		var death_color = 1 - (lifetime - time_of_death) / decomposition_time
#		c.r *= death_color
#		c.g *= death_color
#		c.b *= death_color
#		get_node("Sprite").set_modulate(c)
		if lifetime - time_of_death > decomposition_time:
			queue_free()
		get_node("h_rot/health/lifetimeSS").set_text(str("%4.2f" % time_of_death))
		velocity = Vector2(0,0)
	else:
		get_node("h_rot/health/lifetimeSS").set_text(str("%4.2f" % lifetime))
		velocity += behavier(get_tree().get_root().get_node("main").food_list, get_tree().get_root().get_node("main").poison_list)
		var a = atan2(velocity.x,velocity.y)
		set_rot(a)
		get_node("h_rot").set_rot(-a)
	move(velocity * delta)
	set_health(health - pine)

func set_dna(DNA):
	for i in range(DNA.size()):
		dna[i] = DNA[i]

func get_dna():
	return(dna)

func _draw():
	if main_node.debug_vision:
		get_node("h_rot/health/lifetimeSS").show()
		get_node("h_rot/health/healthSS").show()
		get_node("h_rot/health/dnaSS").show()
		get_node("h_rot/health/nameSS").show()
		var green = Color(0.0, 1.0, 0.0, 0.5)
		var red = Color(1.0, 0.0, 0.0, 0.5)
		draw_circle_arc( dna[2], green )
		draw_circle_arc( dna[3], red )
		draw_line(Vector2(0,0), Vector2(0,dna[0] * 50), green)
		draw_line(Vector2(0,0), Vector2(0,dna[1] * 50), red)
	else:
		get_node("h_rot/health/lifetimeSS").hide()
		get_node("h_rot/health/healthSS").hide()
		get_node("h_rot/health/dnaSS").hide()
		get_node("h_rot/health/nameSS").hide()

func draw_circle_arc(radius, color ):
    var nb_points = 32
    var points_arc = Vector2Array()
    for i in range(nb_points+1):
        var angle_point = i*(360)/nb_points - 90
        var point = Vector2( cos(deg2rad(angle_point)), sin(deg2rad(angle_point)) ) * radius
        points_arc.push_back( point )
    for indexPoint in range(nb_points):
        draw_line(points_arc[indexPoint], points_arc[indexPoint+1], color)


func behavier(good, bad):
	var foodSteer = eat(good, dna[2])
	var poisonSteer = eat(bad, dna[3])
	
	foodSteer *= dna[0]
	poisonSteer *= dna[1]
	return (foodSteer + poisonSteer)

func get_health():
	return(health)

func set_health(h):
	health = h
#	max_speed = (1 - (lifetime/max_lifetime)) * MAX_SPEED
#	max_force = (1 - (lifetime/max_lifetime)) * MAX_FORCE
	if health > for_reproduction:
		health = health / 2
		emit_signal('mult', dna)
	if health < 0:
		if !time_of_death:
			time_of_death = lifetime
#		get_node("CollisionShape2D").set_trigger(true)
		health = 0
		max_speed = 0
	var c = COLORS[dna[1]]
#	var death_color = 1 - (lifetime - time_of_death) / decomposition_time
	var death_color = (health / for_reproduction)
	c.r *= death_color
	c.g *= death_color
	c.b *= death_color

	get_node("Sprite").set_modulate(c)
#	get_node("glow").set_modulate(Color(1, 1, 1,health / 150))
	get_node("h_rot/health/healthSS").set_text(str("%4.1f" %  health))
	
func eat(list, perception):
	var steering = Vector2(0,0)
	var pos = get_global_pos()
	var record = 9999999999.0
	var nearest
	for f in list.keys():
		var dist = (pos - list[f]).length()
		if dist < record and dist < perception:
			nearest = f 
			record = dist
	if nearest:
		if food_container.has_node(nearest):
			var target_obj = food_container.get_node(nearest)
			var desired = target_obj.get_pos() - get_pos()
			desired = desired.normalized() * max_speed
			steering = (desired - velocity).clamped(max_force)
	if steering.length() == 0:
		steering = Vector2((randf()-0.5) * max_force,(randf() - 0.5) * max_force).clamped(max_force)
	return(steering)

