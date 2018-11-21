#!/bin/bash
#       ____  __  ______________
#      / __ \/ / / /  _/ ___/__ \
#     / / / / /_/ // / \__ \__/ /
#    / /_/ / __  // / ___/ / __/
#   /_____/_/ /_/___//____/____/
#
#   Installation stackscript
#


MYUSER='dhis'
SSH='ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEA3bJZB6JYOToA77zNGBVgVKqH8zcGi+RsW0yt5tLf0NqQm+LnQpsF5Av7WjqMp4S+voOTqA8ATEzStEvv9SHAOM4TUiczFY5T3PrgMhCxjCfUVpFE9P6Fr+9Q1iAZvAdJDWXXcgt1dOoURktiy8Tmyu3YDyQOsKBSjYYhPLxSxErUm5sTpmDmi7D2yLB3KpuIBkRyv5uECQlxmZLInfi54uIPy8nyLMD8BNhyeKu2dIXSzimJbz5c9Kv0wCGMSa9GYx1x6uaeOGQRPVmMWOYkCPa0DTykjTJLTzY7F96L9jvjbB3DAL2PAHRFxIXtyBFjPigFjM2DPUmTTF44jQ9eQQ imported-openssh-key'
SSHPORT='22'
HOSTNAME='snigs'
FQDN='snigs.gouv.bj'

# enable firewall
ufw enable

# prefer ipv4 addresses - this solves long delays with apt-get
echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf

# This updates the packages on the system from the distribution repositories.
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y


# This sets the variable $IPADDR to the IP address the new Linode receives.
IPADDR=$(/sbin/ifconfig eth0 | awk '/inet / { print $2 }' | sed 's/addr://')

# This section sets the hostname.
echo $HOSTNAME > /etc/hostname
hostname -F /etc/hostname

# This section sets the Fully Qualified Domain Name (FQDN) in the hosts file.
echo $IPADDR $FQDN $HOSTNAME >> /etc/hosts

# Create administrative user
useradd -m -G sudo -s /bin/bash ${MYUSER}

# Perform tasks for new user
# set a temporary password
echo $(</dev/urandom tr -dc A-Za-z0-9 | head -c 10) > /home/$MYUSER/passwd.txt
chmod 600 /home/$MYUSER/passwd.txt
echo "${MYUSER}:$(cat /home/${MYUSER}/passwd.txt)" | chpasswd

# This sets your public key on your Linode
mkdir /home/$MYUSER/.ssh
echo "${SSH}" >> /home/$MYUSER/.ssh/authorized_keys
chmod 600 /home/$MYUSER/.ssh/authorized_keys

# make sure user owns everything
chown -R $MYUSER.$MYUSER /home/$MYUSER

# Tighten up ssh
# Disables password authentication
#BEN sed -i 's/#*PasswordAuthentication [a-zA-Z]*/PasswordAuthentication no/' /etc/ssh/sshd_config
# Disable root login
sed -i 's/PermitRootLogin [a-zA-Z]*/PermitRootLogin no/' /etc/ssh/sshd_config
# Change Port
sed -i "s/#*Port [0-9]*/Port $SSHPORT/" /etc/ssh/sshd_config
# This restarts the SSH service
service ssh restart

# Allow ssh through firewall
ufw limit $SSHPORT/tcp

# Starting DHIS2 install

#add PPA
apt-get install -y software-properties-common
add-apt-repository -y ppa:bobjolliffe/dhis2-tools
add-apt-repository -y ppa:webupd8team/java
add-apt-repository -y ppa:certbot/certbot
apt-get -y update

#accept oracle license
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections

#install java8 and dhis2-tools
apt-get -y install oracle-java8-installer
apt-get -y install dhis2-tools

#apt-get -y install postgresql postgis apache2
apt-get -y install postgresql apache2
apt install postgresql-10-postgis-2.4
apt install postgresql-10-postgis-2.4-scripts

apt-get -y install python-certbot-apache

a2enmod ssl cache rewrite proxy_http headers
