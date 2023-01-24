<h1>PVE Homelab</h1>

This guide is about Homelab PVE CTs.

As with all our guides, we have an Easy Script to automate CT creation through to the installation of software.

But the first step is to check your network and hardware prerequisite requirements before running our Easy Script. It's important you first read and follow our prerequisite guide.

<h2>Prerequisites</h2>

**Network Prerequisites**
- [x] Layer 2/3 Network Switches
- [x] Network Gateway (*recommend xxx.xxx.1.5*)
- [x] Network DHCP server (*recommend xxx.xxx.1.5*)
- [x] Network DNS server (*recommend xxx.xxx.1.5*)
- [x] Network Name Server (*recommend xxx.xxx.1.5*)
- [x] PiHole DNS server (*recommend xxx.xxx.1.6*)
    Configured with Conditional Forwarding addresses:
    * Router DNS server (i.e xxx.xxx.1.5 - UniFi DNS)
    * New LAN-vpngate-world DNS Server (i.e xxx.xxx.30.5 - pfSense VLAN30)
    * New LAN-vpngate-local DNS Server (i.e xxx.xxx.40.5 - pfSense VLAN40)
- [x] Local domain name is set on all network devices (*see note below*)
- [x] PVE host hostnames are suffixed with a numeric (*i.e pve-01 or pve01 or pve1*)
- [x] PVE host has internet access

**PVE Host Prerequisites**
- [x] PVE Host is configured to our [build](https://github.com/ahuacate/pve-host)
- [x] PVE Host Backend Storage mounted to your NAS
	- nas-0X-backup
	- nas-0X-transcode (required for CCTV applications/Home-Assistant)
	- nas-0X-video (required for CCTV applications/Home-Assistant)
	
	You must have a running network File Server (NAS) with ALL of the above NFS and/or CIFS backend share points configured on your PVE host 'pve-01'.

**Optional Prerequisites**
- [ ] pfSense HA-Proxy for remote access (i.e Guacamole)

<h2>Local DNS Records</h2>

We recommend <span style="color:red">you read</span> about network Local DNS and why a PiHole server is a necessity. Click <a href="https://github.com/ahuacate/common/tree/main/pve/src/local_dns_records.md" target="_blank">here</a> to learn more before proceeding any further.

Your network Local Domain or Search domain must be also set. We recommend only top-level domain (spTLD) names for residential and small networks names because they cannot be resolved across the internet. Routers and DNS servers know, in theory, not to forward ARPA requests they do not understand onto the public internet. It is best to choose one of our listed names: local, home.arpa, localdomain or lan only. Do NOT use made-up names.

<h2>Easy Scripts</h2>

Easy Scripts automate the installation and/or configuration processes with preset configurations. Simply `Cut & Paste` our Easy Script command into your terminal window, press `Enter` and follow the prompts and terminal instructions.

All Easy Scripts assumes your network is VLAN and DHCP IPv4 ready. If not, decline at the Easy Script prompt to accept our default settings (i.e Proceed with our Easy Script defaults (recommended) [y/n]? enter 'n'). You can then configure your all PVE container variables.

But PLEASE first read our guide so you fully understand the input requirements.

<h4><b>1) Easy Script installer</b></h4>

Use this script to select and install all Homelab applications. Run in a PVE host SSH terminal.

Follow our Easy Script installation prompts. We recommend you accept our defaults and application settings to create a fully compatible Homelab application suite.

```bash
bash -c "$(wget -qLO - https://raw.githubusercontent.com/ahuacate/pve-homelab/main/pve_homelab_installer.sh)"
```

<h4><b>2) Easy Script toolbox</b></h4>

A toolbox is available to perform general maintenance, upgrades and configure add-ons. The options vary between Homelab applications and CTs. Run our Homelab Easy Script toolbox and select an application CT.

Run in a PVE host SSH terminal.


```bash
bash -c "$(wget -qLO - https://raw.githubusercontent.com/ahuacate/pve-homelab/main/pve_homelab_toolbox.sh)"
```


