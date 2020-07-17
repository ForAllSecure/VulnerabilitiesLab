#!/usr/bin/env bash

#   Copyright (C) 2020 ForAllSecure, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

##########################################################################
# mayhemit.sh
#
# SYNOPSIS: Utility for managing docker build/push/etc in this repository.
#
##########################################################################

# Bash safeties: exit on error, no unset variables, pipelines can't hide errors
set -o errexit
set -o nounset
set -o pipefail
#set -x

# Check for required tools
command -v jq >/dev/null 2>&1 || { \
 echo >&2 "[ERROR] jq not on PATH. Aborting."
 echo >&2 "[ERROR] Refer to: https://stedolan.github.io/jq/download/"
 exit 1
}

command -v mayhem >/dev/null 2>&1 || { \
 echo >&2 "[ERROR] mayhem not on PATH. Aborting."
 echo >&2 "[ERROR] Refer to the installation page of your Mayhem Instance for download instructions."
 exit 1
}

# Default flags and arguments
FLAG_BUILD=0
FLAG_REWRITE_BASEIMAGE=0
ARG_REWRITE_BASEIMAGE=""
FLAG_REWRITE_TARGET=0
ARG_REWRITE_TARGET=""
FLAG_PUSH=0
FLAG_ALL=0
FLAG_DURATION=0
ARG_DURATION=30
FLAG_RUN=0
FLAG_COPY_POC=0
ARG_MIN_CRASHES=0
FLAG_SAVE=0
FLAG_LOAD=0
FLAG_STOP=0
ARG_PROJECTS=()
FLAG_SANITY=0
FLAG_CLEAN=0
FLAG_PULL=0


