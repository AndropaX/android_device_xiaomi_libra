#!/system/bin/sh
# Copyright (c) 2012-2013, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

target=`getprop ro.board.platform`

function write() {
    echo -n $2 > $1
}

function copy() {
    cat $1 > $2
}

function get-set-forall() {
    for f in $1 ; do
        cat $f
        write $f $2
    done
}

function configure_memory_parameters() {
# Set Memory paremeters.
#
# Set Low memory killer minfree parameters
# 64 bit all memory configurations will use 18K series
#
# Set ALMK parameters (usually above the highest minfree values)
# 64 bit will have 81K
#

    arch_type=`uname -m`
    MemTotalStr=`cat /proc/meminfo | grep MemTotal`
    MemTotal=${MemTotalStr:16:8}

    echo 0 > /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk

    if [ "$arch_type" == "aarch64" ] && [ $MemTotal -gt 2097152 ]; then
        echo "18432,23040,27648,32256,55296,80640" > /sys/module/lowmemorykiller/parameters/minfree
        echo 81250 > /sys/module/lowmemorykiller/parameters/vmpressure_file_min
    elif [ "$arch_type" == "aarch64" ] && [ $MemTotal -gt 1048576 ]; then
        echo 1 > /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk
        echo "18432,23040,27648,32256,55296,80640" > /sys/module/lowmemorykiller/parameters/minfree
        echo 81250 > /sys/module/lowmemorykiller/parameters/vmpressure_file_min
    fi

    # Zram disk - 512MB size
    zram_enable=`getprop ro.config.zram`
    if [ "$zram_enable" == "true" ]; then
        echo 536870912 > /sys/block/zram0/disksize
        mkswap /dev/block/zram0
        swapon /dev/block/zram0 -p 32758
    fi
}

case "$target" in
    "msm8992")
        # take the A57s offline when thermal hotplug is disabled
        write /sys/devices/system/cpu/cpu4/online 0
        write /sys/devices/system/cpu/cpu5/online 0

        # disable thermal bcl hotplug to switch governor
        write /sys/module/msm_thermal/core_control/enabled 0
        get-set-forall /sys/devices/soc.0/qcom,bcl.*/mode disable
        bcl_hotplug_mask=`get-set-forall /sys/devices/soc.0/qcom,bcl.*/hotplug_mask 0`
        bcl_hotplug_soc_mask=`get-set-forall /sys/devices/soc.0/qcom,bcl.*/hotplug_soc_mask 0`
        get-set-forall /sys/devices/soc.0/qcom,bcl.*/mode enable

        # some files in /sys/devices/system/cpu are created after the restorecon of
        # /sys/. These files receive the default label "sysfs".
        # Restorecon again to give new files the correct label.
        restorecon -R /sys/devices/system/cpu

        # Disable CPU retention
        write /sys/module/lpm_levels/system/a53/cpu0/retention/idle_enabled 0
        write /sys/module/lpm_levels/system/a53/cpu1/retention/idle_enabled 0
        write /sys/module/lpm_levels/system/a53/cpu2/retention/idle_enabled 0
        write /sys/module/lpm_levels/system/a53/cpu3/retention/idle_enabled 0
        write /sys/module/lpm_levels/system/a57/cpu4/retention/idle_enabled 0
        write /sys/module/lpm_levels/system/a57/cpu5/retention/idle_enabled 0

        # Disable L2 retention
        write /sys/module/lpm_levels/system/a53/a53-l2-retention/idle_enabled 0
        write /sys/module/lpm_levels/system/a57/a57-l2-retention/idle_enabled 0

        # Setup Little interactive settings
        write /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor interactive
        restorecon -R /sys/devices/system/cpu # must restore after interactive
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_sched_load 1
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_migration_notif 1
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/above_hispeed_delay 19000
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/go_hispeed_load 95
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/timer_rate 19000
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/hispeed_freq 960000
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy 1
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads "65 460800:75 960000:80"
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/min_sample_time 39000
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/max_freq_hysteresis 79000
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/ignore_hispeed_on_notif 1
        write /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq 384000

        # Make sure CPU 4 is only to configure big settings
        write /sys/devices/system/cpu/cpu4/online 1
        restorecon -R /sys/devices/system/cpu # must restore after online

        # Setup Big interactive settings
        write /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor interactive
        restorecon -R /sys/devices/system/cpu # must restore after interactive
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/use_sched_load 1
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/use_migration_notif 1
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/above_hispeed_delay 19000
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/go_hispeed_load 99
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/timer_rate 19000
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/hispeed_freq 1248000
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy 1
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads "70 960000:80 1248000:85"
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/min_sample_time 39000
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/max_freq_hysteresis 79000
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/ignore_hispeed_on_notif 1
        write /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq 384000

        # Configure core_ctl
        write /sys/devices/system/cpu/cpu4/core_ctl/min_cpus 1
        write /sys/devices/system/cpu/cpu4/core_ctl/max_cpus 2
        write /sys/devices/system/cpu/cpu4/core_ctl/busy_up_thres 60
        write /sys/devices/system/cpu/cpu4/core_ctl/busy_down_thres 30
        write /sys/devices/system/cpu/cpu4/core_ctl/offline_delay_ms 100
        write /sys/devices/system/cpu/cpu4/core_ctl/task_thres 4
        write /sys/devices/system/cpu/cpu4/core_ctl/is_big_cluster 1
        chown system:system /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
        chown system:system /sys/devices/system/cpu/cpu4/core_ctl/max_cpus

        write /sys/devices/system/cpu/cpu0/core_ctl/busy_up_thres 0
        write /sys/devices/system/cpu/cpu0/core_ctl/busy_down_thres 0
        write /sys/devices/system/cpu/cpu0/core_ctl/offline_delay_ms 100
        write /sys/devices/system/cpu/cpu0/core_ctl/not_preferred 1

        # Available Freqs in stock kernel
        # Little: 384000 460800 600000 672000 787200 864000 960000 1248000 1440000
        # Big: 384000 480000 633600 768000 864000 960000 1248000 1344000 1440000 1536000 1632000 1689600 1824000
        write /sys/module/cpu_boost/parameters/boost_ms 20
        write /sys/module/cpu_boost/parameters/sync_threshold 960000
        write /sys/module/cpu_boost/parameters/input_boost_freq 0:787200
        write /sys/module/cpu_boost/parameters/input_boost_ms 40

        # b.L scheduler parameters
        write /proc/sys/kernel/sched_migration_fixup 1
        write /proc/sys/kernel/sched_small_task 30
        write /proc/sys/kernel/sched_mostly_idle_load 20
        write /proc/sys/kernel/sched_mostly_idle_nr_run 3
        write /proc/sys/kernel/sched_downmigrate 50
        write /proc/sys/kernel/sched_upmigrate 70
        write /proc/sys/kernel/sched_init_task_load 50
        write /proc/sys/kernel/sched_freq_inc_notify 400000
        write /proc/sys/kernel/sched_freq_dec_notify 400000

        # enable rps static configuration
        write /sys/class/net/rmnet_ipa0/queues/rx-0/rps_cpus 8

        # devfreq
        get-set-forall /sys/class/devfreq/qcom,cpubw*/governor bw_hwmon
        restorecon -R /sys/class/devfreq/qcom,cpubw*
        get-set-forall /sys/class/devfreq/qcom,mincpubw*/governor cpufreq

        # Disable sched_boost
        write /proc/sys/kernel/sched_boost 0

        # set GPU default power level to 5 (180MHz) instead of 4 (305MHz)
        write /sys/class/kgsl/kgsl-3d0/default_pwrlevel 5

        # android background processes are set to nice 10. Never schedule these on the a57s.
        write /proc/sys/kernel/sched_upmigrate_min_nice 9

        # set GPU default governor to msm-adreno-tz
        write /sys/class/devfreq/fdb00000.qcom,kgsl-3d0/governor msm-adreno-tz

        # re-enable thermal and BCL hotplug
        write /sys/module/msm_thermal/core_control/enabled 1
        get-set-forall /sys/devices/soc.0/qcom,bcl.*/mode disable
        get-set-forall /sys/devices/soc.0/qcom,bcl.*/hotplug_mask $bcl_hotplug_mask
        get-set-forall /sys/devices/soc.0/qcom,bcl.*/hotplug_soc_mask $bcl_hotplug_soc_mask
        get-set-forall /sys/devices/soc.0/qcom,bcl.*/mode enable

        # allow CPUs to go in deeper idle state than C0
        write /sys/module/lpm_levels/parameters/sleep_disabled 0
    ;;
