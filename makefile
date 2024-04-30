GAME		= arkanoid.cpp
GAME 		= core_split_screen.c

GIT_REPO	=	"https://github.com/ahmed00101/cpp-game"
bin			=	bin

# x86 x86_64"
# ANDROID_SDK		=	/Users/waqarshujrah/Dev/Android_sdk
ANDROID_SDK		=	/Users/waqara/Dev/Android_sdk

NDK_VER			=	25.2.9519653
ANDROID_NDK		=	$(ANDROID_SDK)/ndk/$(NDK_VER)
BUILD_TOOLS_VER	=	29.0.3# BUILD_TOOLS_VER=34.0.0
BUILD_TOOLS	=	$(ANDROID_SDK)/build-tools/$(BUILD_TOOLS_VER)
# TOOLCHAIN=../android/ndk/toolchains/llvm/prebuilt/linux-x86_64
TOOLCHAIN	=	$(ANDROID_NDK)/toolchains/llvm/prebuilt/darwin-x86_64
ADB			=	$(ANDROID_SDK)/platform-tools/adb
ABIS		=	armeabi-v7a
ABI			=	armeabi-v7a
CCTYPE		=	armv7a-linux-androideabi
ABI_FLAGS	=	-std=c++11 -march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16
CC			=	$(TOOLCHAIN)/bin/$(CCTYPE)29-clang++


CXX			=	clang++
CX			=	g++
CXX_FLAGS	=	-Wall -Wextra -std=c++17 -ggdb
CX_FLAGS	=	-Wall -Wextra -std=c17 -ggdb -Wc++11-narrowing
exeD		=  $(subst .cpp,.o,$(bin)/$(GAME)) 
res			= nothing
NATIVE_APP_GLUE=$(ANDROID_NDK)/sources/android/native_app_glue
FLAGS	= -ffunction-sections -funwind-tables -fstack-protector-strong -fPIC -Wall -Wformat -Werror=format-security -no-canonical-prefixes -DANDROID -DPLATFORM_ANDROID -D__ANDROID_API__=29
INCLUDES	= -I. -Iinclude -I../include -I$(NATIVE_APP_GLUE) -I$(TOOLCHAIN)/sysroot/usr/include




ifeq ($(OS),Windows_NT)
    CXX	=	Q:\Dev\mingw64\bin\x86_64-w64-mingw32-g++
	OSLIBS =  -lopengl32 -lgdi32 -lwinmm -lshell32

    ifeq ($(PROCESSOR_ARCHITEW6432),AMD64)
        CCFLAGS += -D AMD64
    else
        ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
            CCFLAGS += -D AMD64
        endif
        ifeq ($(PROCESSOR_ARCHITECTURE),x86)
            CCFLAGS += -D IA32
        endif
    endif
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
        CCFLAGS += -D LINUX
    endif
    ifeq ($(UNAME_S),Darwin)
	OSLIBS =    -framework CoreVideo -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL
        CCFLAGS += -D OSX
		OS	=	Darwin
    endif
    UNAME_P := $(shell uname -p)
    ifeq ($(UNAME_P),x86_64)
        CCFLAGS += -D AMD64
    endif
    ifneq ($(filter %86,$(UNAME_P)),)
        CCFLAGS += -D IA32
    endif
    ifneq ($(filter arm%,$(UNAME_P)),)
        CCFLAGS += -D ARM
    endif
endif






all:
	clear
	echo $(OS)


runD: compileD
	./$(exeD)

compileD: src/cpp/$(GAME)
	echo $(OS)
	$(CXX) \
	src/cpp/$(GAME) \
	libD/$(OS)/libraylib.a \
	-o $(exeD) \
	-Iinclude \
	$(OSLIBS) \
	$(CXX_FLAGS)





