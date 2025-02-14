extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var modulate_damage: Timer = $"Modulate Damage"


func take_damage(amount):
	sprite.modulate = Color.RED
	modulate_damage.start()

func _on_modulate_damage_timeout() -> void:
	sprite.modulate = Color(1, 1, 1, 1)
