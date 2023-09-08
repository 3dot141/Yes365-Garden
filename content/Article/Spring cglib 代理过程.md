---
aliases: []
created_date: 2023-09-04 16:47
draft: false
summary: ''
tags:
- dev
---

#dev/spring 

### 文章目录

* [一、前言](#_2)
* * [1\. org.springframework.cglib.proxy.Callback](#1__orgspringframeworkcglibproxyCallback_31)
* [二、代理对象的创建](#_54)
* * [1\. CglibAopProxy#getCallbacks](#1_CglibAopProxygetCallbacks_121)
    * [2\. ProxyCallbackFilter](#2_ProxyCallbackFilter_224)
* [三、Cglib 的拦截器](#Cglib__327)
* * [1\. aopInterceptor](#1_aopInterceptor_345)
    * * [1.1 ProxyFactory#getInterceptorsAndDynamicInterceptionAdvice](#11_ProxyFactorygetInterceptorsAndDynamicInterceptionAdvice_407)
        * [1.2 CglibMethodInvocation#proceed](#12_CglibMethodInvocationproceed_518)
    * [2\. targetInterceptor](#2_targetInterceptor_571)
    * [3\. SerializableNoOp](#3_SerializableNoOp_669)
    * [4\. StaticDispatcher](#4_StaticDispatcher_677)
    * [5\. AdvisedDispatcher](#5_AdvisedDispatcher_697)
    * [6\. EqualsInterceptor](#6_EqualsInterceptor_718)
    * [7\. HashCodeInterceptor](#7_HashCodeInterceptor_752)
* [四、总结](#_771)

Spring cglib 代理过程
====

本文是笔者阅读 Spring 源码的记录文章，由于本人技术水平有限，在文章中难免出现错误，如有发现，感谢各位指正。在阅读过程中也创建了一些衍生文章，衍生文章的意义是因为自己在看源码的过程中，部分知识点并不了解或者对某些知识点产生了兴趣，所以为了更好的阅读源码，所以开设了衍生篇的文章来更好的对这些知识点进行进一步的学习。

全集目录：[Spring源码分析：全集整理](https://blog.csdn.net/qq_36882793/article/details/106440723)

* * *

本文系列：

1. [Spring源码分析十一：@Aspect方式的AOP上篇 - @EnableAspectJAutoProxy](https://blog.csdn.net/qq_36882793/article/details/106745317)
2. [Spring源码分析十二：@Aspect方式的AOP中篇 - getAdvicesAndAdvisorsForBean](https://blog.csdn.net/qq_36882793/article/details/107070159)
3. [Spring源码分析十三：@Aspect方式的AOP下篇 - createProxy](https://blog.csdn.net/qq_36882793/article/details/107164934)
4. [Spring源码分析二十四：cglib 的代理过程](https://blog.csdn.net/qq_36882793/article/details/119823785)

本文衍生篇：

1. [Spring 源码分析衍生篇九 ： AOP源码分析 - 基础篇](https://blog.csdn.net/qq_36882793/article/details/105464984)
2. [Spring 源码分析衍生篇十二 ：AOP 中的引介增强](https://blog.csdn.net/qq_36882793/article/details/119874208)

补充篇：

1. [Spring 源码分析补充篇三 ：Spring Aop 的关键类](https://blog.csdn.net/qq_36882793/article/details/117568863)

* * *

本文主要内容来分析 Cglib 的代理创建和调用过程。由于 Spring Aop 的部分内容在之前的文章中有所提及，所以这里并不会从头叙述整个 Aop 过程。

Spring Aop 中会通过 自动代理创建器来创建代理类 AbstractAutoProxyCreator#createProxy，其中可选的有两种， Jdk 动态代理和 Cglib 动态代理，这里我们来看一下 cglib 动态代理。

* * *

1\. org.springframework.cglib.proxy.Callback
--------------------------------------------

**该部分内容参考： [https://blog.csdn.net/NEW_BUGGER/article/details/106350998](https://blog.csdn.net/NEW_BUGGER/article/details/106350998)**

callback 可以认为是 cglib 用于生成字节码的实现手段，cglib 一共实现了 6 种 callback，用于对代理类目标进行不同手段的代理，非常灵活，具体如下：

1. **Dispatcher** ：实现 Dispatcher 接口，要求实现 loadObject 方法，返回期望的代理类。值的一提的是，loadobject 方法在每次调用被拦截方法的时候都会被调用一次。
    
2. **FixedValue** ：实现 FixedValue 接口，该 callback 同样要求实现一个 loadobject 方法，只不过需要注意的是该 loadobject 方法相同与重写了被代理类的相应方法，因为在被代理之后，FixedValue callback 只会调用 loadobject，而不会再调用代理目标类的相应方法！
    
3. **InvocationHandler** ：需要实现 InvocationHandler 接口，实现 invoke 对象，该拦截传入了 proxy 对象，用于自定义实现，与 MethodInterceptor 相似，慎用 method 的 invoke 方法。切忌不要造成循环调用
    
4. **LazyLoader** ：实现 LazyLoader 的 loadObject 方法，返回对象实例，该实例只有第一次调用的时候进行初始化，之后不再重新调用，proxy 类初始化时进行了成员的赋值，之后使用该成员进行调用父类方法
    
5. **MethodInterceptor** ：实现 MethodInterceptor 的 intercept，实现被代理对象的逻辑植入。也是最常用的 callback
    
6. **NoOp** ：通过接口声明了一个单例对象，该代理不对被代理类执行任何操作

* * *

二、代理对象的创建
=========

Spring Aop 的代理对象创建在 `CglibAopProxy#getProxy(java.lang.ClassLoader)` 中完成。其实现如下：

```java
@Override
public Object getProxy(@Nullable ClassLoader classLoader) {
    try {
        Class < ? > rootClass = this.advised.getTargetClass();
        Assert.state(rootClass != null, "Target class must be available for creating a CGLIB proxy");

        Class < ? > proxySuperClass = rootClass;
        // 如果当前类名中包含 “$$” 则被认定为是 cglib 类。
        if (rootClass.getName().contains(ClassUtils.CGLIB_CLASS_SEPARATOR)) {
            proxySuperClass = rootClass.getSuperclass();
            Class < ? > [] additionalInterfaces = rootClass.getInterfaces();
            for (Class < ? > additionalInterface : additionalInterfaces) {
                this.advised.addInterface(additionalInterface);
            }
        }

        // Validate the class, writing log messages as necessary.
        // 校验方法的合法性，但仅仅打印了日志
        validateClassIfNecessary(proxySuperClass, classLoader);

        // Configure CGLIB Enhancer...
        // 配置 Enhancer
        Enhancer enhancer = createEnhancer();
        if (classLoader != null) {
            enhancer.setClassLoader(classLoader);
            if (classLoader instanceof SmartClassLoader &&
                ((SmartClassLoader) classLoader).isClassReloadable(proxySuperClass)) {
                enhancer.setUseCache(false);
            }
        }
        enhancer.setSuperclass(proxySuperClass);
        enhancer.setInterfaces(AopProxyUtils.completeProxiedInterfaces(this.advised));
        enhancer.setNamingPolicy(SpringNamingPolicy.INSTANCE);
        enhancer.setStrategy(new ClassLoaderAwareGeneratorStrategy(classLoader));
        // 1. 获取代理的回调方法集合
        Callback[] callbacks = getCallbacks(rootClass);
        Class < ? > [] types = new Class < ? > [callbacks.length];
        for (int x = 0; x < types.length; x++) {
            types[x] = callbacks[x].getClass();
        }
        // fixedInterceptorMap only populated at this point, after getCallbacks call above
        // 2. 添加 Callback 过滤器。
        enhancer.setCallbackFilter(new ProxyCallbackFilter(
            this.advised.getConfigurationOnlyCopy(), this.fixedInterceptorMap, this.fixedInterceptorOffset));
        enhancer.setCallbackTypes(types);

        // Generate the proxy class and create a proxy instance.
        // 创建代理对象
        return createProxyClassAndInstance(enhancer, callbacks);
    }
    ...
}
```

这里我们知道 CglibAopProxy#getCallbacks 会返回一个 Callback 集合，而 Cglib 的代理对象是通过 ProxyCallbackFilter 中的策略来确定什么场景下使用不同的 Callback。

因此下面我们来看一下这两个类的具体实现：

1\. CglibAopProxy#getCallbacks
------------------------------

CglibAopProxy#getCallbacks 是生成代理类的 Callback。具体实现如下：

```java
 `// 上面可以很明显知道，CallBack是代理增强的关键实现。
	private Callback[] getCallbacks(Class<?> rootClass) throws Exception {
		// Parameters used for optimization choices...
		// 是否暴露代理类
		boolean exposeProxy = this.advised.isExposeProxy();
		// 是否被冻结
		boolean isFrozen = this.advised.isFrozen();
		// 是否静态类，这里的静态并非指静态类，而是每次调用返回的实例都是否是不可变的
		// 如单例模式的bean就是静态，而多例模式下的bean就不是静态
		boolean isStatic = this.advised.getTargetSource().isStatic();

		// Choose an "aop" interceptor (used for AOP calls).
		// 创建 Aop 拦截器
		Callback aopInterceptor = new DynamicAdvisedInterceptor(this.advised);

		// Choose a "straight to target" interceptor. (used for calls that are
		// unadvised but can return this). May be required to expose the proxy.
		Callback targetInterceptor;
		// 根据是否包括和 静态，来生成不同的拦截器
		if (exposeProxy) {
			targetInterceptor = (isStatic ?
					new StaticUnadvisedExposedInterceptor(this.advised.getTargetSource().getTarget()) :
					new DynamicUnadvisedExposedInterceptor(this.advised.getTargetSource()));
		}
		else {
			targetInterceptor = (isStatic ?
					new StaticUnadvisedInterceptor(this.advised.getTargetSource().getTarget()) :
					new DynamicUnadvisedInterceptor(this.advised.getTargetSource()));
		}

		// Choose a "direct to target" dispatcher (used for
		// unadvised calls to static targets that cannot return this).
		Callback targetDispatcher = (isStatic ?
				new StaticDispatcher(this.advised.getTargetSource().getTarget()) : new SerializableNoOp());
		// 回调集合。其中包含aopInterceptor 中包含了 Aspect 的增强
		//  advisedDispatcher 用于判断如果method是Advised.class声明的，则使用AdvisedDispatcher进行分发
		Callback[] mainCallbacks = new Callback[] {
				aopInterceptor,  // for normal advice
				targetInterceptor,  // invoke target without considering advice, if optimized
				new SerializableNoOp(),  // no override for methods mapped to this
				targetDispatcher, this.advisedDispatcher,
				new EqualsInterceptor(this.advised),
				new HashCodeInterceptor(this.advised)
		};

		Callback[] callbacks;
		// 如果类是静态 && 配置冻结。则准备做一些优化策略
		if (isStatic && isFrozen) {
			Method[] methods = rootClass.getMethods();
			Callback[] fixedCallbacks = new Callback[methods.length];
			this.fixedInterceptorMap = new HashMap<>(methods.length);

			// TODO: small memory optimization here (can skip creation for methods with no advice)
			// 遍历所有的方法
			for (int x = 0; x < methods.length; x++) {
				Method method = methods[x];
				// 获取适用于当前方法的拦截器和动态拦截建议
				List<Object> chain = this.advised.getInterceptorsAndDynamicInterceptionAdvice(method, rootClass);
				// 封装成  callback
				fixedCallbacks[x] = new FixedChainStaticTargetInterceptor(
						chain, this.advised.getTargetSource().getTarget(), this.advised.getTargetClass());
				// 保存，此时的key 为 method， value 为当前方法适用的增强。
				this.fixedInterceptorMap.put(method, x);
			}

			// Now copy both the callbacks from mainCallbacks
			// and fixedCallbacks into the callbacks array.
			callbacks = new Callback[mainCallbacks.length + fixedCallbacks.length];
			System.arraycopy(mainCallbacks, 0, callbacks, 0, mainCallbacks.length);
			System.arraycopy(fixedCallbacks, 0, callbacks, mainCallbacks.length, fixedCallbacks.length);
			this.fixedInterceptorOffset = mainCallbacks.length;
		}
		else {
			callbacks = mainCallbacks;
		}
		return callbacks;
	}`
```

这里我们注意 Callback 数组的组成：Callback 数组是由 mainCallbacks + fixedInterceptorMap 组成。

1. mainCallbacks 数组如下，为固定的七个。具体我们后面分析。

```java
    		Callback[] mainCallbacks = new Callback[] {
    				aopInterceptor,  // for normal advice
    				targetInterceptor,  // invoke target without considering advice, if optimized
    				new SerializableNoOp(),  // no override for methods mapped to this
    				targetDispatcher, this.advisedDispatcher,
    				new EqualsInterceptor(this.advised),
    				new HashCodeInterceptor(this.advised)
    		};
    ```

2. fixedInterceptorMap 是 Spring 在静态类 和 配置冻结情况下所做的优化。当类是静态类则表示当前类单例 && 配置冻结则表示配置不会变动。那么此时方法的拦截器可以提前获取并保存到 FixedChainStaticTargetInterceptor 中。ProxyCallbackFilter 中判断如果 method 在 fixedInterceptorMap 中存在，则可以直接从 fixedInterceptorMap 中获取到适用于该方法的增强，而不需要再次查找。

**注**： 这里的所说的静态是 根据 TargetSource#isStatic 方法判断，标志用户返回当前 bean 是否为静态的，比如常见的单例 bean 就是静态的，而原型模式下就是动态的。这里这个方法的主要作用是，对于静态的 bean，spring 是会对其进行缓存的，在多次使用 TargetSource 获取目标 bean 对象的时候，其获取的总是同一个对象，通过这种方式提高效率。

2\. ProxyCallbackFilter
-----------------------

ProxyCallbackFilter 是 CglibAopProxy 的内部类，用来作为 Cglib CallBack 过滤器，在不同的场景下选择不同的 Callback 执行增强策略。下面我们来看看 ProxyCallbackFilter#accept 的具体实现 ：

```

 `// Constants for CGLIB callback array indices  
	// 这里是 Callback 数组的下标。  
	private static final int AOP_PROXY = 0;  
	private static final int INVOKE_TARGET = 1;  
	private static final int NO_OVERRIDE = 2;  
	private static final int DISPATCH_TARGET = 3;  
	private static final int DISPATCH_ADVISED = 4;  
	private static final int INVOKE_EQUALS = 5;  
	private static final int INVOKE_HASHCODE = 6;

	private static class ProxyCallbackFilter implements CallbackFilter {
		// 返回是 Callback 数组的下标
		@Override
		public int accept(Method method) {
			// 1. 如果当前方法被 final 修饰，则不代理该方法
			if (AopUtils.isFinalizeMethod(method)) {
				logger.trace("Found finalize() method - using NO_OVERRIDE");
				return NO_OVERRIDE;
			}
			// 2. 如果当前方法不透明 && 该方法是 Advised 接口声明的方法
			if (!this.advised.isOpaque() && method.getDeclaringClass().isInterface() &&
					method.getDeclaringClass().isAssignableFrom(Advised.class)) {
				return DISPATCH_ADVISED;
			}
			// We must always proxy equals, to direct calls to this.
			// 3. equals 方法 
			if (AopUtils.isEqualsMethod(method)) {
				return INVOKE_EQUALS;
			}
			// We must always calculate hashCode based on the proxy.
			// 4. hashcode 方法
			if (AopUtils.isHashCodeMethod(method)) {
				return INVOKE_HASHCODE;
			}
			// 获取代理目标类的 Class
			Class<?> targetClass = this.advised.getTargetClass();
			// Proxy is not yet available, but that shouldn't matter.
			// 获取适用于当前类的 拦截器和动态拦截建议
			List<?> chain = this.advised.getInterceptorsAndDynamicInterceptionAdvice(method, targetClass);
			boolean haveAdvice = !chain.isEmpty();
			boolean exposeProxy = this.advised.isExposeProxy();
			boolean isStatic = this.advised.getTargetSource().isStatic();
			boolean isFrozen = this.advised.isFrozen();
			// 5. 如果存在适用于当前类的拦截器和建议 || 配置没有被冻结
			if (haveAdvice || !isFrozen) {
				// If exposing the proxy, then AOP_PROXY must be used.
				// 5.1 暴露代理类
				if (exposeProxy) {
					return AOP_PROXY;
				}
				// 5.2 类为静态 && 配置冻结 && 固定拦截器中保存了该方法的配置
				// 检查是否有固定的拦截器来服务这个方法, 这里使用了 fixedInterceptorMap 做了一些优化
				// fixedInterceptorMap  key 为 Method， value 为 Integer 保存了拦截器下标。这里针对某些方法固定使用某个拦截器，不需要再动态匹配。
				if (isStatic && isFrozen && this.fixedInterceptorMap.containsKey(method)) {
					int index = this.fixedInterceptorMap.get(method);
					return (index + this.fixedInterceptorOffset);
				}
				else {
					// 5.3 否则还是使用 AOP_PROXY
					return AOP_PROXY;
				}
			}
			else {// 6. 到这里说明当前方法没有建议 && 配置冻结
			
				// 6.1. 暴露当前代理类 && 代理类不是静态
				if (exposeProxy || !isStatic) {
					return INVOKE_TARGET;
				}
				// 6.2. 如果方法返回类型还是代理类类型
				Class<?> returnType = method.getReturnType();
				if (targetClass != null && returnType.isAssignableFrom(targetClass)) {
					return INVOKE_TARGET;
				}
				else {
					// 6.3 DISPATCH_TARGET
					return DISPATCH_TARGET;
				}
			}
		}
		
		...` 

```

这里总结如下：

1. 如果 method 被 final 修饰，则无法代理，返回 2 ，执行 SerializableNoOp，即代理不会做任何事。
2. 如果 method 是 Advised 接口声明的方法，返回 4。执行 AdvisedDispatcher
3. 如果 method 是 equals 方法，返回 5， 执行 EqualsInterceptor
4. 如果 method 是 hashCode 方法，返回 6，执行 HashCodeInterceptor
5. 如果存在当前方法的拦截器或动态建议 || 配置未冻结 ：  
    1\. 如果需要暴露代理对象，返回 0。执行 DynamicAdvisedInterceptor。这是常规的逻辑  
    2\. 如果 类静态 && 配置冻结 && fixedInterceptorMap 中缓存了该方法，则使用 fixedInterceptorMap 中的 Callback，返回计算出来的下标。执行的是在 CglibAopProxy#getCallbacks 中包装的 FixedChainStaticTargetInterceptor 类型  
    3\. 不满足 5.2 的情况执行返回 0。执行 DynamicAdvisedInterceptor。这是常规的逻辑
6. 如果不存在当前方法的拦截器或动态建议 && 配置已经冻结 ：
    1. 如果需要暴露代理对象 || 对象非静态 ，返回 1。这里根据情况的不同可以为 StaticUnadvisedExposedInterceptor、DynamicUnadvisedExposedInterceptor、StaticUnadvisedInterceptor、DynamicUnadvisedInterceptor，本质上没有多少区别，主要是对 exposeProxy 属性的处理
    2. 如果代理对象类型派生于 方法返回类型，返回 1。同上
    3. 不满足 6.2 返回 3。如果是静态类执行 StaticDispatcher， 否则执行 SerializableNoOp。

三、Cglib 的拦截器
============

上面我们看到 Cglib 默认的 mainCallbacks 如下：

```java
		Callback[] mainCallbacks = new Callback[] {
		    aopInterceptor, // for normal advice
		    targetInterceptor, // invoke target without considering advice, if optimized
		    new SerializableNoOp(), // no override for methods mapped to this
		    targetDispatcher,
		    this.advisedDispatcher,
		    new EqualsInterceptor(this.advised),
		    new HashCodeInterceptor(this.advised)
		};
```

下面我们逐一来看：

1\. aopInterceptor
------------------

aopInterceptor 的实现类是 DynamicAdvisedInterceptor，实现了 MethodInterceptor 接口 用来处理常规的代理逻辑。结构如下：  
![505](../../Attachments/e996482dc1ca39facf681a895c44a1e4_MD5.png)

我们直接来看看 DynamicAdvisedInterceptor#intercept 的具体实现，如下：

```
 `@Override
	@Nullable
	public Object intercept(Object proxy, Method method, Object[] args, MethodProxy methodProxy) throws Throwable {
		Object oldProxy = null;
		boolean setProxyContext = false;
		Object target = null;
		// 获取目标数据
		TargetSource targetSource = this.advised.getTargetSource();
		try {
			// 如果暴露代理对象，则设置到全局上下文中
			if (this.advised.exposeProxy) {
				// Make invocation available if necessary.
				oldProxy = AopContext.setCurrentProxy(proxy);
				setProxyContext = true;
			}
			// Get as late as possible to minimize the time we "own" the target, in case it comes from a pool...
			// 获取目标对象
			target = targetSource.getTarget();
			Class<?> targetClass = (target != null ? target.getClass() : null);
			// 1. 获取 适用于当前类的当前方法的 获取拦截器和动态拦截建议
			List<Object> chain = this.advised.getInterceptorsAndDynamicInterceptionAdvice(method, targetClass);
			Object retVal;
			// 如果没有建议链则说明对该方法不需要增强，直接调用即可
			if (chain.isEmpty() && Modifier.isPublic(method.getModifiers())) {
				// 即当前 args 的参数类型可能与实际方法调用的类型有些区别，这里转换成实际方法的参数类型。特别是，如果给定的可变参数数组与方法中声明的可变参数的数组类型不匹配。
				Object[] argsToUse = AopProxyUtils.adaptArgumentsIfNecessary(method, args);
				// 调用目标类的目标方法
				retVal = methodProxy.invoke(target, argsToUse);
			}
			else {
				// We need to create a method invocation...
				// 2. 创建一个 方法调用类，里面封装了相关信息，然后通过 proceed 方法调用
				retVal = new CglibMethodInvocation(proxy, target, method, args, targetClass, chain, methodProxy).proceed();
			}
			// 处理返回值。 即，如果返回值还是 target。则替换为 代理的proxy
			retVal = processReturnType(proxy, target, method, retVal);
			return retVal;
		}
		finally {
			if (target != null && !targetSource.isStatic()) {
				targetSource.releaseTarget(target);
			}
			if (setProxyContext) {
				// Restore old proxy.
				AopContext.setCurrentProxy(oldProxy);
			}
		}
	}` 



```

注释已经写的比较清楚，这里我们关注下面两点：

1. `this.advised.getInterceptorsAndDynamicInterceptionAdvice(method, targetClass)` ： 这里的 this.advised 实现是 ProxyFactory
2. `new CglibMethodInvocation(proxy, target, method, args, targetClass, chain, methodProxy).proceed()` ：这里的 `CglibMethodInvocation#proceed` 方法完成了拦截器链的调用。

### 1.1 ProxyFactory#getInterceptorsAndDynamicInterceptionAdvice

`ProxyFactory#getInterceptorsAndDynamicInterceptionAdvice` 是获取当前方法的 拦截器和动态拦截建议，在上面也多次调用。其实现在 `AdvisedSupport#getInterceptorsAndDynamicInterceptionAdvice` 中，如下：

```java
	// 	// 当前 this 为 ProxyFactory，所以这里的缓存是作用域是在 ProxyFactory中，如果换一个 ProxyFactory则需要重新加载一次。
	public List < Object > getInterceptorsAndDynamicInterceptionAdvice(Method method, @Nullable Class < ? > targetClass) {
	    // 生成方法的key
	    MethodCacheKey cacheKey = new MethodCacheKey(method);
	    // 从缓存中获取该方法的 拦截器和动态拦截建议
	    List < Object > cached = this.methodCache.get(cacheKey);
	    if (cached == null) {
	        // 缓存没有命中则重新获取
	        cached = this.advisorChainFactory.getInterceptorsAndDynamicInterceptionAdvice(
	            this, method, targetClass);
	        // 将获取到的 拦截器和动态拦截建议 放入缓存中。
	        this.methodCache.put(cacheKey, cached);
	    }
	    return cached;
	}
```

这里的 `this.advisorChainFactory.getInterceptorsAndDynamicInterceptionAdvice` 调用的是  
`DefaultAdvisorChainFactory#getInterceptorsAndDynamicInterceptionAdvice`，其实现如下：

```
 `@Override
	public List<Object> getInterceptorsAndDynamicInterceptionAdvice(
			Advised config, Method method, @Nullable Class<?> targetClass) {

		AdvisorAdapterRegistry registry = GlobalAdvisorAdapterRegistry.getInstance();
		Advisor[] advisors = config.getAdvisors();
		List<Object> interceptorList = new ArrayList<>(advisors.length);
		Class<?> actualClass = (targetClass != null ? targetClass : method.getDeclaringClass());
		Boolean hasIntroductions = null;
		// 遍历所有的 Advisor，这里的 Advisor 是 ProxyFactory 中保存的
		for (Advisor advisor : advisors) {
			/******* 1. PointcutAdvisor 顾问类型的处理 *******/
			// 如果是切点顾问
			if (advisor instanceof PointcutAdvisor) {
				// Add it conditionally.
				PointcutAdvisor pointcutAdvisor = (PointcutAdvisor) advisor;
				// 如果经过 预过滤 || 当前顾问 匹配当前类
				if (config.isPreFiltered() || pointcutAdvisor.getPointcut().getClassFilter().matches(actualClass)) {
					// 判断当前方法是否匹配
					MethodMatcher mm = pointcutAdvisor.getPointcut().getMethodMatcher();
					boolean match;
					if (mm instanceof IntroductionAwareMethodMatcher) {
						if (hasIntroductions == null) {
							hasIntroductions = hasMatchingIntroductions(advisors, actualClass);
						}
						match = ((IntroductionAwareMethodMatcher) mm).matches(method, actualClass, hasIntroductions);
					}
					else {
						match = mm.matches(method, actualClass);
					}
					// 如果方法也匹配，则认为当前顾问适用于当前方法
					if (match) {
						// 获取顾问中的 方法拦截器。这里会将部分不合适的类型转换为合适的拦截器
						MethodInterceptor[] interceptors = registry.getInterceptors(advisor);
						// runtime 为 true， 表明是动态调用，即每次调用都需要执行一次判断。
						if (mm.isRuntime()) {
							// 动态调用将 拦截器包装成 InterceptorAndDynamicMethodMatcher
							for (MethodInterceptor interceptor : interceptors) {
								interceptorList.add(new InterceptorAndDynamicMethodMatcher(interceptor, mm));
							}
						}
						else {
							// 否则直接添加
							interceptorList.addAll(Arrays.asList(interceptors));
						}
					}
				}
			}
			else if (advisor instanceof IntroductionAdvisor) {
				/******* 2. IntroductionAdvisor 顾问类型的处理 *******/
				// 如果是引介顾问类型
				IntroductionAdvisor ia = (IntroductionAdvisor) advisor;
				// 预过滤 || 调用类匹配
				if (config.isPreFiltered() || ia.getClassFilter().matches(actualClass)) {
					// 直接添加
					Interceptor[] interceptors = registry.getInterceptors(advisor);
					interceptorList.addAll(Arrays.asList(interceptors));
				}
			}
			else {
				/******* 3. 其他顾问类型的处理 *******/
				// 直接添加
				Interceptor[] interceptors = registry.getInterceptors(advisor);
				interceptorList.addAll(Arrays.asList(interceptors));
			}
		}
		// 返回拦截器集合
		return interceptorList;
	}` 



```

上面的逻辑还是比较清楚，如下：

1. 遍历 当前 ProxyFactory 中所有的顾问 Advisor 集合。这个 Advisor 集合来自于 `AbstractAutoProxyCreator#createProxy` 中的设值。
2. 下面会根据 Advisor 的类型分开匹配：
3. 对于 PointcutAdvisor 类型顾问，则需要匹配调用类和调用方法。
    1. 进行类和方法的匹配，如果都匹配则认为 Advisor 适用于当前方法。
    2. 随后通过 runtime 参数判断了当前拦截器是否是动态拦截器。
    3. 如果是动态拦截器则封装成 InterceptorAndDynamicMethodMatcher 类型保存到集合中。所谓的动态拦截器，即每次调用时都会判断一次是否可以执行增强。
    4. 如果不是动态拦截器则直接添加到 拦截器集合中，随后将拦截器集合返回。
4. 对于 IntroductionAdvisor 类型顾问，该类型是引介顾问，并不会精确到方法级别，所以对调用类进行校验，如果匹配则认为适用。
5. 对于 IntroductionAdvisor 类型顾问，直接添加。

### 1.2 CglibMethodInvocation#proceed

CglibMethodInvocation#proceed 调用其父类方法 `ReflectiveMethodInvocation#proceed`，作用为 执行了过滤器链流程，其实现如下：

```
 `@Override
	@Nullable
	public Object proceed() throws Throwable {
		// We start with an index of -1 and increment early.
		// 如果所有拦截器执行结束，调用真正的方法
		if (this.currentInterceptorIndex == this.interceptorsAndDynamicMethodMatchers.size() - 1) {
			return invokeJoinpoint();
		}
		// 获取下一个拦截器
		Object interceptorOrInterceptionAdvice =
				this.interceptorsAndDynamicMethodMatchers.get(++this.currentInterceptorIndex);
		// 如果是动态拦截器
		if (interceptorOrInterceptionAdvice instanceof InterceptorAndDynamicMethodMatcher) {
			// Evaluate dynamic method matcher here: static part will already have
			// been evaluated and found to match.
			InterceptorAndDynamicMethodMatcher dm =
					(InterceptorAndDynamicMethodMatcher) interceptorOrInterceptionAdvice;
			Class<?> targetClass = (this.targetClass != null ? this.targetClass : this.method.getDeclaringClass());
			// 判断调用是否匹配，如果匹配则调用拦截器方法
			if (dm.methodMatcher.matches(this.method, targetClass, this.arguments)) {
				return dm.interceptor.invoke(this);
			}
			else {
				// Dynamic matching failed.
				// Skip this interceptor and invoke the next in the chain.
				// 否则递归执行下一个拦截器
				return proceed();
			}
		}
		else {
			// 非动态调用直接调用拦截器方法。
			return ((MethodInterceptor) interceptorOrInterceptionAdvice).invoke(this);
		}
	}` 



```

`ProxyFactory#getInterceptorsAndDynamicInterceptionAdvice` 返回的拦截器集合保存到了 `interceptorsAndDynamicMethodMatchers` 中， `currentInterceptorIndex` 记录执行到哪个拦截器。

其逻辑简述如下：

1. 判断 `this.currentInterceptorIndex == this.interceptorsAndDynamicMethodMatchers.size() - 1` 是否成立，如果成立，则说明当前拦截器链已经执行结束，开始执行目标对象的目标放啊
2. 否则从 `interceptorsAndDynamicMethodMatchers` 中获取下一个拦截器。
3. 如果拦截器类型是 `InterceptorAndDynamicMethodMatcher` 则认为动态匹配，需要每次调用前调用 `MethodMatcher#matches(java.lang.reflect.Method, java.lang.Class<?>, java.lang.Object…)` 方法判断是否匹配，如果匹配则执行该拦截器，否则递归回到第一步找下一个拦截器。
4. 如果拦截器类型不是 `InterceptorAndDynamicMethodMatcher` ，则直接执行该拦截器即可。

关于动态拦截的内容，在 [Spring 源码分析补充篇三 ：Spring Aop 的关键类](https://blog.csdn.net/qq_36882793/article/details/117568863) 中所有提及。

2\. targetInterceptor
---------------------

targetInterceptor 实现了 MethodInterceptor 接口，当方法没有适用拦截器和动态拦截建议 则可能使用该拦截器。aopInterceptor 在不同的情况下有不同的实现类，其规则如下：

```java
	// 如果需要暴露代理类，则需要在执行前将代理类保存到 AOP上下文 中，
	// 而 StaticUnadvisedExposedInterceptor 和 DynamicUnadvisedExposedInterceptor 中完成了此操作。
	if (exposeProxy) {
	    targetInterceptor = (isStatic ?
	        // 如果是静态,直接将 getTarget 对象传入，因为对象不可变。否则传入 TargetSource 由拦截器在内部获取。
	        new StaticUnadvisedExposedInterceptor(this.advised.getTargetSource().getTarget()) :
	        new DynamicUnadvisedExposedInterceptor(this.advised.getTargetSource()));
	} else {
	    targetInterceptor = (isStatic ?
	        new StaticUnadvisedInterceptor(this.advised.getTargetSource().getTarget()) :
	        new DynamicUnadvisedInterceptor(this.advised.getTargetSource()));
	}
```

即：

1. 如果 exposeProxy = true && 代理类是静态 ： StaticUnadvisedExposedInterceptor

    ```java
    		@Override
    		@Nullable
    		public Object intercept(Object proxy, Method method, Object[] args, MethodProxy methodProxy) throws Throwable {
    			Object oldProxy = null;
    			try {
    				// 切换当前AOP上下文的 代理类对象
    				oldProxy = AopContext.setCurrentProxy(proxy);
    				Object retVal = methodProxy.invoke(this.target, args);
    				return processReturnType(proxy, this.target, method, retVal);
    			}
    			finally {
    				// 重置回上下文对象
    				AopContext.setCurrentProxy(oldProxy);
    			}
    		}
    
    ```

2. 如果 exposeProxy = true && 代理类不是静态：DynamicUnadvisedExposedInterceptor

    ```
     `@Override
    		@Nullable
    		public Object intercept(Object proxy, Method method, Object[] args, MethodProxy methodProxy) throws Throwable {
    			Object oldProxy = null;
    			Object target = this.targetSource.getTarget();
    			try {
    				oldProxy = AopContext.setCurrentProxy(proxy);
    				Object retVal = methodProxy.invoke(target, args);
    				return processReturnType(proxy, target, method, retVal);
    			}
    			finally {
    				AopContext.setCurrentProxy(oldProxy);
    				if (target != null) {
    					this.targetSource.releaseTarget(target);
    				}
    			}
    		}` 
    
    ![](Attachments/59ddd7af80665f17c019602d722bf0e2_MD5.png)

    
    
    ```

3. 如果 exposeProxy = false && 代理类是静态： StaticUnadvisedInterceptor

    ```java
    		@Override
    		@Nullable
    		public Object intercept(Object proxy, Method method, Object[] args, MethodProxy methodProxy) throws Throwable {
    			Object retVal = methodProxy.invoke(this.target, args);
    			return processReturnType(proxy, this.target, method, retVal);
    		}
    
    ```

4. 如果 exposeProxy = false && 代理类不是静态：DynamicUnadvisedInterceptor

    ```java
    		@Override
    		@Nullable
    		public Object intercept(Object proxy, Method method, Object[] args, MethodProxy methodProxy) throws Throwable {
    			Object target = this.targetSource.getTarget();
    			try {
    				Object retVal = methodProxy.invoke(target, args);
    				return processReturnType(proxy, target, method, retVal);
    			}
    			finally {
    				if (target != null) {
    					this.targetSource.releaseTarget(target);
    				}
    			}
    		}
    
    ```

**注**： 这里的所说的静态是 根据 TargetSource#isStatic 方法判断，标志用户返回当前 bean 是否为静态的，比如常见的单例 bean 就是静态的，而原型模式下就是动态的。这里这个方法的主要作用是，对于静态的 bean，spring 是会对其进行缓存的，在多次使用 TargetSource 获取目标 bean 对象的时候，其获取的总是同一个对象，通过这种方式提高效率。

3\. SerializableNoOp
--------------------

SerializableNoOp 没有做任何事。用于无需代理或无法代理的方法。

```java
	public static class SerializableNoOp implements NoOp, Serializable {}
```

4\. StaticDispatcher
--------------------

StaticDispatcher 是静态类情况下的懒加载策略，其实现如下：

```java
	private static class StaticDispatcher implements Dispatcher, Serializable {

	    @Nullable
	    private final Object target;

	    public StaticDispatcher(@Nullable Object target) {
	        this.target = target;
	    }

	    @Override
	    @Nullable
	    public Object loadObject() {
	        return this.target;
	    }
	}
```

5\. AdvisedDispatcher
---------------------

AdvisedDispatcher 仍为懒加载策略。 调用时机为代理类调用的是 Advised 接口声明的方法时，其实现如下：

```java
	/**
	 * Dispatcher for any methods declared on the Advised class.
	 */
	private static class AdvisedDispatcher implements Dispatcher, Serializable {

	    private final AdvisedSupport advised;

	    public AdvisedDispatcher(AdvisedSupport advised) {
	        this.advised = advised;
	    }

	    @Override
	    public Object loadObject() {
	        return this.advised;
	    }
	}
```

6\. EqualsInterceptor
---------------------

EqualsInterceptor 用于处理 equals 方法的调用，其实现如下：

```
 `private static class EqualsInterceptor implements MethodInterceptor, Serializable {

		private final AdvisedSupport advised;

		public EqualsInterceptor(AdvisedSupport advised) {
			this.advised = advised;
		}

		@Override
		public Object intercept(Object proxy, Method method, Object[] args, MethodProxy methodProxy) {
			Object other = args[0];
			if (proxy == other) {
				return true;
			}
			if (other instanceof Factory) {
				Callback callback = ((Factory) other).getCallback(INVOKE_EQUALS);
				if (!(callback instanceof EqualsInterceptor)) {
					return false;
				}
				AdvisedSupport otherAdvised = ((EqualsInterceptor) callback).advised;
				return AopProxyUtils.equalsInProxy(this.advised, otherAdvised);
			}
			else {
				return false;
			}
		}
	}` 



```

7\. HashCodeInterceptor
-----------------------

HashCodeInterceptor 用于处理 hashcode 方法的调用，其实现如下：

```java
	private static class HashCodeInterceptor implements MethodInterceptor, Serializable {

	    private final AdvisedSupport advised;

	    public HashCodeInterceptor(AdvisedSupport advised) {
	        this.advised = advised;
	    }

	    @Override
	    public Object intercept(Object proxy, Method method, Object[] args, MethodProxy methodProxy) {
	        return CglibAopProxy.class.hashCode() * 13 + this.advised.getTargetSource().hashCode();
	    }
	}
```

四、总结
====

我们这里总结一下 Spring Aop Cglib 的代理过程：

1. Spring 服务启动后，会加载自动代理创建器 AbstractAutoProxyCreator。AbstractAutoProxyCreator 有多个实现类，不过主体逻辑基本相同，这里就用 AbstractAutoProxyCreator 表述。
2. 在 Spring Bean 创建过程中，AbstractAutoProxyCreator 会从容器中获取 Advisor 集合，并判断是否有适用于当前 Bean 的 Advisor 集合。如果存在，则调用 AbstractAutoProxyCreator#createProxy 准备开始创建该 Bean 的 代理。
3. 创建代理前会做一些准备工作，如：创建当前 Bean 对应的 ProxyFactory ，并将适用 的 Advisor 赋值给 ProxyFactory 等。随后通过 ProxyFactory#getProxy(java.lang.ClassLoader) 创建代理对象。
4. Spring Bean 代理的创建可以选择 Jdk 动态代理和 Cglib 动态代理，本文分析 Cglib 过程，因此这里假定 Bean 使用 Cglib 代理。所以这里选择 CglibAopProxy#getProxy(java.lang.ClassLoader) 创建代理对象
5. 在 CglibAopProxy#getProxy(java.lang.ClassLoader) 在创建代理对象时会添加 Callback 集合用于代理对象调用时的增强操作，并且会添加代理回调过滤器 ProxyCallbackFilter 来选择使用合适的 Callback 来操作 。
6. 当代理对象调用某个方法时，会通过 ProxyCallbackFilter 来选择合适的 Callback 执行。如常规的调用会执行 DynamicAdvisedInterceptor 。
7. 在 DynamicAdvisedInterceptor 中会遍历当前 ProxyFactory 中的 Advisor 集合（这里的 Advisor 集合就是第三步的准备工作中 保存到 ProxyFactory 中的)，挑选出适合当前调用方法的 Advisor 依次执行，最后执行真正的方法。