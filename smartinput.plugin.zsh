declare -g __smartinput_rules=(
  "'"
  "\""
  '`'
  '()'
  '[]'
  '{}'
)

function __smartinput:widget:input_left_bracket {
  # Skip if previous char is backslash
  if [[ "$LBUFFER[-1]" == '\\' ]]; then
    zle self-insert
    return
  fi

  case "$KEYS" in
  "[")
    RBUFFER="]$RBUFFER"
    ;;
  "{")
    RBUFFER="}$RBUFFER"
    ;;
  "(")
    RBUFFER=")$RBUFFER"
    ;;
  esac
  zle self-insert
}

function __smartinput:widget:input_right_bracket {
  # Skip if previous char is backslash
  if [[ "$LBUFFER[-1]" == '\\' ]]; then
    zle self-insert
    return
  fi

  # If next char matches, just move forward
  if [[ "$RBUFFER[1]" == "$KEYS" ]]; then
    zle forward-char
    return
  fi
  zle self-insert
}

function __smartinput:widget:input_quote {
  # Skip if previous char is backslash
  if [[ "$LBUFFER[-1]" == '\\' ]]; then
    zle self-insert
    return
  fi

  # If next char matches, just move forward
  if [[ "$RBUFFER[1]" == "$KEYS" ]]; then
    zle forward-char
    return
  fi

  # For single quotes, check if we're in a word
  if [[ "$KEYS" == "'" ]]; then
    if [[ "$LBUFFER" =~ '[[:alnum:]]$' ]]; then
      zle self-insert
      return
    fi
  fi

  # Add matching quote
  RBUFFER="$KEYS$RBUFFER"
  zle self-insert
}

function __smartinput:widget:backward_delete_char {
  # Skip if previous char is backslash
  if [[ "$LBUFFER[-1]" == '\\' ]]; then
    zle backward-delete-char
    return
  fi

  local left right matched_pair=false
  for rule in "${__smartinput_rules[@]}"; do
    if [[ "${#rule}" == 1 ]]; then
      left="$rule"
      right="$rule"
    elif [[ "${#rule}" == 4 ]]; then
      left="${rule:0:1}"
      right="${rule:2:1}"
    fi

    if [[ "$LBUFFER[-1]" == "$left" && "$RBUFFER[1]" == "$right" ]]; then
      matched_pair=true
      break
    fi
  done

  if $matched_pair; then
    zle backward-delete-char
    zle delete-char
  else
    zle backward-delete-char
  fi
}

# Register widgets
zle -N __smartinput:widget:input_left_bracket
zle -N __smartinput:widget:input_right_bracket
zle -N __smartinput:widget:input_quote
zle -N __smartinput:widget:backward_delete_char

# Bind keys to widgets
bindkey '^H' __smartinput:widget:backward_delete_char
bindkey '^?' __smartinput:widget:backward_delete_char
bindkey '[' __smartinput:widget:input_left_bracket
bindkey '{' __smartinput:widget:input_left_bracket
bindkey '(' __smartinput:widget:input_left_bracket

# Dynamically bind keys based on rules
for rule in "${__smartinput_rules[@]}"; do
  if [[ "${#rule}" == 1 ]]; then
    bindkey "$rule" __smartinput:widget:input_quote
  elif [[ "${#rule}" == 4 ]]; then
    bindkey "${rule:0:1}" __smartinput:widget:input_left_bracket
    bindkey "${rule:2:1}" __smartinput:widget:input_right_bracket
  fi
done
