#!/bin/bash


if [ $1 -eq 1 ]
then 
	dev=ssd
	datadir=/tmp/
else
	dev=pm
	datadir=/mnt/pmem0/
fi

for wktype in {a,f,g};
do
	_wksize=1
	for wksize in {1..25};
	do
		./fix_workload.sh ${wktype} ${_wksize} ${wksize}
		_wksize=${wksize}
		#load workload
		for ((i=1;i<=$2;i++));
		do
			rm ${datadir}ycsb-rocksdb-data${i}/*
			echo "./bin/ycsb load rocksdb -s -P workloads/workload${wktype} -p rocksdb.dir=${datadir}ycsb-rocksdb-data${i}"
			./bin/ycsb load rocksdb -s -P workloads/workload${wktype} -p rocksdb.dir=${datadir}ycsb-rocksdb-data${i}
		done


		#wait for loading data I/O to complete
		sleep 3
		sync
		echo 3 > /proc/sys/vm/drop_caches


		#run workload

		for ((j=1;j<=$2;j++));
		do
			result_file_name=${wktype}_${j}_${wksize}_$2_result
			echo "./bin/ycsb run rocksdb -s -P workloads/workload${wktype} -p rocksdb.dir=${datadir}ycsb-rocksdb-data${j} > ./results/${dev}/${result_file_name} &"
	
			./bin/ycsb run rocksdb -s -P workloads/workload${wktype} -p rocksdb.dir=${datadir}ycsb-rocksdb-data${j} > ./results/${dev}/${result_file_name} &
			pidarr[${j}]=$!
		done

		for k in ${pidarr[*]};
		do
			echo "wait ${k}"
			wait ${k} 
		done

		./fix_workload.sh $wktype $_wksize 1 
	done
done


