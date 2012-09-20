#!/bin/sh
fatal()
{
	echo "$@" >&2
	exit 1
}

[ "$#" -ge 1 ] || fatal "usage: $0 cabName file [file ..]"

name=$1
shift

cat <<EOF
.option explicit
.set maxerrors=1

.set cabinet=on
.set compress=on
.set compressiontype=lzx	;MSZIP|LZX

.set sourcedir=
.set diskdirectorytemplate=
.set rptfilename=$name.rpt

.set generateinf=off
.set inffilename=$name.inf

.set cabinetnametemplate=$name

EOF

for file in $@; do
	echo "$file /inf=no"
done

exit 0
