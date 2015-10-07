[![Build Status](https://travis-ci.org/UberEther/jwt.svg?branch=master)](https://travis-ci.org/UberEther/jwt)
[![NPM Status](https://badge.fury.io/js/uberether-jwt.svg)](http://badge.fury.io/js/uberether-jwt)

# TODO:
- [ ] Integrate dynamic unit tests that use the [jose-cookbook](https://github.com/ietf-jose/cookbook) data
- [ ] Create specific error classes for the various library errors

# Overview

This library provides a class for generating, parsing, and validating JWT tokens.  It uses [uberether-jwk](https://github.com/UberEther/jwk.git) for key management - that library provides options for loading local keys and/or loading them from URLs with periodic refreshes.

Asynchronous methods are based on [Bluebird](https://github.com/petkaantonov/bluebird) promises.

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

## JWT.JWK 
the instance of uberether-jwk used by the JWT library.

## JWT(options)
Constructor 

### Keystores
There are 2 keystores used by the alogrithm - a public and a private one.  The public keystore is used to verify signatures and encrypt data (both public key operations).  The private keystore is used to sign and decrypt (both private key operations).

The same or different JWK objects may be used for each.

Configuration options to control these:
- Public JWK:
	- jwk - JWK object to use - must be an instance of uberether-jwk (or compatible)
	- jwkOptions - If JWK is not specified, a new instance of uberether-jwk is initialized wit these options
	- If neither of these are set, a new keystore with no configuration is used
- Private JWK:
	- pvtJwk - JWK object to use - must be an instance of uberether-jwk (or compatible)
	- pvtJwkOptions - If JWK is not specified, a new instance of uberether-jwk is initialized wit these options
	- If neither of these are set, the public JWK is used
 
### Verification Options

- signingRequired - Set to "req", "opt", or "never" - default is "req"
- encryptionRequired - Set to "req", "opt", or "never" - default is "never"


### Methods

#### parseTokenAsync(token)
Parses and validates the token passed in.
- Throws exceptions if it fails to validate.
- Keys are obtained from the JWK instance

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