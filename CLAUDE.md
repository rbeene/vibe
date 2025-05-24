# MultiAgent Ruby Gem

This Ruby gem is **MultiAgent** - a framework for building and orchestrating multi-agent AI systems.

## Core Purpose
- Orchestrates AI agents to work together on complex tasks
- Provides a workflow system where multiple AI agents can collaborate
- Supports both sequential and concurrent execution of agent tasks

## Key Components

1. **Agents** - AI entities with specific roles (e.g., researcher, writer, support bot)
2. **Tasks** - Discrete units of work agents can perform (e.g., web search)
3. **Workflows** - Orchestrations that coordinate multiple agents and tasks
4. **Jobs** - Scheduled or periodic workflows
5. **Plugins** - Extensions to add functionality (e.g., vector search)

## Architecture

- Uses markdown files with YAML frontmatter to define agents, tasks, and workflows
- Compiles markdown definitions into an intermediate representation (IR) graph
- Dispatches work to AI runtimes (OpenAI, stub for testing)
- Supports dependency resolution between agents/tasks using `@references`
- Provides structured logging and telemetry

## Example Use Case

The `blog_writer.md` workflow shows how a researcher agent gathers information using web search, then a writer agent creates blog content based on that research - demonstrating multi-agent collaboration.

## Commands

- `bin/mag compile workflows/blog_writer.md` - Compile a workflow
- `bin/mag run workflows/blog_writer.md` - Run a workflow
- `bin/mag new agent my_agent` - Create new agent
- `bin/mag run_job jobs/daily_digest.md` - Run scheduled job
- `bin/mag evaluate eval/blog_writer_scorecard.md` - Evaluate workflow