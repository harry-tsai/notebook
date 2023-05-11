#!/bin/bash
set -e

########################################################
# How to use
# ./build.sh -e k8sstg -c {last_commit} -t {target_commit}
# -c: required
# -t: optional, default is master
########################################################

########################################################
# Parse arguments
########################################################

while getopts e:f:c:t: flag
do
  case "${flag}" in
    e) env="${OPTARG}";;
    f) last_commit_file="${OPTARG}";;
    c) last_commit="${OPTARG}";;
    t) target_commit="${OPTARG}";;
    *) exit 1;;
  esac
done

if [ "${last_commit}" == "" ]; then
  echo "specify -c [last_commit]"
  exit 1
fi

if [ "${target_commit}" == "" ]; then
  target_commit="master"
fi

########################################################
# Build and Publish images
########################################################

cd "${GOPATH}"/src/github.com/17media/api
git co master
git pull origin master
git co ${target_commit}
go mod tidy
go mod vendor

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

deploy_env="STAG"

if [ ${env} == "k8sprod" ]; then
  deploy_env="PROD"
fi

release_note=$(cat <<-END
Wave backend, :slack: :robot_face:  \`${deploy_env}\` with \`${current_commit}\` cc @wave-engineers
\`\`\`
${release_commits}
\`\`\`
END
)

echo "${release_note}"

