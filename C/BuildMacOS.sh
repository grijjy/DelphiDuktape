OUTPUT="../bin/libduktape_osx32.dylib"
PLATFORM="MacOSX"

DEVELOPER_DIR=`xcode-select -print-path`
if [ ! -d $DEVELOPER_DIR ]; then
  echo "Please set up Xcode correctly. '$DEVELOPER_DIR' is not a valid developer tools folder."
  exit 1
fi

SDK_ROOT=$DEVELOPER_DIR/Platforms/$PLATFORM.platform/Developer/SDKs/$PLATFORM.sdk
if [ ! -d $SDK_ROOT ]; then
  echo "The MacOSX SDK was not found in $SDK_ROOT."
  exit 1
fi

clang -shared -o $OUTPUT -fPIC -O3 -arch i386 -isysroot $SDK_ROOT src/duktape.c