#!/bin/bash
#
# Oxygen Kernel Build Script By @Siddhant Naik 
# Do Not Use Without My Permission!!
# (C) @Siddhant Naik

##############
# Parameters #
##############
ROOT_DIR=$(pwd)
KERNEL_NAME='Oxygen-Kernel'
ARCHITECTURE=arm64
TOOLCHAIN=~/Toolchains/aarch64-cortex_a53-linux-gnueabi/bin/aarch64-cortex_a53-linux-gnueabi-
ANDROID=N
BUILD_DIR=$ROOT_DIR/oxygen
ZIP_DIR=$BUILD_DIR/zip
AIK_DIR=$BUILD_DIR/Android-Image-Kitchen
RAMDISK_DIR=$BUILD_DIR/ramdisk

#############################   #
# Device Specific Functions #   # Add support for devices by creating functions in the following pattern
#############################   #

j7_prime() #Device 1
{
	DEVICE='J7-Prime'
	DEFCONFIG=Oxygen_on7xelte_defconfig
	DTSFILES="exynos7870-on7xelte_swa_open_00 exynos7870-on7xelte_swa_open_01 exynos7870-on7xelte_swa_open_02"
}

j7_2016()  #Device 2
{
	DEVICE='J7-2016'
	DEFCONFIG=Oxygen_j7xelte_defconfig
	DTSFILES="exynos7870-j7xelte_eur_open_00 exynos7870-j7xelte_eur_open_01 exynos7870-j7xelte_eur_open_02 exynos7870-j7xelte_eur_open_03 exynos7870-j7xelte_eur_open_04"
}

j7_pro()   #Device 3
{
	DEVICE='J7-Pro'
	DEFCONFIG=Oxygen_j7y17lte_defconfig
	DTSFILES="exynos7870-j7y17lte_eur_openm_00 exynos7870-j7y17lte_eur_openm_01 exynos7870-j7y17lte_eur_openm_02 exynos7870-j7y17lte_eur_openm_03 exynos7870-j7y17lte_eur_openm_04 exynos7870-j7y17lte_eur_openm_05 exynos7870-j7y17lte_eur_openm_06 exynos7870-j7y17lte_eur_openm_07"
}

j7_nxt()   #Device 4
{
	DEVICE='J7-Nxt'
	DEFCONFIG=Oxygen_j7velte_defconfig
	DTSFILES="exynos7870-j7velte_sea_open_00 exynos7870-j7velte_sea_open_01 exynos7870-j7velte_sea_open_03"
}

tab_a()    #Device 5
{
	DEVICE='Tab-A-10.1'
	DEFCONFIG=Oxygen_gtaxllte_defconfig
	DTSFILES="exynos7870-gtaxllte_eur_open_00 exynos7870-gtaxllte_eur_open_01 exynos7870-gtaxllte_eur_open_04 exynos7870-gtaxllte_eur_open_05"
}

###########################
# Setup Build Environment #
###########################

printf '\033[8;50;150t'
NUM_CPUS=`grep -c ^processor /proc/cpuinfo`
export ARCH=$ARCHITECTURE
export CROSS_COMPILE=$TOOLCHAIN
export ANDROIDVERSION=$ANDROID
DATE=$(date +%d' '%b' '%Y)

#################
# Setup Colours #
#################

RED="\033[0;31m"
GREEN="\033[1;32m"
DEFAULT="\033[0m"

#############
# Functions #
#############

clean_residue()
{
	echo -e $GREEN"Cleaning Residuals\n"$DEFAULT
	rm -r $AIK_DIR/ramdisk
	rm -r $AIK_DIR/split_img
	rm -rf $AIK_DIR/ramdisk-new.cpio.gz
	rm -r $ZIP_DIR/META-INF
	rm -r $ZIP_DIR/boot.img
}

clean_junk()
{
	echo -e $GREEN"Cleaning Previous Build Junk\n"$DEFAULT
	rm -rf $BUILD_DIR/*log
	rm -rf $ZIP_DIR/z*
	rm -rf $ZIP_DIR/*.zip
	rm -rf $ZIP_DIR/boot.img
	rm -rf $RAMDISK_DIR/*/split_img/boot.img-zImage
	rm -rf $RAMDISK_DIR/*/split_img/boot.img-dtb
	rm -rf $ZIP_DIR/oxygenkernel/anykernel2/anykernel2.zip
	rm -rf $ROOT_DIR/crypto/ansi_cprng.ko
}

clean_dir()
{
	echo -e $RED"Cleaning Directory\n"$DEFAULT
	make clean && make mrproper
	clean_junk
}

build()
{
	KERNEL_VERSION=$(<$BUILD_DIR/version/$DEVICE)
	rm -rf $ROOT_DIR/crypto/ansi_cprng.ko
	rm -rf $RAMDISK_DIR/*/ramdisk/lib/modules/ansi_cprng.ko
	echo -e "\n==============================================================================================================================================="
	echo " Device      =   $DEVICE "
	echo " Defconfig   =   $DEFCONFIG "
	echo " Version     =   $KERNEL_VERSION "
	echo -e "===============================================================================================================================================\n"
	echo -e $GREEN"Starting Build Process for $DEVICE\n"$DEFAULT
	clean_junk
	build_kernel
	build_anykernel
	build_zip
}

