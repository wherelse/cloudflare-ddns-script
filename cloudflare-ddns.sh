#!/bin/bash


# 切换到脚本所在的路径
script_dir=$(cd $(dirname $0);pwd)

# CHANGE THESE
auth_email="xxxxxxx@xxxx.com"  #你的CloudFlare注册账户邮箱,your cloudflare account email address
auth_key="*****************"   #你的cloudflare账户Globel ID ,your cloudflare Globel ID
zone_name="Your main Domain"   #你的域名,your root domain address
record_name="Your Full Domain" #完整域名,your full domain address
record_type="AAAA"             #A or AAAA,ipv4 或 ipv6解析

ip_index="local"            #use "internet" or "local",使用本地方式还是网络方式获取地址
# eth_card="eth0"             #使用本地方式获取ip绑定的网卡，默认为eth0，仅本地方式有效,the default ethernet card is eth0
eth_card="wlp4s0"             #使用本地方式获取ip绑定的网卡，默认为wlp4s0，仅本地方式有效,the default ethernet card is eth0

ip_file=${script_dir}"/""ip.txt"            #保存地址信息,save ip information in the ip.txt
id_file=${script_dir}"/""cloudflare.ids"
log_file=${script_dir}"/""cloudflare.log"


if [ $record_type = "AAAA" ];then
    if [ $ip_index = "internet" ];then
        ip=$(curl -6 ip.sb)
    elif [ $ip_index = "local" ];then
        if [ "$user" = "root" ];then
            ip=$(ifconfig $eth_card | grep 'inet6' | cut -f2 | awk '{ print $2}' |  grep -v '^::1$' | grep -v '^fe80' | grep -v '^f[d|c]' | head -1)
        else
            ip=$(/sbin/ifconfig $eth_card | grep 'inet6' | cut -f2 | awk '{ print $2}' |  grep -v '^::1$' | grep -v '^fe80' | grep -v '^f[d|c]' | head -1)
        fi
    else 
        echo "Error IP index, please input the right type"
        exit 0
    fi
elif [ $record_type = "A" ];then
    if [ $ip_index = "internet" ];then
        ip=$(curl -4 ip.sb)
    elif [ $ip_index = "local" ];then
        if [ "$user" = "root" ];then
            ip=$(ifconfig $eth_card | grep 'inet'| grep -v '127.0.0.1' | grep -v 'inet6'|cut -f2 | awk '{ print $2}')
        else
            ip=$(/sbin/ifconfig $eth_card | grep 'inet'| grep -v '127.0.0.1' | grep -v 'inet6'|cut -f2 | awk '{ print $2}')
        fi
    else 
        echo "Error IP index, please input the right type"
        exit 0
    fi
else
    echo "Error DNS type"
    exit 0
fi

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
    zone_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone_name" \
        -H "X-Auth-Email: $auth_email" \
        -H "X-Auth-Key: $auth_key" \
        -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 )
    record_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?type=${record_type}&name=$record_name" \
        -H "X-Auth-Email: $auth_email" \
        -H "X-Auth-Key: $auth_key" \
        -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*')
    echo "$zone_identifier" > $id_file
    echo "$record_identifier" >> $id_file
fi

#更新DNS记录 update the dns
update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" \
    -H "X-Auth-Email: $auth_email" \
    -H "X-Auth-Key: $auth_key" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"$record_type\",\"name\":\"$record_name\",\"content\":\"$ip\",\"ttl\":1,\"proxied\":false}")


#反馈更新情况 gave the feedback about the update statues
if [[ $update == *"\"success\":true"* ]]; then
    message="IP changed to: $ip"
    echo "$ip" > $ip_file
    log "$message"
    echo "$message"
else
    message="API UPDATE FAILED. DUMPING RESULTS:\n$update"
    log "$message"
    echo -e "$message"
    exit 1
fi
