#! /bin/sh

oldver="${1}"
if test -z "${1}"; then
	echo "Usage $0 OLD_VERSION"
	exit 1
fi

mkdir -p ~/backup-cdh${oldver}/default || :
cd ~/backup-cdh${oldver}/

for d in hadoop hbase hive hue zookeeper spark pig oozie impala sentry; do
  if test -d /etc/${d}; then
    cp -aL /etc/${d}/conf ${d}
    for f in dist empty; do
      if test -d /etc/${d}/conf.${f}; then
        cp -aL /etc/${d}/conf.${f} ${d}.${f}
      fi
    done
  fi
  cp -p /etc/default/${d}* default/ 2>/dev/null || :
done
ls -la
