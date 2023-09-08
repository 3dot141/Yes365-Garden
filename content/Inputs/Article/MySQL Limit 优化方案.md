---
aliases: []
created_date: 2023-09-04 16:47
draft: false
summary: ''
tags:
- dev
---

#dev/mysql  

模板

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

### 主键 id 有序 - 子查询优化

```Java
select * from test where val=4 and id >= (select id from test where val=4 limit 300000,1) limit 5
```

### 主键 id 是无序 -inner join 优化

```Java
mysql> select * from test a inner join (select id from test where val=4 limit 300000,5) b on a.id=b.id;
+---------+-----+--------+---------+
| id      | val | source | id      |
+---------+-----+--------+---------+
| 3327622 |   4 |      4 | 3327622 |
| 3327632 |   4 |      4 | 3327632 |
| 3327642 |   4 |      4 | 3327642 |
| 3327652 |   4 |      4 | 3327652 |
| 3327662 |   4 |      4 | 3327662 |
+---------+-----+--------+---------+
5 rows in set (0.38 sec)
```

> Tips:  
这里有一个注意点 val 是需要有索引的。不然速度也会比较慢。

问题：为什么这样处理就好了呢？