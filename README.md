# MultiAgent

A Ruby framework for building and orchestrating multi-agent AI systems.

## Installation

```bash
bundle install
```

## Usage

### Compile a workflow
```bash
bin/mag compile workflows/blog_writer.md
```

### Run a workflow
```bash
# With stub runtime (default)
bin/mag run workflows/blog_writer.md

# With OpenAI runtime
OPENAI_API_KEY=sk-... bin/mag run workflows/blog_writer.md --runtime openai

# With concurrency
bin/mag run workflows/blog_writer.md --concurrency 4
```

### Create new artifacts
```bash
bin/mag new agent my_agent
bin/mag new task my_task
bin/mag new workflow my_workflow
bin/mag new job my_job
bin/mag new eval my_eval
bin/mag new plugin my_plugin
```

### List plugins
```bash
bin/mag plugins:list
```

### Run scheduled jobs
```bash
bin/mag run_job jobs/daily_digest.md
```

### Evaluate workflows
```bash
bin/mag evaluate eval/blog_writer_scorecard.md
```

## Project Structure

- `agents/` - Agent definitions
- `tasks/` - Task definitions
- `workflows/` - Workflow orchestrations
- `jobs/` - Scheduled jobs
- `plugins/` - Extension plugins
- `eval/` - Evaluation scorecards
- `resources/` - Static resources
- `config/` - Configuration files
- `log/` - Structured logs
- `tmp/` - Temporary files and compiled IR

## Testing

```bash
bundle exec rake test
```

## License

MIT