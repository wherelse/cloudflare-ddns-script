# CloudFlare DDNS script/Raspberry pi IPV6 DDNS Solution 

#### 树莓派IPV6 DDNS解决方案，支持Server酱版本

### 概述
本脚本是基于cloudflare API的DDNS脚本，支持IPV4和IPV6，可通过网络方式和本地方式获取脚本安装主机的IP地址，理论支持所有使用linux系统的主机，已在debian和ubuntu上测试可用。

Server酱是「Server酱」，英文名「ServerChan」，是从服务器推报警和日志到手机的工具，在本脚本中可以推送服务器的IP变动信息，使用前需要在网站使用github登录获得一个SCKEY，网站地址：[Server酱](https://sc.ftqq.com/3.version) 

### 更新[Server酱支持版本](https://github.com/wherelse/cloudflare-ddns-script/tree/ServerPush) 

### 使用脚本前需要做的
1. 一台可联网的liunx设备
2. 拥有一个域名，免费的或者收费的都可以（中国大陆的域名需要备案）
3. 注册一个CloudFlare账户 ( www.cloudflare.com ), 并将需要使用的域名添加到账户上，完成配置后根据需要添加服务设备的IPV6地址添加一个AAAA解析，并设为仅进行DNS解析
4. 查询CloudFlare账户的Globel API Key并记录下来，用于后续配置

### 使用方法
打开命令窗口，执行以下程序：
```shell
wget https://raw.githubusercontent.com/wherelse/cloudflare-ddns-script/ServerPush/cloudflare-ddns.sh
sudo chmod +x /home/pi/cloudflare-ddns.sh #目录根据实际用户等进行更改
```
需要对脚本内的个人配置信息进行更改，目录和上一条命令保持一致
```shell
sudo nano /home/username/cloudflare-ddns.sh
#或
sudo vi /home/username/cloudflare-ddns.sh
```
找到如下内容进行更改
```shell
auth_email="xxxxxxx@xxxx.com"  #你的CloudFlare注册账户邮箱
auth_key="*****************"   #你的cloudflare账户Globel ID 
zone_name="Your main Domain"   #你的域名
record_name="Your Full Domain" #完整域名

ip_index="local"   #域名获取方式，本地或者网络         
#use "internet" or "local",使用本地方式还是网络方式获取地址
eth_card="eth0"    #使用本地获取方式时绑定的网卡，使用网络方式可不更改         
#使用本地方式获取ip绑定的网卡，默认为eth0，仅本地方式有效
```
以任意一个域名为例，ipv6.google.com 这个域名，zone_name为 `google.com` 和record_name则为 `ipv6.google.com` 。然后修改代码中的push函数，填入SCKEY信息，title和content内容可以更改，title为推送的标题，content为推送的内容：

```shell
#server酱推送函数
Pushsend(){
    key=xxxxxxxxxxxxxxxxxxxxxxxx #server酱key
    title=IPV6地址变动
    content=IPV6地址变动到$ip
    curl "http://sc.ftqq.com/$key.send?text=$title&desp=$content" >/dev/null 2>&1 &
}

```

修改完成后，保存并退出。

在命令行中输入以下内容运行脚本：
```shell
bash /home/username/cloudflare-ddns.sh
```
如果提示 `IP changed to: xxxxx` 或 `IP has not changed.` 则说明配置成功了

**定时运行脚本**
为了实现动态域名解析，必须让脚本保持运行以获取IP状态，这里使用系统crontab定时
在命令行输入：`crontab -e` 后在文件最后添加以下内容
```shell
*/5 * * * *  /home/username/cloudflare-ddns.sh >/dev/null 2>&1
```
更改完成后保存并退出。
在这里将脚本设置为每五分钟执行一次 `cloudflare-ddns.sh` 脚本，就可以实现动态域名解析了。

### 结束
该脚本不仅适用于树莓派，在其他Linux服务器上也适用，使用时都需要根据自己的实际情况更改以上配置时使用的路径

### FAQ
错误日志为以下内容时：
`API UPDATE FAILED. DUMPING RESULTS:`
`{"success":false,"errors":[{"code":7001,"message":"Method PUT not available for that URI."}],"messages":[],"result":null}`
删除脚本运行目录下的`cloudflare.ids`文件，然后再次尝试运行。