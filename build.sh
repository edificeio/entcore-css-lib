#!/bin/bash

if [ ! -e node_modules ]
then
  mkdir node_modules
fi

if [ -z ${USER_UID:+x} ]
then
  export USER_UID=1000
  export GROUP_GID=1000
fi


clean () {
  rm -rf node_modules
  rm -rf dist
}

init () {
  echo "[init] Generate package.json from package.json.template..."
  NPM_VERSION_SUFFIX=`date +"%Y%m%d%H%M"`
  cp package.json.template package.json
  sed -i "s/%generateVersion%/${NPM_VERSION_SUFFIX}/" package.json

  echo "[init] Install yarn dependencies..."
  docker-compose run --rm -u "$USER_UID:$GROUP_GID" node sh -c "yarn install"
}

build () {
  local extras=$1
  docker-compose run --rm -u "$USER_UID:$GROUP_GID" node sh -c "npm run release:build"
  VERSION=`grep "version="  gradle.properties| sed 's/version=//g'`
  echo "entcore-css-lib=$VERSION `date +'%d/%m/%Y %H:%M:%S'`" >> dist/version.txt
}

watch () {
  docker-compose run --rm -u "$USER_UID:$GROUP_GID" node sh -c "npm run dev:watch"
}

lint () {
  docker-compose run --rm -u "$USER_UID:$GROUP_GID" node sh -c "npm run dev:lint"
}

lint-fix () {
  docker-compose run --rm -u "$USER_UID:$GROUP_GID" node sh -c "npm run dev:lint-fix"
}

publish () {
  LOCAL_BRANCH=`echo $GIT_BRANCH | sed -e "s|origin/||g"`
  docker-compose run --rm -u "$USER_UID:$GROUP_GID" node sh -c "npm publish --tag $LOCAL_BRANCH"
}

for param in "$@"
do
  case $param in
    clean)
      clean
      ;;
    init)
      init
      ;;
    build)
      build
      ;;
    watch)
      watch
      ;;
    lint)
      lint
      ;;
    lint-fix)
      lint-fix
      ;;
    publish)
      publish
      ;;
    *)
      echo "Invalid argument : $param"
  esac
  if [ ! $? -eq 0 ]; then
    exit 1
  fi
done