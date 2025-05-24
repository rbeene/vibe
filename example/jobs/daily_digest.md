---
name: "daily_digest"
cron: "0 9 * * *"
workflow: "blog_writer"
runtime: "stub"
concurrency: 1
---

# Daily Digest Job

## Description
Generates a daily digest blog post summarizing trending topics.

## Schedule
Runs daily at 9:00 AM

## Workflow
Executes the `blog_writer` workflow to create daily content.