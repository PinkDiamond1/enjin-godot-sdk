extends "res://addons/gut/test.gd"

var server : TCP_Server = null
var response_cache_folder : String = "user://gut_testserver_responses"
var directory = Directory.new()
var using_cache: bool = true
var counter = 0

class ActiveConnection:
    extends Object
    
    var connection : StreamPeerTCP = null
    var peerstream : PacketPeerStream = null
    var _cached_server = null
    
    func _init(in_conn : StreamPeerTCP, cached_server):
        connection = in_conn
        _cached_server = cached_server
        peerstream = PacketPeerStream.new()
        peerstream.set_stream_peer(connection)
    
    func _notification(what):
        if what == NOTIFICATION_PREDELETE:
            Disconnect()
    
    func isAlive():
        return connection.get_status() == StreamPeerTCP.STATUS_CONNECTING or connection.get_status() == StreamPeerTCP.STATUS_CONNECTED

    func onUpdate():
        if peerstream.stream_peer.get_available_bytes() > 0:
            var available_bytes = peerstream.stream_peer.get_available_bytes()
            
            var request = peerstream.stream_peer.get_data(available_bytes)[1].get_string_from_ascii()
            
            var lines = request.split("\n")
            
            var header = lines[0]
            
            if header.begins_with("POST"):
                header = header.lstrip("POST ")
            if header.begins_with("GET"):
                header = header.lstrip("GET ")
            
            var url = header.left(header.find(" ")).percent_decode()

            var content = ""
            
            for x in range(1, lines.size()):
                var line = lines[x]
                
                var colon_pos = line.find(":")
                var prop_name = line.left(colon_pos).strip_edges().to_upper()
                var value = line.right(colon_pos + 1).strip_edges()
                
                if prop_name == "CONTENT-LENGTH":
                    content = request.right(request.length() - value.to_int())
            
            var body = ""
            
            #Todo: scan for all folders
            if _cached_server.HasResponse(content):
                body = _cached_server.GetResponse(content)
            
            
            var return_data = "HTTP/1.0 200 OK" + "\r\n"
            return_data += "Content-Type: application/json;" + "\r\n"
            return_data += "charset=\"ASCII\"" + "\r\n"
            return_data += "Connection: close" + "\r\n"
            return_data += "Content-Length: " + str(body.length() + 2) + "\r\n"
            return_data += "\r\n\r\n"
            return_data += body
            peerstream.stream_peer.put_data(PoolByteArray(return_data.to_ascii()))
            
    func Disconnect():
        connection.disconnect_from_host()

var active_connections = []

func _init():
    print("server initialized")
    server = TCP_Server.new()
    
    if not directory.dir_exists(response_cache_folder):
        directory.make_dir_recursive(response_cache_folder)
        if directory.open(response_cache_folder) == OK:
            using_cache = true
        else:
            using_cache = false


func Start():
    server.listen(8080)

func Stop():
    server.stop()

func ResetCounter():
    counter = 0

func ExpectDifferentResponse():
    counter += 1

func SetResponse(in_request : String, out_response : String, folder : String):
    if not using_cache:
        return
    var request = in_request + str(counter)
    if not HasResponse(request):
        var request_hash : String = request.sha256_text()
    
        var target_dir = response_cache_folder + "/" + folder
    
        if not directory.dir_exists(target_dir):
            directory.make_dir_recursive(target_dir)
    
        var tmp_filename = target_dir + "/" + request_hash + ".rcache"
        print(tmp_filename)
        print(out_response)
    
        var cache = File.new()
        cache.open(tmp_filename, File.WRITE)
        
        cache.store_string(out_response)
        
        cache.close()

func HasResponse(in_request : String) -> bool:
    if not using_cache:
        return false
    var request = in_request + str(counter)
    var request_hash : String = request.sha256_text()
    var tmp_directory = Directory.new()
    
    if tmp_directory.dir_exists(response_cache_folder):
        if tmp_directory.open(response_cache_folder) != OK:
            return false
    
    
    if(!tmp_directory.list_dir_begin()):
        while true:
            var script_folder_name = tmp_directory.get_next()
            if not tmp_directory.current_is_dir():
                continue
            if script_folder_name == "":
                break
           
            
            
            var tmp_filename = response_cache_folder + "/" + script_folder_name + "/" + request_hash + ".rcache"
            
            if tmp_directory.file_exists(tmp_filename):
                print("found cache")
                return true
    
    return false

func GetResponse(in_request : String) -> String:
    if not using_cache:
        return ""
    var request = in_request + str(counter)
    var request_hash : String = request.sha256_text()
    
    var cache_file_path: String
    
    var tmp_directory = Directory.new()
    
    if tmp_directory.dir_exists(response_cache_folder):
        if tmp_directory.open(response_cache_folder) != OK:
            return ""
    
    if(!tmp_directory.list_dir_begin()):
        while true:
            var script_folder_name = tmp_directory.get_next()
            if not tmp_directory.current_is_dir():
                continue
            if script_folder_name == "":
                break
           
            
            
            var tmp_filename = response_cache_folder + "/" + script_folder_name + "/" + request_hash + ".rcache"
            
            if tmp_directory.file_exists(tmp_filename):
                print("found cache")
                cache_file_path = tmp_filename
                break
    
    var cached_response : String = ""
    
    if directory.file_exists(cache_file_path):
        var cache = File.new()
        cache.open(cache_file_path, File.READ)
        
        cached_response = cache.get_as_text()
        
        cache.close()
    
    return cached_response

func onServerUpdate():
    if server.is_connection_available():
        var peer_connection = server.take_connection()
        var active_client = ActiveConnection.new(peer_connection, self)
        active_connections.append(active_client)
    
    for connection in active_connections:
        if connection.isAlive():
            connection.onUpdate()
        else:
            active_connections.erase(connection)
            connection.free() 

func _process(dt):
    if server:
        onServerUpdate()

func _exit_tree():
    server.stop()
