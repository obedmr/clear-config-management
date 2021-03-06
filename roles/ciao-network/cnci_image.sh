#!/bin/bash

# Variables
image_url=$1
image=${image_url##*/}
image=${image%*.xz}

if [ ! -f $image ] && [ ! -f ${image}.xz ] ; then
  curl -Ok $image_url
fi

if [ ! -f $image ] ; then
  unxz ${image}.xz
fi

#Defaults
certs_dir=/etc/pki/ciao
partition=2

echo -e "\nMounting image: $image"
mkdir -p /mnt/tmp
modprobe nbd max_part=63
qemu-nbd -c /dev/nbd0 "$image" -f raw
mount /dev/nbd0p$partition /mnt/tmp

echo -e "Installing the service"
mkdir -p /mnt/tmp/etc/systemd/system/default.target.wants
chroot /mnt/tmp /bin/bash -c "ln -s /usr/lib/systemd/system/cnci-agent.service /etc/systemd/system/default.target.wants/"

echo -e "Copying CA certificates"
sudo mkdir -p /mnt/tmp/var/lib/ciao/
sudo cp "$certs_dir"/CAcert-* /mnt/tmp/var/lib/ciao/CAcert-server-localhost.pem

echo -e "Copying CNCI Agent certificate"
sudo cp "$certs_dir"/cert-CNCIAgent-* /mnt/tmp/var/lib/ciao/cert-client-localhost.pem

echo -e "Removing cloud-init traces"
sudo rm -rf /mnt/tmp/var/lib/cloud

#Umount
echo -e "Done! unmounting\n"
sudo umount /mnt/tmp
sudo qemu-nbd -d /dev/nbd0

mkdir -p /var/lib/ciao/images
mv ${image} /var/lib/ciao/images
exit 0
