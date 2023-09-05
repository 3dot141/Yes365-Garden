## 格式

> [!note] 默认格式
> - rtf

[RTF 格式](../../Outputs/Card/RTF%20格式.md)

### 格式转化

用 word 打开，然后另存为  
![525](../../../Attachments/e3c05abacfe004211465b4e0fbf33e4e_MD5.png)  
发现默认就是 rtf 格式，然后转化成 doc 格式。  
wps 基本是与 word 保持一致。

## 页眉页脚

> [!bug] 限制
> - 页眉页脚只会被处理一次，所以不能为所有的页面个性化定制

- `com.fr.io.exporter.WordExporter#checkHFShowAsImage` 检测页眉页脚是否需要转变成图片
- `com.fr.io.exporter.WordExporter#adjustRowHeight` 调整行高，防止溢出
	- **所以字体大小不重要？**
- RTF 格式的文件本身是依次填入的。不存在选择位置。只有 width / height 决定大小/宽度。是否可以正常展示
	- `com.fr.third.com.lowagie.text.Table#setWidth` 这个 width 是百分比，实在是绝

## 问题

问题一：页眉页脚的表格不会跟随页边距  
![480](../../../Attachments/1051e5ead5f2461d19edfb722db28811_MD5.png)
