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
          "id": "acl",
          "type": "ocf",
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
              "security": "acl"
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
              "security": ["acl","key"]
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
              "security": "acl"
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
since different protocols may support different security mechanisms.

The value in a security object inside a form can be a single string or an object.
If a string, it is an identifier that refers to a previously declared configuration at the 
top level.  If an object, it is a local configuration definition.  If an array, then
a set of configurations may be given, all of which must be satisfied to allow access.
Arrays can contain strings or objects, or both.

## Detailed Specifications of Configuration Specifications
To Do.

-
