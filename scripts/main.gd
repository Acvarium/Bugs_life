extends Node2D
var foodObj = load("res://objects/food.tscn") #Інстанцінг об'єкту кульки
var vehicleObj = load("res://objects/vehicle.tscn") #Інстанцінг об'єкту кульки
var food_counter = 0
var vehicle_counter = 0
var food_energy = 10
var poison_energy = -30
var mov_cam = false
var mm_click_pos = Vector2(0,0)
var mm_cam_pos = Vector2(0,0)
var food_list = {}
var poison_list = {}
const MAX_DELTA = 0.05
var max_food_count = 100
var game_time = 0
var food_to_poison = 3
var show_menu = false
var debug_vision = false
var benchmark_mode = false
var smooth_fps = 0
var fps_count = 0
var fps = 0

func _ready():
	randomize()
	benchmark_mode = get_node("/root/global").benchmark_mode
	
	if benchmark_mode:
		get_node("GUILayer/deltaSS").show()
		get_node("GUILayer/bugsSS").show()
	else:
		get_node("GUILayer/bugsSS").hide()
	set_process(true)
	set_fixed_process(true)
	set_process_input(true)
	var screen_resolution = get_viewport().get_rect().size
	max_food_count = (screen_resolution.x * screen_resolution.y / 8000)
	get_node("camera").set_pos(Vector2(screen_resolution.x/2,screen_resolution.y/2))
	var max_f = max_food_count / (food_to_poison + 1) * food_to_poison
	var bugs_num = screen_resolution.x * screen_resolution.y / 16000
	if benchmark_mode:
		max_f = max_food_count
		bugs_num = 50
	for i in range(max_f):
		var rand_pos = Vector2(randf() * screen_resolution.x,randf() * screen_resolution.y)
		var h = randi()%10 + 1
		add_piece_of_food(rand_pos, h)
	if !max_food_count:
		for i in range(food_to_poison - max_f):
			var rand_pos = Vector2(randf() * screen_resolution.x,randf() * screen_resolution.y)
			var h = poison_energy #randi()%2 * 10 - 5
			add_piece_of_food(rand_pos, h)
	
	for i in range(bugs_num):
		var dna = []
		dna.append(randi()%10 - 5) 	#Притягування до їжі
		dna.append(randi()%10 - 5)	#Притягування до яду
		dna.append(randf()*300 + 10)	#Зоркість до їжі
		dna.append(randf()*300 + 10)	#Зоркість до яду
		add_vehicle(dna, false)

func _process(delta):
	if benchmark_mode or debug_vision:
		get_node("GUILayer/bugsSS").set_text(str(get_node("vihicles").get_child_count()))
		fps += delta
		fps_count += 1
		smooth_fps += delta
		if smooth_fps > 0.2:
			get_node("GUILayer/deltaSS").set_text(str("%2.1f" % (1/(fps/fps_count))) + '     ' + str(fps/fps_count) )
			smooth_fps = 0
			fps_count = 0
			fps = 0
	if delta > MAX_DELTA and !benchmark_mode:
		var v = get_node("vihicles").get_child_count()
		if v > 2:
			for i in range(int(delta/ MAX_DELTA)):
				var to_die = randi()%v
				var destiny = randf()
				
				if destiny < 1:
					get_node("vihicles").get_child(to_die).queue_free()

func _fixed_process(delta):
	game_time += delta
	var hours = int(game_time / 3600)
	var minutes = int((game_time - (hours * 3600)) / 60)
	var sec = int(game_time - (minutes * 60) - (hours * 3600))
	get_node("CanvasLayer/timeSS").set_text(str("%02d" % hours) + ":" + str("%02d" % minutes) + ":" + str("%02d" % sec))
	
#	get_node("CanvasLayer/timeSS").set_text(str("%3.2f" % game_time))
	var mouse_pos = get_local_mouse_pos()
	if mov_cam:
		get_node("camera").set_pos(mm_cam_pos + (mm_click_pos - mouse_pos))
#

