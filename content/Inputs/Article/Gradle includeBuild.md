---
aliases: []
created_date: 2023-08-23 15:31
draft: false
summary: ''
tags:
- dev
---

[What is a composite build?](#composite_build_intro)
------------------------------------------------------------------------------

A composite build is simply a build that includes other builds. In many ways a composite build is similar to a Gradle multi-project build, except that instead of including single `projects`, complete `builds` are included.

Composite builds allow you to:

* combine builds that are usually developed independently, for instance when trying out a bug fix in a library that your application uses
* decompose a large multi-project build into smaller, more isolated chunks that can be worked in independently or together as needed

A build that is included in a composite build is referred to, naturally enough, as an "included build". Included builds do not share any configuration with the composite build, or the other included builds. Each included build is configured and executed in isolation.

Included builds interact with other builds via [_dependency substitution_](resolution_rules.html#sec:dependency_substitution_rules). If any build in the composite has a dependency that can be satisfied by the included build, then that dependency will be replaced by a project dependency on the included build. _Because of the reliance on dependency substitution, composite builds may force configurations to be resolved earlier, when composing the task execution graph. This can have a negative impact on overall build performance, because these configurations are not resolved in parallel._

By default, Gradle will attempt to determine the dependencies that can be substituted by an included build. However for more flexibility, it is possible to explicitly declare these substitutions if the default ones determined by Gradle are not correct for the composite. See [Declaring substitutions](#included_build_declaring_substitutions).

As well as consuming outputs via project dependencies, a composite build can directly declare task dependencies on included builds. Included builds are isolated, and are not able to declare task dependencies on the composite build or on other included builds. See [Depending on tasks in an included build](#included_build_task_dependencies).

[Defining a composite build](#defining_composite_builds)
--------------------------------------------------------------------------------------

The following examples demonstrate the various ways that 2 Gradle builds that are normally developed separately can be combined into a composite build. For these examples, the `my-utils` multi-project build produces 2 different java libraries (`number-utils` and `string-utils`), and the `my-app` build produces an executable using functions from those libraries.

The `my-app` build does not have direct dependencies on `my-utils`. Instead, it declares binary dependencies on the libraries produced by `my-utils`.

Example 1. [Dependencies of my-app](#ex-dependencies-of-my-app)

`Kotlin` `Groovy`

my-app/app/build.gradle.kts

```
plugins { id("application")  } application { mainClass.set("org.sample.myapp.Main")  } dependencies { implementation("org.sample:number-utils:1.0") implementation("org.sample:string-utils:1.0")  }
```

my-app/app/build.gradle

```
plugins { id 'application'  } application { mainClass =  'org.sample.myapp.Main'  } dependencies { implementation 'org.sample:number-utils:1.0' implementation 'org.sample:string-utils:1.0'  }
```

### [Defining a composite build via `--include-build`](#command_line_composite)

The `--include-build` command-line argument turns the executed build into a composite, substituting dependencies from the included build into the executed build.

Output of **`gradle --include-build ../my-utils run`**

\> gradle --include-build ../my-utils run  
\> Task :app:processResources NO-SOURCE  
\> Task :my-utils:string-utils:compileJava  
\> Task :my-utils:string-utils:processResources NO-SOURCE  
\> Task :my-utils:string-utils:classes  
\> Task :my-utils:string-utils:jar  
\> Task :my-utils:number-utils:compileJava  
\> Task :my-utils:number-utils:processResources NO-SOURCE  
\> Task :my-utils:number-utils:classes  
\> Task :my-utils:number-utils:jar  
\> Task :app:compileJava  
\> Task :app:classes

\> Task :app:run  
The answer is 42

BUILD SUCCESSFUL in 0s  
6 actionable tasks: 6 executed

### [](#settings_defined_composite)[Defining a composite build via the settings file](#settings_defined_composite)

It’s possible to make the above arrangement persistent, by using [Settings.includeBuild(java.lang.Object)](../dsl/org.gradle.api.initialization.Settings.html#org.gradle.api.initialization.Settings:includeBuild(java.lang.Object)) to declare the included build in the `settings.gradle` (or `settings.gradle.kts` in Kotlin) file. The settings file can be used to add subprojects and included builds at the same time. Included builds are added by location. See the examples below for more details.

### [](#separate_composite)[Defining a separate composite build](#separate_composite)

One downside of the above approach is that it requires you to modify an existing build, rendering it less useful as a standalone build. One way to avoid this is to define a separate composite build, whose only purpose is to combine otherwise separate builds.

Example 2. [Declaring a separate composite](#ex-declaring-a-separate-composite)

`Kotlin``Groovy`

settings.gradle.kts

```
rootProject.name =  "my-composite" includeBuild("my-app") includeBuild("my-utils")
```

settings.gradle

```
rootProject.name =  'my-composite' includeBuild 'my-app' includeBuild 'my-utils'
```

In this scenario, the 'main' build that is executed is the composite, and it doesn’t define any useful tasks to execute itself. In order to execute the 'run' task in the 'my-app' build, the composite build must define a delegating task.

Example 3. [Depending on task from included build](#ex-depending-on-task-from-included-build)

`Kotlin``Groovy`

build.gradle.kts

```
tasks.register("run")  { dependsOn(gradle.includedBuild("my-app").task(":app:run"))  }
```

build.gradle

```
tasks.register('run')  { dependsOn gradle.includedBuild('my-app').task(':app:run')  }
```

More details about tasks that depend on included build tasks are below.

### [](#included_plugin_builds)[Including builds that define Gradle plugins](#included_plugin_builds)

A special case of included builds are builds that define Gradle plugins. These builds should be included using the `includeBuild` statement inside the `pluginManagement {}` block of the settings file. Using this mechanism, the included build may also contribute a settings plugin that can be applied in the settings file itself.

Example 4. [Including a plugin build](#ex-including-a-plugin-build)

`Kotlin``Groovy`

settings.gradle.kts

```
pluginManagement { includeBuild("../url-verifier-plugin")  }
```

settings.gradle

```
pluginManagement { includeBuild '../url-verifier-plugin'  }
```

| | 

You may also use the `includeBuild` mechanism outside `pluginManagement` to include plugin builds. However, this does not support all use cases and including plugin builds like that might be deprecated in a future Gradle version.

 |

### [Restrictions on included builds](#included_builds)

Most builds can be included into a composite, including other composite builds. However there are some restrictions.

Every included build:

* must not have a `rootProject.name` the same as another included build.
* must not have a `rootProject.name` the same as a top-level project of the composite build.
* must not have a `rootProject.name` the same as the composite build `rootProject.name`.

[Interacting with a composite build](#interacting_with_composite_builds)
--------------------------------------------------------------------------------------------------------------

In general, interacting with a composite build is much the same as a regular multi-project build. Tasks can be executed, tests can be run, and builds can be imported into the IDE.

### [Executing tasks](#composite_build_executing_tasks)

Tasks from an included build can be executed from the command-line or from your IDE in the same way as tasks from a regular multi-project build. Executing a task will result in task dependencies being executed, as well as those tasks required to build dependency artifacts from other included builds.

You can call a task in an included build using a fully qualified path, for example `:included-build-name:project-name:taskName`. Project and task names can be [abbreviated](command_line_interface.html#sec:name_abbreviation).

$ ./gradlew :included-build:subproject-a:compileJava  
\> Task :included-build:subproject-a:compileJava

$ ./gradlew :i-b:sA:cJ  
\> Task :included-build:subproject-a:compileJava

To [exclude a task from the command line](command_line_interface.html#sec:excluding_tasks_from_the_command_line), you also need to provide the fully qualified path to the task.

Included build tasks are automatically executed in order to generate required dependency artifacts, or the [including build can declare a dependency on a task from an included build](#included_build_task_dependencies).

### [Importing into the IDE](#composite_build_ide_integration)

One of the most useful features of composite builds is IDE integration. By applying the [idea](idea_plugin.html#idea_plugin) or [eclipse](eclipse_plugin.html#eclipse_plugin) plugin to your build, it is possible to generate a single IDEA or Eclipse project that permits all builds in the composite to be developed together.

In addition to these Gradle plugins, recent versions of [IntelliJ IDEA](https://www.jetbrains.com/idea/) and [Eclipse Buildship](https://projects.eclipse.org/projects/tools.buildship) support direct import of a composite build.

Importing a composite build permits sources from separate Gradle builds to be easily developed together. For every included build, each sub-project is included as an IDEA Module or Eclipse Project. Source dependencies are configured, providing cross-build navigation and refactoring.

[Declaring the dependencies substituted by an included build](#included_build_declaring_substitutions)
-------------------------------------------------------------------------------------------------------------------------------------------------

By default, Gradle will configure each included build in order to determine the dependencies it can provide. The algorithm for doing this is very simple: Gradle will inspect the group and name for the projects in the included build, and substitute project dependencies for any external dependency matching `${project.group}:${project.name}`.

| | By default, substitutions are not registered for the _main_ build. To make the (sub)projects of the main build addressable by `${project.group}:${project.name}`, you can tell Gradle to treat the main build like an included build by self-including it: `includeBuild(".")`. |

There are cases when the default substitutions determined by Gradle are not sufficient, or they are not correct for a particular composite. For these cases it is possible to explicitly declare the substitutions for an included build. Take for example a single-project build 'anonymous-library', that produces a java utility library but does not declare a value for the group attribute:

Example 5. [Build that does not declare group attribute](#ex-build-that-does-not-declare-group-attribute)

`Kotlin``Groovy`

build.gradle.kts

```
plugins { java }
```

build.gradle

```
plugins { id 'java'  }
```

When this build is included in a composite, it will attempt to substitute for the dependency module "undefined:anonymous-library" ("undefined" being the default value for `project.group`, and "anonymous-library" being the root project name). Clearly this isn’t going to be very useful in a composite build. To use the unpublished library unmodified in a composite build, the composing build can explicitly declare the substitutions that it provides:

Example 6. [Declaring the substitutions for an included build](#ex-declaring-the-substitutions-for-an-included-build)

`Kotlin``Groovy`

settings.gradle.kts

```
includeBuild("anonymous-library")  { dependencySubstitution { substitute(module("org.sample:number-utils")).using(project(":"))  }  }
```

settings.gradle

```
includeBuild('anonymous-library')  { dependencySubstitution { substitute module('org.sample:number-utils')  using project(':')  }  }
```

With this configuration, the "my-app" composite build will substitute any dependency on `org.sample:number-utils` with a dependency on the root project of "anonymous-library".

### [Deactivate included build substitutions for a Configuration](#deactivate_included_build_substitutions)

If you need to [resolve](declaring_dependencies.html#sec:resolvable-consumable-configs) a published version of a module that is also available as part of an included build, you can deactivate the included build substitution rules on the [ResolutionStrategy](../dsl/org.gradle.api.artifacts.ResolutionStrategy.html) of the Configuration that is resolved. This is necessary, because the rules are globally applied in the build and Gradle does not consider published versions during resolution by default.

Example 7. [Deactivate global dependency substitution rules](#ex-deactivate-global-dependency-substitution-rules)

`Kotlin``Groovy`

build.gradle.kts

```
configurations.create("publishedRuntimeClasspath")  { resolutionStrategy.useGlobalDependencySubstitutionRules.set(false) extendsFrom(configurations.runtimeClasspath.get()) isCanBeConsumed =  false isCanBeResolved =  true attributes.attribute(Usage.USAGE_ATTRIBUTE, objects.named(Usage.JAVA_RUNTIME))  }
```

build.gradle

```
configurations.create('publishedRuntimeClasspath')  { resolutionStrategy.useGlobalDependencySubstitutionRules =  false extendsFrom(configurations.runtimeClasspath) canBeConsumed =  false canBeResolved =  true attributes.attribute(Usage.USAGE_ATTRIBUTE, objects.named(Usage,  Usage.JAVA_RUNTIME))  }
```

In this example, we create a separate `publishedRuntimeClasspath` configuration that gets resolve to the published versions of modules that also exist in one of the local builds. This can be used, for example, to compare published and locally built Jar files.

### [Cases where included build substitutions must be declared](#included_build_substitution_requirements)

Many builds will function automatically as an included build, without declared substitutions. Here are some common cases where declared substitutions are required:

* When the `archivesBaseName` property is used to set the name of the published artifact.
* When a configuration other than `default` is published.
* When the `MavenPom.addFilter()` is used to publish artifacts that don’t match the project name.
* When the `maven-publish` or `ivy-publish` plugins are used for publishing, and the publication coordinates don’t match `${project.group}:${project.name}`.

### [Cases where composite build substitutions won’t work](#included_build_substitution_limitations)

Some builds won’t function correctly when included in a composite, even when dependency substitutions are explicitly declared. This limitation is due to the fact that a project dependency that is substituted will always point to the `default` configuration of the target project. Any time that the artifacts and dependencies specified for the default configuration of a project don’t match what is actually published to a repository, then the composite build may exhibit different behaviour.

Here are some cases where the publish module metadata may be different from the project default configuration:

* When a configuration other than `default` is published.
* When the `maven-publish` or `ivy-publish` plugins are used.
* When the `POM` or `ivy.xml` file is tweaked as part of publication.

Builds using these features function incorrectly when included in a composite build. We plan to improve this in the future.

[Depending on tasks in an included build](#included_build_task_dependencies)
-----------------------------------------------------------------------------------------------------------------

While included builds are isolated from one another and cannot declare direct dependencies, a composite build is able to declare task dependencies on its included builds. The included builds are accessed using [Gradle.getIncludedBuilds()](../dsl/org.gradle.api.invocation.Gradle.html#org.gradle.api.invocation.Gradle:includedBuilds) or [Gradle.includedBuild(java.lang.String)](../dsl/org.gradle.api.invocation.Gradle.html#org.gradle.api.invocation.Gradle:includedBuild(java.lang.String)), and a task reference is obtained via the [IncludedBuild.task(java.lang.String)](../dsl/org.gradle.api.initialization.IncludedBuild.html#org.gradle.api.initialization.IncludedBuild:task(java.lang.String)) method.

Using these APIs, it is possible to declare a dependency on a task in a particular included build, or tasks with a certain path in all or some of the included builds.

Example 8. [Depending on a single task from an included build](#ex-depending-on-a-single-task-from-an-included-build)

`Kotlin``Groovy`

build.gradle.kts

```
tasks.register("run")  { dependsOn(gradle.includedBuild("my-app").task(":app:run"))  }
```

build.gradle

```
tasks.register('run')  { dependsOn gradle.includedBuild('my-app').task(':app:run')  }
```

Example 9. [Depending on a task with path in all included builds](#ex-depending-on-a-task-with-path-in-all-included-builds)

`Kotlin``Groovy`

build.gradle.kts

```
tasks.register("publishDeps")  { dependsOn(gradle.includedBuilds.map { it.task(":publishMavenPublicationToMavenRepository")  })  }
```

build.gradle

```
tasks.register('publishDeps')  { dependsOn gradle.includedBuilds*.task(':publishMavenPublicationToMavenRepository')  }
```

[Current limitations and future plans for composite builds](#current_limitations_and_future_work)
-----------------------------------------------------------------------------------------------------------------------------------------

Limitations of the current implementation include:

* No support for included builds that have publications that don’t mirror the project default configuration. See [Cases where composite builds won’t work](#included_build_substitution_limitations).
* Multiple composite builds may conflict when run in parallel, if more than one includes the same build. Gradle does not share the project lock of a shared composite build to between Gradle invocation to prevent concurrent execution.