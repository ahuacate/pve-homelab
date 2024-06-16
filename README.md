<h1>PVE Homelab</h1>

Homelab focuses on everything related to your Home network and management, providing a range of PVE CT-based applications such as PiHole, UniFi-Controller, Guacamole, ddclient, and more. In addition, it offers an Easy Script Installer and Toolbox that automates many of the tasks, accompanied by step-by-step instructions.

However, before you begin using Homelab, it's crucial to ensure that your network, hardware, and NAS setup meet the prerequisites outlined in our guide. It's essential to read and follow this guide before proceeding.

<h2>Prerequisites</h2>

Read about our <a href="https://github.com/ahuacate/common/tree/main/pve/src/local_about_our_build.md" target="_blank">system-wide requirements</a> before proceeding any further.

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

Before proceeding, we <span style="color:red">strongly advise</span> that you familiarize yourself with network Local DNS and the importance of having a PiHole server. To learn more, click <a href="https://github.com/ahuacate/common/tree/main/pve/src/local_dns_records.md" target="_blank">here</a>.

It is essential to set your network's Local Domain or Search domain. For residential and small networks, we recommend using only top-level domain (spTLD) names because they cannot be resolved across the internet. Routers and DNS servers understand that ARPA requests they do not recognize should not be forwarded onto the public internet. It is best to select one of the following names: local, home.arpa, localdomain, or lan only. We strongly advise against using made-up names.

<h2>Easy Scripts</h2>

Easy Scripts simplify the process of installing and configuring preset configurations. To use them, all you have to do is copy and paste the Easy Script command into your terminal window, hit Enter, and follow the prompts and terminal instructions.

Please note that all Easy Scripts assume that your network is VLAN and DHCP IPv4 ready. If this is not the case, you can decline the Easy Script prompt to accept our default settings. Simply enter 'n' to proceed without the default settings. After declining the default settings, you can configure all your PVE container variables.

