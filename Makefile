#FIXME: if i can figure out how to extract the full version from a dll via commandline, i can remove it's config.mk option as a requirement.
#     : use sub-shells when manually switching directories to handle errors from binaries that drop output relative to the cwd
#     : do filename splitting properly so that there's no problems with spaces
include config.mk

.SECONDARY:

help:
	@echo "Usage: make all|build-certs|build-work|build-target|build-pack|"
	@echo "            clean|clean-certs|clean-work|clean-target|clean-pack|"
	@echo "            unbuild-installer|build-installer|clean-installer"

	# in/* contains files before they're signed
	# out/* contains the binaries after they're signed

### package-specific
out/$(PACKAGE_NAME).msi: out/$(PACKAGE_NAME).wixobj out/setup.cab

out/setup.cab.ddf: out/dbgeng.dll out/dbghelp.dll out/dbgeng.dll.manifest out/dbghelp.dll.manifest out/dbgeng.dll.cat out/dbghelp.dll.cat
	echo $^ | sed 's/ /\n/g' | while read x; do echo `basename $$x`; done | xargs ./make.ddf.sh setup.cab >| $@

out/setup.cab: out/setup.cab.ddf cert/package.pfx 
	cd out && makecab.exe -f `basename $<` && rm -f `basename $@`.rpt && cd -
	signtool.exe sign -f cert/package.pfx -t $(TS_SERVER) $@

### building
build-certs: cert/package.pfx
build-work: in/dbgeng.dll in/dbghelp.dll
build-pack: in/dbgeng.dll.cat in/dbghelp.dll.cat
build-target: out/setup.cab out/dbgeng.dll.cat out/dbghelp.dll.cat

all: build-certs build-target out/dbgeng.msi

#build-installer: build-work build-pack out/dbg_x86.msi
#unbuild-installer: unbuild/dbg_x86.wxs

### cleaning
clean: clean-certs clean-work clean-pack clean-target
clean-certs:
	rm -f cert/codesign.cer cert/codesign.pem cert/codesign.der
	rm -f cert/package.pem cert/package.pfx
clean-work:
	rm -f in/*.dll
clean-target:
	rm -f out/*
clean-installer:
	rm -rf unbuild/*
	rm -f out/*.msi
clean-pack:
	rm -f in/*.manifest in/*.manifest.cdf
	rm -f in/*.cat
	rm -f in/setup.cab*

## updating hashes in manifest for in/*.dll
in/%.dll: src/%.dll
	cp $< $@

in/%.dll.manifest: in/%.dll cert/codesign.der
	./make.manifest.sh $(PACKAGE_NAME) $(PACKAGE_VERSION) cert/codesign.der $< >| $@
	mt.exe -nologo -hashupdate:in -manifest $@ -out:$@

in/%.dll.manifest.cdf: in/%.dll.manifest
	cd in && mt.exe -nologo -hashupdate -manifest `basename $<` -makecdfs -out:`basename $<`

in/%.dll.cat: in/%.dll.manifest.cdf cert/package.pfx
	cd in && makecat.exe -v `basename $<`
	signtool.exe sign -f cert/package.pfx -t $(TS_SERVER) $@

### final binary that writes to out/
out/%.dll: in/%.dll in/%.dll.manifest out/%.dll.cat out/%.dll.manifest
	cp $< $@
	#mt.exe -nologo -hashupdate:out -manifest $<.manifest "-outputresource:$@;1"
	#mt.exe -nologo -hashupdate:out -manifest $<.manifest "-outputresource:$@;2"

out/%.dll.cat: in/%.dll.cat
	cp $< $@

out/%.dll.manifest: in/%.dll.manifest
	cp $< $@

## certificate signing (cert/{package.pfx,package.pem,codesign.cer,codesign.pem,codesign.der})
cert/package.pfx: cert/package.pem 
	openssl pkcs12 -export -nodes -passout pass: -in $< -out $@

cert/package.pem: cert/codesign.cer cert/codesign.pem
	cat $^ >| $@

cert/codesign.cer: cert/codesign.pem
	openssl req -config $(OPENSSL_CONFIG) -x509 -new -key $< -out $@

cert/codesign.pem:
	openssl genrsa -out $@ $(PRIVKEY_BITS)

cert/codesign.der: cert/codesign.pem
	openssl rsa -in $< -out $@ -outform der

openssl.cnf:
	@touch $@
	@echo "[req]" >> $@
	@echo "default_md=sha1" >> $@
	@echo "prompt=no" >> $@
	@echo "distinguished_name=req_distinguished_name" >> $@
	@echo "x509_extensions=v3_code" >> $@
	@echo "[req_distinguished_name]" >> $@
	@echo "CN=Microsoft Root Certificate Authority" >> $@
	@echo "DC=microsoft" >> $@
	@echo "DC=com" >> $@
	@echo "[v3_ca]" >> $@
	@echo "subjectKeyIdentifier=hash" >> $@
	@echo "authorityKeyIdentifier=keyid:always,issuer:always" >> $@
	@echo "basicConstraints=CA:true" >> $@
	@echo "[v3_code]" >> $@
	@echo "subjectKeyIdentifier=hash" >> $@
	@echo "authorityKeyIdentifier=keyid:always,issuer:always" >> $@
	@echo "extendedKeyUsage=codeSigning" >> $@

## recompilation of installer
unbuild/%.wxs: src/%.msi
	dark.exe -nologo -o $@ -x $(abspath $@).resources $<

unbuild/%.wixobj: unbuild/%.wxs
	candle.exe -nologo -o $@ $<

unbuild/%.msi: unbuild/%.wixobj
	light.exe -nologo -notidy -spdb -out $@ $<

unbuild/%.wxs: src/%.wxs
	cp $< $@

## building of installer
out/%.wixobj: src/%.wxs
	candle.exe -nologo -o $@ $<
out/%.msi: out/%.wixobj
	light.exe -nologo -notidy -spdb -v -out $@ $<
