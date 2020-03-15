FROM ubuntu:latest as base

MAINTAINER Matt Snow matt@slakin.net

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update && apt-get -y upgrade && apt-get -y install \
      apt-utils \
      build-essential python3-dev \
      libcairo2-dev libffi-dev \
      curl nginx \
      python3 python3-pip \
      python3-postgresql \
      libghc-postgresql-libpq-dev libpq-dev \
      libsasl2-dev python3-venv \
      libldap2-dev git vim


RUN pip3 install \
      django==1.11.25 \
      django-statsd-mozilla \
      fadvise \
      gunicorn==19.9.0 \
      msgpack-python \
      redis \
      python-ldap \
      psycopg2

RUN python3 -m venv /opt/graphite/

ARG version=1.1.6

# install whisper
ARG whisper_version=${version}
ARG whisper_repo=https://github.com/graphite-project/whisper.git
RUN git clone -b ${whisper_version} --depth 1 ${whisper_repo} /usr/local/src/whisper \
  && cd /usr/local/src/whisper \
  && . /opt/graphite/bin/activate \
  && python3 ./setup.py install

# install carbon
ARG carbon_version=${version}
ARG carbon_repo=https://github.com/graphite-project/carbon.git
RUN . /opt/graphite/bin/activate \
  && git clone -b ${carbon_version} --depth 1 ${carbon_repo} /usr/local/src/carbon \
  && cd /usr/local/src/carbon \
  && pip3 install -r requirements.txt \
  && python3 ./setup.py install

# install graphite
ARG graphite_version=${version}
ARG graphite_repo=https://github.com/graphite-project/graphite-web.git
RUN . /opt/graphite/bin/activate \
 && git clone -b ${graphite_version} --depth 1 ${graphite_repo} /usr/local/src/graphite-web \
 && cd /usr/local/src/graphite-web \
 && pip3 install -r requirements.txt \
 && python3 ./setup.py install


FROM base as build

# Setup and configure nginx+gunicorn

COPY conf/etc/nginx/sites-available/graphite /etc/nginx/sites-available/graphite
COPY conf/opt/graphite/webapp/graphite/local_settings.py /opt/graphite/webapp/graphite/local_settings.py
COPY conf/opt/graphite/conf/* /opt/graphite/conf/
COPY conf/entrypoint.sh /

RUN ln -s /etc/nginx/sites-available/graphite /etc/nginx/sites-enabled && \
    rm -f /etc/nginx/sites-enabled/default && \
    touch /var/log/nginx/graphite.access.log && \
    touch /var/log/nginx/graphite.error.log && \
    chmod 640 /var/log/nginx/graphite.* && \
    chown www-data:www-data /var/log/nginx/graphite.* && \
    if [ ! -e /opt/graphite/webapp/graphite ]; then mkdir /opt/graphite/webapp/graphite ; fi && \
    mkdir /opt/graphite/static/ && \
#    cp /opt/graphite/lib/python3.6/site-packages/graphite/local_settings.py.example /opt/graphite/webapp/graphite/local_settings.py && \
    ln -s /opt/graphite/webapp/graphite/local_settings.py /opt/graphite/lib/python3.6/site-packages/graphite/local_settings.py && \
    /opt/graphite/bin/build-index.sh && \
    /opt/graphite/bin/django-admin.py migrate --settings=graphite.settings

# This might not be needed - https://graphite.readthedocs.io/en/latest/config-database-setup.html
RUN chown nobody:nogroup /opt/graphite/storage/graphite.db && \
    cp /opt/graphite/lib/python3.6/site-packages/graphite/wsgi.py /opt/graphite/webapp/graphite/

FROM build as production

# Defaults
EXPOSE 80 2003-2004 2013-2014 2023-2024 8080 8125 8125/udp 8126
VOLUME ["/opt/graphite/conf", "/opt/graphite/storage", "/opt/graphite/webapp/graphite/functions/custom", "/etc/nginx", "/opt/statsd/config", "/etc/logrotate.d", "/var/log", "/var/lib/redis"]

STOPSIGNAL SIGKILL

ENTRYPOINT ["/entrypoint.sh"]
