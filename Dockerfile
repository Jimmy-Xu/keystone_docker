FROM ubuntu:15.04
MAINTAINER tobe tobeg3oogle@gmail.com

RUN apt-get update -y

# Install tools
RUN apt-get install -y git
RUN apt-get install -y python-dev
RUN apt-get install -y python-pip
RUN pip install python-keystoneclient
RUN apt-get install -y libmysqlclient-dev # For MySQL-python
RUN apt-get install -y libpq-dev # For pg_config
RUN apt-get install -y libffi-dev # For ffi.h
RUN apt-get install -y testrepository # For run_tests.sh
RUN pip install netifaces # For glance cli

# Get Keystone
RUN git clone https://github.com/openstack/keystone.git /keystone
WORKDIR /keystone

# Build Keystone
RUN pip install -r requirements.txt
# RUN pip install -r test-requirements.txt
RUN easy_install -U pip # For IncompleteRead
RUN python setup.py install

RUN mkdir -p /etc/keystone/
RUN cp -r etc/* /etc/keystone/
RUN mv /etc/keystone/keystone.conf.sample /etc/keystone/keystone.conf
RUN mv /etc/keystone/logging.conf.sample /etc/keystone/logging.conf
RUN mkdir -p /var/log/keystone/

RUN keystone-manage db_sync

EXPOSE 5000
EXPOSE 35357

CMD keystone-all