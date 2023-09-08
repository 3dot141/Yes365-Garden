---
aliases: []
created_date: 2023-08-23 15:31
draft: false
summary: ''
tags:
- dev
---

**看到很多注解都被@Inherited 进行了修饰，但是这个@Inherited 有什么作用呢？**

查看@Inherited 代码描述：

> Indicates that an annotation type is automatically inherited. If an Inherited meta-annotation is present on an annotation type declaration, and the user queries the annotation type on a class declaration, and the class declaration has no annotation for this type, then the class's superclass will automatically be queried for the annotation type. This process will be repeated until an annotation for this type is found, or the top of the class hierarchy (Object) is reached. If no superclass has an annotation for this type, then the query will indicate that the class in question has no such annotation.  
> Note that this meta-annotation type has no effect if the annotated type is used to annotate anything other than a class. Note also that this meta-annotation only causes annotations to be inherited from superclasses; annotations on implemented interfaces have no effect.

翻译后：

指示批注类型是自动继承的。如果在注释类型声明中存在继承的元注释，并且用户在类声明上查询注释类型，并且类声明对该类没有注释，那么该类的超类将自动被查询到注释类型。这个过程将被重复，直到找到这个类型的注释，或者到达类层次结构 (对象) 的顶端。如果没有超类具有此类的注释，那么查询将表明该类没有此类注释

根据描述进行实例测试：

**定义两个注解：@IsInheritedAnnotation 、@NoInherritedAnnotation，其中@IsInheritedAnnotation 加了注解@Inherited**

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
@Inherited
public @interface IsInheritedAnnotation {
}
 
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
public @interface NoInherritedAnnotation {
}
```

**测试类继承关系中@Inherited 的作用**

```java
@NoInherritedAnnotation
@IsInheritedAnnotation
public class InheritedBase {
}
 
public class MyInheritedClass extends InheritedBase  {
}
```

**测试接口继承关系中@Inherited 的作用**

```java
@NoInherritedAnnotation
@IsInheritedAnnotation
public interface IInheritedInterface {
}
 
public interface IInheritedInterfaceChild extends IInheritedInterface {
}
```

**测试类实现接口关系中@Inherited 的作用**

```java
public class MyInheritedClassUseInterface implements IInheritedInterface {
}
```

**junit 测试代码**

```java
public class MyInheritedClassTest {
 
    @Test
    public void testInherited(){
	    // 测试【类继承类】关系
        {
            Annotation[] annotations = MyInheritedClass.class.getAnnotations();
            assertTrue("", Arrays.stream(annotations).anyMatch(l -> l.annotationType().equals(IsInheritedAnnotation.class)));
            assertTrue("", Arrays.stream(annotations).noneMatch(l -> l.annotationType().equals(NoInherritedAnnotation.class)));
        }
	    // 测试接口关系
        {
            Annotation[] annotations = IInheritedInterface.class.getAnnotations();
            assertTrue("", Arrays.stream(annotations).anyMatch(l -> l.annotationType().equals(IsInheritedAnnotation.class)));
            assertTrue("", Arrays.stream(annotations).anyMatch(l -> l.annotationType().equals(NoInherritedAnnotation.class)));
        }
        // 测试【接口继承接口】关系
        {
            Annotation[] annotations = IInheritedInterfaceChild.class.getAnnotations();
            assertTrue("", Arrays.stream(annotations).noneMatch(l -> l.annotationType().equals(IsInheritedAnnotation.class)));
            assertTrue("", Arrays.stream(annotations).noneMatch(l -> l.annotationType().equals(NoInherritedAnnotation.class)));
        }
        // 测试【类继承接口】后的关系
        {
            Annotation[] annotations = MyInheritedClassUseInterface.class.getAnnotations();
            assertTrue("", Arrays.stream(annotations).noneMatch(l -> l.annotationType().equals(IsInheritedAnnotation.class)));
            assertTrue("", Arrays.stream(annotations).noneMatch(l -> l.annotationType().equals(NoInherritedAnnotation.class)));
        }
    }
 
}
```

### 测试结果：

![](https://img-blog.csdn.net/20180727192057756?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2FiNDExOTE5MTM0/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

### 总结：

**类继承关系中@Inherited 的作用**

类继承关系中，子类会继承父类使用的注解中被@Inherited 修饰的注解

**接口继承关系中@Inherited 的作用**

接口继承关系中，子接口不会继承父接口中的任何注解，不管父接口中使用的注解有没有被@Inherited 修饰

**类实现接口关系中@Inherited 的作用**

类实现接口时不会继承任何接口中定义的注解

# 属性/方法层级的继承关系

以下示例说明属性/方法注解的继承：

```java
public class InheritedTest {

