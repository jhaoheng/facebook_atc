# 自動設定
1. 設定 ap-mode : `enable.sh`
2. 取消 ap-mode : `disable.sh`

-- 以下為手動設定 --

# 將 wifi 設定成 AP MODE

## 啟用 NAT
> 目的 : 透過 iptable 的設定，交換 wifi ap(wlan0) 與 eth0 的網路資訊

1. 開啟 ipv4 路由轉發功能，檔案位置 `/etc/sysctl.conf`
   - 查詢 : `cat /etc/sysctl.conf | grep ip_forward`
   - 變更設定 : 
      - 至 `/etc/sysctl.conf`，找到 `net.ipv4.ip_forward` 並設定為 1
      - 或透過指令變更 : `sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf`
2. 更新 iptable，將內部的 wlan0 封包轉給 eth0，詳細原理可參考 : `http://web.mit.edu/rhel-doc/4/RH-DOCS/rhel-sg-zh_tw-4/s1-firewall-ipt-fwd.html`
   1. 清除設定
      - `sudo iptables -F && sudo iptables -F -t nat`
   2. 設定 NAT
      - 要讓使用私有 IP 的電腦與外部公眾網路連線，需設定防火牆為 IP 偽裝（IP masquerading），把來自區網內部交通的位址，換成防火牆的外部 IP 位址（此例為 eth0）
          - `sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE`
          - 查看設定 : `sudo iptables -t nat -S`
      - FORWARD 政策允許系統管理員控制封包在區網內部的傳送, 送給誰, 誰接收
          - `sudo iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT`
          - `sudo iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT`
          - 查看設定 : 
              - `sudo iptables -S`
              - `sudo iptables -L`
3. 儲存設定，讓每次網路啟動都使用此設定
   1. `sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"`
   2. `vim /etc/rc.local`
      - 在 `exit 0` 之前，加入`sudo iptables-restore < /etc/iptables.ipv4.nat`


## 設定 DHCP client
> 目的 : 接收用戶端連線，設定 raspberry wifi gateway 的位置

1. 編輯 DHCP Client 設定資訊 : `vim /etc/dhcpcd.conf`
2. 在最下方，新增
   1. `interface  wlan0`
   2. `static ip_address=10.0.7.1/24` : 指定 wlan0 的 ip 位置

## 架設 DHCP Server
1. `sudo apt-get -y install dnsmasq`
2. `sudo vim /etc/dnsmasq.conf`，在最下方編輯
```
interface=wlan0
dhcp-range=10.0.7.101,10.0.7.200,255.255.255.0,12h
```
3. 重新啟動 dnsmasq : `sudo systemctl restart dnsmasq && sudo systemctl enable dnsmasq`

## 設定 hostapd

1. `sudo apt-get install hostapd -y`
2. `gunzip -c /usr/share/doc/hostapd/examples/hostapd.conf.gz > /etc/hostapd/hostapd.conf`
3. 編輯 hostapd.conf
  1. `interface=wlan0`
  2. `driver=nl80211`
  3. `ssid=RPI-AP`
  4. `hw_mode=g`
  5. `channel=11`
  6. `macaddr_acl=0`
  7. `auth_algs=1`
  8. `ignore_broadcast_ssid=0`
  9. `wpa=2`
  10. `wpa_passphrase=12345678` : 設定無線網路密碼
  11. `wpa_key_mgmt=WPA-PSK`
  13. `rsn_pairwise=CCMP`
  
### 測試 ap
1. 測試 : `sudo hostapd -dd /etc/hostapd/hostapd.conf`
    - 測試時，可以透過其他裝置，並連接上 wifi ap
    - 如果連接得上，但沒有辦法看網頁，為 iptables 設定錯誤，請檢查你的 iptables

### run hostapd in daemon
1. `vim /etc/rc.local`
2. 加入 : `sudo hostapd -B /etc/hostapd/hostapd.conf`

# troubleshooting

1. 找不到 ssid
   - 請重新啟動 hostapd
2. 連上 ssid，卻無法連到外部網路
   - 請檢查 iptables

## 檢查錯誤訊息
- `/var/log/syslog`

## 如何關閉 wifi ap
- 停掉 hostapd 服務即可 : `sudo systemctl hostapd stop`
