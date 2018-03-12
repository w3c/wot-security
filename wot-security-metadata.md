# WoT Security Metadata (Strawman Proposal)

This is an initial proposal for security metadata to be included in the WoT Thing Description.
It is intended to be compatible with and equivalent in functionality to several other standards
and proposals,
including the 
[OpenAPI 3.0 Security Object](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.1.md#securitySchemeObject)
metadata, which includes in turn header and query parameter API keys, common OAuth2 flows, and OpenID.
Also included are support for OCF access control, Kerberos, Javascript Web Tokens, and Interledger payments.

One requirement is that security should be specifiable both across the entire thing and per-interaction.
Unfortunately, JSON-LD makes it difficult to take the OpenAPI approach of specifying a global default
and then per-interaction overrides.
Therefore, we instead take the approach of allowing the specification of an array of named
"security configurations" at global scope, and then allowing these specifications to be referenced 
in the definition of each interaction.

## TD Example
Before giving the details of each supported scheme, we will give a simple example of a TD using basic
HTTP authentication for HTTP links and ACL for equivalent CoAP links:

    {
      "@context": ["https://w3c.github.io/wot/w3c-wot-td-context.jsonld"],
      "@type": ["Thing"],
      "name": "MyLampThing",
      "@id": "urn:dev:wot:my-lamp-thing",
      "security": [
        {
          "@id": "basic-config",
          "type": "http",
          "scheme": "basic"
        },
        {
          "@id": "ocf-config",
          "type": "ocf"
        },
        {
          "@id": "apikey-config",
          "type": "apikey",
          "in": "header"
        }
      ],
      "interaction": [
        {
          "@type": ["Property"],
          "name": "status",
          "schema": {"type": "string"},
          "writable": false,
          "observable": true,
          "form": [
            {
              "href": "coaps://mylamp.example.com:5683/status",
              "mediaType": "application/json",
              "method": "coap:get",
              "security": "ocf-config"
            },
            {
              "href": "coaps://mylamp.example.com:5683/status",
              "mediaType": "application/json",
              "method": "coap:post",
              "security": ["ocf-config","apikey-config"]
            },
            {
              "href": "https://mylamp.example.com/status",
              "mediaType": "application/json",
              "method": "http:get",
              "security": "basic-config"
            },
            {
              "href": "https://mylamp.example.com/status",
              "mediaType": "application/json",
              "method": "http:post",
              "security": ["basic-config","apikey-config"]
            },
          ]
        },
        {
          "@type": ["Action"],
          "name": "toggle",
          "form": [
            {
              "href": "coaps://mylamp.example.com:5683/toggle",
              "mediaType": "application/json"
              "security": ["ocf-config","apikey-config"]
            },
            {
              "href": "https://mylamp.example.com/toggle",
              "mediaType": "application/json"
              "security": ["basic-config","apikey-config"]
            }
          ]
        },
        {
          "@type": ["Event"],
          "name": "overheating",
          "schema": {"type": "string"},
          "form": [
            {
              "href": "coaps://mylamp.example.com:5683/oh",
              "mediaType": "application/json"
              "security": "ocf-config"
            },
            {
              "href": "https://mylamp.example.com/oh",
              "mediaType": "application/json"
            }
          ]
        }
      ]
    }

In this example, we have three different security configurations: HTTP Basic Authentication,
OCF access control lists (the CoAP interface is actually to OCF devices), and an API key.
We also have one case where no security is used (the HTTPS interface to get overheating events)
and another case where two are required (to turn on the light by CoAP/OCF, we need both
access rights in the ACL _and_ an API key; the corresponding HTTPS interface needs both
basic authentication and the key).

Note that security is specified per "form" so that it can be different for each one,
as is often necessary when multiple protocols are supported for the same interaction,
since different protocols may support different security mechanisms.  In this case we
also wanted to support stronger security for actions that change the state of the light.

Since the API also allows changing the state of the light by writing to the "status" property,
we specify that "read" access (eg the "GET" method) on this property to has different
(weaker) security than "write" access (eg the "POST" and "PUT" methods).
In this example reads just require basic HTTP authentication
(or, under OCF, appropriate ACL authorization) but writes in addition require an API key,
consistent with the actions.  Note that in
practice the API key may not be needed to provide this differential access under OCF as the ACL
can include differential read/write access for different users (although that access is tied to 
identity, not ownership of the API key, so the additional API key provides an additional 
layer of security; in particular, an API key can be updated on a device to revoke access to
everyone with the old key).

The value in a security object inside a form can be a single string or an object.
If a string, it is an identifier that refers to a previously declared configuration at the 
top level.  If an object, it is a local configuration definition.  If an array, then
a set of configurations may be given, _all_ of which must be satisfied to allow access.
Arrays can contain strings or objects, or both.

## Additional Examples:

Matthias Kovatsc has [documented how the current version of Node-wot implements certain
security mechanisms](https://github.com/w3c/wot-security/issues/73).
His example includes several additional mechanisms not covered by the above,
including tokens and proxies.  Here are his two examples as they would be
expressed under the current proposal.

    {
      "@context": ["https://w3c.github.io/wot/w3c-wot-td-context.jsonld"],
      "@type": ["Thing"],
      "name": "FujitsuBeacon",
      "@id": "urn:dev:wot:fujitsu-beacon",
      "security": [{
        "@id": "token-config",
        "type": "token",
        "scheme": "bearer",
        "alg": "ES256",
        "as": "https://plugfest.thingweb.io:8443/"
      }],
      ...
    }
    
The interactions are omitted but under "form" in each there would have to be
a "security" : "token-config" entry.
  
Here is a second example using a proxy configuration:

    {
      "@context": ["https://w3c.github.io/wot/w3c-wot-td-context.jsonld"],
      "@type": ["Thing"],
      "name": "Festo",
      "@id": "urn:dev:wot:festo",
      "security": [{
        "@id": "proxy-config",
        "type": "http-proxy",
        "scheme": "basic",
        "href": "http://plugfest.thingweb.io:8087"
      }],
      ...
    }

As above, interactions are omitted but each would have to include a "security": "proxy-config" entry.

A few comments:
- A Thing ID (here encoded under the `@id` tag) is needed in order for tokens to work (they have to encode some identity).
- The "authority" tag in Matthias' example was changed to "type" and "schema" in this example
  to be consistent with this proposal's tag vocabulary, which is based on OpenAPI.
  To discuss... "type/schema" may be overly verbose and "type" conflicts with other uses of "type" in the TD.
- It is still necessary to refer to the name of the security configuration in each interaction.
  We _could_ make a rule like "the first security scheme mentioned is the default", the problem is consistency with JSON-LD.
- Note that in general security configurations have a set of "extra" parameters that depend on their type and scheme.
- I have converted the simple "proxy" type to "http-proxy" in case we want to contemplate others.
  In this case the "basic" scheme refers to basic HTTP proxy authentication.
- If we had defaults, it would be nice to automatically
  give the @id for a security configuration the same name as the scheme, if it is unique.

## Detailed Specifications of Configuration Specifications

Each configuration is identified with a "type" which must be one of the following:
- "http": HTTP Authentication
- "proxy": HTTP Proxy authentication (note: to be combined with other authentication mechanisms for the actual endpoint)
- "ocf": OCF security model (ACL)
- "apikey": API key
- "bearer": bearer token (to discuss: stand-alone possible?)
- "jwt": JSON Web Token (to discuss: also under HTTP, but... what about CoAP, etc?)
- "oauth2": OAuth2.0 (requires a flow definition)
- "openIdConnect": OpenID Connect
For each type, additional parameters may or may not be required.
These are specified in the corresponding sections below. 

### HTTP Authentication

Type: "http"

The standard HTTP security models can be specified (obviously, just on HTTP links) by
using the additional parameter "scheme" with the following values [RFC7235 https://tools.ietf.org/html/rfc7235#section-5.1]
- "basic": simple authentication
- "bearer": bearer token
If a bearer token is used, its format must be specified using "format", which should
have one of the following values.
- "jwt": JSON Web Token

### HTTP Proxy Authentication

Type: "http-proxy"

This takes the same values as "http" but is targeted at the proxy, not the endpoint.
You would generally include this alongside a separate endpoint authentication scheme (eg you would use an array of configurations).

### OCF Security Model

Type: "ocf"

OCF mandates a specific security model, including ACLs (access control lists).
As OCF itself defines a set of standard introspection mechanisms to discover
security metadata, rather than repeat it all we simply specify that the OCF model
is used.

### API Key
 
Type: "apikey"

OpenAPI-like API key specifications.  The key can be given in either the header or in the 
body, as indicated by the value of the "in" field:
- "in":"header" - the key is in the header
- "in":"body" - the key is in the body 
- "in":"cookie" - the key is in a cookie 

### OAuth2.0

Type: "oauth2"

To do. There are multiple flows: implicit, password, clientCredentials, and authorizationCode.
Each one may use different kinds of tokens.  We probably want to model after the [OpenAPI OAuth
Flow Object](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.1.md#oauthFlowObject).

### OpenID Connect

Type: "openIdConnect"

To do.

### Interledger
 
Type: "interledger"

To do.  To support pay-for-use services and deposit-based trust.
In addition to the address, it is necessary to specify the amount of deposit required,
and perhaps the amount per use.  Units also need to be specified.   This will often be
combined with other forms of authentication.  While not strictly a security mechanism,
it may be used as such (although maybe it's something only used indirectly eg at a
"ticket vending" service, not at individual IoT devices). 

## Issues
The following need to be discussed.  Discussion has been moved from comments on the original
PR to the issues linked below.

### OCF Security Model
OCF is built on top of CoAP and follows ACE recommendations so it's unclear whether or not
the OCF security model should have its own scheme tag.
The other option here would be have a set of options available for CoAP
security that are rich enough to describe the OCF security model.  We probably want
that anyway for non-OCF CoAP systems, so then this tag becomes a convenience for OCF.
However, in that case, we should also add "convenience" tags for other CoAP-based
standards (LWM2M, OMA, etc).

### Authentication Server Link
Many of these schemes require use of an authentication server.
A standard tag should be used for this when it is needed.
The example from Matthias uses "as".

### Algorithm
Many of these schemes require use of a specific encryption or hashing algorithm.
A standard tag should be used for this when it is needed.
The example from Matthias uses "alg".

### Proxy
A proxy requires a separate URL to access it.
A standard tag should be used for this when it is needed.
The example from Matthias uses "href".
However, should this be embedded in another access scheme, or have its own scheme?
For HTTP proxies, do we _need_ to specify anything different from "http"?

### Bearer Token Format
OpenAPI does not specify the terms used to identify different kinds of bearer tokens, since
they are not created by the client, but by an authentication server.
Should we be stricter, or not?

### API Key Format
The `apikey` scheme leaves open the format of the API key, so it is assumed opaque.
An alternative to an API key is a JWT token, which has similar properties but also includes
information about the source, expiry date, and other useful information.   We should look
at how API keys are used in practice to see if any additional parameters are needed.

### Cookie API Keys
Does this even make sense for machine to machine IoT APIs?

### OAuth
Which flows are relevant? What about other versions of OAuth? What about versions in general?

Discussion: [Issue #77](https://github.com/w3c/wot-security/issues/77)

### OpenIDConnect
Does this even make sense for IoT devices?

Discussion: [Issue #75](https://github.com/w3c/wot-security/issues/75)

### Interledger

This is not really a standard yet, but I think it's interesting and relevant for use cases that involve payments.  We should only support this, if at all, for prototyping reasons.

Discussion: [Issue #76](https://github.com/w3c/wot-security/issues/76)

## References

- [OpenAPI 3.0.1](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.1.md)
- [RFC7617 - The 'Basic' HTTP Authentication Scheme](https://tools.ietf.org/html/rfc7617)
- [RFC7519 JSON Web Token (JWT)](https://tools.ietf.org/html/rfc7519)
- [RFC7235 Hypertext Transfer Protocol (HTTP/1.1): Authentication](https://tools.ietf.org/html/rfc7235)
- [RFC6749 The OAuth 2.0 Authorization Framework](https://tools.ietf.org/html/rfc6749)
- [RFC7252 The Constrained Application Protocol (CoAP)](https://tools.ietf.org/html/rfc7252)
- [RFC8152 CBOR Object Signing and Encryption (COSE)](https://tools.ietf.org/html/rfc8152)
- [Authentication and Authorization for Constrained Environments (ACE); _Internet Draft_](https://tools.ietf.org/html/draft-ietf-ace-oauth-authz-09)
- [OCF Specifications](https://openconnectivity.org/developer/specifications)
- [AWS IoT Security Documentation](https://docs.aws.amazon.com/iot/latest/developerguide/iot-security-identity.html)
