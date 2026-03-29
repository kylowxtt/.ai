#!/usr/bin/env sh
# AI Terminal Assistant using GitHub Copilot CLI
# POSIX-compatible helper (works in sh/bash)

AI_SESSION_DIR="${HOME}/.config/gh-copilot/sessions"
AI_CURRENT_SESSION="${AI_SESSION_DIR}/current_session_id"
mkdir -p "$AI_SESSION_DIR"

_ai_new_uuid() {
    if command -v python3 >/dev/null 2>&1; then
        python3 - <<'PY'
import uuid
print(uuid.uuid4())
PY
        return 0
    fi

    if [ -r /proc/sys/kernel/random/uuid ]; then
        cat /proc/sys/kernel/random/uuid
        return 0
    fi

    return 1
}

_ai_get_session() {
    if [ -f "$AI_CURRENT_SESSION" ]; then
        cat "$AI_CURRENT_SESSION"
    else
        printf '%s' ""
    fi
}

_ai_get_copilot_cmd() {
    if command -v copilot >/dev/null 2>&1; then
        command -v copilot
        return 0
    fi

    if command -v copilot.exe >/dev/null 2>&1; then
        command -v copilot.exe
        return 0
    fi

    return 1
}

_ai_shell_is_safe() {
    q="$1"

    case "$q" in
        *";"*|*"&&"*|*"||"*|*'`'*|*'$('*)
            return 1
            ;;
    esac

    padded=" $q "
    for blocked in " sudo " " su " " shutdown " " reboot " " mkfs " " fdisk " " eval " " exec "; do
        case "$padded" in
            *"$blocked"*)
                return 1
                ;;
        esac
    done

    case "$q" in
        *"rm -rf"*|*"rm -fr"*|*"rm -r "*|*"rm -r"*|*"rm --recursive "*)
            return 1
            ;;
    esac

    return 0
}

ai() {
    if [ "$1" = "clear" ] || [ "$1" = "reset" ] || [ "$1" = "new" ]; then
        rm -f "$AI_CURRENT_SESSION"
        echo "AI session cleared."
        return 0
    fi

    if [ "$1" = "help" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        cat <<'EOF'
Usage:
  ai <query>        Contextual mode (resume session)
  ai ! <query>      Fast stateless mode (no resume)
  ai clear          Reset session
EOF
        return 0
    fi

    if [ "$#" -eq 0 ]; then
        echo "Usage: ai <query>"
        return 1
    fi

    copilot_cmd="$(_ai_get_copilot_cmd)"
    if [ -z "$copilot_cmd" ]; then
        echo "Error: Copilot CLI not found"
        return 1
    fi

    stateless="false"
    if [ "$1" = "!" ]; then
        stateless="true"
        shift
    fi

    query="$*"
    session_id="$(_ai_get_session)"

    if [ "$stateless" != "true" ] && [ -z "$session_id" ]; then
        session_id="$(_ai_new_uuid)" || return 1
        printf '%s\n' "$session_id" > "$AI_CURRENT_SESSION"
    fi

    case "$query" in
        *"shell command"*|*"run "*|*"execute "*)
            if ! _ai_shell_is_safe "$query"; then
                echo "Blocked potentially unsafe shell request."
                return 1
            fi
            ;;
    esac

    if [ "$stateless" = "true" ]; then
        "$copilot_cmd" -p "$query" --model gpt-5-mini --effort low --allow-all-tools --no-ask-user --silent
    else
        "$copilot_cmd" -p "$query" --model gpt-5-mini --effort low --resume "$session_id" --allow-all-tools --no-ask-user --silent
    fi
    exit_code=$?

    if [ "$exit_code" -ne 0 ]; then
        rm -f "$AI_CURRENT_SESSION"
    fi

    return "$exit_code"
}

if [ ! -f "${AI_SESSION_DIR}/.session_marker_$$" ]; then
    rm -f "$AI_CURRENT_SESSION"
    : > "${AI_SESSION_DIR}/.session_marker_$$"
    find "${AI_SESSION_DIR}" -name ".session_marker_*" -mtime +1 -delete 2>/dev/null
fi

_ai_cleanup() {
    rm -f "${AI_SESSION_DIR}/.session_marker_$$"
}
trap _ai_cleanup EXIT

