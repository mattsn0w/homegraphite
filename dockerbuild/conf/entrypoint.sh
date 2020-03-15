#!/bin/sh


# remove stale pids
find /opt/graphite/storage -maxdepth 1 -name '*.pid' -delete

service nginx start

. /opt/graphite/bin/activate
PYTHONPATH=/opt/graphite/webapp gunicorn wsgi \
	--workers=4 --bind=127.0.0.1:8080 \
	--log-file=/var/log/gunicorn.log --preload \
	--pythonpath=/opt/graphite/webapp/graphite &

/opt/graphite/bin/carbon-cache.py --instance=a start

LASTPID=$!

wait $LASTPID

echo "The wait is OVER. exiting"

trap shutdown SIGTERM SIGHUP SIGQUIT SIGINT

#shutdown
