# Raspberry pi IPV6 DDNS Solution / CloudFlare DDNS script

#### 树莓派IPV6 DDNS解决方案/cloudflare ddns 脚本

## 更新[Server酱支持版本](https://github.com/wherelse/Raspberrypi-IPV6-DDNS-Solution/tree/ServerPush) 

### 更新日志：V1.1

添加使用本地方式获取IPV4和IPV6地址，使用时根据需要注释使用，可能需要更改绑定网卡，并在crontab运行时使用sudo命令。
例如在使用PPPOE拨号获取地址时:
```shell
sudo ifconfig eth0 | grep 'inet6'| grep -v '::1'|grep -v 'fe80' | cut -f2 | awk '{ print $2}')
#更改为
sudo ifconfig ppp0 | grep 'inet6'| grep -v '::1'|grep -v 'fe80' | cut -f2 | awk '{ print $2}')
```
在`crontab -e`中，更改为：
```shell
*/5 * * * *  sudo /home/pi/CloudFlare-ddns.sh >/dev/null 2>&1
```

### 背景
随着IPV6的逐渐普及，国内各个地方的宽带都开始分配IPV6地址，不同于IPV4很多分配内网地址的情况，IPV6一般分配的都是公网地址，这就为树莓派以及类似这样的设备联网提供了很大的方便。不过，分配的IP地址一般都会以一定的周期变动，一般是一天左右。

IPV6地址又相当的长，通过输入访问变得难以实现，这个时候在树莓派上搭建一个动态域名解析服务（DDNS）就很有必要。在这里我们使用CloudFlare的API接口来实现动态域名解析

### 使用脚本前需要做的
1. 一台可以联网的树莓派设备（其他Linux系统设备也是可以的）
2. 注册一个域名，免费的或者收费的都可以（国内的域名需要备案）
3. 注册一个CloudFlare账户 ( www.cloudflare.com ), 并将需要使用的域名添加到账户上，完成配置后根据需要添加服务设备的IPV6地址添加一个AAAA解析，并设为仅进行DNS解析
4. 查询CloudFlare账户的Globel ID并记录下来，用于后续配置

### 使用方法
打开命令窗口，执行以下程序：
```shell
wget https://raw.githubusercontent.com/wherelse/Raspberrypi-IPV6-DDNS-Solution/master/CloudFlare-ddns.sh
sudo chmod +x /home/pi/CloudFlare-ddns.sh #目录根据实际用户等进行更改
```
需要对脚本内的个人配置信息进行更改，目录和上一条命令保持一致
```shell
sudo nano /home/pi/CloudFlare-ddns.sh
#或
sudo vi /home/pi/CloudFlare-ddns.sh
```
找到如下内容进行更改
```shell
auth_email="xxxxxxx@xxxx.com"  #你的CloudFlare注册账户邮箱
auth_key="*****************"   #你的cloudflare账户Globel ID 
zone_name="Your main Domain"   #你的域名
record_name="Your Full Domain" #完整域名
```
以任意一个域名为例，ipv6.google.com 这个域名，zone_name为 `google.com` 和record_name则为 `ipv6.google.com` ，修改完成后，保存并退出。

在命令行中输入以下内容运行脚本：
```shell
bash /home/pi/CloudFlare-ddns.sh
```
如果提示 `IP changed to: xxxxx` 或 `IP has not changed.` 则说明配置成功了

**定时运行脚本**
为了实现动态域名解析，必须让脚本保持运行以获取IP状态，这里使用系统crontab定时
在命令行输入：`crontab -e` 后在文件最后添加以下内容
```shell
*/5 * * * *  /home/pi/CloudFlare-ddns.sh >/dev/null 2>&1
```
更改完成后保存并退出。
在这里将脚本设置为每五分钟执行一次 `CloudFlare-ddns.sh` 脚本，就可以实现动态域名解析了。

### 结束
该脚本不仅适用于树莓派，在其他Linux服务器上也适用，使用时都需要根据自己的实际情况更改以上配置时使用的路径

### FAQ
错误日志为以下内容时：
`API UPDATE FAILED. DUMPING RESULTS:`
`{"success":false,"errors":[{"code":7001,"message":"Method PUT not available for that URI."}],"messages":[],"result":null}`
删除脚本运行目录下的`cloudflare.ids`文件，然后再次尝试运行。