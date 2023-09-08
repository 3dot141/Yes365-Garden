---
aliases: []
created_date: 2023-09-04 16:47
draft: false
summary: ''
tags:
- dev
---

#dev/mysql

# 从 MySQL 的 LIMIT 聊起

[一次 SQL 查询优化原理分析：900W+ 数据，从 17s 到 300ms](https://mp.weixin.qq.com/s/IH7P_-TxB-W_72KNuWMsjg)

数据量

```Java
mysql> select count(*) from test;
+----------+
| count(*) |
+----------+
|  5242882 |
+----------+
1 row in set (4.25 sec)
```

表格式

```Java
mysql> desc test;
+--------+---------------------+------+-----+---------+----------------+
| Field  | Type                | Null | Key | Default | Extra          |
+--------+---------------------+------+-----+---------+----------------+
| id     | bigint(20) unsigned | NO   | PRI | NULL    | auto_increment |
| val    | int(10) unsigned    | NO   | MUL | 0       |                |
| source | int(10) unsigned    | NO   |     | 0       |                |
+--------+---------------------+------+-----+---------+----------------+
3 rows in set (0.00 sec)
```

id 为自增主键，val 为非唯一索引。

给出一个使用 limit 的查询 SQL

```Java
mysql> select * from test where val=4 limit 300000,5;
+---------+-----+--------+
| id      | val | source |
+---------+-----+--------+
| 3327622 |   4 |      4 |
| 3327632 |   4 |      4 |
| 3327642 |   4 |      4 |
| 3327652 |   4 |      4 |
| 3327662 |   4 |      4 |
+---------+-----+--------+
5 rows in set (15.98 sec)
```

如上可以看到花费了 15s, 为什么这么慢？

# 问题一：LIMIT 执行逻辑

- 执行逻辑

  比如当我们用 limit 1000000, 10 的时候，MySQL 会先扫描满足条件的 1000010 行，扔掉前面的 1000000 行，返回后面的 10 行。所以 offset 越大的时候，扫描的行就越多，效率也就越慢了。

  [MySQL中Limit性能优化的方案_荒野大码农的博客-CSDN博客_limit 优化](https://blog.csdn.net/czx2018/article/details/107911967)

- 为什么这么执行？

	[[MySQL 的 Limit 设计理念]]

  [MySQL的LIMIT这么差劲的吗 - 掘金](https://juejin.cn/post/7018170284687491080)

[大家都知道，MySQL内部其实是分为server层和存储引擎层的： 扩展一：MySQL 的架构](https://flowus.cn/a5c14110-8261-491f-bdde-52677f858c31)

[MySQL是在server层准备向客户端发送记录的时候才会去处理LIMIT子句中的内容。 扩展二：MySQL 语句的执行顺序](https://flowus.cn/150223fb-b49c-4aef-bbff-b36c952c6109)

# 问题二：聚镞索引是什么？

[MySQL 的聚镞索引](MySQL%20的聚镞索引.md)

# 问题三：BufferPool 是什么？

[聊聊MySQL中的Buffer Pool](https://zhuanlan.zhihu.com/p/415004185)

# 怎么优化上面的语句

[MySQL Limit 优化方案](MySQL%20Limit%20优化方案.md)