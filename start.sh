#!/bin/bash

	config_ini=/home/root/.cyberghost/config.ini #CyberGhost Auth token

	enable_dns_port () {
		echo "Allowing PORT 53 - IN/OUT"	
		sudo ufw allow out 53 > /dev/null 2>&1 #Allow port 53 on all interface for initial VPN connection
		sudo ufw allow in 53 > /dev/null 2>&1
	}
	
	disable_dns_port () {
		echo "Blocking PORT 53 - IN/OUT"
		sudo ufw delete allow out 53 > /dev/null 2>&1 #Remove Local DNS Port to prevent leaks
		sudo ufw delete allow in 53 > /dev/null 2>&1
	}
	
	startup () {
		echo "CyberGhostVPN - Docker Edition"
		echo "----------------------------------------------------------"
		echo "	Created By: Tyler McPhee"
		echo "	GitHub: https://github.com/tmcphee/cyberghostvpn"
		echo "	DockerHub: https://hub.docker.com/r/tmcphee/cyberghostvpn"
		echo "	"
		echo "	Ubuntu:${linux_version} | CyberGhost:${cyberghost_version} | ${script_version}"
		echo "----------------------------------------------------------"
		
		echo "**************User Defined Variables**************"
		
		if [ -n "$ACC" ]; then
			echo "	ACC: [PASSED - NOT SHOWN]"
		fi
		if [ -n "$PASS" ]; then
			echo "	PASS: [PASSED - NOT SHOWN]"
		fi
		
		if [ -n "$COUNTRY" ]; then
			echo "	COUNTRY: ${COUNTRY}"
		fi
		if [ -n "$NETWORK" ]; then
			echo "	NETWORK: ${NETWORK}"
		fi
		if [ -n "$WHITELISTPORTS" ]; then
			echo "	WHITELISTPORTS: ${WHITELISTPORTS}"
		fi
		if [ -n "$ARGS" ]; then
			echo "	ARGS: ${ARGS}"
		fi
		if [ -n "$NAMESERVER" ]; then
			echo "	NAMESERVER: ${NAMESERVER}"
		fi
		if [ -n "$PROTOCOL" ]; then
			echo "	PROTOCOL: ${PROTOCOL}"
		fi

		echo "**************************************************"
		
	}
	
	ip_stats () {
		str="$(cat /etc/resolv.conf)"
		value=${str#* }
		
		echo "***********CyberGhost Connection Info***********"
		echo "	IP: ""$(curl -s https://ipinfo.io/ip -H "Cache-Control: no-cache, no-store, must-revalidate")"
		echo "	CITY: ""$(curl -s https://ipinfo.io/city -H "Cache-Control: no-cache, no-store, must-revalidate")"
		echo "	REGION: ""$(curl -s https://ipinfo.io/region -H "Cache-Control: no-cache, no-store, must-revalidate")"
		echo "	COUNTRY: ""$(curl -s https://ipinfo.io/country -H "Cache-Control: no-cache, no-store, must-revalidate")"
		echo "	DNS: ${value}"
		echo "************************************************"
	}
	
	#Originated from Run.sh. Migrated for speed improvements
	cyberghost_start () {
		enable_dns_port
		#Check for CyberGhost Auth file
		if [ -f "$config_ini" ]; then
	
			# Check if country is set. Default to US
			if ! [ -n "$COUNTRY" ]; then
				echo "Country variable not set. Defaulting to US"
				export COUNTRY="US"
			fi
				
			# Check if protocol is set. Default WireGuard
			if ! [ -n "$PROTOCOL" ]; then
				export PROTOCOL="wireguard"
			fi
				
			#Launch and connect to CyberGhost VPN
			sudo cyberghostvpn --connect --country-code "$COUNTRY" --"$PROTOCOL" "$ARGS"
			
			# Add CyberGhost nameserver to resolv for DNS
			# Add Nameserver via env variable $NAMESERVER
			if [ -n "$NAMESERVER" ]; then
				echo 'nameserver ' "$NAMESERVER" > /etc/resolv.conf
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
					*) echo 'nameserver 1.1.1.1' > /etc/resolv.conf
					;;
			esac
			fi
		fi
		disable_dns_port
		ip_stats
	}
	
	#Check if the site is reachable
	check_up() {
		ping -c1 "1.1.1.1" > /dev/null 2>&1 #Ping CloudFlare
		if [ $? -eq 0 ]; then
			return 0
		fi
		return 1
	}
	if ! [ -n "$FIREWALL" ]; then
		export FIREWALL="True"
	fi
	
	startup
	
	#Check if CyberGhost CLI is installed. If not install it
	FILE=/usr/local/cyberghost/uninstall.sh
	if [ ! -f "$FILE" ]; then
		echo "CyberGhost CLI not installed. Installing..."
		bash /install.sh
		echo "Installed"
	fi
	
	#Run Firewall if Enabled. Default Enabled
	sysctl -w net.ipv6.conf.all.disable_ipv6=1 #Disable IPV6
	sysctl -w net.ipv6.conf.default.disable_ipv6=1
	sysctl -w net.ipv6.conf.lo.disable_ipv6=1
	sysctl -w net.ipv6.conf.eth0.disable_ipv6=1
	sysctl -w net.ipv4.ip_forward=1
	
	
	if [[ ${FIREWALL,,} == *"true"* ]]; then
		sudo ufw enable #Start Firewall

		FIREWALL_FILE=/.FIREWALL.cg
		if [ ! -f "$FIREWALL_FILE" ]; then
			echo "Initiating Firewall First Time Setup..."
				
			sudo ufw disable #Stop Firewall
			export CYBERGHOST_API_IP=$(getent ahostsv4 v2-api.cyberghostvpn.com | grep STREAM | head -n 1 | cut -d ' ' -f 1)
			sudo ufw default deny outgoing > /dev/null 2>&1							#Deny All traffic by default on all interfaces
			sudo ufw default deny incoming > /dev/null 2>&1
			sudo ufw allow out on cyberghost from any to any > /dev/null 2>&1 		#Allow All over cyberghost interface
			sudo ufw allow in on cyberghost from any to any > /dev/null 2>&1
			sudo ufw allow in 1337 > /dev/null 2>&1 								#Allow port 1337 for CyberGhost Communication
			sudo ufw allow out 1337 > /dev/null 2>&1
			sudo ufw allow in 891 > /dev/null 2>&1 									#Allow port 1194 for CyberGhost OpenVPN Communication
			sudo ufw allow out 819 > /dev/null 2>&1
			sudo ufw allow out from any to "$CYBERGHOST_API_IP" > /dev/null 2>&1 	#Allow v2-api.cyberghostvpn.com [104.20.0.14] IP for connection
			sudo ufw allow in from "$CYBERGHOST_API_IP" to any > /dev/null 2>&1
			
			#Allow all ports in WHITELISTPORTS ENV [Seperate by ',']
			if [ -n "${WHITELISTPORTS}" ]; then
				echo "Setting Whitelisted Ports..."
				IFS=',' read -a array <<< "$WHITELISTPORTS"
				for i in "${array[@]}"
				do
				   echo "Whitelisting Port:" "$i"
				   sudo ufw allow "$i" > /dev/null 2>&1
				done
			fi
			
			sudo ufw enable #Start Firewall
			echo "Firewall Setup Complete"	
			echo 'FIREWALL ACTIVE WHEN FILE EXISTS' > .FIREWALL.cg
		fi
	else
		sudo ufw disable #Stop Firewall
	fi
	
	#Login to account if config not exist
	if [ ! -f "$config_ini" ]; then
		echo "Logging into CyberGhost..."
		
		#Check for CyberGhost Credentials and Login
		if [ -n "$ACC" ] && [ -n "$PASS" ]; then
			enable_dns_port
			expect /auth.sh
			disable_dns_port
		else
			echo "[E1] Can't Login. User didn't provide login credentials. Set the ACC and PASS ENV variables and try again." 
			exit
		fi
	else
		#Verify the config.ini has successfully created the Account and assigned a Device
		echo "Verifying Login Auth..."
		if ! grep -q '[Device]' $config_ini; then
			echo "Failed"
			rm "$config_ini"
			echo "Logging into CyberGhost..."
			enable_dns_port
			expect /auth.sh
			disable_dns_port
		else
			echo "Passed"
		fi
	fi
	
	if [ -n "${NETWORK}" ]; then
		echo "Adding network route..."
		export LOCAL_GATEWAY=$(ip r | awk '/^def/{print $3}') # Get local Gateway
		ip route add "$NETWORK" via "$LOCAL_GATEWAY" dev eth0 #Enable access to local lan
		echo "$NETWORK" "routed to" "$LOCAL_GATEWAY" "on eth0"
	fi
	
	#WIREGUARD START AND WATCH
	cyberghost_start
	t_hr="$(date -u --date="+30 minutes" +%H)" #Next time to check internet is reachable
	t_min="$(date -u --date="+30 minutes" +%M)"
	while true #Watch if Connection is lost then reconnect
	do
		sleep 30
		if [[ $(sudo cyberghostvpn --status | grep 'No VPN connections found.' | wc -l) = "1" ]]; then
			echo '[E2] VPN Connection Lost - Attempting to reconnect....'
			cyberghost_start	
		fi
		
		#Every 30 Minutes ping CloudFlare to check internet reachability 
		if [ "$(date +%H)" = "$t_hr" ] && [ "$(date +%M)" = "$t_min" ]; then
			if ! check_up; then
				echo '[E3] Internet not reachable - Restarting VPN...'
				sudo cyberghostvpn --stop
				cyberghost_start
				t_hr="$(date -u --date="+30 minutes" +%H)" #Next time to check internet is reachable
				t_min="$(date -u --date="+30 minutes" +%M)"
			fi
		fi
	done
	
	echo '[FATAL ERROR] - $?'
	
	
#ERROR CODES
#E1 Can't Login to CyberGhost - Credentials not provided
#E2 VPN Connection Lost
#E3 Internet Connection Lost
	