extends Node2D
signal eated(f_name, v_name)
var health = 5
var icons = [
load("res://textures/food/1.png"),
load("res://textures/food/2.png"),
load("res://textures/food/3.png"),
load("res://textures/food/4.png"),
load("res://textures/food/5.png"),
load("res://textures/food/6.png"),
load("res://textures/food/7.png"),
load("res://textures/food/8.png"),
load("res://textures/food/9.png"),
load("res://textures/food/10.png"),
load("res://textures/food/11.png")]

var poison_icon = load("res://textures/poison.png")
var debug_vision = false
var main_node

func get_health():
	return(health)

func set_health(h):
	health = h
	if health <= 0:
		health = -30
		get_node("sprite").set_texture(poison_icon)
	else:
		get_node("sprite").set_texture(icons[health])
		health += 5
		
		
func _ready():
	main_node = get_tree().get_root().get_node("main")
	debug_vision = main_node.debug_vision
	get_node("Label").set_text(get_name())
	self.connect('eated',main_node, "_eated_mess")
	

func _on_Area2D_body_enter( body ):
	if body.is_in_group("vehicle"):
		emit_signal('eated', get_name(), body.get_name())

