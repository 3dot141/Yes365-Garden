---
aliases: []
created_date: 2023-09-04 16:47
draft: false
summary: ''
tags:
- dev
---

#dev/mysql  
[关于MySQL的SLEEP(N)函数](https://blog.csdn.net/zyz511919766/article/details/42241211)

都知道通过在 MySQL 中执行 select sleep(N) 可以让此语句运行 N 秒钟：  

```sql
mysql> select sleep(1);
+----------+
| sleep(1) |
+----------+
|        0 |
+----------+
1 row in set (1.00 sec)
```

返回给客户端的执行时间显示出等待了 1 秒钟  

借助于 sleep(N) 这个函数我们可以在 MySQL Server 的 PROCESSLIST 中捕获到执行迅速不易被查看到的语句以确定我们的程序是否确实在 Server 端发起了该语句。比如我们在调试时想确定一下程序是否确确实实向 Server 发起了执行 SQL 语句的请求，那么我们可以通过执行 show processlist 或者由 information_schema.processlist 表来查看语句是否出现。但往往语句执行速度可能非常快，这样的话就很难通过上述办法确定语句是否真正被执行了。例如下面语句的执行时间为 0.00 秒，线程信息一闪而过，根本无从察觉。  

```sql
mysql> select name from animals where name='tiger';
+-------+
| name  |
+-------+
| tiger |
+-------+
1 row in set (0.00 sec)
```

在这种情况下，可以通过在语句中添加一个 sleep(N) 函数，强制让语句停留 N 秒钟，来查看后台线程，例如：  

```sql
mysql> select sleep(1),name from animals where name='tiger';
+----------+-------+
| sleep(1) | name  |
+----------+-------+
|        0 | tiger |
+----------+-------+
1 row in set (1.00 sec)
```

同样的条件该语句返回的执行时间为 1.0 秒。  

但是使用这个办法是有前提条件的，也只指定条件的记录存在时才会停止指定的秒数，例如查询条件为 name='pig',结果表明记录不存在，执行时间为 0  

```sql
mysql> select name from animals where name='pig';
Empty set (0.00 sec)
```

在这样一种条件下，即使添加了 sleep(N) 这个函数，语句的执行还是会一闪而过，例如：  

```sql
mysql> select sleep(1),name from animals where name='pig';
Empty set (0.00 sec)
```

另外需要注意的是，添加 sleep(N) 这个函数后，**语句的执行具体会停留多长时间取决于满足条件的记录数，MySQL 会对每条满足条件的记录停留 N 秒钟。**  
例如，name like '%ger' 的记录有三条  

```sql
mysql> select name from animals where name like '%ger';
+-------+
| name  |
+-------+
| ger   |
| iger  |
| tiger |
+-------+
3 rows in set (0.00 sec)
```

那么针对该语句添加了 sleep(1) 这个函数后语句总的执行时间为 3.01 秒，可得出，MySQL 对每条满足条件的记录停留了 1 秒中。  

```sql
mysql> select sleep(1),name from animals where name like '%ger';
+----------+-------+
| sleep(1) | name  |
+----------+-------+
|        0 | ger   |
|        0 | iger  |
|        0 | tiger |
+----------+-------+
3 rows in set (3.01 sec)
```