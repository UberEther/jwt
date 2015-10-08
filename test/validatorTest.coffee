expect = require("chai").expect
Validator = require("../lib").Validator

describe "Validator", () ->
    describe "Single Scope, Common Generator and Validator Settings", () ->
        it "should validate empty objects, null, and undefined (when legal)", () ->
            t = new Validator
                a:
                    fields: typ: 1

            t2 = t.validate "a", undefined
            expect(t2).to.deep.equal({})

            t2 = t.validate "a", null
            expect(t2).to.deep.equal({})

            t2 = t.validate "a", {}
            expect(t2).to.deep.equal({})

            t2 = t.generate "a", null
            expect(t2).to.deep.equal({})

            t2 = t.generate "a", undefined
            expect(t2).to.deep.equal({})

            t2 = t.generate "a", {}
            expect(t2).to.deep.equal({})

        it "should succeed when required fields are present", () ->
            t = new Validator
                a:
                    fields: a: "string"
                    req: { "a": true }

            t2 = t.validate "a", a: "A"
            expect(t2).to.deep.equal(a: "A")

            t2 = t.generate "a", a: "A"
            expect(t2).to.deep.equal(a: "A")

        it "should fail when required fields are missing", () ->
            t = new Validator
                a:
                    fields: typ: 1
                    req:
                        typ: true

            expect () -> t.validate "a", undefined
            .to.throw "Missing required field: typ"

            expect () -> t.validate "a", null
            .to.throw "Missing required field: typ"

            expect () -> t.validate "a", {}
            .to.throw "Missing required field: typ"

            expect () -> t.generate "a", undefined
            .to.throw "Missing required field: typ"

            expect () -> t.generate "a", null
            .to.throw "Missing required field: typ"

            expect () -> t.generate "a", {}
            .to.throw "Missing required field: typ"

    it "should allow other fields when specified", () ->
            t = new Validator
                a:
                    allowAny: true

            expect t.validate "a", foo: 2
            .to.deep.equal foo: 2

            expect t.generate "a", foo: 2
            .to.deep.equal foo: 2

    it "should not allow other fields by default", () ->
            t = new Validator
                a: {}

            expect () -> t.validate "a", foo: 2
            .to.throw "Illegal value for foo"

            expect () -> t.generate "a", foo: 2
            .to.throw "Illegal value for foo"

    it "should generate values when requested", () ->
            t = new Validator
                a:
                    fields:
                        a: "timestamp"
                        b: "identifier"
                        c: "identifier"
                    req:
                        a: "gen"
                        b: "gen"
                        c: "gen"

            t2 = t.generate "a", c: "c"

            expect(t2).to.be.ok
            expect(Date.now() - t2.a).to.be.within(0, 1000) # Allow slop on the timestamp...

            expect(t2.b).to.match(/[a-f0-9]{8}-[a-f0-9]{4}-1[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}/)

            expect(t2.c).to.equal("c")

    it "should transform values on export", () ->
            t = new Validator
                a:
                    fields:
                        a: "any"
                        a2: "any"
                        a3: "any"
                        b: "never"
                        c: "string"
                        d: "identifier"
                        e: "stringArray"
                        e2: "stringArray"
                        e3: "stringArray"
                        f: "timestamp"
                        f2: "timestamp"
                        g: "expiration"
                        g2: "expiration"

            now = Date.now()

            t2 = t.generate "a",
                a: "A"
                a2: 52
                a3: { foo: 1 }
                c: "XYZZY"
                d: "HowNowBrownMoose"
                e: ["A"]
                e2: "B"
                e3: ["C","D"]
                f: new Date(now)
                f2: now / 1000
                g: 60000
                g2: new Date(now + 60000)

            expect(t2.g*1000-Date.now()).to.be.within(59000, 60000)
            delete t2.g

            expect(t2.g2*1000-Date.now()).to.be.within(59000, 60000)
            delete t2.g2

            expect(t2).to.deep.equal
                a: "A"
                a2: 52
                a3: { foo: 1 }
                c: "XYZZY"
                d: "HowNowBrownMoose"
                e: "A"
                e2: "B"
                e3: ["C","D"]
                f: now / 1000
                f2: now / 1000

    it "should parse values on validate", () ->
            t = new Validator
                a:
                    fields:
                        a: "any"
                        a2: "any"
                        a3: "any"
                        b: "never"
                        c: "string"
                        d: "identifier"
                        e: "stringArray"
                        e2: "stringArray"
                        e3: "stringArray"
                        f: "timestamp"
                        f2: "timestamp"
                        g: "expiration"
                        g2: "expiration"

            now = Date.now()

            t2 = t.validate "a",
                a: "A"
                a2: 52
                a3: { foo: 1 }
                c: "XYZZY"
                d: "HowNowBrownMoose"
                e: ["A"]
                e2: "B"
                e3: ["C","D"]
                f: now / 1000
                f2: new Date(now)
                g: now / 1000
                g2: new Date(now)

            expect(t2).to.deep.equal
                a: "A"
                a2: 52
                a3: { foo: 1 }
                c: "XYZZY"
                d: "HowNowBrownMoose"
                e: ["A"]
                e2: ["B"]
                e3: ["C","D"]
                f: new Date(now)
                f2: new Date(now)
                g: new Date(now)
                g2: new Date(now)

    describe "validate values", () ->
        it "should validate string values", () ->
            t = new Validator a: fields: a: "string"
            expect () -> t.validate "a", a: null
            .to.throw "Illegal value for a"
            expect () -> t.validate "a", a: ""
            .to.throw "Illegal value for a"
            expect () -> t.validate "a", a: 3
            .to.throw "Illegal value for a"
            expect () -> t.validate "a", a: { foo: 4}
            .to.throw "Illegal value for a"
            expect () -> t.validate "a", a: []
            .to.throw "Illegal value for a"

        it "should validate identifier values", () ->
            t = new Validator a: fields: a: "identifier"
            expect () -> t.validate "a", a: null
            .to.throw "Illegal value for a"
            expect () -> t.validate "a", a: ""
            .to.throw "Illegal value for a"
            expect () -> t.validate "a", a: 3
            .to.throw "Illegal value for a"
            expect () -> t.validate "a", a: { foo: 4}
            .to.throw "Illegal value for a"
            expect () -> t.validate "a", a: []
            .to.throw "Illegal value for a"

        it "should validate stringArray values", () ->
            t = new Validator a: fields: a: "stringArray"
            expect () -> t.validate "a", a: null
            .to.throw "Illegal value for a"
            expect () -> t.validate "a", a: ""
            .to.throw "Illegal value for a"
            expect () -> t.validate "a", a: 3
            .to.throw "Illegal value for a"
            expect () -> t.validate "a", a: { foo: 4}
            .to.throw "Illegal value for a"

        it "should validate timestamp values", () ->
            t = new Validator a: fields: a: "timestamp"
            expect () -> t.validate "a", a: null
            .to.throw "Illegal value for a"
            expect () -> t.validate "a", a: ""
            .to.throw "Illegal value for a"
            expect () -> t.validate "a", a: { foo: 4}
            .to.throw "Illegal value for a"
            expect () -> t.validate "a", a: new Date("xyzzy")
            .to.throw "Illegal value for a"

        it "should validate expiration values", () ->
            t = new Validator a: fields: a: "expiration"
            expect () -> t.validate "a", a: null
            .to.throw "Illegal value for a"
            expect () -> t.validate "a", a: ""
            .to.throw "Illegal value for a"
            expect () -> t.validate "a", a: { foo: 4}
            .to.throw "Illegal value for a"
            expect () -> t.validate "a", a: new Date("xyzzy")
            .to.throw "Illegal value for a"

    describe "bad schema", () ->
        it "should throw error if unknown type", () ->
            expect () -> new Validator a: fields: a: "doesNotExist"
            .to.throw "Unable to locate type for a"

        it "should throw error if gen is requested on type without a generator", () ->
            expect () -> new Validator(a:
                    fields:
                        a: "string"
                    req:
                        a: "gen"
                )
            .to.throw "No generate method available for a"

    it "should honor req=never", () ->
        t = new Validator a:
            fields:
                a: "string"
            req:
                a: "never"
        expect () -> t.validate "a", a: "a"
        .to.throw "Illegal value for a"

    it "show throw errors on unknown scopes", () ->
        t = new Validator a: {}

        expect () -> t.validate "b", {}
        .to.throw "Unknown scope"

        expect () -> t.generate "b", {}
        .to.throw "Unknown scope"

    it "should enforce allowed values", () ->
        t = new Validator a:
            fields: a: "string"
            allowedValues: a: /www/
        expect t.validate "a", a: "The www"
        .to.deep.equal a: "The www"
        expect t.generate "a", a: "The www"
        .to.deep.equal a: "The www"
        expect () -> t.validate "a", a: "The yyy"
        .to.throw "Not an allowed value for a"
        expect () -> t.generate "a", a: "yyy"
        .to.throw "Not an allowed value for a"

        t = new Validator a:
            fields: a: "string"
            allowedValues: a: ["www"]
        expect t.validate "a", a: "www"
        .to.deep.equal a: "www"
        expect t.generate "a", a: "www"
        .to.deep.equal a: "www"
        expect () -> t.validate "a", a: "yyy"
        .to.throw "Not an allowed value for a"
        expect () -> t.generate "a", a: "yyy"
        .to.throw "Not an allowed value for a"

        t = new Validator a:
            fields: a: "string"
            allowedValues: a: "www"
        expect t.validate "a", a: "www"
        .to.deep.equal a: "www"
        expect t.generate "a", a: "www"
        .to.deep.equal a: "www"
        expect () -> t.validate "a", a: "yyy"
        .to.throw "Not an allowed value for a"
        expect () -> t.generate "a", a: "yyy"
        .to.throw "Not an allowed value for a"

        t = new Validator a:
            fields: a: "string"
            allowedValues: a: (x) -> x == "www"
        expect t.validate "a", a: "www"
        .to.deep.equal a: "www"
        expect t.generate "a", a: "www"
        .to.deep.equal a: "www"
        expect () -> t.validate "a", a: "yyy"
        .to.throw "Not an allowed value for a"
        expect () -> t.generate "a", a: "yyy"
        .to.throw "Not an allowed value for a"

    it "should enforce disallowed values", () ->
        t = new Validator a:
            fields: a: "string"
            disallowedValues: a: /yyy/
        expect t.validate "a", a: "The www"
        .to.deep.equal a: "The www"
        expect t.generate "a", a: "The www"
        .to.deep.equal a: "The www"
        expect () -> t.validate "a", a: "The yyy"
        .to.throw "Disallowed value for a"
        expect () -> t.generate "a", a: "yyy"
        .to.throw "Disallowed value for a"

        t = new Validator a:
            fields: a: "string"
            disallowedValues: a: ["yyy"]
        expect t.validate "a", a: "www"
        .to.deep.equal a: "www"
        expect t.generate "a", a: "www"
        .to.deep.equal a: "www"
        expect () -> t.validate "a", a: "yyy"
        .to.throw "Disallowed value for a"
        expect () -> t.generate "a", a: "yyy"
        .to.throw "Disallowed value for a"

        t = new Validator a:
            fields: a: "string"
            disallowedValues: a: "yyy"
        expect t.validate "a", a: "www"
        .to.deep.equal a: "www"
        expect t.generate "a", a: "www"
        .to.deep.equal a: "www"
        expect () -> t.validate "a", a: "yyy"
        .to.throw "Disallowed value for a"
        expect () -> t.generate "a", a: "yyy"
        .to.throw "Disallowed value for a"

        t = new Validator a:
            fields: a: "string"
            disallowedValues: a: (x) -> x == "yyy"
        expect t.validate "a", a: "www"
        .to.deep.equal a: "www"
        expect t.generate "a", a: "www"
        .to.deep.equal a: "www"
        expect () -> t.validate "a", a: "yyy"
        .to.throw "Disallowed value for a"
        expect () -> t.generate "a", a: "yyy"
        .to.throw "Disallowed value for a"

    it "should use defaults", () ->
        t = new Validator a:
            allowAny: true
            defaults:
                a: 1
                b: 2
                c: 3

        expect t.validate "a", b:5
        .to.deep.equal a: 1, b: 5, c: 3

        expect t.generate "a", b:5
        .to.deep.equal a: 1, b: 5, c: 3

    it "should call pre and post methods", () ->
        t = new Validator a:
            fields:
                a:
                    verify: (x) -> return x == 2
                    parse: (x) ->
                        expect(x).to.equal(2)
                        return 3
                    export: (x) ->
                        expect(x).to.equal(2)
                        return 3

            pre: (x, scope, validator) ->
                expect(x.a).to.equal(1)
                expect(scope).to.equal("a")
                expect(validator).to.equal(t)
                x.a = 2

            post: (x, scope, validator) ->
                expect(x.a).to.equal(3)
                expect(scope).to.equal("a")
                expect(validator).to.equal(t)
                x.a = 4

        expect t.validate "a", a: 1
        .to.deep.equal a: 4

        expect t.generate "a", a: 1
        .to.deep.equal a: 4

    it "should discard undefined values", () ->
        t = new Validator a:
            allowAny: true
            fields:
                a:
                    parse: (x) ->
                    export: (x) ->

        expect t.validate "a", a: 1, b: 2
        .to.deep.equal b: 2

        expect t.generate "a", a: 1, b: 2
        .to.deep.equal b: 2

    it "should allow us to override __default__", () ->
        t = new Validator a:
            allowAny: false
            fields: __default__: "any"

        expect t.validate "a", a: 1
        .to.deep.equal a: 1

        expect t.generate "a", a: 1
        .to.deep.equal a: 1
