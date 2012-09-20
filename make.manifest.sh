#!/bin/sh
fatal()
{
	echo "$@" >&2
	exit 1
}

[ "$#" -ge 4 ] || fatal "usage: $0 assemblyIdentity assemblyVersion publicKey file [file ..]"

name=$1
version=$2
publickey=$3
shift 3

publickeytoken=$( cat $publickey | openssl dgst -sha1 -hex -r | cut -d ' ' -f 1 | sed 's/.\{24\}//' )
#publickeytoken=$( sn -q -t $publickey | cut -d ' ' -f 5 )
digestvalue()
{
	cat "$1" | openssl dgst -sha1 -binary | openssl enc -base64 2>/dev/null
}

cat <<EOF
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
  <assemblyIdentity type="win32" name="$name" version="$version" processorArchitecture="x86" publicKeyToken="$publickeytoken"></assemblyIdentity>
EOF

for filename in "$@"; do
	basefilename=`basename $filename`
cat <<EOF
  <file name="$basefilename">
    <asmv2:hash xmlns:asmv2="urn:schemas-microsoft-com:asm.v2" xmlns:dsig="http://www.w3.org/2000/09/xmldsig#">
      <dsig:Transforms>
        <dsig:Transform Algorithm="urn:schemas-microsoft-com:HashTransforms.Identity"></dsig:Transform>
      </dsig:Transforms>
      <dsig:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"></dsig:DigestMethod>
      <dsig:DigestValue>`digestvalue $filename`</dsig:DigestValue>
    </asmv2:hash>
  </file>
EOF
done

cat <<EOF
</assembly>
EOF

exit 0
