#!/bin/bash

if [ -z "${JUMPER_HOME}" ]; then
  JUMPER_HOME=$HOME/.jumper
fi
echo "JUMPER_HOME: ${JUMPER_HOME}"
mkdir -p ${JUMPER_HOME}

cp jumper ${JUMPER_HOME}/jumper
cp jumper.sh ${JUMPER_HOME}/jumper.sh

if [[ -z "${JUMPER_WORKSPACE}" ]]; then
  JUMPER_WORKSPACE="${HOME}"
fi
echo "JUMPER_WORKSPACE: ${JUMPER_WORKSPACE}"

JUMPER_DEPTH=4
echo "JUMPER_DEPTH: ${JUMPER_DEPTH}"

JUMPER="${JUMPER_HOME}/jumper"
JUMPERRC="${JUMPER_HOME}/jumperrc"

echo "export JUMPER_HOME=${JUMPER_HOME}
export JUMPER_WORKSPACE=${JUMPER_WORKSPACE}
export JUMPER_DEPTH=${JUMPER_DEPTH}
alias j='. ${JUMPER_HOME}/jumper.sh'
alias jassemble='${JUMPER} assemble'
alias jalias='${JUMPER} alias'
" > "${JUMPERRC}"

if [[ -f "${HOME}/.zshrc" ]]; then
  BASHRC="${HOME}/.zshrc"
elif [ -f "${HOME}/.bashrc" ]; then
  BASHRC="${HOME}/.bashrc"
elif [ -f "${HOME}/.bash_profile" ]; then
  BASHRC="${HOME}/.bash_profile"
fi

echo "Shell config: ${BASHRC}"
if [[ -n "${BASHRC}" ]]; then
  source "${JUMPERRC}"
  SOURCE_JUMPERRC="source ${JUMPERRC}"
  if ! grep -q "${SOURCE_JUMPERRC}" "${BASHRC}"; then
    echo "${SOURCE_JUMPERRC}" >> "${BASHRC}"
  fi
fi
