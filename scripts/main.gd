extends Node3D

const STARTING_COINS := 5000
const BUILD_COSTS := {"carousel": 1200, "ferris": 2400, "tree": 100, "path": 25}
const RIDE_TICKET_PRICE := 35
const ENTRY_TICKET_PRICE := 10
const MAX_VISITORS := 14
const VISITOR_SPAWN_SECONDS := 3.5

var coins := STARTING_COINS
var selected_build := ""
var camera_pivot: Node3D
var camera: Camera3D
var coins_label: Label
var visitors_label: Label
var hint_label: Label
var build_buttons: Dictionary = {}
var touch_dragged := false
var visitors: Array[Dictionary] = []
var rides: Array[Dictionary] = []
var spawn_timer := 1.0
var total_visitors := 0
var total_income := 0

var grass_material: StandardMaterial3D
var path_material: StandardMaterial3D
var wood_material: StandardMaterial3D
var leaf_material: StandardMaterial3D
var red_material: StandardMaterial3D
var yellow_material: StandardMaterial3D
var blue_material: StandardMaterial3D
var cream_material: StandardMaterial3D
var skin_material: StandardMaterial3D
var shirt_materials: Array[StandardMaterial3D] = []


func _ready() -> void:
	_create_materials()
	_create_environment()
	_create_ground()
	_create_entrance()
	_create_starter_decoration()
	_create_camera()
	_create_ui()
	_update_hud()
	_set_hint("Построй аттракцион, чтобы привлечь посетителей и зарабатывать монеты")


func _process(delta: float) -> void:
	_update_visitors(delta)
	_animate_rides(delta)
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = VISITOR_SPAWN_SECONDS
		_spawn_visitor()


func _create_materials() -> void:
	grass_material = _material(Color("#79c96b"))
	path_material = _material(Color("#e9d7ad"))
	wood_material = _material(Color("#9b603b"))
	leaf_material = _material(Color("#36a96b"))
	red_material = _material(Color("#f05b63"))
	yellow_material = _material(Color("#ffd45c"))
	blue_material = _material(Color("#59b9e8"))
	cream_material = _material(Color("#fff0cf"))
	skin_material = _material(Color("#f2bd91"))
	shirt_materials = [
		_material(Color("#f06b68")),
		_material(Color("#5a9fe8")),
		_material(Color("#f2c94c")),
		_material(Color("#a77be8")),
		_material(Color("#54b99a"))
	]


func _material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.9
	return result


func _create_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#328ac5")
	sky_material.sky_horizon_color = Color("#b9e3f5")
	sky_material.ground_bottom_color = Color("#536b49")
	sky_material.ground_horizon_color = Color("#b9d7a5")
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#d8e9ff")
	environment.ambient_light_energy = 0.65
	world.environment = environment
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)


func _create_ground() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(100.0, 100.0)
	ground.mesh = plane
	ground.material_override = grass_material
	ground.position.y = -0.12
	add_child(ground)

	for x in range(-2, 3):
		for z in range(5, 9):
			_add_box(Vector3(float(x) * 2.0, 0.015, float(z) * 2.0), Vector3(1.95, 0.08, 1.95), path_material)


func _create_entrance() -> void:
	_add_box(Vector3(0, 2.2, 17.0), Vector3(12.0, 0.55, 0.65), red_material)
	_add_box(Vector3(-5.5, 1.1, 17.0), Vector3(0.65, 2.2, 0.65), cream_material)
	_add_box(Vector3(5.5, 1.1, 17.0), Vector3(0.65, 2.2, 0.65), cream_material)
	_add_box(Vector3(0, 2.65, 17.0), Vector3(3.8, 0.55, 0.7), yellow_material)
	_add_box(Vector3(0, 0.12, 11.0), Vector3(3.0, 0.18, 12.0), path_material)


func _create_starter_decoration() -> void:
	for i in range(10):
		var x := -18.0 + float(i) * 4.0
		_create_tree(Vector3(x, 0.0, -15.0))
		_create_tree(Vector3(x, 0.0, 21.0))
	for i in range(5):
		_create_tree(Vector3(-21.0, 0.0, -10.0 + float(i) * 7.0))
		_create_tree(Vector3(21.0, 0.0, -10.0 + float(i) * 7.0))


func _create_camera() -> void:
	camera_pivot = Node3D.new()
	add_child(camera_pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0.0, 23.0, 31.0)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	camera.fov = 52.0
	camera.current = true
	camera_pivot.add_child(camera)


