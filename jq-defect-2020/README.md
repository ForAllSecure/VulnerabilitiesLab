# jq Use-After-Free

[JQ](https://github.com/stedolan/jq) is a command line utility and popular C
library for parsing and manipulating JSON. A use-after-free with potential for
memory corruption was discovered via structure-aware fuzzing by Harrison Green
(@hgarrereyn) during his internship with ForAllSecure, and has since been fixed.

You can read more about this bug and the techniques used to find it on our
[blog](https://blog.forallsecure.com/learning-about-structure-aware-fuzzing-and-finding-json-bugs-to-boot).

## Build

You can build or pull the tag `forallsecure/jq-defect-2020` as below:

```bash
docker pull -t forallsecure/jq-defect-2020 .
```

## Running

Run using the Dockerfile-defined entrypoint:

```bash
docker run --rm -it forallsecure/jq-defect-2020 .
```

The time to find the crash is typically under a minute, though it can vary by
several minutes due to the large potential state space to explore. It should
be found within 10 minutes when run with the container entrypoint on a single
core.

## Defect Found: Use-After-Free

The `poc/` directory contains a test casewhich triggers a heap use-after-free
as detected by ASAN. This bug was reported to the maintainers of jq by Harrison
Green on 14 Feb 2020, and is
[now fixed](https://github.com/stedolan/jq/commit/9163e09605383a88f6e953d6cb5cc2aebe18c84f).
This repository pulls the commit used to find the bug originally. The
original code containing the defect (builtin.c:325-328) is below:

```c++
    jv res = str;

    for (n = jv_number_value(num) - 1; n > 0; n--)
      res = jv_string_append_buf(res, jv_string_value(str), alen);
```

The issue is that `res` is originally a shallow copy of `str`, but
`jv_string_append_buf` can realloc the backing buffer for `res`, leaving a
stale buffer pointer in `str`. Subsequent calls to `jv_string_append_buf`
result in a use-after-free situation on `jv_string_value(str)`, and can lead
to leaking of heap data or potentially a write primitive.

## Additional Notes

The jq library operates in three main stages:

1. `Parse` the input JSON
2. `Compile` the input filter into an internal bytecode representation
3. `Execute` the bytecode and pull out results

In order to find bugs in the more interesting stage of execution, we need to
provide valid JSON and valid jq filters, so we model the search space of
valid inputs with a grammar. To accomplish this we used
[libprotobuf-mutator](https://github.com/google/libprotobuf-mutator) to
specify and mutate both the JSON input and jq filters as protobuf messages.

### Harness Source Overview

This repo contains two protobuf definitions, `json.proto` and `jq.proto` which
define a protobuf message structure for JSON and jq filters. These are stripped
down for the sake of being an easy-to-read example, where each protobuf has its
own writer file that exposes a *_to_string() method that walks the message like
a tree and builds up a string.

Also included are directories to show a subset of the primary harness, which
use libprotobuf-mutator to generate JSON and how to pass those strings to jq's
main JSON parsing function.
