---
aliases: []
created_date: 2023-08-24 19:57
draft: false
summary: ''
tags:
- dev
---

```java fold file:JStack
/*
 * Copyright (c) 2005, 2019, Oracle and/or its affiliates. All rights reserved.
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
 *
 * This code is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 only, as
 * published by the Free Software Foundation.  Oracle designates this
 * particular file as subject to the "Classpath" exception as provided
 * by Oracle in the LICENSE file that accompanied this code.
 *
 * This code is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * version 2 for more details (a copy is included in the LICENSE file that
 * accompanied this code).
 *
 * You should have received a copy of the GNU General Public License version
 * 2 along with this work; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * Please contact Oracle, 500 Oracle Parkway, Redwood Shores, CA 94065 USA
 * or visit www.oracle.com if you need additional information or have any
 * questions.
 */

package sun.tools.jstack;

import java.io.InputStream;
import java.util.Collection;

import com.sun.tools.attach.VirtualMachine;
import sun.tools.attach.HotSpotVirtualMachine;
import sun.tools.common.ProcessArgumentMatcher;
import sun.tools.common.PrintStreamPrinter;

/*
 * This class is the main class for the JStack utility. It parses its arguments
 * and decides if the command should be executed by the SA JStack tool or by
 * obtained the thread dump from a target process using the VM attach mechanism
 */
public class JStack {

    public static void main(String[] args) throws Exception {
        if (args.length == 0) {
            usage(1); // no arguments
        }

        checkForUnsupportedOptions(args);

        boolean locks = false;
        boolean extended = false;

        // Parse the options (arguments starting with "-" )
        int optionCount = 0;
        while (optionCount < args.length) {
            String arg = args[optionCount];
            if (!arg.startsWith("-")) {
                break;
            }
            if (arg.equals("-?")     ||
                arg.equals("-h")     ||
                arg.equals("--help") ||
                // -help: legacy.
                arg.equals("-help")) {
                usage(0);
            }
            else {
                if (arg.equals("-l")) {
                    locks = true;
                } else {
                    if (arg.equals("-e")) {
                        extended = true;
                    } else {
                        usage(1);
                    }
                }
            }
            optionCount++;
        }

        // Next we check the parameter count.
        int paramCount = args.length - optionCount;
        if (paramCount != 1) {
            usage(1);
        }

        // pass -l to thread dump operation to get extra lock info
        String pidArg = args[optionCount];
        String params[]= new String[] { "" };
        if (extended) {
            params[0] += "-e ";
        }
        if (locks) {
            params[0] += "-l";
        }

        ProcessArgumentMatcher ap = new ProcessArgumentMatcher(pidArg);
        Collection<String> pids = ap.getVirtualMachinePids(JStack.class);

        if (pids.isEmpty()) {
            System.err.println("Could not find any processes matching : '" + pidArg + "'");
            System.exit(1);
        }

        for (String pid : pids) {
            if (pids.size() > 1) {
                System.out.println("Pid:" + pid);
            }
            runThreadDump(pid, params);
        }
    }

    // Attach to pid and perform a thread dump
    private static void runThreadDump(String pid, String args[]) throws Exception {
        VirtualMachine vm = null;
        try {
            vm = VirtualMachine.attach(pid);
        } catch (Exception x) {
            String msg = x.getMessage();
            if (msg != null) {
                System.err.println(pid + ": " + msg);
            } else {
                x.printStackTrace();
            }
            System.exit(1);
        }

        // Cast to HotSpotVirtualMachine as this is implementation specific
        // method.
        InputStream in = ((HotSpotVirtualMachine)vm).remoteDataDump((Object[])args);
        // read to EOF and just print output
        PrintStreamPrinter.drainUTF8(in, System.out);
        vm.detach();
    }

    private static void checkForUnsupportedOptions(String[] args) {
        // Check arguments for -F, -m, and non-numeric value
        // and warn the user that SA is not supported anymore

        int paramCount = 0;

        for (String s : args) {
            if (s.equals("-F")) {
                SAOptionError("-F option used");
            }

            if (s.equals("-m")) {
                SAOptionError("-m option used");
            }

            if (! s.startsWith("-")) {
                paramCount += 1;
            }
        }

        if (paramCount > 1) {
            SAOptionError("More than one non-option argument");
        }
    }

    private static void SAOptionError(String msg) {
        System.err.println("Error: " + msg);
        System.err.println("Cannot connect to core dump or remote debug server. Use jhsdb jstack instead");
        System.exit(1);
    }

    // print usage message
    private static void usage(int exit) {
        System.err.println("Usage:");
        System.err.println("    jstack [-l][-e] <pid>");
        System.err.println("        (to connect to running process)");
        System.err.println("");
        System.err.println("Options:");
        System.err.println("    -l  long listing. Prints additional information about locks");
        System.err.println("    -e  extended listing. Prints additional information about threads");
        System.err.println("    -? -h --help -help to print this help message");
        System.exit(exit);
    }
}

```

