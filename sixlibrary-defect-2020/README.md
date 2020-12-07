# six-library Defect 2020

Reproducer for six-library Defect 2020. This repository contains the files necessary to find several bugs in the National Geospatial-Intelligence Agency's six-library. Among these bugs is a one that allows arbitrary control of program execution (program counter) resulting from an uninitialized variable error. As with all ForAllSecure VulnerabiltiesLab's publicly disclosed bugs, proper responsible disclosure procedures were followed (see below).

Additional information about this bug can be found on the ForAllSecure blog [here](TODO).

## Responsible disclosure timeline

- June 24 2020: Bug is discovered by fuzzing in Mayhem
- June 26 2020: Root cause of bug diagnosed
- June 29 2020: First reachout attempt made to contact developers
- July 9 2020: Contact made with relevant developers and bug/fix disclosed
- July 22 2020: Developers [commit fix](https://github.com/mdaus/nitro/commit/22716b796a968cdfcf0f681577965175942f81a6) for the bug to repository

## To build

Assuming you just want to build the docker image, run:

```bash
docker build -t forallsecure/sixlibrary-defect-2020 .
```

## Get from Dockerhub

If you don't want to build locally, you can pull a pre-built image
directly from dockerhub:

```bash
docker pull forallsecure/sixlibrary-defect-2020
```

## Run under Mayhem

Change to the `sixlibrary-defect-2020` folder and run:

```bash
mayhem run mayhem/test-extract-xml
```

and watch Mayhem replicate the bugs! These bugs take some time (a couple hours) to find but be patient as a wide variety are exposed over time!

## POC

We have included a proof of concept output under the `poc`
directory.
