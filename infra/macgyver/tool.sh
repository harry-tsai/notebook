#!/bin/bash
set -e

PROVIDER=gcp
PROJECT=wave-stag
LOCATION=global
KEYRING=wave-stag
CRYPTOKEY=flags-sym

DECRYPT=decrypt
ENCRYPT=encrypt

FLAGS="-twitter_ro_secret=<SECRET_TAG>CiUAeV4Wacan4MAAeJ5F4QzJtkia7e5dpjFMXMnivvJWNRmEJmjLEloAoeWDLdvwMaxkMzH8wAp9H07IGElaFdFBy/LNe/FRtQuglY1Y2fi3SJkLznTvpV7WXdm/2hk7TqDvYr6sfR9RLyOQ7koPsQiSgAQ8mG1BKzbjt231DqIWmuI=</SECRET_TAG>"

usage="$(basename "$0") [-h] [-e env] [-a action] -- program to encrypt/decrypt text by macgyver

where:
    -h  show this help text
    -e  required, environment name (e.g. k8ssta, k8sprod)
    -a  required, action (e.g. encrypt, decrypt)"

########################################################
# Parse arguments
########################################################

while getopts ':he:a:' flag; do
  case "${flag}" in
  h)
    echo "${usage}"
    exit
    ;;
  e) env="${OPTARG}" ;;
  a) action="${OPTARG}" ;;
  :)
    printf "missing argument for -%s\n" "${OPTARG}" >&2
    echo "${usage}" >&2
    exit 1
    ;;
  \?)
    printf "illegal option: -%s\n" "${OPTARG}" >&2
    echo "${usage}" >&2
    exit 1
    ;;
  esac
done

########################################################
# validate arguments
########################################################

if [ -z "${env}" ] || [ -z "${action}" ]; then
  echo "missing required arguments." >&2
  echo "${usage}" >&2
  exit 1
fi

if [ "${env}" != "k8ssta" ] && [ "${env}" != "k8sprod" ]; then
  echo "-e [env] should be k8ssta or k8sprod"
  exit 1
fi

if [ "${action}" != "${DECRYPT}" ] && [ "${action}" != "${ENCRYPT}" ]; then
  echo "-a [action] should be ${DECRYPT} or ${ENCRYPT}"
  exit 1
fi

########################################################
# replace variables by $env
########################################################

if [ "${env}" == "k8sprod" ]; then
  PROJECT=wave-ccc3c
  KEYRING=wave-ccc3c
fi

echo "=============== [${PROJECT}] ${action} ==============="
echo $FLAGS
echo '=============== OUTPUT BELOW ==============='

function decrypt() {
  plain_text=$(macgyver decrypt \
    --cryptoProvider=${PROVIDER} \
    --GCPprojectID=${PROJECT} \
    --GCPlocationID=${LOCATION} \
    --GCPkeyRingID=${KEYRING} \
    --GCPcryptoKeyID=${CRYPTOKEY} \
    --flags="${FLAGS}")
  echo $plain_text
}

function encrypt() {
  cipher_text=$(macgyver encrypt \
    --cryptoProvider="${PROVIDER}" \
    --GCPprojectID="${PROJECT}" \
    --GCPlocationID="${LOCATION}" \
    --GCPkeyRingID="${KEYRING}" \
    --GCPcryptoKeyID="${CRYPTOKEY}" \
    --flags="${FLAGS}")
  echo $cipher_text
}

if [ "${action}" == "${ENCRYPT}" ]; then
  encrypt
elif [ "${action}" == "${DECRYPT}" ]; then
  decrypt
fi
