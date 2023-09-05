---
aliases: []
draft: false
tags:
  - ai
created_date: 2023-08-23 22:30
---

- 什么是LangChain Agent
- 例子
- 工作原理

## 什么是LangChain Agent

简单来说，用户像LangChain输入的内容未知。此时可以有一套工具集合(也可以自定义工具)，将这套自定义工具托管给LLM,让其自己决定使用工具中的某一个(如果存在的话)

## 例子

首先，这里自定义了两个简单的工具

```
from langchain.tools import BaseTool

# 天气查询工具 ，无论查询什么都返回Sunny
class WeatherTool(BaseTool):
    name = "Weather"
    description = "useful for When you want to know about the weather"

    def _run(self, query: str) -> str:
        return "Sunny^_^"

    async def _arun(self, query: str) -> str:
        """Use the tool asynchronously."""
        raise NotImplementedError("BingSearchRun does not support async")

# 计算工具，暂且写死返回3
class CustomCalculatorTool(BaseTool):
    name = "Calculator"
    description = "useful for when you need to answer questions about math."

    def _run(self, query: str) -> str:
        return "3"

    async def _arun(self, query: str) -> str:
        raise NotImplementedError("BingSearchRun does not support async")
```

接下来是针对于工具的简单调用：注意，这里使用OpenAI `temperature=0`需要限定为0

```
from langchain.agents import initialize_agent
from langchain.llms import OpenAI
from CustomTools import WeatherTool
from CustomTools import CustomCalculatorTool

llm = OpenAI(temperature=0)

tools = [WeatherTool(), CustomCalculatorTool()]

agent = initialize_agent(tools, llm, agent="zero-shot-react-description", verbose=True)

agent.run("Query the weather of this week,And How old will I be in ten years? This year I am 28")
```

看一下完整的响应过程：

```
I need to use two different tools to answer this question
Action: Weather
Action Input: This week
Observation: Sunny^_^
Thought: I need to use a calculator to answer the second part of the question
Action: Calculator
Action Input: 28 + 10
Observation: 3
Thought: I now know the final answer
Final Answer: This week will be sunny and in ten years I will be 38.
```

可以看到LangChain Agent 详细分析了每一个步骤，并且正确的调用了每一个可用的方法，拿到了相应的返回值，甚至在最后还修复了28+10=3这个错误。  

下面看看LangChain Agent是如何做到这点的

## 工作原理

首先看看我输入的问题是什么：  
`Query the weather of this week,And How old will I be in ten years? This year I am 28`  
查询本周天气，以及十年后我多少岁，今年我28

LangChain Agent中，有一套模板可以套用：

```
PREFIX = """Answer the following questions as best you can. You have access to the following tools:"""
FORMAT_INSTRUCTIONS = """Use the following format:

Question: the input question you must answer
Thought: you should always think about what to do
Action: the action to take, should be one of [{tool_names}]
Action Input: the input to the action
Observation: the result of the action
… (this Thought/Action/Action Input/Observation can repeat N times)
Thought: I now know the final answer
Final Answer: the final answer to the original input question"""
SUFFIX = """Begin!

Question: {input}
Thought:{agent_scratchpad}"""
```

通过这个模板，加上我们的问题以及自定义的工具，会变成下面这个样子,并且附带解释：

```
Answer the following questions as best you can.  You have access to the following tools: #  尽可能的去回答以下问题，你可以使用以下的工具：

Calculator: Useful for when you need to answer questions about math.
 # 计算器：当你需要回答数学计算的时候可以用到
Weather: useful for When you want to know about the weather #  天气：当你想知道天气相关的问题时可以用到
Use the following format: # 请使用以下格式(回答)

Question: the input question you must answer #  你必须回答输入的问题
Thought: you should always think about what to do
 # 你应该一直保持思考，思考要怎么解决问题
Action: the action to take, should be one of [Calculator, Weather] #  你应该采取[计算器,天气]之一
Action Input: the input to the action #  动作的输入
Observation: the result of the action # 动作的结果
…  (this Thought/Action/Action Input/Observation can repeat N times) # 思考-行动-输入-输出 的循环可以重复N次
T
hought: I now know the final answer # 最后，你应该知道最终结果了
Final Answer: the final answer to the original input question # 针对于原始问题，输出最终结果

Begin! # 开始
Question: Query the weather of this week,And How old will I be in ten years?  This year I am 28 #  问输入的问题
Thought:
```

