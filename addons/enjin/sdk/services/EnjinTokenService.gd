extends Reference

const TrustedPlatformMiddleware = preload("res://addons/enjin/sdk/TrustedPlatformMiddleware.gd")

var _middleware: TrustedPlatformMiddleware

func _init(middleware: TrustedPlatformMiddleware):
    _middleware = middleware

func get_token(input: GetTokenInput, udata: Dictionary = {}):
    _middleware.execute_gql("GetTokenQuery", input.create(), udata)

func get_tokens(input: GetTokensInput, udata: Dictionary = {}):
    if udata.has("pagination"):
        _middleware.execute_gql("GetTokensPaginatedQuery", input.create(), udata)
    else:
        _middleware.execute_gql("GetTokensQuery", input.create(), udata)

func import_token(input: ImportTokenInput, udata: Dictionary = {}):
    _middleware.execute_gql("ImportTokenMutation", input.create(), udata)

func update_token(input: UpdateTokenInput, udata: Dictionary = {}):
    _middleware.execute_gql("UpdateTokenMutation", input.create(), udata)

func delete_token(input: DeleteTokenInput, udata: Dictionary = {}):
    _middleware.execute_gql("DeleteTokenMutation", input.create(), udata)
