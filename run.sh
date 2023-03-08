#!/bin/bash
	config_ini=/home/root/.cyberghost/config.ini
	if [ -f "$config_ini" ]; then
		#Launch and connect to CyberGhost VPN [Example]
		sudo cyberghostvpn --connect --country-code $COUNTRY --wireguard $ARGS
		
		# Add CyberGhost nameserver to resolv for DNS
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
			*) echo 'nameserver 99.83.181.72' > /etc/resolv.conf # Default US
			;;
		esac
	fi
	