LibMain.so: src/cpp/$(GAME)
	@echo "\n$%\n"
	$(CC) src/cpp/$(GAME) -o android/build/lib/$(ABI)/libmain.so -shared \
	$(INCLUDES) -I$(TOOLCHAIN)/sysroot/usr/include/$(CCTYPE) $(FLAGS) $(ABI_FLAGS) \
	-Wl,-soname,libmain.so -Wl,--exclude-libs,libatomic.a -Wl,--build-id \
	-Wl,--no-undefined -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now \
	-Wl,--warn-shared-textrel -Wl,--fatal-warnings -u ANativeActivity_onCreate \
	-L. -Landroid/build/obj -Llib/$(ABI) \
	-lraylib -lnative_app_glue -llog -landroid -lEGL -lGLESv2 -lOpenSLES -latomic -lc -lm -ldl

CompileNativeLoader: LibMain.so
	@echo $%
	$(BUILD_TOOLS)/aapt package -f -m \
	-S android/build/res -J src/java -M android/build/AndroidManifest.xml \
	-I $(ANDROID_SDK)/platforms/android-29/android.jar

	@echo "$% \n"
	javac -verbose -source 1.8 -target 1.8 -d android/build/obj \
	-bootclasspath jre/lib/rt.jar \
	-classpath $(ANDROID_SDK)/platforms/android-29/android.jar:android/build/obj \
	-sourcepath src src/java/com/raylib/game/R.java \
	src/java/com/raylib/game/NativeLoader.java
	@echo "$% complete \n\n"


DEX: CompileNativeLoader
	@echo "$% \n"
	$(BUILD_TOOLS)/dx --dex --output=android/build/dex/classes.dex android/build/obj
	@echo "Dexing complete \n\n"

