extends Node2D

var t := 0.0
@onready var cart_path = $CartPath/CartFollow
@onready var cart = $CartPath/CartFollow/Cart
var has_entered = true

func _physics_process(delta):
	t += delta
	if cart_path:
		cart_path.progress = t * 200
		
func toggle_cart_vert():
	cart.transform.y *= -1

func toggle_hide_cart():
	cart.visible = !cart.visible

func _on_cart_switcher_1_area_entered(area):
	if has_entered:
		toggle_cart_vert()
		toggle_hide_cart()
		has_entered = false
	else:
		toggle_hide_cart()
		has_entered = true

