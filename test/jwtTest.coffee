expect = require("chai").expect
JWT = require "../lib"

describe "JWT", () ->

    jwk = new JWT.JWK
    before (done) ->
        jwk.manualLoadJwkAsync keys: [
            kty: "EC"
            kid: "testKey1"
            crv: "P-256"
            x: "uiOfViX69jYwnygrkPkuM0XqUlvW65WEs_7rgT3eaak"
            y: "v8S-ifVFkNLoe1TSUrNFQVj6jRbK1L8V-eZa-ngsZLM"
            d: "dI5TRpZrVLpTr_xxYK-n8FgTBpe5Uer-8QgHu5gx9Ds"
        ]
        .then () -> done()
        .catch done

    describe "Should round-trip", () ->
        it "sign and encrypt", (done) ->
            t = new JWT jwk: jwk, signingAllowed: "req", encryptionAllowed: "req"
            claims = test: "ABCDE"
            t.generateTokenAsync claims,
                signingKey: "testKey1"
                encryptionKey: "testKey1"
            .then (rv) ->
                expect(typeof rv).to.equal("object")
                expect(typeof rv.signingOptions).to.equal("object")
                expect(typeof rv.encryptionOptions).to.equal("object")
                expect(typeof rv.token).to.equal("string")
                t.parseTokenAsync rv.token
            .then (rv) ->
                expect(typeof rv).to.equal("object")
                expect(typeof rv.encryptionHeader).to.equal("object")
                expect(typeof rv.rawDecryptResult).to.equal("object")
                expect(typeof rv.signingHeader).to.equal("object")
                expect(typeof rv.rawVerifyResult).to.equal("object")
                expect(rv.claims).to.deep.equal(claims)

            .then () -> done()
            .catch done

        it "sign only", (done) ->
            t = new JWT jwk: jwk, signingAllowed: "req", encryptionAllowed: "never"
            claims = test: "ABCDE"
            t.generateTokenAsync claims,
                signingKey: "testKey1"
            .then (rv) ->
                expect(typeof rv).to.equal("object")
                expect(typeof rv.signingOptions).to.equal("object")
                expect(typeof rv.encryptionOptions).to.equal("undefined")
                expect(typeof rv.token).to.equal("string")
                t.parseTokenAsync rv.token
            .then (rv) ->
                expect(typeof rv).to.equal("object")
                expect(typeof rv.encryptionHeader).to.equal("undefined")
                expect(typeof rv.rawDecryptResult).to.equal("undefined")
                expect(typeof rv.signingHeader).to.equal("object")
                expect(typeof rv.rawVerifyResult).to.equal("object")
                expect(rv.claims).to.deep.equal(claims)
            .then () -> done()
            .catch done

        it "encrypt only", (done) ->
            t = new JWT jwk: jwk, signingAllowed: "never", encryptionAllowed: "req"
            claims = test: "ABCDE"
            t.generateTokenAsync claims,
                encryptionKey: "testKey1"
            .then (rv) ->
                expect(typeof rv).to.equal("object")
                expect(typeof rv.signingOptions).to.equal("undefined")
                expect(typeof rv.encryptionOptions).to.equal("object")
                expect(typeof rv.token).to.equal("string")
                t.parseTokenAsync rv.token
            .then (rv) ->
                expect(typeof rv).to.equal("object")
                expect(typeof rv.encryptionHeader).to.equal("object")
                expect(typeof rv.rawDecryptResult).to.equal("object")
                expect(typeof rv.signingHeader).to.equal("undefined")
                expect(typeof rv.rawVerifyResult).to.equal("undefined")
                expect(rv.claims).to.deep.equal(claims)
            .then () -> done()
            .catch done

    describe "constructor options", () ->
        it "should default correctly", () ->
            t = new JWT
            expect(t.jwk).to.equal(t.pvtJwk)
            expect(t.signingAllowed).to.equal("req")
            expect(t.encryptionAllowed).to.equal("never")

        it "should require signing or encryption", () ->
            expect () -> new JWT signingAllowed: "never", encryptionAllowed: "never"
            .to.throw "Cannot specify never for both signing and encryption"

        it "should validate encryptionAllowed", () ->
            expect () -> new JWT signingAllowed: "xxx", encryptionAllowed: "never"
            .to.throw "Illegal value for signingAllowed"

        it "should validate signingAllowed", () ->
            expect () -> new JWT signingAllowed: "never", encryptionAllowed: "xxx"
            .to.throw "Illegal value for encryptionAllowed"

    describe "parsing validation of alogrithms", () ->
        it "should fail on verifyAsync if signing is not allowed", () ->
            t = new JWT signingAllowed: "never", encryptionAllowed: "req"
            expect () -> t.verifyAsync()
            .to.throw "Token signed but signing not allowed"

        it "should fail on decryptAsync if encryption is not allowed", () ->
            t = new JWT signingAllowed: "req", encryptionAllowed: "never"
            expect () -> t.decryptAsync()
            .to.throw "Token encrypted but encryption not allowed"

        it "should fail if unencrypted token is parsed when encryption required", (done) ->
            t = new JWT jwk: jwk, signingAllowed: "req", encryptionAllowed: "opt"
            t2 = new JWT jwk: jwk, signingAllowed: "req", encryptionAllowed: "req"

            claims = test: "ABCDE"
            t.generateTokenAsync claims, signingKey: "testKey1"
            .then (rv) -> t2.parseTokenAsync rv.token
            .then () -> done new Error "Test expected to fail"
            .catch (err) ->
                if err.message == "Token not encrypted" then done()
                else done err

        it "should fail if unsigned token is parsed when signature required", (done) ->
            t = new JWT jwk: jwk, signingAllowed: "opt", encryptionAllowed: "req"
            t2 = new JWT jwk: jwk, signingAllowed: "req", encryptionAllowed: "req"

            claims = test: "ABCDE"
            t.generateTokenAsync claims, encryptionKey: "testKey1"
            .then (rv) -> t2.parseTokenAsync rv.token
            .then () -> done new Error "Test expected to fail"
            .catch (err) ->
                if err.message == "Token not signed" then done()
                else done err

    describe "should validate generation options", () ->
        t = new JWT signingAllowed: "req", encryptionAllowed: "req"

        expect () -> t.generateTokenAsync {}, {}
        .to.throw "Must specify either signing or encryption key"

        expect () -> t.generateTokenAsync {}, signingKey: "x"
        .to.throw "Encryption key required"

        expect () -> t.generateTokenAsync {}, encryptionKey: "x"
        .to.throw "Signing key required"

        t = new JWT signingAllowed: "never", encryptionAllowed: "opt"
        expect () -> t.generateTokenAsync {}, signingKey: "x"
        .to.throw "Signing key not allowed"

        t = new JWT signingAllowed: "opt", encryptionAllowed: "never"
        expect () -> t.generateTokenAsync {}, encryptionKey: "x"
        .to.throw "Encryption key not allowed"



