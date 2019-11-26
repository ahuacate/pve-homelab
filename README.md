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
- [x] UniFi network is fully configured as per [UNIFIBUILD](https://github.com/ahuacate/unifibuild#unifi-build)
- [x] Proxmox node fully configured as per [PROXMOX-NODE BUILDING](https://github.com/ahuacate/proxmox-node/blob/master/README.md#proxmox-node-building)
- [x] pfSense is fully configured on typhoon-01 including both OpenVPN Gateways VPNGATE-LOCAL and VPNGATE-WORLD.

Tasks to be performed are:
- [About LXC Homelab Installations](#about-lxc-homelab-installations)
- [1.00 Unprivileged LXC Containers and file permissions](#100-unprivileged-lxc-containers-and-file-permissions)
	- [1.01 Unprivileged container mapping - homelab](#101-unprivileged-container-mapping---homelab)
	- [1.02 Allow a LXC to perform mapping on the Proxmox host - homelab](#102-allow-a-lxc-to-perform-mapping-on-the-proxmox-host---homelab)
	- [1.03 Create a newuser `storm` in a LXC](#103-create-a-newuser-storm-in-a-lxc)
- [2.00 PiHole LXC - Ubuntu 18.04](#200-pihole-lxc---ubuntu-1804)
	- [2.01 Create a Ubuntu 18.04 LXC for PiHole - Ubuntu 18.04](#201-create-a-ubuntu-1804-lxc-for-pihole---ubuntu-1804)
	- [2.02 Install PiHole - Ubuntu 18.04](#202-install-pihole---ubuntu-1804)
	- [2.03 Reset your PiHole webadmin password - Ubuntu 18.04](#203-reset-your-pihole-webadmin-password---ubuntu-1804)
	- [2.04 Enable DNSSEC - Ubuntu 18.04](#204-enable-dnssec---ubuntu-1804)
- [3.00 UniFi Controller - Ubuntu 18.04](#300-unifi-controller---ubuntu-1804)
	- [3.01 Create a Ubuntu 18.04 LXC for UniFi Controller - Ubuntu 18.04](#301-create-a-ubuntu-1804-lxc-for-unifi-controller---ubuntu-1804)
	- [3.02 Setup UniFi Mount Points - Ubuntu 18.04](#302-setup-unifi-mount-points---ubuntu-1804)
	- [3.03 Unprivileged container mapping - Ubuntu 18.04](#303-unprivileged-container-mapping---ubuntu-1804)
	- [3.04 Create new "storm" user - Ubuntu 18.04](#304-create-new-storm-user---ubuntu-1804)
	- [3.05 Install UniFi - Ubuntu 18.04](#305-install-unifi---ubuntu-1804)
	- [3.06 Move the UniFi Controller to your LXC Instance - Ubuntu 18.04](#306-move-the-unifi-controller-to-your-lxc-instance---ubuntu-1804)
	- [3.07 Patches & Fixes](#307-patches--fixes)
- [4.00 Syncthing - Ubuntu 18.04](#400-syncthing---ubuntu-1804)
	- [4.01 Download the NextCloud LXC template - Ubuntu 18.04](#401-download-the-nextcloud-lxc-template---ubuntu-1804)
	- [4.02 Create the Syncthing LXC - Ubuntu 18.04](#402-create-the-syncthing-lxc---ubuntu-1804)
	- [4.03 Setup Nextcloud Mount Points - Ubuntu 18.04](#403-setup-nextcloud-mount-points---ubuntu-1804)
	- [4.04 Unprivileged container mapping - Ubuntu 18.04](#404-unprivileged-container-mapping---ubuntu-1804)
	- [4.05 Create Syncthing default and user folders on your NAS - Ubuntu 18.04](#405-create-syncthing-default-and-user-folders-on-your-nas---ubuntu-1804)
	- [4.06 Create new "storm" user - Ubuntu 18.04](#406-create-new-storm-user---ubuntu-1804)
	- [4.07 Installing Syncthing - Ubuntu 18.04](#407-installing-syncthing---ubuntu-1804)
	- [4.08 Configuring Syncthing - Ubuntu 18.04](#408-configuring-syncthing---ubuntu-1804)
	- [4.09 Edit Syncthing configuration file - Ubuntu 18.04](#409-edit-syncthing-configuration-file---ubuntu-1804)
	- [4.10 Edit your Network Firewall](#410-edit-your-network-firewall)
	- [4.10 Accessing Syncthing WebGUI](#410-accessing-syncthing-webgui)



## About LXC Homelab Installations
This page is about installing Proxmox LXC's and VM's for your homelab network. Software tools like PiHole, cloud storage and stuff.

Again we build our LXC's on Unbuntu 18.04. Proxmox itself ships with a set of basic templates and to download a prebuilt OS distribution use the graphical interface `typhoon-01` > `local` > `content` > `templates` and select and download the following templates:
*  `ubuntu-18.04-standard`.

## 1.00 Unprivileged LXC Containers and file permissions
With unprivileged LXC containers you will have issues with UIDs (user id) and GIDs (group id) permissions with bind mounted shared data. All of the UIDs and GIDs are mapped to a different number range than on the host machine, usually root (uid 0) became uid 100000, 1 will be 100001 and so on.

However you will soon realise that every file and directory will be mapped to "nobody" (uid 65534). This isn't acceptable for host mounted shared data resources. For shared data you want to access the directory with the same - unprivileged - uid as it's using on other LXC machines.

The fix is to change the UID and GID mapping. So in our build we will create a new users/groups:

*  user `media` (uid 1605) and group `medialab` (gid 65605) accessible to unprivileged LXC containers (i.e Jellyfin, NZBGet, Deluge, Sonarr, Radarr, LazyLibrarian, Flexget);
*  user `storm` (uid 1606) and group `homelab` (gid 65606) accessible to unprivileged LXC containers (i.e Syncthing, Nextcloud, Unifi, Home Assistant, CCTV etc);
*  user `typhoon` (uid 1607) and group `privatelab` (gid 65606) accessible to unprivileged LXC containers (i.e all things private).

Also because Synology new Group ID's are in ranges above 65536, outside of Proxmox ID map range, we must pass through our Medialab (gid 65605), Homelab (gid 65606) and Privatelab (gid 65607) Group GID's mapped 1:1.

This is achieved in three parts during the course of creating your new media LXC's.

### 1.01 Unprivileged container mapping - homelab
To change a container mapping we change the container UID and GID in the file `/etc/pve/lxc/container-id.conf` after you create a new container. Simply use Proxmox CLI `typhoon-01` >  `>_ Shell` and type the following:
```
# User media | Group homelab
echo -e "lxc.idmap: u 0 100000 1606
lxc.idmap: g 0 100000 100
lxc.idmap: u 1606 1606 1
lxc.idmap: g 100 100 1
lxc.idmap: u 1607 101607 63929
lxc.idmap: g 101 100101 65435
# Below are our Synology NAS Group GID's (i.e homelab) in range from 65604 > 65704
lxc.idmap: u 65604 65604 100
lxc.idmap: g 65604 65604 100" >> /etc/pve/lxc/container-id.conf
```
### 1.02 Allow a LXC to perform mapping on the Proxmox host - homelab
Next we have to allow the LXC to actually do the mapping on the host. Since LXC creates the container using root, we have to allow root to use these new uids in the container.

To achieve this we need to **add** lines to `/etc/subuid` (users) and `/etc/subgid` (groups). So we need to define two ranges: one where the system IDs (i.e root uid 0) of the container can be mapped to an arbitrary range on the host for security reasons, and another where Synology GIDs above 65536 of the container can be mapped to the same GIDs on the host. That's why we have the following lines in the /etc/subuid and /etc/subgid files.

Simply use Proxmox CLI `typhoon-01` >  `>_ Shell` and type the following (NOTE: Only needs to be performed ONCE on each host (i.e typhoon-01/02/03)):

```
grep -qxF 'root:65604:100' /etc/subuid || echo 'root:65604:100' >> /etc/subuid &&
grep -qxF 'root:65604:100' /etc/subgid || echo 'root:65604:100' >> /etc/subgid &&
grep -qxF 'root:100:1' /etc/subgid || echo 'root:100:1' >> /etc/subgid &&
grep -qxF 'root:1606:1' /etc/subuid || echo 'root:1606:1' >> /etc/subuid
```

The above code adds a ID map range from 65604 > 65704 on the container to the same range on the host. Next ID maps gid100 (default linux users group) and uid1606 (username storm) on the container to the same range on the host.


### 1.03 Create a newuser `storm` in a LXC
We need to create a `media` user in all media LXC's which require shared data (NFS NAS shares). After logging into the LXC container type the following:

(A) To create a user without a Home folder
```
groupadd -g 65606 homelab &&
useradd -u 1606 -g homelab -M storm
```
(B) To create a user with a Home folder
```
groupadd -g 65606 homelab &&
useradd -u 1606 -g homelab -m storm
```
Note: We do not need to create a new user group because `users` is a default linux group with GID value 100.

## 2.00 PiHole LXC - Ubuntu 18.04
Here we are going install PiHole which is a internet tracker blocking application which acts as a DNS sinkhole. Basically its charter is to block advertisments, tracking domains, tracking cookies and all those personal data mining collection companies.

### 2.01 Create a Ubuntu 18.04 LXC for PiHole - Ubuntu 18.04
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
| Template |`ubuntu-18.04-standard_18.04.1-1_amd64.tar.gz`|
| **Root Disk**
| Storage |`typhoon-share`|
| Disk Size |`20 GiB`|
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
pct create 254 local:vztmpl/ubuntu-18.04-standard_18.04.1-1_amd64.tar.gz --arch amd64 --cores 1 --hostname pihole --cpulimit 1 --cpuunits 1024 --memory 256 --net0 name=eth0,bridge=vmbr0,firewall=1,gw=192.168.1.5,ip=192.168.1.254/24,type=veth --ostype ubuntu --rootfs typhoon-share:20 --swap 256 --unprivileged 1 --onboot 1 --startup order=1 --password
```

### 2.02 Install PiHole - Ubuntu 18.04
First Start your `254 (pihole)` LXC container using the web interface `Datacenter` > `254 (pihole)` > `Start`. Then login into your `254 (pihole)` LXC by going to  `Datacenter` > `254 (pihole)` > `>_ Console and logging in with username `root` and the password you created in the previous step 1.1.

Now using the web interface `Datacenter` > `254 (pihole)` > `>_ Console` run the following command:

```
sudo apt update &&
sudo apt install -y curl &&
curl -sSL https://install.pi-hole.net | bash
```
At the prompt `Configuring libssl1.1:amd64` select `<Yes>`.

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

### 2.03 Reset your PiHole webadmin password - Ubuntu 18.04
Now reset the web admin password using the web interface `Datacenter` > `254 (pihole)` > `>_ Console` run the following command:
```
pihole -a -p
```
You can now login to your PiHole server using your preferred web browser with the following URL http://192.168.1.254/admin/index.php

### 2.04 Enable DNSSEC - Ubuntu 18.04
You can enable DNSSEC when using Cloudfare which support DNSSEC. Using the PiHole webadmin URL http://192.168.1.254/admin/index.php go to `Settings` > `DNS Tab` and enable `USE DNSSEC` under Advanced DNS Settings. Click `Save`.


## 3.00 UniFi Controller - Ubuntu 18.04
Rather than buy a UniFi Cloud Key to securely run a instance of the UniFi Controller software you can use Proxmox LXC container to host your UniFi Controller software.

For this we will use a Ubuntu 18.04 LXC container.

### 3.01 Create a Ubuntu 18.04 LXC for UniFi Controller - Ubuntu 18.04
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
| Template |`ubuntu-18.04-standard_18.04.1-1_amd64.tar.gz`|
| **Root Disk**
| Storage |`typhoon-share`|
| Disk Size |`20 GiB`|
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

**Script (A):** Including LXC Mount Points
```
pct create 251 local:vztmpl/ubuntu-18.04-standard_18.04.1-1_amd64.tar.gz --arch amd64 --cores 1 --hostname unifi --cpulimit 1 --cpuunits 1024 --memory 1024 --net0 name=eth0,bridge=vmbr0,firewall=1,gw=192.168.1.5,ip=192.168.1.251/24,type=veth --ostype ubuntu --rootfs typhoon-share:20 --swap 256 --unprivileged 1 --onboot 1 --startup order=3 --password --mp0 /mnt/pve/cyclone-01-backup,mp=/mnt/backup
```

**Script (B):** Excluding LXC Mount Points:
```
pct create 251 local:vztmpl/ubuntu-18.04-standard_18.04.1-1_amd64.tar.gz --arch amd64 --cores 1 --hostname unifi --cpulimit 1 --cpuunits 1024 --memory 1024 --net0 name=eth0,bridge=vmbr0,firewall=1,gw=192.168.1.5,ip=192.168.1.251/24,type=veth --ostype ubuntu --rootfs typhoon-share:20 --swap 256 --unprivileged 1 --onboot 1 --startup order=3 --password
```

### 3.02 Setup UniFi Mount Points - Ubuntu 18.04
If you used **Script (B)** in Section 2.02 then you have no Moint Points.

Please note your Proxmox UniFi LXC **MUST BE** in the shutdown state before proceeding.

To create the Mount Points use the web interface go to Proxmox CLI `Datacenter` > `typhoon-01` > `>_ Shell` and type the following:

```
pct set 251 -mp0 /mnt/pve/cyclone-01-backup,mp=/mnt/backup
```

### 3.03 Unprivileged container mapping - Ubuntu 18.04
To change the UniFi container mapping we change the container UID and GID in the file `/etc/pve/lxc/251.conf`. Simply use Proxmox CLI `typhoon-01` > `>_ Shell` and type the following:

```
# User storm | Group homelab
echo -e "lxc.idmap: u 0 100000 1606
lxc.idmap: g 0 100000 100
lxc.idmap: u 1606 1606 1
lxc.idmap: g 100 100 1
lxc.idmap: u 1607 101607 63929
lxc.idmap: g 101 100101 65435
# Below are our Synology NAS Group GID's (i.e homelab) in range from 65604 > 65704
lxc.idmap: u 65604 65604 100
lxc.idmap: g 65604 65604 100" >> /etc/pve/lxc/251.conf&&
grep -qxF 'root:65604:100' /etc/subuid || echo 'root:65604:100' >> /etc/subuid &&
grep -qxF 'root:65604:100' /etc/subgid || echo 'root:65604:100' >> /etc/subgid &&
grep -qxF 'root:100:1' /etc/subgid || echo 'root:100:1' >> /etc/subgid &&
grep -qxF 'root:1606:1' /etc/subuid || echo 'root:1606:1' >> /etc/subuid
```

### 3.04 Create new "storm" user - Ubuntu 18.04
First start LXC 251 (unifi) with the Proxmox web interface go to `typhoon-01` > `251 (unifi)` > `START`.

Then with the Proxmox web interface go to `typhoon-01` > `251 (unifi)` > `>_ Shell` and type the following:
```
groupadd -g 65606 homelab &&
useradd -u 1606 -g homelab -m storm
```

### 3.05 Install UniFi - Ubuntu 18.04
First Start your `251 (unifi)` LXC container using the web interface `Datacenter` > `251 (unifi)` > `Start`. Then login into your `251 (unifi)` LXC by going to  `Datacenter` > `251 (unifi)` > `>_ Console` and logging in with username `root` and the password you created in the previous step 2.01.

Now using the web interface `Datacenter` > `251 (unifi)` > `>_ Console` run the following command:

```
# Install required packages
sudo apt update && sudo apt install -y ca-certificates apt-transport-https &&
# Add a new source list
echo 'deb http://www.ui.com/downloads/unifi/debian stable ubiquiti' | sudo tee /etc/apt/sources.list.d/100-ubnt-unifi.list
#  Add the GPG Keys
sudo wget -O /etc/apt/trusted.gpg.d/unifi-repo.gpg https://dl.ui.com/unifi/unifi-repo.gpg &&
sudo apt install -y gnupg2 &&
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6 &&
echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list &&
#  Install and upgrade the UniFi controller
sudo apt update && sudo apt install -y unifi
```
At the prompt `Configuring libssl1.1:amd64` select `<Yes>`.

### 3.06 Move the UniFi Controller to your LXC Instance - Ubuntu 18.04
You can backup the current configuration and move it to a different computer.

Take a backup of the existing controller using the UniFi WebGUI interface and go to `Settings` > `Maintenance` > `Backup` > `Download Backup`. This will create a `xxx.unf` file format to be saved at your selected destination on your PC (i.e Downloads).

Now on your Proxmox UniFi LXC, https://192.168.1.251:8443/ , you must restore the downloaded backup unf file to the new machine by going to `Settings` > `Maintenance` > `Restore` > `Choose File` and selecting the unf file saved on your local PC.

But make sure when you are restoring the backup you Have closed the previous UniFi Controller server and software because you cannot manage the APs by two controller at a time.

### 3.07 Patches & Fixes
Read UniFi's instructions [HERE](https://help.ubnt.com/hc/en-us/articles/220066768-UniFi-How-to-Install-and-Update-via-APT-on-Debian-or-Ubuntu).


## 4.00 Syncthing - Ubuntu 18.04
Syncthing is an open source continuous file synchronization used to sync files between two or more computers in a network. This guide will cover the installation and usage of Syncthing on Ubuntu 18.04.

### 4.01 Download the NextCloud LXC template - Ubuntu 18.04

First you need to add Ubuntu 18.04 LXC to your Proxmox templates if you have'nt already done so. Now using the Proxmox web interface Datacenter > typhoon-01 >Local (typhoon-01) > Content > Templates select ubuntu-18.04-standard LXC and click Download.

Or use a Proxmox typhoon-01 CLI >_ Shell and type the following:
```
wget  http://download.proxmox.com/images/system/ubuntu-18.04-standard_18.04.1-1_amd64.tar.gz -P /var/lib/vz/template/cache && gzip -d /var/lib/vz/template/cache/ubuntu-18.04-standard_18.04.1-1_amd64.tar.gz
```

### 4.02 Create the Syncthing LXC - Ubuntu 18.04
Now using the Proxmox web interface `Datacenter` > `Create CT` and fill out the details as shown below (whats not shown below leave as default):

| Create: LXC Container | Value |
| :---  | :---: |
| **General**
| Node | `typhoon-01` |
| CT ID |`122`|
| Hostname |`syncthing`|
| Unprivileged container | `☑` |
| Resource Pool | Leave Blank
| Password | Enter your pasword
| Password | Enter your pasword
| SSH Public key | Add one if you want to
| **Template**
| Storage | `local` |
| Template |`ubuntu-18.04-standard_18.04.1-1_amd64.tar.gz`|
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
| VLAN Tag | `80`
| Rate limit (MN/s) | Leave Default (unlimited)
| Firewall | `☑`
| IPv4 | `☑  Static`
| IPv4/CIDR |`192.168.80.122/24`|
| Gateway (IPv4) |`192.168.80.5`|
| IPv6 | Leave Blank
| IPv4/CIDR | Leave Blank |
| Gateway (IPv6) | Leave Blank |
| **DNS**
| DNS domain | `192.168.80.5`
| DNS servers | `192.168.80.5`
| **Confirm**
| Start after Created | `☐`

And Click `Finish` to create your Syncthing LXC. The above will create the Syncthing LXC without any of the required local Mount Points to the host.

If you prefer you can simply use Proxmox CLI `typhoon-01` > `>_ Shell` and type the following to achieve the same thing PLUS it will automatically add the required Mount Points (note, have your root password ready for Syncthing LXC):

**Script (A):** Including LXC Mount Points
```
pct create 122 local:vztmpl/ubuntu-18.04-standard_18.04.1-1_amd64.tar.gz --arch amd64 --cores 2 --hostname syncthing --cpulimit 1 --cpuunits 1024 --memory 1024 --net0 name=eth0,bridge=vmbr0,tag=80,firewall=1,gw=192.168.80.5,ip=192.168.80.122/24,type=veth --ostype ubuntu --rootfs typhoon-share:8 --swap 256 --unprivileged 1 --onboot 1 --startup order=2 --password --mp0 /mnt/pve/cyclone-01-cloudstorage,mp=/mnt/cloudstorage --mp1 /mnt/pve/cyclone-01-backup,mp=/mnt/backup --mp2 /mnt/pve/cyclone-01-books,mp=/mnt/books --mp3 /mnt/pve/cyclone-01-audio,mp=/mnt/audio --mp4 /mnt/pve/cyclone-01-public,mp=/mnt/public
```

**Script (B):** Excluding LXC Mount Points:
```
pct create 122 local:vztmpl/ubuntu-18.04-standard_18.04.1-1_amd64.tar.gz --arch amd64 --cores 2 --hostname syncthing --cpulimit 1 --cpuunits 1024 --memory 1024 --net0 name=eth0,bridge=vmbr0,tag=80,firewall=1,gw=192.168.80.5,ip=192.168.80.122/24,type=veth --ostype ubuntu --rootfs typhoon-share:8 --swap 256 --unprivileged 1 --onboot 1 --startup order=2 --password
```

### 4.03 Setup Nextcloud Mount Points - Ubuntu 18.04
If you used Script (B) in Section 3.02 then you have no Moint Points.

Please note your Proxmox Syncthing LXC MUST BE in the shutdown state before proceeding.

To create the Mount Points use the web interface go to Proxmox CLI Datacenter > typhoon-01 > >_ Shell and type the following:
```
pct set 121 -mp0 /mnt/pve/cyclone-01-cloudstorage,mp=/mnt/cloudstorage &&
pct set 121 -mp1 /mnt/pve/cyclone-01-backup,mp=/mnt/backup &&
pct set 121 -mp2 /mnt/pve/cyclone-01-books,mp=/mnt/books &&
pct set 121 -mp3 /mnt/pve/cyclone-01-audio,mp=/mnt/audio
pct set 121 -mp4 /mnt/pve/cyclone-01-public,mp=/mnt/public
```

### 4.04 Unprivileged container mapping - Ubuntu 18.04
To change the Syncthing container mapping we change the container UID and GID in the file `/etc/pve/lxc/122.conf`. Simply use Proxmox CLI `typhoon-01` >  `>_ Shell` and type the following:

```
# User storm | Group homelab
echo -e "lxc.idmap: u 0 100000 1606
lxc.idmap: g 0 100000 100
lxc.idmap: u 1606 1606 1
lxc.idmap: g 100 100 1
lxc.idmap: u 1607 101607 63929
lxc.idmap: g 101 100101 65435
# Below are our Synology NAS Group GID's (i.e homelab) in range from 65604 > 65704
lxc.idmap: u 65604 65604 100
lxc.idmap: g 65604 65604 100" >> /etc/pve/lxc/122.conf&&
grep -qxF 'root:65604:100' /etc/subuid || echo 'root:65604:100' >> /etc/subuid &&
grep -qxF 'root:65604:100' /etc/subgid || echo 'root:65604:100' >> /etc/subgid &&
grep -qxF 'root:100:1' /etc/subgid || echo 'root:100:1' >> /etc/subgid &&
grep -qxF 'root:1606:1' /etc/subuid || echo 'root:1606:1' >> /etc/subuid
```

### 4.05 Create Syncthing default and user folders on your NAS - Ubuntu 18.04
To create the Syncthing default folders use the web interface go to Proxmox CLI `Datacenter` > `typhoon-01` > `>_ Shell` and type the following:
```
mkdir -m 775 -p {/mnt/pve/cyclone-01-cloudstorage/syncthing,/mnt/pve/cyclone-01-cloudstorage/syncthing/Sync} &&
chown -R 1606:65606 {/mnt/pve/cyclone-01-cloudstorage/syncthing,/mnt/pve/cyclone-01-cloudstorage/syncthing/Sync}
```

### 4.06 Create new "storm" user - Ubuntu 18.04
First start LXC 122 (syncthing) with the Proxmox web interface go to `typhoon-01` > `122 (syncthing)` > `START`.

Then with the Proxmox web interface go to `typhoon-01` > `122 (syncthing)` > `>_ Shell` and type the following:
```
groupadd -g 65606 homelab &&
useradd -u 1606 -g homelab -m storm
```

### 4.07 Installing Syncthing - Ubuntu 18.04
The Syncthing package is available on the official repository which can easily be added by running the following commands on your terminal.

First start LXC 122 (syncthing) with the Proxmox web interface go to `typhoon-01` > `122 (syncthing)` > `START`. Then with the Proxmox web interface go to `typhoon-01` > `122 (syncting)` >` >_ Shell` and type the following:

```
# Start by installing curl package & the apt-transport-https package 
sudo apt update &&
sudo apt install -y curl apt-transport-https gnupg2 &&
# Add the release PGP keys & add the "stable" channel to your APT sources
curl -s https://syncthing.net/release-key.txt | sudo apt-key add - &&
echo "deb https://apt.syncthing.net/ syncthing release" > /etc/apt/sources.list.d/syncthing.list &&
# Update system and install syncthing package
sudo apt update &&
sudo apt install -y syncthing &&
# Check Syncthing version
syncthing --version
```
At the prompt `Configuring libssl1.1:amd64` select `<Yes>`.

### 4.08 Configuring Syncthing - Ubuntu 18.04
Create systemd unit files to manage syncthing service.

With the Proxmox web interface go to `typhoon-01` > `122 (syncting)` >` >_ Shell` and type the following:
```
echo -e "[Unit]
Description=Syncthing - Open Source Continuous File Synchronization for %I
Documentation=man:syncthing(1)
After=network.target

[Service]
User=%i
ExecStart=/usr/bin/syncthing -no-browser -gui-address="192.168.80.122:8384" -no-restart -logflags=0
Restart=on-failure
SuccessExitStatus=3 4
RestartForceExitStatus=3 4

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/syncthing@.service &&
sleep 2 &&
sudo systemctl daemon-reload &&
sleep 2 &&
sudo systemctl enable syncthing@storm &&
sleep 2 &&
sudo systemctl start syncthing@storm
```


### 4.09 Edit Syncthing configuration file - Ubuntu 18.04
The Syncthing configuration file needs to have its defaults changed - most important is default storage to your NAS. In this step we are going to change or add the following settings:
*  `Default Folder Path` changed to /mnt/cloudstorage/syncthing;
*  GUI changed to dark setting;

Using the Proxmox web interface go to `typhoon-01` > `122 (syncthing)` > `>_ Shell` and type the following:
```
# First stop the Syncthing Service
sudo systemctl stop syncthing@storm
sleep 2
# Set the Default Folder Path
sed -i 's|<defaultFolderPath>.*</defaultFolderPath>|<defaultFolderPath>/mnt/cloudstorage/syncthing</defaultFolderPath>|g' /home/storm/.config/syncthing/config.xml &&
# Change the GUI to dark
sed -i 's|<theme>.*</theme>|<theme>dark</theme>|g' /home/storm/.config/syncthing/config.xml
<theme>dark</theme>
# Start syncthing
sudo systemctl start syncthing@storm
```

### 4.10 Edit your Network Firewall
Syncthing requires you to open the following ports for incoming and outgoing traffic:
*  Port 22000/TCP (or the actual listening port if you have changed the Sync Protocol Listen Address setting.);
*  Port 21027/UDP (for discovery broadcasts on IPv4 and multicasts on IPv6).

Below are instructions for a UniFi controller `Settings` > `Routing & Firewall` > `Port Forwarding` and look for `+ Create New Port Forward Rule` and fill out the form details as shown below:

| Port Forwarding| Value | Notes
| :--- | :--- | :---
| **Create New Port Forward Rule**
| Name | `Syncthing - listening` |
| Enabled | `☑` Enable this port forward rule |
| From | `☑` Anywhere `☐` Limited |
| Port | `22000`
| Forward IP | `192.168.80.122`
| Forward Port | `22000`
| Protocol | `☐` Both `☑` TCP `☐` UDP
| Logs | `☐` Enable Logging

And click `Save`.

![alt text](https://raw.githubusercontent.com/ahuacate/proxmox-lxc-homelab/master/images/syncthing-listening.png)

### 4.10 Accessing Syncthing WebGUI
The Syncthing admin GUI is started automatically by systemd and is available on https://192.168.80.122:8384/.

---
---
# Under Development

## 4.00 NextCloud - Ubuntu 18.04
Nextcloud helps store your files, folders, contacts, photo galleries, calendars and more on a server of your choosing. Access that folder from your mobile device, your desktop, or a web browser. Access your data wherever you are, when you need it.

But there's a issue. Nextcloud data directory, the folder where each Nextcloud user account stores data (basically user home), cannot be moved to the NAS due to UID GID issues with NFS. 

### 4.01 Download the NextCloud LXC template - Ubuntu 18.04

First you need to add Ubuntu 18.04 LXC to your Proxmox templates if you have'nt already done so. Now using the Proxmox web interface Datacenter > typhoon-01 >Local (typhoon-01) > Content > Templates select ubuntu-18.04-standard LXC and click Download.

Or use a Proxmox typhoon-01 CLI >_ Shell and type the following:
```
wget  http://download.proxmox.com/images/system/ubuntu-18.04-standard_18.04.1-1_amd64.tar.gz -P /var/lib/vz/template/cache && gzip -d /var/lib/vz/template/cache/ubuntu-18.04-standard_18.04.1-1_amd64.tar.gz
```

### 4.02 Create the Nextcloud LXC - Ubuntu 18.04
Now using the Proxmox web interface `Datacenter` > `Create CT` and fill out the details as shown below (whats not shown below leave as default):

| Create: LXC Container | Value |
| :---  | :---: |
| **General**
| Node | `typhoon-01` |
| CT ID |`121`|
| Hostname |`nextcloud`|
| Unprivileged container | `☐` |
| Resource Pool | Leave Blank
| Password | Enter your pasword
| Password | Enter your pasword
| SSH Public key | Add one if you want to
| **Template**
| Storage | `local` |
| Template |`ubuntu-18.04-standard_18.04.1-1_amd64.tar.gz`|
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
| VLAN Tag | `80`
| Rate limit (MN/s) | Leave Default (unlimited)
| Firewall | `☑`
| IPv4 | `☑  Static`
| IPv4/CIDR |`192.168.80.121/24`|
| Gateway (IPv4) |`192.168.80.5`|
| IPv6 | Leave Blank
| IPv4/CIDR | Leave Blank |
| Gateway (IPv6) | Leave Blank |
| **DNS**
| DNS domain | `192.168.80.5`
| DNS servers | `192.168.80.5`
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
pct create 121 local:vztmpl/ubuntu-18.04-standard_18.04.1-1_amd64.tar.gz --arch amd64 --cores 2 --hostname nextcloud --cpulimit 1 --cpuunits 1024 --memory 1024 --net0 name=eth0,bridge=vmbr0,tag=80,firewall=1,gw=192.168.80.5,ip=192.168.80.121/24,type=veth --ostype debian --rootfs typhoon-share:10 --swap 256 --unprivileged 0 --onboot 1 --startup order=2 --password
```

### 4.03 Setup Nextcloud Mount Points - Ubuntu 18.04
If you used Script (B) in Section 3.02 then you have no Moint Points.

Please note your Proxmox Nextcloud LXC MUST BE in the shutdown state before proceeding.

To create the Mount Points use the web interface go to Proxmox CLI Datacenter > typhoon-01 > >_ Shell and type the following:
```
pct set 121 -mp0 /mnt/pve/cyclone-01-nextcloud,mp=/mnt/nextcloud &&
pct set 121 -mp1 /mnt/pve/cyclone-01-backup,mp=/mnt/backup &&
pct set 121 -mp2 /mnt/pve/cyclone-01-books,mp=/mnt/books &&
pct set 121 -mp3 /mnt/pve/cyclone-01-audio,mp=/mnt/audio 
```

### 4.04 Unprivileged container mapping - Ubuntu 18.04

Underdevelopment so ignore - for unprivileged CT.
To create container mapping we change the container UID and GID in the file /etc/pve/lxc/container-id.conf after you create a new container. Here we are mapping users root (0) and www-data (33) so we set the Nextcloud data folder on the Synology NAS.~~
Simply use Proxmox CLI typhoon-01 > >_ Shell and type the following

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


### 4.05 Install PHP - Ubuntu 18.04
First start LXC 121 (nextcloud) with the Proxmox web interface go to `typhoon-01` > `121 (nextcloud)` > `START`. Then with the Proxmox web interface go to `typhoon-01` > `121 (nextcloud)` > `>_ Console` and type your root login and password.

The first step, to set up Nextcloud you must have a running LAMP server on your Ubuntu 18.04 LXC system. The following commands will install it. Type the following:

```
# apt-get update
sudo apt-get update -y &&
# Install PHP
sudo apt-get install -y php-cli php-fpm php-json php-intl php-imagick php-pdo php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-bcmath
```
You will be prompted during the installation whether to `Restart services during package upgrades without asking?`. Select `<Yes>`.

### 4.07 Install Apache Web Server
Here we install and configure a Apache HTTP Server. With the Proxmox web interface go to `typhoon-01` > `121 (nextcloud)` > `>_ Console` and type the following:

```
sudo apt-get install -y apache2 libapache2-mod-php
```

### 4.06 Install MySQL database server.
NextCloud can use MySQL, MariaDB, PostgreSQL or SQLite database to store its data. In this guide, we will use MySQL database server. Type the following:

```
sudo apt-get install -y mysql-server
```

### 4.08 Download the Nextcloud 17.0.0 Archive - Ubuntu 18.04
Here we download and install the latest Nextcloud version. With the Proxmox web interface go to `typhoon-01` > `121 (nextcloud)` > `>_ Console` and login and type the following:

```
# Install unzip
sudo apt-get install -y unzip &&
# Download Nextcloud
wget https://download.nextcloud.com/server/releases/latest.zip -P /tmp && # Latest version, if problems try v17.0.0
#wget https://download.nextcloud.com/server/releases/nextcloud-17.0.0.zip -P /tmp &&
# Extract Nextcloud zip
unzip -o /tmp/latest.zip -d /var/www/html &&
# Set appropriate permissions
sudo chown -R www-data:www-data /var/www/html/nextcloud/ &&
sudo chmod -R 755 /var/www/html/nextcloud &&
# Remove archive
sudo rm -f /tmp/latest.zip
```

### 4.09 Create Nextclouds MySQL Database and User
After the installation of the database server, you need to create a database and user for Nextcloud.

This step requires user input to enter passwords. Its best to create and record two different strong passwords (i.e oTL&9qe/9Y&RV style) ready for the Nextcloud installation.

| Nextcloud StrongPasswords | Value | Notes
| :---  | :---: | :---
| MySQL_ROOT_Password | `STRONGPASSWORD` | *This is your MySQL root password - make a record of it*
| MySQL_NEXTCLOUD_Password| `STRONGPASSWORD`  | *This is your MySQL Nextcloud user password - make a record of it*
| Nextcloud_Password | `STRONGPASSWORD`  | *This password is your Nextcloud WebGUI admin account passowrd - make a record of it*

Next you need to create the MySQL database and user account for configuring Nextcloud. Use the following set of commands to log into MySQL server and create a new database and user. 

```
mysql -u root -p
```
You will be prompted to enter a password. Enter your **MySQL_ROOT_Password**.

After creating the MySQL database root password the terminal will present you with a `mysql>` prompt.  At the `mysql>` prompt type the following (Cut & Paste) and don’t forget to replace STRONGPASSWORD with your database user **MySQL_NEXTCLOUD_Password**. :

```
CREATE USER 'nextcloud'@'localhost' identified by 'STRONGPASSWORD';
CREATE DATABASE nextcloud;
GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'localhost';
FLUSH PRIVILEGES;
QUIT;
```
Now type `reboot -h` to restart the LXC before proceeding to the next step.

### 4.10 Configure Apache Web Server - Ubuntu 18.04
Here we configure a Apache HTTP Server. With the Proxmox web interface go to `typhoon-01` > `121 (nextcloud)` > `>_ Console` and type the following:

```
echo -e "<VirtualHost *:80>
     ServerAdmin admin@example.com
     DocumentRoot /var/www/html/nextcloud/
     ServerName example.com
     ServerAlias www.example.com
     ErrorLog /var/log/apache2/nextcloud-error.log
     CustomLog /var/log/apache2/nextcloud-access.log combined
 
    <Directory /var/www/html/nextcloud/>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
        SetEnv HOME /var/www/html/nextcloud
        SetEnv HTTP_HOME /var/www/html/nextcloud
        <IfModule mod_dav.c>
          Dav off
        </IfModule>
    </Directory>
</VirtualHost>" > /etc/apache2/conf-enabled/nextcloud.conf &&
# Enable required Apache modules and restart the service
sudo a2enmod rewrite dir mime env headers &&
sudo systemctl restart apache2
```

### 4.11 Setup Nextcloud
Browse to http://192.168.80.121 to start using Nextcloud. You may receive a Firefox warning **Warning: Potential Security Risk Ahead** which you are to ignore. Simply click `Advanced` then `Accept the Risk and Continue` to proceed to your Nextcloud login.

### 4.12 Patches and Fixes
sudo -u www-data ls -lisa /mnt/nextcloud/data
sudo -u www-data ls -lisa /var/www/html/nextcloud/data


