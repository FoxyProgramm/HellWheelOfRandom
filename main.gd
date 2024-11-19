extends Control

const pi2:float = PI * 2
const default_screen_size := Vector2(1152, 648)

var quality:float = 0.025
var console_state:bool = false
var screen_font_ratio = 18.0 / min(default_screen_size.x, default_screen_size.y)
var big_screen_font_ratio = 28.0 / min(default_screen_size.x, default_screen_size.y)
var wheel_time_rotation:float = 3.0
var idx_option_for_typing:int = 0

class ManageOptions:
	static var options:Array = []
	
	static func is_empty() -> bool:
		if options.size() > 0:
			return false
		return true
	
	static func normalize_options() -> void:
		var sum:float = 0.0
		for option in options:
			sum += option.weight
		for option in options:
			option.normalized_weight = option.weight / sum
	
	static func get_gradient() -> Array:
		var result:Array[float] = [0.0]
		var cur_num:float = 0.0
		normalize_options()
		for option in options:
			cur_num += option.normalized_weight
			result.append(cur_num)
		result[-1] = 1.0
		return result
		
	static func add_option(_option:Option) -> void:
		options.append(_option)
	
	static func remove_option(idx:int) -> void:
		#var new_idx:int = idx
		options[idx].polygon.queue_free()
		options.remove_at(idx)
	static func select_option(value:float) -> int:
		var result = 0
		return result

class Option:
	var name:String
	var weight:float
	var normalized_weight:float = 0.0
	var color: Color
	var polygon:Polygon2D = null
	
	func _init(_name:String, _weight:float, _color:Color) -> void:
		name = _name
		weight = _weight
		color = _color
	
	func sync_polygon() -> void:
		if polygon == null: return
		polygon.color = color
	
	func change_color(_color:Color) -> void:
		color = _color
		sync_polygon()

func _ready() -> void:
	#Connect some signals
	$mc/hbc/vbc/sc/mc/vbc/add.pressed.connect(func():
		var new_polygon = Polygon2D.new()
		$mc/hbc/wheel_handler/wheel/wheel_center.add_child(new_polygon)
		var od = $option_def.duplicate()
		$mc/hbc/vbc/sc/mc/vbc.add_child(od)
		$mc/hbc/vbc/sc/mc/vbc.move_child(od, $mc/hbc/vbc/sc/mc/vbc.get_child_count()-2)
		var rnd_color = Color( randf()/2.0+0.5, randf()/2.0+0.5, randf()/2.0+0.5 )
		var new_option:Option = Option.new(str(ManageOptions.options.size()+1), 1.0, rnd_color)
		new_option.polygon = new_polygon
		ManageOptions.add_option(new_option)
		od.get_node("mc/hbc/expand").pressed.connect(func():
			idx_option_for_typing = od.get_index()
			$text_editor/control/textedit.text = od.get_node("mc/hbc/name_edit").text
			$text_editor.show()
			$text_editor/control/textedit.grab_focus()
			$text_editor/control/textedit.set_caret_column(10)
			$text_editor/control/textedit.set_caret_line(1000)
			)
			
		od.get_node("mc/hbc/name_edit").text = str(ManageOptions.options.size())
		od.get_node("mc/hbc/color").color = rnd_color
		od.get_node("mc/hbc/delete").pressed.connect(func():ManageOptions.remove_option(od.get_index());update_circle();od.queue_free())
		od.get_node("mc/hbc/color").color_changed.connect(func(color:Color): ManageOptions.options[od.get_index()].change_color(color) )
		od.get_node("mc/hbc/name_edit").text_changed.connect(func(new_text:String): ManageOptions.options[od.get_index()].name = new_text)
		od.get_node("mc/hbc/weight_edit").text_changed.connect(func(new_text:String):
			ManageOptions.options[od.get_index()].weight = int(new_text); update_circle() )
		od.show(); update_circle())

	get_tree().get_root().size_changed.connect(func(): 
		update_circle()
		theme.default_font_size = int(screen_font_ratio * min(self.size.x, self.size.y))
		$mc/hbc/wheel_handler/wheel/winner_label.set("theme_override_font_sizes/font_size", int(big_screen_font_ratio * min(self.size.x, self.size.y)))
		)

	$mc/hbc/wheel_handler/hbc/play.pressed.connect(start)
	$mc/hbc/wheel_handler/hbc/reset.pressed.connect(func(): 
		create_tween().tween_property($mc/hbc/wheel_handler/wheel/wheel_center, "rotation", -PI/2.0, .6).set_trans(Tween.TRANS_QUAD)
		create_tween().tween_property($mc/hbc/wheel_handler/wheel/winner_label, "text", "", 0.3))
		
	$mc/hbc/vbc/console/Settigns/mc/vbc/wheel_rotation/value.value_changed.connect(func(value:float):
		wheel_time_rotation=value
		$mc/hbc/vbc/console/Settigns/mc/vbc/wheel_rotation/value_label.text = "%02d.%01d" % [int(value), int((value-floorf(value))*10) ]
		
		)
	
	$text_editor/control/textedit.text_changed.connect(func():
		$mc/hbc/vbc/sc/mc/vbc.get_child(idx_option_for_typing).get_node("mc/hbc/name_edit").text = $text_editor/control/textedit.text
		ManageOptions.options[idx_option_for_typing].name = $text_editor/control/textedit.text)
	$mc/hbc/vbc/console/Output/mc/vbc/clear.pressed.connect(func():$mc/hbc/vbc/console/Output/mc/vbc/text.text = "")

