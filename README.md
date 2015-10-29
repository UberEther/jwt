[![Build Status](https://travis-ci.org/UberEther/jwt.svg?branch=master)](https://travis-ci.org/UberEther/jwt)
[![NPM Status](https://badge.fury.io/js/uberether-jwt.svg)](http://badge.fury.io/js/uberether-jwt)

# TODO:
- [ ] Integrate dynamic unit tests that use the [jose-cookbook](https://github.com/ietf-jose/cookbook) data
- [ ] Create specific error classes for the various library errors

# Overview

This library provides a class for generating, parsing, and validating JWT tokens.  It uses [uberether-jwk](https://github.com/UberEther/jwk.git) for key management - that library provides options for loading local keys and/or loading them from URLs with periodic refreshes.

Asynchronous methods are based on [Bluebird](https://github.com/petkaantonov/bluebird) promises.  If you require callbacks, you can use the [Bluebird nodeify method](https://github.com/petkaantonov/bluebird/blob/master/API.md#nodeifyfunction-callback--object-options---promise).  For example: ```foo.somethingTharReturnsPromise().nodeify(callback);```

# EXAMPLES:

## Javascript
```js
// @todo WRITE ME
```

## Coffeescript
```coffeescript
# @todo WRITE ME
```

# APIs:

## JWT.JWKS 
the instance of uberether-jwk used by the JWT library.

## JWT(options)
Constructor

Available options:
- signingAllowed - Is signing allowed - must be "req", "opt", or "never"
- encryptionAllowed - Is signing allowed - must be "req", "opt", or "never"

### Validators

An uberether-object-validator compatible validator or schema may be provided to validate signing headers, encryption headers, and claims.  For any not provided, a new validator is generated using the default schema: ```{ skip: true }```
- signingHeaderSchema - A validator object OR a schema to generate one - used to validate signing headers
- encryptionHeaderSchema - A validator object OR a schema to generate one - used to validate encryption headers
- claimsSchema - A validator object OR a schema to generate one - used to validate claims

### Keystores
There are 2 keystores used by the alogrithm - a public and a private one.  The public keystore is used to verify signatures and encrypt data (both public key operations).  The private keystore is used to sign and decrypt (both private key operations).

The same or different JWKS objects may be used for each.

Configuration options to control these:
- Public JWKS:
	- jwks - JWKS object to use - must be an instance of uberether-jwk (or compatible)
	- jwksOptions - If JWKS is not specified, a new instance of uberether-jwk is initialized wit these options
	- If neither of these are set, a new keystore with no configuration is used
- Private JWKS:
	- pvtJwks - JWKS object to use - must be an instance of uberether-jwk (or compatible)
	- pvtJwksOptions - If JWKS is not specified, a new instance of uberether-jwk is initialized wit these options
	- If neither of these are set, the public JWKS is used
 
- jwks - An instance of uberether-jwk to use for processing
- jwksOptions - If specified the options passed to the uberether-jwk to construct the keystore
- pvt


### Methods

#### parseTokenAsync(token)
Parses and validates the token passed in.
- Throws exceptions if it fails to validate.
- Keys are obtained from the JWKS instance

The method returns a promise that resolves to an object containing:
- signingHeader - If the claim was signed, this will be an object with the JWS header
- rawVerifyResult - Raw result from the signature verification by node-jose - includes raw signature
- encryptionHeader - If the claim was signed, this will be an object with the JWA header
- rawDecryptResult - Raw result from the decryption operation by node-jose - includes the key used for decryption
- claims - An object containing the claims encoded in the JWT

Returns a promise that resolves to a string containing the token

#### generateTokenAsync(claims, options)
Generates a token containing the listed claims.  Allowed options are:
- encryptionKey - If the JWT is to be encrypted, then this is set to either a node-jose key to encrypt with OR a node-jose key-search criteria.
- signingKey - If the JWT is to be signed, then this is set to either a node-jose key to sign with OR a node-jose key-search criteria.

Returns a promise that resolves to an object with the following:
- signingOptions - If signed, these are the JWS options passed into node-jose
- encryptionOptions - If encrypted, these are the JWS options passed into node-jose
- token - The JWT in string form

# Contributing

Any PRs are welcome but please stick to following the general style of the code and stick to [CoffeeScript](http://coffeescript.org/).  I know the opinions on CoffeeScript are...highly varied...I will not go into this debate here - this project is currently written in CoffeeScript and I ask you maintain that for any PRs.