#!/bin/sh

echo "Installing required services..."
apk update
apk install nano zfs smb docker docker-compose

echo "Starting services on boot..."
rc-update add zfs-import default
rc-update add zfs
rc-update add smb
rc-update add docker default

echo "Creating a ZFS pool..."
lsblk
read -p "Enter the pool name: " pool_name
read -p "Enter the disk identifiers (e.g. sda sdb): " disk_identifiers
zpool create -f -o ashift=12 $pool_name mirror $disk_identifiers

echo "Modifying Samba settings..."
rm /etc/samba/smb.conf
cat > /etc/samba/smb.conf <<EOF
[global]
        bind interfaces only = yes
        client ipc min protocol = SMB3
        client ipc signing = required
        client signing = required
        map to guest = Bad User
        restrict anonymous = 2
        security = USER
        server min protocol = SMB3
        server signing = required
        socket options = TCP_NODELAY IPTOS_LOWDELAY
        fruit:metadata = stream
        fruit:model = MacSamba
        fruit:veto_appledouble = no
        fruit:nfs_aces = no
        fruit:wipe_intentionally_left_blank_rfork = yes
        fruit:delete_empty_adfiles = yes
        fruit:posix_rename = yes
        idmap config * : backend = tdb
        browseable = no
        vfs objects = fruit streams_xattr

[Time Machine]
        comment = Time Machine Backup
        force create mode = 0660
        force directory mode = 0770
        force group = smb_group
        force user = nobody
        inherit acls = yes
        path = /$pool_name/time_machine
        posix locking = no
        read only = no
        fruit:time machine = yes
EOF

echo "Creating a new group..."
addgroup smb_group
echo "Creating a new user..."
read -p "Enter the username (default: john): " username
username=${username:-john}
adduser -H -D -G smb_group -S $username
echo "Creating a new Samba user..."
read -sp "Enter the Samba password: " smb_password
echo
read -sp "Confirm the Samba password: " smb_password_confirm
echo
while [ "$smb_password" != "$smb_password_confirm" ]; do
  echo "Passwords do not match. Please try again."
  read -sp "Enter the Samba password: " smb_password
  echo
  read -sp "Confirm the Samba password: " smb_password_confirm
  echo
done
echo "$username:$smb_password" | chpasswd -c smb
echo "Creating the /time_machine path on the pool..."
mkdir /$pool_name/time_machine
echo "Modifying the /time_machine r/w permissions..."
chmod 770 /$pool_name/time_machine
chgrp smb_group /$pool_name/time_machine
echo "Starting the Samba service..."
rc-service start samba

echo "Configuring automatic updates and maintenance..."
crontab -l | { 
  cat; 
  echo "0 3 * * * apk update && apk upgrade"; 
  echo "30 3 * * * docker compose pull && docker compose up -d && docker image prune -af"; 
} | crontab -
