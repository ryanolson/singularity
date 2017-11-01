#!/bin/bash
#
# Copyright (c) 2017, SingularityWare, LLC. All rights reserved.
#
# See the COPYRIGHT.md file at the top-level directory of this distribution and at
# https://github.com/singularityware/singularity/blob/master/COPYRIGHT.md.
#
# This file is part of the Singularity Linux container project. It is subject to the license
# terms in the LICENSE.md file found in the top-level directory of this distribution and
# at https://github.com/singularityware/singularity/blob/master/LICENSE.md. No part
# of Singularity, including this file, may be copied, modified, propagated, or distributed
# except according to the terms contained in the LICENSE.md file.
#
# This file also contains content that is covered under the LBNL/DOE/UC modified
# 3-clause BSD license and is subject to the license terms in the LICENSE-LBNL.md
# file found in the top-level directory of this distribution and at
# https://github.com/singularityware/singularity/blob/master/LICENSE-LBNL.md.


message 2 "Evaluating args: '$*'\n"

NVIDIA_CONTAINER_SCRIPTS=${NVIDIA_CONTAINER_SCRIPTS:-/etc/singularity}
nv_parse()
{
    if [ -f ${NVIDIA_CONTAINER_SCRIPTS}/nvidia-container-libs.py ]; then
       NV_GREP="`${NVIDIA_CONTAINER_SCRIPTS}/nvidia-container-libs.py`"
    else
       NV_GREP="/libnv|/libcuda|/libEGL|/libGL|/libnvcu|/libvdpau|/libOpenCL|/libOpenGL"
    fi
    for i in `ldconfig -p | grep -E "${NV_GREP}"`; do
        if [ -f "$i" ]; then
            message 2 "Found NV library: $i\n"
            if [ -z "${SINGULARITY_CONTAINLIBS:-}" ]; then
                SINGULARITY_CONTAINLIBS="$i"
            else
                SINGULARITY_CONTAINLIBS="$SINGULARITY_CONTAINLIBS,$i"
            fi
        fi
    done
    if [ -z "${SINGULARITY_CONTAINLIBS:-}" ]; then
        message WARN "Could not find any Nvidia libraries on this host!\n";
    else
        export SINGULARITY_CONTAINLIBS
    fi
    if [ -f ${NVIDIA_CONTAINER_SCRIPTS}/nvidia-smi-path.py ]; then
        NVIDIA_SMI_PATH=$(${NVIDIA_CONTAINER_SCRIPTS}/nvidia-smi-path.py)
    else
        NVIDIA_SMI_PATH=`which nvidia-smi`
    fi
    if [ ! -z "${NVIDIA_SMI_PATH}" ]; then
        if [ -n "${SINGULARITY_BINDPATH:-}" ]; then
            SINGULARITY_BINDPATH="${SINGULARITY_BINDPATH},${NVIDIA_SMI_PATH}:/usr/local/nvidia/bin"
        else
            SINGULARITY_BINDPATH="${NVIDIA_SMI_PATH}:/usr/local/nvidia/bin"
        fi
        export SINGULARITY_BINDPATH
    fi
}

nv_default=${SINGULARITY_NVIDIA_DEFAULT:-true}
nv_parsed=false

while true; do
    case ${1:-} in
        -h|--help|help)
            exec "$SINGULARITY_libexecdir/singularity/cli/help.exec" "$SINGULARITY_COMMAND"
        ;;
        -o|--overlay)
            shift
            SINGULARITY_OVERLAYIMAGE="${1:-}"
            export SINGULARITY_OVERLAYIMAGE
            shift

            if [ ! -e "${SINGULARITY_OVERLAYIMAGE:-}" ]; then
                message ERROR "Overlay image must be a file or directory!\n"
                ABORT 255
            fi
        ;;
        -s|--shell)
            shift
            SINGULARITY_SHELL="${1:-}"
            export SINGULARITY_SHELL
            shift
        ;;
        -u|--user|--userns)
            SINGULARITY_NOSUID=1
            export SINGULARITY_NOSUID
            shift
        ;;
        -w|--writable)
            shift
            SINGULARITY_WRITABLE=1
            export SINGULARITY_WRITABLE
        ;;
        -H|--home)
            shift
            SINGULARITY_HOME="$1"
            export SINGULARITY_HOME
            shift
        ;;
        -W|--wdir|--workdir|--workingdir)
            shift
            SINGULARITY_WORKDIR="$1"
            export SINGULARITY_WORKDIR
            shift
        ;;
        -S|--scratchdir|--scratch-dir|--scratch)
            shift
            SINGULARITY_SCRATCHDIR="$1,${SINGULARITY_SCRATCHDIR:-}"
            export SINGULARITY_SCRATCHDIR
            shift
        ;;
        app|--app|-a)
            shift
            SINGULARITY_APPNAME="${1:-}"
            export SINGULARITY_APPNAME
            shift
        ;;
        -B|--bind)
            shift
            SINGULARITY_BINDPATH="${SINGULARITY_BINDPATH:-},${1:-}"
            export SINGULARITY_BINDPATH
            shift
        ;;
        -c|--contain)
            shift
            SINGULARITY_CONTAIN=1
            export SINGULARITY_CONTAIN
        ;;
        -C|--containall|--CONTAIN)
            shift
            SINGULARITY_CONTAIN=1
            SINGULARITY_UNSHARE_PID=1
            SINGULARITY_UNSHARE_IPC=1
            SINGULARITY_CLEANENV=1
            export SINGULARITY_CONTAIN SINGULARITY_UNSHARE_PID SINGULARITY_UNSHARE_IPC SINGULARITY_CLEANENV
        ;;
        -e|--cleanenv)
            shift
            SINGULARITY_CLEANENV=1
            export SINGULARITY_CLEANENV
        ;;
        -p|--pid)
            shift
            SINGULARITY_UNSHARE_PID=1
            export SINGULARITY_UNSHARE_PID
        ;;
        -i|--ipc)
            shift
            SINGULARITY_UNSHARE_IPC=1
            export SINGULARITY_UNSHARE_IPC
        ;;
        -n|--net)
            shift
            SINGULARITY_UNSHARE_NET=1
            export SINGULARITY_UNSHARE_NET
        ;;
        --pwd)
            shift
            SINGULARITY_TARGET_PWD="$1"
            export SINGULARITY_TARGET_PWD
            shift
        ;;
        --nv)
            shift
<<<<<<< HEAD
            nv_parse
            nv_parsed=true
        ;;
        -*)
            message ERROR "Unknown option: ${1:-}\n"
            exit 1
        ;;
        *)
            break;
        ;;
    esac
done

if "$nv_default" && ! "$nv_parsed"; then
    nv_parse
fi
