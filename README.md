<p alighn="center">
 <a href="https://www.cyberghostvpn.com/"> <img src="https://raw.githubusercontent.com/tmcphee/cyberghostvpn/main/.img/CyberGhost-Logo-Header.png"></a>
</p>

# CyberGhost VPN
 
This is a WireGuard client docker that uses the CyberGhost Cli. It allows routing containers traffic through WireGuard.

## What is WireGuard?

WireGuard® is an extremely simple yet fast and modern VPN that utilizes state-of-the-art cryptography. It aims to be faster, simpler, leaner, and more useful than IPsec, while avoiding the massive headache. It intends to be considerably more performant than OpenVPN. WireGuard is designed as a general-purpose VPN for running on embedded interfaces and super computers alike, fit for many different circumstances.

## How to use this image
Start the image using optional environment variables shown below. The end-user must supply a volume for local storage of the CyberGhost auth and token files. Supplied DNS is optional to avoid using ISP DNS during the initial connection. 
```
docker run -d --cap-add=NET_ADMIN --dns 1.1.1.1 \
           -v /local/path/to/config:/home/root/.cyberghost:rw \
           cyberghostvpn
```

Other containers can connect to this image using by using its network connection.
`--net=container:cyberghostvpn`
```
docker run -d --net=container:cyberghostvpn other-container
```
Note: If the other containers have exposed ports for example a WEBUI. Forward that port in the cyberghostvpn image, add the port to WHITELISTPORTS environment variable, and set your local LAN using NETWORK environment variable. See `Environment variables` below for details. 

## Selecting a server

Once the initial setup is made the image will copy a run.sh file into the local volume (config folder). Open `run.sh` and edit the command `sudo cyberghostvpn --connect --torrent --country-code NL --wireguard` to the desired.
Examples:
- `sudo cyberghostvpn --traffic --country-code CA --wireguard --connect`
- `sudo cyberghostvpn --streaming 'Netflix US' --country-code US  --wireguard --connect`

See [GyberGhost selecting a country or single server](https://support.cyberghostvpn.com/hc/en-us/articles/360020673194--How-to-select-a-country-or-single-server-with-CyberGhost-on-Linux) for more details

## Environment variables

- `NETWORK` - Adds a route to the local network once the VPN is connected. CIDR networks [192.168.1.0/24]
- `WHITELISTPORTS` - Allow access to listed ports when VPN is connected. Delimited by comma [8080,8081,9000]

## Firewall
This image has a custom built-in firewall. On initial start, all traffic is blocked except CyberGhost API IP and Local DNS for resolve. After VPN is connected Local DNS is blocked on Port 53. For first time use the firewall will go through a setup phase to include whitelisted ports where the firewall will be inactive. 

See the firewall section located in start.sh for details. 

## Work in progress
- Logging in using enviroement variables
- In the meantime open the image console use `sudo cyberghostvpn --setup` to login then restart the container

## Disclaimer
This project was developed independently for personal use. CyberGhost has no affiliation, nor has control over the content or availability of this project. 
