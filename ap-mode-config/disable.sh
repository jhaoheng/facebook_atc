#!/bin/bash

# iptables
rm /etc/iptables.ipv4.nat
sudo iptables -F && sudo iptables -F -t nat
sed -i '/iptables-restore/d'  /etc/rc.local

# DHCP Client
sed -i '/interface wlan0/d' /etc/dhcpcd.conf
sed -i '/static ip_address/d' /etc/dhcpcd.conf

# DHCP Server
sed -i '/interface=wlan0/d' /etc/dnsmasq.conf
sed -i '/dhcp-range/d' /etc/dnsmasq.conf
sudo systemctl stop dnsmasq && sudo systemctl disable dnsmasq

# hostapd
sed -i '/hostapd/d'  /etc/rc.local

reboot
