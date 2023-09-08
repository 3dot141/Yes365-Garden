## 导出事件

`com.fr.js.ExportJavaScript#actionJS`

## 富文本导出

`com.fr.report.core.Html2ImageUtils#html2PdfContainer`

## 换行逻辑

内置换行 `DefaultAutoChangeLine` `DefaultRotationTextDrawProvider`

- 分行内容
- 修正行高 - 计算时 `com.fr.report.core.cal.SE.Box2DCase#dealWithShrink` 
- 绘制逻辑

## 字体配置

- `com.fr.io.exporter.PDFExporter.MyFontMapper#awtToPdf` 覆写的方法。查找字体
- `com.fr.io.exporter.PDFExporter#prepareFontMapper` 插入字体
- `com.fr.io.exporter.PDFExporter#getDocument` 创建文档

	```java file:注入字体
		PdfContentByte cb = writer.getDirectContent();
		Graphics2D g2d = cb.createGraphics(reportWidth, reportHeight, prepareFontMapper());
	```

## 字体绘制

- `java.awt.FontMetrics#getAscent` 获取字体基线往上的部分高度
- `java.awt.Font#pointSize` 是实际上打印出来的高度，精度比较高为 float
- `java.awt.Font#size` 精度比较低未 int

## 根据参数分 Sheet

> 将多个 Reportlet 合并成 com.fr.web.reportlet.GroupTemplateReportlet，然后进行导出

```js
var url = 'report?viewlets='; //定义 url  
var pars = '&format=excel&__filename__=1'; //设置导出格式和导出文件名称  
var path = "${reportName}"; //获取模板名称和路径  
//获取模板中参数值，以数组形式存储，每个参数值对应一个sheet  
var json = [];
for (var i = 0; i < area.length; i++) {
    var sheet = {
        reportlet: path,
        地区: area[i]
    };
    json.push(sheet);
}
jsonStr = encodeURIComponent(JSON.stringify(json)); //对url进行encodeURIComponent编码
```

- ReportRequestService
	- com.fr.web.factory.WebletFactory#createWebletByRequest
	- com.fr.web.reportlet.GroupReportletCreator#createWebletByRequest

```java
@Override  
public Weblet createWebletByRequest(HttpServletRequest req, HttpServletResponse res) {  
	TemplatePathNode node = queryPath(req);  
	String reportlets = node.getPath();  
	boolean pageNumber = !"false".equals(WebUtils.getHTTPRequestParameter(req, ParameterConstants.__CUMULATE_PAGE_NUMBER__));  
	Actor actor = createActor(req);  

	// 决定是否直接走 GroupTemplate 还是通过 OldWeblet 来 redirect
	if (oldWebletOrServletCheck(req, node)) {
		String op = WebUtils.getHTTPRequestParameter(req, ParameterConstants.OP);  
		if ("getSessionID".equals(op)) {  
			GroupTemplateReportlet multiTemplateReportlet = new GroupTemplateReportlet(  
					reportlets, actor, WebUtils.parameters4SessionIDInfor(req), pageNumber);  
			return OldWeblet.asOldReportlets(reportlets).bindRealReportlet(multiTemplateReportlet);  
		}
		return OldWeblet.asOldReportlets(reportlets);  
	}
	return new GroupTemplateReportlet(  
			reportlets, actor, WebUtils.parameters4SessionIDInfor(req), pageNumber);  
}
```

- OldWeblet 将处理参数，将 reportlets 转换成 viewlets ， 并转发一次请求
- GroupTemplate 将组合每一个 Reportlets, 计算后，将结果表保存下来。
	- com.fr.web.reportlet.GroupTemplateReportlet#createReport

```java fold
ReportSessionIDInfor sessionIDInfor = new ReportSessionIDInfor(para, tplName, getActor());  
sessionIDInfor.updateTableDataSource();  
sessionId = SessionPoolManager.addSessionIDInfor(sessionIDInfor);  
para.put(SessionInfo.SESSIONID.toString(), sessionId);
// tbook 是 templateBook
// rbook 是 resultBook
rbook = executeWorkBookInGroup(tbook, para);
```

## 问题

### 通过 scale 方式放大/缩小字体的效果

![505](../../../Attachments/778f83da9fd46d78a5bf0bb72b053bef_MD5.png)

不同的行，宽度不一样？  
需要研究一下。

### FontMetrics 计算宽度差异

- chromius  
	![350](../../../Attachments/bef8f6ab2b4956a423fc1e88ba83c45f_MD5.png)
- JDK 计算宽度  
	![480](../../../Attachments/fc318475144c3325dcb206cdf526f3b5_MD5.png) 

就很尴尬，都不完全一样。甚至 `javafx` 和 `awt` 算出来都不一样。就离谱。  
那理论上肯定是要往高了算，这样才能不遮挡吧。

如果想要完全和前端一致的方案，那么是否可以用 j2v8 然后使用 [前端字体方案](../../../Daily/2023/2023-07-06.md#JS%20FontMetrics) 来展示呢
