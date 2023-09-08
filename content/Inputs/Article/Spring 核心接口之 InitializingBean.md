---
aliases: []
created_date: 2023-09-04 16:47
draft: false
summary: ''
tags:
- dev
---

#dev/spring 

一、InitializingBean 接口说明  
InitializingBean 接口为 bean 提供了属性初始化后的处理方法，它只包括 afterPropertiesSet 方法，凡是继承该接口的类，在 bean 的属性初始化后都会执行该方法。

```
package org.springframework.beans.factory;

/\*\*
 \* Interface to be implemented by beans that need to react once all their
 \* properties have been set by a BeanFactory: for example, to perform custom
 \* initialization, or merely to check that all mandatory properties have been set.
 \*
 \* <p>An alternative to implementing InitializingBean is specifying a custom
 \* init-method, for example in an XML bean definition.
 \* For a list of all bean lifecycle methods, see the BeanFactory javadocs.
 \*
 \* @author Rod Johnson
 \* @see BeanNameAware
 \* @see BeanFactoryAware
 \* @see BeanFactory
 \* @see org.springframework.beans.factory.support.RootBeanDefinition#getInitMethodName
 \* @see org.springframework.context.ApplicationContextAware
 */
public interface InitializingBean {

    /\*\*
     \* Invoked by a BeanFactory after it has set all bean properties supplied
     \* (and satisfied BeanFactoryAware and ApplicationContextAware).
     \* <p>This method allows the bean instance to perform initialization only
     \* possible when all bean properties have been set and to throw an
     \* exception in the event of misconfiguration.
     \* @throws Exception in the event of misconfiguration (such
     \* as failure to set an essential property) or if initialization fails.
     */
    void afterPropertiesSet() throws Exception;

}

```

从方法名 afterPropertiesSet 也可以清楚的理解该方法是在属性设置后才调用的。  
二、源码分析接口应用  
通过查看 spring 的加载 bean 的源码类 (AbstractAutowireCapableBeanFactory) 可以看到

```
protected void invokeInitMethods(String beanName, final Object bean, RootBeanDefinition mbd)
            throws Throwable {
//判断该bean是否实现了实现了InitializingBean接口，如果实现了InitializingBean接口，则调用bean的afterPropertiesSet方法
        boolean isInitializingBean = (bean instanceof InitializingBean);
        if (isInitializingBean && (mbd == null || !mbd.isExternallyManagedInitMethod("afterPropertiesSet"))) {
            if (logger.isDebugEnabled()) {
                logger.debug("Invoking afterPropertiesSet() on bean with name '" \+ beanName + "'");
            }
            if (System.getSecurityManager() != null) {
                try {
                    AccessController.doPrivileged(new PrivilegedExceptionAction<Object>() {
                        public Object run() throws Exception {
                            //调用afterPropertiesSet
                            ((InitializingBean) bean).afterPropertiesSet();
                            return null;
                        }
                    }, getAccessControlContext());
                }
                catch (PrivilegedActionException pae) {
                    throw pae.getException();
                }
            }
            else {
                //调用afterPropertiesSet
                ((InitializingBean) bean).afterPropertiesSet();
            }
        }

        if (mbd != null) {            //判断是否指定了init-method方法，如果指定了init-method方法，则再调用制定的init-method
            String initMethodName = mbd.getInitMethodName();
            if (initMethodName != null && !(isInitializingBean && "afterPropertiesSet".equals(initMethodName)) && !mbd.isExternallyManagedInitMethod(initMethodName)) {
                //反射调用init-method方法
                invokeCustomInitMethod(beanName, bean, mbd);
            }
        }
    }
```

分析代码可以了解：  
1：spring 为 bean 提供了两种初始化 bean 的方式，实现 InitializingBean 接口，实现 afterPropertiesSet 方法，或者在配置文件中同过 init-method 指定，两种方式可以同时使用  
2：实现 InitializingBean 接口是直接调用 afterPropertiesSet 方法，比通过反射调用 init-method 指定的方法效率相对来说要高点。但是 init-method 方式消除了对 spring 的依赖  
3：如果调用 afterPropertiesSet 方法时出错，则不调用 init-method 指定的方法。

三、接口应用  
InitializingBean 接口在 spring 框架中本身就很多应用，这就不多说了。我们在实际应用中如何使用该接口呢？

1、使用 InitializingBean 接口处理一个配置文件：

```
import java.io.File;
import java.io.FileInputStream;
import java.util.Properties;

import org.springframework.beans.factory.InitializingBean;

public class ConfigBean implements InitializingBean{
    
    //微信公众号配置文件
    private String configFile;
    
    private String appid;
    
    private String appsecret;
    
    public String getConfigFile() {
        return configFile;
    }

    public void setConfigFile(String configFile) {
        this.configFile = configFile;
    }
    
    public void afterPropertiesSet() throws Exception {
        if(configFile!=null){
            File cf = new File(configFile);
            if(cf.exists()){
                Properties pro = new Properties();
                pro.load(new FileInputStream(cf));
                appid = pro.getProperty("wechat.appid");
                appsecret = pro.getProperty("wechat.appsecret");
            }
        }
        System.out.println(appid);
        System.out.println(appsecret);
    }
}
```

2、配置  
spring 配置文件：

```
    <bean id="configBean" class="com.ConfigBean">
        <property name="configFile" value="d:/wechat.properties"></property>
    </bean>
```

wechat.properties 配置文件

```
    wechat.appid=wxappid
    wechat.appsecret=wxappsecret
```

3、测试

```
 public static void main(String\[\] args) throws Exception {
        String config = Test.class.getPackage().getName().replace('.', '/') \+ "/bean.xml";
       ClassPathXmlApplicationContext context = new ClassPathXmlApplicationContext(config);
       context.start();
    }

```