FROM ubuntu:20.04
LABEL MAINTAINER="Tyler McPhee"
LABEL CREATOR="Tyler McPhee"
LABEL GITHUB="https://github.com/tmcphee/cyberghostvpn"
LABEL DOCKER="https://hub.docker.com/r/tmcphee/cyberghostvpn"

ARG buildtime_script_version

ENV cyberghost_version=1.4.1
ENV linux_version=20.04
ENV script_version=$buildtime_script_version

ARG DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC

#RUN yes | unminimize

RUN apt-get update -y
RUN apt-get install -y \
	sudo \
	wget \
	unzip \
	iproute2 \
	openresolv \
	ufw \
	expect \
	iputils-ping \
	curl \
	lsb-release \
	squid \
	apache2-utils \
	systemctl \
	dos2unix
	
RUN apt-get update -y && \
	apt-get autoremove -y && \
	apt-get autoclean -y
	
#Download, prepare and install CyberGhost CLI [COPY - CACHED VERSION]
RUN wget https://download.cyberghostvpn.com/linux/cyberghostvpn-ubuntu-$linux_version-$cyberghost_version.zip -U="Mozilla/5.0"
# COPY ver/cyberghostvpn-ubuntu-$linux_version-$cyberghost_version.zip ./
RUN mv cyberghostvpn-ubuntu-$linux_version-$cyberghost_version.zip cyberghostvpn_ubuntu.zip && \
	unzip cyberghostvpn_ubuntu.zip && \
	mv cyberghostvpn-ubuntu-$linux_version-$cyberghost_version/* . && \
	rm -r cyberghostvpn-ubuntu-$linux_version-$cyberghost_version  && \
	rm cyberghostvpn_ubuntu.zip && \
	sed -i 's/cyberghostvpn --setup/#cyberghostvpn --setup/g' install.sh && \
	bash install.sh
	
#Setup HTTP Proxy. Allow all connections
RUN sed -i 's/http_access allow localhost/http_access allow all/g' /etc/squid/squid.conf && \
	sed -i 's/http_access deny all/#http_access deny all/g' /etc/squid/squid.conf

#Disable IPV6 on ufw
RUN sed -i 's/IPV6=yes/IPV6=no/g' /etc/default/ufw

COPY start.sh auth.sh ./
RUN dos2unix start.sh auth.sh
RUN chmod +x start.sh && \
	chmod +x auth.sh

CMD ["bash", "/start.sh"]
