FROM ubuntu:18.04
MAINTAINER Tyler McPhee

RUN apt-get update -y
RUN apt-get install -y tzdata
RUN apt-get install -y lsb-core \
	sudo \
	wget \
	unzip \
	openresolv \
	iptables \
	net-tools \
	ifupdown \
	iproute2 \
	ufw
RUN apt upgrade -y

#Download and prepare Cyberghost for install
RUN wget https://download.cyberghostvpn.com/linux/cyberghostvpn-ubuntu-18.04-1.3.4.zip -O cyberghostvpn_ubuntu.zip
RUN unzip cyberghostvpn_ubuntu.zip
RUN mv cyberghostvpn-ubuntu-18.04-1.3.4/* .
RUN rm -r cyberghostvpn-ubuntu-18.04-1.3.4
RUN rm cyberghostvpn_ubuntu.zip
RUN sed -i 's/cyberghostvpn --setup/#cyberghostvpn --setup/g' install.sh

#Install Cyberghost
RUN bash install.sh

#Disable IPV6 on ufw
RUN sed -i 's/IPV6=yes/IPV6=no/g' /etc/default/ufw

COPY start.sh .
RUN chmod +x start.sh

COPY run.sh .
RUN chmod +x run.sh

CMD ["bash", "/start.sh"]
