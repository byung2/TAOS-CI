#!/usr/bin/env bash

##
# Copyright (c) 2018 Samsung Electronics Co., Ltd. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

echo "Make sure commit all changes before running this checker."

CLANGFORMAT=NA

# Use the highest version, >= 3.8
for v in `seq 9 -1 0`; do
	which clang-format-4.$v
	if [[ $? -eq 0 ]]; then
		CLANGFORMAT=clang-format-4.$v
		break
	fi
done
if [ "$CLANGFORMAT" == "NA" ]; then
	for v in `seq 9 -1 8`; do
		which clang-format-3.$v
		if [[ $? -eq 0 ]]; then
			CLANGFORMAT=clang-format-3.$v
			break
		fi
	done

fi

if [ "$CLANGFORMAT" == "NA" ]; then
	echo "Error: clang-format-3.8 or higher is not available."
	echo "       Please install clang-format-3.8 or higher."
	exit 1
fi

FILES_IN_COMPILER=$(find ROS/ -iname '*.h' -o -iname '*.cpp' -o -iname '*.c' -o -iname '*.hpp')
FILES_TO_BE_TESTED=$(git ls-files $FILES_IN_COMPILER)

ln -sf ROS/catkin/style/.clang-format .clang-format
$CLANGFORMAT -i $FILES_TO_BE_TESTED
git diff > format.patch

git diff --name-only > format.list
git show --name-only --pretty="" > format.commit
rm -f .format.infraction
touch .format.infraction
while IFS= read -r LINE
do
	grep "^${LINE}$" format.list >> .format.infraction
done < "format.commit"
COUNT=`cat .format.infraction | wc -l`
echo ${COUNT} "files have infractions"

if [[ ${COUNT} -ne 0 ]]; then
	echo "[FAILED] Format checker failed and update code to follow convention."
	echo "         You can find changes in format.patch"
	exit 1
else
	echo "[PASSED] Format checker succeed."
	exit 0
fi

echo "Error: Something went wrong."
exit 1
