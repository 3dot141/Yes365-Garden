---
aliases: []
created_date: 2023-08-25 16:00
draft: false
summary: ''
tags:
- dev
---

## JDK 源码

见 `jdk` 通用的获取字体的方案

```java
GraphicsEnvironment ge = GraphicsEnvironment.getLocalGraphicsEnvironment();
String[] availableFontFamilyNames = ge.getAvailableFontFamilyNames(Locale.getDefault());
System.out.println(Arrays.toString(availableFontFamilyNames));
```

但是这种方案在 mac 上有问题。jdk1.8-jdk20 均出现无法正常显示 【中文】名称的问题

看 jdk 的源码，只能定位到

```java file:src/java.desktop/macosx/native/libawt_lwawt/font/AWTFont.m:333

	// 调用 java 方法
	static JNF_CLASS_CACHE(jc_CFontManager,  
	"sun/font/CFontManager");  
	static JNF_MEMBER_CACHE(jm_registerFont, jc_CFontManager,  
	"registerFont",  
	"(Ljava/lang/String;Ljava/lang/String;)V");  
	  
	jint num = 0;  
	  
	JNF_COCOA_ENTER(env);  

	// 获取所有的过滤的 fonts
	NSArray *filteredFonts = GetFilteredFonts();  
	num = (jint)[filteredFonts count];  
	  
	jint i;  
	for (i = 0; i < num; i++) {  
		NSString *fontname = [filteredFonts objectAtIndex:i];  
		jobject jFontName = JNFNSToJavaString(env, fontname);  
		jobject jFontFamilyName =  
		JNFNSToJavaString(env, GetFamilyNameForFontName(fontname));  
		  
		JNFCallVoidMethod(env, jthis,  
		jm_registerFont, jFontName, jFontFamilyName);  
		(*env)->DeleteLocalRef(env, jFontName);  
		(*env)->DeleteLocalRef(env, jFontFamilyName);
	}
```

如图，核心在 `GetFilteredFonts` , 然而无法确认 mac 上出现问题的原因。

### 替代方案，注册字体

通过获取所有的字体路径，然后通过

```java
	FontManagerForSGE fontManagerForSGE = SunGraphicsEnvironment.getFontManagerForSGE();
	if (fontManagerForSGE instanceof CFontManager) {
		CFontManager fontManager = (CFontManager) fontManagerForSGE;
		fontManager.registerFontsInDir("/Users/3dot141/Library/Fonts");
		fontManager.registerFontsInDir("/System/Library/Fonts");
		fontManager.registerFontsInDir("/System/Library/Fonts/Supplemetal");

		// 有缓存，需要清理一下
		Method initialiseDeferredFont = SunFontManager.class.getDeclaredMethod("initialiseDeferredFonts");
		initialiseDeferredFont.setAccessible(true);
		initialiseDeferredFont.invoke(fontManager);
		
		// 清理 locale
		Field lastDefaultLocale = SunFontManager.class.getDeclaredField("lastDefaultLocale");
		lastDefaultLocale.setAccessible(true);
		lastDefaultLocale.set(fontManager, null);
	}
```

将字体注入

### 替代方案 JRE 中的字体能够正常加载

```java file:constructor
SunFontManager.this.registerFontsInDir(SunFontManager.jreFontDirName, true, 2, true, false);
```

通过这种方式注册的字体，是直接生成的 `TrueTypeFont`, 而不是默认的 `CFont`

## Mac 字体位置

![490](../../Attachments/6732daa76db3c01a9ffa0019459afcb7_MD5.png)

如图，只要鼠标移上去即可找到  
字体类型见 [2023-06-26#字体类型](../../Daily/2023/2023-06-26.md#字体类型)