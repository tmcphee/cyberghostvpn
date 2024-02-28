<p align="center">
 <a href="https://www.cyberghostvpn.com/"> <img src="https://raw.githubusercontent.com/tmcphee/cyberghostvpn/main/.img/CyberGhost-Logo-Header.png"></a>
</p>

# CyberGhost VPN
![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/tmcphee/cyberghostvpn/docker-image.yml?style=for-the-badge) ![GitHub release (latest by date)](https://img.shields.io/github/v/release/tmcphee/cyberghostvpn?style=for-the-badge)

This is a WireGuard client docker that uses the CyberGhost CLI. It allows routing containers traffic through WireGuard.

[Docker Image](https://hub.docker.com/r/tmcphee/cyberghostvpn)
###### Ubuntu 20.04 | CyberGhost 1.3.4

###### OpenVPN only image available [here](https://hub.docker.com/r/tmcphee/cyberghost-openvpn) running CyberGhost 1.4.1 

## What is WireGuard?

WireGuard® is an extremely simple yet fast and modern VPN that utilizes state-of-the-art cryptography. It aims to be faster, simpler, leaner, and more useful than IPsec, while avoiding the massive headache. It intends to be considerably more performant than OpenVPN. WireGuard is designed as a general-purpose VPN for running on embedded interfaces and super computers alike, fit for many different circumstances.

## How to use this image
Start the image using optional environment variables shown below. The end-user must supply a volume for local storage of the CyberGhost auth and token files. Supplied DNS is optional to avoid using ISP DNS during the initial connection. Ensure to run the image in privileged mode.
```
docker run 
   -d 
   --name='cyberghostvpn'
   --net='bridge'
   --privileged=true
   --cap-add=NET_ADMIN 
   -e TZ="America/New_York"
   -e 'ACC'='example@gmail.com'
   -e 'PASS'='mypassword'
   -e 'COUNTRY'='US'
   -e 'NETWORK'='192.168.1.0/24'
   -e 'WHITELISTPORTS'='9090,8080'
   -p 9090:9090
   -p 8080:8080
   -v '/local/path/to/config':'/home/root/.cyberghost:rw'
```
OR using Docker Compose
```
version: '3'
services:
  cyberghostvpn:
    image: tmcphee/cyberghostvpn
    container_name: cyberghostvpn
    network_mode: "bridge"
    privileged: true
    cap_add: 
      - NET_ADMIN
    volumes:
      - /local/path/to/config:/home/root/.cyberghost:rw
    environment:
      - TZ=America/New_York
      - ACC=example@gmail.com
      - PASS=mypassword
      - COUNTRY=US
      - NETWORK=192.168.1.0/24
      - WHITELISTPORTS=9090,8080
    ports:
      - 9090:9090
      - 8080:8080
    restart: unless-stopped
```

Other containers can connect to this image by using its network connection.
`--net=container:cyberghostvpn`
```
docker run -d --net=container:cyberghostvpn other-container
```
OR in Docker Compose
`network_mode: container:cyberghostvpn`
```
services:
  other_service:
    image: other_service_image
    container_name: other_service
    network_mode: container:cyberghostvpn
```

If using Docker Compose, place all ports needed from other container into the ports section
```
ports:
  - 9090:9090
  - 8080:8080
  - 6000:6000
  - 6881:6881
```

Note: If the other containers have exposed ports for example a WEBUI. Forward that port in the cyberghostvpn image, add the port to WHITELISTPORTS environment variable, and set your local LAN using NETWORK environment variable. See [Environment variables](https://github.com/tmcphee/cyberghostvpn#environment-variables) below for details. 

## Selecting a country

Add an environment variable called `COUNTRY` and set to the desired country. 
Examples:
- `United States` COUNTRY=US
- `Canada`        COUNTRY=CA

See [CyberGhost selecting a country or single server](https://support.cyberghostvpn.com/hc/en-us/articles/360020673194--How-to-select-a-country-or-single-server-with-CyberGhost-on-Linux) for more details

## Custom DNS / NAMESERVER
Add an environment variable called `NAMESERVER` and set to the desired DNS. 
Examples:
- Cloudflare 1.1.1.1
- Google 8.8.8.8

This image will use CyberGhost Smart DNS if no Nameserver is provided. Automatic Smart DNS for countries US, NL, JP and GB. Default is CloudFlare [1.1.1.1] for all other countries.

## How to login
Login by providing the ACC and PASS environment variables
```
           -e ACC=example@gmail.com
           -e PASS=mypassword
```

## How to access ports locally
Access ports [webUI] by providing the NETWORK and WHITELISTPORTS environment variables. Where NETWORK is the user’s network and WHITELISTPORTS is the ports the user wants to expose. 
```
           -e NETWORK=192.168.1.0/24
           -e WHITELISTPORTS=9090,8080
           -p 9090:9090
           -p 8080:8080
```

## HTTP Proxy Service
Connect devices on the same network with HTTP proxy. Allowing to use the same IP address as the VPN client.
Proxy will disconnect if VPN conection is starting or lost. 
Proxy Port: 3128
```
           -e PROXY=True
           -p 3128:3128
```
Connect devices with the HOST IP and proxy port 3128

## Environment variables

- `NETWORK` - Adds a route to the local network once the VPN is connected. CIDR networks [192.168.1.0/24]
- `WHITELISTPORTS` - Allow access to listed ports when VPN is connected. Delimited by comma [8080,8081,9000]
- `ACC` - CyberGhost username - Used for login
- `PASS` - CyberGhost password - Used for login
- `COUNTRY` - Destination Country - See [CyberGhost Connect to a country](https://support.cyberghostvpn.com/hc/en-us/articles/360020673194--How-to-select-a-country-or-single-server-with-CyberGhost-on-Linux#h_01EJDGC9TZDW38J9FKNFPE6MBE)
- `ARGS` - All additional arguments [Examples: "--torrent" "--traffic" "--streaming 'Netflix US'"]
- `NAMESERVER` - Custom Nameserver/DNS [Examples: Cloudflare 1.1.1.1, Google 8.8.8.8]
- `PROTOCOL` - Choose between WireGuard or OpenVPN [wireguard, openvpn]. Default WireGuard
- `FIREWALL` - Optional disable firewall. [FIREWALL=False]. Default True
- `PROXY` - Optional enable proxy. [PROXY=True]. Default False

## Firewall
This image has a custom built-in firewall. On initial start, all traffic is blocked except CyberGhost API IP and Local DNS for resolve. After VPN is connected Local DNS is blocked on Port 53. For first time use the firewall will go through a setup phase to include whitelisted ports where the firewall will be inactive. 

See the firewall section located in start.sh for details. 

## Troubleshooting

Docker runs, but WireGuard does not connect or gives an error
- Try deleting the config.ini file located in your mapped config folder. This file is the login token for CyberGhost and may be expired. 


## Disclaimer
This project was developed independently for personal use. CyberGhost has no affiliation, nor has control over the content or availability of this project.
