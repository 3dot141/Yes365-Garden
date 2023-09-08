---
aliases: []
created_date: 2023-08-25 16:00
draft: false
summary: ''
tags:
- dev
---

现象是带有滚动条![500](../../Attachments/54674f9868522781136bc912d40076ad.png)

测试提供的思路  

![500](../../Attachments/9d1d84fefbe88d599e74f90873fe8939.mp4)

我尝试复现，发现这个现象是由于变更了页面的 viewport 导致的。

原先的 viewport 更大， 然后我将 viewport 缩小到合理的范围后，导致整个页面缩小了。

- 这里涉及一个概念页面的 viewport

  简单讲一下，看到的页面是经过 chrome + windows 转化后的大小。

  chrome 内部处理时，会有 （窗口大小 - [[windows系统显示逻辑]] ）* deviceScaleFactor ，才会得到你看到的页面

  边框大小视不同的系统，而不同。这里是 winserver2012, 照着 win8 改过来的。和 win8 一致的系统。

实际截图时，会截取缩小后的页面。所以并没有影响。

继续处理，发现我的 imac 访问，和 angle 的 windows 访问，滚动条大小不一样。

猜测，如果继续用 paul 的电脑（原来就是他的电脑

可能就不![500](../../Attachments/cd42bd221b2cfd2a7d4e306d0c9a8ea0.png)e306d0c9a8ea0.png)

---

等 paul 回来后，验证，发现依然存在问题。于是决定深刻的研究一下。

# 首先是滚动条大小的问题，究竟差别多少？

首先是

OSX (Chrome, Safari, Firefox) - **15px**

OSX (Chrome，Safari，Firefox)-15px

Windows XP (IE7, Chrome, Firefox) - **17px**

Windows XP (IE7，Chrome，Firefox)-17px

Windows 7 (IE10, IE11, Chrome, Firefox) - **17px**

Windows 7(IE10，IE11，Chrome，Firefox)-17px

Windows 8.1 (IE11, Chrome, Firefox) - **17px**

Windows 8.1(IE11，Chrome，Firefox)-17px

Windows 10 (IE11, Chrome, Firefox) - **17px**

Windows 10(IE11，Chrome，Firefox)-17px

Windows 10 (Edge 12/13) - **12px**

Windows10(边缘 12/13)-12px

[Browser Scrollbar Widths (2018)](https://codepen.io/sambible/post/browser-scrollbar-widths)

其次是如何确认当前浏览器的滚动条大小？

可以直接点击 [这个链接](https://adminhacks.com/scrollbar-size/)，即可获取当前浏览器的滚动条大小。

发现

通过驱动启动的浏览器，滚动条大小是 21px，而直接启动的浏览器是 17px。

17px 是符合规范的。

---

# 那如果我将滚动条修改为 17px，是不是就可以了呢？

思路有两个

[ChromeDriver - WebDriver for Chrome - Capabilities & ChromeOptions](https://chromedriver.chromium.org/capabilities)

headless 能否启动 extensions

[Is it possible to run Google Chrome in headless mode with extensions?](https://stackoverflow.com/questions/45372066/is-it-possible-to-run-google-chrome-in-headless-mode-with-extensions)

完全没有提供默认的修改滚动条的逻辑

- ::[webkit-scrollbar](https://developer.mozilla.org/en-US/docs/Web/CSS/::-webkit-scrollbar)
- ::[How to change the Scrollbar width](https://deletingsolutions.com/how-to-change-scrollbars-width-in-chrome-and-firefox-on-windows-11-or-10/)
- :: 案例 -[custom-scrollbar](https://chrome.google.com/webstore/detail/custom-scrollbars/ddbipglapfjojhfapmpmofnaoellkggc?hl=en)

滚动条实现起来比较麻烦，且不一定能完全和默认的一致。

于是，思路变更为：为什么变成了 21 px 呢？

---

# 所以为什么是 21px 呢？

还记得我之前联想到的 undefined 我考虑是不是缩放的问题

而 chromedriver 启动的版本有不同的参数，导致启动后的 chrome 的缩放表现不一样。

控制变量法 + 二分法尝试，保持在同一个电脑上，修改 chromedriver 的启动参数。

发现和参数 **`force-device-scale-factor=1`** 有关系。

如果开启了 **`force-device-scale-factor=1`** 这个参数，就会让 chrome 默认不依赖当前的分辨率进行缩放。

从而保证 可用内容 的所见所得完全一致。

***估计是有 BUG，导致内容没有缩放，但是滚动条缩放了***

但是这里又不能不加，不然截图出来的图片大小，因为依赖 viewport , 因此会变更。

怎么办呢？这里想到，既然还是缩放的问题，说白了，就是

`force-scale` 和 `real-scale` 不一致导致的问题，那只要让 `scale` 一致不就可以啦？

---

# 那怎么确认 scale 被什么东西影响的呢？

首先还是从 undefined 这里原理性的东西入手。

既然是 scale ，那是不是和 **分辨率** 或者 windows 上独有的 **缩放** 有关系？

首先尝试分辨率，发现没区别。

然后尝试缩放，发现这就是关键。

当你使用缩放的时候，windows 上的缩放及其混乱 [系统显示逻辑](https://flowus.cn/487c7157-2ed9-4de7-a93d-600ca4400a06)

因此，出现 scale 被影响的情况。

---

# 那么怎么保持缩放没问题的呢？

正常的电脑，直接保证缩放是 100% 即可。

**但是因为是远程的电脑，所以远程的时候，会被你当前的系统所影响**

因此，如果要保证缩放是 100% ，那么必须让你当前的电脑保证是 100% 的缩放。

  - mac 系统，尝试使用 imac 发现不行，尝试使用 mbp 可以

    怀疑是电脑屏幕分辨率的问题， mbp 分辨率相对来说比较的低，而 imac 分辨率为 5k。参考 [修改虚拟机win系统的缩放](https://flowus.cn/c8d453e5-82ef-4b32-b98a-4d6b7aec6830) ，猜测，可能也有对应的设置，导致会直接根据分辨率锁定一些图像相关的配置。

  **因此，windows 系统也尽量使用笔电，且保证 100% 缩放后。作为标记跳板。在服务器第一次重启后，连接。固化配置。**

---

# 结论

即保证缩放没问题即可。

# 那么怎么保持缩放没问题的呢？

正常的电脑，直接保证缩放是 100% 即可。

**但是因为是远程的电脑，所以远程的时候，会被你当前的系统所影响**

因此，如果要保证缩放是 100% ，那么必须让你当前的电脑保证是 100% 的缩放。

  - mac 系统，尝试使用 imac 发现不行，尝试使用 mbp 可以

    怀疑是电脑屏幕分辨率的问题， mbp 分辨率相对来说比较的低，而 imac 分辨率为 5k。参考 [修改虚拟机win系统的缩放](https://flowus.cn/c8d453e5-82ef-4b32-b98a-4d6b7aec6830) ，猜测，可能也有对应的设置，导致会直接根据分辨率锁定一些图像相关的配置。

  **因此，windows 系统也尽量使用笔电，且保证 100% 缩放后。作为标记跳板。在服务器第一次重启后，连接。固化配置。**