build_kernel()
{
	# Setup Kernel Defconfig
	echo -e $GREEN"Setting Up Defconfig $DEFCONFIG\n"$DEFAULT
	echo
	make $DEFCONFIG
	sed -i "s;##VERSION##;$KERNEL_VERSION;" .config;
	
	# Build Image
	echo -e $GREEN"\nStarting To Build Image\n"$DEFAULT
	time make -j$NUM_CPUS 2>&1 |tee $BUILD_DIR/build_kernel.log
	
	# Check If Kernel Is Built
	if [ -e $ROOT_DIR/arch/arm64/boot/Image ]; then
		echo -e $GREEN"Kernel Sussfully Built\n"$DEFAULT
	else
		echo -e $RED"Kernel Build Failed\n"$DEFAULT
		read -p "Press any key to exit " option
		case "$option" in
			*)
				exit
				;;
		esac
	fi
	echo -e $GREEN"Starting To Build Image\n"$DEFAULT

	# Build DTB
	mkdir -p $ROOT_DIR/arch/arm64/boot/dtb && cd $ROOT_DIR/arch/arm64/boot/dtb && rm -rf *
	echo -e $GREEN"Starting To Build DTB\n"$DEFAULT
	for dts in $DTSFILES; do
		echo "=> Processing: ${dts}.dts"
		${CROSS_COMPILE}cpp -nostdinc -undef -x assembler-with-cpp -I "$ROOT_DIR/include" "$ROOT_DIR/arch/arm64/boot/dts/${dts}.dts" > "${dts}.dts"
		echo "=> Generating: ${dts}.dtb"
		$ROOT_DIR/scripts/dtc/dtc -p 0 -i "$ROOT_DIR/arch/arm64/boot/dts" -O dtb -o "${dts}.dtb" "${dts}.dts"
	done
	$ROOT_DIR/scripts/dtbTool/dtbTool -o "$ROOT_DIR/arch/arm64/boot/dtb.img" -d "$ROOT_DIR/arch/arm64/boot/dtb/" -s 2048
	echo -e $GREEN"DTB Generated\n"$DEFAULT
}

build_anykernel()
{
	echo -e $GREEN"Building AnyKernel Zip File\n"$DEFAULT
	cd $BUILD_DIR/anykernel2
	zip -gq anykernel2.zip -r * -x "*~"
	mv anykernel2.zip $ZIP_DIR/oxygenkernel/anykernel2/anykernel2.zip
}

build_zip()
{
	# Build Ramdisk && boot.img
	echo -e $GREEN"Building boot.img\n"$DEFAULT
	mv $ROOT_DIR/arch/arm64/boot/Image $RAMDISK_DIR/$DEVICE/split_img/boot.img-zImage
	mv $ROOT_DIR/arch/arm64/boot/dtb.img $RAMDISK_DIR/$DEVICE/split_img/boot.img-dtb
	cp -r $RAMDISK_DIR/$DEVICE/* $AIK_DIR
	if [ -e $ROOT_DIR/crypto/ansi_cprng.ko ]; then
	mv $ROOT_DIR/crypto/ansi_cprng.ko $AIK_DIR/ramdisk/lib/modules/ansi_cprng.ko
	fi
	cd $AIK_DIR
	find . -name \.placeholder -type f -delete
	./repackimg.sh
	echo SEANDROIDENFORCE >> image-new.img
	mv image-new.img $ZIP_DIR/boot.img
	echo 

	# Append Version Info
	cp -r $BUILD_DIR/aroma/META-INF $ZIP_DIR/META-INF
	cp $BUILD_DIR/aroma/changelogs/$DEVICE.txt $ZIP_DIR/META-INF/com/google/android/aroma/changelog.txt
	sed -i "s;###DATE###;$DATE;" $ZIP_DIR/META-INF/com/google/android/aroma-config;
	sed -i "s;###DEVICE###;$DEVICE;" $ZIP_DIR/META-INF/com/google/android/aroma-config;
	sed -i "s;###VERSION###;$KERNEL_VERSION;" $ZIP_DIR/META-INF/com/google/android/aroma-config;
	
	# Build Zip File
	echo -e $GREEN"Building Zip File\n"$DEFAULT
	cd $ZIP_DIR
	ZIPNAME=$KERNEL_NAME-$DEVICE-v$KERNEL_VERSION.zip
	zip -gq $ZIPNAME -r * -x "*~"
	mv -f $ZIPNAME $BUILD_DIR/$ZIPNAME
	cd $ROOT_DIR
	
	# Check If Zip Is Built
	if [ -e $BUILD_DIR/$ZIPNAME ]; then
		echo -e $GREEN"Kernel Build Finished Successfully\n"$DEFAULT
	else
		echo -e $RED"Zip Build Failed\n"$DEFAULT
	fi
	
	# Clean AIK Directory
	clean_residue
}

################
# Main Program #
################
clear
echo
echo "==============================================================================================================================================="
echo "                                                   $KERNEL_NAME Build Menu" 
echo "                                                          $DATE"
echo "==============================================================================================================================================="
echo 
echo "	  	      0  = Clean Directory             |     l  = Open Build_kernel.log"
echo "		      1  = Build Kernel for J7 Prime   |" 
echo "		      2  = Build Kernel for J7 2016    |"
echo "		      3  = Build Kernel for J7 Pro     |"
echo "		      4  = Build Kernel for J7 Nxt     |"
echo "		      5  = Build Kernel for Tab A 10.1 |"
echo 
echo -e "===============================================================================================================================================\n"
read -p "Select an option " option
case "$option" in
	0)
		clean_dir
		;;
	1)
		clear
		j7_prime
		build
		;;
	2)
		clear
		j7_2016
		build
		;;
	3)
		clear
		j7_pro
		build
		;;
	4)
		clear
		j7_nxt
		build
		;;
	5)
		clear
		tab_a
		build
		;;
	l)
		gedit $BUILD_DIR/build_kernel.log
		. build.sh
		;;
esac
