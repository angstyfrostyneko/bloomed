extends RigidBody


export var damage = 10
export var speed = 100

func _ready():
	set_as_toplevel(true)


func _physics_process(_delta):
	apply_impulse(transform.basis.z, -transform.basis.z * speed)


func _on_Area_body_entered(body):
	if body.is_in_group("Player"):
		body.damage(damage)
	queue_free()


func _on_TimeAlive_timeout():
	queue_free()
