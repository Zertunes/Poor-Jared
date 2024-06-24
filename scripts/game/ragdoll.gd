extends Node

# The scale you want to apply
@onready var skeleton = $Armature/Skeleton3D
@onready var mesh = $Armature/Skeleton3D/Player
@onready var desired_scale = Vector3(0.01, 0.01, 0.01)

func _ready():
	#await get_tree().create_timer(3).timeout
	# Reference to your Skeleton3D node
	apply_scale_to_skeleton(skeleton, desired_scale)
	#mesh.scale = desired_scale
	#skeleton.physical_bones_start_simulation()

func apply_scale_to_skeleton(skeleton: Skeleton3D, scale_factor: Vector3):
	# Apply the scale to the Skeleton3D node itself
	skeleton.scale = scale_factor
	
	# Adjust the scale for all physical bones
	adjust_physical_bones_scale(skeleton, scale_factor)

	# Restart the physics simulation to apply the changes
	skeleton.physical_bones_start_simulation()

func adjust_physical_bones_scale(skeleton: Skeleton3D, scale_factor: Vector3):
	# Iterate through all children to find physical bones and apply the scale to collision shapes
	for bone in skeleton.get_children():
		if bone is PhysicalBone3D:
			bone.scale = scale_factor
			# Scale the collision shapes under this physical bone node
			for child in bone.get_children():
				if child is CollisionShape3D:
					child.scale = scale_factor
