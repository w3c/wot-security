# Hub Security Review
A review of various "hubs" for IoT and their security support.

## Home Assistant
Home Assistant in a nutshell is "just" a smart hub for home automation. Conceptually it is very similar to Mozilla Hub with the difference that it does not follow any WoT spec and has more automation capabilities. Devices or services are integrated through scripting (precisely python scripts) and, in general, it doesn't provide any specific security layer. To take an example that we know well, the Philips Hue is integrated using their API and security (API key). Another example is the MQTT integration where the security is handled by providing the username and password of the MQTT broker. Security parameters are provided to Smart Assistant by humans (administrator or other users) and are stored in encrypted configuration files.

Home Assistant does not expose any device or API by default (i.e., it just discover your local stuff and display/automate it). However, one script integration creates a RESTFull and WebSocket API. So if we have to create a TD for smart assistant we could use the HTTP and the WebSocket protocol bindings.
Security in the RESTFull API uses a standard bearer token obtained by users from the home assistant web page (see here). On the other hand, the WebSocket API uses a custom protocol, which I think the Protocol Binding task force should look at as an example. Regarding security, the custom protocol expects a preamble message with the authentication parameters (see here).

Remote access (i.e., outside your local network) is handled with a private connection to a paid cloud service. From there is not clear if you gain complete access also to the REST API or just the ability to see your local web dashboard.

Other security mechanisms are different authentication methods to access the web dashboard but I think it is not relevant for our use cases.
