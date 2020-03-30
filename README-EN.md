# CloudFlare DDNS script/Raspberry pi IPV6 DDNS Solution 

### update[ServerChan version](https://github.com/wherelse/cloudFlare-ddns-script/tree/ServerPush)

English | [中文](/README.md)

### Overview
This script is a DDNS script based on the cloudflare API, which supports IPV4 and IPV6. The IP address of the script installation host can be obtained through the network and local methods. Theoretically supports all hosts using the Linux system. It has been tested and available on debian and ubuntu.

### What to do before using a script
1. A liunx device that can be connected to the Internet.
2. Have a domain name.
3. Register a CloudFlare account ( www.cloudflare.com ), add the domain to the account. After the configuration is complete, add an AAAA resolution to the IPV6 address of the service device as required, and set it to perform DNS resolution only.
4. Query the Globe ID of CloudFlare account and record it for subsequent configuration.

### Instructions
Open a terminal window and execute the following procedure:
```shell
wget https://raw.githubusercontent.com/wherelse/cloudflare-ddns-script/master/cloudflare-ddns.sh
sudo chmod +x /home/username/cloudflare-ddns.sh #Directory changes based on actual users, you should change the username.
```
The personal configuration information in the script needs to be changed, and the directory is consistent with the previous command
```shell
sudo nano /home/username/cloudflare-ddns.sh
#or
sudo vi /home/username/cloudflare-ddns.sh
```
Find the following to make changes
```shell
auth_email="xxxxxxx@xxxx.com"  #Your CloudFlare account email
auth_key="*****************"   #Yout cloudflare account Globel ID 
zone_name="Your main Domain"   #Your zone domain name
record_name="Your Full Domain" #Your full record name 

ip_index="local"   #Domain acquisition method, local or network         
#use "internet" or "local",Use local or network to obtain the address
eth_card="eth0"    
#The network card bound when using the local acquisition method, the network method can be used without change.         
#Get the network card bound by ip in local mode, default is eth0, only local mode is effective
```
Take any domain name as an example, the domain name ipv6.google.com, the zone_name is `google.com` and the record_name is` ipv6.google.com`. After modification, save and exit.

Enter the following at the terminal to run the script:
```shell
bash /home/username/cloudflare-ddns.sh
```
If it says `IP changed to: xxxxx` or` IP has not changed.`, the configuration is successful.

#### Schedule script
In order to achieve dynamic domain name resolution, the script must be kept running to obtain the IP status. Here the system crontab is used for timing.
Enter the `crontab -e` at the terminal,Add the following at the end of the file:
```shell
*/5 * * * *  /home/username/cloudflare-ddns.sh >/dev/null 2>&1
```
Save and exit after making changes.Set the script here to execute the `cloudflare-ddns.sh` script every five minutes to achieve dynamic domain name resolution.

### FAQ
When the error log is:
`API UPDATE FAILED. DUMPING RESULTS:`
`{"success":false,"errors":[{"code":7001,"message":"Method PUT not available for that URI."}],"messages":[],"result":null}`
Delete the `cloudflare.ids` file in the script running directory, and then try to run again.
