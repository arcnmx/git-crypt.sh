#!/bin/bash
set -eu

ORIG_PATH="$PATH"
REPO_PATH="$PWD"

switch_system() {
	export PATH="$ORIG_PATH"
}

switch_script() {
	export PATH="$REPO_PATH:$ORIG_PATH"
}

git-cat-noconv() {
	FILENAME="$1"
	git show --no-textconv --binary HEAD:"$FILENAME"
}

git-cat() {
	FILENAME="$1"
	git show --binary HEAD:"$FILENAME"
}

assert() {
	MSG="$1"
	shift 1
	if ! "$@"; then
		echo "$MSG" >&2
		return 1
	fi
}

inv() {
	! "$@"
}

run() {
	SWITCH_1="$1"
	SWITCH_2="$2"

	switch_$SWITCH_1

	DIR_INIT=$(mktemp -d "${TMPDIR:-/tmp}"/git-crypt.XXXXXXXX)
	DIR_CLONE=$(mktemp -d "${TMPDIR:-/tmp}"/git-crypt.XXXXXXXX)
	DATA=$(openssl rand -hex 1000)
	cleanup() {
		rm -rf "$DIR_INIT" "$DIR_CLONE"
	}
	trap cleanup EXIT
	cd "$DIR_INIT"
	git init -q
	git-crypt init
	echo "$DATA" > file1
	echo "$DATA" > file2
	mkdir dir1 && echo "$DATA" > "dir1/has space"
	echo '/file1 filter=git-crypt diff=git-crypt' > .gitattributes
	echo '/dir1/* filter=git-crypt diff=git-crypt' >> .gitattributes
	git add file1 file2 "dir1/has space" .gitattributes
	git config user.name "no one"
	git config user.email "ghost@konpa.ku"
	git commit -qm "some data"
	assert "file1 not encrypted" inv cmp -s <(git-cat-noconv file1) file1
	assert "dir1 not encrypted" inv cmp -s <(git-cat-noconv "dir1/has space") "dir1/has space"
	assert "file2 differs" cmp -s <(git-cat-noconv file2) file2
	git-crypt export-key "$DIR_INIT/key"

	switch_$SWITCH_2

	cd "$DIR_CLONE"
	git clone -q "$DIR_INIT" .
	assert "file1 not encrypted" inv cmp -s file1 <(echo "$DATA")
	assert "dir1 not encrypted" inv cmp -s "dir1/has space" <(echo "$DATA")
	assert "file2 differs" cmp -s file2 <(echo "$DATA")
	git-crypt unlock "$DIR_INIT/key"
	assert "file1 differs" cmp -s file1 <(echo "$DATA")
	assert "dir1 differs" cmp -s "dir1/has space" <(echo "$DATA")
	assert "file2 differs" cmp -s file2 <(echo "$DATA")
}

echo "# git-crypt -> git-crypt.sh"
(run system script)
echo "# git-crypt.sh -> git-crypt"
(run script system)
