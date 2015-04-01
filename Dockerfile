FROM dockerfile/java:oracle-java8
MAINTAINER William Durand <william.durand1@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get install -y supervisor curl

# Elasticsearch
RUN \
    apt-key adv --keyserver pool.sks-keyservers.net --recv-keys 46095ACC8548582C1A2699A9D27D666CD88E42B4 && \
    if ! grep "elasticsearch" /etc/apt/sources.list; then echo "deb http://packages.elasticsearch.org/elasticsearch/1.4/debian stable main" >> /etc/apt/sources.list;fi && \
    if ! grep "logstash" /etc/apt/sources.list; then echo "deb http://packages.elasticsearch.org/logstash/1.4/debian stable main" >> /etc/apt/sources.list;fi && \
    apt-get update

RUN \
    apt-get install -y elasticsearch && \
    apt-get clean && \
    sed -i '/#cluster.name:.*/a cluster.name: logstash' /etc/elasticsearch/elasticsearch.yml && \
    sed -i '/#path.data: \/path\/to\/data/a path.data: /data' /etc/elasticsearch/elasticsearch.yml


# Logstash
RUN apt-get install -y logstash && \
    apt-get clean



# Kibana
RUN \
    curl -s https://download.elasticsearch.org/kibana/kibana/kibana-4.0.1-linux-x64.tar.gz | tar -C /opt -xz && \
    ln -s /opt/kibana-4.0.1-linux-x64 /opt/kibana && \
    sed -i 's/port: 5601/port: 80/' /opt/kibana/config/kibana.yml


COPY etc/supervisor/conf.d/logstash.conf /etc/supervisor/conf.d/logstash.conf
COPY etc/supervisor/conf.d/elasticsearch.conf /etc/supervisor/conf.d/elasticsearch.conf
# patch logstash input and server to allow ssl client cert validation

COPY patches/input/lumberjack.rb /opt/logstash/lib/logstash/inputs/lumberjack.rb
COPY patches/1.9/server.rb /opt/logstash/vendor/bundle/jruby/1.9/gems/jls-lumberjack-0.0.20/lib/server.rb
COPY patches/2.1/server.rb /opt/logstash/vendor/bundle/jruby/2.1/gems/jls-lumberjack-0.0.20/lib/server.rb


COPY etc/supervisor/conf.d/kibana.conf /etc/supervisor/conf.d/kibana.conf

EXPOSE 80

CMD [ "/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf" ]

