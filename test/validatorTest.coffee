expect = require("chai").expect
generateValidator = require "../lib/generateValidator"

describe "generateValidator", () ->
    describe "SValidator Settings", () ->
        it "should validate empty objects, null, and undefined (when legal)", () ->
            t = generateValidator fields: typ: 1

            t2 = t.parse undefined
            expect(t2).to.deep.equal({})

            t2 = t.parse null
            expect(t2).to.deep.equal({})

            t2 = t.parse {}
            expect(t2).to.deep.equal({})

            t2 = t.export null
            expect(t2).to.deep.equal({})

            t2 = t.export undefined
            expect(t2).to.deep.equal({})

            t2 = t.export {}
            expect(t2).to.deep.equal({})

        it "should succeed when required fields are present", () ->
            t = generateValidator
                    fields: a: "string"
                    req: { "a": true }

            t2 = t.parse a: "A"
            expect(t2).to.deep.equal(a: "A")

            t2 = t.export a: "A"
            expect(t2).to.deep.equal(a: "A")

        it "should fail when required fields are missing", () ->
            t = generateValidator
                    fields: typ: 1
                    req:
                        typ: true

            expect () -> t.parse undefined
            .to.throw "Missing required field: typ"

            expect () -> t.parse null
            .to.throw "Missing required field: typ"

            expect () -> t.parse {}
            .to.throw "Missing required field: typ"

            expect () -> t.export undefined
            .to.throw "Missing required field: typ"

            expect () -> t.export null
            .to.throw "Missing required field: typ"

            expect () -> t.export {}
            .to.throw "Missing required field: typ"

    it "should allow other fields when specified", () ->
            t = generateValidator
                    allowAny: true

            expect t.parse foo: 2
            .to.deep.equal foo: 2

            expect t.export foo: 2
            .to.deep.equal foo: 2
    it "should not allow other fields by default", () ->
            t = generateValidator {}

            expect () -> t.parse foo: 2
            .to.throw "Illegal value for foo"

            expect () -> t.export foo: 2
            .to.throw "Illegal value for foo"

    it "should generate values when requested", () ->
            t = generateValidator
                    fields:
                        a: "timestampSeconds"
                        b: "identifier"
                        c: "identifier"
                    req:
                        a: "gen"
                        b: "gen"
                        c: "gen"

            t2 = t.export c: "c"

            expect(t2).to.be.ok
            expect(Date.now()/1000 - t2.a).to.be.within(0, 1000) # Allow slop on the timestampSeconds...

            expect(t2.b).to.match(/[a-f0-9]{8}-[a-f0-9]{4}-1[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}/)

            expect(t2.c).to.equal("c")

    it "should transform values on export", () ->
            t = generateValidator
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
                        f: "timestampSeconds"
                        f2: "timestampSeconds"
                        g: "expirationSeconds"
                        g2: "expirationSeconds"

            now = Date.now()

            t2 = t.export
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
                g: 60
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
            t = generateValidator
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
                        f: "timestampSeconds"
                        f2: "timestampSeconds"
                        g: "expirationSeconds"
                        g2: "expirationSeconds"

            now = Date.now()

            t2 = t.parse
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
            t = generateValidator fields: a: "string"
            expect () -> t.parse a: null
            .to.throw "Illegal value for a"
            expect () -> t.parse a: ""
            .to.throw "Illegal value for a"
            expect () -> t.parse a: 3
            .to.throw "Illegal value for a"
            expect () -> t.parse a: { foo: 4}
            .to.throw "Illegal value for a"
            expect () -> t.parse a: []
            .to.throw "Illegal value for a"

        it "should validate identifier values", () ->
            t = generateValidator fields: a: "identifier"
            expect () -> t.parse a: null
            .to.throw "Illegal value for a"
            expect () -> t.parse a: ""
            .to.throw "Illegal value for a"
            expect () -> t.parse a: 3
            .to.throw "Illegal value for a"
            expect () -> t.parse a: { foo: 4}
            .to.throw "Illegal value for a"
            expect () -> t.parse a: []
            .to.throw "Illegal value for a"

        it "should validate stringArray values", () ->
            t = generateValidator fields: a: "stringArray"
            expect () -> t.parse a: null
            .to.throw "Illegal value for a"
            expect () -> t.parse a: ""
            .to.throw "Illegal value for a"
            expect () -> t.parse a: 3
            .to.throw "Illegal value for a"
            expect () -> t.parse a: { foo: 4}
            .to.throw "Illegal value for a"

        it "should validate timestampSeconds values", () ->
            t = generateValidator fields: a: "timestampSeconds"
            expect () -> t.parse a: null
            .to.throw "Illegal value for a"
            expect () -> t.parse a: ""
            .to.throw "Illegal value for a"
            expect () -> t.parse a: { foo: 4}
            .to.throw "Illegal value for a"
            expect () -> t.parse a: new Date("xyzzy")
            .to.throw "Illegal value for a"

        it "should validate expirationSeconds values", () ->
            t = generateValidator fields: a: "expirationSeconds"
            expect () -> t.parse a: null
            .to.throw "Illegal value for a"
            expect () -> t.parse a: ""
            .to.throw "Illegal value for a"
            expect () -> t.parse a: { foo: 4}
            .to.throw "Illegal value for a"
            expect () -> t.parse a: new Date("xyzzy")
            .to.throw "Illegal value for a"

    describe "bad schema", () ->
        it "should throw error if unknown type", () ->
            expect () -> generateValidator fields: a: "doesNotExist"
            .to.throw "Unable to locate type for a"

        it "should throw error if gen is requested on type without a generator", () ->
            expect () -> generateValidator(
                    fields:
                        a: "string"
                    req:
                        a: "gen"
                )
            .to.throw "No generate method available for a"

    it "should honor req=never", () ->
        t = generateValidator
            fields:
                a: "string"
            req:
                a: "never"
        expect () -> t.parse a: "a"
        .to.throw "Illegal value for a"

    it "should enforce allowed values", () ->
        t = generateValidator
            fields: a: "string"
            allowedValues: a: /www/
        expect t.parse a: "The www"
        .to.deep.equal a: "The www"
        expect t.export a: "The www"
        .to.deep.equal a: "The www"
        expect () -> t.parse a: "The yyy"
        .to.throw "Not an allowed value for a"
        expect () -> t.export a: "yyy"
        .to.throw "Not an allowed value for a"

        t = generateValidator
            fields: a: "string"
            allowedValues: a: ["www"]
        expect t.parse a: "www"
        .to.deep.equal a: "www"
        expect t.export a: "www"
        .to.deep.equal a: "www"
        expect () -> t.parse a: "yyy"
        .to.throw "Not an allowed value for a"
        expect () -> t.export a: "yyy"
        .to.throw "Not an allowed value for a"

        t = generateValidator
            fields: a: "string"
            allowedValues: a: "www"
        expect t.parse a: "www"
        .to.deep.equal a: "www"
        expect t.export a: "www"
        .to.deep.equal a: "www"
        expect () -> t.parse a: "yyy"
        .to.throw "Not an allowed value for a"
        expect () -> t.export a: "yyy"
        .to.throw "Not an allowed value for a"

        t = generateValidator
            fields: a: "string"
            allowedValues: a: (x) -> x == "www"
        expect t.parse a: "www"
        .to.deep.equal a: "www"
        expect t.export a: "www"
        .to.deep.equal a: "www"
        expect () -> t.parse a: "yyy"
        .to.throw "Not an allowed value for a"
        expect () -> t.export a: "yyy"
        .to.throw "Not an allowed value for a"

    it "should enforce disallowed values", () ->
        t = generateValidator
            fields: a: "string"
            disallowedValues: a: /yyy/
        expect t.parse a: "The www"
        .to.deep.equal a: "The www"
        expect t.export a: "The www"
        .to.deep.equal a: "The www"
        expect () -> t.parse a: "The yyy"
        .to.throw "Disallowed value for a"
        expect () -> t.export a: "yyy"
        .to.throw "Disallowed value for a"

        t = generateValidator
            fields: a: "string"
            disallowedValues: a: ["yyy"]
        expect t.parse a: "www"
        .to.deep.equal a: "www"
        expect t.export a: "www"
        .to.deep.equal a: "www"
        expect () -> t.parse a: "yyy"
        .to.throw "Disallowed value for a"
        expect () -> t.export a: "yyy"
        .to.throw "Disallowed value for a"

        t = generateValidator
            fields: a: "string"
            disallowedValues: a: "yyy"
        expect t.parse a: "www"
        .to.deep.equal a: "www"
        expect t.export a: "www"
        .to.deep.equal a: "www"
        expect () -> t.parse a: "yyy"
        .to.throw "Disallowed value for a"
        expect () -> t.export a: "yyy"
        .to.throw "Disallowed value for a"

        t = generateValidator
            fields: a: "string"
            disallowedValues: a: (x) -> x == "yyy"
        expect t.parse a: "www"
        .to.deep.equal a: "www"
        expect t.export a: "www"
        .to.deep.equal a: "www"
        expect () -> t.parse a: "yyy"
        .to.throw "Disallowed value for a"
        expect () -> t.export a: "yyy"
        .to.throw "Disallowed value for a"

    it "should use defaults", () ->
        t = generateValidator
            allowAny: true
            defaults:
                a: 1
                b: 2
                c: 3

        expect t.parse b:5
        .to.deep.equal a: 1, b: 5, c: 3

        expect t.export b:5
        .to.deep.equal a: 1, b: 5, c: 3

    it "should call pre and post methods", () ->
        t = generateValidator
            fields:
                a:
                    verify: (x) -> return x == 2
                    parse: (x) ->
                        expect(x).to.equal(2)
                        return 3
                    export: (x) ->
                        expect(x).to.equal(2)
                        return 3

            pre: (x, validator) ->
                expect(x.a).to.equal(1)
                expect(validator).to.be.ok
                x.a = 2

            post: (x, validator) ->
                expect(x.a).to.equal(3)
                expect(validator).to.be.ok
                x.a = 4

        expect t.parse a: 1
        .to.deep.equal a: 4

        expect t.export a: 1
        .to.deep.equal a: 4

    it "should discard undefined values", () ->
        t = generateValidator
            allowAny: true
            fields:
                a:
                    parse: (x) ->
                    export: (x) ->

        expect t.parse a: 1, b: 2
        .to.deep.equal b: 2

        expect t.export a: 1, b: 2
        .to.deep.equal b: 2

    it "should allow us to override __default__", () ->
        t = generateValidator
            allowAny: false
            fields: __default__: "any"

        expect t.parse a: 1
        .to.deep.equal a: 1

        expect t.export a: 1
        .to.deep.equal a: 1
