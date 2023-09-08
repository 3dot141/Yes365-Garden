---
aliases: []
created_date: 2023-08-23 15:31
draft: false
summary: ''
tags:
- dev
---

```Java
default<V>Function<V, R>compose(Function<? super V, ? extends T>before) {
Objects.requireNonNull(before);
    return(V v)-> apply(before.apply(v));
}
```

```Java
Function<Integer, Integer> func = e -> {return e + 5;};
Function<Integer, Integer> func2 = e -> {return e * 5;};
//func2即after
func.andThen(func2).apply(5); // 50
```

```Java
default <V> Function<T, V> andThen(Function<? super R, ? extends V> after) {
        Objects.requireNonNull(after);
        return (T t) -> after.apply(apply(t));
}
```

```Java
Function<Integer, Integer> func = e -> {return e + 5;};
Function<Integer, Integer> func2 = e -> {return e * 5;};
//func2即before
func.compose(func2).apply(5); // 30
```