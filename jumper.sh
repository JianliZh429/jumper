#! /bin/bash
# Jumper shell wrapper - enables cd functionality
# This script is required because subprocesses cannot change the parent shell's directory

function j_help() {
    cat << 'HELP'
Jumper - Directory navigation tool

Usage:
  j              Jump to workspace root
  j <name>       Jump to a registered directory
  j --help       Show this help message

Shell aliases (set up by installer):
  j              - Jump to directory
  jadd           - Register a directory (jumper add)
  jassemble      - Find and register (jumper assemble)
  jalias         - Create alias (jumper alias)
  jlist          - List all registrations (jumper list)
  jremove        - Remove registration (jumper remove)

Examples:
  j              # Jump to workspace root
  j my-project   # Jump to registered directory
  jadd blog ~/work/blog
  jlist

For more information: https://github.com/yixun/jumper
HELP
}

function jump() {
  local target="$1"
  local JUMPER="${JUMPER_HOME:-$HOME/.jumper}/jumper"
  local target_dir

  # Handle help
  if [[ "${target}" == "--help" || "${target}" == "-h" || "${target}" == "help" ]]; then
    j_help
    return 0
  fi

  # No argument - jump to workspace root
  if [[ -z "${target}" ]]; then
    target_dir="${JUMPER_WORKSPACE:-$HOME}"
    echo "GOTO: $target_dir"
    # shellcheck disable=SC2164
    cd "$target_dir" || return 1
    return 0
  fi

  # Get target directory from jumper binary
  target_dir=$("$JUMPER" goto "$target" 2>&1)
  local exit_code=$?

  # Check for errors
  if [[ $exit_code -ne 0 ]]; then
    echo "Error: $target_dir" >&2
    return 1
  fi

  # Validate and change directory
  if [[ -d "$target_dir" ]]; then
    echo "GOTO: $target_dir"
    # shellcheck disable=SC2164
    cd "$target_dir" || return 1
  else
    echo "Error: '$target_dir' is not a valid directory" >&2
    return 1
  fi
}

# Execute jump function with all arguments
jump "$@"
