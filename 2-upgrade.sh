#! /bin/bash -xe

alternative='cluster'
oldver='5.4.7'

service puppet stop || :

## upgrade
#echo "Upgrade? (CTRL-C for stop)"
#read X

test -d /hdfs && umount -f /hdfs || :
# for HA: to standby
#service hadoop-hdfs-zkfc stop
#service hadoop-yarn-resourcemanager stop

# new repo + download
sed -e 's,/repos/hadoop/,/repos/hadoop-test/,' -i /etc/apt/sources.list.d/cloudera.list
apt-get update
apt-get dist-upgrade -y -d

# move away old configs
hbmanager stop || :
hivemanager stop || :
service spark-history-server stop || :
service spark-master stop || :
yellowmanager stop || :
service zookeeper-server stop || :
ps xafuw | grep java || :
for d in hadoop hbase hive zookeeper spark pig oozie impala sentry; do
  if test -d /etc/${d}/conf.${alternative}; then
    mv /etc/${d}/conf.${alternative} /etc/${d}/conf.cdh${oldver}
    update-alternatives --auto ${d}-conf
  fi
done
rm -fv ~hbase/.puppet-ssl-facl
shs='/etc/init.d/spark-history-server'
test -f ${shs} && mv -v ${shs} ${shs}.fuck || :

# upgrade!
apt-get dist-upgrade -y
hbmanager stop || :
hivemanager stop || :
service spark-history-server stop || :
service spark-master-server stop || :
yellowmanager stop || :
service zookeeper-server stop || :
ps xafuw | grep java || :

# replace by the new configs
puppet agent --test
#/opt/puppet3-omnibus/bin/puppet agent --test

# for HA (during puppet):
#service hadoop-hdfs-namenode stop
#service hadoop-hdfs-namenode rollingUpgradeStarted
