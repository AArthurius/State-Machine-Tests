extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $Sprite


func take_damage(amount):
	sprite.modulate = Color.RED

func _on_modulate_damage_timeout() -> void:
	sprite.modulate = Color(1, 1, 1, 1)
