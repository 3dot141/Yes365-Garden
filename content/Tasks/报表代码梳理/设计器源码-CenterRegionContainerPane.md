![525](../../../Attachments/b63e6442a77800fb0981d14a6aa82a4a.png)

- 生成工具条
	- com.fr.design.mainframe.CenterRegionContainerPane#resetToolkitByPlus

	```java
	protected void resetToolkitByPlus(ToolBarMenuDockPlus plus, ToolBarMenuDock ad, ToolKitConfigStrategy strategy) {  
	  
	    resetCombineUpTooBar(ad.resetUpToolBar(plus), plus);  
	  
	    if (toolbarComponent != null) {  
	        toolbarPane.remove(toolbarComponent);  
	    }  
	  
	    // 颜色，字体那些按钮的工具栏  
	    toolbarPane.add(toolbarComponent = ad.resetToolBar(toolbarComponent, plus), BorderLayout.CENTER);  
	    JPanel customNorthPane = strategy.customNorthPane(toolbarPane,plus);  
	    if (!isExist(customNorthPane)){  
	        this.removeNorth();  
	        this.add(customNorthPane, BorderLayout.NORTH);  
	    }  
	
		// 多模板 tab 
	    if (strategy.hasTemplateTabPane(plus)) {  
	        eastCenterPane.add(templateTabPane, BorderLayout.CENTER);  
	    } else {  
	        eastCenterPane.remove(templateTabPane);  
	    }  
	  
	    if (strategy.hasCombineUp(plus)) {  
	        eastCenterPane.add(combineUp, BorderLayout.NORTH);  
	    } else {  
	        eastCenterPane.remove(combineUp);  
	    }  
	    resetByDesignMode();  
	}
	```

- 创建工具栏 - `Font` 字体  
	![425](../../../Attachments/5d3bb4a43c26914be58ec41f7eb1bee2.png)  
	![380](../../../Attachments/603cfc7ed1b7798e89dee5d708663727.png)
- 创建工具栏组件  
	![455](../../../Attachments/919c1fd1cb326347850978a1b3da9264.png)
