#!/usr/bin/env bash

URBIT_VERSION=urbit-v0.10.8-linux64
FAKEZOD_TAR=fakezod-init.tar.gz
LOGFILE=fakeship_output.log


#cd test_environment || exit

function downloadUrbitRuntime() {
  echo "Downloading Urbit Runtime"
  curl -O https://bootstrap.urbit.org/$URBIT_VERSION.tgz
  tar xzf $URBIT_VERSION.tgz
}


# MARK - live ship management
function start_ship() {
  screen -d -m -S fakeship -L -Logfile "$LOGFILE" ./$URBIT_VERSION/urbit zod
}

function send2ship() {
  # read the manpage for the input format that screen expects
  screen -S fakeship -p 0 -X stuff "$1"
}

function getLastNLines() {
  # shellcheck disable=SC2005
  echo "$(tail -n"$1" fakeship_output.log)"
}

function wait4boot() {
  until [[ "$(tail -n1 fakeship_output.log)" =~ "~zod:dojo>" ]]; do
    echo "Waiting for zod to boot: "
    getLastNLines 2
    sleep 10s
  done
}

function killShip() {
  screen -S fakeship -X quit 2> /dev/null # ok if it doesn't exist
}

# MARK - ship creation/deletion + boot
function make_fakezod() {
  rm -rf ./zod  # remove if existing fakezod
  echo "Creating fakezod"
  screen -d -m -S fakeship -L -Logfile "$LOGFILE" ./$URBIT_VERSION/urbit -F zod # https://stackoverflow.com/a/15026227
  wait4boot
  echo "Fakezod created"
  send2ship "^D"
  sleep 5s
}

function boot_fakezod() {
  start_ship
  wait4boot
  echo "Booted fakezod"
}

function tar_fakezod_state() {
  echo "Saving pristine fakezod state"
  if [ -d ./zod ]; then
#    rm ./zod/.urb/.http.ports
#    rm ./zod/.urb/.vere.lock
    tar cvzf $FAKEZOD_TAR zod
  else
    echo "Could not save ./zod. Does not exist"
  fi
}

function untar_fakezod_state() {
  echo "Unzipping existing fakezod"
  tar xvf ./$FAKEZOD_TAR
}


function cleanup() {
  killShip
  mkdir -p ./old_logs
  mv "$LOGFILE" "./old_logs/{$LOGFILE}_$(date -Iminutes).old.log"
  rm -rf ./zod >> /dev/null 2>&1
  rm -f $URBIT_VERSION.tgz
}

# assuming eyre will be live on 8080 b/c port 80 is not available by default

# references
# inspired by https://github.com/asssaf/urbit-fakezod-docker/
# https://urbit.org/using/install/
# https://raymii.org/s/snippets/Sending_commands_or_input_to_a_screen_session.html
# https://urbit.org/using/operations/using-your-ship/#chat-management