However, before proceeding, we highly recommend that you read our guide to fully understand the input requirements.

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
        - [1.1.3. Create a new user 'home' in a LXC](#113-create-a-new-user-home-in-a-lxc)
- [2. Pi-Hole CT](#2-pi-hole-ct)
    - [2.1. Configure Pi-Hole](#21-configure-pi-hole)
    - [2.2. Manual Conditional Forwarding entries](#22-manual-conditional-forwarding-entries)
    - [2.3. Pi-Hole updates](#23-pi-hole-updates)
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
    - [4.3. Guacamole Toolbox](#43-guacamole-toolbox)
- [5. Guaca-RDP CT](#5-guaca-rdp-ct)
    - [5.1. Installation](#51-installation)
    - [5.2. Setup Guaca-RDP](#52-setup-guaca-rdp)
        - [5.2.1. Firefox bookmarks](#521-firefox-bookmarks)
        - [5.2.2. GPU accelerated Firefox](#522-gpu-accelerated-firefox)
- [6. Tailscale CT](#6-tailscale-ct)
    - [6.1. Installation](#61-installation)
    - [6.2. Connect and authenticate to Tailscale network](#62-connect-and-authenticate-to-tailscale-network)
    - [6.3. Tailscale node RDP login](#63-tailscale-node-rdp-login)
        - [6.3.1. Firefox bookmarks](#631-firefox-bookmarks)
        - [6.3.2. GPU accelerated Firefox](#632-gpu-accelerated-firefox)
    - [6.4. Setup your Tailscale CT for network device ssh connections](#64-setup-your-tailscale-ct-for-network-device-ssh-connections)
- [7. Tails OS VM](#7-tails-os-vm)
    - [7.1. Installation](#71-installation)
    - [7.2. Connect to Tails OS using the Proxmox console](#72-connect-to-tails-os-using-the-proxmox-console)
    - [7.3. Connect to Tails OS using Virt-Machine-Viewer](#73-connect-to-tails-os-using-virt-machine-viewer)
        - [7.3.1. Windows 10/11 Install](#731-windows-1011-install)
    - [7.4. Tails updates](#74-tails-updates)
- [8. UniFi Controller CT](#8-unifi-controller-ct)
    - [8.1. Installation](#81-installation)
    - [8.2. Setup UniFi Controller](#82-setup-unifi-controller)
    - [8.3. UniFi Controller Toolbox](#83-unifi-controller-toolbox)
- [9. Patches and Fixes](#9-patches-and-fixes)

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
To change a PVE container mapping we change the PVE container UID and GUID in the file `/etc/pve/lxc/container-id.conf` after our Easy Script creates a new Homelab application CT.
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

### 1.1.3. Create a new user 'home' in a LXC
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
## 2.3. Pi-Hole updates
A toolbox is available to perform general maintenance, upgrades and configure add-ons. The options vary between Homelab applications and CTs. Run our Homelab Easy Script toolbox and select an application CT.

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

## 4.3. Guacamole Toolbox
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

# 6. Tailscale CT
Tailscale is a software-defined networking solution that establishes secure communication between devices over the internet. It creates a virtual private network (VPN) that allows devices to interact as if they were on the same local network.

The Tailscale host CT node is a Ubuntu machine with remote desktop (RDP) and preinstalled with Mozilla Firefox.

You can remotely connect to your Tailscale node to remotely manage your network.

## 6.1. Installation
Use our Easy Script installer. Follow our Easy Script installation prompts.

## 6.2. Connect and authenticate to Tailscale network
We recommend you connect and authenticate your Tailscale CT to your private tailnet network with SSH support. Tailscale SSH allows Tailscale to manage the authentication and authorization of SSH connections on your private tailnet.

Historically, to secure an SSH connection, you generate a keypair on the machine you are connecting from (known as the client), with the private key stored on the client, and the public key distributed to the device you want to connect to (known as the server). This lets the server authenticate communication from the client.

With Tailscale, you can already connect machines in your network, and encrypt communications end-to-end from one point to another—and this includes, for example, SSHing from your work laptop to your work desktop. Tailscale also knows your identity, since that’s how you connected to your Tailnet. When you enable Tailscale SSH, Tailscale claims port 22 for the Tailscale IP address (that is, only for traffic coming from your tailnet) on the devices for which you have enabled Tailscale SSH. This routes SSH traffic for the device from the Tailscale network to an SSH server run by Tailscale, instead of your standard SSH server.

Connect and authenticate your Tailscale CT with SSH support:

```
# sudo tailscale up --ssh
sudo tailscale up --accept-routes=true --accept-dns=true --ssh
```

You will be prompted with a webpage URL to authenticate and login using an authorization method. We use GMail for home use. For home users, consider disabling your Tailscale key expiry. To disable Tailscale key expiry open the 'Machines page' of the admin console webpage, select your Tailscale server and in the far right menu select the 'Disable Key Expiry' option.

## 6.3. Tailscale node RDP login
The default Tailscale CT RDP Ubuntu credentials are: username `admin` and password `ahuacate`.

### 6.3.1. Firefox bookmarks
We have created a Firefox bookmark list of all our Ahuacate CT URLs.

Navigate using the Firefox web interface Settings > `Bookmarks` > `Manage bookmarks` > `Import and Backup` > `Restore` > `Choose File` and browse to Desktop file `bookmarks-ahuacate.json`. Click `Open` to import.

### 6.3.2. GPU accelerated Firefox
Connect to the Tailscale node using any remote connect package (i.e Windows Remote Desktop Connection) and IP address obtained from Tailscale.

The Tailscale node is preinstalled with Firefox. To enable VA-API GPU acceleration you need to perform some Firefox tuning.

Navigate using the Firefox web interface and input the address `about:config` and click `Accept the Risk and Continue`. Search for the following settings and configure them as shown in the table below.

| Preference Name | Flag Value
| :--- | :---
| media.ffmpeg.vaapi.enabled | true
| gfx.webrender.enabled | true
| gfx.webrender.all | true
| layers.acceleration.force-enabled | true

Restart Firefox web browser.

## 6.4. Setup your Tailscale CT for network device ssh connections
After establishing a connection to your Tailscale Central Team (CT), you gain the ability to administer your network devices remotely through either SSH or a web browser. For SSH access, it might be necessary to incorporate your device's private SSH key(s) into the Tailscale CT user folder located at ~/.ssh.

In the following demonstration, we generate an SSH key pair specially designated for Proxmox hosts to facilitate Tailscale CT connectivity. To distinguish this new key, we append "-pve" to its name. Always ensure that you securely store both the private and public key pairs in a safe location.

In this illustration, we create the keys utilizing a Proxmox host.
```
# Generate new ssh keypair
ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/id_ed25519-pve -N ""

# Copy ssh public key to Proxmox authorized_keys (localhost)
ssh-copy-id -i ~/.ssh/id_ed25519-pve.pub localhost

# Copy ssh public key to Proxmox authorized_keys (other PVE hosts)
ssh-copy-id -i ~/.ssh/id_ed25519-pve.pub root@192.168.1.10X
```

Copy ssh private key to your Tailscale CT user 'admin' (id_ed25519-pve):
```
# Copy ssh private key to Tailscale CT:
scp ~/.ssh/id_ed25519-pve admin@tailscale.local:~/.ssh/
```

If you want to add aliases for SSH hosts in your SSH configuration file, you can create named sections with custom configuration options. These sections allow you to define aliases for remote hosts with specific settings. Here's an example of how you can define aliases in your ~/.ssh/config (the following already exists for Tailscale user 'admin'):

```
Host pve-01
  HostName 192.168.1.101
  User root
  IdentityFile ~/.ssh/id_ed25519-pve

Host pve-02
  HostName 192.168.1.102
  User root
  IdentityFile ~/.ssh/id_ed25519-pve

Host pve-03
  HostName 192.168.1.103
  User root
  IdentityFile ~/.ssh/id_ed25519-pve

Host pve-04
  HostName 192.168.1.104
  User root
  IdentityFile ~/.ssh/id_ed25519-pve

Host pve-05
  HostName 192.168.1.105
  User root
  IdentityFile ~/.ssh/id_ed25519-pve

Host nas-01
  HostName nas-01.local
  User admin
  IdentityFile ~/.ssh/id_ed25519-pve
```

Set the appropriate permissions:
```
sudo -u admin chmod 600 /home/admin/.ssh/config
```

<hr>

# 7. Tails OS VM
Tails is a portable operating system that protects against surveillance and censorship. Tails use the Tor network to protect your privacy online and help you avoid censorship.

## 7.1. Installation
Use our Easy Script installer. Follow our Easy Script installation prompts.

Or follow this tutorial to create a Tails VM: <a href="https://tultr.com/tutorial-how-to-install-tails-os-in-a-proxmox-vm/" target="_blank">here</a>.

If you're using a VPN service, think about directing the traffic through the VPN VLAN tag within the PVE GUI.

## 7.2. Connect to Tails OS using the Proxmox console
Start Tails VM using your PVE host WebGUI.

Navigate to PVE WEbGUI `PVE host` > `Tails VM`:
-- `Start`
-- `Console`

Boot times vary on hardware so be patient. Tails will now start in your PVE console window.

## 7.3. Connect to Tails OS using Virt-Machine-Viewer
Read about Virt-Viewer [here](https://gitlab.com/virt-viewer/virt-viewer).

### 7.3.1. Windows 10/11 Install
You can install Virt-Viewer on your Windows machine to access your Tails VM. Our Tails installation is already set up for SPICE (virt-viewer) remote connections.

1. First step is to install Virt-Viewer on your Windows machine. Navigate to Windows `cmd` prompt, run as administrator, and type the following command:
-- `winget install virt-viewer`
2. Navigate to PVE WebGUI `PVE host` > `Tails VM` > `Start`
After Tails has started you can get the PVE Spice config file downloaded to your Windows machine.
3. Navigate to PVE WebGUI `PVE host` > `Tails VM` > `_Console` > `Spice` and a Spice config file will be downloaded to your Windows machine.
4. Open the Spice config file (i.e CQv4zBSK.vv) with Virt-Viewer. Virt-Viewer should automatically start with your Tails session.

## 7.4. Tails updates
Our Tails VM is self-updating. After VM shutdown our Tails install will check and update if required the boot ISO to the latest version. So be patient between Tails reboots because if updating is performed the download is more than 1GB.

<hr>

# 8. UniFi Controller CT
Rather than buy an UniFi Cloud Key to securely run an instance of the UniFi Controller software you can use a Proxmox LXC container to host your UniFi Controller software.

## 8.1. Installation
Use our Easy Script installer. Follow our Easy Script installation prompts.

## 8.2. Setup UniFi Controller
UniFi Controller must be assigned a static IP address. Make a DHCP IP reservation at your DHCP server or router (i.e 192.168.1.4) and restart your UniFi Controller CT.

In your web browser URL type `http://unifi-controller.local:8443`. The application's WebGUI front end will appear.

## 8.3. UniFi Controller Toolbox
A toolbox is available to perform general maintenance, upgrades and configure add-ons. The options vary between Homelab applications and CTs. Run our Homelab Easy Script toolbox and select an application CT.

<hr>

# 9. Patches and Fixes

