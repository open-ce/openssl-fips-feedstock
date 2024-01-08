#!/bin/bash

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

$CONDA_PREFIX/bin/openssl fipsinstall -out $CONDA_PREFIX/ssl/fipsmodule.cnf -module $CONDA_PREFIX/lib/ossl-modules/fips.so > /dev/null 2>&1
pushd $CONDA_PREFIX  > /dev/null
sed -i "s:# .include fipsmodule.cnf:.include $(pwd)/ssl/fipsmodule.cnf:" ssl/openssl.cnf
sed -i 's:# fips = fips_sect:fips = fips_sect:' ssl/openssl.cnf
sed -i '/\[default_sect\]/{n;s/^# activate = 1/activate=1/;}' ssl/openssl.cnf
popd > /dev/null
