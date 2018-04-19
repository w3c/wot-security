# WoT Security Metadata (Proposal)

This is a proposal for security metadata to be included in the WoT Thing Description.
It is intended to be compatible with and equivalent in functionality to
several other standards and proposals, including the 
[OpenAPI 3.0 Security Object](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.1.md#securitySchemeObject)
metadata, which includes in turn header and query parameter API keys, common OAuth2 flows, and OpenID.
Also included are support for
OCF access control, Kerberos, Javascript Web Tokens, and Interledger payments.

This proposal allows different security
configurations to be specifiable both across the entire thing and per-interaction
(actually, per link in each interaction).
We allow the specification of an array of named
"security configurations" at global scope.
These configuration can then be referenced and combined
in the definition of each interaction.
This approach also allows a "OR-AND" approach to security configurations.
Within each specific
"form" within an interaction, all security configurations specified need to be met:
an AND combination.
However, multiple form alternatives are possible within an interaction,
and these can have different security requirements: an OR combination.

This proposal takes advantage of (proposed) JSON-LD 1.1 features.
This proposal is similar to a new feature being proposed for the TD,
a "definition" block.  However, we recommend that a separate "security"
block be used specifically for security metadata.  The "definitions"
block is still useful to, for example, create definitions for combinations
of security configurations suitable to particular roles, thereby
abstracting security definitions.

## TD Example
Before giving the details of each supported security configuration scheme,
we will give a simple example of a TD using basic
HTTP authentication for HTTPS links and OCF access control lists for equivalent CoAP links:

    {
      "@context": ["https://w3c.github.io/wot/w3c-wot-td-context.jsonld",
                   "https://w3c.github.io/wot/w3c-wot-common-context.jsonld",
                    {
                      "iot": "http://iotschema.org/",
                      "http": "http://iotschema.org/protocol/http",
                      "coap": "http://iotschema.org/protocol/coap"
                    }
                  ],
      "@type": ["Thing","iot:Light","iot:BinarySwitch"],
      "label": "MyLampThing",
      "@id": "urn:dev:wot:my-lamp-thing",
      "security": {
        "basicConfig": {
          "scheme": "basic"
        },
        "ocfConfig": {
          "scheme": "ocf"
        },
        "apikeyConfig": {
          "scheme": "apikey",
          "in": "header"
        }
      },
      "properties": {
        "status": {
          "name": "Status",
          "@type": ["iot:SwitchStatus"],
          "schema": {
             "type": "boolean"
          },
          "writable": true,
          "observable": true,
          "form": [
            {
              "href": "coaps://mylamp.example.com:5683/status",
              "mediaType": "application/json",
              "rel": "readProperty",
              "coap:methodCode": 1,
              "security": "ocfConfig"
            },
            {
              "href": "coaps://mylamp.example.com:5683/status",
              "mediaType": "application/json",
              "rel": "writeProperty",
              "coap:methodCode": 3,
              "security": ["ocfConfig","apikeyConfig"]
            },
            {
              "href": "https://mylamp.example.com/status",
              "mediaType": "application/json",
              "rel": "readProperty",
              "http:methodName": "GET",
              "security": "basicConfig"
            },
            {
              "href": "https://mylamp.example.com/status",
              "mediaType": "application/json",
              "rel": "writeProperty",
              "http:methodName": "PUT",
              "security": ["basicConfig","apikeyConfig"]
            },
          ]
        }
      },
      "actions": {
        "toggle": {
          "name": "Toggle",
          "@type": ["iot:ToggleAction"],
          "form": [
            {
              "href": "coaps://mylamp.example.com:5683/toggle",
              "mediaType": "application/json"
              "rel": "invokeAction",
              "coap:methodCode": 2,
              "security": ["ocfConfig","apikeyConfig"]
            },
            {
              "href": "https://mylamp.example.com/toggle",
              "mediaType": "application/json"
              "rel": "invokeAction",
              "http:methodName": "POST",
              "security": ["basicConfig","apikeyConfig"]
            }
          ]
        }
      },
      "events": {
        "overheating": {
          "name": "Overheating",
          "@type": ["iot:OverheatEvent"],
          "schema": {"type": "string"},
          "form": [
            {
              "href": "coaps://mylamp.example.com:5683/oh",
              "mediaType": "application/json"
              "rel": "subscribeEvent",
              "coap:methodCode": 1,
              "security": "ocfConfig"
            },
            {
              "href": "https://mylamp.example.com/oh",
              "rel": "subscribeEvent",
              "http:methodName": "GET",
              "mediaType": "application/json"
            }
          ]
        }
      }
    }

In this example, we have three different security configurations: HTTP Basic Authentication,
OCF access control lists (the CoAP interface is actually to OCF devices), and an API key.
We also have one case where _no_ security is used (the HTTPS interface to get overheating events)
and another case where two are required (to turn on the light by CoAP/OCF, we need both
access rights in the ACL _and_ an API key; the corresponding HTTPS interface needs both
basic authentication and the key).

*Note:* Security is specified per `form` so that it can be different for each one,
as is often necessary when multiple protocols are supported for the same interaction,
since different protocols may support different security mechanisms.  In this case we
also wanted to support stronger security (eg multiple authentication mechanisms)
for actions that change the state of the device.

Since the API also allows changing the state of the device by writing to the `status` property,
we specify that "read" access (eg the "GET" method) on this property to has different
(weaker) security than "write" access (eg "POST" or "PUT" methods).

In general if a property is marked as being writable
this means it is writable for _some_ user.  Conversely, if it is marked as
not being writable, it is not writeable by _any_ user, regardless of access rights.
For example, it does not in general make sense to write to sensors whose state
reflects the measured value of a physical property.
A property may also be immutable for other reasons, for example, immutable configuration
state such as a ID that can only be set during provisioning.
The main point is that the `writable` flag is not meant to represent
a constraint due to access rights.  In particular if some configuration can
be updated by an administrator with sufficient access rights, 
but not by a normal user, it should still be marked as writable.

**To Discuss**: What if we have "filtered" TDs where a TD is generated for
a specific class of users?  For example, we might want to have a TD specifically
for normal users and another for administrators.  The former would omit any
properties or actions that users cannot access at all.  It _might_ make sense in
this case to mark properties that no users in the target set can have write
access to as not being readable.  In other words, the "writable" flag refers
to the capabilities of all users in the target set.

In this example reads just require basic HTTP authentication
(or, under OCF, appropriate ACL authorization) but writes in addition require an API key,
consistent with the interactions.
In practice the API key may not be needed to provide this differential access under OCF as the ACL
can include differential read/write access for different users.  However, that access is tied to 
identity, not ownership of the API key, so the additional API key provides an additional 
layer of security; in particular, an API key can be updated on a device to revoke access to
everyone with the old key.

The value in a security object inside a form can be a single string or an object.
If a string, it is an identifier that refers to a previously declared configuration at the 
top level.  If an object, it is a local configuration definition.  If an array, then
a set of configurations may be given, _all_ of which must be satisfied to allow access.
Arrays can contain strings or objects, or both.

All links in this example use secure transport, i.e. either CoAPS (CoAP over UDP using DTLS)
or HTTPS (HTTP over TCP using TLS).
These transports use certificates for mutual authentication, secure session key exchange,
and of course encrypted transport.  In fact, use of such encrypted transport is essential
for many authorization schemes, such as basic HTTP authentication, which transmits a
username and password "in the clear" in the header.  This is only secure if the header is
encrypted by an outer transport layer.  Likewise, other authentication mechanisms not
used in this example, such as bearer tokens, also rely on secure transport to protect against
certain forms of attack, since an intercepted bearer token could be used by an attacker to gain
access to the device.  The security configuration metadata in this example focuses on 
authentication, but in general the goal is authorization (providing access rights) to
authenticated users.

**To discuss:** In this example, it is assumed that issues such as certificate authentication
for TLS can be handled by TLS itself, although it may use other information 
in the TD (for example, a UUID or other value in the `@id` field) to validate identity.
This is useful in situations where
normal certificate validation cannot be performed, eg semi offline systems.

## Additional Examples:
Matthias Kovatsc has [documented how 'node-wot' circa March 2018 implemented certain
security mechanisms](https://github.com/w3c/wot-security/issues/73).
His example included several additional mechanisms,
including tokens and proxies.  Here are two of his examples as they would be
expressed under the current proposal.

### Bearer Tokens
Here is an example (based on Matthias' example, above) using bearer tokens:

    {
      "@context": ["https://w3c.github.io/wot/w3c-wot-td-context.jsonld",...],
      "@type": ["Thing"],
      "name": "FujitsuBeacon",
      "label": "Beacon",
      "@id": "urn:dev:wot:fujitsu-beacon",
      "security": {
        "bearerTokenConfig": {
          "scheme": "bearer",
          "format": "jwt",
          "alg": "ES256",
          "authorizationUrl": "https://plugfest.thingweb.io:8443/"
        },
        ... // other security configurations, if needed
      },
      ...
      "properties": {
        "status": {
          ...
          "form": [
            {
              ...
              "security": "bearerTokenConfig"
            },
            ... // other forms
        },
        ... // other properties
      },
      ... // other interactions
    }

As shown, in each form under interactions there would have to be
a `"security" : "bearerTokenConfig"` entry.  As bearer tokens need
to be protected from interception they should only be used in combination with
secure transport.

**To Discuss**: Should TD validation flag insecure 
configurations, such as basic authentication or bearer tokens
combined with non-encrypted transports?  These could be warnings
rather than errors, since they might be useful during development.
  
### Proxies
Here is a second example using a proxy configuration:

    {
      "@context": ["https://w3c.github.io/wot/w3c-wot-td-context.jsonld",...],
      "@type": ["Thing"],
      "label": "Festo",
      "@id": "urn:dev:wot:festo",
      "security": {
        "proxyConfig": {
          "scheme": "basic",
          "proxyUrl": "http://plugfest.thingweb.io:8087"
        },
        "endpointConfig": {
          ... // details omitted; independent of proxy configuration
        },
        ... // other security configurations, if needed
      },
      "definitions": {
        "propertySecurityConfig": ["proxyConfig","endpointConfig"],
        // other definitions
      },
      ...
      "properties": {
        "status": {
          ...
          "form": [
            {
              ...
              "security": "propertySecurityConfig"
            },
            ... // other forms
          ]
        },
        ... // other properties
      },
      ... // other interactions
    }

As above, each form under interactions 
would have to include a _both_ a `proxyConfig` _and_ an `endpointConfig`
reference in its `security` field.
We make use of the new definitions feature here to
avoid having to repeat such combinations in every form that uses them;
the two configurations are combined into one using an array `propertySecurityConfig`
declared under `definitions`.
Multiple proxy configuration and endpoint configurations could also
be included in a single Thing Description.
In this example, the details of the endpoint security configuration have 
been omitted.
Proxy authentication is handled separately from
endpoint configuration in any case.

### OAuth
This example uses an OAuth authorization code flow.

    {
      "@context": ["https://w3c.github.io/wot/w3c-wot-td-context.jsonld",...],
      "@type": ["Thing"],
      "label": "Camera",
      "@id": "urn:dev:wot:camera",
      "base": "https://...",
      "security": {
        "oauthConfig": {
          "scheme": "oauth2",
          "flow": "code",
          "authorizationUrl": "https://example.com/api/oauth/dialog",
          "tokenUrl": "https://example.com/api/oauth/token",
          "refreshUrl": "https://example.com/api/oauth/refresh",
          "scope": [
            { "name": "read:frame" },
            ... // other scopes
          ]
        }
        ... // other security configurations, if needed
      },
      ...
      "properties": {
        "frame": {
          ...
          "writable": false,
          "observable": true,
          "form": [
            {
              "href": "/api/frame",
              "mediaType": "image/jpeg",
              "rel": "readProperty",
              "security": "oauthConfig",
              "scope": "read:frame"
            },
            {
              "href": "/api/frame/observe",
              "mediaType": "image/jpeg",
              "rel": "observeProperty",
              "security": "oauthConfig",
              "scope": "read:frame"
            }
        },
        ... // other properties
      },
      ... // other interactions
    }

Here we see that an additional field is used for OAuth flows, `scope`.
This could be generalized to other authentication mechanisms to restrict
application of a security mechanism to those with matching scope definitions.

We do not specify `http:methodName' here so the defaults are used.
Due to the write restriction, only reading and observation of this property is 
supported.

### Comments
A few comments:
- A Thing ID (encoded under some top-level tag, such as `@id`, as shown)
  is needed in order for tokens to work (they have to encode some identity).
- The `authorization` tag in Matthias' example was changed to `scheme` 
  to be more consistent with this proposal's tag vocabulary, which is based on OpenAPI.
  At any rate, it is more consistent to talk about _authorization_, but use of
  `scheme` avoids any confusion.
  Unlike OpenAPI, however, we only use a single name for the `scheme` and it is actually
  the combination of the `scheme` with the protocol used in a particular form that determines
  the actual security mechanism.
    - For example, `"basic"` authentication means clear-text user name and password,
      but this will be instantiated in different ways in MQTT and HTTP.
- **To discuss:** 
  It is still necessary to refer to the name of the security configuration in each interaction.
  We might be able to use a rule like "the first security scheme mentioned is the default" as 
  long as we can make this work with JSON-LD.
- In general security configurations have a set of "extra" parameters that depend on their type
  and scheme. Several of these tags, however, are used in more than one scheme.
    - For example, many schemes have references to an authentication server.
- If a security configuration is intended for a proxy this is indicated by giving a value (a URL)
  to the `proxyUrl` tag.  If no such value is given, then the configuration is intended for the 
  endpoint.

## Detailed Specifications of Configurations
Each configuration is identified with a `scheme` which currently must be one of the following:
- `basic`: Clear-text username and password (must be encapsulated in encrypted transport)
- `ocf`: OCF security model (access control lists with authentication servers and tickets)
- `apikey`: API key (opaque strings)
- `bearer`: bearer token (format given by the value of a `format` field) 
- `pop`: proof of possession token (format given by the value of a `format` field) 
- `oauth2`: OAuth2.0 authentication flows (no support for OAuth1.0, however; see OpenAPI discussion)

For each scheme, additional parameters may be required.
These are specified in the corresponding sections below. 

*Notes:*
- OpenIDConnect is not included in the above since it is a user identification scheme,
  not an authorization scheme. However, it might be used by an authorization server to
  identify a user, and we assume authentication services will be implemented by other means,
  eg web services with metadata in OpenAPI.  
    - **To discuss:** can a Thing be an authentication server?
- In general we have tried to use generic tags identifying authorization schemes that are
  orthogonal to protocols.
    - For example, in theory, `basic` authentication can be combined with several transport
      protocols, such as HTTPS and MQTT, although it is only secure if that transport is
      previously encrypted by other means.
    - This also raises a validation question:
      combining certain authentication schemes with certain protocols should be considered an
      error.
- OCF is an exception.  It has its own scheme label since it has an authentication scheme specific to OCF,
  even though it is built on top of the ACE specification.  OCF authorization and communication
  can also take place over multiple protocols (COAPS and HTTPS).
    - **To discuss:** we may want to add an `ace` scheme with an appropriate set of parameters.
- This is not a closed set. In particular, additional tags may be needed for additional schemes
  specific to particular ecosystems: OneM2M, OPC-UA, MQTT, AWS IoT, HomeKit, etc. or supported
  by additional standards.  Whenever possible new schemes should reuse parameter vocabulary
  already defined and be defined in a way orthogonal to transport protocols.

### Basic Authentication
Scheme: `basic`

In the basic authentication scheme, a username and password are provided in plaintext,
using a mechanism specific to the protocol.  Additional parameters may be necessary for
some protocols as follows:
- `https`:
    - `in`: specifies location of the authentication information.  See defintion below.

Since the username and password used in this scheme are in plaintext, they need
to be sent via a mechanism that provides transport security, such as TLS.  In the case of HTTP,
this means that a secure HTTPS connection needs to be established before this authentication
method can be used.  In the context of a Thing Description this means that this mechanism
should only be combined with protocols supporting secure transport,
eg. COAPS, HTTPS, and the equivalent.

### OCF Security 
Scheme: `ocf`

OCF mandates a specific security model, including ACLs (access control lists),
an authentication server, and tickets.
As OCF itself defines a set of standard introspection mechanisms to discover
security metadata, including the location of authorization servers, 
rather than repeat it all we simply specify that the OCF model is used.

**Note:** We should build prototypes to discover if additional configuration parameters are needed
in practice.

### API Key
Scheme: `apikey`

The key can be given in either the header or in the 
body, as indicated by the value of the `in` field (see definition below).

By definition an API key is opaque.  If the key is not opaque it should be considered a token.

### OAuth2.0
Scheme: `oauth2`

In general OAuth2 supports multiple flows, indicated with the `flow` field, which has 
one of the following values:
- `implicit`: also requires `authorizationUrl` and `scope` array.
- `password`: also requires `tokenUrl` and `scope` array.
- `client`: also requires `tokenUrl` and `scope` array.
- `code`: requires both `authorizationUrl` and `tokenUrl` URLs and `scope` array.

This is modelled after the [OpenAPI OAuth
Flow Object](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.1.md#oauthFlowObject) 
specification.
In partiuclar we use the names `authorizationUrl` and `tokenUrl` to be consistent with OpenAPI.
In addition to the above required values, all flows may also have a 
`refreshUrl`. 

All flows require an array of scopes.  These are a set of strings giving a name to each scope.
Within each form of an interaction, an additional `scope` field is needed giving an array
of authorized scopes.  Note that the value of the `scope` field may be reduced to a single
value if the array only has one element.

**To discuss:** Note that the version is embedded in the name.
We may want to generalize this to other
standards _or_ define a general mechanism to specify a minimum version.  If we embed versions
in names, we need a consistent rule to identify versions in schemes that do not have them
embedded.  OAuth is also a funny special case since we don't intend to support OAuth version 1.

## Other Schemes
It's not clear we need to support these, so we have left them out of the 
initial proposal, but we mention them here to provide a starting
point for discuission.

### OpenID Connect
Scheme: `openIdConnect`

This is provided for in OpenAPI but is an identification (authentication) scheme, whereas
for Thing interactions we are generally interested in authorization.  OpenIdConnect is 
also user-oriented.  It seems more appropriate to only support this on authorization servers.

If this is supported, it would also use the `scope` and `authorizationUrl` fields defined for OAuth.

**To discuss:** we _may_ want to support this if Things can act as authentication servers.

### Interledger
Scheme: `interledger`

Interledger can support pay-for-use services and deposit-based trust.
In addition to the address, it is necessary to specify the amount of deposit required,
and perhaps the amount per use.  Units also need to be specified.   This will often be
combined with other forms of authentication.  While not strictly a security mechanism,
it may be used as such (although maybe it's something only used indirectly e.g. at a
"ticket vending" service, not at individual IoT devices). 

**To discuss:** Supporting this as an experimental authentication scheme, perhaps alongside
other schemes based on permissioned blockchain (eg hyperledger).

## Security Parameter Vocabulary
This section defines terms used to identify 
parameters that can be used with one or more security configurations.

### Authorization Server Link
Tag: `authorizationUrl`

For authentication schemes requiring the use of an authorization server to obtain
tokens or keys.

Value: URL specifying the location of the authorization server.

### Token Server Link
Tag: `tokenUrl`

For authentication schemes requiring the use of an token server to obtain
tokens or keys.

Value: URL specifying the location of the token server.

**Note:** the OAuth code flow, as well as Kerberos, have multiple authorization servers.
The first provides a ticket-granting ticket, the second actually provides this tickets.
This is done for reasons of scalability.  This may be optional if the information
is provided by the authentication server.

### Refresh Server Link
Tag: `refreshUrl`

For authentication schemes requiring the use of an token server to obtain
refreshed tokens or keys.

Value: URL specifying the location of the refresh server.  This only needs to be
provided in general if it is different from the `tokenUrl`.  It is also optional
since usually the information is provided a by the authorization server.

### Authorization Scopes
Tag: `scope`

Value: an array of strings used to identify different roles for interactions.

If used, each form also needs a `scope` tag (which can be
an array or a single value) specifying the
authorization roles it can be used with.

**To discuss:** Would an implied default value for `scope` be useful here?  For example,
if not given, it could be assumed that an interaction can be used with all scopes.

### Algorithm
Tag: `alg`

Many schemes require use of a specific encryption or hashing algorithm, or 
combination of algorithms.  This is usually referred to as a "ciphersuite".

Value: String specifying the ciphersuite used.  One of:
- `ES256`: SHA-256 ciphersuite.

**To do:** we should indicate a set of additional valid values for this based on existing RFCs
and standards.

### Proxy
Tag: `proxyUrl`

For protocols that support proxies, the proxy may have its own authentication scheme
separate from that of the endpoint.  If a security configuration includes a value
for the following tag, it indicates the information provided is for the proxy and not the
endpoint.

Value: URL of the proxy.

### Format
Tag: `format`

Some authentication schemes have options for how data is to be encoded, in particular,
there might be different formats for how tokens are encoded.  This tag indicates how
the data for a scheme is encoded.  Valid values depend on the scheme.

For the `"token"` scheme, the value is one of 
- `"jwt"`: JSON Web Token 
    
**Note:** The format tag is only used in one place for now and when used currently only has
one legal value.  This is a temporary situation and we expect `format`
to be used in multiple schemes and also to be used to express multiple formats for tokens 
in the future.

### In
Tag: `in`

Location of information in a particular protocol.

Value is one of
- `header`: in protocol header
- `parameter`: the key is added to the url as a query parameter
- `body`: in payload body
- `cookie`: in data maintained by the client and sent automatically with each transaction
  (typically also in the header, but in a different field)

**Note:** The `parameter` option requires manipulation of the URL.  In this case the URL given
in the `href` parameter is just considered the base URL.

### Name
Tag: `name`

The name to be used for a header, query parameter, or cookie.  In the case of a header
this can be omitted if there is a useful default.

**To discuss:** Should this be `label`?  However, `name` is consistent with OpenAPI.

## Protocol-Specific Notes
Schemes only resolve into specific security mechanisms when combined with specific protocols.
Right now only the following combinations are supported:
- `basic`+`https`: Basic HTTP Authentication
    - When used in combination with a `proxyUrl` tag indicates Basic HTTP Proxy Authentication
- `bearer`+`https`: requires a `format' tag as well
- `bearer`+`coaps`: requires a 'format' tag as well
- `pop`+`https`: requires a `format' tag as well
- `pop`+`coaps`: requires a 'format' tag as well
- `apikey`+`https`
- `apikey`+`https`
- `apikey`+`coaps`
- `ocf`+`coaps`

**To discuss:** Other combinations may make sense, for example, basic authentication under COAPS,
tokens and api keys with non-encrypted transports (maybe, if the tokens are self-protected
somehow), and support for additional protocols (for example, MQTT).

### HTTP
The standard HTTP security models can be specified by
using the following schemes. 
- `basic`: simple (basic) authentication
- `bearer`: bearer token
- `pop`: proof-of-possession token
Please refer to [RFC7235 https://tools.ietf.org/html/rfc7235#section-5.1].
If basic authentication is used, the location should be specified using the `in` tag.
If no value is given for this, `header` is assumed.
If a token is used, its format must be specified using `format`.

**Notes:** 
- Basic authentication assumes defaults whose values actually depend on the protocol
  it is combined with, and whether a proxy is being used.  
    - **To discuss:** whether this will work with JSON-LD. 

### HTTP Proxy Authentication
This takes the same values as `http` but is targeted at the proxy, not the endpoint.
In this case, in addition to the standard configuration, a URL specifying the proxy
should be given as the value of a `proxy` tag.
You would generally include this alongside a separate endpoint authentication scheme 
(eg you would use an array of security configurations in each form using the proxy).

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
