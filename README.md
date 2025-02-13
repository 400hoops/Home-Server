# Home-Server
This guide provides a step-by-step walkthrough for setting up a lightweight and minimal home server using Alpine Linux, Docker, OpenZFS, and SMB.

### Hardware Requirements

* A computer capable of running Alpine Linux (preferably x86 based)
* A RJ45 cable
* An empty USB stick
* A PCIE NIC (optional)

### Software Requirements

* Alpine Linux
* Software to create a boot USB, such as:
	+ Rufus
	+ Etcher
	+ Gnome Disks

### Initial Setup

1. **Create a boot USB**: Use the chosen software to create a bootable USB stick with Alpine Linux.
2. **Boot into Alpine**: Insert the USB stick and boot into Alpine Linux.
3. **Alpine Configuration**: Run the `setup-alpine` command to configure the basic settings.

### Installing Services

To install the required services, run the following command:
```bash
apk install nano zfs smb docker docker-compose
```
To start the services on boot, run:
```bash
rc-update add zfs-import default && rc-update add zfs && rc-update add smb && rc-update add docker default
```

### Creating a ZFS Pool

1. **Find disks attached to the system**: Run `lsblk` or `fdisk -l` to identify the available disks.
2. **Create the pool**: Run the following command, replacing `pool` with your desired pool name and `sda` and `sdb` with the actual disk identifiers:
```bash
zpool create -f -o ashift=12 pool mirror sda sdb
```

### Modifying Samba

3. **Remove the existing example conf file**: Run `rm /etc/samba/smb.conf`.
4. **Modify the existing example conf file**: Run `nano /etc/samba/smb.conf`.

### Creating Folders, Users, Groups, and Permissions

1. **Create a new group**: Run `addgroup smb_group`.
2. **Create a new user**: Run `adduser -H -D -G smb_group -S john`.
3. **Create a new Samba user**: Run `smbpasswd -a john`.
4. **Create the /time_machine path on the pool**: Run `mkdir /pool/time_machine`.
5. **Modify the `/pool/time_machine` r/w permissions**: Run `chmod 770 /pool/time_machine && chgrp smb_group /pool/time_machine`.
6. **Start the Samba service**: Run `rc-service start samba`.

### Automatic Updates and Maintainance

To ensure your home server remains secure and up-to-date, consider setting up automatic updates. This can be done by configuring `crontab`. Add the following lines to your crontab file:

```bash
0 3 * * * apk update && apk upgrade
```
This will update the package index and upgrade all packages to the latest version every day at 3:00 am.

To keep your Docker containers up-to-date, add the following line:

```bash
30 3 * * * docker compose pull && docker compose up -d && docker image prune -af
```
This will pull the latest Docker images, update the containers, and prune any unused images every day at 3:30 am.
