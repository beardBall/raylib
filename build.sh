#!/bin/sh
# ______________________________________________________________________________
#
#  Compile raylib project for Android
# ______________________________________________________________________________
#
# NOTE: If you excluded any ABIs in the previous steps, remove them from this list too

# TODO: arm64-v8a building doesn't work, ARM64 devices can still run the 32 bit version:
#       /usr/bin/ld: /tmp/main-08f12a.o: Relocations in generic ELF (EM: 183)
#       /usr/bin/ld: /tmp/main-08f12a.o: Relocations in generic ELF (EM: 183)
#       /usr/bin/ld: /tmp/main-08f12a.o: error adding symbols: file in wrong format
git_repo="https://github.com/ahmed00101/cpp-game"
BIN=bin
TYPE=$1
GAME=$2
LANG=$3
echo $TYPE
echo $GAME
echo $LANG

if [ "$TYPE" = "Mac" ]; then
	echo "\nDo mac compiling for $GAME"
	
#	clang src/*.c -Lraylib/src -lraylib -Iinclude -framework OpenGL -framework OpenAL -framework Cocoa -DPLATFORM_DESKTOP
	if [ "$LANG" = "CPP" ]; then
		echo "C plus plus"
		g++ -std=c++17 -framework CoreVideo -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL libD/libraylib.a src/cpp/$GAME -o $BIN/game.o -Iinclude/CPP -Iinclude
	else
		clang -framework CoreVideo -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL libD/libraylib.a src/cpp/$GAME -o $BIN/game.o -Iinclude
	fi
	$BIN/game.o
	exit
fi




ABIS="armeabi-v7a"
# x86 x86_64"
ANDROID_SDK=/Users/waqarshujrah/Dev/Android_sdk
NDK_VER=25.2.9519653
ANDROID_NDK=$ANDROID_SDK/ndk/$NDK_VER

BUILD_TOOLS_VER=29.0.3
# BUILD_TOOLS_VER=34.0.0
BUILD_TOOLS=$ANDROID_SDK/build-tools/$BUILD_TOOLS_VER
# TOOLCHAIN=../android/ndk/toolchains/llvm/prebuilt/linux-x86_64
TOOLCHAIN=$ANDROID_NDK/toolchains/llvm/prebuilt/darwin-x86_64
echo $BUILD_TOOLS
export PATH="$BUILD_TOOLS:$PATH"

# exit


NATIVE_APP_GLUE=$ANDROID_NDK/sources/android/native_app_glue

FLAGS="-ffunction-sections -funwind-tables -fstack-protector-strong -fPIC -Wall \
	-Wformat -Werror=format-security -no-canonical-prefixes \
	-DANDROID -DPLATFORM_ANDROID -D__ANDROID_API__=29"

INCLUDES="-I. -Iinclude -I../include -I$NATIVE_APP_GLUE -I$TOOLCHAIN/sysroot/usr/include"

# Copy icons
cp assets/icon_ldpi.png android/build/res/drawable-ldpi/icon.png
cp assets/icon_mdpi.png android/build/res/drawable-mdpi/icon.png
cp assets/icon_hdpi.png android/build/res/drawable-hdpi/icon.png
cp assets/icon_xhdpi.png android/build/res/drawable-xhdpi/icon.png

# Copy other assets
cp assets/* android/build/assets

# ______________________________________________________________________________
#
#  Compile
# ______________________________________________________________________________
#
for ABI in $ABIS; do
	case "$ABI" in
		"armeabi-v7a")
			CCTYPE="armv7a-linux-androideabi"
			ABI_FLAGS="-std=c99 -march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16"
			;;

		"arm64-v8a")
			CCTYPE="aarch64-linux-android"
			ABI_FLAGS="-std=c99 -target aarch64 -mfix-cortex-a53-835769"
			;;

		"x86")
			CCTYPE="i686-linux-android"
			ABI_FLAGS=""
			;;

		"x86_64")
			CCTYPE="x86_64-linux-android"
			ABI_FLAGS=""
			;;
	esac
	CC="$TOOLCHAIN/bin/${CCTYPE}29-clang"

	echo "Compile native app glue c. -> .o"
	# .c -> .o"
	# $CC -c $NATIVE_APP_GLUE/android_native_app_glue.c -o $NATIVE_APP_GLUE/native_app_glue.o \
		# $INCLUDES -I$TOOLCHAIN/sysroot/usr/include/$CCTYPE $FLAGS $ABI_FLAGS
	
	echo "Compile native app glue o. -> .a"
	# .o -> .a
	# $TOOLCHAIN/bin/llvm-ar rcs lib/$ABI/libnative_app_glue.a $NATIVE_APP_GLUE/native_app_glue.o


	echo "\nCompile project src/*.c to libmain.so"
	$CC src/cpp/*.c -o android/build/lib/$ABI/libmain.so -shared \
		$INCLUDES -I$TOOLCHAIN/sysroot/usr/include/$CCTYPE $FLAGS $ABI_FLAGS \
		-Wl,-soname,libmain.so -Wl,--exclude-libs,libatomic.a -Wl,--build-id \
		-Wl,--no-undefined -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now \
		-Wl,--warn-shared-textrel -Wl,--fatal-warnings -u ANativeActivity_onCreate \
		-L. -Landroid/build/obj -Llib/$ABI \
		-lraylib -lnative_app_glue -llog -landroid -lEGL -lGLESv2 -lOpenSLES -latomic -lc -lm -ldl
done


# ______________________________________________________________________________
#
#  Build APK
# ______________________________________________________________________________
#
$BUILD_TOOLS/aapt package -f -m \
	-S android/build/res -J src/java -M android/build/AndroidManifest.xml \
	-I $ANDROID_SDK/platforms/android-29/android.jar

echo "Compile NativeLoader.java"
javac -verbose -source 1.8 -target 1.8 -d android/build/obj \
	-bootclasspath jre/lib/rt.jar \
	-classpath $ANDROID_SDK/platforms/android-29/android.jar:android/build/obj \
	-sourcepath src src/java/com/raylib/game/R.java \
	src/java/com/raylib/game/NativeLoader.java

echo "\n\nDexing"
$BUILD_TOOLS/dx --dex --output=android/build/dex/classes.dex android/build/obj
# $BUILD_TOOLS/d8 --classpath android/build/obj --output android/build/dex/classes.dex
echo "\n\nDexing done!"

echo "# Add resources and assets to APK"
$BUILD_TOOLS/aapt package -f \
	-M android/build/AndroidManifest.xml -S android/build/res -A assets \
	-I $ANDROID_SDK/platforms/android-29/android.jar -F android/game.apk android/build/dex

echo "# Add libraries to APK"
cd android/build
for ABI in $ABIS; do
	$BUILD_TOOLS/aapt add ../../android/game.apk lib/$ABI/libmain.so
done
cd ../..
echo "# Add libraries to APK - Completed"



echo " Sign APK"
# NOTE: If you changed the storepass and keypass in the setup process, change them here too
jarsigner -keystore android/raylib.keystore -storepass raylib -keypass raylib \
	-signedjar android/game.apk android/game.apk projectKey

echo " Sign APK - completed"

echo " Zipalign APK"
$BUILD_TOOLS/zipalign -f 4 android/game.apk android/game.final.apk
echo " Zipalign APK - completed"

mv -f android/game.final.apk android/game.apk

# Install to device or emulator
$ANDROID_SDK/platform-tools/adb install -r android/game.apk
adb shell am start -a android.intent.action.MAIN -n com.raylib.game/.NativeLoader
