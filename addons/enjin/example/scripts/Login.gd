extends CanvasLayer

export(NodePath) var form

var _email_regex
var _login_callback: EnjinCallback

func _init():
    _email_regex = RegEx.new()
    _email_regex.compile("[^@]+@[^\\.]+\\..+")
    _login_callback = EnjinCallback.new(self, "_on_login_response")

func _ready():
    hide_errors()

func _on_login_pressed():
    if get_button().disabled:
        return

    hide_errors()

    var email: String = email_input().text
    var password: String = password_input().text

    var valid = true
    if email.empty():
        show(email_error())
        valid = false
    if !_email_regex.search(email):
        show(email_error())
        valid = false
    if password.empty():
        show(password_error())
        valid = false

    if !valid:
        return

    var udata = {}
    udata.callback = _login_callback
    Enjin.client.auth_service().auth_user(email, password, udata);

    get_button().disabled = true

func _on_login_response(udata: Dictionary):
    if Enjin.client.get_state().is_authed():
        get_tree().change_scene("res://addons/enjin/example/scenes/Main.tscn")
    else:
        var gql = udata.gql
        if gql != null and gql.has_errors():
            show_errors()
        get_button().disabled = false

func show(control: Label):
    control.set_visible_characters(-1)

func hide(control: Label):
    control.set_visible_characters(0)

func show_errors():
    show(email_error())
    show(password_error())

func hide_errors():
    hide(email_error())
    hide(password_error())

func get_form() -> Node:
    return get_node(form)

func get_button() -> Button:
    return get_form().get_node("Margin").get_node("Submit") as Button

func get_input(parent: String) -> Node:
    return get_form().get_node(parent).get_node("Input")

func get_error(parent: String) -> Node:
    return get_form().get_node(parent).get_node("Error")

func email_input() -> LineEdit:
    return get_input("Email") as LineEdit

func password_input() -> LineEdit:
    return get_input("Password") as LineEdit

func email_error() -> Label:
    return get_error("Email") as Label

func password_error() -> Label:
    return get_error("Password") as Label