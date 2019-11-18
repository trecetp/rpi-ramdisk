#!/bin/bash

echo "BalenaMigration: Init [OK]" | tee /dev/kmsg | tee -a /tmp/logBalenaMigration
touch /tmp/balenaMigration_Init

mkdir -p /tmp/ramdisk && mount -t tmpfs -o size=400M tmpramdisk /tmp/ramdisk && cd /tmp/ramdisk && \
echo "BalenaMigration: Ramdisk [OK]" | tee /dev/kmsg  | tee -a /tmp/logBalenaMigration
touch /tmp/balenaMigration_Ramdisk

attempt_counter=0
max_attempts=5

# until $(curl --output /dev/null --silent --head --fail 10.0.0.208/balenaos/balenamigration); do
until $(wget --tries=10 --timeout=10 --spider 10.0.0.208/balenaos/balenamigration); do
	if [ ${attempt_counter} -eq ${max_attempts} ];then
		echo "BalenaMigration: Network [ERROR]" | tee /dev/kmsg  | tee -a /tmp/logBalenaMigration
		touch /tmp/balenaMigration_Network_ERROR
		exit 1
    fi

    attempt_counter=$(($attempt_counter+1))
	echo "BalenaMigration: Network attempt ${attempt_counter} [FAIL]" | tee /dev/kmsg  | tee -a /tmp/logBalenaMigration
    sleep 10
done

wget --spider 10.0.0.208/balenaos/balenamigration

if [[ $? -eq 0 ]]; then
	echo "BalenaMigration: Network [OK]" | tee /dev/kmsg  | tee -a /tmp/logBalenaMigration
	touch /tmp/balenaMigrationNetwork_OK
	
	wget 10.0.0.208/balenaos/balena-init-256.mbr.gz && gunzip -c balena-init-256.mbr.gz | sfdisk /dev/mmcblk0 && rm balena-init-256.mbr.gz && \
	echo "BalenaMigration: MBR [OK]" | tee /dev/kmsg  | tee -a /tmp/logBalenaMigration && \
	wget 10.0.0.208/balenaos/p2-resin-rootA.img.gz && gunzip -c p2-resin-rootA.img.gz | dd of=/dev/mmcblk0p2 status=progress bs=4M && rm p2-resin-rootA.img.gz && \
	echo "BalenaMigration: RootA [OK]" | tee /dev/kmsg  | tee -a /tmp/logBalenaMigration && \
	wget 10.0.0.208/balenaos/p3-resin-rootB.img.gz && gunzip -c p3-resin-rootB.img.gz | dd of=/dev/mmcblk0p3 status=progress bs=4M && rm p3-resin-rootB.img.gz && \
	echo "BalenaMigration: RootB [OK]" | tee /dev/kmsg  | tee -a /tmp/logBalenaMigration && \
	wget 10.0.0.208/balenaos/p5-resin-state.img.gz && gunzip -c p5-resin-state.img.gz | dd of=/dev/mmcblk0p5 status=progress bs=4M && rm p5-resin-state.img.gz && \
	echo "BalenaMigration: State [OK]" | tee /dev/kmsg  | tee -a /tmp/logBalenaMigration && \
	wget 10.0.0.208/balenaos/p6-resin-data.img.gz  && gunzip -c p6-resin-data.img.gz  | dd of=/dev/mmcblk0p6 status=progress bs=4M && rm p6-resin-data.img.gz && \
	echo "BalenaMigration: Data [OK]" | tee /dev/kmsg  | tee -a /tmp/logBalenaMigration && \
	wget 10.0.0.208/balenaos/p1-resin-boot.img.gz  && gunzip -c p1-resin-boot.img.gz  | dd of=/dev/mmcblk0p1 status=progress bs=4M && rm p1-resin-boot.img.gz && \
	echo "BalenaMigration: Boot [OK]" | tee /dev/kmsg  | tee -a /tmp/logBalenaMigration && \
	mkdir -p /mnt/boot && mount /dev/mmcblk0p1 /mnt/boot/ && wget 10.0.0.208/balenaos/BalenaMigration.config.json && cp BalenaMigration.config.json /mnt/boot/config.json && \
	echo "BalenaMigration: Config [OK]" | tee /dev/kmsg  | tee -a /tmp/logBalenaMigration
	echo "BalenaMigration: Succesful [OK]" | tee /dev/kmsg  | tee -a /tmp/logBalenaMigration
	touch /tmp/balenaMigration_Successful
else
	echo "BalenaMigration: Network [FAIL]" | tee /dev/kmsg  | tee -a /tmp/logBalenaMigration
	touch /tmp/balenaMigration_Network_FAIL
fi

echo "BalenaMigration: Finish [OK]" | tee /dev/kmsg | tee -a /tmp/logBalenaMigration
touch /tmp/balenaMigration_Finish
# exec /sbin/reboot
