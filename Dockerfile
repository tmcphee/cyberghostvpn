FROM ubuntu:18.04
LABEL MAINTAINER="Tyler McPhee"
LABEL CREATOR="Tyler McPhee"
LABEL GITHUB="https://github.com/tmcphee/cyberghostvpn"
LABEL DOCKER="https://hub.docker.com/r/tmcphee/cyberghostvpn"

ENV cyberghost_version=1.3.4
ENV linux_version=18.04

RUN apt update -y
RUN apt upgrade -y
RUN apt dist-upgrade -y
RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC
RUN apt-get install -y tzdata
RUN apt-get install -y lsb-core \
	sudo \
	wget \
	unzip \
	openresolv \
	iproute2 \
	ufw \
	expect

#Download, prepare and instll Cyberghost 
RUN wget https://download.cyberghostvpn.com/linux/cyberghostvpn-ubuntu-$linux_version-$cyberghost_version.zip -O cyberghostvpn_ubuntu.zip && \
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
