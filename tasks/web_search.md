---
name: "web_search"
timeout: 60
retries: 2
---

# Web Search Task

## Description
Search the web for relevant information on a given topic.

## Inputs
- query: Search query string
- max_results: Maximum number of results (default: 10)

## Outputs
- results: Array of search results with title, url, snippet

## Implementation
Uses search APIs to find relevant web content and returns structured results.