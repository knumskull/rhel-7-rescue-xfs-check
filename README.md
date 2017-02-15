# Description
Scripts for creating a bootable image based on RHEL-7-boot image.

# Usage

* Download RHEL 7 boot image (`rhel-server-7.3-x86_64-boot.iso`) from <https://access.redhat.com/downloads/content/69/>
* Define variable `ISO` in `create-iso.sh` script
* run script with `root`-rights. `sudo bash create-iso.sh`
* mount the created `rhel-7-rescue.iso` image and boot from cdrom


# Disclaimer
There is no warranty on success by using these scripts. You will use these scripts on your own risk.
