#!/bin/bash
set -e

PROVIDER=gcp
PROJECT=wave-stag
LOCATION=global
KEYRING=wave-stag
CRYPTOKEY=flags-sym

DECRYPT=decrypt
ENCRYPT=encrypt

MACGYVER=~/go/bin/macgyver

usage="$(basename "$0") [-h] [-e env] [-a action] [-u user_account] [-f file] -- program to encrypt/decrypt text by macgyver

where:
    -h  show this help text
    -e  required, environment name (e.g. k8ssta, k8sprod)
    -a  required, action (e.g. encrypt, decrypt)
    -u  required, gcloud user's account, it would be used to login and call kms encrypt / decrypt. Please ensure the user has been granted kms permissions.
    -f  required, the file path contains flags line by line."

########################################################
# Parse arguments
########################################################

while getopts ':he:a:u:f:' flag; do
  case "${flag}" in
  h)
    echo "${usage}"
    exit
    ;;
  e) env="${OPTARG}" ;;
  a) action="${OPTARG}" ;;
  u) user_account="${OPTARG}" ;;
  f) file="${OPTARG}" ;;
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

if [ -z "${env}" ] || [ -z "${action}" ] || [ -z "${user_account}" ] || [ -z "${file}" ]; then
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

if [ ! -f "${file}" ]; then
  echo "${file} does not exist."
  exit 1
fi

########################################################
# replace variables by $env
########################################################

if [ "${env}" == "k8sprod" ]; then
  PROJECT=wave-ccc3c
  KEYRING=wave-ccc3c
fi

########################################################
# login GCP
########################################################

function gcloud_env_setting {
  if [ "$#" -ne 5 ]; then
    echo "illeagel"
    exit -1
  fi
  projectID=$1
  region=$2
  zone=$3
  clusterName=$4
  account=$5
  gcloud config set account $account
  gcloud config set project $projectID
  gcloud config set compute/zone $zone
  gcloud beta container clusters get-credentials $clusterName --region asia-east1 --project $projectID
}

gcloud_env_setting "${PROJECT}" "asia-east1" "asia-east1-a" "wave-api" "${user_account}"

########################################################
# run
########################################################
flags="$(cat ${file})"

function decrypt() {
  plain_text=$(${MACGYVER} decrypt \
    --cryptoProvider=${PROVIDER} \
    --GCPprojectID=${PROJECT} \
    --GCPlocationID=${LOCATION} \
    --GCPkeyRingID=${KEYRING} \
    --GCPcryptoKeyID=${CRYPTOKEY} \
    --flags="$1")
  echo $plain_text
}

function encrypt() {
  cipher_text=$(${MACGYVER} encrypt \
    --cryptoProvider="${PROVIDER}" \
    --GCPprojectID="${PROJECT}" \
    --GCPlocationID="${LOCATION}" \
    --GCPkeyRingID="${KEYRING}" \
    --GCPcryptoKeyID="${CRYPTOKEY}" \
    --flags="$1")
  echo $cipher_text
}

function run() {
  output_file=""
  res=""
  # encrypt
  if [ "${action}" == "${ENCRYPT}" ]; then
    while read -r line; do
      if [ -z "${line}" ]; then
        continue
      fi
      res="${res}$(encrypt ${line})\n"
    done < <(printf "%s\n" "${flags}")
    output_file="${file}.encrypt"

  # decrypt
  elif [ "${action}" == "${DECRYPT}" ]; then
    while read -r line; do
      if [ -z "${line}" ]; then
        continue
      fi
      res="${res}$(decrypt ${line})\n"
    done < <(printf "%s\n" "${flags}")
    output_file="${file}.decrypt"
  fi

  # write to output file
  echo -e ${res} >${output_file}
  echo "============= RESULT ============="
  echo "Input file: ${file}"
  echo "Output file: ${output_file}"
}

run
