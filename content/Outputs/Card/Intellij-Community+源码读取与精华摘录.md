---
aliases: []
created_date: 2023-08-23 15:31
draft: false
summary: ''
tags:
- dev
---

### 见 IDEA 的插件体系

[Plugin Structure | IntelliJ Platform Plugin SDK](https://plugins.jetbrains.com/docs/intellij/plugin-structure.html)

```Java
ComponentService#preloadServices 
```

### IDEA 的 UI 体系

|类|说明|
|-|-|
|com.intellij.util.ui.EDT|线程判断类|
||比 SwingUtilities.isEventDispatchThread() 性能更好|
||结合|
||IdeEventQueue|
||一起使用|
|com.intellij.ide.IdeEventQueue||

IdeaForkJoinWorkerThreadFactory

```Java
public final class IdeaForkJoinWorkerThreadFactory implements ForkJoinPool.ForkJoinWorkerThreadFactory {

  // must be called in the earliest possible moment on startup, but after Main.setFlags()
  public static void setupForkJoinCommonPool(boolean headless) {
    System.setProperty("java.util.concurrent.ForkJoinPool.common.threadFactory", IdeaForkJoinWorkerThreadFactory.class.getName());
    boolean parallelismWasNotSpecified = System.getProperty("java.util.concurrent.ForkJoinPool.common.parallelism") == null;
    if (parallelismWasNotSpecified) {
      int N_CPU = Runtime.getRuntime().availableProcessors();
      // By default, FJP initialized with the parallelism=N_CPU - 1
      // so in case of two processors it becomes parallelism=1 which is too unexpected.
      // In this case force parallelism=2
      // In case of headless execution (unit tests or inspection command-line) there is no AWT thread to reserve cycles for, so dedicate all CPUs for FJP
      if (headless || N_CPU == 2) {
        System.setProperty("java.util.concurrent.ForkJoinPool.common.parallelism", String.valueOf(N_CPU));
      }
    }
  }

@Override
public ForkJoinWorkerThread newThread(ForkJoinPool pool) {
  final int n =setNextBit();
  //System.out.println("New  FJP thread "+n);
  ForkJoinWorkerThread thread = new ForkJoinWorkerThread(pool) {
    @Override
    protected void onTermination(Throwable exception) {
      //System.out.println("Exit FJP thread "+n);
			clearBit(n);
      super.onTermination(exception);
    }
  };
  thread.setName("JobScheduler FJ pool " + n + "/" + pool.getParallelism());
  thread.setPriority(Thread.NORM_PRIORITY- 1);
  return thread;
	}
}
```

这里是有一个比较有意思的点，priority 这个东西的设置。

通过 forkjoinpool 设置的 thread 优先级会相对变弱一点。

如果变弱， 那么在整个线程调度中，就会偏弱。

并行执行服务一：FontFamilyServiceImpl

```Java
Font[] fonts = GraphicsEnvironment.getLocalGraphicsEnvironment().getAllFonts();
      for (Font font : fonts) {
        Font2D font2D = (Font2D)GET_FONT_2D_METHOD.invoke(font);
        String fontName = font.getName();
        String font2DName = font2D.getFontName(null);
        if (font2DName.startsWith(Font.DIALOG) && !fontName.startsWith(Font.DIALOG)) {
          // skip fonts that are declared as available, but cannot be used due to some reason,
          // with JDK substituting them with Dialog logical font (on Windows)
          if (VERBOSE_LOGGING) {
            LOG.info("Skipping '" + fontName + "' as it's mapped to '" + font2DName + "' by the runtime");
          }
          continue;
        }
        String family = (String)GET_TYPO_FAMILY_METHOD.invoke(font2D);
        String subfamily = (String)GET_TYPO_SUBFAMILY_METHOD.invoke(font2D);
        FontFamily fontFamily = myFamilies.computeIfAbsent(family, FontFamily::new);
        fontFamily.addFont(subfamily, font);
      }
```

Dnd-DragAndDrop

Aware 的命名

[Spring Aware 到底是个啥？_yusimiao的博客-CSDN博客](https://blog.csdn.net/yusimiao/article/details/99301137?spm=1035.2023.3001.6557&utm_medium=distribute.pc_relevant_bbs_down_v2.none-task-blog-2~default~OPENSEARCH~Rate-1-99301137-bbs-310190551.pc_relevant_bbs_down_v2_default&depth_1-utm_source=distribute.pc_relevant_bbs_down_v2.none-task-blog-2~default~OPENSEARCH~Rate-1-99301137-bbs-310190551.pc_relevant_bbs_down_v2_default)

LafManager - LookAndFeel