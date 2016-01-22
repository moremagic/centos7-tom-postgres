FROM centos:7
MAINTAINER moremagic <itoumagic@gmail.com>

# Install wget etc...
RUN yum install -y passwd openssh-server openssh-clients initscripts
RUN yum install -y install java-1.8.0-* git wget curl tar zip \
    && yum -y update

# ssh
RUN echo 'root:root' | chpasswd
RUN /usr/sbin/sshd-keygen

# タイムゾーンを日本に
RUN echo 'ZONE="Asia/Tokyo"' > /etc/sysconfig/clock
RUN rm -f /etc/localtime
RUN ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# 言語を日本語に
#RUN sed -ri 's/en_US/ja_JP/' /etc/sysconfig/i18n
RUN yum -y clean all

# tomcat install
RUN wget http://ftp.riken.jp/net/apache/tomcat/tomcat-7/v7.0.67/bin/apache-tomcat-7.0.67.tar.gz
RUN tar -xzvf apache-tomcat-7.0.67.tar.gz && mv apache-tomcat-7.0.67 /opt/apache-tomcat
ADD tomcat-users.xml /opt/apache-tomcat/conf/

#----------------------------------------------------------
# postgresql
#----------------------------------------------------------
RUN curl -O http://yum.postgresql.org/9.4/redhat/rhel-7-x86_64/pgdg-centos94-9.4-1.noarch.rpm > /dev/null 2>&1
RUN rpm -ivh *.rpm > /dev/null 2>&1 && rm -f *.rpm 
RUN yum install -y tcsh postgresql94-server > /dev/null 2>&1
RUN rm -fr /var/lib/pgsql && mkdir -p /var/lib/pgsql/data &&chown -R postgres:postgres /var/lib/pgsql
RUN mkdir -p /var/log/pg_log && chown postgres:postgres /var/log/pg_log
RUN ln -s /usr/pgsql-9.4 /usr/pgsql
RUN echo 'postgres:postgres' | chpasswd

RUN mkdir /usr/pgsql/data
RUN chmod 755 /usr/pgsql/data && chown -R postgres:postgres /usr/pgsql/
RUN su - postgres -c '/usr/pgsql/bin/initdb -D /usr/pgsql/data'
RUN echo "host    all             all             0.0.0.0/0               trust" >> /usr/pgsql/data/pg_hba.conf
RUN echo "listen_addresses='*'" >> /usr/pgsql/data/postgresql.conf

RUN printf '#!/bin/bash \n\
export JAVA_HOME=/usr/lib/jvm/java-openjdk/ \n\
/opt/apache-tomcat/bin/startup.sh \n\
su - postgres -c "/usr/pgsql/bin/postgres -D /usr/pgsql/data/" & \n\
/usr/sbin/sshd -D \n\
tail -f /var/null  \n\
' >> /etc/service.sh \
    && chmod +x /etc/service.sh

EXPOSE 22 8080 5432
CMD /etc/service.sh
