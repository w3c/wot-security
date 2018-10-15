# WoT Security Best Practices

## Secure Transport

* HTTPS (HTTP + TLS 1.3) 
* CoAPS (CoAP + DTLS) 
* MQTTS (MQTT + TLS 1.3) 

## Authentication

* HTTPS with one of oauth2, basic, digest...
* CoAPS with one of psk, public, cert.
* MQTTS with basic (MQTT native username/password)

In addition, TDs with HTTP/nosec and CoAP/nosec should be tested and properly handled.
They are useful in conjunction with reverse proxies that layer on one of the above secure
transport and authentication schemes.

## Access Control

* Thing Directories: protected with basic or digest auth and HTTPS
** node-wot may need to be updated to work with this
* OAuth2 scopes on forms
** Scripting API may need to be updated to allow specification of scopes on properties etc.
* OAuth authentication servers
** Allowing connection of scopes to roles
** Allowing assignment of roles to users

## End-to-end Security

* COSE 
* OSCORE
* OSCOAP ?

## Secure Update and Post Manufacturing Provisioning

## Secure Interaction with Thing Directory


