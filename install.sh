#!/bin/bash
#
# This script is meant to setup a fresh RockyLinux install
# with apache's httpd behind an nginx reverse proxy as well as
# supervisord. By default httpd will listen on port 8080 and
# nginx will route everything on port 80 to 8080.
#
# It will also install php and vim as well as python3
#


#
# VARIABLES
# colors
RED='\033[0;31m'
NC='\033[0m' # No Color

# paths
HTTPD_CONF=/etc/httpd/conf/httpd.conf
PROXY_PARAMS=/etc/nginx/proxy_params
APACHE_CONF=/etc/nginx/conf.d/apache.conf
NGINX_CONF=/etc/nginx/nginx.conf


#
# BASIC SETUP
echo "Updating packages (dnf upgrade)"
dnf upgrade -y

echo "Enable EPEL (Extra Packages for Enterprise Linux)"
dnf install epel-release -y

echo "Install wget, vim, php and python39"
dnf install wget vim php python39 -y
alternatives --set python /usr/bin/python3


#
# INSTALL APACHE
echo "Install Apache's httpd and php"
dnf install httpd -y

echo "Set Apache's httpd port from 80 to 8080"
sed 's/Listen 80/Listen 8080/g' -i $HTTPD_CONF

echo "Enable Apaches' httpd"
systemctl enable --now httpd


#
# INSTALL NGINX
echo "Install nginx"
dnf install nginx -y

echo "Remove PHP from being handled by nginx"
mv /etc/nginx/conf.d/php-fpm.conf /etc/nginx/conf.d/php-fpm._conf

echo "Configure nginx"

# add proxy_params file
curl https://raw.githubusercontent.com/bliepp/burst/main/config/nginx/proxy_params > $PROXY_PARAMS

# add apache config to nginx
curl https://raw.githubusercontent.com/bliepp/burst/main/config/nginx/apache.conf > $APACHE_CONF

# backup and overwrite nginx config
mv $NGINX_CONF $NGINX_CONF\_old
curl https://raw.githubusercontent.com/bliepp/burst/main/config/nginx/nginx.conf > $NGINX_CONF

# enable nginx
systemctl enable --now nginx


#
# ALLOW NGINX REVERSE PROXY TO ACCESS SERVICES
echo "Set nginx permissions"
setsebool -P httpd_can_network_relay 1


#
# INSTALL SUPERVISOR
echo "Install and enable supervisord"
dnf install supervisor -y
systemctl enable --now supervisord


#
# FINISH
# further instructions
#echo -e "${RED}Please remove the default server block manually and then activate nginx:${NC}"
#echo -e "${RED}  > vim /etc/nginx/nginx.conf${NC}"
#echo -e "${RED}  > systemctl enable --now nginx${NC}"
