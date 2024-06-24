extends Node

signal disconnect_player(peer_id)

signal on_host_disconnect

@onready var menus = {
	"menu": $DeathMenu/DeathMenu,
	"confirm_menu": $DeathMenu/ConfirmMenu,
	"menu_label": $DeathMenu/DeathLabel,
	"confirm_menu_label": $DeathMenu/ConfirmLabel
}

@onready var join_menu = $"../../"

var confirmtype: int = 0

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	menus.menu.show()
	menus.menu_label.show()
	menus.confirm_menu.hide()
	menus.confirm_menu_label.hide()

func _input(event):
	if confirmtype > 0:
		menus.menu.hide()
		menus.menu_label.hide()
		menus.confirm_menu.show()
		menus.confirm_menu_label.show()
	else:
		menus.menu.show()
		menus.menu_label.show()
		menus.confirm_menu.hide()
		menus.confirm_menu_label.hide()

func _on_exit_button_pressed():
	confirmtype = 1

func _on_menu_button_pressed():
	confirmtype = 2

func _on_yes_button_pressed():
	if confirmtype == 1:
		#emit_signal("on_host_disconnect")
		join_menu._on_host_disconnect()
	elif confirmtype == 2:
		#emit_signal("disconnect_player", multiplayer.get_unique_id())
		join_menu._disconnect_player(multiplayer.get_unique_id())

func _on_no_button_pressed():
	confirmtype = 0


func _on_respawn_button_pressed():
	await get_tree().create_timer(2).timeout
	join_menu.remove_player(multiplayer.get_unique_id())
	print(str(multiplayer.get_unique_id()) + "a")
	join_menu.add_player(multiplayer.get_unique_id())
	print(str(multiplayer.get_unique_id()) + "b")
