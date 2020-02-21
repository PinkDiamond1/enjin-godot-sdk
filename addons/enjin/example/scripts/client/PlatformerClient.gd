extends Node2D
signal update_hud

# Constants
const DEFAULT_SETTINGS: Dictionary = {
    "connection": {
        "port": 11011
    },
    "player": {
        "name": "DemoPlayer"
    }
}
const SETTINGS_FILE_NAME: String = "client.cfg"

# Fields
var _settings: Settings
var _client: WebSocketClient
var _tp_client: TrustedPlatformClient
var _app_id: int
var _tokens
var _identity: Dictionary
# Callbacks
var _fetch_player_data_callback: EnjinCallback

# Exports
export var respawn_height = 1500

func _init():
    _settings = Settings.new(DEFAULT_SETTINGS, SETTINGS_FILE_NAME)
    _client = WebSocketClient.new()
    _tp_client = TrustedPlatformClient.new()
    _app_id = 0
    _fetch_player_data_callback = EnjinCallback.new(self, "_fetch_player_data")

    _settings.save()
    _settings.load()

    _client.connect("connection_established", self, "_connection_established")
    _client.connect("connection_error", self, "_connection_error")
    _client.connect("data_received", self, "_data_received")

func _ready():
    if !_settings_valid():
        get_tree().quit()

    _client.connect_to_url("localhost:%d" % _settings.data().connection.port)

    respawn($Player)

func _process(delta):
    if _client.get_connection_status() != WebSocketClient.CONNECTION_DISCONNECTED:
        _client.poll()

    if $Player.position.y > respawn_height:
        out_of_bounds()

func _connection_established(protocol):
    handshake()

func _connection_error():
    print("Connection Error")

func _data_received():
    print("Data received from server.")
    var peer = _client.get_peer(1)
    var packet = WebSocketHelper.decode(peer.get_packet(), peer.was_string_packet())
    if packet.id == PacketIds.PLAYER_AUTH:
        handle_auth(packet)
#    else:
#        $Canvas/Ending.show()
#        get_tree().paused = true

func _settings_valid() -> bool:
    var settings = _settings.data()
    if settings.player.name.empty():
        return false
    return true

func handle_auth(packet):
    var session = packet.session
    _app_id = packet.app_id
    _tokens = packet.tokens
    _tp_client.get_state().auth_user(session.accessToken)
    if _tp_client.get_state().is_authed():
        print("Player client authenticated!")
        fetch_player_data()
    else:
        print("Unable to authenticate player client.")

func fetch_player_data():
    var input = GetUserInput.new()
    var udata = { "callback": _fetch_player_data_callback }
    input.me(true)
    input.user_i.with_identities(true)
    input.identity_i.with_linking_code_qr(true)
    input.identity_i.with_wallet(true)
    _tp_client.user_service().get_user(input, udata)

func load_identity(data):
    _identity = get_identity(data.identities)

    if _identity == null:
        get_tree().quit()

    var linkingCode = _identity.linkingCodeQr
    if linkingCode and !linkingCode.empty():
        download_and_show_qr_code(linkingCode)

    var wallet = _identity.wallet
    print(var2str(wallet))

func get_identity(identities):
    for identity in identities:
        var app_id = int(identity.appId)
        if app_id == _app_id:
            return identity
    return null

func download_and_show_qr_code(url: String):
    if $Canvas/QR/Rect.texture == null:
        var http_request = HTTPRequest.new()
        add_child(http_request)
        http_request.connect("request_completed", self, "_qr_code_request_complete")
        var http_error = http_request.request(url)
        if http_error != OK:
            print("An error occurred in the HTTP request.")
    else:
        show_qr_code()

func show_qr_code():
    $Canvas/QR.show()
    get_tree().paused = true

func handshake():
    var packet = {
        "id": PacketIds.HANDSHAKE,
        "name": _settings.data().player.name
    }
    WebSocketHelper.send_packet(_client, packet)

func send_token(name: String, amount: int):
    var packet = {
        "id": PacketIds.SEND_TOKEN,
        "token": name,
        "amount": amount,
        "player_id": int(_identity.id)
    }
    WebSocketHelper.send_packet(_client, packet)

func out_of_bounds():
    var player_dead = $Player.damage(1)

    if player_dead:
        get_tree().reload_current_scene()
    else:
        respawn($Player)
        emit_signal("update_hud", $Player)

func respawn(player):
    player.position.x = $Spawn.position.x
    player.position.y = $Spawn.position.y

func exit_entered(body):
    if $Player.coins == 3:
        send_token("shard", $Player.coins)
        $Canvas/Ending.show()
        $Timer.set_wait_time(.5)
        $Timer.start()
        yield($Timer, "timeout")
        get_tree().paused = true

# Callbacks

func _fetch_player_data(udata: Dictionary):
    var gql = udata.gql
    if gql.has_errors():
        print("Errors: %s" % PoolStringArray(udata.gql.get_errors()).join(","))
    elif gql.has_result():
        load_identity(gql.get_result())

func _qr_code_request_complete(result, response_code, headers, body):
    # Create image from body
    var image = Image.new()
    var image_error = image.load_png_from_buffer(body)
    if image_error != OK:
        print("Unable to load qr code from url.")
    # Create texture rectangle
    var texture = ImageTexture.new()
    texture.create_from_image(image)
    $Canvas/QR/Rect.texture = texture
    show_qr_code()

func _wallet_linked():
    fetch_player_data()