func write_to_output(msg:String) -> void:
	$mc/hbc/vbc/console/Output/mc/vbc/text.text += msg + "\n"

func start() -> void:
	if ManageOptions.is_empty():
		write_to_output("Circle is empty")
		return
	$blank.show()
	toggle_buttons(false)
	var rnd = randf()
	var gradient = ManageOptions.get_gradient()
	var winner:int = -1
	for i in range(gradient.size()-1):
		if rnd >= gradient[i] and rnd < gradient[i+1]:
			winner = i
			break
	$mc/hbc/wheel_handler/wheel/wheel_center.rotation -= pi2*4
	var tween = create_tween()
	tween.tween_property($mc/hbc/wheel_handler/wheel/wheel_center, "rotation", rnd*pi2-PI/2.0, wheel_time_rotation).set_trans(Tween.TRANS_QUART)
	await tween.finished
	create_tween().tween_property($mc/hbc/wheel_handler/wheel/winner_label, "text", ManageOptions.options[winner].name, 0.3)
	write_to_output(ManageOptions.options[winner].name + " - is winner")
	toggle_buttons(true)
	$blank.hide()

func update_circle() -> void:
	var wheel_center = $mc/hbc/wheel_handler/wheel/wheel_center
	var wheel_radius:float = min($mc/hbc/wheel_handler/wheel.size.x, $mc/hbc/wheel_handler/wheel.size.y) / 2.0
	var need_childs = wheel_center.get_child_count() - ManageOptions.options.size()

	#Create a circle from polygons
	var gradient:Array = ManageOptions.get_gradient()
	for i in range(gradient.size()-1):
		var value_from:float = gradient[i]
		var value_to:float = gradient[i+1]
		#Create a piece of circle
		var points:Array = [Vector2(0,0)]
		while value_from < value_to:
			points.append( Vector2(sin(value_from*pi2), cos(value_from*pi2))*wheel_radius )
			value_from = move_toward(value_from, value_to, quality)
		points.append( Vector2(sin(value_from*pi2), cos(value_from*pi2))*wheel_radius )
		ManageOptions.options[i].polygon.polygon = PackedVector2Array(points)
		ManageOptions.options[i].sync_polygon()
	$mc/hbc/wheel_handler/wheel/wheel_center.position = $mc/hbc/wheel_handler/wheel.size / 2.0

func clear() -> void:
	pass

func toggle_buttons(state:bool) -> void:
	$mc/hbc/wheel_handler/hbc/play.disabled = !state
	$mc/hbc/wheel_handler/hbc/reset.disabled = !state
	$mc/hbc/vbc/sc/mc/vbc/add.disabled = !state

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_console"):
		var console = $mc/hbc/vbc/console
		var tween = create_tween()
		if console_state:
			tween.tween_property(console, "size_flags_stretch_ratio", 0.0, 0.4).set_trans(Tween.TRANS_QUAD)
		else :
			tween.tween_property(console, "size_flags_stretch_ratio", 1.0, 0.4).set_trans(Tween.TRANS_QUAD)
		console_state = !console_state