    @Target(value = {ElementType.METHOD, ElementType.FIELD})
    @Retention(value = RetentionPolicy.RUNTIME)
    @interface DESC {
        String value() default "";
    }

    class SuperClass {
        @DESC("父类方法foo")
        public void foo() {}
        @DESC("父类方法bar")
        public void bar(){}
        @DESC("父类的属性")
        public String field;
    }

    class ChildClass extends SuperClass {
        @Override
        public void foo() {
            super.foo();
        }
    }

    public static void main(String[] args) throws NoSuchMethodException, NoSuchFieldException {
        Method foo = ChildClass.class.getMethod("foo");
        System.out.println(Arrays.toString(foo.getAnnotations()));
        // output: []
        // 子类ChildClass重写了父类方法foo,并且@Override注解只在源码阶段保留，所以没有任何注解

        Method bar = ChildClass.class.getMethod("bar");
        System.out.println(Arrays.toString(bar.getAnnotations()));
        // output: [@annotations.InheritedTest$DESC(value=父类方法bar)]
        // bar方法未被子类重写，从父类继承到了原本注解

        Field field = ChildClass.class.getField("field");
        System.out.println(Arrays.toString(field.getAnnotations()));
    }
    // output: [@annotations.InheritedTest$DESC(value=父类的属性)]
    // 解释同上
```

基于接口的继承/实现中，属性和方法注解的继承大体与类相似。jdk7 以前接口的方法都需要实现，所以子类中的方法永远也无法获得父接口方法的注解，但是 jdk8 以后的默认方法打开了这种限制。

```java
public class IterInheritedTest {

    @Target(value = {ElementType.METHOD, ElementType.FIELD})
    @Retention(value = RetentionPolicy.RUNTIME)
    @interface DESC {
        String value() default "";
    }

    interface SuperInterface {
        @DESC("父接口的属性")
        String field = "field";
        @DESC("父接口方法foo")
        public void foo();
        @DESC("父接口方法bar")
        default public void bar() {

        }
    }

    interface ChildInterface extends SuperInterface {
        @DESC("子接口方法foo")
        @Override
        void foo();
    }

    class ChildClass implements SuperInterface {
        @DESC("子类的属性")
        public String field = "field";
        @Override
        public void foo() {
        }
    }

    public static void main(String[] args) throws NoSuchMethodException, NoSuchFieldException {
        Method iFoo = ChildInterface.class.getMethod("foo");
        System.out.println(Arrays.toString(iFoo.getAnnotations()));
        // output: [@annotations.IterInheritedTest$DESC(value=子接口方法foo)]

        Method iBar = ChildInterface.class.getMethod("bar");
        System.out.println(Arrays.toString(iBar.getAnnotations()));
        // output: [@annotations.IterInheritedTest$DESC(value=父接口方法bar)]

        Field iField = ChildInterface.class.getField("field");
        System.out.println(Arrays.toString(iField.getAnnotations()));
        // output: [@annotations.IterInheritedTest$DESC(value=父接口的属性)]

        Method foo = ChildClass.class.getMethod("foo");
        System.out.println(Arrays.toString(foo.getAnnotations()));
        // output: []; 被子类覆盖

        Method bar = ChildClass.class.getMethod("bar");
        System.out.println(Arrays.toString(bar.getAnnotations()));
        // output: [@annotations.IterInheritedTest$DESC(value=父接口方法bar)]

        Field field = ChildClass.class.getField("field");
        System.out.println(Arrays.toString(field.getAnnotations()));
        // output: [@annotations.IterInheritedTest$DESC(value=子类的属性)]
        // 是子类作用域下的属性`field`
    }
}
```

### 总结

方法和属性上注解的继承，忠实于方法/属性继承本身，客观反映方法/属性上的注解。