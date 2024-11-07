# Jeeves
Simple keystroke-initiated search tool that mimics the basic web search functionality of Alfred for the Mac on Windows. Jeeves uses AutoHotKey 2.0

Usage is simple:

- Install Autohotkey 2.0
- Place jeeves.ahk and jeeves.ini in the same folder
- Run right click on jeeves.ahk and run. 

Jeeves can run at startup by placing a shortcut to jeeves.ahk in the startup folder.

Configuration is super simple. In the jeeves.ini file, you'll see two sections: [SearchEngines] and [Settings]

[SearchEngines] is where you define search URLs. This doesn't have to be limited to search engines like Google or Duck Duck Go. Any site that passes search information via URL parameters can be used by replacing the search term with {query], as in this example, which is in the format of KEYWORD=URL{query}:

ddg=https://duckduckgo.com/?q={query}

With this example, typing "ddg tennis ball" will open up Duck Duck Go and search for the phrase "tennis ball"

Since this can be used for anything that accepts search terms via URL parameter, it can even be used with sites like Perplexity, which will accept full natural language prompts via URL parameter in the following way:

pp=https://www.perplexity.ai/search?q={query}

In  [Settings], the defaults are configured: 

- By default, CTRL-S is the command to open the search window. This conflicts with the "Save" shortcut on Windows devices, but it's the workflow I was accustomed to.

- Also by default, the search engine is Duck Duck Go. You can change this by specifying another keyword

