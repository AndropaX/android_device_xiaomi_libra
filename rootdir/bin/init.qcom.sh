#!/system/bin/sh

start_copying_prebuilt_qcril_db()
{
    if [ -f /system/vendor/qcril.db -a ! -f /data/misc/radio/qcril.db ]; then
        cp /system/vendor/qcril.db /data/misc/radio/qcril.db
        chown -h radio.radio /data/misc/radio/qcril.db
    fi
}

start_copying_prebuilt_qcril_db

#
# Make modem config folder and copy firmware config to that folder
#
rm -rf /data/misc/radio/modem_config
mkdir /data/misc/radio/modem_config
chmod 770 /data/misc/radio/modem_config
cp -r /firmware/image/modem_pr/mcfg/configs/* /data/misc/radio/modem_config
chown -hR radio.radio /data/misc/radio/modem_config
echo 1 > /data/misc/radio/copy_complete