CreateAPKData: DEX
	@echo "$% \n"
	cp -R assets android/build/assets

	$(BUILD_TOOLS)/aapt package -f \
	-M android/build/AndroidManifest.xml -S android/build/res -A assets \
	-I $(ANDROID_SDK)/platforms/android-29/android.jar -F android/game.apk android/build/dex
	@echo "\n" 
	cd android/build;$(BUILD_TOOLS)/aapt add ../../android/game.apk lib/$(ABI)/*.so;cd ../..
# $(BUILD_TOOLS)/aapt add ../../android/game.apk lib/$(ABI)/libmain.so
#	@cd ../..
	@echo "$% complete \n\n"




JarSignAPK: CreateAPKData
	@echo $%
	jarsigner -keystore android/raylib.keystore -storepass raylib -keypass raylib \
	-signedjar android/game.apk android/game.apk projectKey

ZipAlignAPK: JarSignAPK
	@echo $%
	$(BUILD_TOOLS)/zipalign -f 4 android/game.apk android/game_ZA.apk
	mv -f android/game_ZA.apk android/game.apk


runA: ZipAlignAPK
	@echo $%
	$(ADB) install -r android/game.apk
	$(ADB) shell am start -a android.intent.action.MAIN -n com.raylib.game/.NativeLoader
# $(ADB) logcat am start -a android.intent.action.MAIN -n com.raylib.game/.NativeLoader
#	$(ADB) logcat *:E| grep -F "`$(ADB) shell ps | grep com.raylib.game  | tr -s [:space:] ' ' | cut -d' ' -f2`"
#	$(ADB) logcat --pid=`$(ADB) shell pidof -s com.raylib.game`

testAVD:
	@echo $%
	rest:=$(shell "$(ADB) devices" )
	# | grep "device" &> /dev/null)
	ifeq (res,0)
		echo "ADB running"
	endif





testArch:
	CXXARCH:=$(shell $(CXX) -dumpmachine | grep -i 'x86_64')
	ifeq ( $(CXXARCH), 'x86_64-apple-darwin20.6.0' )
		?$(shell echo "arch is x86_64")
		$(shell clear)
	endif








APK: JARSIGN
	@echo $%
	# Copy icons
	cp assets/icon_ldpi.png android/build/res/drawable-ldpi/icon.png
	cp assets/icon_mdpi.png android/build/res/drawable-mdpi/icon.png
	cp assets/icon_hdpi.png android/build/res/drawable-hdpi/icon.png
	cp assets/icon_xhdpi.png android/build/res/drawable-xhdpi/icon.png

	# Copy other assets
	# cp assets/* android/build/assets

	@echo " Sign APK"
	# NOTE: If you changed the storepass and keypass in the setup process, change them here too
	jarsigner -keystore android/raylib.keystore -storepass raylib -keypass raylib \
		-signedjar android/game.apk android/game.apk projectKey

	@echo " Sign APK - completed"

	@echo " Zipalign APK"
	$(BUILD_TOOLS)/zipalign -f 4 android/game.apk android/game.final.apk
	@echo " Zipalign APK - completed"

	mv -f android/game.final.apk android/game.apk







compileJ:
	echo "Compile NativeLoader.java"
	javac -verbose -source 1.8 -target 1.8 -d android/build/obj \
	-bootclasspath jre/lib/rt.jar \
	-classpath $ANDROID_SDK/platforms/android-29/android.jar:android/build/obj \
	-sourcepath src src/java/com/raylib/game/R.java \
	src/java/com/raylib/game/NativeLoader.java

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


clean:


cleanD:


cleanA:





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







# if [ "$TYPE" = "Mac" ]; then
# 	echo "\nDo mac compiling for $GAME"
	
# #	clang src/*.c -Lraylib/src -lraylib -Iinclude -framework OpenGL -framework OpenAL -framework Cocoa -DPLATFORM_DESKTOP
# 	if [ "$LANG" = "CPP" ]; then
# 		echo "C plus plus"
# 		g++ -std=c++17  libD/libraylib.a -framework CoreVideo -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL src/cpp/$GAME -o $BIN/game.o -Iinclude/CPP -Iinclude
# 		clang  src/cpp/arkanoid.c libD/libraylib.a -o arkanoid -Iinclude -framework CoreVideo -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL -framework CoreAudio
# 	else
# 		echo "compiling using C"
# #		clang  src/cpp/$GAME libD/libraylib.a  -o $BIN/game.o -Iinclude -framework CoreVideo -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL 
# #		clang  src/cpp/$GAME -LlibD libD/libraylib.a -lraylib  -o $BIN/game.o -Iinclude -framework CoreVideo -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL 
# 	#	clang  -o game.o -LlibD -lraylib  src/cpp/$GAME    -Iinclude -framework CoreVideo -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL 
# 		# clang libD/libraylib.a -o game.o src/cpp/arkanoid.c -Iinclude -framework CoreVideo -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL 
# 		# clang -o game.o libD/libraylib.a src/cpp/arkanoid.c -Iinclude -framework CoreVideo -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL 
# 		# clang  src/cpp/arkanoid.c libD/raudio.o libD/libraylib.a  -o game -Iinclude -framework CoreVideo -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL -framework CoreAudio
# 		# clang  src/cpp/arkanoid.c -Llibd -lraylib   -o game -Iinclude -framework CoreVideo -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL -framework CoreAudio
# 		# clang  src/cpp/arkanoid.c libD/libraylib.a -o arkanoid -Iinclude -framework CoreVideo -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL -framework CoreAudio
# 		$CX $CX_FLAGS src/cpp/$GAME libD/libraylib.a  -o $BIN/game.o -Iinclude -framework CoreVideo -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL 

# 	fi

# 		if [ $? -ne 0 ]
# 		then
# 			echo "Build failed"
# 			exit 1
# 		else
# 			$BIN/game.o
# 			exit	
# 		fi

	
# fi



# exit






# ______________________________________________________________________________
#
#  Compile
# ______________________________________________________________________________
#





# ______________________________________________________________________________
#
#  Build APK
# ______________________________________________________________________________
#







# Install to device or emulator

