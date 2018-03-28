FROM cloudtrust-baseimage:f27

ARG elasticsearch_service_git_tag

RUN echo -e "\
[elasticsearch-6.x]\n\
name=Elasticsearch repository for 6.x packages\n\
baseurl=https://artifacts.elastic.co/packages/6.x/yum\n\
gpgcheck=1\n\
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch\n\
enabled=1\n\
autorefresh=1\n\
type=rpm-md" > /etc/yum.repos.d/elasticsearch.repo

RUN rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch && \
    dnf install -y java-1.8.0-openjdk elasticsearch kibana nginx && \
    dnf clean all

WORKDIR /cloudtrust
RUN git clone git@github.com:cloudtrust/elasticsearch-service.git

WORKDIR /cloudtrust/elasticsearch-service
RUN git checkout ${elasticsearch_service_git_tag} && \
    install -d -v -m 775 -o root -g root /etc/systemd/system/elasticsearch.service.d && \
    install -v -m 664 -o root -g root deploy/etc/systemd/system/elasticsearch.service /etc/systemd/system/elasticsearch.service && \
    install -v -m 664 -o root -g root deploy/etc/systemd/system/elasticsearch.service.d/* /etc/systemd/system/elasticsearch.service.d/ && \
    install -v -m 644 -o root -g root deploy/etc/security/limits.d/* /etc/security/limits.d/ && \
    install -v -m 644 -o root -g root deploy/usr/lib/jvm/jre/lib/security/java.security /usr/lib/jvm/jre/lib/security/java.security
    install -v -m 644 -D -o root -g root deploy/etc/nginx/conf.d/* /etc/nginx/conf.d/ && \
    install -v -m 644 -o root -g root deploy/etc/nginx/nginx.conf /etc/nginx/nginx.conf && \
    install -v -m 644 -o root -g root deploy/etc/nginx/mime.types /etc/nginx/mime.types && \
    install -v -o root -g root -m 644 deploy/etc/systemd/system/nginx.service.d/limit.conf /etc/systemd/system/nginx.service.d/limit.conf

RUN systemctl enable elasticsearch && \
    systemctl enable kibana && \
    systemctl enable nginx

