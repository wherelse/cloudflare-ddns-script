#!/bin/bash

# CHANGE THESE
auth_email="xxxxxxx@xxxx.com"  #你的CloudFlare注册账户邮箱,your cloudflare email address
auth_key="*****************"   #你的cloudflare账户Globel ID ,your cloudflare Globel ID
zone_name="Your main Domain"   #你的域名,your root domain address
record_name="Your Full Domain" #完整域名,your full domain address
record_type="AAAA"             #A or AAAA,ipv4 或 ipv6解析

#选择合适的ip获取方式， select the correct get ip method
ip=$(curl -6 ip.sb)     #通过网络获取ipv6地址,get ipv6 address through the internet
#ip=$(ifconfig | grep 'inet6'| grep -v '::1'|grep -v 'fe80' | cut -f2 | awk '{ print $2}') #通过本地获取ipv6地址,get ipv6 address through the local terminal
#ip=$(curl -4 ip.sb)    #通过网络获取ipv4地址，get ipv4 address through the internet
#ip=$(ifconfig | grep 'inet'| grep -v '127.0.0.1' | grep -v ':'|cut -f2 | awk '{ print $2}') #通过本地获取ipv4地址,get ipv4 address through the local terminal
ip_file="ip.txt"        #保存地址信息,save ip information in the ip.txt
id_file="cloudflare.ids"
log_file="cloudflare.log"

# 日志 log file
log() {
    if [ "$1" ]; then
        echo -e "[$(date)] - $1" >> $log_file
    fi
}

# SCRIPT START
log "Check Initiated"

#判断ip是否发生变化,check the ip had been changed?
if [ -f $ip_file ]; then
    old_ip=$(cat $ip_file)
    if [ $ip == $old_ip ]; then
        echo "IP has not changed."
        exit 0
    fi
fi

#获取域名和授权 get the domain and authentic
if [ -f $id_file ] && [ $(wc -l $id_file | cut -d " " -f 1) == 2 ]; then
    zone_identifier=$(head -1 $id_file)
    record_identifier=$(tail -1 $id_file)
else
    zone_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone_name" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 )
    record_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$record_name" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*')
    echo "$zone_identifier" > $id_file
    echo "$record_identifier" >> $id_file
fi

#更新DNS记录 update the dns
update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" --data "{\"id\":\"$zone_identifier\",\"type\":\"$record_type\",\"name\":\"$record_name\",\"content\":\"$ip\"}")


#反馈更新情况 gave the feedback about the update statues
if [[ $update == *"\"success\":false"* ]]; then
    message="API UPDATE FAILED. DUMPING RESULTS:\n$update"
    log "$message"
    echo -e "$message"
    exit 1 
else
    message="IP changed to: $ip"
    echo "$ip" > $ip_file
    log "$message"
    echo "$message"
fi
