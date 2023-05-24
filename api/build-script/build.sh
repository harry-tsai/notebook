#!/bin/bash
set -e

usage="$(basename "$0") [-h] [-e env] [-c last_commit] [-t target_commit] -- program to build and publish Wave API docker image

where:
    -h  show this help text
    -e  required, environment name (e.g. k8ssta, k8sprod)
    -c  required, last commit sha1. It's used to generate RELEASE NOTE
    -t  optional, target commit sha1. It's used to generate RELEASE NOTE (default is master)"

########################################################
# Parse arguments
########################################################

# default value
target_commit="master"

while getopts ':he:c:t:' flag
do
  case "${flag}" in
    h) echo "${usage}"
       exit
       ;;
    e) env="${OPTARG}";;
    c) last_commit="${OPTARG}";;
    t) target_commit="${OPTARG}";;
    :) printf "missing argument for -%s\n" "${OPTARG}" >&2
       echo "${usage}" >&2
       exit 1
       ;;
   \?) printf "illegal option: -%s\n" "${OPTARG}" >&2
       echo "${usage}" >&2
       exit 1
       ;;
  esac
done

if [ -z "${env}" ] || [ -z "${last_commit}" ] || [ -z "${target_commit}" ]; then
  echo "missing required arguments." >&2
  echo "${usage}" >&2
  exit 1
fi

########################################################
# Pull target commit
########################################################

cd "${GOPATH}"/src/github.com/17media/api
git checkout master
git fetch --all
git pull origin master

last_commit_ref=$(git rev-parse ${last_commit})
target_commit_ref=$(git rev-parse ${target_commit})

git checkout ${target_commit_ref}

########################################################
# Print basic information
########################################################

echo "----------- BASIC INFO BELOW -----------"
echo "env: [${env}]"
echo "last_commit: ${last_commit} (sha1: ${last_commit_ref})"
echo "target_commit: ${target_commit} (sha1: ${target_commit_ref})"
echo "----------------------------------------"

########################################################
# Build and Publish images
########################################################

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

deploy_env="STAG"

if [ ${env} == "k8sprod" ]; then
  deploy_env="PROD"
fi

release_commits=$(git log --name-only --oneline "${last_commit_ref}".."${target_commit_ref}" | grep "Wave")
release_note=$(cat <<-END
Wave backend, :slack: :robot_face:  \`${deploy_env}\` with \`${target_commit_ref}\` cc @wave-engineers
\`\`\`
${release_commits}
\`\`\`
END
)

echo "---------- RELEASE NOTE BELOW ----------"
echo "${release_note}"
echo "-----------------------------------------"
