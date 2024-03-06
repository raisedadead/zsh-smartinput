declare -g __smartinput_rules=(
  "'"
  "\""
  '`'
  '()'
  '[]'
  '{}'
)

function __smartinput:widget:input_left_bracket {
  if [[ "$LBUFFER[-1]" == '\' ]]; then
    # Support Escape "\"
    :
  else
    local rule
    for rule in "${__smartinput_rules[@]}"; do
      if [[ "${#rule}" == 4 && "${rule:0:1}" == "$KEYS" ]]; then
        RBUFFER="${rule:2:1}$RBUFFER"
        break
      fi
    done
  fi
  zle self-insert
}

function __smartinput:widget:input_right_bracket {
  if [[ "$RBUFFER[1]" == "$KEYS" ]]; then
    # [xxxxxx|]<right bracket key>
    zle forward-char
    return
  fi
  zle self-insert
}

function __smartinput:widget:input_quote {
  if [[ "$LBUFFER[-1]" == '\' ]]; then
    # Support Escape "\"
    :
  elif [[ "$RBUFFER[1]" == "$KEYS" ]]; then
    # 'xxxxxx|'<quote key>
    zle forward-char
    return
  elif [[ "$KEYS" == "'" && "$LBUFFER" =~ '[[:word:]]$' ]]; then
    # Support English "someone's"
    :
  else
    RBUFFER="$KEYS$RBUFFER"
  fi
  zle self-insert
}

function __smartinput:widget:backward_delete_char {
  local left right matched_pair=false
  # Iterate over the rules to find if there's a matched pair for deletion
  for rule in "${__smartinput_rules[@]}"; do
    if [[ "${#rule}" == 1 ]]; then
      left="$rule"
      right="$rule"
    elif [[ "${#rule}" == 4 ]]; then
      left="${rule:0:1}"
      right="${rule:2:1}"
    else
      # Not a valid rule
      continue
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

zle -N __smartinput:widget:input_left_bracket
zle -N __smartinput:widget:input_right_bracket
zle -N __smartinput:widget:input_quote
zle -N __smartinput:widget:backward_delete_char
bindkey "^H" __smartinput:widget:backward_delete_char
bindkey "^?" __smartinput:widget:backward_delete_char

local rule
for rule in "${__smartinput_rules[@]}"; do
  if [[ "${#rule}" == 1 ]]; then
    bindkey "$rule" __smartinput:widget:input_quote
  elif [[ "${#rule}" == 4 ]]; then
    bindkey "${rule:0:1}" __smartinput:widget:input_left_bracket
    bindkey "${rule:2:1}" __smartinput:widget:input_right_bracket
  fi
done
