---
tags:
  - dev/deploy
created_date: 2023-08-26 00:06
aliases: []
draft: false
summary:
---

> 翻墙 梯子 quanx surge clash

[subconverter](https://github.com/tindy2013/subconverter/blob/master/README-cn.md)  
- [利用subconverter实现订阅合并与转换 | 摸鱼笔记](https://mybj.org/2021/09/subconverter/)  
[GitHub - 3dot141/subweb at main](https://github.com/3dot141/subweb/tree/main)

MyUrls

```bash
docker run -d -p 8002:8002 --name myurls careywong/myurls:latest -domain 'myurls.3dot141.top' -port 8002 -conn 'apn1-thorough-feline-34121.upstash.io:34121' -passwd 'd84f3d8e37f04072887089d6d7e9888e' -ttl 90
```

## fly.io 

固定 ip  
- [Run A Private DNS Over HTTPS Service · Fly Docs](https://fly.io/docs/app-guides/run-a-private-dns-over-https-service/#change-hostnames)
- [Restart an App or a Machine · Fly Docs](https://fly.io/docs/apps/restart/)

## JsDelivr

[Migrate from GitHub to jsDelivr](https://www.jsdelivr.com/github)  
[jsdelivr CDN 使用和缓存刷新 - 易波叶平 - 博客园](https://www.cnblogs.com/UncleZhao/p/13753723.html)

## 工具  

[GitHub - KOP-XIAO/QuantumultX-Surge-API: Several server-convert APIs for QuantumultX/Surge/Clash/Mellow](https://github.com/KOP-XIAO/QuantumultX-Surge-API/tree/master)

## 更多规则  

[GitHub - sve1r/Rules-For-Quantumult-X: 适用于 Quantumult X 规则整理集合. 所有内容源自 互联网,仅作为收集和整理](https://github.com/sve1r/Rules-For-Quantumult-X/tree/develop)
- 不支持 hostxxx
- 不支持 wildcard
