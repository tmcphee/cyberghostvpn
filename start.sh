#!/bin/bash
	sudo ufw enable #Start Firewall

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
		export LOCAL_GATEWAY=$(ip r | awk '/^def/{print $3}') # Get local Gateway
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
		
		#Login to account if config not exist
		#config_ini=/home/root/.cyberghost/config.ini
		#if [ ! -f "$config_ini" ]; then
		#	(echo "$USER"; echo "$PASS" ) | sudo cyberghostvpn --setup
		#fi
		
		sudo ufw enable #Start Firewall
		if [ -n "${NETWORK}" ]; then
			echo "$NETWORK" "routed to " "$LOCAL_GATEWAY"
			ip route add $NETWORK via $LOCAL_GATEWAY dev eth0 #Enable access to local lan
		fi
		
		echo "Firewall Setup Complete"	
		echo 'FIREWALL ACTIVE WHEN FILE EXISTS' > .FIREWALL.cg
	fi

	
	FILE_RUN=/home/root/.cyberghost/run.sh
	if [ ! -f "$FILE_RUN" ]; then
		cp /run.sh /home/root/.cyberghost/run.sh
	fi
	
	#WIREGUARD START AND WATCH
	sudo ufw allow out 53 #Allow port 53 on all interface for initial VPN connection
	sudo ufw allow in 53
	bash /home/root/.cyberghost/run.sh #Start the CyberGhost run script
	sudo ufw delete allow out 53 #Remove Local DNS Port to prevent leaks
	sudo ufw delete allow in 53
	while true #Watch if Connection is lost then reconnect
	do
		sleep 30
		if [[ $(sudo cyberghostvpn --status | grep 'No VPN connections found.' | wc -l) = "1" ]]; then
			echo 'VPN Connection Lost - Attempting to reconnect....'
		
			sudo ufw allow out 53 #Add Local DNS Port to find VPN Server
			sudo ufw allow in 53
			
			bash /home/root/.cyberghost/run.sh #Start the CyberGhost run script
			
			sudo ufw delete allow out 53 #Remove Local DNS Port to prevent leaks
			sudo ufw delete allow in 53
		fi
	done
	
	