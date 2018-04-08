#!/bin/bash

# NAT : iptable
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sudo iptables -F && sudo iptables -F -t nat
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT
sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"
sed -i '$ i sudo iptables-restore < /etc/iptables.ipv4.nat' /etc/rc.local # daemon


# DHCP Client
echo "interface wlan0" >> /etc/dhcpcd.conf
echo "static ip_address=10.0.7.1/24" >> /etc/dhcpcd.conf


# DHCP Server
sudo apt-get -y install dnsmasq
echo "interface=wlan0" >> /etc/dnsmasq.conf
echo "dhcp-range=10.0.7.101,10.0.7.200,255.255.255.0,12h" >> /etc/dnsmasq.conf
sudo systemctl restart dnsmasq && sudo systemctl enable dnsmasq


# hostapd
sudo apt-get install hostapd -y
mv ./hostapd.conf /etc/hostapd/hostapd.conf
sed -i '$ i sudo hostapd -B /etc/hostapd/hostapd.conf' /etc/rc.local # daemon

sudo reboot