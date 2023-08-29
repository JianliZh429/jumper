#!/bin/bash

if [ -z "${JUMPER_HOME}" ]; then
  JUMPER_HOME=$HOME/.jumper
fi
echo "JUMPER_HOME: ${JUMPER_HOME}"

if [[ -z "${JUMPER_WORKSPACE}" ]]; then
  JUMPER_WORKSPACE="${HOME}"
fi
echo "JUMPER_WORKSPACE: ${JUMPER_WORKSPACE}"

JUMPER_LAYER=4
echo "JUMPER_LAYER: ${JUMPER_LAYER}"

JUMPER="${JUMPER_HOME}/jumper"

echo "export JUMPER_HOME=${JUMPER_HOME}
export JUMPER_WORKSPACE=${JUMPER_WORKSPACE}
export JUMPER_LAYER=${JUMPER_LAYER}
alias j='. ${JUMPER_HOME}/jumper.sh'
alias jassemble='${JUMPER} assemble'
alias jalias='${JUMPER} alias'
" > "./jumperrc"

JUMPERRC="${JUMPER_HOME}/jumperrc"
if [[ -f "${HOME}/.zshrc" ]]; then
  BASHRC="${HOME}/.zshrc"
elif [ -f "${HOME}/.bashrc" ]; then
  BASHRC="${HOME}/.bashrc"
elif [ -f "${HOME}/.bash_profile" ]; then
  BASHRC="${HOME}/.bash_profile"
fi

if [[ -n "${BASHRC}" ]]; then
  source ./workonrc
  SOURCE_JUMPERRC="source ${JUMPERRC}"
  if ! grep -q "${SOURCE_JUMPERRC}" "${BASHRC}"; then
    echo "${SOURCE_JUMPERRC}" >> "${BASHRC}"
  fi
fi