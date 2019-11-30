extends PaginatedInput
class_name GetUserInput

var user_i: UserFragmentInput
var role_i: RoleFragmentInput
var identity_i: IdentityFragmentInput
var wallet_i: WalletFragmentInput
var balance_i: SimpleBalanceFragmentInput
var token_i: TokenFragmentInput

func _init():
    user_i = UserFragmentInput.new(vars)
    role_i = RoleFragmentInput.new(vars)
    identity_i = IdentityFragmentInput.new(vars)
    wallet_i = WalletFragmentInput.new(vars)
    balance_i = SimpleBalanceFragmentInput.new(vars)
    token_i = TokenFragmentInput.new(vars)

func id(id: int) -> GetUserInput:
    vars.id = id
    return self

func name(name: String) -> GetUserInput:
    vars.name = name
    return self

func me(me: bool) -> GetUserInput:
    vars.me = me
    return self
