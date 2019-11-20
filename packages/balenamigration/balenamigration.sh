#!/bin/bash

server_path='http://10.0.0.210/balenaos'
file_test_conection='balenamigration'
file_resin_mbr='balena-init-60.mbr.gz'
file_resin_rootA='p2-resin-rootA.img.gz'
file_resin_rootB='p3-resin-rootB.img.gz'
file_resin_state='p5-resin-state.img.gz'
file_resin_data='p6-resin-data.img.gz'
file_resin_boot='p1-resin-boot-60M.img.gz'
file_config_json='BalenaMigration.config.json'
attempt_counter=0
max_attempts=5

function logmsg {
	echo $1 | tee /dev/kmsg | tee -a /tmp/logBalenaMigration
	return 0
}

logmsg "BalenaMigration: Init [OK]"
touch /tmp/balenaMigration_Init

mkdir -p /tmp/ramdisk && mount -t tmpfs -o size=400M tmpramdisk /tmp/ramdisk && cd /tmp/ramdisk && \
logmsg "BalenaMigration: Ramdisk [OK]"
touch /tmp/balenaMigration_Ramdisk

# until $(curl --output /dev/null --silent --head --fail 10.0.0.210/balenaos/balenamigration); do
until $(wget --tries=10 --timeout=10 --spider "$server_path/$file_test_conection"); do
	if [ ${attempt_counter} -eq ${max_attempts} ];then
		logmsg "BalenaMigration: Network [ERROR]"
		touch /tmp/balenaMigration_Network_ERROR
		exit 1
    fi

    attempt_counter=$(($attempt_counter+1))
	logmsg "BalenaMigration: Network attempt ${attempt_counter} [FAIL]"
    sleep 10
done

wget --spider "$server_path/$file_test_conection"

if [[ $? -eq 0 ]]; then
	logmsg "BalenaMigration: Network [OK]"
	touch /tmp/balenaMigrationNetwork_OK
	
	wget "$server_path/$file_resin_mbr" && gunzip -c $file_resin_mbr | sfdisk /dev/mmcblk0 && rm $file_resin_mbr && \
	logmsg "BalenaMigration: MBR [OK]" && \
	wget "$server_path/$file_resin_rootA" && gunzip -c $file_resin_rootA | dd of=/dev/mmcblk0p2 status=progress bs=4M && rm $file_resin_rootA && \
	logmsg "BalenaMigration: RootA [OK]" && \
	wget "$server_path/$file_resin_rootB" && gunzip -c $file_resin_rootB | dd of=/dev/mmcblk0p3 status=progress bs=4M && rm $file_resin_rootB && \
	logmsg "BalenaMigration: RootB [OK]" && \
	wget "$server_path/$file_resin_state" && gunzip -c $file_resin_state | dd of=/dev/mmcblk0p5 status=progress bs=4M && rm $file_resin_state && \
	logmsg "BalenaMigration: State [OK]" && \
	wget "$server_path/$file_resin_data"  && gunzip -c $file_resin_data  | dd of=/dev/mmcblk0p6 status=progress bs=4M && rm $file_resin_data && \
	logmsg "BalenaMigration: Data [OK]" && \
	wget "$server_path/$file_resin_boot"  && gunzip -c $file_resin_boot  | dd of=/dev/mmcblk0p1 status=progress bs=4M && rm $file_resin_boot && \
	logmsg "BalenaMigration: Boot [OK]" && \
	mkdir -p /mnt/boot && mount /dev/mmcblk0p1 /mnt/boot/ && wget "$server_path/$file_config_json" && cp $file_config_json /mnt/boot/config.json && \
	logmsg "BalenaMigration: Config [OK]" && \
	logmsg "BalenaMigration: End [OK]" && \
	touch /tmp/balenaMigration_Successful || \
	logmsg "BalenaMigration: End [FAIL]"
else
	logmsg "BalenaMigration: Network [FAIL]"
	touch /tmp/balenaMigration_Network_FAIL
fi

logmsg "BalenaMigration: Finish [OK]"
touch /tmp/balenaMigration_Finish

sleep 10

#exec /sbin/reboot
