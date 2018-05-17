FROM cloudtrust-baseimage:f27

ARG elasticsearch_service_git_tag

# Installing elasticsearch

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

WORKDIR /cloudtrust
RUN git clone git@github.com:cloudtrust/elasticsearch-service.git

WORKDIR /cloudtrust/elasticsearch-service
RUN git checkout ${elasticsearch_service_git_tag} && \
    install -v -m 644 -o root -g root deploy/etc/monit.d/elasticsearch.monit /etc/monit.d/ && \
    install -d -v -m 775 -o root -g root /etc/systemd/system/elasticsearch.service.d && \
    install -v -m 664 -o root -g root deploy/etc/systemd/system/elasticsearch.service /etc/systemd/system/elasticsearch.service && \
    install -v -m 664 -o root -g root deploy/etc/systemd/system/elasticsearch.service.d/* /etc/systemd/system/elasticsearch.service.d/ && \
    install -v -m 644 -o root -g root deploy/etc/security/limits.d/* /etc/security/limits.d/ && \
    install -v -m 644 -o root -g root deploy/usr/lib/jvm/jre/lib/security/java.security /usr/lib/jvm/jre/lib/security/java.security


RUN systemctl enable elasticsearch.service && \
    systemctl enable monit.service
