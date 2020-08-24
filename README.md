![](https://github.com/forallsecure/vulnerabilitieslab/workflows/Published%20on%20Dockerhub/badge.svg)

<p align="center">
 <img src="https://github.com/forallsecure/vulnerabilitieslab/blob/master/_images/mayhem.png">
</p>

# ForAllSecure Vulnerability Labs

We open source our vulnerabilities after our responsible disclosure
period has terminated. You will find:

 * A reproducible environment for building the vulnerable code inside
   docker.
 * Proof of concept artifacts that show how to trigger the discovered
   vulnerability.
 * (Optional) If you are a [ForAllSecure](https://forallsecure.com) Mayhem subscriber, you can
   run all of these locally.

We will be adding to this as find more bugs! Currently we have:

 * [JQ Use-After-Free](https://github.com/ForAllSecure/VulnerabilitiesLab/tree/master/jq-defect-2020) -
   read more [here](https://blog.forallsecure.com/learning-about-structure-aware-fuzzing-and-finding-json-bugs-to-boot)
 * [GNU libm CVE-2020-10029](https://github.com/ForAllSecure/VulnerabilitiesLab/tree/master/libm-cve-2020-10029) - read more [here](https://blog.forallsecure.com/cve-2020-10029-buffer-overflow-in-gnu-libc-trigonometry-functions)
 * [Cereal CVE 2020-11104 & 2020-11105](https://github.com/ForAllSecure/VulnerabilitiesLab/tree/master/cereal-cve-2020-11104-11105) - read more [here](https://blog.forallsecure.com/uncovering-memory-defects-in-cereal)
 * [Oniguruma Regex CVEs 2019-13224 & 2019-13225](https://github.com/ForAllSecure/VulnerabilitiesLab/tree/master/oniguruma-cve-2019-13224-13225)
 * [STB Vorbis CVE-2019-132xx](https://github.com/ForAllSecure/VulnerabilitiesLab/tree/master/stb-cve-2019-132xx) - read more [here](https://blog.forallsecure.com/analyzing-matio-and-stb_vorbis-libraries-with-mayhem)
 * [MATIO CVE 2019-13107](https://github.com/ForAllSecure/VulnerabilitiesLab/tree/master/matio-cve-2019-13107) - read more [here](https://blog.forallsecure.com/analyzing-matio-and-stb_vorbis-libraries-with-mayhem)
 * [Das U-Boot CVE 2019-13103 to 2019-13106](https://github.com/ForAllSecure/VulnerabilitiesLab/tree/master/uboot-cve-2019-13103-13106) - read more [here](https://blog.forallsecure.com/forallsecure-uncovers-critical-vulnerabilities-in-das-u-boot)
 * [Netflix Dial CVE 2019-10028](https://github.com/ForAllSecure/VulnerabilitiesLab/tree/master/netflix-cve-2019-10028) - read more [here](https://blog.forallsecure.com/forallsecure-uncovers-vulnerability-in-netflix-dial-software)
 * [objdump CVEs 2017-124xx](https://github.com/ForAllSecure/VulnerabilitiesLab/tree/master/objdump-cve-2017-124xx) - read more [here](https://blog.forallsecure.com/applying-cyber-grand-challenge-technology-to-real-software)
 * [sthttpd CVE 2017-10671](https://github.com/ForAllSecure/VulnerabilitiesLab/tree/master/sthttpd-cve-2017-10671)
 * [OpenSSL CVE 2014-0160 - Heartbleed](https://github.com/ForAllSecure/VulnerabilitiesLab/tree/master/openssl-cve-2014-0160)
   This is a template for how this directory should look; this
   vulnerability was originally found by Google Security [reference](https://heartbleed.com/).

Please report any issues on the GitHub issue tracker. This is not an
official ForAllSecure product.

## Running from Dockerhub

All vulnerabilities are in pare-built images on our [ForAllSecure
Dockerhub account](https://hub.docker.com/orgs/forallsecure). The
image name is the same as the directory name, prefixed with
"forallsecure".  For example, to run openssl-cve-2014-0160:
```bash
docker run forallsecure/openssl-cve-2014-0160
```

## Mayhem Subscribers

Mayhem subscribers can run all examples within their Mayhem
instance. The `mayhemit.sh` utility script helps with migration.


If you have access to dockerhub.com from your network:
```bash
./mayhemit.sh run
```

If you do not have access to dockerhub.com from your network, you will
need to migrate the docker images to your local Mayhem docker
repository, and rewrite the `Mayhemfile` to point to that registry.
You can do this by running:
```bash
```

To start Mayhem fuzzing, you can use `mayhem run`, or use this script
as follows:

```bash
mayhem run .
```


## Building Locally

You can build and run the image locally. For example, if you are a
researcher you can build the docker image to better understand the
vulnerability.

To build:
```bash
./mayhemit.sh --build <directory>  # A single CVE
./mayhemit.sh --build --all        # Every CVE in this repository
```

Two notes:
  *  You may need Mayhem to fuzz some targets. Mayhem supports
  binary-only fuzzing, network inputs (TCP & UDP), and many other
  features.  Some targets, however, are libfuzzer or AFL.  These you
  can fuzz yourself with the standard AFL or libfuzzer tool.

  * A single docker image includes multiple CVEs when they are all
    based on the same source code build.

If you are wondering what Mayhem runs, look in
`<dir>/mayhem/<name>/Mayhemfile`. A `Mayhemfile` is a yaml file, and
Mayhem fuzzing executes the `cmd` as given.

You always can run the vulnerable program/target locally. Run the
docker image, and look at the associated `cmd`. E.g., for heartbleed,
do:
```
host$ docker run -ti openssl-cve-2014-0160 bash
docker$ /build/handshake-fuzzer
```

## Migrating to a closed network or your own Mayhem docker registry

These directions also apply to any Mayhem subscriber who does not wish
to run the images from  [dockerhub](https://docker.com) (e.g., a
closed network).

Migration steps:

  1. On a host *with* access to dockerhub, run:
     ```bash
     # Build all the images, rewriting the tag with your registry name.
     ./mayhemit.sh --all --save
     ```
     This will build all images, and save the docker images as tgz files.
  2. Tar up this entire directory *with* the previously saved docker
     images from the previous step. For example:
     ```bash
     cd .. && tar zcf vulnlabs.tgz ./vulnlabs
     ```
  3. Copy over the resulting tar file (e.g., `vulnlabs.tgz`) to your
     a host on the *closed* network. You must have docker installed on
     this machine as well, but no internet access is required.
  4. Untar the tar file on the closed network host:
     ```bash
     tar zxf vulnlabs.tgz
     ```
  4. Rewrite all the `Mayhemfile` files to point to your local docker
     registry, load up the images (the image is tagged with
     `baseimage` from the `Mayhemfile`), and push to your registry. It
     is *important* that you give the `--rewrite` flag first, as
     `--load` uses the registry `baseimage` directive in the
     `Mayhemfile` to determine the proper place to load the image:
     ```bash
     ./mayhemit.sh --all --rewrite \"your-registry:your-port/openssl-cve-2014-0160\" --load
     ```

     Replace `openssl-cve-2014-0160` with the folder of the project you are
     analyzing.
  5. Test out a run, e.g.,:
     ```bash
     ./mayhemit.sh --run ./openssl-cve-2014-0160
     ```
