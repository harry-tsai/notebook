# build-script

## How to use

```
$ ./build.sh -h
build.sh [-h] [-e env] [-c last_commit] [-t target_commit] -- program to build and publish Wave API docker image

where:
    -h  show this help text
    -e  required, environment name (e.g. k8ssta, k8sprod)
    -c  required, last release commit sha1 (ref to slack channel: `wave-release`). It's used to generate RELEASE NOTE.
    -t  optional (default is `master`), target release commit sha1. It's used to generate RELEASE NOTE.
```

### Example

```
$ ./build.sh -e k8ssta -c 4e6f4cde23 -t b84a505030
```
