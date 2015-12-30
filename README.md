Quick Start: Run a keystone server with MySQL

>This repo is the docker image of Liberty Keystone.

============================================================================

**Three containers**

- **mysql**: db for keystone
- **keystone**: link to mysql
- **phpmyadmin**: link to mysql


```
############################
# get repo
$ git clone https://github.com/Jimmy-Xu/keystone_docker.git -b mine
$ cd keystone_docker

############################
# build docker image
$ docker build -t xjimmyshcn/keystone_docker .

############################
# Start mysql
$ mkdir -p data
$ docker run --name mysql -v `pwd`/data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=aaa123aa -P -d mysql

# Start keystone as daemon
$ docker run -d --name keystone -p 50000:5000 -p 35357:35357 --link mysql:mysql -e KEYSTONE_DB_USER=keystone -e KEYSTONE_DB_PASSWORD=aaa123aa -e KEYSTONE_DB_NAME=keystone xjimmyshcn/keystone_docker

# Start phpMyAdmin
$ docker run -d --link mysql:mysql -e MYSQL_USERNAME=root --name phpmyadmin -p 8880:80 corbinu/docker-phpmyadmin

############################
# call keystone api
curl -s -H "Content-Type: application/json" http://localhost:50000 | python -mjson.tool
curl -s -H "Content-Type: application/json" http://localhost:35357 | python -mjson.tool

############################
# connect to mysql(phpMyAdmin)
http://localhost:8880
login user account:
1) root:aaa123aa
2) keystone:aaa123aa

############################
$ docker ps
CONTAINER ID  IMAGE                       COMMAND                 CREATED        STATUS        PORTS                                              NAMES
579d689b8945  corbinu/docker-phpmyadmin   "/bin/sh -c phpmyadmi"  1 minutes ago  Up 1 minutes  0.0.0.0:8880->80/tcp                               phpmyadmin
6698b6628f9b  xjimmyshcn/keystone_docker  "/entrypoint.sh /bin/"  2 minutes ago  Up 2 minutes  0.0.0.0:35357->35357/tcp, 0.0.0.0:50000->5000/tcp  keystone
9f153212629c  mysql                       "/entrypoint.sh mysql"  2 minutes ago  Up 2 minutes  0.0.0.0:32770->3306/tcp                            mysql
```
