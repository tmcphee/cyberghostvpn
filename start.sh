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
		sudo ufw default deny outgoing #Deny All traffic by default on all interfaces
		sudo ufw default deny incoming
		sudo ufw allow out on cyberghost from any to any #Allow All over cyberghost interface
		sudo ufw allow in on cyberghost from any to any
		sudo ufw allow in 1337 #Allow port 1337 for CyberGhost Communication
		sudo ufw allow out 1337
		sudo ufw allow out 53 #Allow port 53 on all interface for initial VPN connection
		sudo ufw allow in 53
		sudo ufw allow out from any to 104.20.0.14 #Allow v2-api.cyberghostvpn.com [104.20.0.14] IP for connection
		sudo ufw allow in from 104.20.0.14 to any
		
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
		ip route add 10.0.0.0/24 via 172.17.0.1 dev eth0 #Enable access to local lan
		
		echo "Firewall Setup Complete"	
		echo 'FIREWALL ACTIVE WHEN FILE EXISTS' > .FIREWALL.cg
	fi

	
	FILE_RUN=/home/root/.cyberghost/run.sh
	if [ ! -f "$FILE_RUN" ]; then
		cp /run.sh /home/root/.cyberghost/run.sh
	fi
	
	#WIREGUARD START AND WATCH
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
	
	