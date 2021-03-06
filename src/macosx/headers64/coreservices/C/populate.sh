if [ "$(basename "$(pwd)")" = C -a "$(basename "$(dirname "$(pwd)")")" = coreservices ] ; then
    rm -rf System Developer usr
    SDK=/Developer/SDKs/MacOSX10.6.sdk
    CFLAGS="-m64 -fobjc-abi-version=2 -isysroot ${SDK} -mmacosx-version-min=10.6"
    export CFLAGS
    h-to-ffi.sh ${SDK}/System/Library/Frameworks/CoreServices.framework/Headers/CoreServices.h
else
    echo "Please   cd coreservices/C   before running   sh ./populate.sh"
fi
