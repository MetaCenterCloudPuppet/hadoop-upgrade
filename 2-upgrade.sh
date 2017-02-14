#! /bin/bash -xe

alternative='cluster'
oldver="${1}"
if test -z "${1}"; then
  echo "Usage $0 OLD_VERSION"
  exit 1
fi

cdh_stop() {
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
cdh_stop
for d in hadoop hbase hive hue zookeeper spark pig oozie impala sentry; do
  if test -d /etc/${d}/conf.${alternative}; then
    mv /etc/${d}/conf.${alternative} /etc/${d}/conf.cdh${oldver}
    update-alternatives --auto ${d}-conf
  fi
done
rm -fv ~hbase/.puppet-ssl-facl ~oozie/.puppet-ssl-facl || :
shs='/etc/init.d/spark-history-server'
test -f ${shs} && mv -v ${shs} ${shs}.fuck || :

# upgrade!
apt-get dist-upgrade -y
cdh_stop

# replace by the new configs
puppet agent --test
#/opt/puppet3-omnibus/bin/puppet agent --test

# for HA (during puppet):
#service hadoop-hdfs-namenode stop
#service hadoop-hdfs-namenode rollingUpgradeStarted
