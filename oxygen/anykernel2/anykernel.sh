# -------------------------------
# OXYEGN AROMA INSTALLER v1.0
# anykernel2 portion
#
# Anykernel2 created by #osm0sis
# Adapted for Oxygen by @SiddhantNaik
# Everything else done by @djb77
# DO NOT USE ANY PORTION OF THIS
# CODE WITHOUT MY PERMISSION!!
# -------------------------------

## AnyKernel setup
# Begin Properties
properties() {
do.devicecheck=0
do.modules=0
do.cleanup=1
do.cleanuponabort=1
} # end properties

# Extra 0's needed for CPU Freqs
ZEROS=000

# Shell Variables
block=/dev/block/platform/13540000.dwmmc0/by-name/BOOT;
is_slot_device=0;

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. /tmp/anykernel/tools/ak2-core.sh;

## AnyKernel install
ui_print "- Extracing Boot Image";
dump_boot;

# Ramdisk changes - Modded / New Files
ui_print "- Adding Oxygen Mods";
replace_file sbin/resetprop 755 oxygen/sbin/resetprop;
replace_file sbin/initd.sh 755 oxygen/sbin/initd.sh;
replace_file sbin/kernelinit.sh 755 oxygen/sbin/kernelinit.sh;
replace_file sbin/wakelock.sh 755 oxygen/sbin/wakelock.sh;
replace_file init.services.rc 755 oxygen/init.services.rc;

# Ramdisk changes - init.rc
insert_line init.rc "import /init.services.rc" after "import /init.fac.rc" "import /init.services.rc";

# Ramdisk changes - Spectrum
if egrep -q "install=1" "/tmp/aroma/spectrum.prop"; then
	ui_print "- Adding Spectrum";
	replace_file sbin/spa 755 spectrum/spa;
	replace_file init.spectrum.rc 644 spectrum/init.spectrum.rc;
	replace_file init.spectrum.sh 644 spectrum/init.spectrum.sh;
	insert_line init.rc "import /init.spectrum.rc" after "import /init.services.rc" "import /init.spectrum.rc";
fi;

# Ramdisk changes - SELinux (Fake) Enforcing Mode
if egrep -q "install=1" "/tmp/aroma/selinux.prop"; then
	ui_print "- Enabling SELinux Enforcing Mode";
	replace_string sbin/kernelinit.sh "echo \"1\" > /sys/fs/selinux/enforce" "echo \"0\" > /sys/fs/selinux/enforce" "echo \"1\" > /sys/fs/selinux/enforce";
fi;

# Ramdisk Advanced Options
if egrep -q "install=1" "/tmp/aroma/advanced.prop"; then

# Ramdisk changes for CPU Governors
	sed -i -- "s/governor-big=//g" /tmp/aroma/governor-big.prop
	GOVERNOR_BIG=`cat /tmp/aroma/governor-big.prop`
	if [[ "$GOVERNOR_BIG" != "interactive" ]]; then
		ui_print "- Setting CPU Freq Governor to $GOVERNOR_BIG";
		insert_line sbin/kernelinit.sh "echo $GOVERNOR_BIG > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor" after "# Customisations" "echo $GOVERNOR_BIG > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor";
		insert_line sbin/kernelinit.sh "echo $GOVERNOR_BIG > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" after "# Customisations" "echo $GOVERNOR_BIG > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor";
	fi

# Ramdisk changes for CPU Max Freq
	sed -i -- "s/cpumax-big=//g" /tmp/aroma/cpumax-big.prop
	CPUMAX_BIG=`cat /tmp/aroma/cpumax-big.prop`
		ui_print "- Setting Max CPU Freq to $CPUMAX_BIG Mhz";
		WORKVAL1=$CPUMAX_BIG$ZEROS
		insert_line sbin/kernelinit.sh "echo $WORKVAL1 > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq" after "# Customisations" "echo $WORKVAL1 > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq";
		insert_line sbin/kernelinit.sh "echo $WORKVAL1 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq" after "# Customisations" "echo $WORKVAL1 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq";

# Ramdisk changes for CPU Min Freq
	sed -i -- "s/cpumin-big=//g" /tmp/aroma/cpumin-big.prop
	CPUMIN_BIG=`cat /tmp/aroma/cpumin-big.prop`
		ui_print "- Setting Min CPU Freq to $CPUMIN_BIG Mhz";
		WORKVAL2=$CPUMIN_BIG$ZEROS
		insert_line sbin/kernelinit.sh "echo $WORKVAL2 > /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq" after "# Customisations" "echo $WORKVAL2 > /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq";
		insert_line sbin/kernelinit.sh "echo $WORKVAL2 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq" after "# Customisations" "echo $WORKVAL2 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq";

# Ramdisk changes for GPU Max Freq
	sed -i -- "s/gpumax=//g" /tmp/aroma/gpumax.prop
	GPUMAX=`cat /tmp/aroma/gpumax.prop`
		ui_print "- Setting Max GPU Freq to $GPUMAX Mhz";
		insert_line sbin/kernelinit.sh "echo $GPUMAX > /sys/devices/11400000.mali/max_clock" after "# Customisations" "echo $GPUMAX > /sys/devices/11400000.mali/max_clock";

# Ramdisk changes for GPU Min Freq
	sed -i -- "s/gpumin=//g" /tmp/aroma/gpumin.prop
	GPUMIN=`cat /tmp/aroma/gpumin.prop`
		ui_print "- Setting Min GPU Freq to $GPUMIN Mhz";
		insert_line sbin/kernelinit.sh "echo $GPUMIN > /sys/devices/11400000.mali/min_clock" after "# Customisations" "echo $GPUMIN > /sys/devices/11400000.mali/min_clock";

# Ramdisk changes for IO Schedulers (Internal)
	sed -i -- "s/scheduler-internal=//g" /tmp/aroma/scheduler-internal.prop
	SCHEDULER_INTERNAL=`cat /tmp/aroma/scheduler-internal.prop`
		ui_print "- Setting Internal IO Scheduler to $SCHEDULER_INTERNAL";
		insert_line sbin/kernelinit.sh "echo $SCHEDULER_INTERNAL > /sys/block/sda/queue/scheduler" after "# Customisations" "echo $SCHEDULER_INTERNAL > /sys/block/sda/queue/scheduler";

# Ramdisk changes for IO Schedulers (External)
	sed -i -- "s/scheduler-external=//g" /tmp/aroma/scheduler-external.prop
	SCHEDULER_EXTERNAL=`cat /tmp/aroma/scheduler-external.prop`
	if [[ "$SCHEDULER_EXTERNAL" != "cfq" ]]; then
		ui_print "- Setting External IO Scheduler to $SCHEDULER_EXTERNAL";
		insert_line sbin/kernelinit.sh "echo $SCHEDULER_EXTERNAL > /sys/block/mmcblk0/queue/scheduler" after "# Customisations" "echo $SCHEDULER_EXTERNAL > /sys/block/mmcblk0/queue/scheduler";
	fi

# Ramdisk changes for TCP Congestion Algorithms
	sed -i -- "s/tcp=//g" /tmp/aroma/tcp.prop
	TCP=`cat /tmp/aroma/tcp.prop`
	if [[ "$TCP" != "bic" ]]; then
		ui_print "- Setting TCP Congestion Algorithm to $TCP";
		insert_line sbin/kernelinit.sh "echo $TCP > /proc/sys/net/ipv4/tcp_congestion_control" after "# Customisations" "echo $TCP > /proc/sys/net/ipv4/tcp_congestion_control";
	fi
fi

# End ramdisk changes
ui_print "- Writing Boot Image";
write_boot;

## End install