func _create_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	layer.add_child(root)

	coins_label = Label.new()
	coins_label.position = Vector2(24, 18)
	coins_label.add_theme_font_size_override("font_size", 30)
	coins_label.add_theme_color_override("font_color", Color.WHITE)
	coins_label.add_theme_color_override("font_shadow_color", Color("#263c35"))
	coins_label.add_theme_constant_override("shadow_offset_x", 2)
	coins_label.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(coins_label)

	visitors_label = Label.new()
	visitors_label.position = Vector2(24, 58)
	visitors_label.add_theme_font_size_override("font_size", 19)
	visitors_label.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(visitors_label)

	hint_label = Label.new()
	hint_label.position = Vector2(24, 88)
	hint_label.add_theme_font_size_override("font_size", 16)
	hint_label.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(hint_label)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -365
	panel.offset_right = 365
	panel.offset_top = -108
	panel.offset_bottom = -14
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.16, 0.19, 0.9)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	_add_build_button(row, "Карусель\n🪙 1 200", "carousel")
	_add_build_button(row, "Колесо 🔒\n🪙 2 400", "ferris")
	_add_build_button(row, "Дерево\n🪙 100", "tree")
	_add_build_button(row, "Дорожка\n🪙 25", "path")
	_add_clear_button(row)


func _add_build_button(parent: HBoxContainer, caption: String, build_type: String) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(132, 72)
	button.add_theme_font_size_override("font_size", 17)
	button.pressed.connect(_select_build.bind(build_type))
	parent.add_child(button)
	build_buttons[build_type] = button


func _add_clear_button(parent: HBoxContainer) -> void:
	var button := Button.new()
	button.text = "Отмена"
	button.custom_minimum_size = Vector2(90, 72)
	button.add_theme_font_size_override("font_size", 16)
	button.pressed.connect(_select_build.bind(""))
	parent.add_child(button)


func _select_build(build_type: String) -> void:
	selected_build = build_type
	if selected_build == "":
		_set_hint("Строительство выключено. Перетаскивай экран для вращения камеры")
	else:
		_set_hint("Выбрано: " + _build_name(build_type) + ". Коснись свободного места")
	for key in build_buttons:
		var button: Button = build_buttons[key]
		button.modulate = Color("#ffe28a") if key == selected_build else Color.WHITE


