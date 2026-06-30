extends Node

signal progress_changed(progress: float)
signal load_finished

const NO_OP: Callable = Callable()

var loading_screen: PackedScene = preload("uid://dqkfcurofrb1g")
var loaded_resource: PackedScene
var scene_path: String
var progress: Array[float] = []
var use_sub_threads: bool = true
var transformer: Callable

func _ready() -> void:
	set_process(false)


func load_scene(_scene_path: String, _transformer: Callable = NO_OP) -> void:
	scene_path = _scene_path
	transformer = _transformer
	
	var new_load_screen = loading_screen.instantiate()
	add_child(new_load_screen)
	progress_changed.connect(new_load_screen._on_progress_changed)
	load_finished.connect(new_load_screen._on_load_finished)

	await new_load_screen.loading_screen_ready
	
	start_load()


func start_load() -> void:
	var state = ResourceLoader.load_threaded_request(scene_path, "", use_sub_threads)
	if state == OK:
		set_process(true)


func _process(_delta: float) -> void:
	var load_status = ResourceLoader.load_threaded_get_status(scene_path, progress)
	progress_changed.emit(progress[0])
	match load_status:
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE, ResourceLoader.THREAD_LOAD_FAILED:
			set_process(false)
		ResourceLoader.THREAD_LOAD_LOADED:
			loaded_resource = ResourceLoader.load_threaded_get(scene_path)
			if transformer != NO_OP:
				var node = loaded_resource.instantiate()
				transformer.call(node)
				get_tree().change_scene_to_node(node)
			else:
				get_tree().change_scene_to_packed(loaded_resource)
			load_finished.emit()
