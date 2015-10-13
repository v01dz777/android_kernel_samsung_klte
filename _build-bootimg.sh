#!/bin/bash

KERNEL_DIR=$PWD

if [ "$BUILD_TARGET" = 'RECO' ]; then
IMAGE_NAME=recovery
else
IMAGE_NAME=boot
fi

BIN_DIR=out/$TARGET_DEVICE/$BUILD_TARGET/bin
OBJ_DIR=out/$TARGET_DEVICE/$BUILD_TARGET/obj
mkdir -p $BIN_DIR
mkdir -p ${OBJ_DIR}

. build_func
. mod_version
. cross_compile

# jenkins build number
if [ -n "$BUILD_NUMBER" ]; then
export KBUILD_BUILD_VERSION="$BUILD_NUMBER"
fi

if [ "$BUILD_TARGET" = 'RECO' ]; then
  RECOVERY_VERSION=recovery_version
  if [ -f $RAMDISK_SRC_DIR/recovery_version ]; then
    RECOVERY_VERSION=$RAMDISK_SRC_DIR/recovery_version
  fi
  . $RECOVERY_VERSION
  BUILD_LOCALVERSION=$BUILD_RECOVERYVERSION
fi

# set build env
export ARCH=arm
export CROSS_COMPILE=$BUILD_CROSS_COMPILE
export LOCALVERSION="-$BUILD_LOCALVERSION"

echo ""
echo "====================================================================="
echo "    BUILD START (KERNEL VERSION $BUILD_KERNELVERSION-$BUILD_LOCALVERSION)"
echo "    toolchain: ${BUILD_CROSS_COMPILE}"
echo "====================================================================="

if [ ! -n "$1" ]; then
  echo ""
  read -p "select build? [(a)ll/(u)pdate/(i)mage default:update] " BUILD_SELECT
else
  BUILD_SELECT=$1
fi

# copy RAMDISK
echo ""
echo "=====> COPY RAMDISK"
copy_ramdisk


# make start
if [ "$BUILD_SELECT" = 'all' -o "$BUILD_SELECT" = 'a' ]; then
  echo ""
  echo "=====> CLEANING..."
  make clean
  echo "=====> GENERATE DEFCONFIG..."
  if [ "$BUILD_TARGET" = 'RECO' ]; then
    make -C $PWD O=${OBJ_DIR} msm8974_sec_defconfig VARIANT_DEFCONFIG=$KERNEL_DEFCONFIG SELINUX_DEFCONFIG=selinux_defconfig || exit -1
  else
    make -C $PWD O=${OBJ_DIR} msm8974_sec_defconfig VARIANT_DEFCONFIG=$KERNEL_DEFCONFIG || exit -1
  fi
fi

if [ "$BUILD_SELECT" != 'image' -a "$BUILD_SELECT" != 'i' ]; then
  echo ""
  echo "=====> BUILDING..."
  if [ -e make.log ]; then
    mv make.log make_old.log
  fi
  nice -n 10 make O=${OBJ_DIR} -j12 2>&1 | tee make.log || exit -1
fi

# append dtb
KERNEL_ZIMG=${OBJ_DIR}/arch/arm/boot/zImage
DTC=${OBJ_DIR}/scripts/dtc/dtc
DTS_NAMES=msm8974pro-ac-sec-kjpn-

if ! [ -d ${OBJ_DIR}/arch/arm/boot ] ; then
  echo "error no directory : "${OBJ_DIR}/arch/arm/boot""
  exit -1
else
  echo "rm files in : "${OBJ_DIR}/arch/arm/boot/*-zImage""
  rm ${OBJ_DIR}/arch/arm/boot/*-zImage
  echo "rm files in : "${OBJ_DIR}/arch/arm/boot/*.dtb""
  rm ${OBJ_DIR}/arch/arm/boot/*.dtb
fi

for DTS_FILE in `ls ./arch/arm/boot/dts/msm8974pro/${DTS_NAMES}*.dts`
do
  DTB_FILE=${DTS_FILE%.dts}.dtb
  DTB_FILE=${OBJ_DIR}/arch/arm/boot/${DTB_FILE##*/}
  ZIMG_FILE=${DTB_FILE%.dtb}-zImage

  echo ""
  echo "dts : $DTS_FILE"
  echo "dtb : $DTB_FILE"
  echo "out : $ZIMG_FILE"
  echo ""

  $DTC -p 1024 -O dtb -o $DTB_FILE $DTS_FILE
  cat $KERNEL_ZIMG $DTB_FILE > $ZIMG_FILE
done

# build DT image
INSTALLED_DTIMAGE_TARGET=${OBJ_DIR}/dt.img
DTBTOOL=./release-tools/dtbToolCM

echo "DT image target : $INSTALLED_DTIMAGE_TARGET"
echo "$DTBTOOL -o $INSTALLED_DTIMAGE_TARGET -s $KERNEL_PAGESIZE \
    -p ${OBJ_DIR}/scripts/dtc/ ${OBJ_DIR}/arch/arm/boot/"
$DTBTOOL -o $INSTALLED_DTIMAGE_TARGET -s $KERNEL_PAGESIZE \
    -p ${OBJ_DIR}/scripts/dtc/ ${OBJ_DIR}/arch/arm/boot/
chmod a+r $INSTALLED_DTIMAGE_TARGET

echo ""
echo "=====> CREATE RELEASE IMAGE"
# clean release dir
if [ `find $BIN_DIR -type f | wc -l` -gt 0 ]; then
  rm -rf $BIN_DIR/*
fi
mkdir -p $BIN_DIR

# copy zImage -> kernel
cp ${OBJ_DIR}/arch/arm/boot/zImage $BIN_DIR/kernel
cp $INSTALLED_DTIMAGE_TARGET $BIN_DIR/dt.img

# create boot image
make_boot_image

#check image size
img_size=`wc -c $BIN_DIR/$IMAGE_NAME.img | awk '{print $1}'`
if [ $img_size -gt $IMG_MAX_SIZE ]; then
    echo "FATAL: $IMAGE_NAME image size over. image size = $img_size > $IMG_MAX_SIZE byte"
#    rm $BIN_DIR/$IMAGE_NAME.img
    exit -1
fi

cd $BIN_DIR

# create odin image
make_odin3_image
# create install package
make_cwm_image

cd $KERNEL_DIR

echo ""
echo "====================================================================="
echo "    BUILD COMPLETED"
echo "====================================================================="
exit 0
