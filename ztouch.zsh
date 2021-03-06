# vim:ft=zsh

typeset -gA __ZTOUCH
__ZTOUCH=(
  current_mode  "history"
  current_index "1"
  modes         "history","dirstack","functions"
  mode_label    ""
  init          0
  message_start ""
  message_end   ""
  message       ""
  max_width     10
  num_keys      24
  F1            'OP'
  F2            'OQ'
  F3            'OR'
  F4            'OS'
  F5            '[15~'
  F6            '[17~'
  F7            '[18~'
  F8            '[19~'
  F9            '[20~'
  F10           '[21~'
  F11           '[23~'
  F12           '[24~'
  F13           '[1;2P'
  F14           '[1;2Q'
  F15           '[1;2R'
  F16           '[1;2S'
  F17           '[15;2~'
  F18           '[17;2~'
  F19           '[18;2~'
  F20           '[19;2~'
  F21           '[20;2~'
  F22           '[21;2~'
  F23           '[23;2~'
  F24           '[24;2~'
)

## Mode Functions ##
__ztouch_mode_history() {

  local histsize histitem key
  local histindex=0

  __ZTOUCH[mode_label]="History"

  histsize="${#history[@]}"

  # Starting at 2 to offset the "mode change" key on F1
  for ((key=2; key <= __ZTOUCH[num_keys]; key++)); do

    histitem="${history[$((histsize-histindex))]}"

    if (($#histitem > 10)); then
      __ztouch_create_key "F${key}" "${(r:${__ZTOUCH[max_width]}:)histitem}..." "${histitem}" "print"
    else
      __ztouch_create_key "F${key}" "${histitem}" "${histitem}" "print"
    fi

    ((histindex++))

  done

}

__ztouch_mode_dirstack() {

  local key directory

  __ZTOUCH[mode_label]="Dirs"

  # Starting at 2 to offset the "mode change" key on F1
  for ((key=2; key <= __ZTOUCH[num_keys]; key++)); do

    if [[ -z "${dirstack[key-1]}" ]]; then
      return;
    fi

    directory="${dirstack[key-1]}"

    if (($#directory > 10)); then
      __ztouch_create_key "F${key}" "...${(l:${__ZTOUCH[max_width]}:)directory}" "cd ${directory}" "run"
    else
      __ztouch_create_key "F${key}" "${directory}" "cd ${directory}" "run"
    fi

  done

}

__ztouch_mode_functions() {

  local key=2
  local -A funcmap

  __ZTOUCH[mode_label]="Func"

  zstyle -a "ztouch:functions" map funcmap

  for label cmd in "${(kv)funcmap[@]}"; do
    ((key > __ZTOUCH[num_keys])) && break;

    __ztouch_create_key "F${key}" "${label}" "${cmd}" "run"

    ((key++))
  done
}

__ztouch_mode_commands() {

  local mode="$1"
  local key
  local -a labels

  zstyle -a "ztouch:${mode}" labels labels

  for ((key=1; key <= __ZTOUCH[num_keys]; key++)); do
    __ztouch_create_key "F${key}" "${labels[key]}" "" "label_only"
  done
}
## Mode Functions ##

## Widget Functions ##
__ztouch_cycle_mode() {

  local -a modes
  local modecount index

  __ztouch_clear

  modes=( ${(s:,:)__ZTOUCH[modes]} )
  modecount="${#modes[@]}"

  ((__ZTOUCH[current_index]++))

  if ((__ZTOUCH[current_index] > ${#modes[@]} )); then
    __ZTOUCH[current_index]=1
  fi

  __ZTOUCH[current_mode]="${modes[__ZTOUCH[current_index]]}"

  __ztouch_run

}
zle -N __ztouch_cycle_mode

__ztouch_print() {
  BUFFER="${__ZTOUCH[$KEYS]}"
  zle end-of-line
}
zle -N __ztouch_print
## Widget Functions ##

__ztouch_create_key() {

  local key label cmd mode

  key="$1"
  label="$2"
  cmd="$3"
  mode="$4"

  __ZTOUCH[message]+="${__ZTOUCH[message_start]}"SetKeyLabel=${key}=${label}"${__ZTOUCH[message_end]}"

  case "${mode}" in;
    "print")
      bindkey "${__ZTOUCH[${key}]}" __ztouch_print
      ;;
    "run")
      bindkey -s "${__ZTOUCH[${key}]}" "${cmd}\n"
      ;;
    "label_only")
      ;;
    *)
      bindkey "${__ZTOUCH[${key}]}" "${cmd}"
      ;;
  esac

  __ZTOUCH[${__ZTOUCH[${key}]}]="${cmd}"
}

__ztouch_run() {

  emulate -L zsh
  local matched_mode="$1"

  __ztouch_clear "now"

  if [[ -n "${matched_mode}" ]]; then
    __ztouch_mode_commands "${matched_mode}"
  else
    __ztouch_mode_${__ZTOUCH[current_mode]}
    __ztouch_create_key "F1" "${__ZTOUCH[mode_label]}" '__ztouch_cycle_mode'
  fi

  echo -ne "${__ZTOUCH[message]}"
}

__ztouch_clear() {

  emulate -L zsh

  __ZTOUCH[message]="${__ZTOUCH[message_start]}PopKeyLabels${__ZTOUCH[message_end]}"

  for ((key=1;key<=__ZTOUCH[num_keys];key++)); do
    bindkey -s "${__ZTOUCH[F${key}]}" ''
  done

  if [[ -n "$1" ]]; then
    echo -ne "${__ZTOUCH[message]}"
  fi
}

# Run once to initialize
__ztouch_init() {

  setopt auto_pushd pushd_ignore_dups

  local iterm2_osc_1337='\033]1337;'
  local iterm2_st='\a'
  local tmux_wrap_escape_start='\ePtmux;\e'
  local tmux_wrap_escape_end='\e\\'
  local nested_tmux_wrap_escape_start='\ePtmux;\e\ePtmux;\e\e\e'
  local nested_tmux_wrap_escape_end='\e\e\\\e\\'

  if [ -n "$NESTED_TMUX" ]; then
    __ZTOUCH[message_start]="${nested_tmux_wrap_escape_start}${iterm2_osc_1337}"
    __ZTOUCH[message_end]="${iterm2_st}${nested_tmux_wrap_escape_end}"
  elif [ -n "$TMUX" ]; then
    __ZTOUCH[message_start]="${tmux_wrap_escape_start}${iterm2_osc_1337}"
    __ZTOUCH[message_end]="${iterm2_st}${tmux_wrap_escape_end}"
  else
    __ZTOUCH[message_start]="${iterm2_osc_1337}"
    __ZTOUCH[message_end]="${iterm2_st}"
  fi

  __ZTOUCH[init]=1

}

ztouch_plugin_unload() {

  add-zsh-hook -d precmd __ztouch_precmd
  add-zsh-hook -d preexec __ztouch_preexec

  __ztouch_clear

  unfunction ztouch_plugin_unload __ztouch_mode_history __ztouch_mode_dirstack \
    __ztouch_mode_functions __ztouch_cycle_mode __ztouch_print __ztouch_create_key \
    __ztouch_run __ztouch_clear __ztouch_init __ztouch_precmd __ztouch_preexec \
    __ztouch_mode_commands

  unset __ZTOUCH
}

__ztouch_precmd() {
  __ztouch_run
}

__ztouch_preexec() {

  local -A patterns
  local match

  zstyle -a 'ztouch:commands' patterns patterns 

  match="${patterns[(k)$1]}"

  if [[ -n "${match}" ]]; then
    __ztouch_run "${match}"
  fi

}

autoload -Uz add-zsh-hook
add-zsh-hook precmd __ztouch_precmd
add-zsh-hook preexec __ztouch_preexec

__ztouch_init
