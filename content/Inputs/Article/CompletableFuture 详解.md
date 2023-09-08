---
aliases: []
created_date: 2023-08-25 16:00
draft: false
summary: ''
tags:
- dev
---

## 为什么需要

> 主要是因为 jdk1.5 引入了 future， 这种异步开发的方式后，实际使用效果并不优雅。

1. Future 获取结果的方式很不优雅，还是需要通过阻塞（或者轮训）的方式。

```JavaScript
public static void main(String[] args) {
        ExecutorService executorService = Executors.newFixedThreadPool(10);
        final Future<?> submit = executorService.submit(() -> {
            try {
                TimeUnit.SECONDS.sleep(5);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        });
        while (!submit.isDone()) {

        }
        System.out.println(" finished");
    }
```

1. Future API 没有流式异常处理

```JavaScript
try {
	future.get()
} catch(exception e) {
	...
}
```

1. 多个 Future 不能串联在一起组成链式调用

  有时候你需要执行一个长时间运行的计算任务，并且当计算任务完成的时候，你需要把它的计算结果发送给另外一个长时间运行的计算任务等等。你会发现你无法使用 Future 创建这样的一个工作流。

  正常的逻辑

```Java
//thread1-future
result = future.get()
future2 = executor.submit(result)
return future2.get()
```

1. 组合多个 Future 的结果。假设你有 10 个不同的 Future，你想并行的运行，然后在它们运行完成后运行一些函数

  ```Java
//scene-1
比较哪一个任务运行的快，输出哪一个
future1 / future2
ouput (compareSpeed(future1, future2))

//scene-2
future1 / 2 / 3 / 4 xxx / 10
get() + ... + get()
```

## 如何使用

### 创建对象

```Java
public boolean complete(T value)
public boolean completeExceptionally(Throwable ex)

public static CompletableFuture<Void>   runAsync(Runnable runnable)
public static CompletableFuture<Void>   runAsync(Runnable runnable, Executor executor)
public static <U> CompletableFuture<U>  supplyAsync(Supplier<U> supplier)
public static <U> CompletableFuture<U>  supplyAsync(Supplier<U> supplier, Executor executor)
```

以 Async 结尾并且没有指定 Executor 的方法会使用 ForkJoinPool.commonPool() 作为它的线程池执行异步代码。

以下我将会省略 Async 的后缀

### 中间过程

- 转换（thenApply）- Function

  ```Java



public <U> CompletableFuture<U> thenApply(Function<? super T,? extends U> fn)

```

- 消费（thenAccept）- Consumer

  ```Java
public CompletableFuture<Void>  thenAccept(Consumer<? super T> action)
```

- 运行（thenRun) - Runnable

  ```Java



public CompletableFuture<Void> thenRun(Runnable action)

```

- 二者都 (both)

  ```Java
public <U> CompletableFuture<Void> thenAcceptBoth(CompletionStage<? extends U> other, BiConsumer<? super T,? super U> action)
public     CompletableFuture<Void> runAfterBoth(CompletionStage<?> other,  Runnable action)
```

  这里出现了 `CompletionStage` , 这个单词的意思是什么呢？

  `CompletionStage` 接口表示异步处理的一个 **阶段（stage）**， 也就是说这代表着阶段的组合。

  `Bixxx` 感知上也是一个知识点

  BiFunction-BinaryFunction

  说明：原先的一个参数，变成两个参数。

- 合并（thenCombine）

  ```Java



public <U,V> CompletableFuture<V> thenCombine(CompletionStage<? extends U> other, BiFunction<? super T,? super U,? extends V> fn)

```

- 取速度最快的其中之一 (either)

  ```Java
public CompletableFuture<Void>  acceptEither(CompletionStage<? extends T> other, Consumer<? super T> action)
public <U> CompletableFuture<U>  applyToEither(CompletionStage<? extends T> other, Function<? super T,U> fn)
public CompletableFuture<Void> runAfterEither(CompletionStage<?> other, Runnable action)
```

- 组合（thenCompose）

  > 将上一轮的返回值作为参数，生成一个新的 CompletableFuture

[Future 接口](Future%20接口.md)

  ```Java
public <U> CompletableFuture<U> thenCompose(Function<? super T,? extends CompletionStage<U>> fn)
```

  注意这里的参数 `? extends CompletionStage` 表示是返回 CompletionStage 的。

  有点像 `thenApplyBoth、thenCombine` , 但是这里相当于形成一个新的有着依赖链的 `CompletionFuture`

  和 `thenApply` 很像，这两个方法之间的差异类似于 `map()` 和 `flatMap()` 之间的差异。

- 全部 （allOf) | 任意 (anyOf)

```Java

public static CompletableFuture<Void> allOf(CompletableFuture<?>… cfs);  
public static CompletableFuture<Object> anyOf(CompletableFuture<?>… cfs);

```

  由于 `allOf` 返回的是 `CompletableFuture<Void>` 因此只能用来等待所有 future 完成或者其中一个失败。

  如果你用过 `Guava` 的 `Future`s 类，你就会知道它的 `Futures` 辅助类提供了很多便利方法，用来处理多个 `Future`，比如 `Futures.allAsList`，但是对于 `CompletableFuture`，我们需要一些辅助方法：

  ```Java
// 写成 sequence 是因为和 scala 的 api 保持一致
public static <T> CompletableFuture<List<T>> sequence(List<CompletableFuture<T>> futures) {
       CompletableFuture<Void> allDoneFuture = CompletableFuture.allOf(futures.toArray(new CompletableFuture[futures.size()]));
       return allDoneFuture.thenApply(v -> futures.stream().map(CompletableFuture::join).collect(Collectors.<T>toList()));
   }
public static <T> CompletableFuture<Stream<T>> sequence(Stream<CompletableFuture<T>> futures) {
       List<CompletableFuture<T>> futureList = futures.filter(f -> f != null).collect(Collectors.toList());
       return sequence(futureList);
   }
```