```java fold file:runThreadDump
// Attach to pid and perform a thread dump
    private static void runThreadDump(String pid, String args[]) throws Exception {
        VirtualMachine vm = null;
        try {
            vm = VirtualMachine.attach(pid);
        } catch (Exception x) {
            String msg = x.getMessage();
            if (msg != null) {
                System.err.println(pid + ": " + msg);
            } else {
                x.printStackTrace();
            }
            System.exit(1);
        }

        // Cast to HotSpotVirtualMachine as this is implementation specific
        // method.
        InputStream in = ((HotSpotVirtualMachine)vm).remoteDataDump((Object[])args);
        // read to EOF and just print output
        PrintStreamPrinter.drainUTF8(in, System.out);
        vm.detach();
    }
```

如上的核心实现，是通过 `VirtualMachine` 进行远程连接。  
然后依次

- `javaVFrame::print_locked_object_class_name vframe.cpp:156` 6
- `javaVFrame::print_lock_info_on vframe.cpp:251`
- `JavaThread::print_stack_on thread.cpp:3259`
- `Threads::print_on thread.cpp:4786`
- `VM_PrintThreads::doit vmOperations.cpp:171`
- `VM_Operation::evaluate vmOperations.cpp:68`
- `VMThread::evaluate_operation vmThread.cpp:383`
- `VMThread::loop vmThread.cpp:521`
- `VMThread::run vmThread.cpp:274`
- `Thread::call_run thread.cpp:393`
- `thread_native_entry os_linux.cpp:791`
- `start_thread 0x00007fa45e0defa3`
- `clone 0x00007fa45e00a4cf`

其中会创建 `vframe.cpp#MonitorInfo`

```java
private:
  oop        _owner; // the object owning the monitor
  BasicLock* _lock;
  oop        _owner_klass; // klass (mirror) if owner was scalar replaced
  bool       _eliminated;
  bool       _owner_is_scalar_replaced;
```

然后会获取监听器的 `owner`

```cpp file:print_locked_object_class_name
print_locked_object_class_name(st, Handle(THREAD, monitor->owner()), lock_state);
```

最后通过 `globalDefineitions.hpp#p2i` 将 `pointer` 转化位 `intptr_t `

```java

st->print("\t- %s <" INTPTR_FORMAT "> ", lock_state, p2i(obj()));

// Convert pointer to intptr_t, for use in printing pointers.
inline intptr_t p2i(const void * p) {
  return (intptr_t) p;
}
```

参见 

```
"main" #1 prio=5 os_prio=31 tid=0x00007f9bd6808800 nid=0x1503 waiting on condition [0x000070000f70b000]
   java.lang.Thread.State: TIMED_WAITING (sleeping)
	at java.lang.Thread.sleep(Native Method)
	at Gzip3Test.main(Gzip3Test.java:22)
	// 这里的值
	- locked <0x000000071575ca20> (a java.lang.Object)
```

可以知道，最后打出来的值是锁的持有对象的地址。 

通过 [2023-08-24#JOL 依赖类库](../../Daily/2023/2023-08-24.md#JOL%20依赖类库) 这个依赖库，也能获取到相对应的 10 进制值，然后转化成 16 进制即可发现一致。  
比如

```java
VM.current().addressOf(object);
-> 30423750320
-> 0x00000007156596b0
```

和之前的 `Synchronized` 预期一致  
![深入理解 Synchronized 原理](深入理解%20Synchronized%20原理.md#^yjcs0y)