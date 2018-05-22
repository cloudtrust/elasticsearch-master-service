FROM cloudtrust-baseimage:f27

ARG elasticsearch_service_git_tag
ARG elasticsearch_bridge_release
ARG jaeger_release
ARG config_git_tag
ARG config_repo

##
## Installing elasticsearch
##

RUN echo -e "\
[elasticsearch-6.x]\n\
name=Elasticsearch repository for 6.x packages\n\
baseurl=https://artifacts.elastic.co/packages/6.x/yum\n\
gpgcheck=1\n\
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch\n\
enabled=1\n\
autorefresh=1\n\
type=rpm-md" > /etc/yum.repos.d/elasticsearch.repo

RUN dnf update -y && \
    rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch && \
    dnf install -y java-1.8.0-openjdk elasticsearch && \
    dnf clean all

RUN install -d -v -m755 /opt/elasticsearch -o root -g root && \
    install -d -v -m755 /etc/elasticsearch -o elasticsearch -g elasticsearch && \
    groupadd agent && \
    useradd -m -s /sbin/nologin -g agent agent && \
    install -d -v -m755 /opt/agent -o root -g root && \
    install -d -v -m755 /etc/agent -o agent -g agent

WORKDIR /cloudtrust
RUN git clone git@github.com:cloudtrust/elasticsearch-service.git && \
    git clone ${config_repo} ./config

WORKDIR /cloudtrust/elasticsearch-service
RUN git checkout ${elasticsearch_service_git_tag} 

WORKDIR /cloudtrust/elasticsearch-service
RUN install -v -m 644 -o root -g root deploy/etc/monit.d/elasticsearch.monit /etc/monit.d/ && \
    install -d -v -m 775 -o root -g root /etc/systemd/system/elasticsearch.service.d && \
    install -v -m 664 -o root -g root deploy/etc/systemd/system/elasticsearch.service /etc/systemd/system/elasticsearch.service && \
    install -v -m 664 -o root -g root deploy/etc/systemd/system/elasticsearch.service.d/* /etc/systemd/system/elasticsearch.service.d/ && \
    install -v -m 644 -o root -g root deploy/etc/security/limits.d/* /etc/security/limits.d/ && \
    install -v -m 644 -o root -g root deploy/usr/lib/jvm/jre/lib/security/java.security /usr/lib/jvm/jre/lib/security/java.security

##
## ELASTICSEARCH-BRIDGE
##

WORKDIR /cloudtrust
RUN wget ${elasticsearch_bridge_release} -O elasticsearch-bridge.tar.gz && \
    mkdir "elasticsearch-bridge" && \
    tar -xzf "elasticsearch-bridge.tar.gz" -C "elasticsearch-bridge" --strip-components 1 && \
    rm -f elasticsearch-bridge.tar.gz

WORKDIR /cloudtrust/elasticsearch-bridge
RUN install -d -v -o elasticsearch -g elasticsearch /opt/elasticsearch-bridge && \ 
    install -v -o elasticsearch -g elasticsearch elasticsearch_bridge /opt/elasticsearch-bridge

WORKDIR /cloudtrust/elasticsearch-service 
RUN install -v -o root -g root deploy/etc/systemd/system/elasticsearch-bridge.service /etc/systemd/system/ && \
    install -v -m 644 -o root -g root deploy/etc/monit.d/elasticsearch-bridge.monit /etc/monit.d/

##
##  JAEGER AGENT
##  

WORKDIR /cloudtrust
RUN wget ${jaeger_release} -O jaeger.tar.gz && \
    mkdir jaeger && \
    tar -xzf jaeger.tar.gz -C jaeger --strip-components 1 && \
    install -v -m0755 jaeger/agent-linux /opt/agent/agent && \
    rm jaeger.tar.gz && \
    rm -rf jaeger/

WORKDIR /cloudtrust/elasticsearch-service
RUN install -v -o agent -g agent -m 644 deploy/etc/systemd/system/agent.service /etc/systemd/system/agent.service && \
    install -d -v -o root -g root -m 644 /etc/systemd/system/agent.service.d && \
    install -v -m 644 -o root -g root deploy/etc/monit.d/agent.monit /etc/monit.d/ && \
    install -v -o root -g root -m 644 deploy/etc/systemd/system/agent.service.d/limit.conf /etc/systemd/system/agent.service.d/limit.conf

##
##  CONFIG
##

WORKDIR /cloudtrust/config
RUN git checkout ${config_git_tag}

WORKDIR /cloudtrust/config
RUN install -v -m0755 -o agent -g agent deploy/etc/jaeger-agent/agent.yml /etc/agent/ && \
    install -v -o elasticsearch -g elasticsearch -d -m755 /etc/elasticsearch-bridge && \
    install -v -m0755 -o elasticsearch -g elasticsearch deploy/etc/elasticsearch-bridge/elasticsearch_bridge.yml /etc/elasticsearch-bridge/ 

RUN systemctl enable elasticsearch.service && \
    systemctl enable agent.service && \
    systemctl enable elasticsearch-bridge && \
    systemctl enable monit.service