- 将 `Future` 转化成 `CompletableFuture`

  ```Java



public static <T> CompletableFuture<T> toCompletable(Future<T> future, Executor executor) {  
    return CompletableFuture.supplyAsync(() -> {  
        try {  
            return future.get();  
        } catch (InterruptedException | ExecutionException e) {  
            throw new RuntimeException(e);  
        }  
    }, executor);  
}

```

### 计算结束

```Java
// 只处理，不转换
public CompletableFuture<T>     whenComplete(BiConsumer<? super T,? super Throwable> action)
public CompletableFuture<T>     whenCompleteAsync(BiConsumer<? super T,? super Throwable> action)
public CompletableFuture<T>     whenCompleteAsync(BiConsumer<? super T,? super Throwable> action, Executor executor)
public CompletableFuture<T>     exceptionally(Function<Throwable,? extends T> fn)

// 即转化还处理
public <U> CompletableFuture<U>     handle(BiFunction<? super T,Throwable,? extends U> fn)
public <U> CompletableFuture<U>     handleAsync(BiFunction<? super T,Throwable,? extends U> fn)
public <U> CompletableFuture<U>     handleAsync(BiFunction<? super T,Throwable,? extends U> fn, Executor executor)
```

### 获取结果

```Java
// 如果当前没执行，则返回 value
public T getNow(T valueIfAbsent)
// 阻塞获取结果， 抛出 unchecked 异常
public T join()
// 阻塞获取结果， 显式抛出异常
public T get() throws InterruptedException, ExecutionException
public T get(long timeout, TimeUnit unit) throws InterruptedException, ExecutionException, TimeoutEx![635](../../Attachments/e888faf32a10325517dff6ced142df01.png)5517dff6ced142df01.png)

```Java
// 核心逻辑		
@SuppressWarnings("serial")
    abstract static class Completion extends ForkJoinTask<Void>
        implements Runnable, AsynchronousCompletionTask {
        volatile Completion next;      // Treiber stack link

        /**
         * Performs completion action if triggered, returning a
         * dependent that may need propagation, if one exists.
         *
         * @param mode SYNC, ASYNC, or NESTED
         */
        abstract CompletableFuture<?> tryFire(int mode);

        /** Returns true if possibly still triggerable. Used by cleanStack. */
        abstract boolean isLive();

        public final void run()                { tryFire(ASYNC); }
        public final boolean exec()            { tryFire(ASYNC); return true; }
        public final Void getRawResult()       { return null; }
        public final void setRawResult(Void v) {}
    }
```

```Java
// 链式结构
		@SuppressWarnings("serial")
    abstract static class UniCompletion<T,V> extends Completion {
        Executor executor;                 // executor to use (null if none)
        CompletableFuture<V> dep;          // the dependent to complete
        CompletableFuture<T> src;          // source for action

        UniCompletion(Executor executor, CompletableFuture<V> dep,
                      CompletableFuture<T> src) {
            this.executor = executor; this.dep = dep; this.src = src;
        }

        /**
         * Returns true if action can be run. Call only when known to
         * be triggerable. Uses FJ tag bit to ensure that only one
         * thread claims ownership.  If async, starts as task -- a
         * later call to tryFire will run action.
         */
        final boolean claim() {
            Executor e = executor;
            if (compareAndSetForkJoinTaskTag((short)0, (short)1)) {
                if (e == null)
                    return true;
                executor = null; // disable
                e.execute(this);
            }
            return false;
        }

        final boolean isLive() { return dep != null; }
    }
```

```Java
// 具体方法
@SuppressWarnings("serial")
    static final class UniApply<T,V> extends UniCompletion<T,V> {
        Function<? super T,? extends V> fn;
        UniApply(Executor executor, CompletableFuture<V> dep,
                 CompletableFuture<T> src,
                 Function<? super T,? extends V> fn) {
            super(executor, dep, src); this.fn = fn;
        }
        final CompletableFuture<V> tryFire(int mode) {
            CompletableFuture<V> d; CompletableFuture<T> a;
            if ((d = dep) == null ||
                !d.uniApply(a = src, fn, mode > 0 ? null : this))
                return null;
            dep = null; src = null; fn = null;
            return d.postFire(a, mode);
        }
    }
```

### 源码解析

```Java
ExecutorService executorService = Executors.newFixedThreadPool(2);
    CompletableFuture cf = CompletableFuture.supplyAsync(() -> {
			// doSomething
    }, executorService).thenApplyAsync(s -> {
			// applySomething
    }, executorService);
```

并不是构建好一个树结构后，分析前后执行关系进行处理。而是 →

先异步执行 supplyAsync

```Java
private CompletableFuture<Void> uniAcceptStage(Executor e,
                                                   Consumer<? super T> f) {
        if (f == null) throw new NullPointerException();
        CompletableFuture<Void> d = new CompletableFuture<Void>();
				// 是否是异步
				// 依赖任务是否结束，可以开始当前任务？
					// 已经结束 - 同步直接执行， 异步放到线程池中执行 
        if (e != null || !d.uniAccept(this, f, null)) {
					// 未结束， 放入堆栈中
            UniAccept<T> c = new UniAccept<T>(e, d, this, f);
            push(c);
            c.tryFire(SYNC);
        }
        return d;
}
```

然后在执行 thenXX 的时候进行判断。

- 先判断源任务是否完成，
  - 如果完成，直接在对应线程执行以来任务（如果是同步，则在当前线程处理，否则在异步线程处理）
- 如果任务没有完成，直接返回，因为等任务完成之后会通过 postComplete 去触发调用依赖任务。