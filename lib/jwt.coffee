Promise = require "bluebird"
_JWKS = require "uberether-jwk"
registerDefaultFieldTypes = require "./registerDefaultFieldTypes"
_generateValidator = require "uberether-object-validator"

# Ensure we register the JWT default types with our choice of validator
# If the user provides their own, they are on their own...
registerDefaultFieldTypes require "uberether-object-validator/lib/defaultFieldTypes"

legalAllowedValues = ["req", "opt", "never"]

class JWT
    constructor: (options = {}) ->
        @signingAllowed = options.signingAllowed || "req"
        @encryptionAllowed = options.encryptionAllowed || "never"
        if legalAllowedValues.indexOf(@signingAllowed) == -1 then throw new Error "Illegal value for signingAllowed"
        if legalAllowedValues.indexOf(@encryptionAllowed) == -1 then throw new Error "Illegal value for encryptionAllowed"
        if @signingAllowed == "never" && @encryptionAllowed == "never" then throw new Error "Cannot specify never for both signing and encryption"

        @jwks = options.jwks || new JWT.JWKS options.jwksOptions
        @pvtJwks = options.pvtJwks || (options.pvtJwksOptions && new JWT.JWKS options.pvtJwksOptions) || @jwks

        @signingHeaderValidator = options.signingHeaderValidator || JWT.generateValidator options.signingHeaderSchema || { skip: true }
        @encryptionHeaderValidator = options.encryptionHeaderValidator || JWT.generateValidator options.encryptionHeaderSchema || { skip: true }
        @claimsValidator = options.claimsValidator || JWT.generateValidator options.claimsSchema || { skip: true }

    ##################################
    ### Token Parsing
    ##################################

    verifyAsync: (token, rv) ->
        if @signingAllowed == "never" then throw new Error "Token signed but signing not allowed"
        Promise.bind @
        .then () -> @jwks.verifySignatureAsync token
        .then (x) ->
            rv.signingHeader = @signingHeaderValidator.parse x.header
            rv.rawVerifyResult = x
            return x.payload

    decryptAsync: (token, rv) ->
        if @encryptionAllowed == "never" then throw new Error "Token encrypted but encryption not allowed"
        Promise.bind @
        .then () -> @pvtJwks.decryptAsync token
        .then (x) ->
            rv.encryptionHeader = @encryptionHeaderValidator.parse x.header
            rv.rawDecryptResult = x

            if rv.encryptionHeader.cty?.toUpperCase() == "JWT" then @verifyAsync x.plaintext.toString("utf8"), rv
            else return x.plaintext

    parseTokenAsync: (token) ->
        rv = {}

        Promise.bind @, token
        .then (token) ->
            token = token.toString "utf8"
            t = token.split /\./
            if t.length == 5 then @decryptAsync token, rv
            else @verifyAsync token, rv
        .then (payload) ->
            if @signingAllowed == "req" && !rv.signingHeader then throw new Error "Token not signed"
            if @encryptionAllowed == "req" && !rv.encryptionHeader then throw new Error "Token not encrypted"

            claims = JSON.parse payload.toString "utf8"
            rv.claims = @claimsValidator.parse claims

            return rv

    ##################################
    ### Token Generation
    ##################################

    generateTokenAsync: (claims, options = {}) ->
        if !options.signingKey &&  !options.encryptionKey then throw new Error "Must specify either signing or encryption key"
        if @signingAllowed == "req" && !options.signingKey then throw new Error "Signing key required"
        if @signingAllowed == "never" && options.signingKey then throw new Error "Signing key not allowed"
        if @encryptionAllowed == "req" && !options.encryptionKey then throw new Error "Encryption key required"
        if @encryptionAllowed == "never" && options.encryptionKey then throw new Error "Encryption key not allowed"

        rv = {}
        Promise.bind @, JSON.stringify @claimsValidator.export claims
        .then (payload) ->
            return payload if !options.signingKey
            rv.signingOptions = @generateSigningOptions options
            @pvtJwks.signAsync options.signingKey, payload, rv.signingOptions
        .then (payload) ->
            return payload if !options.encryptionKey
            
            rv.encryptionOptions = @generateEncryptionOptions options
            @jwks.encryptAsync options.encryptionKey, payload, rv.encryptionOptions
        .then (payload) ->
            rv.token = payload
            return rv

    generateSigningOptions: (options) ->
        # todo: IMPLEMENT ME
        return {
            format: "compact"
            fields: @signingHeaderValidator.export options.signingHeader || {}
        }

    generateEncryptionOptions: (options) ->
        # todo: IMPLEMENT ME
        rv = {
            format: "compact"
            fields: @encryptionHeaderValidator.export options.signingHeader || {}
        }

        if options.signingKey then rv.fields.cty = "JWT"

        return rv

JWT.JWKS = _JWKS
JWT.generateValidator = _generateValidator

module.exports = JWT
