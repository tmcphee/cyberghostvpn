FROM ubuntu:20.04
LABEL MAINTAINER="Tyler McPhee"
LABEL CREATOR="Tyler McPhee"
LABEL GITHUB="https://github.com/tmcphee/cyberghostvpn"
LABEL DOCKER="https://hub.docker.com/r/tmcphee/cyberghostvpn"

ARG buildtime_script_version

ENV cyberghost_version=1.3.4
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
	lsb-release
	
RUN apt-get update -y && \
	apt-get autoremove -y && \
	apt-get autoclean -y
	
#Download, prepare and install CyberGhost CLI [COPY - CACHED VERSION]
#RUN wget https://download.cyberghostvpn.com/linux/cyberghostvpn-ubuntu-$linux_version-$cyberghost_version.zip -O cyberghostvpn_ubuntu.zip -U="Mozilla/5.0" && \
COPY ver/cyberghostvpn-ubuntu-$linux_version-$cyberghost_version.zip ./
RUN mv cyberghostvpn-ubuntu-$linux_version-$cyberghost_version.zip cyberghostvpn_ubuntu.zip && \
	unzip cyberghostvpn_ubuntu.zip && \
	mv cyberghostvpn-ubuntu-$linux_version-$cyberghost_version/* . && \
	rm -r cyberghostvpn-ubuntu-$linux_version-$cyberghost_version  && \
	rm cyberghostvpn_ubuntu.zip && \
	sed -i 's/cyberghostvpn --setup/#cyberghostvpn --setup/g' install.sh && \
	bash install.sh
	

#Disable IPV6 on ufw
RUN sed -i 's/IPV6=yes/IPV6=no/g' /etc/default/ufw

COPY start.sh auth.sh ./
RUN chmod +x start.sh && \
	chmod +x auth.sh

CMD ["bash", "/start.sh"]
