extends BaseShip
## Minimal BaseShip stand-in for headless fort tests. Lifecycle hooks
## are no-op'd so the stub works without the full ship scene (sprites,
## cannon, crew cabin), leaving just the body + faction + state that
## fort targeting inspects. Load()ed at runtime by test scripts — do
## not reference from compile-time code.

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func _physics_process(_delta: float) -> void:
	pass

func _on_lost_beach_head(_beach: BeachHead) -> void:
	pass
