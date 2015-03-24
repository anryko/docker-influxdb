FROM ubuntu
MAINTAINER Matt Baldwin (baldwin@stackpointcloud.com)

RUN \
  apt-get update && apt-get -y --no-install-recommends install \
    ca-certificates \
    software-properties-common \
    python-django-tagging \
    python-simplejson \
    python-memcache \
    python-ldap \
    python-cairo \
    python-pysqlite2 \
    python-support \
    python-pip \
    gunicorn \
    supervisor \
    nginx-light \
    nodejs \
    git \
    curl \
    openjdk-7-jre \
    build-essential \
    python-dev


WORKDIR /opt
RUN \
  grafana_url=$(curl -s http://grafanarel.s3.amazonaws.com/latest.json | python -c 'import sys, json; print json.load(sys.stdin)["url"]') && \
  curl -s -o grafana.tar.gz $grafana_url && \
  curl -s -o influxdb_latest_amd64.deb http://s3.amazonaws.com/influxdb/influxdb_latest_amd64.deb && \
  mkdir grafana && \
  tar -xzf grafana.tar.gz --directory grafana --strip-components=1 && \
  dpkg -i influxdb_latest_amd64.deb && \
  mkdir influxdb/ssl && \
  openssl req -new -x509 -newkey rsa:2048 -days 1825 -nodes -out influxdb/ssl/influxdb.pem -keyout influxdb/ssl/influxdb.key \
    -subj "/C=DE/ST=BE/L=Berlin/O=CompanyName/CN=grafana.companyname.com" && \
  echo "influxdb soft nofile unlimited" >> /etc/security/limits.conf && \
  echo "influxdb hard nofile unlimited" >> /etc/security/limits.conf

ADD config.js /opt/grafana/config.js
ADD grafana.conf /etc/nginx/sites-available/grafana.conf
RUN ln -s /etc/nginx/sites-available/grafana.conf /etc/nginx/sites-enabled/grafana.conf
RUN rm /etc/nginx/sites-enabled/default
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD config.toml /opt/influxdb/current/config.toml

VOLUME ["/opt/influxdb/shared/data"]

EXPOSE 443 8083 8086 2003

CMD ["supervisord", "-n"]
