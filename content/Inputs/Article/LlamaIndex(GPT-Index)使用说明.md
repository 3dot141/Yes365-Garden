---
aliases: []
draft: false
tags:
  - ai
created_date: 2023-08-25 16:00
---

> [LlamaIndex Usage Pattern — LlamaIndex documentation](https://gpt-index.readthedocs.io/en/latest/guides/primer/usage_pattern.html#setting-response-mode) 有很多可以吸收借鉴的地方  
> 比如折叠、总结模式  
> 比如类结构的处理  
> [LLamaIndex FAQ](https://docs.google.com/document/u/0/d/1bLP7301n4w9_GsukIYvEhZXVAvOMWnrxMy089TYisXU/mobilebasic#) 一些常见的问题

> [Data Connectors (LlamaHub 🦙) - LlamaIndex](https://gpt-index.readthedocs.io/en/latest/how_to/data_connectors.html)

Our data connectors are offered through [LlamaHub](https://llamahub.ai/) 🦙.  
LlamaHub is an open-source repository containing data loaders that you can easily plug and play into any LlamaIndex application.

![525](Attachments/42f478209f3ddf55e7d50e64836d7207.png)

Some sample data connectors:

- local file directory (`SimpleDirectoryReader`). Can support parsing a wide range of file types: `.pdf`, `.jpg`, `.png`, `.docx`, etc.
- [Notion](https://developers.notion.com/) (`NotionPageReader`)
- [Google Docs](https://developers.google.com/docs/api) (`GoogleDocsReader`)
- [Slack](https://api.slack.com/) (`SlackReader`)
- [Discord](https://discord.com/developers/docs/intro) (`DiscordReader`)

Each data loader contains a "Usage" section showing how that loader can be used. At the core of using each loader is a `download_loader` function, which  
downloads the loader file into a module that you can use within your application.

Example usage:

```python
from llama_index import GPTSimpleVectorIndex, download_loader

GoogleDocsReader = download_loader('GoogleDocsReader')

gdoc_ids = ['1wf-y2pd9C878Oh-FmLH7Q_BQkljdm6TQal-c1pUfrec']
loader = GoogleDocsReader()
documents = loader.load_data(document_ids=gdoc_ids)
index = GPTSimpleVectorIndex.from_documents(documents)
index.query('Where did the author go to school?')
```

### Setting `mode`

An index can have a variety of query modes. For instance, you can choose to specify `mode="default"` or `mode="embedding"` for a list index. `mode="default"` will a create and refine an answer sequentially through the nodes of the list. `mode="embedding"` will synthesize an answer by fetching the top-k nodes by embedding similarity.

```
index = GPTListIndex.from_documents(documents)
# mode="default"
response = index.query("What did the author do growing up?", mode="default")
# mode="embedding"
response = index.query("What did the author do growing up?", mode="embedding")
```

The full set of modes per index are documented in the [Query Reference](../../reference/query.html).

### Setting `response_mode`

Note: This option is not available/utilized in `GPTTreeIndex`.

An index can also have the following response modes through `response_mode`:

- `default`: For the given index, “create and refine” an answer by sequentially going through each Node; make a separate LLM call per Node. Good for more detailed answers.
- `compact`: For the given index, “compact” the prompt during each LLM call by stuffing as many Node text chunks that can fit within the maximum prompt size. If there are too many chunks to stuff in one prompt, “create and refine” an answer by going through multiple prompts.
	- 会重新组合 contexts, 比如原来有 10 个 context, 会将其按照最大的可能组合成
- `tree_summarize`: Given a set of Nodes and the query, recursively construct a tree and return the root node as the response. Good for summarization purposes.

```
index = GPTListIndex.from_documents(documents)  
# mode="default"  
response = index.query("What did the author do growing up?", response_mode="default")  
# mode="compact"  
response = index.query("What did the author do growing up?", response_mode="compact")  
# mode="tree_summarize"  
response = index.query("What did the author do growing up?", response_mode="tree_summarize")
```

### Query

> 查询是会通过上面的模式，将 contexts 转化成串行的多个不同的 resquset.  
> 大概形式如下 【lastRes-context-request-response】 + 【lastRes-context-request-response】
