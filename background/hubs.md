# Hub Security Review
A review of various "hubs" for IoT and their security support.
By a "hub" we mean a service running on a local gateway that connects to local devices and
may provide other services: common dashboard, protocol translation, remote access, etc.
The reviews should answer the following questions:
* If we wrote a TD or TDs for the network APIs exposed by this hub, what security schemes would it use?   
* What kinds of device security can the hub deal with (e.g. can it talk to password and TLS-protected devices or services?)
* How is security metadata managed, i.e. how is "administrator" access protected?
* Is security handled locally or remotely (eg in a cloud service, via a cloud proxy, etc).
* Is remote access supported and if so, how is is protected?
* How is local access protected (if it is)?

It would also be helpful to summarize what services the hub offers.

## Home Assistant
Description from their web page:
* Open source home automation that puts local control and privacy first.
  Powered by a worldwide community of tinkerers and DIY enthusiasts.
  Perfect to run on a Raspberry Pi or a local server.

Company associated with project (supports cloud service for remote access): Nabu Casa, Inc.

[Home Assistant](https://www.home-assistant.io/) in a nutshell is "just" a smart hub for home automation.
Conceptually it is very similar to Mozilla Hub with the difference that it does not
follow any WoT spec and has more automation capabilities. 
Devices or services are integrated through scripting (precisely python scripts) and,
in general, it doesn't provide any specific security layer.
To take an example that we know well,
the Philips Hue is integrated using their API and security (API key).
Another example is the MQTT integration where the security is handled by
providing the username and password of the MQTT broker.
Security parameters are provided to Smart Assistant by humans
(administrator or other users) and are stored in encrypted configuration files.

Home Assistant does not expose any device or API by default
(i.e., it just discovers your local stuff and displays/automates it).
However, one script integration creates a RESTFul and WebSocket API.
So if we have to create a TD for smart assistant we could use the HTTP
and the WebSocket protocol bindings.
Security in the RESTFul API uses a standard bearer token obtained by users
from the [home assistant web page](https://developers.home-assistant.io/docs/api/rest).
On the other hand, the WebSocket API uses a custom protocol,
which I think the Protocol Binding task force should look at as an example.
Regarding security,
the custom protocol expects a 
[preamble message with the authentication parameters](https://developers.home-assistant.io/docs/api/websocket#server-states).

Remote access (i.e., outside your local network) is handled with a private connection
to a paid [cloud service](https://www.nabucasa.com/).
From there is not clear if you gain complete access also to the REST API
or just the ability to see your local web dashboard.

[TODO: Discuss] Other security mechanisms are different authentication methods to access the
web dashboard but I think it is not relevant for our use cases.
