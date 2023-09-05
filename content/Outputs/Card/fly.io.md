---
aliases: []
created_date: 2023-08-25 16:00
draft: false
summary: ''
tags:
- dev
---

> [Deploy app servers close to your users · Fly](https://fly.io/)
> 
> Fly.io 是一个全球性的应用程序部署平台，可以帮助开发人员轻松地将应用程序部署到全球各地的数据中心，提供更快的响应速度和更好的用户体验。Fly.io 支持多种编程语言和框架，包括 Node.js、Ruby、Python、Go、Java 和 PHP 等。
> 
> Fly.io 提供了一组强大的功能，包括：
> 
> - 全球部署：Fly.io 的全球性部署可以将应用程序部署到多个数据中心，以提高响应速度和可靠性。
> - 自动伸缩：Fly.io 可以根据应用程序的负载自动伸缩，以确保应用程序始终具有足够的资源可用。
> - 安全性：Fly.io 提供了强大的安全功能，包括 SSL/TLS 加密、防火墙和 DDoS 保护等，以保护应用程序和用户数据。
> - 简单易用：Fly.io 提供了易于使用的命令行工具和 API，可以帮助开发人员轻松地部署和管理应用程序。
> 
> 此外，Fly.io 还提供了一组工具和服务，可以帮助开发人员更好地管理应用程序，包括日志记录、性能监控、错误跟踪和应用程序分析等。
> 
> 总之，Fly.io 是一个强大、可靠和易于使用的应用程序部署平台，可以帮助开发人员轻松地将应用程序部署到全球各地，提供更好的用户体验和更高的可靠性。
> 
> # fly.io
> 
> 问题记录一：flyctl deploy --remote-only 部署失败  
> 原因是使用 clash 的代理。猜测可能是代理导致实际访问的构建节点选取有问题。  
> 完全关掉 clash 的代理，即关闭【系统代理、增强模式】  
> [截图](../../Attachments/f693abb8b30db3dc2c4f4eafe0bada6c.png)  
> ![](../../Attachments/f693abb8b30db3dc2c4f4eafe0bada6c.png)  
> 即可解决问题