---
name: "blog_writer"
concurrency: 2
---

# Blog Writer Workflow

## Overview
Automates blog post creation by researching topics and generating content.

## Agents
- @researcher - Gathers information on the topic
- @writer - Creates the blog post content

## Tasks
- @web_search - Searches for relevant information

## Flow
1. Research Phase: @researcher uses @web_search to gather information
2. Writing Phase: @writer creates blog post based on research
3. Review Phase: Final editing and formatting