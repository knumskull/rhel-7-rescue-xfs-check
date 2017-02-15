#!/bin/bash


## We need to check all vd-devices

# check all xfs-filesystems
list_xfs_fs () {
  blkid | grep xfs | cut -d":" -f1 | grep vd
}


# check volume-groups
list_lvm_devices () {
  blkid | grep LVM2_member | cut -d":" -f1 | grep vd
}

list_lvm_vgs () {
    for PV in $(list_lvm_devices); do
    lvm pvs | grep ${PV} | awk -F" " '{print $2}'
  done
}

activate_lvm_vg () {
  for VG in $(list_lvm_vgs); do
    lvm vgchange -ay ${VG}
  done

}

list_lvm_lvs () {
  for VG in $(list_lvm_vgs); do
    for LV in $(lvm lvs | grep ${VG} | grep -v swap | awk -F" " '{print $1}'); do
      echo "/dev/mapper/${VG}-${LV}"
    done
  done
}

# check if all files are unmounted
check_mounted () {
  device=$1
  mount | grep ${device} >/dev/null; echo $?
}

mount_cycle () {
  DEV=$1
  if [ 0 -eq $(check_mounted ${DEV}) ]; then
    umount ${DEV}
  fi
  if [ ! -d /mnt ]; then
    mkdir /mnt
  fi
  if [ 0 -eq $(mount ${device} /mnt >/dev/null; echo $?) ]; then
    umount ${device}
  else
    exit 1
  fi
}

repair_device () {
  device=$1
  dev_name=${device##/dev*/}
  mount_cycle ${device}
  if [ $? -eq 0 ]; then 
    xfs_repair -n ${device} > xfs-check.${dev_name}.log 2>&1; echo $?
  fi
}

# 1. repair all xfs volumes, which are no LVM-member
# 2. 
ERROR_FOUND=0

for DEV in $(list_xfs_fs); do 
  if [ "0" != "$(repair_device ${DEV})" ]; then
    ERROR_FOUND=1
    break
  fi
done

activate_lvm_vg

for DEV in $(list_lvm_lvs); do
  if [ "0" != "$(repair_device ${DEV})" ]; then
    ERROR_FOUND=1
    break
  fi
done

if [ 0 -eq $ERROR_FOUND ]; then 
  #_emergency_action=halt
  #exit 1
  systemctl isolate poweroff.target
else
  echo " ##########################################################"
  echo " # XFS-ERROR detected. There is one drive with XFS-errors #"
  echo " # Please run 'xfs_repair' manually on all your drives    #"
  echo " ##########################################################"
  exec sh -i -l
fi
