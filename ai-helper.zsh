#!/usr/bin/env zsh

# AI Terminal Assistant using GitHub Copilot CLI
# Fast defaults + basic command safety guard

export AI_SESSION_DIR="${HOME}/.config/gh-copilot/sessions"
export AI_CURRENT_SESSION="${AI_SESSION_DIR}/current_session_id"
mkdir -p "$AI_SESSION_DIR"

_ai_new_uuid() {
    if command -v python3 &> /dev/null; then
        python3 - <<'PY'
import uuid
print(uuid.uuid4())
PY
        return 0
    fi

    if [[ -r /proc/sys/kernel/random/uuid ]]; then
        cat /proc/sys/kernel/random/uuid
        return 0
    fi

    return 1
}

_ai_get_session() {
    if [[ -f "$AI_CURRENT_SESSION" ]]; then
        cat "$AI_CURRENT_SESSION"
    else
        echo ""
    fi
}

_ai_get_copilot_cmd() {
    local cmd_path

    cmd_path=$(whence -p copilot 2>/dev/null)
    if [[ -n "$cmd_path" && -x "$cmd_path" ]]; then
        echo "$cmd_path"
        return 0
    fi

    cmd_path=$(whence -p copilot.exe 2>/dev/null)
    if [[ -n "$cmd_path" && -x "$cmd_path" ]]; then
        echo "$cmd_path"
        return 0
    fi

    return 1
}

_ai_shell_is_safe() {
    local q="$1"

    # Hard blocks
    [[ "$q" =~ '(^|[[:space:]])sudo([[:space:]]|$)' ]] && return 1
    [[ "$q" =~ '(^|[[:space:]])su([[:space:]]|$)' ]] && return 1
    [[ "$q" =~ '(^|[[:space:]])shutdown([[:space:]]|$)' ]] && return 1
    [[ "$q" =~ '(^|[[:space:]])reboot([[:space:]]|$)' ]] && return 1
    [[ "$q" =~ '(^|[[:space:]])mkfs([[:space:]]|$)' ]] && return 1
    [[ "$q" =~ '(^|[[:space:]])fdisk([[:space:]]|$)' ]] && return 1
    [[ "$q" =~ '(^|[[:space:]])eval([[:space:]]|$)' ]] && return 1
    [[ "$q" =~ '(^|[[:space:]])exec([[:space:]]|$)' ]] && return 1
    [[ "$q" =~ '(^|[[:space:]])rm([[:space:]].*)?-r(f)?([[:space:]]|$)' ]] && return 1
    [[ "$q" =~ '(^|[[:space:]])rm([[:space:]].*)?-rf([[:space:]]|$)' ]] && return 1

    # Block common chaining/injection operators
    [[ "$q" == *';'* ]] && return 1
    [[ "$q" == *'&&'* ]] && return 1
    [[ "$q" == *'||'* ]] && return 1
    [[ "$q" == *'`'* ]] && return 1
    [[ "$q" == *'$('* ]] && return 1

    return 0
}

ai() {
    if [[ "$1" == "clear" ]] || [[ "$1" == "reset" ]] || [[ "$1" == "new" ]]; then
        rm -f "$AI_CURRENT_SESSION"
        echo "AI session cleared."
        return 0
    fi

    if [[ "$1" == "help" ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        cat <<EOF
Usage:
  ai <query>        Contextual mode (resume session)
  ai ! <query>      Fast stateless mode (no resume)
  ai clear          Reset session
EOF
        return 0
    fi

    if [[ $# -eq 0 ]]; then
        echo "Usage: ai <query>"
        return 1
    fi

    local copilot_cmd
    copilot_cmd=$(_ai_get_copilot_cmd)
    if [[ -z "$copilot_cmd" ]]; then
        echo "Error: Copilot CLI not found"
        return 1
    fi

    local stateless="false"
    if [[ "$1" == "!" ]]; then
        stateless="true"
        shift
    fi

    # Preserve exact user text; avoids zsh glob issues with ? and *.
    local query="${(j: :)@}"
    local session_id
    session_id=$(_ai_get_session)

    if [[ "$stateless" != "true" && -z "$session_id" ]]; then
        session_id=$(_ai_new_uuid) || return 1
        echo "$session_id" > "$AI_CURRENT_SESSION"
    fi

    if [[ "$query" == *"shell command"* ]] || [[ "$query" == *"run "* ]] || [[ "$query" == *"execute "* ]]; then
        if ! _ai_shell_is_safe "$query"; then
            echo "Blocked potentially unsafe shell request."
            return 1
        fi
    fi

    if [[ "$stateless" == "true" ]]; then
        "$copilot_cmd" -p "$query" --model gpt-5-mini --effort low --allow-all-tools --no-ask-user --silent
    else
        "$copilot_cmd" -p "$query" --model gpt-5-mini --effort low --resume "$session_id" --allow-all-tools --no-ask-user --silent
    fi
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        rm -f "$AI_CURRENT_SESSION"
    fi

    return $exit_code
}

if [[ ! -f "${AI_SESSION_DIR}/.session_marker_$$" ]]; then
    rm -f "$AI_CURRENT_SESSION"
    touch "${AI_SESSION_DIR}/.session_marker_$$"
    find "${AI_SESSION_DIR}" -name ".session_marker_*" -mtime +1 -delete 2>/dev/null
fi

_ai_cleanup() {
    rm -f "${AI_SESSION_DIR}/.session_marker_$$"
}
trap _ai_cleanup EXIT

if [[ -n "$ZSH_VERSION" ]]; then
    compdef _gnu_generic ai 2>/dev/null || true
fi
