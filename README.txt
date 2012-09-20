This build-environment allows for one to automatically build an installer for DLLs that need to be registered into the GAC. It does this by taking a binary dll, signing it to ensure it is strongly named, and then building a .cab file containing the manifest and security catalog. Then using the WiX toolset, it will combine all these files into an easy-to-deploy .msi installer.

This fixes DLL hell if for example your operating system and your SDK give 2 versions of a DLL, and your application chooses to use the operating system's version.

http://msdn.microsoft.com/en-us/library/windows/desktop/aa375188(v=vs.85).aspx

To build the installer, the following tools are required.
    GNU Make and binutils (msys) -- http://www.mingw.org/wiki/MSYS
    Microsoft Platform SDK -- http://www.microsoft.com/en-us/download/details.aspx?id=8279
    WiX Toolset -- http://wixtoolset.org/

Build certificates, manifests, strong-naming, and finally the installer.
    $ make all

This takes a binary dll, and makes it strongly named so that it can be registered into the GAC (Global Assembly Cache) as a shared Side-by-Side assembly.
    $ make out/whatever.dll

This will take the strongly-named dbgeng.dll and dbghelp.dll, security catalogs, and combine them into an installer.
    $ make out/dbgeng.msi

[Paths]
    src/:
        original source files that are untampered with

    cert/:
        contains output of all files that were used to generate a self-signed certificate.

    in/:
        the manifest for each binary is stored here, and then is updated via mt.exe for the file hashes
        each .cdf file is generated from the .manifest that is created
        a security catalog (.cat) file is generated from the .cdf file and is then signed for the installer
        
    out/:
        final output
