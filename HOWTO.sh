# see https://wiki.metacentrum.cz/metawiki/U%C5%BEivatel:Valtri/Hadoop/Installation#Upgrade

# (0) mirror
...

# (0) backup metadata
rsync -av --delete /data/ ~/backup/data/


# (1) scripts
# upravit na /opt!!!
# upravit oldversion
...
#for m in -c1 -c2 '' `seq 1 24`; do scp -p *.sh root@hador${m}:~/; done
#for m in 12 4 14 15 8; do scp -p *.sh root@myriad${m}:~/; done
for m in 75 90 98 99 100 101 102; do scp -p *.sh root@took${m}:~/; done


# (2) [all] backup
~/1-backup-conf.sh


# (3) [any NN] take a snapshot
su hdfs -s /bin/bash
export KRB5CCNAME=FILE:/tmp/krb5cc_hdfs_admin
kinit -k -t /etc/security/keytab/nn.service.keytab nn/`hostname -f`@ICS.MUNI.CZ
##non-HA
#hdfs dfsadmin -safemode enter
hdfs dfsadmin -rollingUpgrade prepare
while true; do hdfs dfsadmin -rollingUpgrade query; sleep 30; done


# (4) [standby NN] upgrade NN2
~/2-upgrade.sh
service hadoop-hdfs-namenode stop
service hadoop-hdfs-namenode rollingUpgradeStarted


# (5) [active NN] upgrade NN1
~/2-upgrade.sh
service hadoop-hdfs-namenode stop
service hadoop-hdfs-namenode rollingUpgradeStarted


# (6) [DN,front,RM,...] upgrade datanodes, frontends (other controllers probably first, paralelization according to dfs.replication)
~/2-upgrade.sh


# (7) [any NN] finalize
su hdfs -s /bin/bash
export KRB5CCNAME=FILE:/tmp/krb5cc_hdfs_admin
kinit -k -t /etc/security/keytab/nn.service.keytab nn/`hostname -f`@ICS.MUNI.CZ
hdfs dfsadmin -rollingUpgrade finalize
hdfs fsck /


# (8) [Spark HS]
# obnovit startup skript
...


# (9) [Hive Metastore, pokud třeba]
hivemanager stop
#nebo:
#schematool -dbType mysql -upgradeSchemaFrom 0.13.0
mysqldump --opt metastore > metastore_cdh250.sql
mysqldump --skip-add-drop-table --no-data metastore > my-schema-cdh250.mysql.sql
cd /usr/lib/hive/scripts/metastore/upgrade/mysql
mysql metastore
 \. upgrade-0.13.0-to-0.14.0.mysql.sql
 \. upgrade-0.14.0-to-1.1.0.mysql.sql
hivemanager start


# (10) [any NN - kuli kredencím] Spark Jar
su hdfs -s /bin/bash
export KRB5CCNAME=FILE:/tmp/krb5cc_hdfs_admin
hdfs dfs -ls /user/spark/share/lib/spark-assembly.jar
hdfs dfs -rm /user/spark/share/lib/spark-assembly.jar && hdfs dfs -put /usr/lib/spark/lib/spark-assembly.jar /user/spark/share/lib/spark-assembly.jar
hdfs dfs -ls /user/spark/share/lib/spark-assembly.jar


# (11) [all]
reboot


# (12) [front] test everything (example jobs: Hadoop, HBase, Hive, Pig, Spark; service pages + node versions, logy, fungujici log aggregation, ...)
./hadoop-test.sh; echo $?


# (13) update LogBook a wiki:
#https://wiki.metacentrum.cz/metawiki/U%C5%BEivatel:Valtri/Hadoop/LogBook
#https://wiki.metacentrum.cz/wiki/Hadoop#Instalovan.C3.BD_SW
...
