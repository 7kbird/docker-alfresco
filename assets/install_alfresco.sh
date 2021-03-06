#!/bin/bash
set -e

# vars
export JAVA_HOME=/usr/java/latest
ALF_HOME=/alfresco
ALF_VERSION=5.0.d
ALF_BUILD=00002
ALF_BIN=alfresco-community-$ALF_VERSION-installer-linux-x64.bin

# Add latest epel-release rpm
cat <<EOM >/etc/yum.repos.d/epel-bootstrap.repo
[epel]
name=Bootstrap EPEL
mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=epel-\$releasever&arch=\$basearch
failovermethod=priority
enabled=0
gpgcheck=0
EOM

yum --enablerepo=epel -y install epel-release
rm -f /etc/yum.repos.d/epel-bootstrap.repo

# satisfy dependencies
yum install -y fontconfig libSM libICE libXrender libXext hostname libXinerama cups-libs dbus-glib
yum install -y supervisor
yum clean all

# get alfresco installer
mkdir -p $ALF_HOME
cd /tmp
wget -nv http://dl.alfresco.com/release/community/$ALF_VERSION-build-$ALF_BUILD/$ALF_BIN
chmod +x $ALF_BIN

# install alfresco
./$ALF_BIN --mode unattended --prefix $ALF_HOME --alfresco_admin_password admin

# get rid of installer - makes image smaller
rm $ALF_BIN

# install fonts for openoffic renders
yum groupinstall -y "Fonts"

# setup supervisor configs
cat > /etc/supervisord.d/alfresco.ini <<EOF
[program:alfresco]
priority=20
directory=/alfresco/tomcat/logs
command=/alfresco/init.sh
user=root
autostart=true
autorestart=true
stdout_logfile=/alfresco/tomcat/logs/catalina_stdout.log
stderr_logfile=/alfresco/tomcat/logs/catalina_stderr.log
EOF
