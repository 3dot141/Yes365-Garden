---
aliases: []
draft: false
tags:
  - ai
created_date: 2023-03-31 17:38
---

> [Colab使用教程（超级详细版）及Colab Pro/Pro+评测 - 知乎](https://zhuanlan.zhihu.com/p/527663163?utm_id=0)

## 使用说明

### 费用说明

取决于使用什么机器配置。大概是 70 块 100 unit。  
然后 A100 的话，大概是 13 unit/h 。所以基本上等同于 70 块 = 8h  
还是蛮贵的。  
好处是

## 加载云盘

```
from google.colab import drive
drive.mount('/content/drive')
```

如果中间遇到 ["Transport endpoint is not connected"](https://stackoverflow.com/questions/49588113/google-colab-script-throws-transport-endpoint-is-not-connected)  
可以通过以下代码重连

```python file:solution1
from google.colab import drive
drive.mount('/content/drive')
```

```yaml file:solution2
!fusermount -u drive
!google-drive-ocamlfuse drive
```

## 内存查看

```
from psutil import virtual_memory

ram_gb = virtual_memory().total / 1e9

print('Your runtime has {:.1f} gigabytes of available RAM\n'.format(ram_gb))

if ram_gb < 20:

print('Not using a high-RAM runtime')

else:

print('You are using a high-RAM runtime!')
```

## 显卡查看

```
gpu_info = !nvidia-smi

gpu_info = '\n'.join(gpu_info)

if gpu_info.find('failed') >= 0:
	print('Not connected to a GPU')
else:
	print(gpu_info)
 
```

# System aliases

Jupyter includes shortcuts for common operations, such as ls:

---

```
!ls /bin
```

---

That `!ls` probably generated a large output. You can select the cell and clear the output by either:

1. Clicking on the clear output button (x) in the toolbar above the cell; or
2. Right clicking the left gutter of the output area and selecting "Clear output" from the context menu.

Execute any other process using `!` with string interpolation from python variables, and note the result can be assigned to a variable:

---

# Magics

Colaboratory shares the notion of magics from Jupyter. There are shorthand annotations that change how a cell's text is executed. To learn more, see [Jupyter's magics page](http://nbviewer.jupyter.org/github/ipython/ipython/blob/1.x/examples/notebooks/Cell%20Magics.ipynb).

参看下面的代码

```text
# 克隆仓库到/content/my-repo目录下
!git clone https://github.com/my-github-username/my-git-repo.git 
%cd my-git-repo
!./train.py --logdir /my/log/path --data_root /my/data/root --resume
```

既有 `!` 还有 `%` 就很奇怪。原因是 Jupyter 里面就有很多魔术命令。需要通过 `%` 才能生效
