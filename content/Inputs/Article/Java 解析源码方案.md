---
aliases: []
created_date: 2023-08-23 15:31
draft: false
summary: ''
tags:
- dev
---

```java
/**  
 * created by Harrison on 2020/09/22 
 **/
 public static class MethodCollector {  
  
    private static JavacFileManager fileManager = new JavacFileManager(new Context(), true, Charsets.UTF_8);  
  
    private static JavacTool javacTool = new JavacTool();  
  
    public static Map<String, byte[]> collect(String code) {  
  
        Map<String, byte[]> methods = Maps.newHashMap();  
        SourceVisitor visitor = new SourceVisitor(methods);  
  
        JavaContentObject object = new JavaContentObject("anonymous", code);  
        Iterable<? extends JavaFileObject> files = Lists.newArrayList(object);  
  **
        scanJavaCode(visitor, files);  
        return visitor.getMethods();  
    }  
  
    private static void scanJavaCode(SourceVisitor visitor, Iterable<? extends JavaFileObject> files) {  
  
        JavacTask javacTask = javacTool.getTask(null, fileManager, null, null, null, files);  
        try {  
            Iterable<? extends CompilationUnitTree> result = javacTask.parse();  
            for (CompilationUnitTree tree : result) {  
                tree.accept(visitor, null);  
            }  
        } catch (IOException e) {  
            e.printStackTrace();  
        }  
    }  
  
    static class SourceVisitor extends TreeScanner<Void, Void> {  
          
        private boolean innerClass = false;  
  
        private final Map<String, byte[]> methods;  
  
        public SourceVisitor(Map<String, byte[]> methods) {  
            this.methods = methods;  
        }  
  
        @Override  
        public Void visitClass(ClassTree node, Void unused) {  
            //先过滤匿名类  
            if (innerClass) {  
                return null;  
            }  
            innerClass = true;  
            return super.visitClass(node, unused);  
        }  
  
        @Override  
        public Void visitMethod(MethodTree node, Void unused) {  
            String methodName = formatMethodName(node.getName().toString(), node.getParameters());  
            BlockTree body = node.getBody();  
            if (body == null) {  
                return null;  
            }  
            methods.put(methodName, (body.toString().getBytes()));  
            return super.visitMethod(node, unused);  
        }  
  
        private String formatMethodName(String name, Iterable<? extends VariableTree> params) {  
  
            StringBuilder sb = new StringBuilder();  
            sb.append(name)  
                    .append("(");  
            for (VariableTree param : params) {  
                String type = param.getType().toString();  
                //过滤掉范型  
                String filterGeneric = type.replaceAll("<.*?>", StringUtils.EMPTY);  
                sb.append(filterGeneric).append(";");  
            }  
            sb.append(")");  
            return sb.toString();  
        }  
  
        public Map<String, byte[]> getMethods() {  
            return methods;  
        }  
    }  
  
    private static class JavaContentObject extends SimpleJavaFileObject {  
  
        private final String code;  
  
        private JavaContentObject(String name, String code) {  
            super(URI.create("string:///" + name.replace('.', '/') + Kind.SOURCE.extension), Kind.SOURCE);  
            this.code = code;  
        }  
  
        public CharSequence getCharContent(boolean ignoreEncodingErrors) {  
            return code;  
        }  
    }  
  
}
```