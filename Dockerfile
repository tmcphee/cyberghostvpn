FROM ubuntu:18.04
MAINTAINER Tyler McPhee

RUN apt update -y
RUN apt upgrade -y
RUN apt dist-upgrade -y
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
	ufw \
	expect

#Download, prepare and instll Cyberghost 
RUN wget https://download.cyberghostvpn.com/linux/cyberghostvpn-ubuntu-18.04-1.3.4.zip -O cyberghostvpn_ubuntu.zip && \
	unzip cyberghostvpn_ubuntu.zip && \
	mv cyberghostvpn-ubuntu-18.04-1.3.4/* . && \
	rm -r cyberghostvpn-ubuntu-18.04-1.3.4  && \
	rm cyberghostvpn_ubuntu.zip && \
	sed -i 's/cyberghostvpn --setup/#cyberghostvpn --setup/g' install.sh && \
	bash install.sh

#Disable IPV6 on ufw
RUN sed -i 's/IPV6=yes/IPV6=no/g' /etc/default/ufw

COPY start.sh .
RUN chmod +x start.sh

COPY auth.sh .
RUN chmod +x auth.sh

CMD ["bash", "/start.sh"]
