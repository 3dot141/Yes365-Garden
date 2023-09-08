---
aliases: []
created_date: 2023-08-25 09:46
draft: false
summary: ''
tags:
- dev
---

> [Graphics2D的RenderingHints方法参数详解\_graphics2d setrenderinghint\_u010142437的博客-CSDN博客](https://blog.csdn.net/u010142437/article/details/102871754)

RenderingHints 类定义了多种着色微调，它们存储在一个映射集的 Graphics2D 对象里。setRenderingHint() 方法的参数是一个键值对的形式。

下面详细介绍各个常用键值的含义：

1. KEY_ANTIALIASING 决定是否使用抗锯齿。当着色有倾斜角度的线时，通常会得到一组阶梯式的像素排列，使这条线看上去不平滑，经常被称为锯齿状图形。抗锯齿是一种技术，它设置有倾斜角度的线的像素亮度，以使线看起来更平滑。因此，这个微调是用来决定在着色有倾斜角度的线时是否在减少锯齿状图形上花费时间。可能的值有 VALUE_ANTIALIAS_ON（使用抗锯齿）、VALUE_ANTIALIAS_OFF（不使用抗锯齿） 和 VALUE_ANTIALIAS_DEFAULT（默认的抗锯齿）。  
2. KEY_COLOR_RENDERING 控制颜色着色的渲染方式。可能的值有 VALUE_COLOR_RENDER_SPEED（追求速度）VALUE_COLOR_RENDER _QUALITY（追求质量） 和 VALUE_COLOR_RENDER_DEFAULT（默认）。 
3. KEY_DITHERING 控制如何处理抖动。抖动是用一组有限的颜色合成出一个更大范围的颜色的过程，方法是给相邻像素着色以产生不在该组颜色中的新的颜色幻觉。可能的值有 VALUE_DITHER_ENABLE（不抖动）、VALUE_DITHER _DISABLE （抖动）和 VALUE_DITHER_DEFAULT（默认）。 
4. KEY_FRACTIONALMETRICS  字体规格。可能的值有 VALUE_FRACTIONALMETRICS_ON（启用字体规格）、VALUE_FRACTIONALMETRICS_OFF（禁用字体规格） 和 VALUE_FRACTIONALMETRICS _DEFAULT（默认）。 
5. KEY_INTERPOLATION 确定怎样做内插。在对一个源图像做变形时，变形后的像素很少能够恰好对应目标像素位置。在这种情况下，每个变形后的像素的颜色值不得不由周围的像素决定。内插就是实现上述过程。有许多可用的技术，可能的值，按处理时间从最多到最少，是 VALUE_INTERPOLATION_BICUBIC、 VALUE_INTERPOLATION_BILINEAR 和 VALUE_INTERPOLATION_NEAREST_NEIGHBOR。 
6. KEY_RENDERING 确定着色技术，在速度和质量之间进行权衡。可能的值有 VALUE_RENDERING_SPEED（追求速度）、VALUE_RENDERING _QUALITY（追求质量） 和 VALUE_RENDERING_DEFAULT（默认）。
7. KEY_TEXT_ANTIALIASING 确定对文本着色时是否抗锯齿。可能的值有 VALUE_TEXT_ANTIALIASING_ON（使用抗锯齿呈现文本）、VALUE_TEXT_ANTIALIASING _OFF （不使用抗锯齿呈现文本）和 VALUE_TEXT_ANTIALIASING _DEFAULT（使用平台默认的文本抗锯齿模式呈现文本）。 
8. KEY_ALPHA_INTERPOLATION  代表 alpha 合成微调的键，该微调可能的值有 VALUE_ALPHA_INTERPOLATION_SPEED（追求速度）、VALUE_ALPHA_INTERPOLATION_QUALITY（追求质量）和 VALUE_ALPHA_INTERPOLATION_DEFAULT，代表平台缺省值。
9. KEY_STROKE_CONTROL 笔划规范化控制，可能有的值有VALUE_STROKE_NORMALIZE、VALUE_STROKE_PURE和VALUE_STROKE_DEFAULT