<hr>

<h4>Table of Contents</h4>

<!-- TOC -->

- [1. About our Homelab Applications](#1-about-our-homelab-applications)
    - [1.1. Unprivileged CTs and File Permissions](#11-unprivileged-cts-and-file-permissions)
        - [1.1.1. Unprivileged container mapping - homelab](#111-unprivileged-container-mapping---homelab)
        - [1.1.2. Allow a LXC to perform mapping on the Proxmox host - homelab](#112-allow-a-lxc-to-perform-mapping-on-the-proxmox-host---homelab)
        - [1.1.3. Create a newuser 'home' in a LXC](#113-create-a-newuser-home-in-a-lxc)
- [2. Pi-Hole CT](#2-pi-hole-ct)
    - [2.1. Configure Pi-Hole](#21-configure-pi-hole)
    - [2.2. Manual Conditional Forwarding entries](#22-manual-conditional-forwarding-entries)
- [3. ddclient CT](#3-ddclient-ct)
    - [3.1. Installation](#31-installation)
    - [3.2. Maintenance](#32-maintenance)
        - [3.2.1. Force Dynamic DNS service](#321-force-dynamic-dns-service)
        - [3.2.2. Reconfigure ddclient](#322-reconfigure-ddclient)
- [4. Guacamole CT](#4-guacamole-ct)
    - [4.1. Installation](#41-installation)
    - [4.2. Setup Guacamole](#42-setup-guacamole)
        - [4.2.1. Configure Groups](#421-configure-groups)
        - [4.2.2. Configure Users](#422-configure-users)
        - [4.2.3. Add Connection - Guaca-RDP](#423-add-connection---guaca-rdp)
    - [4.2. Guacamole Toolbox](#42-guacamole-toolbox)
- [5. Guaca-RDP CT](#5-guaca-rdp-ct)
    - [5.1. Installation](#51-installation)
    - [5.2. Setup Guaca-RDP](#52-setup-guaca-rdp)
        - [5.2.1. Firefox bookmarks](#521-firefox-bookmarks)
        - [5.2.2. GPU accelerated Firefox](#522-gpu-accelerated-firefox)
- [6. UniFi Controller CT](#6-unifi-controller-ct)
    - [6.1. Installation](#61-installation)
    - [Setup UniFi Controller](#setup-unifi-controller)
    - [4.2. UniFi Controller Toolbox](#42-unifi-controller-toolbox)
- [7. Patches and Fixes](#7-patches-and-fixes)

<!-- /TOC -->
<hr>


# 1. About our Homelab Applications
All our Homelab PVE CTs are built using the PVE Ubuntu 20.10 template whenever possible.

Shared storage (NAS) is via CT bind mounts with your PVE host(s). All Homelab CT applications use our custom Linux User `home` and Group `homelab`.


## 1.1. Unprivileged CTs and File Permissions
With unprivileged CT containers, you will have issues with UIDs (user id) and GUIDs (group id) permissions with bind-mounted shared data. In Proxmox UIDs and GUIDs are mapped to a different number range than on the host machine, usually, root (uid 0) became uid 100000, 1 will be 100001 and so on.

This means every CT file and directory will be mapped to "nobody" (uid 65534). This isn't acceptable for host mounted shared data resources. For shared data, we want to access the directory with the same, unprivileged, UID as is being used on all other CTs under the same user name.

Our default PVE Users (UID) and Groups (GUID) in all our MediaLab, HomeLab and PrivateLab CTs are common.

*  user `media` (uid 1605) and group `medialab` (gid 65605) accessible to unprivileged LXC containers (i.e JellyFin, NZBGet, Deluge, Sonarr, Radarr, LazyLibrarian, FlexGet);
*  user `home` (uid 1606) and group `homelab` (gid 65606) accessible to unprivileged LXC containers (i.e Syncthing, Nextcloud, Unifi);
*  user `private` (uid 1607) and group `privatelab` (gid 65606) accessible to unprivileged CT containers (i.e all things private).

> Because some people use Synology DiskStations where new Group ID's are in ranges above 65536, outside of Proxmox ID map range, we must pass through our `medialab` (GUID 65605), `homelab` (GUID 65606) and `privatelab` (GUID 65607) Group GUIDs mapped 1:1.

Our fix is done in three stages in our Easy Scripts when you create any new MediaLab application CT.

### 1.1.1. Unprivileged container mapping - homelab
To change a PVE containers mapping we change the PVE container UID and GUID in the file `/etc/pve/lxc/container-id.conf` after our Easy Script creates a new Homelab application CT.
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
### 1.1.2. Allow a LXC to perform mapping on the Proxmox host - homelab
A PVE CT has to be allowed to perform mapping on a PVE host. Since CTs create new containers using root, we have to allow root to use these new UIDs in the new CT.

To achieve this we **add** lines to `/etc/subuid` (users) and `/etc/subgid` (groups). We define two ranges:

1.	One where the system IDs (i.e root uid 0) of the container can be mapped to an arbitrary range on the host for security reasons; and,
2.  Another where Synology GUIDs above 65536 of the container can be mapped to the same GUIDs on a PVE host. That's why we have the following lines in the /etc/subuid and /etc/subgid files.

```
# /etc/subuid
root:65604:100
root:1606:1

# /etc/subgid
root:65604:100
root:100:1
```

The above edits add an ID map range from 65604 > 65704 in the container to the same range on the PVE host. Next ID maps GUID 100 (default Linux users group) and UID 1606 (username home) on the container to the same range on the host.

The above edit is done automatically in our Easy Script.

### 1.1.3. Create a newuser 'home' in a LXC
Our PVE User `home` and Group `homelab` are the defaults in all our Homelab CTs. This means all new files created by our Homelab CTs have a common UID and GUID so NAS file creation, ownership and access permissions are fully maintained within the Group `homelab`.

The Linux User and Group settings we use in all MediaLab CTs are:

(A) To create a user without a Home folder
```
groupadd -g 65606 homelab
useradd -u 1606 -g homelab -M home
```
(B) To create a user with a Home folder
```
groupadd -g 65606 homelab
useradd -u 1606 -g homelab -m home
```
The above change is done automatically in our Easy Script.

<hr>

# 2. Pi-Hole CT

Pi-Hole is an internet tracker blocking application that acts as a DNS sinkhole. Its charter is to block advertisements, tracking domains, tracking cookies, and all those personal data mining collection companies. In our configuration, we also completely bypass 3rd party DNS servers like 8.8.8.8, 1.1.1.1 or your ISP DNS.

## 2.1. Configure Pi-Hole
Our installation fully configures your Pi-Hole DNS server.

In your web browser URL type `http:/pi.hole/admin` or use the static IP address `http:/<ip-address>/admin`. The application's WebGUI front end will appear. The default password is 'ahuacate'.


## 2.2. Manual Conditional Forwarding entries
The User would've been prompted to configure additional Conditional Forwarding entries during the installation. If you choose to add more entries follow these instructions.

Navigate using the Pi-Hole web interface to `Settings` > `DNS tab` and complete as follows (change to match your network).

:white_check_mark: Use DNSSEC
:white_check_mark: Use Conditional Forwarding

|Local network in CIDR|IP address of your DHCP server (router)|Local domain name
|----|----|----
|192.168.0.0/24|192.168.1.5|local

At the time of writing, Pi-Hole WebGUI only allows for one conditional forward entry. From an SSH session to your Pi-hole DNS server create a PiHole host custom file using command/path `nano /etc/dnsmasq.d/01-custom.conf`. In this file we add the following server entries (amend to your chosen IPv4 addresses):

```
server=/local/192.168.30.5 # LAN-vpngate-world
server=/local/192.168.40.5 # LAN-vpngate-local
server=/168.192.in-addr.arpa/192.168.1.5 # UniFi UGS/UDM router
server=/168.192.in-addr.arpa/192.168.30.5 # LAN-vpngate-world
server=/168.192.in-addr.arpa/192.168.40.5 # LAN-vpngate-local

strict-order
```

<hr>

# 3. ddclient CT
ddclient is a Perl client used to update dynamic DNS entries for accounts on many dynamic DNS services.

Dynamic DNS services currently supported include:
```
DynDNS.com  - See http://www.dyndns.com for details on obtaining a free account.
Zoneedit    - See http://www.zoneedit.com for details.
EasyDNS     - See http://www.easydns.com for details.
NameCheap   - See http://www.namecheap.com for details
DslReports  - See http://www.dslreports.com for details
Sitelutions - See http://www.sitelutions.com for details
Loopia      - See http://www.loopia.se for details
Noip        - See http://www.noip.com/ for details
Freedns     - See http://freedns.afraid.org/ for details
ChangeIP    - See http://www.changeip.com/ for details
nsupdate    - See nsupdate(1) and ddns-confgen(8) for details
CloudFlare  - See https://www.cloudflare.com/ for details
Google      - See http://www.google.com/domains for details
Duckdns     - See https://duckdns.org/ for details
Freemyip    - See https://freemyip.com for details
woima.fi    - See https://woima.fi/ for details
Yandex      - See https://domain.yandex.com/ for details
DNS Made Easy - See https://dnsmadeeasy.com/ for details
DonDominio  - See https://www.dondominio.com for details
NearlyFreeSpeech.net - See https://www.nearlyfreespeech.net/services/dns for details
OVH         - See https://www.ovh.com for details
ClouDNS     - See https://www.cloudns.net
dinahosting - See https://dinahosting.com
Gandi       - See https://gandi.net
dnsexit     - See https://dnsexit.com/ for details
```

## 3.1. Installation
Open an account at any of the above providers ( Freedns is free ).

Have your Dynamic DNS hosting service credentials ready. During the installation you are required to input your account credentials:

* Username
* Password
* Server URL ( i.e hello.crabdance.com for a freedns.afraid.org account )

Use our Easy Script installer.

The native ddclient setup wizard will start in your terminal window. Select your Dynamic DNS service provider and input your credentials when prompted.

## 3.2. Maintenance
To manually update or reconfigure ddclient run the following SSH commands on your PVE host ( i.e pve-01 ).

### 3.2.1. Force Dynamic DNS service
```
# Replace with your ddclient CTID (252)
CTID=252
pct exec ${CTID} -- bash -c 'ddclient -daemon=0 -debug -verbose -noquiet -force'
```
### 3.2.2. Reconfigure ddclient
```
# Replace with your ddclient CTID (252)
CTID=252
pct exec ${CTID} -- bash -c 'sudo dpkg-reconfigure ddclient'
```

<hr>

# 4. Guacamole CT
Apache Guacamole is a clientless remote desktop gateway. It supports standard protocols like VNC, RDP, and SSH. Once Guacamole is installed on a server, all you need to access your desktops is a web browser.

## 4.1. Installation
This install uses the [MysticRyuujin](https://github.com/MysticRyuujin/guac-install) installation script. Thanks to [MysticRyuujin](https://github.com/MysticRyuujin/guac-install) for maintaining this script.

During the install process you will be prompted to use two-factor authorization. We recommend you configure two-factor authorization. Our preference is TOTP with a YubiKey. Your install options are:

*  **TOTP** - Time-based one-time password (Recommended)
TOTPs are used for two-factor authentication (2FA) or multi-factor authentication (MFA). Providers are YubiKey, Google Authenticator, Microsoft Authenticator etc.
*  **DUO** - Part of Cisco MFA family.


Use our Easy Script installer. Follow our Easy Script installation prompts.

## 4.2. Setup Guacamole
To connect to this system, we have to create an administrative user account that allows us to authenticate and administer Guacamole.

Much like any Linux OS Guacamole uses Groups and Users.

In your web browser URL type `http://guacamole.local:8080/guacamole/#/`. The application's WebGUI front end will appear. The installer default credentials are: username `guacadmin` and password `guacadmin`.

### 4.2.1. Configure Groups
Navigate using the Guacamole web interface to `settings` > `Groups tab` > `New Group` and complete as follows.

| Description | Value
| :--- | :---
| Group name | `Privatelab`
| **Group Restrictions**
| Disabled | `☐`
| **Permissions**
| Administer system | `☑`
| Create new users | `☑`
| Create new user groups | `☐`
| Create new connections | `☐`
| Create new connection groups | `☐`
| Create new sharing profiles | `☐`
| **Parent Groups**
| **Member Groups**
| **Member Users**
| **Connections**

And click `Save`.

### 4.2.2. Configure Users
Guacamole's default root level user is "guacadmin". We recommend you delete this user BUT first create an alternative.

Navigate using the Guacamole web interface to `settings` > `Users tab` > `New User` and complete as follows.

| Description | Value
| :--- | :---
| MySQL `☑`
| Username | input your own admin name (not guacadmin or admin or root)
| Password | something complex as its open to the web
| **Configure TOTP**
| Clear TOTP secret
| TOTP key confirmed
| **Account Restrictions**
| Login disabled | `☐`
| Password expired | 
|Allow access after
| Do not allow access after
|Enable account after
| Disable account after
| User time zone | best set as it makes reading logs easier
| **Profile**
| Full name
| Email address
| Organization
| Role
| **Permissions**
| Administer system | `☑`
| Create new users | `☑`
| Create new user group | `☑`
| Create new connections | `☑`
| Create new connection groups | `☑`
| Create new sharing profiles | `☑`
| Change own password | `☑`
| **Groups**
|| `☑` Privatelab
| **Connections**

And click `Save`.

Now immediately delete user `guacadmin`.

### 4.2.3. Add Connection - Guaca-RDP
Guaca-RDP is a headless PVE Ubuntu remote desktop gateway.

Navigate using the Guacamole web interface to `settings` > `Connections tab` > `New Group` and complete as follows.

| Description | Value
| :--- | :---
| Name | `Privatelab`
| Location | `ROOT`
| Type | `Organizational`
| **Concurrency Limits** (Balancing Groups)
| Maximum number of connections | `1`
| Maximum number of connections per user | `1`
| Enable session affinity | `☐`

Navigate using the Guacamole web interface to `settings` > `Connections tab` > `New Connection` and complete as follows.

| Description | Value
| :--- | :---
| Name | `Guacamole RDP Machine`
| Location | `homelab`
| Protocol | `RDP`
| **Concurrency Limits**
| Maximum number of connections | `1`
| Maximum number of connections per user | `2`
| **Load Balancing**
| Connection weight
| Use for failover only
| **Guacamole Proxy Parameters**
| Hostname
| Port
| Encryption
| **Parameters**
| **Network**
| Hostname | `guacardp.local`
| Port | `3389`
| **Authentication**
| Username | `admin`
| Password | `ahuacate`
| Domain | `local` (or your localdomain)
| Security mode | `RDP encryption`
| Disable authentication | `☐`
| Ignore server certificate | `☑`
| **Remote Desktop Gateway**
| Hostname
| Port
| Username
| Password
| Domain
| **Basic Settings**
| Initial program
| Client name
| Keyboard layout
| Time zone
| Enable multi-touch | `☑`
| Administrator console
| **Display**
| Width | `1920`
| Height| `1080`
| Resolution (DPI)
| Color depth | `True colour (32-bit)`
| Force lossless compression | `☐`
| Resize method | `"Display update" virtual channel (RDP 8.1+)`
| Read-only | `☐`
| **Clipboard**
| Line endings
| Disable copying from remote desktop
| Disable pasting from client
| **Device Redirection**
| Support audio in console
| Disable audio
| Enable audio input (microphone)
| Enable printing
| Redirected printer name
| Enable drive
| Drive name
| Disable file download
| Disable file upload
| Drive path
| Automatically create drive
| Static channel names
| **Performance**
| Enable wallpaper
| Enable theming
| Enable font smoothing (ClearType) | `☑`
| Enable full-window drag | `☑`
| Enable desktop composition (Aero)
| Enable menu animations
| Disable bitmap caching
| Disable off-screen caching
| Disable glyph caching
| **RemoteApp**
| Program
| Working directory
| Parameters
| **Preconnection PDU / Hyper-V**
| RDP source ID
| Preconnection BLOB (VM ID)
| **Load Balancing**
| Load balance info/cookie
| **Screen Recording**
| Recording path
| Recording name
| Exclude graphics/streams
| Exclude mouse
| Exclude touch events
| Include key events
| Automatically create recording path
| **SFTP**
| Enable SFTP
| Hostname
| Port
| Public host key (Base64)
| Username
| Password
| Private key
| Passphrase
| File browser root directory
| Default upload directory
| SFTP keepalive interval
| Disable file download
| Disable file upload
| **Wake-on-LAN (WoL)**
| Send WoL packet
| MAC address of the remote host
| Broadcast address for WoL packet
| UDP port for WoL packet
| Host boot wait time 

And click `Save`.

## 4.2. Guacamole Toolbox
A toolbox is available to perform general maintenance, upgrades and configure add-ons. The options vary between Homelab applications and CTs. Run our Homelab Easy Script toolbox and select an application CT.

<hr>

# 5. Guaca-RDP CT
Guaca-RDP is a headless PVE Ubuntu remote desktop gateway. It supports Guacamole RDP and SSH connections. Use it to remotely connect to your PVE hosts and network clients using Guacamole.

## 5.1. Installation
Use our Easy Script installer. Follow our Easy Script installation prompts.

## 5.2. Setup Guaca-RDP
The default user credentials are: username `admin` and password `ahuacate`.

### 5.2.1. Firefox bookmarks
We have created a Firefox bookmark list of all our Ahuacate CT URLs.

Navigate using the Firefox web interface `Settings` > `Bookmarks` > `Manage bookmarks` > `Import and Backup` > `Restore` > `Choose File` and browse to Desktop file `bookmarks-ahuacate.json`. Click `Open` to import.

### 5.2.2. GPU accelerated Firefox
Connect to Guaca-RDP using any remote connect package (i.e Windows Remote Desktop Connection).

Guaca-RDP is preinstalled with Firefox. To enable VA-API GPU acceleration you need to perform some Firefox tuning.

Navigate using the Firefox web interface and input the address `about:config` and click `Accept the Risk and Continue`. Search for the following settings and configure them as shown in the table below.

| Preference Name | Flag Value
| :--- | :---
| media.ffmpeg.vaapi.enabled | true
| gfx.webrender.enabled | true
| gfx.webrender.all | true
| layers.acceleration.force-enabled | true

<hr>

# 6. UniFi Controller CT
Rather than buy an UniFi Cloud Key to securely run an instance of the UniFi Controller software you can use a Proxmox LXC container to host your UniFi Controller software.

## 6.1. Installation
Use our Easy Script installer. Follow our Easy Script installation prompts.

## Setup UniFi Controller
UniFi Controller must be assigned a static IP address. Make a DHCP IP reservation at your DHCP server or router (i.e 192.168.1.4) and restart your UniFi Controller CT.

In your web browser URL type `http://unifi-controller.local:8443`. The application's WebGUI front end will appear.

## 4.2. UniFi Controller Toolbox
A toolbox is available to perform general maintenance, upgrades and configure add-ons. The options vary between Homelab applications and CTs. Run our Homelab Easy Script toolbox and select an application CT.

<hr>

# 7. Patches and Fixes