func _input(event):

	if event.is_action_pressed("plus"):
		add_vehicle([3,-1,300,50], true)
		
	if event.is_action_pressed("minus"):
		if get_node("vihicles").get_child_count() > 1:
			var mouse_pos = get_local_mouse_pos()
			var nearest
			var record = 99999999999999.0
			for b in get_node("vihicles").get_children():
				var dist = (mouse_pos - b.get_pos()).length()
				if dist < record:
					nearest = b 
					record = dist
			nearest.queue_free()

	
	if event.is_action_pressed("LMB"):
		add_piece_of_food(get_local_mouse_pos(), randi()%10 + 1)

	if event.is_action_pressed("RMB"):
		add_piece_of_food(get_local_mouse_pos(), poison_energy)
	if event.is_action_pressed("MMB"):
		mm_click_pos = get_local_mouse_pos()
		mm_cam_pos = get_node("camera").get_pos()
		mov_cam = true
	elif event.is_action_released("MMB"):
		mov_cam = false
		
	if event.is_action_pressed("wUp"):
		var zoom = get_node("camera").get_zoom()
		zoom *= 0.95
		get_node("camera").set_zoom(zoom)

	if event.is_action_pressed("wDown"):
		var zoom = get_node("camera").get_zoom()
		zoom *= 1.05
		get_node("camera").set_zoom(zoom)

func add_vehicle(dna, randomize_pos):
	vehicle_counter += 1
	var v = vehicleObj.instance()
	var name = "vehicle" + str(vehicle_counter)
	var screen_resolution = get_viewport().get_rect().size
	
	var rand_pos = Vector2(randf() * screen_resolution.x,randf() * screen_resolution.y)
	v.set_name(name)
	if !benchmark_mode:
		v.set_dna(dna)
	if randomize_pos:
		rand_pos = get_local_mouse_pos()
	v.set_pos(rand_pos)
	get_node("vihicles").add_child(v)

func _multiply(dna):
	add_vehicle(mutation(dna), false)

func copy_array(array):
	var new_array = []
	for i in range(array.size()):
		new_array.append(array[i])
	return(new_array)

func mutation(dna):
	var prob = 0.05
	var new_dna = copy_array(dna)
	for i in range(dna.size()):
		var p = randf()
		if p < prob:
			if i < 2:
				new_dna[i] = (randi()%10 - 5)
			else:
				new_dna[i] = (randf()*300 + 10)
	return(new_dna)
		
func add_piece_of_food(pos,health):
	food_counter += 1
	var f = foodObj.instance()
	var name = "food" + str(food_counter)
	if health < 0:
		name = "poison" + str(food_counter)
		poison_list[name] = pos
	else:
		food_list[name] = pos
	f.set_name(name)
	f.set_pos(pos)
	f.set_health(health)
	get_node("food_container").add_child(f)

func _eated_mess(f_name, v_name):
	if !benchmark_mode:
		var vehicle = get_node("vihicles/" + v_name)
		var food = get_node("food_container/" + f_name)
		vehicle.set_health(vehicle.get_health() + food.get_health())
		if f_name in food_list.keys():
	
			food_list.erase(f_name)
		elif f_name in poison_list.keys():
			poison_list.erase(f_name)
		food.queue_free()

		var screen_resolution = get_viewport().get_rect().size
		var rand_pos = Vector2(randf() * screen_resolution.x,randf() * screen_resolution.y)
		var h = randi()%10 + 1
		if (food_list.size() / food_to_poison) > poison_list.size():
			h = poison_energy
		if food_list.size() + poison_list.size() < max_food_count:
			add_piece_of_food(rand_pos, h)
	

func _on_reset_pressed():
	get_node("/root/global").benchmark_mode = false
	get_tree().reload_current_scene()


func _on_TextureButton_pressed():
	if !show_menu:
		get_node("GUILayer/menu_anim").play("menu_appear")
		show_menu = !show_menu

	else:
		get_node("GUILayer/menu_anim").play_backwards("menu_appear")
		show_menu = !show_menu


func _on_debug_hint_pressed():
	debug_vision = get_node("GUILayer/menu/debug_hint").is_pressed()
	if debug_vision:
		get_node("GUILayer/deltaSS").show()
	else:
		get_node("GUILayer/deltaSS").hide()
			
func _on_benchmark_pressed():
	get_node("/root/global").benchmark_mode = true
	get_tree().reload_current_scene()
