## Library for creating prompt windows.
extends Node

@onready var _window_root = get_node('/root')  

## The fallback UI for if a node is not autodetected (e.g. your top-level node is not a [Control]).
var fallback_ui: Node

## If the user is currently already in a prompt.
var in_prompt = false

## The result of prompt creation.
enum PromptCreationResult {
	SUCCESSFUL,
	NO_SUITABLE_UI,
	IN_PROMPT
}

## Returns a Result with the PanelContainer for the Prompt.
func new_fullscreen_prompt() -> Result:
	if in_prompt:
		return Result.err(PromptCreationResult.IN_PROMPT)
	var prompt = preload("res://libraries/ui/prompt/prompt.tscn").instantiate()
	var ui = null
	for child in _window_root.get_children():
		if child is Control: # top-level ui node
			ui = child
			break
	if ui == null and fallback_ui:
		ui = fallback_ui
	elif ui == null:
		return Result.err(PromptCreationResult.NO_SUITABLE_UI)
	ui.add_child(prompt)
	return Result.ok(prompt.find_child("Prompt"))
