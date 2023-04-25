#!/bin/bash
########################################################
# How to use
# ./build.sh -e k8sstg -c {last_commit}
########################################################

set -e

########################################################
# Parse arguments
########################################################

last_commit_file=".tmp/last_commit"

while getopts e:f:c: flag
do
  case "${flag}" in
    e) env="${OPTARG}";;
    f) last_commit_file="${OPTARG}";;
    c) last_commit="${OPTARG}";;
    *) exit 1;;
  esac
done

if [ "${last_commit}" == "" ]; then
  if [ ! -f "${last_commit_file}" ]; then
    echo "${last_commit_file} is not exist, specify -f [last_commit_file]"
    exit 1;
  fi
  last_commit=$(cat "${last_commit_file}")
fi

########################################################
# Build and Publish images
########################################################

cd "${GOPATH}"/src/github.com/17media/api
git pull origin master
go mod tidy

cd "${GOPATH}"/src/github.com/17media/api/infra/deploy/docker

./entry.py -s wave -e "${env}" build --disable_swagger publish
./entry.py -s wave-slackbot -e "${env}" build --disable_swagger publish
./entry.py -s wave-worker -e "${env}" build --disable_swagger publish

./entry.py -s wave-migration -e "${env}" build --disable_swagger publish
./entry.py -s wave-pubsub-setup -e "${env}" build --disable_swagger publish
./entry.py -s perimeterx-revprox -e "${env}" build publish

########################################################
# Generate Release Note
########################################################

current_commit=$(git rev-parse HEAD)
release_commits=$(git log --name-only --oneline "${last_commit}".."${current_commit}" | grep "Wave")
echo "env: [${env}]"
echo "last_commit: [${last_commit}]"
echo "curr_commit: [${current_commit}]"
echo "---------- RELEASE NOTE BELOW ----------"

release_note=$(cat <<-END
Wave backend, :slack: :機器人:  \`STAG\` with \`${current_commit}\` cc @wave-engineers
\`\`\`
${release_commits}
\`\`\`
END
)

echo "${release_note}"
