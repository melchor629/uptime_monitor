#!/bin/bash

#https://stackoverflow.com/a/16349776/1938013
cd "${0%/*}"
DIR="$PWD"

ERROR="\033[31m"
TEXT="\033[32m"
RESET="\033[0m"

function error() {
  echo -e ${ERROR}$@${RESET}
  exit 1
}

function doing() {
  echo -e "  > ${TEXT}$@${RESET}"
}

function image_name() {
  name=""
  if [[ ! -z "$DOCKER_USER" ]]; then
    name="$DOCKER_USER/$1"
  else
    name="$1"
  fi

  if [[ ! -z "$TAG" ]]; then
    name="$name:$TAG"
  fi

  printf $name
}

function dockerbuild() {
  if [[ ! -d "$DIR/$1" ]]; then
    error "\`$DIR/$1' is not a directory :("
  fi

  cd "$DIR/$1"
  args=""

  if [[ -z "$NO_PULL" ]]; then
    args="$args --pull"
  fi

  args="$args -t $(image_name $1)"

  if [[ ! -z "$ARCH" ]]; then
    args="$args --build-arg ARCH=$ARCH"
  fi

  doing "Building $(image_name $1)"
  docker image build $args . || exit $?
}

function dockerpush() {
  if [[ ! -d "$DIR/$1" ]]; then
    error "\`$DIR/$1' is not a directory :("
  fi

  if [[ -z "$DOCKER_USER" ]]; then
    error "You must provide an user with -u or --user"
  fi

  if ! (docker image ls | grep $(image_name $1) > /dev/null); then
    dockerbuild $1
  fi

  doing "Pushing $(image_name $1)"
  docker image push $(image_name $1) || exit $?
}

function dockerpull() {
  if [[ ! -d "$DIR/$1" ]]; then
    error "\`$DIR/$1' is not a directory :("
  fi

  if [[ -z "$DOCKER_USER" ]]; then
    error "You must provide an user with -u or --user"
  fi

  doing "Pulling $(image_name $1)"
  docker image pull $(image_name $1) || exit $?
}

function dockerrm() {
  if [[ ! -d "$DIR/$1" ]]; then
    error "\`$DIR/$1' is not a directory :("
  fi

  if [[ -z "$DOCKER_USER" ]]; then
    error "You must provide an user with -u or --user"
  fi

  doing "Removing $(image_name $1)"
  docker image rm $(image_name $1)
}

function show_help() {
  cat <<-EOM
USAGE: $0 [build|push|pull|rm] [-t|--tag TAG] [-a|--arch ARCH] [-u|--user HUB_USER] [--no-pull] [--help] dirs...

Actions:
  build              Builds the image(s).
  push               Uploads the image(s) to Docker Hub (requires -u).
  pull               Gets the image(s) from Docker Hub (requires -u).
  rm                 Remove the images from local.

Options:
  -t|--tag TAG       Adds a custom tag for the image (user/name:TAG).
  -a|--arch ARCH     Changes the ARCH of the image (you should have binfmt
                     support enabled, docker for macOS and Windows have it). The
                     names supported must be something like \`arm32v7', that can
                     be found in Docker Hub images from \`library'.
  -u|--user HUB_USER Docker Hub user.
  --no-pull          By default, when building, \`--pull' will be used. With
                     this option, this argument won't be used, i.e. won't pull
                     the base images. Only works when building.
  --help             Shows this help.

Valid dirs:
EOM

  for dir in "$DIR"/*; do
    if [[ -f "$dir/Dockerfile" ]]; then
      echo "  $(printf $dir | sed s\|$DIR/\|\|)"
    fi
  done

  exit 1
}

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--tag)
      TAG="$2"
      shift
      shift
      ;;

    -a|--arch)
      ARCH="$2"
      shift
      shift
      ;;

    -u|--user)
      DOCKER_USER="$2"
      shift
      shift
      ;;

     --no-pull)
       NO_PULL=true
       shift
       ;;

     --help)
       show_help
       ;;

    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

set -- "${POSITIONAL[@]}"



if [[ -z "$1" ]]; then
  echo "${ERROR}You must define an action.${RESET}"
  show_help
fi

case "$1" in
  build )
    shift
    for dir in $@; do
      dockerbuild $dir
    done
    ;;

  push )
    shift
    for dir in $@; do
      dockerpush $dir
    done
    ;;

  pull )
    shift
    for dir in $@; do
      dockerpull $dir
    done
    ;;

  rm )
    shift
    for dir in $@; do
      dockerrm $dir
    done
    ;;

  * )
    echo "${ERROR}Action \`$1' unknown...${RESET}"
    show_help
    ;;

esac
