extends Node3D

#@onready var skeleton: Skeleton3D = $Armature/Skeleton3D
@onready var camera = get_parent().get_node("Head").get_node("FPCamera")
@onready var node  = $MeshInstance3D
