# WoT Security Best Practices

## Use Cases

TODO: define and list threats
- Do we really need this here?  Can it be in a separate document?

## Secure Transport

"Use latest version of TLS and DTLS"

* HTTPS (HTTP + TLS 1.3) 
* CoAPS (CoAP + DTLS) 
    - [IETF RFC7925 Transport Layer Security (TLS) /
                Datagram Transport Layer Security (DTLS)
                  Profiles for the Internet of Things](https://tools.ietf.org/html/rfc7925)
    - [IETF RFC7252 The Constrained Application Protocol (CoAP)](https://tools.ietf.org/html/rfc7252)
* MQTTS (MQTT + TLS 1.3) 
    - TODO link to standard
    - standard URL scheme for "mqtts://..." (draft IETF RFC for URL scheme)
    
### TODO TD Example

## Authentication and Access Control

* HTTPS with one of oauth2, bearer, basic, digest
   - TODO: consider adding psk, public, cert for local HTTPS
   - BUT maybe also leave out to limit scope of testing
   - Support for scopes in both oauth2 and bearer
   - TODO: what about realms in basic and digest?  Mapped to scopes?  A new scheme parameter?
* CoAPS with one of psk, public, cert
   - according to CoAP/DTLS spec (link to specific sections)
   - TODO: what about ACLs for OCF?
* MQTTS with basic AND psk (MQTT native username/password with psk for encrypted)
   - TODO: discuss use of psk/basic combo further

In addition, TDs with HTTP/nosec and CoAP/nosec should be tested and properly handled.
They are useful in conjunction with reverse proxies that layer on one of the above secure
transport and authentication schemes.

### Recommendations

## Thing Directories

* Thing Directories Protection
   - TODO: what is appropriate mechanisms
   - TODO: determine threat 
   - TODO: how is consent managed
   - TODO: private vs. public access
   - Previous: protected with basic or digest auth and HTTPS
   - Probably better: token or cert protection with credential server
   - TODO: considered signed TDs - pros and cons
       - threat: if TD server can be compromised
** node-wot may need to be updated to work with this
** need a reference thing directory
   - A docker image for a correct thing directory would be good

## Object Security

* Recommended if CoAP or MQTT to HTTP gateway that translates payloads.
    - Ideally you would NOT translate the payload but use end-to-end security.
* STILL use with TLS and DTLS
* Gateway will be prevented from modifying payload, but might want to add annotation
    - For example, adding timestamps

* COSE 
* OSCORE
* OSCOAP ?

### Secure Update and Post Manufacturing Provisioning

TODO: Link to IIC recommendations.

