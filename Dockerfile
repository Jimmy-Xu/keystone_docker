FROM ubuntu:14.04
MAINTAINER Jimmy Xu <xjimmyshcn@gmail.com>

##########################################################################################
# - Build -
# docker build -t xjimmyshcn/keystone_docker .
#
# - Start MySQL -
# docker run --name mysql -e MYSQL_ROOT_PASSWORD=aaa123aa -P -d mysql
#
# - Start keystone as daemon -
# docker run -d --name keystone -p 50000:5000 -p 35357:35357 --link mysql:mysql -e KEYSTONE_DB_USER=keystone -e KEYSTONE_DB_PASSWORD=aaa123aa -e KEYSTONE_DB_NAME=keystone xjimmyshcn/keystone_docker
#
# - Start keystone for debug -
# docker run -it --rm --link mysql:mysql -e KEYSTONE_DB_USER=keystone -e KEYSTONE_DB_PASSWORD=aaa123aa -e KEYSTONE_DB_NAME=keystone xjimmyshcn/keystone_docker bash
#
# - Start phpMyAdmin -
# docker run -d --link mysql:mysql -e MYSQL_USERNAME=root --name phpmyadmin -p 8800:80 corbinu/docker-phpmyadmin
##########################################################################################


##########################################################################################
# Set 163 apt source
ADD etc/apt/sources.list /etc/apt/sources.list

# Disable lang
RUN echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/99translations

# Set the Server Timezone
RUN echo "Asia/Shanghai" > /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata

# update apt
RUN apt-get update -y


####################################################
# Install tools
RUN apt-get install -y git
RUN apt-get install -y python-dev
RUN apt-get install -y python-pip
RUN apt-get install -y libmysqlclient-dev # For MySQL-python
RUN apt-get install -y libpq-dev  # For pg_config
RUN apt-get install -y libffi-dev # For ffi.h
RUN apt-get install -y python-mysqldb
RUN apt-get install -y mysql-client
RUN pip install python-keystoneclient

####################################################
# Get Keystone
ADD . /usr/lib/keystone
WORKDIR /usr/lib/keystone

# Deploy config
RUN mkdir -p /var/log/keystone/
RUN mkdir -p /etc/keystone/
RUN cp -r ./etc/* /etc/keystone/
RUN mv /etc/keystone/keystone.conf.sample /etc/keystone/keystone.conf
RUN mv /etc/keystone/logging.conf.sample /etc/keystone/logging.conf

# Build Keystone
RUN easy_install -U pip # For IncompleteRead
RUN pip install -r requirements.txt
RUN python setup.py install

####################################################
COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 5000
EXPOSE 35357
VOLUME /var/lib/mysql

CMD keystone-all
