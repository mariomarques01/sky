extends StaticBody3D

@export var launch_speed := 12.4

func bounce_strength() -> float:
	return launch_speed
