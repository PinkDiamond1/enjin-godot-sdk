extends Reference

const TrustedPlatformMiddleware = preload("res://addons/enjin/sdk/TrustedPlatformMiddleware.gd")

var _middleware: TrustedPlatformMiddleware

func _init(middleware: TrustedPlatformMiddleware):
    _middleware = middleware

func get_user(input: GetUserInput, udata: Dictionary = {}):
    _middleware.execute_gql("GetUserQuery", input.create(), udata)

func get_users(input: GetUserInput, udata: Dictionary = {}):
    if udata.has("pagination"):
        _middleware.execute_gql("GetUsersPaginatedQuery", input.create(), udata)
    else:
        _middleware.execute_gql("GetUsersQuery", input.create(), udata)

func create_user(input: CreateUserInput, udata: Dictionary = {}):
    _middleware.execute_gql("CreateUserMutation", input.create(), udata)

func update_user(input: UpdateUserInput, udata: Dictionary = {}):
    _middleware.execute_gql("UpdateUserMutation", input.create(), udata)

func delete_user(input: DeleteUserInput, udata: Dictionary = {}):
    _middleware.execute_gql("DeleteUserMutation", input.create(), udata)