esac

chown -h system /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate
chown -h system /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor
chown -h system /sys/devices/system/cpu/cpufreq/ondemand/io_is_busy

emmc_boot=`getprop ro.boot.emmc`
case "$emmc_boot"
    in "true")
        chown -h system /sys/devices/platform/rs300000a7.65536/force_sync
        chown -h system /sys/devices/platform/rs300000a7.65536/sync_sts
        chown -h system /sys/devices/platform/rs300100a7.65536/force_sync
        chown -h system /sys/devices/platform/rs300100a7.65536/sync_sts
    ;;
esac

# Post-setup services
case "$target" in
    "msm8994" | "msm8992")
        rm /data/system/perfd/default_values
        setprop ro.min_freq_0 384000
        setprop ro.min_freq_4 384000
        start perfd
    ;;
esac

case "$target" in
    "msm8226" | "msm8974" | "msm8610" | "apq8084" | "mpq8092" | "msm8610" | "msm8916" | "msm8994" | "msm8992")
        # Let kernel know our image version/variant/crm_version
        image_version="10:"
        image_version+=`getprop ro.build.id`
        image_version+=":"
        image_version+=`getprop ro.build.version.incremental`
        image_variant=`getprop ro.product.name`
        image_variant+="-"
        image_variant+=`getprop ro.build.type`
        oem_version=`getprop ro.build.version.codename`
        echo 10 > /sys/devices/soc0/select_image
        echo $image_version > /sys/devices/soc0/image_version
        echo $image_variant > /sys/devices/soc0/image_variant
        echo $oem_version > /sys/devices/soc0/image_crm_version
        ;;
esac

# Enable QDSS agent if QDSS feature is enabled
# on a non-commercial build.  This allows QDSS
# debug tracing.
if [ -c /dev/coresight-stm ]; then
    build_variant=`getprop ro.build.type`
    if [ "$build_variant" != "user" ]; then
        # Test: Is agent present?
        if [ -f /data/qdss/qdss.agent.sh ]; then
            # Then tell agent we just booted
           /system/bin/sh /data/qdss/qdss.agent.sh on.boot &
        fi
    fi
fi

# Start RIDL/LogKit II client
#su -c /system/vendor/bin/startRIDL.sh &
