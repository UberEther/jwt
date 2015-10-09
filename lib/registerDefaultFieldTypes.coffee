registerDefaultFieldTypes = (x) ->
    # JWT Specificaiton
    x.typ = "string"
    x.alg = "string"
    x.cty = "string"
    x.iss = "string"
    x.sub = "string"
    x.aud = "stringArray"
    x.exp = "expirationSeconds"
    x.nbf = "timestampSeconds"
    x.iat = "timestampSeconds"
    x.jti = "identifier"

    # OIDC 1.0 Core Section 2
    x.auth_time = "timestampSeconds"
    x.acr = "stringArray"
    x.amr = "stringArray"
    x.azp = "string"

module.exports = registerDefaultFieldTypes