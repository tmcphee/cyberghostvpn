#!/bin/bash

	config_ini=/home/root/.cyberghost/config.ini #CyberGhost Auth token

	enable_dns_port () {
		echo "Allowing PORT 53 - IN/OUT"	
		sudo ufw allow out 53 #Allow port 53 on all interface for initial VPN connection
		sudo ufw allow in 53
	}
	
	disable_dns_port () {
		echo "Blocking PORT 53 - IN/OUT"
		sudo ufw delete allow out 53 #Remove Local DNS Port to prevent leaks
		sudo ufw delete allow in 53
	}
	
	ip_stats () {
		echo "***********CyberGhost Connection Info***********"
		echo "IP: ""$(curl -s https://ipinfo.io/ip)"
		echo "CITY: ""$(curl -s https://ipinfo.io/city)"
		echo "REGION: ""$(curl -s https://ipinfo.io/region)"
		echo "COUNTRY: ""$(curl -s https://ipinfo.io/country)"
		
		str="$(cat /etc/resolv.conf)"
		value=${str#* }
		echo "DNS: "$value
		echo "************************************************"
	}
	
	#Originated from Run.sh. Migrated for speed improvements
	cyberghost_start () {
		#Check for CyberGhost Auth file
		if [ -f "$config_ini" ]; then
	
			# Check if country is set. Default to US
			if ! [ -n "$COUNTRY" ]; then
				echo "Country variable not set. Defaulting to US"
				export COUNTRY="US"
			fi
				
			#Launch and connect to CyberGhost VPN
			sudo cyberghostvpn --connect --country-code $COUNTRY --wireguard $ARGS
			
			# Add CyberGhost nameserver to resolv for DNS
			# Add Nameserver via env variable $NAMESERVER
			if [ -n "$NAMESERVER" ]; then
				echo 'nameserver ' $NAMESERVER > /etc/resolv.conf
			else
				# SMART DNS
				# This will switch baised on country selected
				# https://support.cyberghostvpn.com/hc/en-us/articles/360012002360
				case "$COUNTRY" in
					"NL") echo 'nameserver 75.2.43.210' > /etc/resolv.conf
					;;
					"GB") echo 'nameserver 75.2.79.213' > /etc/resolv.conf
					;;
					"JP") echo 'nameserver 76.223.64.81' > /etc/resolv.conf
					;;
					"DE") echo 'nameserver 13.248.182.241' > /etc/resolv.conf
					;;
					"US") echo 'nameserver 99.83.181.72' > /etc/resolv.conf
					;;
					*) echo 'nameserver 99.83.181.72' > /etc/resolv.conf
					;;
			esac
			fi
		fi
	}
	
	sudo ufw enable #Start Firewall

	#Check if CyberGhost CLI is installed. If not install it
	FILE=/usr/local/cyberghost/uninstall.sh
	if [ ! -f "$FILE" ]; then
		echo "CyberGhost CLI not installed. Installing..."
		bash /install.sh
		echo "Installed"
	fi
	
	FIREWALL_FILE=/.FIREWALL.cg
	if [ ! -f "$FIREWALL_FILE" ]; then
		echo "Initiating Firewall First Time Setup..."
		
		sysctl -w net.ipv6.conf.all.disable_ipv6=1 #Disable IPV6
		sysctl -w net.ipv6.conf.default.disable_ipv6=1
		sysctl -w net.ipv6.conf.lo.disable_ipv6=1
		sysctl -w net.ipv6.conf.eth0.disable_ipv6=1
		sysctl -w net.ipv4.ip_forward=1
			
		sudo ufw disable #Stop Firewall
		export CYBERGHOST_API_IP=$(getent ahostsv4 v2-api.cyberghostvpn.com | grep STREAM | head -n 1 | cut -d ' ' -f 1)
		sudo ufw default deny outgoing #Deny All traffic by default on all interfaces
		sudo ufw default deny incoming
		sudo ufw allow out on cyberghost from any to any #Allow All over cyberghost interface
		sudo ufw allow in on cyberghost from any to any
		sudo ufw allow in 1337 #Allow port 1337 for CyberGhost Communication
		sudo ufw allow out 1337
		sudo ufw allow out from any to "$CYBERGHOST_API_IP" #Allow v2-api.cyberghostvpn.com [104.20.0.14] IP for connection
		sudo ufw allow in from "$CYBERGHOST_API_IP" to any
		
		#Allow all ports in WHITELISTPORTS ENV [Seperate by ',']
		if [ -n "${WHITELISTPORTS}" ]; then
			echo "Setting Whitelisted Ports..."
			IFS=',' read -a array <<< "$WHITELISTPORTS"
			for i in "${array[@]}"
			do
			   echo "Whitelisting Port:" "$i"
			   sudo ufw allow "$i"
			done
		fi
		
		sudo ufw enable #Start Firewall
		echo "Firewall Setup Complete"	
		echo 'FIREWALL ACTIVE WHEN FILE EXISTS' > .FIREWALL.cg
	fi
	
	#Login to account if config not exist
	if [ ! -f "$config_ini" ]; then
		echo "Logging into CyberGhost..."
		enable_dns_port
		expect /auth.sh
		disable_dns_port
	fi
	
	if [ -n "${NETWORK}" ]; then
		echo "Adding network route..."
		export LOCAL_GATEWAY=$(ip r | awk '/^def/{print $3}') # Get local Gateway
		ip route add $NETWORK via $LOCAL_GATEWAY dev eth0 #Enable access to local lan
		echo "$NETWORK" "routed to " "$LOCAL_GATEWAY" " on eth0"
	fi
	
	#WIREGUARD START AND WATCH
	enable_dns_port
	cyberghost_start
	disable_dns_port
	ip_stats
	while true #Watch if Connection is lost then reconnect
	do
		sleep 30
		if [[ $(sudo cyberghostvpn --status | grep 'No VPN connections found.' | wc -l) = "1" ]]; then
			echo 'VPN Connection Lost - Attempting to reconnect....'
		
			enable_dns_port
			cyberghost_start	
			disable_dns_port
			
			ip_stats
		fi
	done
	
	
