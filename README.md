<h1>PVE Homelab</h1>

This guide is about our Homelab PVE CTs.

As with all our guides, we have an Easy Script to automate CT creation through to the installation of software.

But the first step is to check your network and hardware prerequisite requirements before running our Easy Script. It's important you first read and follow our prerequisite guide.

**Prerequisites**

Network Prerequisites:
- [ ] Layer 2/3 Network Switches

PVE Host Prerequisites:
- [x] PVE Host is configured to our [build](https://github.com/ahuacate/pve-host-setup)
- [x] PVE Host Backend Storage mounted to your NAS
	- nas-0X-backup
	- nas-0X-transcode
	- nas-0X-video
	
	You must have a running network File Server (NAS) with ALL of the above NFS and/or CIFS backend share points configured on your PVE host pve-01.

Optional Prerequisites:
- [ ] pfSense with working OpenVPN Gateways VPNGATE-LOCAL (VLAN30) and VPNGATE-WORLD (VLAN40).

<h4>Easy Scripts</h4>
Easy Scripts are based on bash scripting. Simply `Cut & Paste` our Easy Script command into your terminal window, press `Enter` and follow the prompts and terminal instructions. But PLEASE first read our guide so you fully understand the input requirements.

Our Easy Scripts assumes your network is VLAN ready. If not, simply decline the Easy Script prompt to accept our default settings ( i.e Proceed with our Easy Script defaults (recommended) [y/n]? enter 'n' ). You can then set your own PVE container variables such as IP address.
<hr>

<h4>Table of Contents</h4>
<!-- TOC -->

- [1. About our Homelab Applications](#1-about-our-homelab-applications)
    - [1.1. Unprivileged CTs and File Permissions](#11-unprivileged-cts-and-file-permissions)
        - [1.1.1. Unprivileged container mapping - homelab](#111-unprivileged-container-mapping---homelab)
        - [1.1.2. Allow a LXC to perform mapping on the Proxmox host - homelab](#112-allow-a-lxc-to-perform-mapping-on-the-proxmox-host---homelab)
        - [1.1.3. Create a newuser `storm` in a LXC](#113-create-a-newuser-storm-in-a-lxc)
- [2. PiHole CT](#2-pihole-ct)
    - [2.1. Installation](#21-installation)
    - [2.2. Setup PiHole](#22-setup-pihole)
- [3. UniFi Controller CT](#3-unifi-controller-ct)
    - [3.1. Installation](#31-installation)
- [4. Patches and Fixes](#4-patches-and-fixes)

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

### 1.1.3. Create a newuser `storm` in a LXC
Our PVE User `home` and Group `homelab` are the defaults in all our Homelab CTs. This means all new files created by our Homelab CTs have a common UID and GUID so NAS file creation, ownership and access permissions are fully maintained within the Group `homelab`.

The Linux User and Group settings we use in all MediaLab CTs are:

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
The above change is done automatically in our Easy Script.

# 2. PiHole CT
PiHole is an internet tracker blocking application that acts as a DNS sinkhole. Its charter is to block advertisements, tracking domains, tracking cookies, and all those personal data mining collection companies.

## 2.1. Installation
Our Easy Script will create your PiHole CT. Go to your Proxmox PVE host (i.e pve-01) management WebGUI CLI `>_ Shell` or SSH terminal and type the following (cut & paste):

```
bash -c "$(wget -qLO - https://raw.githubusercontent.com/ahuacate/pve-homelab/master/pve_homelab_ct_pihole_installer.sh)"
```

Follow our Easy Script installation prompts. We recommend you accept our defaults and application settings to create a fully compatible Medialab build suite.

## 2.2. Setup PiHole
In your web browser URL type `http://192.168.1.254`. The application's WebGUI front end will appear. The installation default password is 'ahuacate'.
Our PiHole installation presets all settings.

---


# 3. UniFi Controller CT
Rather than buy an UniFi Cloud Key to securely run an instance of the UniFi Controller software you can use a Proxmox LXC container to host your UniFi Controller software.

## 3.1. Installation
Our Easy Script will create your PiHole CT. Go to your Proxmox PVE host (i.e pve-01) management WebGUI CLI `>_ Shell` or SSH terminal and type the following (cut & paste):

```
Coming soon. Sorry.
```

Follow our Easy Script installation prompts. We recommend you accept our defaults and application settings to create a fully compatible Medialab build suite.

<hr>

# 4. Patches and Fixes