# Log helper function
cli_log() {
    script_name=${0##*/}
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "== $script_name $timestamp $1"
}

help_cmd() {
    cli_name=${0##*/}
    echo "
$cli_name <options>*  <dir>+
Utility for managing ForAllSecure fuzzing examples.

Options:
  --build          Run docker build specified directories
  --rewrite repo   Rewrite Mayhemfile \"baseimage\" directive to use \"repo\"
  --target suffix  Change the Mayhemfile \"target\" directive to add the specified suffix to the existing \"target\"
  --run            Start a Mayhem run
  --min-crashes c  Specify the expected number of crashes when used with --run. Stops the run when enough crashes found.
  --copy-poc       Copy proof of concept (if one exists) into the corpus folder when used with --run.
  --push           Push image to location(s) specified in \"baseimage\"
  --all            Run on all subdirectories
  --duration t     Specify alternate duration time for \`mayhem run\` command
  --stop           Stop previously launched Mayhem jobs
  --pull           Pull all docker images locally
  --save           Run docker save.
  --load           Run docker load.
  --sanity         Sanity check this repo (for contributors)
  --clean          Clean up lingering files (for contributors)
  --verbose        Set -x bit in bash script to make more verbose
  --help           This screen

Examples:
  \$ $cli_name --build openssl-cve-2014-0160
  \$ $cli_name --push openssl-cve-2014-0160
  \$ $cli_name --build --push --run openssl-cve-2014-0160
  \$ $cli_name --all --build
"
}


# Push our build to whatever is specified in the Mayhemfile(s)
push_cmd() {
    local project=$1

    for d in `ls mayhem/`; do
        local filename="mayhem/$d/Mayhemfile"
        if [ ! -f $filename ]; then
            echo "Fatal: $project/mayhem/$d needs a Mayhemfile!"
            exit 1
        else
            image=$(grep "^baseimage:" $filename | sed "s|baseimage:[ ]*||g")
            cli_log "Pushing $project as $image"
            # Push the repo. This utilizes the tag from the Mayhemfile.
            #docker tag $project $image
            docker push $image

            # clean up images we tagged
            #docker rmi $image
        fi
    done
}


sanity_cmd() {
    local project=$1

    cli_log "checking $project"
    # Make sure there is a Dockerfile
    if [ ! -f Dockerfile ]; then
        echo "Fatal: $project needs a Dockerfile!"
        exit 1
    else
        cli_log "  $project/Dockerfile exists."
    fi


    if [ ! -f README.md ]; then
        echo "Fatal: $project needs a README.md!"
    else
        cli_log "  $project/README.md exists."
    fi


    # Make sure there is a mayhem directory
    if [ ! -d mayhem ]; then
        echo "Fatal: $project has no mayhem directory!"
        exit 1
    else
        cli_log "  $project/mayhem directory exists."
    fi

    for d in `ls mayhem/`; do
        if [ ! -f "mayhem/$d/Mayhemfile" ]; then
            echo "Fatal: $project/mayhem/$d needs a Mayhemfile!"
            exit 1
        else
            cli_log "  $project/mayhem/Mayhemfile exists."
        fi
    done

    if [ ! -d "corpus" ]; then
        echo "Warning: $project does not have a corpus. Consider adding some."
    else
        cli_log "  $project/corpus exists."
    fi

    if [ ! -d "poc" ]; then
        echo "Warning: $project does not have poc. Consider adding some."
    else
        cli_log "  $project/poc exists."
    fi

    cli_log "$project ready to go!"
}


# Rewrite where baseimage points to in Mayhemfiles
rewrite_baseimage_cmd() {
    local project=$1

    for mayhem in `ls mayhem/`; do
        pushd mayhem/$mayhem > /dev/null
        sed -i.bak "s|baseimage:.*|baseimage: ${ARG_REWRITE_BASEIMAGE}|g" Mayhemfile
        popd > /dev/null
        cli_log "$project/mayhem/$mayhem/Mayhemfile baseimage now ${ARG_REWRITE_BASEIMAGE}"
        cli_log "  Original Mayhemfile saved as $project/mayhem/$mayhem/Mayhemfile.bak"
    done
}


# Rewrite where baseimage points to in Mayhemfiles
rewrite_target_cmd() {
    local project=$1

    for mayhem in `ls mayhem/`; do
        pushd mayhem/$mayhem > /dev/null
        sed -E -i.bak "s|(target:.*)|\1-${ARG_REWRITE_TARGET}|g" Mayhemfile
        popd > /dev/null
        cli_log "$project/mayhem/$mayhem/Mayhemfile baseimage now ${ARG_REWRITE_TARGET}/$project"
        cli_log "  Original Mayhemfile saved as $project/mayhem/$mayhem/Mayhemfile.bak"
    done
}

run_cmd() {
    local project=$1
    local cli=$(which mayhem) || (echo "mayhem command not found" && exit 1)

    for mayhem in `ls mayhem/`; do
        pushd mayhem/$mayhem > /dev/null

        # Copy poc folder over to corpus if one exists
        if [ $FLAG_COPY_POC -ne 0 ]; then
            mkdir -p corpus || true
            cp poc/* corpus || true
        fi

        if [ $FLAG_DURATION -ne 0 ]; then
            cmd="$cli run --duration $ARG_DURATION ."
        else
            cmd="$cli run ."
        fi

        run_id=$($cmd)
        if [ $? -ne 0 ]; then
            echo "$project failed to start. Aborting."
            exit 1
        fi
        echo $run_id > _run_id
        cli_log "Running $project with run id $run_id"

        #
        # When specifying a minimum number of crashes, the run will be polled
        # periodically until the number of crashes is equal to or greater than
        # the specified amount. If the minimum is not reached within approximately
        # 30 minutes then the script will exit with return code 1.
        #
        # Regardless of the outcome, the run will be stopped if the minimum
        # threshold is reached# or if the time limit is exceeded. This fress
        # up analyze workers to work on other tasks.
        #
        if [ $ARG_MIN_CRASHES -gt 0 ]; then
            #
            # Don't start the the timer below until the run has started, otherwise
            # time spent waiting for a worker will count against the time waiting
            # for finding a crash!
            #
            echo "Waiting for $run_id to start..."
            until [[ $($cli show --format json $run_id | jq -r ".[0].status" | grep -E "running") ]]; do
                printf "."
                sleep 5
            done

            max_sleep=1800 # Sleep for a max of ~30 minutes
            sleep_time=0   # Track how long we have slept for
            echo "Waiting for at least $ARG_MIN_CRASHES crashe(s)..."
            until [[ $($cli show --format json $run_id | jq -r '.[0].crashes') -ge $ARG_MIN_CRASHES ]]; do
                if [ "$sleep_time" -gt "$max_sleep" ]; then
                    echo "Failed to find at least $ARG_MIN_CRASHES in less than 30 minutes. Stopping run..."
                    popd > /dev/null
                    stop_cmd $project
                    exit 1
                fi

                if [[ $($cli show --format json $run_id | jq -r ".[0].status" | grep -E "pending|running") ]]; then
                    printf "."
                    sleep 10
                    sleep_time=$((sleep_time+10))
                else
                    echo "Run $run_id does not appear to be running any longer. Failed to find any crashes."
                    popd > /dev/null
                    exit 1
                fi
            done

            crashes=$($cli show --format json $run_id | jq -r '.[0].crashes')
            echo "$crashes found! Stopping run..."
            popd > /dev/null
            stop_cmd $project
        else
            popd > /dev/null
        fi
    done
}

stop_cmd() {
    local project=$1
    local cli=$(which mayhem) || (echo "mayhem command not found" && exit 1)
    for mayhem in `ls mayhem/`; do
        pushd mayhem/$mayhem > /dev/null
        if [ ! -f _run_id ]; then
            echo "No run pending for $project. Skipping."
            popd > /dev/null
            continue
        fi

        runid=$(cat _run_id)
        $cli stop $runid && rm _run_id
        if [ $? -ne 0 ]; then
            echo "Failed to stop $runid. Aborting."
            return
        fi

        cli_log "$runid stopped."
        popd > /dev/null
    done
}

# Save a local copy of any docker image built as done by pull_cmd
# Note: We assume one docker image per project.
save_cmd() {
    local project=$1
    mayhemfile=$(find . -name Mayhemfile -type f | head -1)
    image=$(grep "baseimage: " $mayhemfile | sed "s|baseimage:[ ]*||g")
    docker pull $image
    docker save ${image} | gzip > ${project}-image.tar.gz
    cli_log "$project image saved as $project-image.tar.gz)"
}

# Load a local copy of any docker image built as done by pull_cmd
# Note: We assume one docker image per project.
load_cmd() {
    local project=$1
    id=$(docker load < ${project}-image.tar.gz)
    name=$(echo $id | sed  "s|^Loaded image: ||g")
    mayhemfile=$(find . -name Mayhemfile -type f | head -1)
    image=$(grep "baseimage: " $mayhemfile | sed "s|baseimage:||g")
    docker tag $name $image
    docker push $image
    cli_log "$project ready (image: $image)"
}


# Pulls docker images as specified in Mayhemfiles. Then tags it/them as though
# we've built locally. Note that this assumes all Mayhemfiles reference the
# *same* docker image.
pull_cmd() {
    local project=$1
    mayhemfile=$(find . -name Mayhemfile -type f | head -1)
    image=$(grep "baseimage: " $mayhemfile | sed "s|baseimage:||g")
    docker pull $image
    docker tag $image $project
}


# Cleans up any files we created, such as saved docker image files
# backup Mayhemfiles (Mayhemfile.bak), and local builds
clean_cmd() {
    local project=$1

    cli_log "Remove $project image (don't worry about warnings)"
    docker rmi -f $project

    if [ -f $project.tgz ]; then
        cli_log "Deleting $project.tgz"
        rm -f $project.tgz
    fi

    for mayhem in `ls mayhem/`; do
        (cd mayhem/$mayhem && if [ -f Mayhemfile.bak ]; then
             mv Mayhemfile.bak Mayhemfile && \
                 cli_log "Restored $project/mayhem/$mayhem/Mayhemfile.bak"
         fi)
    done
}


# Obviously building a project. But we use the name in the Mayhemfile as the tag
build_cmd(){
    local project=$1
    mayhemfile=$(find . -name Mayhemfile | head -1)
    image=$(grep "^baseimage:" $mayhemfile | sed "s|baseimage:||g")
    cli_log "Building $project with docker image $image"
    docker build -t $image .
}


process_project(){
    local dir=$1
    local project=$2

    pushd $dir > /dev/null
    [ $FLAG_SANITY -eq 1 ] && (sanity_cmd $project)
    [ $FLAG_REWRITE_BASEIMAGE -eq 1 ] && (rewrite_baseimage_cmd $project)
    [ $FLAG_REWRITE_TARGET -eq 1 ] && (rewrite_target_cmd $project)
    [ $FLAG_BUILD -eq 1 ] && (build_cmd $project) # rewrite before build
    [ $FLAG_PUSH -eq 1 ] && (push_cmd $project)   # rewrite before push
    [ $FLAG_RUN -eq 1 ] && (run_cmd $project)     # run after build & push
    [ $FLAG_STOP -eq 1 ] && (stop_cmd $project)   # stop a run after starting
    [ $FLAG_PULL -eq 1 ] && (pull_cmd $project)
    [ $FLAG_SAVE -eq 1 ] && (save_cmd $project)   # save after pull
    [ $FLAG_LOAD -eq 1 ] && (load_cmd $project)   # load after save
    [ $FLAG_CLEAN -eq 1 ] && (clean_cmd $project)


    popd > /dev/null
}

if [ $# -eq 0 ]; then
    help_cmd
    exit 0
fi

# main: loop through arguments and process
while [ $# -gt 0 ]; do
    case "$1" in
        --build)
            FLAG_BUILD=1
            shift
            ;;
        --load)
            FLAG_LOAD=1
            shift
            ;;
        --rewrite)
            FLAG_REWRITE_BASEIMAGE=1
            shift
            # if [ $# -lt 2 ]; then
            #    echo "Must provide rewrite argument"
            #    exit 1
            # fi
            ARG_REWRITE_BASEIMAGE="$1"
            echo "ARG_REWRITE_BASEIMAGE: $ARG_REWRITE_BASEIMAGE"
            shift      # consume flag + argument
            echo "REMAINING ARGS: $@"
            ;;
        --target)
            FLAG_REWRITE_TARGET=1
            shift
            # if [ $# -lt 2 ]; then
            #    echo "Must provide target argument"
            #    exit 1
            # fi
            ARG_REWRITE_TARGET="$1"
            echo "ARG_REWRITE_TARGET: $ARG_REWRITE_TARGET"
            shift      # consume flag + argument
            echo "REMAINING ARGS: $@"
            ;;
        --push)
            FLAG_PUSH=1
            shift
            ;;
        --all)
            FLAG_ALL=1
            shift
            ;;
        --duration)
            FLAG_DURATION=1
            if [ $# -lt 2 ]; then
                echo "Must provide duration"
                exit 1
            fi
            ARG_DURATION=$2
            shift
            shift
            ;;
        --run)
            FLAG_RUN=1
            shift
            ;;
        --min-crashes)
            if [ $# -lt 2 ]; then
                echo "Must provide expected minimum number of crashes."
                exit 1
            fi
            ARG_MIN_CRASHES=$2
            shift
            shift
            ;;
        --copy-poc)
            FLAG_COPY_POC=1
            shift
            ;;
        --stop)
            FLAG_STOP=1
            shift
            ;;
        --pull)
            FLAG_PULL=1
            shift
            ;;
        --sanity)
            FLAG_SANITY=1
            shift
            ;;
        --save)
            FLAG_SAVE=1
            shift
            ;;
        -h|--help)
            FLAG_HELP=1
            help_cmd
            exit 0
            shift
            ;;
        --verbose)
            set -x
            shift
            ;;
        --clean)
            FLAG_CLEAN=1
            shift
            ;;
        -*)
            echo "Unknown option: $1"
            exit 1
            ;;
        *)
            if [ ! -d $1 ]; then
                echo "$1 not a directory"
                exit 1
            fi

            ARG_PROJECTS+=("$1")
            shift
            ;;
    esac
done


# Add all directories that have a Dockerfile to ARG_PROJECTS
if [ $FLAG_ALL -eq 1 ]; then
    if [ ${#ARG_PROJECTS[@]} -ne 0 ]; then
        echo "Cannot use --all with project names"
        exit 1
    fi
    for i in $(find . -depth 2 -type f -name Dockerfile); do
        ARG_PROJECTS+=( $(basename "$(dirname "$i")"))
    done
fi

# Sanity check we got at least one project
if [ ${#ARG_PROJECTS[@]} -lt 1 ]; then
    echo "Error: must provide at least one project directory"
    exit 1
fi

for project in "${ARG_PROJECTS[@]}"
do
    dir=$project
    name=$(basename "$(cd $project && pwd)")
    cli_log "processing $dir with project name $name"
    process_project "$dir" "$name"
done


exit 0
