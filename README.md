# MultiAgent

A Ruby framework for building and orchestrating multi-agent AI systems. MultiAgent enables you to create collaborative AI workflows where multiple agents work together to solve complex tasks.

## Features

- 🤖 **Multi-Agent Orchestration** - Coordinate multiple AI agents with different roles and capabilities
- 📝 **Markdown-based DSL** - Define agents, tasks, and workflows using simple markdown files
- 🔄 **Dependency Resolution** - Automatically manages dependencies between agents and tasks
- ⚡ **Concurrent Execution** - Run independent tasks in parallel for better performance
- 🔌 **Extensible Architecture** - Add custom plugins and runtime adapters
- 📊 **Structured Logging** - Built-in telemetry and audit trails for debugging

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'multi_agent'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself:

```bash
$ gem install multi_agent
```

## Quick Start

### 1. Create an Agent

Agents are AI entities with specific roles. Create an agent using the CLI:

```bash
$ bin/mag new agent researcher
```

Or manually create `agents/researcher.md`:

```markdown
---
name: researcher
role: Research Assistant
goal: Gather and analyze information on topics
backstory: You are an expert researcher skilled at finding and synthesizing information.
---

You excel at:
- Finding relevant information from various sources
- Analyzing and summarizing complex topics
- Identifying key insights and patterns
```

### 2. Define a Task

Tasks are discrete units of work. Create `tasks/web_search.md`:

```markdown
---
name: web_search
description: Search the web for information
expected_output: Comprehensive search results with summaries
---

Search for information about {topic} and provide:
1. Key findings
2. Relevant sources
3. Summary of important points
```

### 3. Create a Workflow

Workflows orchestrate agents and tasks. Create `workflows/research_workflow.md`:

```markdown
---
name: research_workflow
description: Research a topic using multiple agents
---

## Agents
@agent researcher from '../agents/researcher.md'
@agent writer from '../agents/writer.md'

## Tasks
@task search from '../tasks/web_search.md' by researcher
  with:
    topic: "AI agent frameworks"

@task summarize by writer
  with:
    content: "{{search.output}}"
  depends_on: [search]
```

### 4. Run the Workflow

```bash
# Compile the workflow (validates structure)
$ bin/mag compile workflows/research_workflow.md

# Run the workflow
$ bin/mag run workflows/research_workflow.md
```

## CLI Commands

The `mag` CLI provides commands for managing your multi-agent system:

```bash
# Create new components
$ bin/mag new agent <name>          # Create a new agent
$ bin/mag new task <name>           # Create a new task  
$ bin/mag new workflow <name>       # Create a new workflow
$ bin/mag new job <name>            # Create a scheduled job
$ bin/mag new plugin <name>         # Create a plugin

# Work with workflows
$ bin/mag compile <workflow_path>   # Validate and compile a workflow
$ bin/mag run <workflow_path>       # Execute a workflow
$ bin/mag dot <workflow_path>       # Generate DOT graph visualization

# Run scheduled jobs
$ bin/mag run_job <job_path>        # Execute a scheduled job

# Evaluate workflows
$ bin/mag evaluate <eval_path>      # Run evaluation scorecard

# List plugins
$ bin/mag plugins:list              # Show available plugins
```

## Configuration

Configure MultiAgent in `config/project.yaml`:

```yaml
name: my-multi-agent-project
version: 1.0.0
description: My AI agent system
runtime_default: openai
log_level: info
telemetry_opt_in: true
openai_api_key_env: OPENAI_API_KEY
```

## Running Workflows

### Basic Usage

```bash
# With stub runtime (default, for testing)
$ bin/mag run workflows/blog_writer.md

# With OpenAI runtime
$ OPENAI_API_KEY=sk-... bin/mag run workflows/blog_writer.md --runtime openai

# With concurrency limit
$ bin/mag run workflows/blog_writer.md --concurrency 4
```

### Advanced Features

#### Concurrent Execution

Tasks without dependencies run in parallel automatically:

```markdown
@task task1 by agent1
@task task2 by agent2  
@task task3 by agent1
  depends_on: [task1, task2]  # Waits for both to complete
```

#### Using References

Reference outputs from other tasks using template syntax:

```markdown
@task analyze by analyst
  with:
    data: "{{gather_data.output}}"
    context: "{{previous_analysis.summary}}"
  depends_on: [gather_data, previous_analysis]
```

#### Scheduled Jobs

Create recurring workflows with `jobs/daily_report.md`:

```markdown
---
name: daily_report
description: Generate daily reports
schedule: "0 9 * * *"  # 9 AM daily (cron syntax)
enabled: true
---

@workflow report from '../workflows/daily_report_workflow.md'
```

## Project Structure

```
multi_agent/
├── agents/          # Agent definitions
├── tasks/           # Reusable task definitions
├── workflows/       # Workflow orchestrations
├── jobs/            # Scheduled jobs
├── plugins/         # Extension plugins
├── eval/            # Evaluation scorecards
├── resources/       # Static resources
├── config/         
│   └── project.yaml # Configuration
├── lib/            
│   └── multi_agent/ # Core framework code
├── log/             # Structured logs
├── tmp/             # Temporary files and compiled IR
└── bin/
    └── mag          # CLI executable
```

## Examples

### Blog Writer Workflow

See `workflows/blog_writer.md` for a complete example of agents collaborating to research and write blog posts:

1. Researcher agent gathers information using web search
2. Writer agent creates content based on research
3. Editor agent reviews and refines the content

### Support Bot System

Check `agents/support-bot.md` and `agents/faq-bot.md` for examples of specialized agents handling customer support tasks.

## Extending MultiAgent

### Custom Plugins

Create plugins to extend functionality:

```ruby
# plugins/vector_search/vector_search.rb
module MultiAgent
  module Plugins
    class VectorSearch
      def search(query, options = {})
        # Implementation
      end
    end
  end
end
```

With manifest `plugins/vector_search/manifest.yml`:

```yaml
name: vector_search
version: 1.0.0
description: Vector search capabilities
entry_point: vector_search.rb
```

### Runtime Adapters

MultiAgent supports multiple AI providers:

- **OpenAI** - Default adapter using GPT models
- **Stub** - For testing without API calls

Configure in your workflow:

```yaml
runtime: openai  # or 'stub' for testing
```

## Development

### Running Tests

```bash
$ bundle exec rake test
```

### Best Practices

1. **Single Responsibility** - Each agent should have one clear role
2. **Reusable Tasks** - Define tasks that can be shared across workflows
3. **Clear Dependencies** - Explicitly define task dependencies
4. **Structured Outputs** - Use consistent output formats for better agent collaboration
5. **Test with Stubs** - Use the stub runtime for testing workflows without API costs

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This gem is available as open source under the terms of the [MIT License](LICENSE.txt).