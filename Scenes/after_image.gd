extends Sprite2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _process(delta: float) -> void:
	if !animation_player.is_playing():
		queue_free()
