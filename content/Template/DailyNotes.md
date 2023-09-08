---
aliases: []
draft: false
tags: []
created_date: <% tp.file.creation_date() %>
modified_date: <% tp.file.creation_date() %>
---

```dataviewjs

const currentPage = dv.current().file;
const dailyPages = dv.pages('"Daily"').sort(k=>k.file.name, "asc");
const currentPageName = currentPage.name;
const index = dailyPages.findIndex((e) => {return e.file.name === currentPageName});
if (index < 1) {
	dv.table(["File", "Created", "Size"],[]);
} else {
	const lastIndex = index - 1;
	const lastPage = dailyPages[lastIndex].file;
	const allPages = dv.pages().values;
	const searchPages = [];
	
	const lastTime = dv.parse(lastPage.name);
	const currentTime = dv.parse(currentPage.name);

	for (let page of allPages) {
		const pageFile = page.file;
		if (pageFile.cday > lastTime && pageFile.cday <= currentTime) {
		  searchPages.push(pageFile);
		}
	}
	dv.table(["File", "Created", "Size"], searchPages.sort((a, b) => a.ctime > b.ctime ? 1 : -1).map(b => [b.link, b.ctime, b.size]));
}

```

<% tp.file.cursor() %>
