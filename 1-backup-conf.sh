#! /bin/sh

mkdir -p ~/backup-cdh547/default || :
cd ~/backup-cdh547/

for d in hadoop hbase hive zookeeper spark pig oozie impala sentry; do
  if test -d /etc/${d}; then
    cp -aL /etc/${d}/conf ${d}
    for f in dist empty; do
      if test -d /etc/${d}/conf.${f}; then
        cp -aL /etc/${d}/conf.${f} ${d}.${f}
      fi
    done
  fi
  cp /etc/default/${d}* default/ 2>/dev/null || :
done
ls -la
