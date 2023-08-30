#!/bin/bash

function jump() {
  if [ -z "$1" ]; then
    # shellcheck disable=SC2164
    echo -e "GOTO $JUMPER_WORKSPACE"
    cd "${JUMPER_WORKSPACE}"
  else
    JUMPER=$JUMPER_HOME/jumper
    FIRST_DIR=$($JUMPER goto "$1" | tr -d '"')
    
    if (( $(grep -c . <<<"${FIRST_DIR}") > 1 )); then
      echo -e "${FIRST_DIR}\n"
    fi

    FIRST_DIR=$(echo "${FIRST_DIR}" | tail -n 1)
    echo -e "GOTO: $FIRST_DIR"

    if [[ -d $FIRST_DIR ]]; then
      # shellcheck disable=SC2164
      cd "$FIRST_DIR"
    else
      FIRST_DIR=$1
      echo -e "\n$FIRST_DIR is not a valid directory"
    fi
  fi
}

jump "$1"
