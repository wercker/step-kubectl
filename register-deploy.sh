#!/bin/bash

LOG=$1

if [[ ! -f $LOG ]]; then
 fail "Should pass kubectl log file" 
fi

function normalize {
  TEXT=$1
  NO_SPACES=${TEXT// /\\ }
  NO_COMMAS=${NO_SPACES//,/\\,}
  NO_EQUALS=${NO_COMMAS//=/\\=}
  echo "$NO_EQUALS"
}

AUTHOR_EMAIL=$(normalize "$(git --no-pager log -1 --format="%aE")")
AUTHOR_NAME=$(normalize "$(git --no-pager log -1 --format="%aN")")
COMMIT_SUBJECT=$(normalize "$(git --no-pager log -1 --format="%s")")
REVISION=$(normalize "$(git --no-pager log -1 --format="%H")")

TS=$(date +%s)

RGEX="^deployment \"(.*)\" configured$"

while IFS= read -r line
do
  if [[ $line =~ $RGEX ]]
  then
    APP="${BASH_REMATCH[1]}"
    curl -s -X POST "http://$WERCKER_KUBECTL_INFLUXDB_HOST/write?db=$WERCKER_KUBECTL_INFLUXDB_DB&u=$WERCKER_KUBECTL_INFLUXDB_USER&p=$WERCKER_KUBECTL_INFLUXDB_PASSWORD&precision=s" --data-binary "deploy,app=$APP,revision=$REVISION,author_name=$AUTHOR_NAME,author_email=$AUTHOR_EMAIL,msg=$COMMIT_SUBJECT value=1.0 $TS"
  fi 
done < "$LOG"
