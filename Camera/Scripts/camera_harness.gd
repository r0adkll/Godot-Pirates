class_name CameraHarness
extends Node2D
## A structured way to inform a camera of its position, zoom, limits and other
## configurations based on the intended camera target


# The targeted rect of the viewport that this harness would like
# If larger than the default viewport, then this will tell the camera
# to scale its zoom to fit this rect.
# If smaller, then the camera will scale to its bounded minimum scale
@export var viewport_rect: Vector2
