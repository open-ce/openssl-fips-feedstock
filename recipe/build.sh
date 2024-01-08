#!/usr/bin/env bash
# *****************************************************************
# (C) Copyright IBM Corp. 2023. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# *****************************************************************
# Adopted from https://github.com/AnacondaRecipes/openssl-feedstock/blob/master/recipe/build.sh

set -ex

PERL="${BUILD_PREFIX}/bin/perl"
declare -a _CONFIG_OPTS
_CONFIG_OPTS+=(--prefix=${PREFIX})
_CONFIG_OPTS+=(--libdir=lib)
_CONFIG_OPTS+=(shared)
_CONFIG_OPTS+=(enable-fips)
_CONFIG_OPTS+=(threads)
_CONFIG_OPTS+=(no-ssl2)     # broken, insecure protocol
_CONFIG_OPTS+=(no-ssl3)     # broken, insecure protocol
_CONFIG_OPTS+=(no-zlib)
#_CONFIG_OPTS+=(enable-legacy) # necessary to support some function in Python package cryptography

_BASE_CC=$(basename "${CC}")


if [[ ${_BASE_CC} == *-* ]]; then
  # We are cross-compiling or using a specific compiler.
  # do not allow config to make any guesses based on uname.
  _CONFIGURATOR="perl ./Configure"
  case ${_BASE_CC} in
    x86_64-*linux*)
      _CONFIG_OPTS+=(linux-x86_64)
      CFLAGS="${CFLAGS} -Wa,--noexecstack"
      ;;
    aarch64-*-linux*)
      _CONFIG_OPTS+=(linux-aarch64)
      CFLAGS="${CFLAGS} -Wa,--noexecstack"
      ;;
    *powerpc64le-*linux*)
      _CONFIG_OPTS+=(linux-ppc64le)
      CFLAGS="${CFLAGS} -Wa,--noexecstack"
      ;;
    # Optimized s390x builds must use -fno-merge-constants.
    # Without this, a string ("private") in the nid_objs table
    # (obj_dat.c) will vanish when libcrypto.so is built.
    # This is currently assumed to be a bug in the -fmerge-constants
    # optimization for this architecture.
    # This issue prevents the OBJ_sn2nid function from ever finding
    # prime256v1, rendering it unusable as an ecparam.
    *s390x-*linux*)
      _CONFIG_OPTS+=(linux64-s390x)
      CFLAGS="${CFLAGS} -Wa,--noexecstack -fno-merge-constants"
      ;;
    *darwin-arm64*|*arm64-*-darwin*)
      _CONFIG_OPTS+=(darwin64-arm64-cc)
      ;;
    *darwin*)
      _CONFIG_OPTS+=(darwin64-x86_64-cc)
      ;;
  esac
else
  if [[ $(uname) == Darwin ]]; then
    _CONFIG_OPTS+=(darwin64-x86_64-cc)
    _CONFIGURATOR="perl ./Configure"
  else
    # Use config, which is a config.guess-like wrapper around Configure
    _CONFIGURATOR=./config
  fi
fi

CC=${CC}" ${CPPFLAGS} ${CFLAGS}" \
  ${_CONFIGURATOR} ${_CONFIG_OPTS[@]} ${LDFLAGS}

#export LDFLAGS="${LDFLAGS} -Wl,-rpath-link,${PREFIX}/lib"
# This is not working yet. It may be important if we want to perform a parallel build
# as enabled by openssl-1.0.2d-parallel-build.patch where the dependency info is old.
# makedepend is a tool from xorg, but it seems to be little more than a wrapper for
# '${CC} -M', so my plan is to replace it with that, or add a package for it? This
# tool uses xorg headers (and maybe libraries) which is unfortunate.
# http://stackoverflow.com/questions/6362705/replacing-makedepend-with-cc-mm
# echo "echo \$*" > "${SRC_DIR}"/makedepend
# echo "${CC} -M $(echo \"\$*\" | sed s'# --##g')" >> "${SRC_DIR}"/makedepend
# chmod +x "${SRC_DIR}"/makedepend
# PATH=${SRC_DIR}:${PATH} make -j1 depend

export LDFLAGS="${LDFLAGS} -Wl,-rpath-link,${PREFIX}/lib"
make -j${CPU_COUNT} ${VERBOSE_AT}
make install_fips

./util/wrap.pl -fips apps/openssl list -provider-path providers \
-provider fips -providers

# https://github.com/ContinuumIO/anaconda-issues/issues/6424
#if [[ ${HOST} =~ .*linux.* ]]; then
#  if execstack -q "${PREFIX}"/lib/libcrypto.so.3.0 | grep -e '^X '; then
#    echo "Error, executable stack found in libcrypto.so.3.0"
#    exit 1
#  fi
#fi

#Install activate script
mkdir -p "${PREFIX}/bin"
cp "${RECIPE_DIR}/openssl-enable-fips.sh" "${PREFIX}/bin"
