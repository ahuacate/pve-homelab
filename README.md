# Proxmox-LXC-Homelab
The following is for creating our Homelab LXC containers.

Network Prerequisites are:
- [x] Layer 2 Network Switches
- [x] Network Gateway is `192.168.1.5`
- [x] Network DNS server is `192.168.1.5` (Note: your Gateway hardware should enable you to a configure DNS server(s), like a UniFi USG Gateway, so set the following: primary DNS `192.168.1.254` which will be your PiHole server IP address; and, secondary DNS `1.1.1.1` which is a backup Cloudfare DNS server in the event your PiHole server 192.168.1.254 fails or os down)
- [x] Network DHCP server is `192.168.1.5`
- [x] A DDNS service is fully configured and enabled (I recommend you use the free Synology DDNS service)
- [x] A ExpressVPN account (or any preferred VPN provider) is valid and its smart DNS feature is working (public IP registration is working with your DDNS provider)

Other Prerequisites are:
- [x] Synology NAS, or linux variant of a NAS, is fully configured as per [SYNOBUILD](https://github.com/ahuacate/synobuild#synobuild)
- [x] Proxmox node fully configured as per [PROXMOX-NODE BUILDING](https://github.com/ahuacate/proxmox-node/blob/master/README.md#proxmox-node-building)
- [x] pfSense is fully configured on typhoon-01 including both OpenVPN Gateways VPNGATE-LOCAL and VPNGATE-WORLD.

Tasks to be performed are:
- [ ] 1.00 PiHole LXC - CentOS7
- [ ] 2.00 UniFi Controller - CentOS7
- [ ] 3.00 NextCloud LXC - Turnkey Debian

## About LXC Homelab Installations
This page is about installing Proxmox LXC's and VM's for your homelab network. Software tools like PiHole, cloud storage and stuff.

Proxmox itself ships with a set of basic templates and to download a prebuilt OS distribution use the graphical interface `typhoon-01` > `local` > `content` > `templates` and select and download the following templates:
*  `centos-7-default`;
*  `ubuntu-18.04-standard`; *and,*
*  `turnkey-nextcloud`.

## 1.00 Unprivileged LXC Containers and file permissions
With unprivileged LXC containers you will have issues with UIDs (user id) and GIDs (group id) permissions with bind mounted shared data. All of the UIDs and GIDs are mapped to a different number range than on the host machine, usually root (uid 0) became uid 100000, 1 will be 100001 and so on.

However you will soon realise that every file and directory will be mapped to "nobody" (uid 65534). This isn't acceptable for host mounted shared data resources. For shared data you want to access the directory with the same - unprivileged - uid as it's using on other LXC machines.

The fix is to change the UID and GID mapping.

So like our [Proxmox Media LXC builds](https://github.com/ahuacate/proxmox-lxc-media#proxmox-lxc-media) where we created a new user/group called `media` and made uid 1005 and gid 1005 accessible to unprivileged LXC containers, we need to do much the same but with UID's 0 (root) and 33 (www-data) AND GID's 0 (root) and 33 (www-data) on some LXC's like Nextcloud. This is achieved in three parts during the course of creating your new media LXC's.

### 1.01 Unprivileged container mapping
To change a container mapping we change the container UID and GID in the file `/etc/pve/lxc/container-id.conf` after you create a new container. Simply use Proxmox CLI `typhoon-01` >  `>_ Shell` and type the following:
```
echo -e "lxc.idmap: u 1 100000 32
lxc.idmap: g 1 100000 32
lxc.idmap: u 0 0 1
lxc.idmap: g 0 0 1
lxc.idmap: u 33 33 1
lxc.idmap: g 33 33 1
lxc.idmap: u 34 100034 65502
lxc.idmap: g 34 100034 65502" >> /etc/pve/lxc/container-id.conf
```
The above example is for Nextcloud.

### 1.02 Allow a LXC to perform mapping on the Proxmox host
Next we have to allow LXC to actually do the mapping on the host. Since LXC creates the container using root, we have to allow root to use these new uids in the container.

To achieve this we need to **add** the line `root:0:1` and `root:33:1` to the files `/etc/subuid` and `/etc/subgid`. Simply use Proxmox CLI `typhoon-01` >  `>_ Shell` and type the following (NOTE: Only needs to be performed ONCE on each host (i.e typhoon-01/02/03)):
```
echo -e "root:33:1" >> /etc/subuid &&
echo -e "root:0:1" >> /etc/subuid
```
Then we need to also **add** the line `root:0:1` and `root:33:1` to the file `/etc/subgid`. Simply use Proxmox CLI `typhoon-01` >  `>_ Shell` and type the following:
```
echo -e "root:33:1" >> /etc/subgid &&
echo -e "root:0:1" >> /etc/subgid
```
Note, we **add** these lines not replace any default lines. My /etc/subuid and /etc/subgid both look identical:
```
root:1005:1 # media userID
root:100000:65536
root:33:1 # www-data userID
root:0:1 # root userID
```

## 2.00 PiHole LXC - CentOS7
Here we are going install PiHole which is a internet tracker blocking application which acts as a DNS sinkhole. Basically its charter is to block advertisments, tracking domains, tracking cookies and all those personal data mining collection companies.

### 2.01 Create a CentOS7 LXC for PiHole - CentOS7
Now using the web interface `Datacenter` > `Create CT` and fill out the details as shown below (whats not shown below leave as default):

| Create: LXC Container | Value |
| :---  | :---: |
| **General**
| Node | `typhoon-01` |
| CT ID |`254`|
| Hostname |`pihole`|
| Unprivileged container | `☑` |
| Resource Pool | Leave Blank
| Password | Enter your pasword
| Password | Enter your pasword
| SSH Public key | Add one if you want to
| **Template**
| Storage | `local` |
| Template |`centos-7-default_xxxx_amd`|
| **Root Disk**
| Storage |`typhoon-share`|
| Disk Size |`8 GiB`|
| **CPU**
| Cores |`1`|
| CPU limit | Leave Blank
| CPU Units | `1024`
| **Memory**
| Memory (MiB) |`256`|
| Swap (MiB) |`256`|
| **Network**
| Name | `eth0`
| Mac Address | `auto`
| Bridge | `vmbr0`
| VLAN Tag | Leave Blank
| Rate limit (MN/s) | Leave Default (unlimited)
| Firewall | `☑`
| IPv4 | `☑  Static`
| IPv4/CIDR |`192.168.1.254/24`|
| Gateway (IPv4) |`192.168.1.5`|
| IPv6 | Leave Blank
| IPv4/CIDR | Leave Blank |
| Gateway (IPv6) | Leave Blank |
| **DNS**
| DNS domain | Leave Default (use host settings)
| DNS servers | Leave Default (use host settings)
| **Confirm**
| Start after Created | `☑`

And Click `Finish` to create your PiHole LXC.

Or if you prefer you can simply use Proxmox CLI `typhoon-01` >  `>_ Shell` and type the following to achieve the same thing (note, you will need to create a password for PiHole LXC):
```
pct create 254 local:vztmpl/centos-7-default_20171212_amd64.tar.xz --arch amd64 --cores 1 --hostname pihole --cpulimit 1 --cpuunits 1024 --memory 256 --net0 name=eth0,bridge=vmbr0,firewall=1,gw=192.168.1.5,ip=192.168.1.254/24,type=veth --ostype centos --rootfs typhoon-share:8 --swap 256 --unprivileged 1 --onboot 1 --startup order=1 --password
```

### 2.02 Install PiHole - CentOS7
First Start your `254 (pihole)` LXC container using the web interface `Datacenter` > `254 (pihole)` > `Start`. Then login into your `254 (pihole)` LXC by going to  `Datacenter` > `254 (pihole)` > `>_ Console and logging in with username `root` and the password you created in the previous step 1.1.

Now using the web interface `Datacenter` > `254 (pihole)` > `>_ Console` run the following command:
```
curl -sSL https://install.pi-hole.net | bash
```
The PiHole installation package will download and the installation will commence. Follow the prompts making sure to enter the prompts and field values as follows:

| PiHole Installation | Value | Notes
| :---  | :---: | :--- |
| PiHole automated installer | `<OK>` | *Just hit your ENTER key*
| Free and open source | `<OK>` | *Just hit your ENTER key*
| Static IP Needed | `<OK>` | *Just hit your ENTER key*
| Select UPstream DNS Provider | `Cloudfare` | *And tab key to highlight <OK> and hit your ENTER key*
| Pihole relies on third party .... | Leave Default, all selected | *And tab key to highlight <OK> and hit your ENTER key*
| Select Protocols | Leave default, all selected | *And tab key to highlight <OK> and hit your ENTER key*
| Static IP Address | Leave Default | *It should show IP Address: 192.168.1.254/24, and Gateway: 192.168.1.5. And tab key to highlight <Yes> and hit your ENTER key*
| FYI: IP Conflict | Nothing to do here | *And tab key to highlight <OK> and hit your ENTER key*
| Do you wish to install the web admin interface | `☑` On (Recommended) | *And tab key to highlight <OK> and hit your ENTER key*
| Do you wish to install the web server |  `☑` On (Recommended) | *And tab key to highlight <OK> and hit your ENTER key*
| Do you want to log queries? |  `☑` On (Recommended) | *And tab key to highlight <OK> and hit your ENTER key*
| Select a privacy mode for FTL |  `☑` 0 Show Everything  | *And tab key to highlight <OK> and hit your ENTER key*
| **And the installation script will commence ...**
| Installation Complete | `<OK>` | *Just hit your ENTER key*

Your installation should be complete.

### 2.03 Reset your PiHole webadmin password - CentOS7
Now reset the web admin password using the web interface `Datacenter` > `254 (pihole)` > `>_ Console` run the following command:
```
pihole -a -p
```
You can now login to your PiHole server using your preferred web browser with the following URL http://192.168.1.254/admin/index.php

### 2.04 Enable DNSSEC - CentOS7
You can enable DNSSEC when using Cloudfare which support DNSSEC. Using the PiHole webadmin URL http://192.168.1.254/admin/index.php go to `Settings` > `DNS Tab` and enable `USE DNSSEC` under Advanced DNS Settings. Click `Save`.

---

## 3.00 UniFi Controller - CentOS7
Rather than buy a UniFi Cloud Key to securely run a instance of the UniFi Controller software you can use Proxmox LXC container to host your UniFi Controller software.

For this we will use a CentOS LXC container.

### 3.01 Create a CentOS7 LXC for UniFi Controller - CentOS7
Now using the web interface `Datacenter` > `Create CT` and fill out the details as shown below (whats not shown below leave as default):

| Create: LXC Container | Value |
| :---  | :---: |
| **General**
| Node | `typhoon-01` |
| CT ID |`251`|
| Hostname |`unifi`|
| Unprivileged container | `☑` |
| Resource Pool | Leave Blank
| Password | Enter your pasword
| Password | Enter your pasword
| SSH Public key | Add one if you want to
| **Template**
| Storage | `local` |
| Template |`centos-7-default_xxxx_amd`|
| **Root Disk**
| Storage |`typhoon-share`|
| Disk Size |`8 GiB`|
| **CPU**
| Cores |`1`|
| CPU limit | Leave Blank
| CPU Units | `1024`
| **Memory**
| Memory (MiB) |`1024`|
| Swap (MiB) |`256`|
| **Network**
| Name | `eth0`
| Mac Address | `auto`
| Bridge | `vmbr0`
| VLAN Tag | Leave Blank
| Rate limit (MN/s) | Leave Default (unlimited)
| Firewall | `☑`
| IPv4 | `☑  Static`
| IPv4/CIDR |`192.168.1.251/24`|
| Gateway (IPv4) |`192.168.1.5`|
| IPv6 | Leave Blank
| IPv4/CIDR | Leave Blank |
| Gateway (IPv6) | Leave Blank |
| **DNS**
| DNS domain | Leave Default (use host settings)
| DNS servers | Leave Default (use host settings)
| **Confirm**
| Start after Created | `☑`

And Click `Finish` to create your UniFi LXC.

Or if you prefer you can simply use Proxmox CLI `typhoon-01` >  `>_ Shell` and type the following to achieve the same thing (note, you will need to create a password for UniFi LXC):
```
pct create 251 local:vztmpl/centos-7-default_20171212_amd64.tar.xz --arch amd64 --cores 1 --hostname unifi --cpulimit 1 --cpuunits 1024 --memory 1024 --net0 name=eth0,bridge=vmbr0,firewall=1,gw=192.168.1.5,ip=192.168.1.251/24,type=veth --ostype centos --rootfs typhoon-share:8 --swap 256 --unprivileged 1 --onboot 1 --startup order=1 --password
```

**Note:** test CentOS UniFi package listing is available [HERE](https://community.ui.com/questions/Unofficial-RHEL-CentOS-UniFi-Controller-rpm-packages/a5db143e-e659-4137-af8d-735dfa53e36d).

### 3.02 Install UniFi - CentOS7
First Start your `251 (unifi)` LXC container using the web interface `Datacenter` > `251 (unifi)` > `Start`. Then login into your `251 (unifi)` LXC by going to  `Datacenter` > `251 (unifi)` > `>_ Console and logging in with username `root` and the password you created in the previous step 2.1.

Now using the web interface `Datacenter` > `251 (unifi)` > `>_ Console` run the following command:

```
yum install epel-release -y &&
yum install http://dl.marmotte.net/rpms/redhat/el7/x86_64/unifi-controller-5.8.24-1.el7/unifi-controller-5.8.24-1.el7.x86_64.rpm -y &&
systemctl enable unifi.service &&
systemctl start unifi.service
```

### 3.03 Move the UniFi Controller to your LXC Instance - CentOS7
You can backup the current configuration and move it to a different computer.

Take a backup of the existing controller using the UniFi WebGUI interface and go to `Settings` > `Maintenance` > `Backup` > `Download Backup`. This will create a `xxx.unf` file format to be saved at your selected destination on your PC (i.e Downloads).

Now on your Proxmox UniFi LXC, https://192.168.1.251:8443/ , you must restore the downloaded backup unf file to the new machine by going to `Settings` > `Maintenance` > `Restore` > `Choose File` and selecting the unf file saved on your local PC.

But make sure when you are restoring the backup you Have closed the previous UniFi Controller server and software because you cannot manage the APs by two controller at a time.


## 4.00 NextCloud - Ubuntu 18.04
Nextcloud helps store your files, folders, contacts, photo galleries, calendars and more on a server of your choosing. Access that folder from your mobile device, your desktop, or a web browser. Access your data wherever you are, when you need it.

Here we going to Turnkey Linux NextCloud prebuilt container.

### 4.01 Download the NextCloud LXC template - Ubuntu 18.04

First you need to add Ubuntu 18.04 LXC to your Proxmox templates if you have'nt already done so. Now using the Proxmox web interface Datacenter > typhoon-01 >Local (typhoon-01) > Content > Templates select ubuntu-18.04-standard LXC and click Download.

Or use a Proxmox typhoon-01 CLI >_ Shell and type the following:
```
wget  http://mirror.turnkeylinux.org/turnkeylinux/images/proxmox/debian-9-turnkey-nextcloud_15.2-1_amd64.tar.gz -P /var/lib/vz/template/cache && gz
```

### 4.02 Create the Turnkey Nextcloud LXC - Ubuntu 18.04
Now using the Proxmox web interface `Datacenter` > `Create CT` and fill out the details as shown below (whats not shown below leave as default):

| Create: LXC Container | Value |
| :---  | :---: |
| **General**
| Node | `typhoon-01` |
| CT ID |`121`|
| Hostname |`nextcloud`|
| Unprivileged container | `☑` |
| Resource Pool | Leave Blank
| Password | Enter your pasword
| Password | Enter your pasword
| SSH Public key | Add one if you want to
| **Template**
| Storage | `local` |
| Template |`debian-9-turnkey-nextcloud_15.2-1_amd64.tar.gz`|
| **Root Disk**
| Storage |`typhoon-share`|
| Disk Size |`8 GiB`|
| **CPU**
| Cores |`1`|
| CPU limit | Leave Blank
| CPU Units | `1024`
| **Memory**
| Memory (MiB) |`1024`|
| Swap (MiB) |`256`|
| **Network**
| Name | `eth0`
| Mac Address | `auto`
| Bridge | `vmbr0`
| VLAN Tag | `70`
| Rate limit (MN/s) | Leave Default (unlimited)
| Firewall | `☑`
| IPv4 | `☑  Static`
| IPv4/CIDR |`192.168.70.121/24`|
| Gateway (IPv4) |`192.168.70.5`|
| IPv6 | Leave Blank
| IPv4/CIDR | Leave Blank |
| Gateway (IPv6) | Leave Blank |
| **DNS**
| DNS domain | `192.168.70.5`
| DNS servers | `192.168.70.5`
| **Confirm**
| Start after Created | `☐`

And Click `Finish` to create your Nextcloud LXC. The above will create the Nextcloud LXC without any of the required local Mount Points to the host.

If you prefer you can simply use Proxmox CLI `typhoon-01` > `>_ Shell` and type the following to achieve the same thing PLUS it will automatically add the required Mount Points (note, have your root password ready for Nextcloud LXC):

**Script (A):** Including LXC Mount Points
```
pct create 121 local:vztmpl/ubuntu-18.04-standard_18.04.1-1_amd64.tar.gz --arch amd64 --cores 2 --hostname nextcloud --cpulimit 1 --cpuunits 1024 --memory 1024 --net0 name=eth0,bridge=vmbr0,tag=80,firewall=1,gw=192.168.80.5,ip=192.168.80.121/24,type=veth --ostype debian --rootfs typhoon-share:8 --swap 256 --unprivileged 0 --onboot 1 --startup order=2 --password --mp0 /mnt/pve/cyclone-01-nextcloud,mp=/mnt/nextcloud --mp1 /mnt/pve/cyclone-01-backup,mp=/mnt/backup --mp2 /mnt/pve/cyclone-01-books,mp=/mnt/books --mp3 /mnt/pve/cyclone-01-audio,mp=/mnt/audio
```

**Script (B):** Excluding LXC Mount Points:
```
pct create 121 local:vztmpl/ubuntu-18.04-standard_18.04.1-1_amd64.tar.gz --arch amd64 --cores 2 --hostname nextcloud --cpulimit 1 --cpuunits 1024 --memory 1024 --net0 name=eth0,bridge=vmbr0,tag=80,firewall=1,gw=192.168.80.5,ip=192.168.80.121/24,type=veth --ostype debian --rootfs typhoon-share:8 --swap 256 --unprivileged 0 --onboot 1 --startup order=2 --password
```

### 4.03 Setup Nextcloud Mount Points - Ubuntu 18.04
If you used Script (B) in Section 3.02 then you have no Moint Points.

Please note your Proxmox Nextcloud LXC MUST BE in the shutdown state before proceeding.

To create the Mount Points use the web interface go to Proxmox CLI Datacenter > typhoon-01 > >_ Shell and type the following:
```
pct set 121 -mp0 /mnt/pve/cyclone-01-nextcloud,mp=/mnt/nextcloud &&
pct set 121 -mp0 /mnt/pve/cyclone-01-backup,mp=/mnt/backup &&
pct set 121 -mp2 /mnt/pve/cyclone-01-books,mp=/mnt/books &&
pct set 121 -mp3 /mnt/pve/cyclone-01-audio,mp=/mnt/audio 
```

### 4.04 Unprivileged container mapping - Ubuntu 18.04

~~To create container mapping we change the container UID and GID in the file /etc/pve/lxc/container-id.conf after you create a new container. Here we are mapping users root (0) and www-data (33) so we set the Nextcloud data folder on the Synology NAS.

~~Simply use Proxmox CLI typhoon-01 > >_ Shell and type the following:
```
echo -e "lxc.idmap: u 1 100000 32
lxc.idmap: g 1 100000 32
lxc.idmap: u 0 0 1
lxc.idmap: g 0 0 1
lxc.idmap: u 33 33 1
lxc.idmap: g 33 33 1
lxc.idmap: u 34 100034 65502
lxc.idmap: g 34 100034 65502" >> /etc/pve/lxc/121.conf &&
# Allow LXC to perform mapping on the Proxmox Host
grep -qxF 'root:33:1' /etc/subuid || echo 'root:33:1' >> /etc/subuid &&
grep -qxF 'root:33:1' /etc/subgid || echo 'root:33:1' >> /etc/subgid &&
grep -qxF 'root:0:1' /etc/subuid || echo 'root:0:1' >> /etc/subuid &&
grep -qxF 'root:0:1' /etc/subgid || echo 'root:0:1' >> /etc/subgid 
```

### 4.04 Install Nextcloud - Ubuntu 18.04
First start LXC 121 (nextcloud) with the Proxmox web interface go to `typhoon-01` > `121 (nextcloud)` > `START`.

Then with the Proxmox web interface go to `typhoon-01` > `121 (nextcloud)` > `>_ Console` and type your root login and password. The Turnkey installation script will autostart requiring user input. Its best to create and record two different complex passwords (i.e oTL&9qe/9Y&RV style) ready for the Nextcloud installation.

| Nexcloud Passwords | Value | Notes
| :---  | :---: | :---
| MySQL Password | `complex password` | *This password is for your Nextcloud SQL - make a record of it*
| Nextcloud Password | `complex password` | *This password is for your Nextcloud admin account - make a record of it*

Now follow the onscreen prompts and type your input as follows:

| First boot configuration | Value | Notes
| :---  | :---: | :---
| **MySQL Password**
| Enter | `insert MySQL password in the box` | *Add a complex password and record it i.e oTL&9qe/9Y&RV*
| **Nextcloud Password**
| Enter | `insert Nextcloud password in the box` | *Add a complex password and record it i.e oTL&9qe/9Y&RV*
| **Nextcloud Domain**
| Enter the domain to serve Nextcloud | `*` | *Enter a asterix for now. You will configure domain access later*
| **Initialize Hub Services**
| Select | `<Skip>` | *Not required*
| **System Notifications and Critical Security Alerts**
| Select | `<Skip>` | *Not required at this stage*
| **Security Updates**
| Security updates? | `<Install>` |

Your Nextcloud console will commence downloading security updates and complete the Nextcloud installation. On completion a dialoque box will appear listing your Nextcloud appliance services.

![alt text](https://raw.githubusercontent.com/ahuacate/proxmox-lxc-homelab/master/images/appliance.png)

Click/Select `<Quit>`

### 3.04 Configure Nextcloud home- Turnkey Debian 9


### 3.05 Setup Nextcloud
Browse to http://192.168.70.121 to start using Nextcloud. You may receive a Firefox warning **Warning: Potential Security Risk Ahead** which you are to ignore. Simply click `Advanced` then `Accept the Risk and Continue` to proceed to your Nextcloud login.

Your Nextcloud user is `admin`and  password is your `Nextcloud Password` which you set Step 3.04.


# Set Nextcloud Home folder to NAS
sed -i "/'datadirectory' => '\/var\/www\/nextcloud\/data',/c\  'datadirectory' => '\/mnt\/nextcloud\/data'," /var/www/nextcloud/config/config.php 


echo -e "lxc.idmap: u 0 100000 33
lxc.idmap: g 0 100000 33
lxc.idmap: u 33 33 1
lxc.idmap: g 33 33 1
lxc.idmap: u 34 100034 65502
lxc.idmap: g 34 100034 65502" >> /etc/pve/lxc/121.conf

echo -e "lxc.idmap: u 1 100000 32
lxc.idmap: g 1 100000 32
lxc.idmap: u 0 0 1
lxc.idmap: g 0 0 1
lxc.idmap: u 33 33 1
lxc.idmap: g 33 33 1
lxc.idmap: u 34 100034 65502
lxc.idmap: g 34 100034 65502" >> /etc/pve/lxc/121.conf

echo -e "root:33:1" >> /etc/subuid &&
echo -e "root:33:1" >> /etc/subgid


echo -e "root:0:1" >> /etc/subuid &&
echo -e "root:0:1" >> /etc/subgid

65535 

# uid map: from uid 0 map 1005 uids (in the ct) to the range starting 100000 (on the host), so 0..1004 (ct) → 100000..101004 (host)
lxc.idmap = u 0 100000 1005
lxc.idmap = g 0 100000 1005
# we map 1 uid starting from uid 1005 onto 1005, so 1005 → 1005
lxc.idmap = u 1005 1005 1
lxc.idmap = g 1005 1005 1
# we map the rest of 65535 from 1006 upto 101006, so 1006..65535 → 101006..165535
lxc.idmap = u 1006 101006 64530
lxc.idmap = g 1006 101006 64530

echo -e "lxc.idmap: u 0 100000 1005
lxc.idmap: g 0 100000 1005
lxc.idmap: u 1005 1005 1
lxc.idmap: g 1005 1005 1
lxc.idmap: u 1006 101006 64530
lxc.idmap: g 1006 101006 64530" >> /etc/pve/lxc/113.conf


---
nano /var/www/nextcloud/config/config.php
sudo nextcloud.occ config:system:set trusted_domains 1 --value=192.168.1.*

  'datadirectory' => '/var/www/nextcloud/data',
  
apt-get update
apt-get install sudo
1. sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --on
2. mkdir -p /mnt/nextcloud/data
3. cp -a /var/www/nextcloud/data. /mnt/nextcloud/data
4. sudo chown -R www-data:www-data /mnt/nextcloud/data
5. nano /path/to/nextcloud/config/config.php
       'datadirectory' => '/new/path/to/data',
6. mysqldump -u<rootuser> -p > /path/to/dbdump/dump.sql
7. Adjust "oc_storages"database table to reflect the new data folder location:
      mysql -u<rootuser> -p
      //enter mysql root password, then within mysql console:
      use <nextclouddb>;
      update oc_storages set id='local::/new/path/to/data/' where id='local::/path/to/data/'; //take care about backslash at the end of path!!
      quit;
8. sudo -u www-data php /path/to/nextcloud/occ maintenance:mode --off
  


Install PHP

Let’s start with the installation of PHP version 5.6 or higher version on your Ubuntu 18.04 LTS Bionic systems.

sudo apt-get update -y &&
sudo apt-get install -y unzip &&
sudo apt-get install -y php php-gd php-curl php-zip php-xml php-mbstring

Install Apache2

sudo apt-get install -y apache2 libapache2-mod-php

Install MySQL

Also install MySQL database server.

sudo apt-get install -y mysql-server php-mysql

Step 2 – Download Nextcloud Archive

After successfully configuring lamp server on your system, Let’s download latest Nextcloud from its official website.

cd /tmp &&
wget https://download.nextcloud.com/server/releases/nextcloud-17.0.0.zip


Now extract downloaded archive under website document root and set up appropriate permissions on files and directories.

cd /var/www/html &&
sudo unzip /tmp/nextcloud-17.0.0.zip &&
sudo chown -R www-data:www-data nextcloud &&
sudo chmod -R 755 nextcloud

Now, remove the archive file.

sudo rm -f /tmp/nextcloud-17.0.0.zip

Step 3 – Create MySQL Database

After extracting code, let’s create a MySQL database and user account for configuring Next cloud. Use the following set of command to log in to MySQL server and create database and user.

mysql -u root -p
Enter password:

CREATE DATABASE nextcloud; &&
GRANT ALL ON nextcloud.* to 'nextcloud'@'localhost' IDENTIFIED BY '_Pa$$w0rd_'; &&
FLUSH PRIVILEGES; &&
quit

Step 4 – Run Nextcloud Web Installer

Access the Nextcloud directory in the web browser as below. Change localhost to your server IP address or domain name.

 http://localhost/nextcloud/

grep -q '^root:33:1' /etc/subuid && sed -i 's/root:33:1/root:33:1/' /etc/subuid || echo 'root:33:1' >> /etc/subuid

grep -qxF 'root:33:1' /etc/subuid || echo 'root:33:1' >> /etc/subuid

