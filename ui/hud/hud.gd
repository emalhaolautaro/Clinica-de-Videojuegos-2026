extends CanvasLayer

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var energy_bar: TextureProgressBar = $EnergyBar

func update_max_health(max_health: int) -> void:
	health_bar.max_value = max_health

func update_health(new_health: int) -> void:
	health_bar.value = new_health

func update_max_energy(max_energy: float) -> void:
	energy_bar.step = 0.01
	energy_bar.max_value = max_energy

func update_energy(new_energy: float) -> void:
	energy_bar.value = new_energy
