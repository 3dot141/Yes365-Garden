
- `com.fr.js.ReportletHyperlink#actionJS` 超链接的 js 值
- `com.fr.web.factory.WebletFactory#createWebletByRequest`
	- `com.fr.web.reportlet.OldWeblet`
		- 兼容 'ReportServer', 并转发

## Tips

### 计算时的并发问题

可能由于 clone 时候的同一个对象引起的。  
如果 clone 时没有进行深拷贝，那么就可能出现问题。

那么什么时候会要拷贝呢，比如参数，比如抽数缓存对模板的缓存。

- [定时调度-邮件多个收件人时发送数据出错](https://kms.fineres.com/pages/viewpage.action?pageId=646712074)
