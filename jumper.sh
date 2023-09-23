#! /bin/bash

function help() {
   # Display Help
   echo "Command line tool for switching folders."
   echo
   echo "Commands: "
   echo "j          :Switch to the base working directory."
   echo "j  <Directory Name>"
   echo "           :Switch to the target directory."
   echo "jadd <Directory Name> <Directory Path>"
   echo "           :Register a new folder with its path."
   echo "jassemble  <Directory Name>"
   echo "           :Assemble the target directory and register it"
   echo "jalias <Shortcut>  <Registered Directory Name>"
   echo "           :Register the given shortcut as the target directory."
   echo
}

function jump() {
  target=$1
  if [ -z "${target}" ]; then
    # shellcheck disable=SC2164
    echo -e "GOTO $JUMPER_WORKSPACE"
    cd "${JUMPER_WORKSPACE}"
  else
    if [[ "${target}" == "--help" ]]; then
        help
        exit 0
    fi
    JUMPER=$JUMPER_HOME/jumper
    FIRST_DIR=$($JUMPER goto "${target}" | tr -d '"')
    
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