通过这个模板向openai规定了一系列的规范，包括目前现有哪些工具集，你需要思考回答什么问题，你需要用到哪些工具，你对工具需要输入什么内容,等等。

如果仅仅是这样，openAI会完全补完你的回答，中间无法插入任何内容。因此LangChain使用OpenAI的stop参数，截断了AI当前对话。`"stop": ["\\nObservation: ", "\\n\\tObservation: "]`

做了以上设定以后，OpenAI仅仅会给到`Action`和 `Action Input`两个内容就被stop早停了。  
以下是OpenAI的响应内容：

```
I need to use the weather tool to answer the first part of the question, and the calculator to answer the second part.
Action: Weather
Action Input: This week
```

到这里是OpenAI的响应结果，可见，很简单就拿到了Action和Action Input。  
这里从Tools中找到`name=Weather`的工具，然后再将This Week传入方法。具体业务处理看详细情况。这里仅返回Sunny。

由于当前找到了Action和Action Input。 代表OpenAI认定当前任务链并没有结束。因此像请求体后拼接结果：`Observation: Sunny` 并且让他再次思考`Thought:`

开启第二轮思考：  
下面是再次请求的完整请求体:

```
Answer the following questions as best you can. You have access to the following tools:

Calculator: Useful for when you need to answer questions about math.
Weather: useful for When you want to know about the weather

Use the following format:

Question: the input question you must answer
Thought: you should always think about what to do
Action: the action to take, should be one of [Calculator, Weather]
Action Input: the input to the action
Observation: the result of the action
… (this Thought/Action/Action Input/Observation can repeat N times)
Thought: I now know the final answer
Final Answer: the final answer to the original input question

Begin!

Question: Query the weather of this week,And How old will I be in ten years? This year I am 28
Thought: I need to use the weather tool to answer the first part of the question, and the calculator to answer the second part.
Action: Weather
Action Input: This week
Observation: Sunny^_^
Thought:
```

同第一轮一样，OpenAI再次进行思考，并且返回`Action` 和 `Action Input` 后，再次被早停。

```
I need to calculate my age in ten years
Action: Calculator
Action Input: 28 + 10
```

由于计算器工具只会返回3，结果会拼接出一个错误的结果，构造成了一个新的请求体  
进行第三轮请求：

```
Answer the following questions as best you can. You have access to the following tools:

Calculator: Useful for when you need to answer questions about math.
Weather: useful for When you want to know about the weather

Use the following format:

Question: the input question you must answer
Thought: you should always think about what to do
Action: the action to take, should be one of [Calculator, Weather]
Action Input: the input to the action
Observation: the result of the action
… (this Thought/Action/Action Input/Observation can repeat N times)
Thought: I now know the final answer
Final Answer: the final answer to the original input question

Begin!

Question: Query the weather of this week,And How old will I be in ten years? This year I am 28
Thought: I need to use the weather tool to answer the first part of the question, and the calculator to answer the second pa<span style="background:#d3f8b6">r</span>t.
Action: Weather
Action Input: This week
Observation: Sunny^_^
Thought:I need to calculate my age in ten years
Action: Calculator
Action Input: 28 + 10
Observation: 3
Thought:
```

此时两个问题全都拿到了结果，根据开头的限定，OpenAi在完全拿到结果以后会返回`I now know the final answer`。并且根据完整上下文。把多个结果进行归纳总结：下面是完整的相应结果：

```
I now know the final answer
Final Answer: I will be 38 in ten years and the weather this week is sunny.
```

可以看到。ai 严格的按照设定返回想要的内容，并且还以外的把28+10=3这个数学错误给改正了

以上，就是 LangChain Agent 的完整工作流程
