# build-script

## How to use

```
$ ./build.sh -h
build.sh [-h] [-e env] [-c last_commit] [-t target_commit] -- program to build and publish Wave API docker image

where:
    -h  show this help text
    -e  required, environment name (e.g. k8ssta, k8sprod)
    -c  required, last commit sha1. It's used to generate RELEASE NOTE
    -t  optional, target commit sha1. It's used to generate RELEASE NOTE (default is master)
```

### Example

```
$ ./build.sh -e k8ssta -c 4e6f4cde23 -t b84a505030
```