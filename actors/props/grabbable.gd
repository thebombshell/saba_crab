class_name GrabbableActor extends RigidBody3D

# the tl;dr? this is a very simple set of information so we can tweak how the
# crab holds objects

@export var grab_point: Vector3 = Vector3.ZERO;
@export var grab_rotation: Vector3 = Vector3.ZERO;
@export var two_handed: bool = false;
