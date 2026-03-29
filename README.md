# AI Terminal Assistant Setup

Natural language command interface using GitHub Copilot CLI with gpt-5-mini.

## Installation

Helper scripts are available for:

- `zsh`: `ai-helper.zsh`
- POSIX/Bash: `ai-helper.sh`
- PowerShell: `ai-helper.ps1`

### Zsh setup

Add this to `~/.zshrc`:

```bash
if [[ -f ~/.config/gh-copilot/.ai/.ai/ai-helper.zsh ]]; then
    source ~/.config/gh-copilot/.ai/.ai/ai-helper.zsh
fi
```

### POSIX/Bash setup

For Bash, add this to `~/.bashrc`:

```bash
if [ -f ~/.config/gh-copilot/.ai/.ai/ai-helper.sh ]; then
    . ~/.config/gh-copilot/.ai/.ai/ai-helper.sh
fi
```

For generic `sh` startup files, source the same helper script.

### PowerShell setup

Add this to your PowerShell profile:

```powershell
if (Test-Path "$HOME/.config/gh-copilot/.ai/.ai/ai-helper.ps1") {
    . "$HOME/.config/gh-copilot/.ai/.ai/ai-helper.ps1"
}
```

Open profile for editing:

```powershell
if (!(Test-Path -Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }
notepad $PROFILE
```

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

- Zsh helper: `~/.config/gh-copilot/.ai/.ai/ai-helper.zsh`
- POSIX/Bash helper: `~/.config/gh-copilot/.ai/.ai/ai-helper.sh`
- PowerShell helper: `~/.config/gh-copilot/.ai/.ai/ai-helper.ps1`
- Shell config file: your shell profile (`~/.zshrc`, `~/.bashrc`, or `$PROFILE`)
- Session data: `~/.config/gh-copilot/sessions/`

## Activating in Current Shell

To use immediately without restarting your terminal, run one of:

```bash
source ~/.zshrc
```

Or:

```bash
. ~/.config/gh-copilot/.ai/.ai/ai-helper.sh
```

Or in PowerShell:

```powershell
. "$HOME/.config/gh-copilot/.ai/.ai/ai-helper.ps1"
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
Reload your shell configuration (`source ~/.zshrc`, `source ~/.bashrc`, or restart PowerShell after profile changes).

### No responses
Ensure GitHub CLI is installed and authenticated:
```bash
gh --version
gh auth status
```

### Want to change the model?
Edit your shell helper (`ai-helper.zsh`, `ai-helper.sh`, or `ai-helper.ps1`) and change `--model gpt-5-mini`.

## Uninstall

1. Remove the source line from your shell profile (`~/.zshrc`, `~/.bashrc`, or `$PROFILE`):
   ```bash
   # Remove these lines:
   # if [[ -f ~/.config/gh-copilot/.ai/.ai/ai-helper.zsh ]]; then
   #     source ~/.config/gh-copilot/.ai/.ai/ai-helper.zsh
   # fi
   ```

2. Remove session data and helper files:
   ```bash
   rm -rf ~/.config/gh-copilot/sessions
   rm -f ~/.config/gh-copilot/.ai/.ai/ai-helper.zsh
   rm -f ~/.config/gh-copilot/.ai/.ai/ai-helper.sh
   ```

   In PowerShell, also remove:
   ```powershell
   Remove-Item -Force "$HOME/.config/gh-copilot/.ai/.ai/ai-helper.ps1"
   ```