func _build_name(build_type: String) -> String:
	match build_type:
		"carousel":
			return "Карусель"
		"ferris":
			return "Колесо обозрения"
		"tree":
			return "Дерево"
		"path":
			return "Дорожка"
	return "Объект"


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		touch_dragged = true
		camera_pivot.rotate_y(-event.relative.x * 0.005)
		camera.position.y = clampf(camera.position.y + event.relative.y * 0.035, 12.0, 38.0)
	elif event is InputEventMagnifyGesture:
		_zoom_camera(1.0 / event.factor)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(0.88)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(1.12)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_try_place(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			touch_dragged = false
		elif not touch_dragged:
			_try_place(event.position)


func _zoom_camera(factor: float) -> void:
	camera.position *= factor
	camera.position.y = clampf(camera.position.y, 12.0, 38.0)
	camera.position.z = clampf(camera.position.z, 16.0, 48.0)


func _try_place(screen_position: Vector2) -> void:
	if selected_build == "":
		return
	var origin := camera.project_ray_origin(screen_position)
	var direction := camera.project_ray_normal(screen_position)
	if absf(direction.y) < 0.001:
		return
	var distance := -origin.y / direction.y
	if distance < 0.0:
		return
	var hit := origin + direction * distance
	if absf(hit.x) > 45.0 or absf(hit.z) > 45.0:
		return
	_place_selected(Vector3(snappedf(hit.x, 2.0), 0.0, snappedf(hit.z, 2.0)))


func _place_selected(position: Vector3) -> void:
	var cost: int = BUILD_COSTS.get(selected_build, 0)
	if coins < cost:
		_set_hint("Не хватает монет для строительства")
		return
	match selected_build:
		"carousel":
			_create_carousel(position)
		"ferris":
			_create_ferris_wheel(position)
		"tree":
			_create_tree(position)
		"path":
			_add_box(position + Vector3(0, 0.04, 0), Vector3(2.0, 0.12, 2.0), path_material)
	coins -= cost
	_update_hud()
	_set_hint(_build_name(selected_build) + " построено! 🪙 " + str(coins))


func _create_tree(position: Vector3) -> void:
	_add_cylinder(position + Vector3(0, 1.0, 0), 0.28, 2.0, wood_material)
	_add_sphere(position + Vector3(0, 2.5, 0), 1.25, leaf_material)
	_add_sphere(position + Vector3(0.75, 2.25, 0.1), 0.75, leaf_material)


func _create_carousel(position: Vector3) -> void:
	var ride := Node3D.new()
	ride.position = position
	add_child(ride)
	_add_cylinder_local(ride, Vector3(0, 0.25, 0), 3.4, 0.5, cream_material)
	_add_cylinder_local(ride, Vector3(0, 2.0, 0), 0.22, 3.2, red_material)
	_add_cylinder_local(ride, Vector3(0, 3.65, 0), 3.0, 0.35, yellow_material)
	var spinning := Node3D.new()
	spinning.position.y = 2.0
	ride.add_child(spinning)
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var seat_position := Vector3(cos(angle) * 2.25, -0.55, sin(angle) * 2.25)
		var seat_color: StandardMaterial3D = red_material if i % 2 == 0 else blue_material
		_add_box_local(spinning, seat_position, Vector3(0.8, 0.8, 0.8), seat_color)
		_add_cylinder_local(spinning, Vector3(cos(angle) * 2.25, 0.45, sin(angle) * 2.25), 0.07, 2.0, cream_material)
	rides.append({"kind": "carousel", "position": position, "node": spinning, "timer": 0.0, "queue": [], "busy": false, "queue_capacity": 6})


func _create_ferris_wheel(position: Vector3) -> void:
	var ride := Node3D.new()
	ride.position = position
	add_child(ride)
	_add_box_local(ride, Vector3(-2.3, 2.1, 0), Vector3(0.35, 4.2, 0.45), blue_material)
	_add_box_local(ride, Vector3(2.3, 2.1, 0), Vector3(0.35, 4.2, 0.45), blue_material)
	var wheel := Node3D.new()
	wheel.position = Vector3(0, 4.1, 0)
	ride.add_child(wheel)
	_add_torus_local(wheel, Vector3.ZERO, 3.0, 0.16, yellow_material)
	_add_cylinder_local(wheel, Vector3.ZERO, 0.35, 0.45, red_material)
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var spoke := _add_box_local(wheel, Vector3(cos(angle) * 1.5, sin(angle) * 1.5, 0), Vector3(3.0, 0.09, 0.12), cream_material)
		spoke.rotation.z = angle
		var gondola := _add_box_local(wheel, Vector3(cos(angle) * 3.0, sin(angle) * 3.0, 0), Vector3(0.65, 0.55, 0.55), red_material if i % 2 == 0 else blue_material)
		gondola.rotation.z = angle
	rides.append({"kind": "ferris", "position": position, "node": wheel, "timer": 0.0, "queue": [], "busy": false, "queue_capacity": 6})


func _animate_rides(delta: float) -> void:
	for ride in rides:
		var node: Node3D = ride["node"]
		if is_instance_valid(node):
			if ride["kind"] == "carousel":
				node.rotate_y(delta * 0.75)
			else:
				node.rotate_z(delta * 0.22)


func _spawn_visitor() -> void:
	if visitors.size() >= MAX_VISITORS or rides.is_empty():
		return
	var target_index := _find_best_ride()
	if target_index < 0:
		return
	var person := Node3D.new()
	person.position = Vector3(randf_range(-0.7, 0.7), 0, 13.0)
	add_child(person)
	var shirt: StandardMaterial3D = shirt_materials[randi() % shirt_materials.size()]
	_add_capsule_local(person, Vector3(0, 0.85, 0), 0.28, 1.1, shirt)
	_add_sphere_local(person, Vector3(0, 1.65, 0), 0.25, skin_material)
	var queue: Array = rides[target_index]["queue"]
	queue.append(person.get_instance_id())
	rides[target_index]["queue"] = queue
	var target := _queue_position(target_index, queue.size() - 1)
	visitors.append({"node": person, "target": target, "state": "walking", "wait": 0.0, "ride_index": target_index})
	coins += ENTRY_TICKET_PRICE
	total_visitors += 1
	total_income += ENTRY_TICKET_PRICE
	_update_hud()
	_set_hint("Новый посетитель вошёл в парк: +🪙 " + str(ENTRY_TICKET_PRICE))


func _find_best_ride() -> int:
	var best_index := -1
	var best_load := INF
	for i in range(rides.size()):
		var queue: Array = rides[i]["queue"]
		var capacity: int = rides[i]["queue_capacity"]
		if queue.size() >= capacity:
			continue
		var load := float(queue.size())
		if rides[i]["busy"]:
			load += 0.5
		if load < best_load:
			best_load = load
			best_index = i
	return best_index


func _queue_position(ride_index: int, queue_index: int) -> Vector3:
	var ride_position: Vector3 = rides[ride_index]["position"]
	return ride_position + Vector3(0, 0, 4.0 + float(queue_index) * 1.15)


func _find_visitor_queue_index(ride_index: int, person_id: int) -> int:
	var queue: Array = rides[ride_index]["queue"]
	return queue.find(person_id)


func _remove_visitor_from_queue(ride_index: int, person_id: int) -> void:
	if ride_index < 0 or ride_index >= rides.size():
		return
	var queue: Array = rides[ride_index]["queue"]
	var index := queue.find(person_id)
	if index >= 0:
		queue.remove_at(index)
		rides[ride_index]["queue"] = queue


func _update_visitors(delta: float) -> void:
	for i in range(visitors.size() - 1, -1, -1):
		var visitor: Dictionary = visitors[i]
		var person: Node3D = visitor["node"]
		var ride_index: int = visitor["ride_index"]
		if not is_instance_valid(person):
			visitors.remove_at(i)
			continue
		if ride_index < 0 or ride_index >= rides.size():
			continue
		var person_id := person.get_instance_id()
		var queue_index := _find_visitor_queue_index(ride_index, person_id)
		if visitor["state"] == "walking":
			if queue_index < 0:
				continue
			var target := _queue_position(ride_index, queue_index)
			visitor["target"] = target
			var direction: Vector3 = target - person.position
			direction.y = 0.0
			if direction.length() < 0.35:
				visitor["state"] = "queued"
			else:
				person.position += direction.normalized() * delta * 2.2
				person.look_at(Vector3(target.x, person.position.y, target.z), Vector3.UP)
		elif visitor["state"] == "queued":
			if queue_index < 0:
				continue
			var target := _queue_position(ride_index, queue_index)
			var direction: Vector3 = target - person.position
			direction.y = 0.0
			if direction.length() > 0.18:
				person.position += direction.normalized() * delta * 2.0
				person.look_at(Vector3(target.x, person.position.y, target.z), Vector3.UP)
			if queue_index == 0 and not rides[ride_index]["busy"] and direction.length() < 0.6:
				rides[ride_index]["busy"] = true
				visitor["state"] = "riding"
				visitor["wait"] = 4.0
				person.position = rides[ride_index]["position"] + Vector3(0, 0.2, 0)
				_set_hint("Аттракцион начал обслуживать посетителя")
		elif visitor["state"] == "riding":
			visitor["wait"] -= delta
			if visitor["wait"] <= 0.0:
				_remove_visitor_from_queue(ride_index, person_id)
				rides[ride_index]["busy"] = false
				coins += RIDE_TICKET_PRICE
				total_income += RIDE_TICKET_PRICE
				visitor["state"] = "leaving"
				visitor["target"] = Vector3(randf_range(-1.0, 1.0), 0, 16.0)
				_update_hud()
				_set_hint("Катание завершено! +🪙 " + str(RIDE_TICKET_PRICE))
		elif visitor["state"] == "leaving":
			var exit_target: Vector3 = visitor["target"]
			var exit_direction := exit_target - person.position
			exit_direction.y = 0.0
			if exit_direction.length() < 0.8:
				person.queue_free()
				visitors.remove_at(i)
				_update_hud()
			else:
				person.position += exit_direction.normalized() * delta * 2.4
				person.look_at(Vector3(exit_target.x, person.position.y, exit_target.z), Vector3.UP)


func _add_box(position: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	add_child(instance)
	return instance


func _add_box_local(parent: Node3D, position: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	parent.add_child(instance)
	return instance


func _add_cylinder_local(parent: Node3D, position: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	parent.add_child(instance)
	return instance


func _add_cylinder(position: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	return _add_cylinder_local(self, position, radius, height, material)


func _add_sphere(position: Vector3, radius: float, material: Material) -> MeshInstance3D:
	return _add_sphere_local(self, position, radius, material)


func _add_sphere_local(parent: Node3D, position: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	parent.add_child(instance)
	return instance


func _add_capsule_local(parent: Node3D, position: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	parent.add_child(instance)
	return instance


func _add_torus_local(parent: Node3D, position: Vector3, radius: float, tube_radius: float, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - tube_radius
	mesh.outer_radius = radius + tube_radius
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	parent.add_child(instance)
	return instance


func _update_hud() -> void:
	if build_buttons.has("ferris"):
		var ferris_button: Button = build_buttons["ferris"]
		ferris_button.disabled = total_visitors < 8
		ferris_button.text = "Колесо 🔒\n🪙 2 400" if total_visitors < 8 else "Колесо\n🪙 2 400"
	if coins_label != null:
		coins_label.text = "PARKORA   🪙 " + _format_number(coins)
	if visitors_label != null:
		visitors_label.text = "👥 " + str(visitors.size()) + " / " + str(MAX_VISITORS) + "    Всего гостей: " + str(total_visitors)


func _format_number(value: int) -> String:
	var raw := str(value)
	var output := ""
	for i in range(raw.length()):
		output += raw[i]
		var remaining := raw.length() - i - 1
		if remaining > 0 and remaining % 3 == 0:
			output += " "
	return output


func _set_hint(message: String) -> void:
	if hint_label != null:
		hint_label.text = message
