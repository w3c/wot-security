# WoT Security Metadata

This is an initial proposal for security metadata to be included in the WoT Thing Description.
It is intended to be compatible with and equivalent in functionality to several other standards
and proposals,
including the 
[OpenAPI 3.0 Security Object https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.1.md#securitySchemeObject]
metadata (which includes in turn header and query parameter API keys, common OAuth2 flows, and OpenID.
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
      "security": [
        {
          "id": "simple",
          "type": "http",
          "scheme": "basic"
        },
        {
          "id": "ocfACL",
          "type": "ocf"
        },
        {
          "id": "key",
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
              "security": "ocfACL"
            },
            {
              "href": "https://mylamp.example.com/status",
              "mediaType": "application/json",
              "security": "simple"
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
              "security": ["ocfACL","key"]
            },
            {
              "href": "https://mylamp.example.com/toggle",
              "mediaType": "application/json"
              "security": ["simple","key"]
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
              "security": "ocfACL"
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

TODO: We may want "read" access (eg the "GET" method) on a property to have different
(for example, weaker) security than "write" access (eg the "POST" and "PUT" methods).
How would we specify that here?

The value in a security object inside a form can be a single string or an object.
If a string, it is an identifier that refers to a previously declared configuration at the 
top level.  If an object, it is a local configuration definition.  If an array, then
a set of configurations may be given, all of which must be satisfied to allow access.
Arrays can contain strings or objects, or both.

## Detailed Specifications of Configuration Specifications

Each configuration is identified with a "type" which must be one of the following:
- "http": HTTP Authentication
- "ocf": OCF security model (ACL)
- "apiKey": API key
- "oauth2": OAuth2.0
- "openIdConnect": OpenID Connect
For each type, additional parameters may or may not be required.
These are specified in the corresponding sections below. 

### Basic HTTP Authentication

Type: "http"

The standard HTTP security models can be specified (obviously, just on HTTP links) by
using the additional parameter "scheme" with the following values [RFC7235 https://tools.ietf.org/html/rfc7235#section-5.1]
- "basic": simple authentication
- "bearer": bearer token
If a bearer token is used, its format must be specified using "format", which should
have one of the following values.
- "JWT": Javascript Web Token

### OCF Security Model

Type: "ocf"

OCF mandates a specific security model, including ACLs (access control lists).
As OCF itself defines a set of standard introspection mechanisms to discover
security metadata, rather than repeat it all we simply specify that the OCF model
is used.

### API Key
 
Type: "apiKey"

OpenAPI-like API key specifications.  The key can be given in either the header or in the 
body, as indicated by the value of the "in" field:
- "in":"header" - the key is in the header
- "in":"body" - the key is in the body 
- "in":"cookie" - the key is in a cookie 

### OAuth2.0

Type: "oauth2"

To do. There are also multiple flows: implicit, password, clientCredentials, and authorizationCode.

### OpenID Connect

Type: "openIdConnect"

To do.

### Interledger
 
Type: "interledger"

To do.

## Issues
The following need to be discussed.

### Authentication Server Link
Many of these schemes require use of an authentication server.
Should the metadata include a link to the authentication server in this case?

### Bearer Token Format
OpenAPI does not specify the terms used to identify different kinds of bearer tokens, since
they are not created by the client, but by an authentication server.
Should we be stricter, or not?

### Cookie API Keys
Does this even make sense for M2M IoT APIs?

### OAuth
What about other versions of OAuth? What about versions in general?

### OpenIDConnect
Does this even make sense for IoT devices?

### Interledger
In addition to the address, it is necessary to specify the amount of deposit required,
and perhaps the amount per use.  Units also need to be specified.   This will often be
combined with other forms of authentication.  While not strictly a security mechanism,
it may be used as such (although maybe it's something only used indirectly eg at a
"ticket vending" service, not at individual IoT devices).
