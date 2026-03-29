# AI Terminal Assistant Setup

Natural language command interface using GitHub Copilot CLI with gpt-5-mini.

## Installation

Already installed! The setup has been added to your `~/.zshrc`.

## Usage

### Basic Commands

```bash
# Ask any question or request a command
ai how do I find large files?
ai list all processes using port 8080
ai create a python virtual environment
ai show me disk usage
ai explain what this command does: tar -xzf

# Get help
ai help

# Clear the conversation and start fresh
ai clear
```

### Features

- **Persistent Sessions**: Maintains conversation context within the same terminal session
- **Fast Model**: Uses `gpt-5-mini` for quick responses
- **Auto-Reset**: Automatically clears when you start a new terminal
- **Manual Reset**: Use `ai clear` to start a fresh conversation anytime

### How It Works

1. Type `ai` followed by your natural language request
2. The system sends your query to GitHub Copilot CLI with the gpt-5-mini model
3. Responses are inline and maintain context for follow-up questions
4. Each terminal session maintains its own conversation until cleared

### Session Management

- **Session Storage**: `~/.config/gh-copilot/sessions/`
- **Current Session**: Tracks conversation context automatically
- **Clear Session**: `ai clear`, `ai reset`, or `ai new`
- **Auto-Clear**: Sessions clear when you open a new terminal

## Configuration Files

- Main function: `~/.config/gh-copilot/ai-helper.zsh`
- ZSH config: `~/.zshrc` (sources the helper file)
- Session data: `~/.config/gh-copilot/sessions/`

## Activating in Current Shell

To use immediately without restarting your terminal:

```bash
source ~/.zshrc
```

Or:

```bash
source ~/.config/gh-copilot/ai-helper.zsh
```

## Examples

```bash
# File operations
ai find all python files modified in the last 7 days

# System diagnostics
ai why is my disk full?
ai check if port 3000 is in use

# Git operations
ai create a new branch called feature-login

# Package management
ai install nodejs on ubuntu

# Process management
ai kill the process using port 8000
```

## Troubleshooting

### Command not found: ai
Run `source ~/.zshrc` to reload your shell configuration.

### No responses
Ensure GitHub CLI is installed and authenticated:
```bash
gh --version
gh auth status
```

### Want to change the model?
Edit `~/.config/gh-copilot/ai-helper.zsh` and change `--model gpt-5-mini` to another model.

## Uninstall

1. Remove the source line from `~/.zshrc`:
   ```bash
   # Remove these lines:
   # AI Terminal Assistant - Natural Language Commands
   # if [[ -f ~/.config/gh-copilot/ai-helper.zsh ]]; then
   #     source ~/.config/gh-copilot/ai-helper.zsh
   # fi
   ```

2. Remove the files:
   ```bash
   rm -rf ~/.config/gh-copilot
   ```
