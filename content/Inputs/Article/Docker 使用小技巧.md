---
aliases: []
created_date: 2023-08-27 16:20
draft: false
summary: ''
tags:
- dev
---

## 传递给应用的配置参数

比如

```
docker run -d -p 8002:8002 --name myurls myurls-custom:latest -domain 'myurls.3dot141.top' -port 8002 -conn 'apn1-thorough-feline-34121.upstash.io:34121' -passwd 'd84f3d8e37f04072887089d6d7e9888e' -ttl 90
```

`ENTRYPOINT` 是 Dockerfile 中的一个指令，用于指定容器启动时要执行的命令或程序。

在您的情况下，您正在运行一个容器，并希望在容器启动时执行特定的命令。您可以使用 `ENTRYPOINT` 指令来定义这个命令。

以下是一个示例 Dockerfile，展示了如何使用 `ENTRYPOINT` 指令来定义容器启动时要执行的命令：

```
FROM myurls-custom:latest

# 设置环境变量
ENV DOMAIN myurls.3dot141.top
ENV PORT 8002
ENV CONN apn1-thorough-feline-34121.upstash.io:34121
ENV PASSWD d84f3d8e37f04072887089d6d7e9888e
ENV TTL 90

# 定义 ENTRYPOINT
ENTRYPOINT ["myurls-custom", "-domain", "$DOMAIN", "-port", "$PORT", "-conn", "$CONN", "-passwd", "$PASSWD", "-ttl", "$TTL"]
```

在这个示例中，`myurls-custom` 是容器中的可执行文件，您需要根据实际情况替换为您的可执行文件。

然后，使用 `docker build` 命令来构建镜像，并使用 `docker run` 命令来运行容器。在运行容器时，不需要显式指定命令和参数，因为它们已经在 `ENTRYPOINT` 中定义。

```
docker build -t myurls-image .
docker run -d -p 8002:8002 --name myurls myurls-image
```

这样，当容器启动时，它将自动执行 `myurls-custom` 命令，并使用您在 Dockerfile 中定义的环境变量作为参数。

## 设置环境变量的方式

放在 Dockerfile 中的环境变量,相当于提供了默认配置。

```
ENV NAME=VALUE
```

但每个容器启动时可以通过 `-e` 覆盖。  
而使用`docker run -e`设置的变量只对当前容器生效,不会影响镜像。