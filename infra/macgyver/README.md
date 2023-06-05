# macgyver
## Preparation

1. Install macgyver
```sh
$ go install github.com/17media/macgyver
```
2. Install [gcloud CLI](https://cloud.google.com/sdk/docs/install)

## How to use
### Helper
```sh
./tool.sh -h
tool.sh [-h] [-e env] [-a action] [-u user_account] [-f file] -- program to encrypt/decrypt text by macgyver

where:
    -h  show this help text
    -e  required, environment name (e.g. k8ssta, k8sprod)
    -a  required, action (e.g. encrypt, decrypt)
    -u  required, gcloud user's account, it would be used to login and call kms encrypt / decrypt. Please ensure the user has been granted kms permissions.
    -f  required, the file path contains flags line by line.
```

### Encrypt
```sh
$ cat ./data/k8ssta.txt
-db_user=foo
-db_password=bar
```

```sh
$ ./tool.sh -e k8ssta -a encrypt -u harrytsai@17.media -f ./data/k8ssta.txt
Updated property [core/account].
Updated property [core/project].
Updated property [compute/zone].
Fetching cluster endpoint and auth data.
kubeconfig entry generated for wave-api.
============= RESULT =============
Input file: ./data/k8ssta.txt
Output file: ./data/k8ssta.txt.encrypt
```
```sh
$ cat ./data/k8ssta.txt.encrypt
-db_user=<SECRET_TAG>CiUAeV4WaVZhGBZzNjI0TGex4Bt8U9jfceMciz+FfyKxNyeIRBUtEiwA7uJB2vMTzIzQmPFKD4+IXe9XmwVM348j3IrzZqiyCAPDVjQ2R59T+5IY7Q==</SECRET_TAG>
-db_password=<SECRET_TAG>CiUAeV4WaW+zdZbAsN2RW6+n63TCdbB9AtBBTx4jspvAhKe7HrqgEisA7uJB2vvLrbs1X/rwIB0qfmL4+yhGhc7tBRaTmVm1pTQrKRetuwTYUBWE</SECRET_TAG>
```

### Decrypt
```sh
$ cat ./data/k8ssta.txt.encrypt
-db_user=<SECRET_TAG>CiUAeV4WaVZhGBZzNjI0TGex4Bt8U9jfceMciz+FfyKxNyeIRBUtEiwA7uJB2vMTzIzQmPFKD4+IXe9XmwVM348j3IrzZqiyCAPDVjQ2R59T+5IY7Q==</SECRET_TAG>
-db_password=<SECRET_TAG>CiUAeV4WaW+zdZbAsN2RW6+n63TCdbB9AtBBTx4jspvAhKe7HrqgEisA7uJB2vvLrbs1X/rwIB0qfmL4+yhGhc7tBRaTmVm1pTQrKRetuwTYUBWE</SECRET_TAG>
```

```sh
$ ./tool.sh -e k8ssta -a decrypt -u harrytsai@17.media -f ./data/k8ssta.txt.encrypt
Updated property [core/account].
Updated property [core/project].
Updated property [compute/zone].
Fetching cluster endpoint and auth data.
kubeconfig entry generated for wave-api.
============= RESULT =============
Input file: ./data/k8ssta.txt.encrypt
Output file: ./data/k8ssta.txt.encrypt.decrypt
```

```sh
$ cat ./data/k8ssta.txt.encrypt.decrypt
-db_user=foo
-db_password=bar
```