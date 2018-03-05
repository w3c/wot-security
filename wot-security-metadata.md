# WoT Security Metadata

This is an initial proposal for security metadata to be included in the WoT Thing Description.
It is intended to be compatible with and equivalent in functionality to several other standards
and proposals,
including the 
[OpenAPI 3.0 Security Object](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.1.md#securitySchemeObject)
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
              "security": "ocf-config"
            },
            {
              "href": "https://mylamp.example.com/status",
              "mediaType": "application/json",
              "security": "basic-config"
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

TODO: We may want "read" access (eg the "GET" method) on a property to have different
(for example, weaker) security than "write" access (eg the "POST" and "PUT" methods).
How would we specify that here?

The value in a security object inside a form can be a single string or an object.
If a string, it is an identifier that refers to a previously declared configuration at the 
top level.  If an object, it is a local configuration definition.  If an array, then
a set of configurations may be given, all of which must be satisfied to allow access.
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
- "jwt": Javascript Web Token (to discuss: also under HTTP, but... what about CoAP, etc?)
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
- "jwt": Javascript Web Token

### HTTP Proxy Authentication

Type: "http-proxy"

This takes the same values as "http" but is targeted at the proxy, not the endpoint.
You would generally include this alongside a separate endpoint authentication scheme (eg you would use an array of configurations).

TO DISCUSS: Do we _need_ anything different from "http" here?

### OCF Security Model

Type: "ocf"

OCF mandates a specific security model, including ACLs (access control lists).
As OCF itself defines a set of standard introspection mechanisms to discover
security metadata, rather than repeat it all we simply specify that the OCF model
is used.

TO DISCUSS: The other option here would be have a set of options available for CoAP
security that are rich enough to describe the OCF security model.

### API Key
 
Type: "apikey"

OpenAPI-like API key specifications.  The key can be given in either the header or in the 
body, as indicated by the value of the "in" field:
- "in":"header" - the key is in the header
- "in":"body" - the key is in the body 
- "in":"cookie" - the key is in a cookie 

TO DISCUSS: This leaves open the format of the API key, so it is assumed opaque.
An alternative to an API key is a JWT token, which has similar properties but also includes
information about the source, expiry date, and other useful information.   We should look
at how API keys are used in practice to see if any additional parameters are needed.

### OAuth2.0

Type: "oauth2"

To do. There are also multiple flows: implicit, password, clientCredentials, and authorizationCode.
Each one may use different kinds of tokens.

TO DISCUSS: Which flows are relevant?

### OpenID Connect

Type: "openIdConnect"

To do.

TO DISCUSS: Is this relevant?

### Interledger
 
Type: "interledger"

To do.

TO DISCUSS: This is not really a standard yet so we should probably leave it out, for now,
but I think it's interesting and relevant for prototyping use cases that involve payments.

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
