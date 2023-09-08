---
aliases: []
created_date: 2023-09-04 16:47
draft: false
summary: ''
tags:
- dev
---

#dev/mysql

MySQL JDBC 默认客户端数据接收方式为如下：

默认为从服务器一次取出所有数据放在客户端内存中，fetch size 参数不起作用，当一条 SQL 返回数据量较大时可能会出现 JVM OOM。

要一条 SQL 从服务器读取大量数据，不发生 JVM OOM，可以采用以下方法之一：

1、当 statement 设置以下属性时，采用的是流数据接收方式，每次只从服务器接收部份数据，直到所有数据处理完毕，不会发生 JVM OOM。

```java
  setResultSetType(ResultSet.TYPE_FORWARD_ONLY);
  setFetchSize(Integer.MIN_VALUE);
```

2、调用 statement 的 enableStreamingResults 方法，实际上 enableStreamingResults 方法内部封装的就是第 1 种方式。

3、设置连接属性 useCursorFetch=true (5.0 版驱动开始支持)，statement 以 TYPE_FORWARD_ONLY 打开，再设置 fetch size 参数，表示采用服务器端游标，每次从服务器取 fetch_size 条数据。