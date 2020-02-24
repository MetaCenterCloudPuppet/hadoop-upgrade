#! /bin/sh -xe

# Launch manually first:
#
# 1) unmount /hdfs everywhere
# 2) switch HA to the other server
# 3) edit script parameters

# Script actions:
#
# 1) start rolling upgrade on HDFS
# 2) stop all daemons
# 3) backup data

# Launch manually after:
#
# 1) download all the data!
# 2) download the old backups and whole ~/system ~/hadoop

oldver="${1}"
realm="${2}"
if test -z "${2}"; then
  echo "Usage $0 OLD_VERSION REALM"
  exit 1
fi

cdh_stop() {
  test -d /hdfs && umount /hdfs || :
  hbmanager stop || :
  hivemanager stop || :
  impmanager stop || :
  service hue stop || :
  service oozie stop || :
  service spark-history-server stop || :
  service spark-master stop || :
  yellowmanager stop || :
  service zookeeper-server stop || :
  ps xafuw | grep java || :
}

w() {
  echo "Press Enter... CTRL-C for quit"
  read X
}

`dirname $0`/1-backup-conf.sh ${oldver}
mv ~/backup-cdh${oldver}/ .

if test `basename $0` = 'backup-master.sh'; then
  mysqldump --skip-opt --all-databases | pbzip2 --fast > data.sql.bz2

  echo "No rolling update prepare on primary or HA quorum servers"
else
  export KRB5CCNAME=FILE:/tmp/krb5cc_hdfs_admin
  kinit -k -t /etc/security/keytab/nn.service.keytab nn/`hostname -f`@${realm}
  hdfs dfsadmin -rollingUpgrade prepare

  #QUERY rolling upgrade ...
  #Preparing for upgrade. Data is being saved for rollback.
  #Run "dfsadmin -rollingUpgrade query" to check the status
  #for proceeding with rolling upgrade
  #  Block Pool ID: BP-215329554-192.168.42.12-1569416869794
  #     Start Time: Wed Sep 25 17:06:40 CEST 2019 (=1569424000724)
  #  Finalize Time: <NOT FINALIZED>

  #QUERY rolling upgrade ...
  #Proceed with rolling upgrade:
  #  Block Pool ID: BP-215329554-192.168.42.12-1569416869794
  #     Start Time: Wed Sep 25 17:06:40 CEST 2019 (=1569424000724)
  #  Finalize Time: <NOT FINALIZED>

  while hdfs dfsadmin -rollingUpgrade query | grep 'Preparing for upgrade'; do sleep 30; done
  hdfs dfsadmin -rollingUpgrade query

  echo "No MySQL on secondary or HA quorum servers"
fi
w

cdh_stop
w
# to prevent daemons startups
apt-get remove hadoop
apt-get remove oracle-java\*

dpkg --get-selections | grep -v install
w

test -d /data && tar -c /data | pbzip2 --fast > hdfs-data.tar.bz2
test -d /var/lib/hadoop-hdfs/cache && tar -c /var/lib/hadoop-hdfs/cache | pbzip2 --fast > hdfs-data-var.tar.bz2
test -d /var/lib/zookeeper && tar -c /var/lib/zookeeper | pbzip2 --fast > zookeeper.tar.bz2
tar -c /etc | pbzip2 > etc.tar.bz2
