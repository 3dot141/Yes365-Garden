---
aliases: []
created_date: 2023-08-23 15:31
draft: false
summary: ''
tags:
- dev
---

## 建立镜像

安装官方镜像

```Shell
docker pull mysql:5.7   # 拉取 mysql 5.7
docker pull mysql       # 拉取最新版mysql镜像
```

检查是否拉取成功

```Shell
docker images # 查看是否有对应的镜像
```

创建容器

```Shell
sudo docker run -p 3306:3306 --name mysql -e MYSQL_ROOT_PASSWORD=123456 -d mysql:5.7
# Docker 搭建 MySQL
–name：容器名，此处命名为mysql
-e：配置信息，此处配置mysql的root用户的登陆密码
-p：端口映射，此处映射 主机3306端口 到 容器的3306端口
-d：后台运行容器，保证在退出终端后容器继续运行
```

建立目录映射

```Shell
docker run -p 3306:3306 --name mysql \\
-v /usr/local/docker/mysql/conf:/etc/mysql \\
-v /usr/local/docker/mysql/logs:/var/log/mysql \\
-v /usr/local/docker/mysql/data:/var/lib/mysql \\
-e MYSQL_ROOT_PASSWORD=123456 \\
-d mysql:5.7
```

- -v：主机和容器的目录映射关系，":"前为主机目录，之后为容器目录

检查容器是否正确运行

```Shell
# 看到容器ID，容器的源镜像，启动命令，创建时间，状态，端口映射信息，容器名字
docker container ls
# 查看容器值
docker ps -a
```