#!/usr/bin/env bash
# AI-Workflows install.sh — bash completion
#
# Install:
#   source contrib/install-completion.bash       # interactive shell, this session
#   # or symlink into a permanent location:
#   ln -s "$(pwd)/contrib/install-completion.bash" ~/.bash_completion.d/aiwf
#   # or for zsh users (bash-completion compat):
#   autoload bashcompinit && bashcompinit
#   source contrib/install-completion.bash
#
# Adds tab-completion for ./install.sh flags + their values:
#   ./install.sh --profile <TAB>     → restricted standard permissive
#   ./install.sh --preset <TAB>      → go-hex,nextjs-fsd,vue-pinia,k8s-helm (csv-aware)
#   ./install.sh --config <TAB>      → file glob
#   ./install.sh diff <TAB>          → directory glob
#   ./install.sh <TAB>               → directory glob (install target)
# Subcommand recognition (`diff`) is implicit — the position decides.

_aiwf_install() {
  local cur prev words cword
  if declare -F _init_completion >/dev/null 2>&1; then
    _init_completion -n : || return
  else
    # Fallback for minimal completion environments.
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    cword=$COMP_CWORD
    words=("${COMP_WORDS[@]}")
  fi

  local profiles="restricted standard permissive"
  local presets="go-hex nextjs-fsd vue-pinia k8s-helm"
  local subcommands="diff"
  local flags="--profile --preset --config --brain-path --dry-run --force --version --help -h"

  case "$prev" in
    --profile)
      COMPREPLY=( $(compgen -W "$profiles" -- "$cur") )
      return 0
      ;;
    --preset)
      # CSV-aware: complete each token after the last comma.
      local tail="${cur##*,}"
      local lead="${cur%"$tail"}"
      local matches
      matches=$(compgen -W "$presets" -- "$tail")
      if [[ -n "$matches" ]]; then
        COMPREPLY=()
        local m
        while IFS= read -r m; do
          [[ -n "$m" ]] && COMPREPLY+=("${lead}${m}")
        done <<< "$matches"
      fi
      return 0
      ;;
    --config)
      COMPREPLY=( $(compgen -f -- "$cur") )
      return 0
      ;;
    --brain-path)
      COMPREPLY=( $(compgen -d -- "$cur") )
      return 0
      ;;
  esac

  # Subcommand position (first positional after the script name).
  if [[ $cword -eq 1 ]]; then
    case "$cur" in
      -*) COMPREPLY=( $(compgen -W "$flags" -- "$cur") ) ;;
      *)  COMPREPLY=( $(compgen -W "$subcommands" -d -- "$cur") ) ;;
    esac
    return 0
  fi

  # After `diff` → directories only.
  if [[ "${words[1]}" == "diff" ]]; then
    COMPREPLY=( $(compgen -d -- "$cur") )
    return 0
  fi

  # Default: flags + target directory.
  case "$cur" in
    -*) COMPREPLY=( $(compgen -W "$flags" -- "$cur") ) ;;
    *)  COMPREPLY=( $(compgen -d -- "$cur") ) ;;
  esac
}

complete -F _aiwf_install install.sh
complete -F _aiwf_install ./install.sh
