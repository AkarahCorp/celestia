extends PanelContainer

signal prompt_closed

func _input(event: InputEvent):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		var evLocal = make_input_local(event)
		if !Rect2(Vector2(0,0), size).has_point(evLocal.position):
			prompt_closed.emit()
			self.get_parent().get_parent().queue_free()
			Prompts.in_prompt = false

func close():
	self.get_parent().get_parent().queue_free()
	Prompts.in_prompt = false
