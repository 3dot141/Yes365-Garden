---
aliases: []
created_date: 2023-09-04 16:47
draft: false
summary: ''
tags:
- dev
---

#dev/spring

简单说明及使用方式见：[jdk动态代理,cglib,Spring AOP和Aspectj (AOP日志收集实战)](jdk动态代理,cglib,Spring%20AOP和Aspectj%20(AOP日志收集实战).md)

流程图见

- 初始化完成 `org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#applyBeanPostProcessorsAfterInitialization`  
- 创建切面 `org.springframework.aop.framework.autoproxy.AbstractAutoProxyCreator#getAdvicesAndAdvisorsForBean`
	- 匹配切面 `org.springframework.aop.framework.autoproxy.AbstractAdvisorAutoProxyCreator#findEligibleAdvisors`
	- `org.springframework.aop.aspectj.annotation.InstantiationModelAwarePointcutAdvisorImpl#instantiateAdvice`
		- `org.springframework.aop.aspectj.annotation.ReflectiveAspectJAdvisorFactory#getAdvice`
			- `org.springframework.aop.aspectj.AspectJAroundAdvice`
- 创建代理 `org.springframework.aop.framework.autoproxy.AbstractAutoProxyCreator#createProxy`
	- `org.springframework.aop.framework.CglibAopProxy#CglibAopProxy`

然后创建代理时， 见 [Spring cglib 的 7 个拦截器之 Aop Interceptor](Spring%20cglib%20代理过程.md#1%20aopInterceptor)  
会创建出拦截器 `org.springframework.aop.framework.CglibAopProxy.DynamicAdvisedInterceptor`

然后获取 `AspectJAroundAdvice` 运行切面中支持的方法

直接通过 AspectJ 创建 Proxy 的方式，见 [Spring 的 AspectJProxyFactory](Spring%20的%20AspectJProxyFactory.md)

## 注意点

需要注意的是，虽然正常使用 AspectJ 是静态代理的，见 [jdk动态代理,cglib,Spring AOP和Aspectj (AOP日志收集实战)](jdk动态代理,cglib,Spring%20AOP和Aspectj%20(AOP日志收集实战).md)  
但是在 Spring 中，使用时是通过 cglib 连接 aspect ，从而实现的动态代理