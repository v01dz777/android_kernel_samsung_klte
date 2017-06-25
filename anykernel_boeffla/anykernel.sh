# AnyKernel2 Script
#
# Original and credits: osm0sis @ xda-developers
#
# Modified by Lord Boeffla, 05.12.2016

############### AnyKernel setup start ############### 

# EDIFY properties
do.devicecheck=1
do.initd=0
do.modules=1
do.cleanup=1
device.name1=kltexx
device.name2=kltelra
device.name3=kltetmo
device.name4=kltecan
device.name5=klteatt
device.name6=klteub
device.name7=klteacg
device.name8=klte
device.name9=kltekor
device.name10=klteskt
device.name11=kltektt
device.name12=kltedcm
device.name13=kltekdi
device.name14=
device.name15=

# shell variables
block=/dev/block/platform/msm_sdcc.1/by-name/boot;
add_seandroidenforce=1
supersu_exclusions=""
is_slot_device=0;

############### AnyKernel setup end ############### 

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. /tmp/anykernel/tools/ak2-core.sh;

# dump current kernel
dump_boot;

############### Ramdisk customization start ###############

# AnyKernel permissions
chmod 775 $ramdisk/sbin
chmod 755 $ramdisk/sbin/busybox

chmod 775 $ramdisk/res
chmod -R 755 $ramdisk/res/bc
chmod -R 755 $ramdisk/res/misc

# ramdisk changes
# Felica
insert_line init.qcom.rc "import init.carrier.rc" after "import init.qcom.usb.rc" "import init.carrier.rc";
insert_line ueventd.qcom.rc "#JPN FeliCa" "/sys/devices/i2c.73/i2c-16/16-0018/input/input* delay 0664 system system" after "#JPN FeliCa";
insert_line ueventd.qcom.rc "/dev/felica               0666    root   system" after "#JPN FeliCa" "/dev/felica               0666    root   system";
insert_line ueventd.qcom.rc "/dev/felica_pon           0666    root   system" after "/dev/felica               0666    root   system" "/dev/felica_pon           0666    root   system";
insert_line ueventd.qcom.rc "/dev/felica_cen           0666    root   system" after "/dev/felica_pon           0666    root   system" "/dev/felica_cen           0666    root   system";
insert_line ueventd.qcom.rc "/dev/felica_rfs           0444    root   system" after "/dev/felica_cen           0666    root   system" "/dev/felica_rfs           0444    root   system";
insert_line ueventd.qcom.rc "/dev/felica_rws           0666    root   system" after "/dev/felica_rfs           0444    root   system" "/dev/felica_rws           0666    root   system";
insert_line ueventd.qcom.rc "/dev/felica_ant           0666    root   system" after "/dev/felica_rws           0666    root   system" "/dev/felica_ant           0666    root   system";
insert_line ueventd.qcom.rc "/dev/felica_int_poll      0400    root   system" after "/dev/felica_ant           0666    root   system" "/dev/felica_int_poll      0400    root   system";
insert_line ueventd.qcom.rc "/dev/felica_uid           0222    root   system" after "/dev/felica_int_poll      0400    root   system" "/dev/felica_uid           0222    root   system";
insert_line ueventd.qcom.rc "/dev/felica_uicc          0666    root   system" after "/dev/felica_uid           0222    root   system" "/dev/felica_uicc          0666    root   system";

############### Ramdisk customization end ###############

# write new kernel
write_boot;
