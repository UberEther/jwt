uuid = require "node-uuid"
clone = require "clone"

class Validator
    constructor: (scopes = {}) ->
        @scopes = {}
        @scopes[scopeName] = @createScope scopeOpts for scopeName, scopeOpts of scopes

    validate: (scope, x = {}) ->
        schema = @scopes[scope]?.val
        if !schema then throw new Error "Unknown scope"

        if schema.pre then schema.pre x, scope, @

        # Process the values that are there
        rv = if schema.defaults then clone(schema.defaults) else {}
        for name, val of x when val != undefined
            verifier = schema.fields[name] || schema.fields.__default__
            t = verifier.call verifier, name, val
            if t != undefined then rv[name] = t

        # Ensure we got everybody
        for name in schema.req
            if !rv[name]? then throw new Error "Missing required field: #{name}"

        if schema.post then schema.post rv, scope, @

        return rv

    generate: (scope, x = {}) ->
        schema = @scopes[scope]?.gen
        if !schema then throw new Error "Unknown scope"

        if schema.pre then schema.pre x, scope, @

        # Process the values that are there
        rv = if schema.defaults then clone(schema.defaults) else {}
        for name, val of x when val != undefined
            generator = schema.fields[name] || schema.fields.__default__
            t = generator.call generator, name, val
            if t != undefined then rv[name] = t

        # Ensure we got everybody
        for name in schema.gen
            if !rv[name]? then rv[name] = (schema.fields[name] || schema.fields.__default__).type.generate()
        for name in schema.req
            if !rv[name]? then throw new Error "Missing required field: #{name}"

        if schema.post then schema.post rv, scope, @

        return rv

    createScope: (scopeOpts = {}) ->
        return {
            val: @createScopePart scopeOpts, scopeOpts.val
            gen: @createScopePart scopeOpts, scopeOpts.val, true
        }

    createScopePart: (scopeOpts, partOpts = {}, useExport) ->
        rv =
            defaults: partOpts.defaults || scopeOpts.defaults # Default values - true/req, gen (required+generate), opt (optional), never
            pre: partOpts.pre || scopeOpts.pre # Pre-processing funciton
            post: partOpts.post || scopeOpts.post # Post-processing funciton
            req: []
            gen: []
            fields: {}

        for name, type of partOpts.fields || scopeOpts.fields || {}
            req = partOpts.req?[name] || scopeOpts.req?[name]
            if req == "never" then rv.fields[name] = @generateValidatorFunction name, "never"
            else
                if req == true || req == "req" || req == "gen" then rv.req.push name
                allowed = partOpts.allowedValues?[name] || scopeOpts.allowedValues?[name]
                disallowed = partOpts.disallowedValues?[name] || scopeOpts.disallowedValues?[name]
                rv.fields[name] = @generateValidatorFunction name, type, allowed, disallowed, useExport, req == true || req == "req" || req == "gen", useExport && req == "gen"
                if req == "gen"
                    if !rv.fields[name].type.generate then throw new Error "No generate method available for #{name}"
                    rv.gen.push name

        if !rv.fields.__default__
            allowAny = if partOpts.allowAny? then partOpts.allowAny else scopeOpts.allowAny
            rv.fields.__default__ = @generateValidatorFunction "__default__", if allowAny then "any" else "never"

        return rv

    generateValidatorFunction: (name, type, allowed, disallowed, useExport) ->
        if typeof type == "string"
            type = Validator.Types[type] || Validator.Types[Validator.DefaultType[name]]

        if !type then throw new Error "Unable to locate type for #{name}"

        t = ""
        if type.verify then t += "if (!this.type.verify(val)) throw new Error('Illegal value for '+name);"

        if useExport
            if type.export then t += "val = this.type.export(val);"
        else
            if type.parse then t += "val = this.type.parse(val);"

        t += "if (val === null || val === undefined) return val;"

        if allowed
            switch
                when allowed instanceof RegExp
                    check = "this.allowed.test(val)"
                when typeof allowed == "function"
                    check = "this.allowed(val)"
                when Array.isArray allowed
                    check = "this.allowed.indexOf(val) >= 0"
                else
                    check = "val === this.allowed"

            t += "if (!(#{check})) throw new Error('Not an allowed value for '+name);"

        if disallowed
            switch
                when disallowed instanceof RegExp
                    check = "this.disallowed.test(val)"
                when typeof disallowed == "function"
                    check = "this.disallowed(val)"
                when Array.isArray disallowed
                    check = "this.disallowed.indexOf(val) >= 0"
                else
                    check = "val === this.disallowed"

            t += "if (#{check}) throw new Error('Disallowed value for '+name);"

        t += "return val;"

        rv = new Function "name", "val", t
        rv.type = type
        rv.allowed = allowed
        rv.disallowed = disallowed

        return rv

Validator.Types =
    "any": verify: (x) -> return true

    "never": verify: (x) -> return false

    "string":
        verify: (x) -> return typeof x == "string" && x != ""

    "identifier": # Generates a v1 UUID
        verify: (x) -> return typeof x == "string" && x != ""
        generate: () -> return uuid.v1()

    "stringArray": # Exports single string values as a string - Imports single string values as an array
        verify: (x) -> return (typeof x == "string" && x != "") || Array.isArray(x)
        parse: (x) -> if typeof x == "string" then [x] else x
        export: (x) -> if Array.isArray(x) && x.length == 1 then x[0] else x

    "timestamp": # Supports both dates and JWT-style numeric dates (seconds from epoch)
        verify: (x) -> return typeof x == "number" || (x instanceof Date && !isNaN(x.valueOf()))
        parse: (x) -> if typeof(x) == "number" then new Date(x * 1000) else x
        export: (x) -> if typeof(x) == "number" then x else (x.getTime() / 1000)
        generate: () -> new Date

    "expiration": # If parsing a number, it is a JWT-style numeric date - if exporting from a number, then it is milliseconds till expiration
        verify: (x) -> return typeof x == "number" || (x instanceof Date && !isNaN(x.valueOf()))
        parse: (x) -> if typeof(x) == "number" then new Date(x * 1000) else x
        export: (x) -> if typeof(x) == "number" then ((Date.now()+x)/1000) else (x.valueOf() / 1000)

Validator.DefaultType =
    # JWT Specificaiton
    "typ": "string"
    "alg": "string"
    "cty": "string"
    "iss": "string"
    "sub": "string"
    "aud": "stringArray"
    "exp": "expiration"
    "nbf": "timestamp"
    "iat": "timestamp"
    "jti": "identifier"
    # OIDC 1.0 Core Section 2
    "auth_time": "timestamp"
    "acr": "stringArray"
    "amr": "stringArray"
    "azp": "string"

module.exports = Validator
