SET(OSGEDITOR_MAJOR_VERSION 0)
SET(OSGEDITOR_MINOR_VERSION 1)
SET(OSGEDITOR_PATCH_VERSION 1)
SET(OSGEDITOR_SOVERSION 1)
SET(OSGEDITOR_VERSION ${OSGEDITOR_MAJOR_VERSION}.${OSGEDITOR_MINOR_VERSION}.${OSGEDITOR_PATCH_VERSION})

# set to 0 when not a release candidate, non zero means that any generated
# git tags will be treated as release candidates of given number
SET(OSGEDITOR_RELEASE_CANDIDATE 1)

# allow use logic keyword
set(CMAKE_ALLOW_LOOSE_LOOP_CONSTRUCTS TRUE)
# Use to organize targets in an IDE, 分目录组织你的多个工程
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

cmake_minimum_required(VERSION 3.0.0 FATAL_ERROR)

project(OSGEditor LANGUAGES CXX)

# Get OSX version in MAJOR.MINOR format
# sw_vers [-productName|-productVersion|-buildVersion] fetch system version
# delete trainling whitespces and assign to OSGEDITOR_OSX_VERSION
IF(APPLE)
  EXECUTE_PROCESS(COMMAND sw_vers -productVersion
    OUTPUT_VARIABLE OSGEDITOR_OSX_VERSION
    OUTPUT_STRIP_TRAILING_WHITESPACE)
  STRING(REGEX REPLACE "^([0-9]+\\.[0-9]+).*$" "\\1"
    OSGEDITOR_OSX_VERSION "${OSGEDITOR_OSX_VERSION}")
ENDIF()

# Set OSX architecture flags here, since they must be specified before
# creating the actual OSG project.
# Note that the CMAKE_OSX_* variables are not well documented in
# CMake 2.8, but they do officially exist.
# See https://cmake.org/Bug/view.php?id=14695#c34953
# Additionally, OSGEDITOR_WINDOWING_SYSTEM is set here for OSX since its
# value is needed to find the correct version of OpenGL (X11 or Cocoa).
IF(APPLE)

  # Here we check if the user specified IPhone SDK
  # These options are formally defined later, but can also be specified
  # by the user at the command line using the cmake -D switch
  # Note that FORCE is used since the user will likely enable IPhone
  # build via CMake GUI after already having configured once
  IF(OSGEDITOR_BUILD_PLATFORM_IPHONE OR OSGEDITOR_BUILD_PLATFORM_IPHONE_SIMULATOR)
    SET(OSGEDITOR_WINDOWING_SYSTEM "IOS" CACHE STRING "Windowing system type for graphics window creation, options only IOS.")

    #set iphone arch and flags taken from http://sites.google.com/site/michaelsafyan/coding/resources/how-to-guides/cross-compile-for-the-iphone/how-to-cross-compile-for-the-iphone-using-cmake
    IF(OSGEDITOR_BUILD_PLATFORM_IPHONE)
      IF(${IPHONE_VERSION_MIN} LESS "7.0")
	SET(CMAKE_OSX_ARCHITECTURES "armv6;armv7" CACHE STRING "Build architectures for iOS" FORCE)
      ELSE()
	SET(CMAKE_OSX_ARCHITECTURES "armv7;armv7s;arm64" CACHE STRING "Build architectures for iOS" FORCE)
      ENDIF()

    ELSE()
      #simulator uses i386 architectures
      SET(CMAKE_OSX_ARCHITECTURES "i386" CACHE STRING "Build architectures for iOS Simulator" FORCE)
    ENDIF()

    #here we set the specific iphone sdk version. We can only set either device or simulator sdk. So if you want both you currently have to have two seperate projects
    SET(CMAKE_OSX_SYSROOT "${IPHONE_SDKROOT}" CACHE STRING "System root for iOS" FORCE)

  ELSE()
    foreach(APPLE_SDK_VERSION 10 11 12 13 14 15)
        if (IS_DIRECTORY "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.${APPLE_SDK_VERSION}.sdk")
            set(CMAKE_OSX_SYSROOT "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.${APPLE_SDK_VERSION}.sdk")
        endif()
    endforeach(APPLE_SDK_VERSION)

    # OSX >= 10.5 uses Cocoa windowing system, otherwise Carbon
    IF(OSGEDITOR_OSX_VERSION VERSION_LESS 10.5)
      SET(OSGEDITOR_WINDOWING_SYSTEM "Carbon" CACHE STRING "Windowing system type for graphics window creation, options Carbon, Cocoa or X11.")
    ELSE()
      SET(OSGEDITOR_WINDOWING_SYSTEM "Cocoa" CACHE STRING "Windowing system type for graphics window creation, options Carbon, Cocoa or X11.")
    ENDIF()

    # Set defaults for Universal Binaries. We want 32-bit Intel/PPC on 10.4
    # and 32/64-bit Intel/PPC on >= 10.5. Anything <= 10.3 doesn't support.
    # These are set the first time CMake is run, and can be changed by
    # the user at any time.
    IF(OSG_OSX_VERSION VERSION_GREATER_EQUAL 10.14)
        # x86_64 only
        SET(CMAKE_OSX_ARCHITECTURES "x86_64" CACHE STRING "Build architectures for OSX")
        SET(CMAKE_OSX_DEPLOYMENT_TARGET "10.9" CACHE STRING "Target OSX version")
        # libstdc++ is no longer supported
        SET(CMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LANGUAGE_STANDARD "c++11")
        SET(CMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LIBRARY "libc++")
    ELSEIF(OSG_OSX_VERSION VERSION_GREATER 10.8)
      # 64 Bit Works, i386,ppc is not supported any more
      SET(CMAKE_OSX_ARCHITECTURES "x86_64" CACHE STRING "Build architectures for OSX")
      SET(CMAKE_OSX_DEPLOYMENT_TARGET "10.10" CACHE STRING "Target OSX version")
    ELSEIF(OSGEDITOR_OSX_VERSION VERSION_GREATER 10.7)
      # 64 Bit Works, i386,ppc is not supported any more
      SET(CMAKE_OSX_ARCHITECTURES "x86_64" CACHE STRING "Build architectures for OSX")
      SET(CMAKE_OSX_DEPLOYMENT_TARGET "10.8" CACHE STRING "Target OSX version")
    ELSEIF(OSGEDITOR_OSX_VERSION VERSION_EQUAL 10.7)
      # 64 Bit Works, PPC is not supported any more
      SET(CMAKE_OSX_ARCHITECTURES "i386;x86_64" CACHE STRING "Build architectures for OSX")
    ELSEIF(OSGEDITOR_OSX_VERSION VERSION_GREATER 10.4)
      # 64-bit compiles are not supported with Carbon.
      SET(CMAKE_OSX_ARCHITECTURES "ppc;i386" CACHE STRING "Build architectures for OSX")
      SET(CMAKE_OSX_DEPLOYMENT_TARGET "10.5" CACHE STRING "Target OSX version")
    ELSEIF(OSGEDITOR_OSX_VERSION VERSION_EQUAL 10.4)
      # 64-bit compiles are not supported with Carbon.
      SET(CMAKE_OSX_ARCHITECTURES "ppc;i386" CACHE STRING "Build architectures for OSX")
    ELSE()
      # No Universal Binary support and SDK detection is too unreliable.
      # Warn user and continue at their own peril.
      MESSAGE(WARNING "OSX 10.3 and earlier not supported.")
    ENDIF()
  ENDIF()
ENDIF()

# There are some configurations
# We have some custom .cmake scripts not in the official distribution.
# Maybe this can be used override existing behavior if needed?
SET(CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/CMakeModules;${CMAKE_MODULE_PATH}")

# Include macro utilities here
INCLUDE(OsgMacroUtils)

# Expose CMAKE_INCLUDE_PATH and CMAKE_LIBARY_PATH to the GUI so users
# may set these values without needing to manipulate the environment.
SET(CMAKE_INCLUDE_PATH ${CMAKE_INCLUDE_PATH} CACHE STRING "You may add additional search paths here. Use ; to separate multiple paths.")
SET(CMAKE_LIBRARY_PATH ${CMAKE_LIBRARY_PATH} CACHE STRING "You may add additional search paths here. Use ; to separate multiple paths.")

# We are proposing that a new variable called CMAKE_PREFIX_PATH be introduced
# to CMake to compliment CMAKE_INCLUDE_PATH and CMAKE_LIBRARY_PATH.
# A formal feature request has been submited to CMake, Bug #4947.
# It is intended for those users who have common prefixes for their INCLUDE
# and LIBRARY locations. So if users have headers in /usr/local/include
# and libraries in /usr/local/lib, the common prefix is /usr/local.
# It should also cover the case where headers and libraries are
# in the same directory.
# Our proposal expects that FIND_* commands will automatically search for
# CMAKE_PREFIX_PATH right after CMAKE_INCLUDE_PATH or CMAKE_LIBRARY_PATH.
# Obviously, since CMake does not currently support this, we must write
# our Find*.cmake modules to explicitly support this. Otherwise, this variable
# will have no impact.
# This is unofficial so this may be removed or changed at anytime.
SET(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} CACHE STRING "(EXPERIMENTAL) You may add additional search paths here. Use ; to separate multiple paths.")
SET(ACTUAL_3DPARTY_DIR ${PROJECT_SOURCE_DIR}/3rdparty CACHE STRING "(EXPERIMENTAL) You may set your 3rdparty path")


# This is for an advanced option to give aggressive warnings
# under different compilers. If yours is not implemented, this option
# will not be made available.
IF(CMAKE_COMPILER_IS_GNUCXX)
    # To be complete, we might also do GNUCC flags,
    # but everything here is C++ code.
    # -Wshadow and -Woverloaded-virtual are also interesting flags, but OSG
    # returns too many hits.
    # FYI, if we do implement GNUCC, then -Wmissing-prototypes in another
    # interesting C-specific flag.
    # Also, there is a bug in gcc 4.0. Under C++, -pedantic will create
    # errors instead of warnings for certain issues, including superfluous
    # semicolons and commas, and the use of long long. -fpermissive seems
    # to be the workaround.
    SET(OSGEDITOR_AGGRESSIVE_WARNING_FLAGS -Wall -Wparentheses -Wno-long-long -Wno-import -pedantic -Wreturn-type -Wmissing-braces -Wunknown-pragmas -Wunused)

    IF(${CMAKE_MAJOR_VERSION} GREATER 2 AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 4.9)
        SET(OSGEDITOR_AGGRESSIVE_WARNING_FLAGS ${OSGEDITOR_AGGRESSIVE_WARNING_FLAGS} -Wshadow -Wmaybe-uninitialized -Wextra)
    ENDIF()

    # Previous included -Wformat=2 in OSGEDITOR_AGGRESSIVE_WARNING_FLAGS but had to remove it due to standard library errors


ELSEIF(MSVC)
        #disable specific warning level 4 warnings:
        #C4100 'identifier' : unreferenced formal parameter
        #C4127 Error Message conditional expression is constant
        #C4706 assignment within conditional expression
        #C4430 C++ does not support default-int" .
        SET(OSGEDITOR_AGGRESSIVE_WARNING_FLAGS /W4 /wd4706 /wd4127 /wd4100 /wd4430)
ELSEIF(CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
        SET(OSGEDITOR_AGGRESSIVE_WARNING_FLAGS  -Wall -Wparentheses -Wno-long-long -Wno-import -pedantic -Wreturn-type -Wmissing-braces -Wunknown-pragmas -Wunused -Wno-overloaded-virtual)

        # CMake lacks an elseif, so other non-gcc, non-VS compilers need
        # to be listed below. If unhandled, OSGEDITOR_AGGRESSIVE_WARNING_FLAGS should
        # remain unset.

        IF (APPLE)
            SET(OSGEDITOR_CXX_LANGUAGE_STANDARD "C++11" CACHE STRING "set the c++ language standard (C++98 / GNU++98 / C++11) for OSG" )
            MARK_AS_ADVANCED(OSGEDITOR_CXX_LANGUAGE_STANDARD)
            # remove existing flags
            REMOVE_CXX_FLAG(-std=c++98)
            REMOVE_CXX_FLAG(-std=gnu++98)
            REMOVE_CXX_FLAG(-std=c++11)
            REMOVE_CXX_FLAG(-stdlib=libstdc++)
            REMOVE_CXX_FLAG(-stdlib=libc++)

            IF(${OSGEDITOR_CXX_LANGUAGE_STANDARD} STREQUAL "c++98" OR ${OSGEDITOR_CXX_LANGUAGE_STANDARD} STREQUAL "C++98")
                set(CMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LANGUAGE_STANDARD "c++98")
                set(CMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LIBRARY "libstdc++")
                set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++98 -stdlib=libstdc++")
            ELSE()
                IF(${OSGEDITOR_CXX_LANGUAGE_STANDARD} STREQUAL "gnu++98" OR ${OSGEDITOR_CXX_LANGUAGE_STANDARD} STREQUAL "GNU++98")
                    set(CMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LANGUAGE_STANDARD "gnu++98")
                    set(CMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LIBRARY "libstdc++")
                    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=gnu++98 -stdlib=libstdc++")
                ELSE()
                    set(CMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LANGUAGE_STANDARD "c++11")
                    set(CMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LIBRARY "libc++")
                    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -stdlib=libc++")
                ENDIF()
            ENDIF()

            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-overloaded-virtual -Wno-conversion")
            set(WARNING_CFLAGS "")
        ENDIF()
ENDIF()

# Search 3rd package by CMake's moduls file, it named findopenscenegraph.cmake, you can set env OSGDIR
find_package(OpenSceneGraph 3.6.3 REQUIRED osgDB osgGA osgUtil osgText osgViewer osgWidget osgQt)

# To select a specific version of QT define DESIRED_QT_VERSION
# via cmake -DDESIRED_QT_VERSION=5
# QUIET option disables messages if the package cannot be found.

find_package(Qt5 COMPONENTS Widgets OpenGL REQUIRED)

# Okay, here's the problem: On some platforms, linking against OpenThreads
# is not enough and explicit linking to the underlying thread library
# is also required (e.g. FreeBSD). But OpenThreads may be built with different
# backends (Pthreads, Sproc, Windows) so we don't know what the underlying
# thread library is because some platforms support multiple backends (e.g.
# IRIX supports Sproc and Pthreads). Linking all libraries won't work
# because the libraries may be incompatible.
# So the current solution is to attempt best guess linking and exempt certain
# cases. With IRIX, we're going to hope explicit linking to the underlying
# library is not necessary. We currently don't case for pthreads on Windows
# which might be an issue on things like Cygwin. This may need to be fixed.

FIND_PACKAGE(Threads)

# Erase CMAKE_THREAD_LIBS_INIT and hope it works
IF(CMAKE_SYSTEM MATCHES IRIX)
    SET(CMAKE_THREAD_LIBS_INIT "" CACHE INTERNAL "")
ENDIF()

# Find OpenGL and windowing system for different sys
IF(APPLE)
    # Trying to get CMake to generate an XCode IPhone project, current efforts are to get iphoneos sdk 3.1 working
    # Added option which needs manually setting to select the IPhone SDK for building. We can only have one of the below
    # set to true. Should realy have an OSGEDITOR_BUILD_PLATFORM variable that we set to our desired platform
    OPTION(OSGEDITOR_BUILD_PLATFORM_IPHONE "Enable IPhoneSDK Device support" OFF)
    OPTION(OSGEDITOR_BUILD_PLATFORM_IPHONE_SIMULATOR "Enable IPhoneSDK Simulator support" OFF)

    IF(OSGEDITOR_BUILD_PLATFORM_IPHONE OR OSGEDITOR_BUILD_PLATFORM_IPHONE_SIMULATOR)

        #you need to manually set the default sdk version here
        SET (IPHONE_SDKVER "6.0" CACHE STRING "IOS SDK-Version")
        SET (IPHONE_VERSION_MIN "4.2" CACHE STRING "IOS minimum os version, use 7.0 or greater to get 64bit support")

        #the below is taken from ogre, it states the gcc stuff needs to happen before PROJECT() is called. I've no clue if we even need it
        # Force gcc <= 4.2 on iPhone
        IF(IPHONE_VERSION_MIN LESS "6.0")
            include(CMakeForceCompiler)
            CMAKE_FORCE_C_COMPILER(llvm-gcc-4.2 GNU)
            CMAKE_FORCE_CXX_COMPILER(llvm-gcc-4.2 GNU)
            SET(GCC_THUMB_SUPPORT NO)
        ENDIF()

        #set either the device sdk or the simulator sdk. Can't find away to separate these in the same project
        IF(OSGEDITOR_BUILD_PLATFORM_IPHONE)
            SET (IPHONE_DEVROOT "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer")
            SET (IPHONE_SDKROOT "${IPHONE_DEVROOT}/SDKs/iPhoneOS${IPHONE_SDKVER}.sdk")
        ELSE()
            SET (IPHONE_DEVROOT "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer")
            SET (IPHONE_SDKROOT "${IPHONE_DEVROOT}/SDKs/iPhoneSimulator${IPHONE_SDKVER}.sdk")
        ENDIF()

        # Apple iOS: Find OpenGLES
        FIND_LIBRARY(OPENGLES_LIBRARY OpenGLES)
    ELSE ()
        FIND_LIBRARY(CARBON_LIBRARY Carbon)
        FIND_LIBRARY(COCOA_LIBRARY Cocoa)

        # Apple OS X: Find OpenGL and AGL based on OSGEDITOR_WINDOWING_SYSTEM
        # This is the accepted way of finding X11/OpenGL on OSX, as
        # documented in CMake's FindOpenGL module.
        # Note that without this check, libosg would use Cocoa/OpenGL but
        # libosgViewer would use X11/OpenGL, which causes compatibility
        # issues for applications using OSG.
        UNSET(OPENGL_gl_LIBRARY CACHE)
        UNSET(OPENGL_glu_LIBRARY CACHE)
        UNSET(OPENGL_INCLUDE_DIR CACHE)
        IF(OSGEDITOR_WINDOWING_SYSTEM STREQUAL "X11")
          FIND_PACKAGE(X11)
          IF(NOT X11_FOUND)
            MESSAGE(FATAL_ERROR "OSGEDITOR_WINDOWING_SYSTEM is X11, but no X11 installation was found. Please make sure X11 is properly installed.")
          ENDIF()

          # Use X11 version of OpenGL as seed for CMake FindOpenGL
          GET_FILENAME_COMPONENT(X11LIBDIR ${X11_X11_LIB} DIRECTORY)
          FIND_LIBRARY(OPENGL_gl_LIBRARY GL PATHS ${X11LIBDIR} DOC "OpenGL lib for OSX" NO_DEFAULT_PATH)
          FIND_LIBRARY(OPENGL_glu_LIBRARY GLU PATHS ${X11LIBDIR} DOC "GLU lib for OSX" NO_DEFAULT_PATH)
          SET(OPENGL_INCLUDE_DIR ${X11_INCLUDE_DIR} CACHE PATH "Include for OpenGL on OSX" FORCE)

        ELSEIF(OSGEDITOR_WINDOWING_SYSTEM STREQUAL "Carbon")
          # AGL needed for Carbon windowing systems
          FIND_LIBRARY(AGL_LIBRARY AGL)
        ENDIF()

        FIND_PACKAGE(OpenGL)
        add_definitions(-DGL_DO_NOT_WARN_IF_MULTI_GL_VERSION_HEADERS_INCLUDED)
    ENDIF ()

    OPTION(OSGEDITOR_COMPILE_FRAMEWORKS "compile frameworks instead of dylibs (experimental)" OFF)
    SET(OSGEDITOR_COMPILE_FRAMEWORKS_INSTALL_NAME_DIR "@executable_path/../Frameworks" CACHE STRING "install name dir for compiled frameworks")
ELSE()
    # Non-Apple: Find OpenGL
    FIND_PACKAGE(OpenGL)
ENDIF()

INCLUDE_DIRECTORIES(
    ${OPENSCENEGRAPH_INCLUDE_DIRS}
    ${CMAKE_CURRENT_LIST_DIR}/include
    ${CMAKE_CURRENT_BINARY_DIR}/src
    ${OPENGL_INCLUDE_DIR}
)

# There are some default configurations
# Change the default build type to Release
IF(NOT CMAKE_BUILD_TYPE)
    SET(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build, options are: None Debug Release RelWithDebInfo MinSizeRel." FORCE)
ENDIF(NOT CMAKE_BUILD_TYPE)

# if you are maintainer, you should make tag or run test or so on.
OPTION(OSGEDITOR_MAINTAINER "Enable ${PROJECT_NAME} maintainer build methods, such as making git branches, tags, updating ChangeLog." OFF)
IF (OSGEDITOR_MAINTAINER)

    SET(OSGEDITOR_BRANCH ${PROJECT_NAME}-${OSGEDITOR_MAJOR_VERSION}.${OSGEDITOR_MINOR_VERSION})

    #
    # Provide target for tagging a release
    #
    SET(GITCOMMAND git)

    IF   (OPENSCENEGRAPH_RELEASE_CANDIDATE EQUAL 0)
        SET(RELEASE_NAME ${PROJECT_NAME}-${OSGEDITOR_VERSION})
    ELSE()
        SET(RELEASE_NAME ${PROJECT_NAME}-${OSGEDITOR_VERSION}-rc${OSGEDITOR_RELEASE_CANDIDATE})
    ENDIF()

    SET(RELEASE_MESSAGE "Release ${RELEASE_NAME}")
    SET(BRANCH_MESSAGE "Branch ${OSGEDITOR_BRANCH}")


    ADD_CUSTOM_TARGET(tag-test
        COMMAND echo ${GITCOMMAND} tag -a ${RELEASE_NAME} -m ${RELEASE_MESSAGE}
        COMMAND echo ${GITCOMMAND} push origin ${RELEASE_NAME}
    )

    ADD_CUSTOM_TARGET(tag-run
        COMMAND ${GITCOMMAND} tag -a ${RELEASE_NAME} -m ${RELEASE_MESSAGE}
        COMMAND ${GITCOMMAND} push origin ${RELEASE_NAME}
    )

    ADD_CUSTOM_TARGET(branch-test
        COMMAND echo ${GITCOMMAND} branch ${OSGEDITOR_BRANCH} -m ${BRANCH_MESSAGE}
        COMMAND echo ${GITCOMMAND} push origin ${OSGEDITOR_BRANCH}
    )

    ADD_CUSTOM_TARGET(branch-run
        COMMAND ${GITCOMMAND} branch ${OSGEDITOR_BRANCH} -m ${BRANCH_MESSAGE}
        COMMAND ${GITCOMMAND} push origin ${OSGEDITOR_BRANCH}
    )

    #
    # Provide target for generating ChangeLog
    #
    SET(GITLOGFORMAT "%aD%nAuthor : %an%n%s%b%n")
    SET(GENERATELOGS git log --pretty=format:${GITLOGFORMAT})

    ADD_CUSTOM_TARGET(ChangeLog
        COMMAND ${GENERATELOGS} > ChangeLog
    )

ENDIF(OSGEDITOR_MAINTAINER)

# Common global definitions
#ADD_DEFINITIONS(-D)
# Platform specific definitions

IF(WIN32 AND NOT ANDROID)

    IF(MSVC)
        # This option is to enable the /MP switch for Visual Studio 2005 and above compilers
        OPTION(WIN32_USE_MP "Set to ON to build OpenSceneGraph with the /MP option (Visual Studio 2005 and above)." OFF)
        MARK_AS_ADVANCED(WIN32_USE_MP)
        IF(WIN32_USE_MP)
            SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /MP")
        ENDIF(WIN32_USE_MP)

        # turn off various warnings
        # foreach(warning 4244 4251 4267 4275 4290 4786 4305 4996)
        #     SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /wd${warning}")
        # endforeach(warning)

        # This option is to enable the /DYNAMICBASE switch
        # It is used to workaround a bug in Windows 7 when linking in release, which results in corrupt
        # binaries. See this page for details: http://www.wintellect.com/CS/blogs/jrobbins/archive/2009/01/24/the-case-of-the-corrupt-pe-binaries.aspx
        OPTION(WIN32_USE_DYNAMICBASE "Set to ON to build OpenSceneGraph with the /DYNAMICBASE option to work around a bug when linking release executables on Windows 7." OFF)
        MARK_AS_ADVANCED(WIN32_USE_DYNAMICBASE)
        IF(WIN32_USE_DYNAMICBASE)
            SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /DYNAMICBASE")
        ENDIF(WIN32_USE_DYNAMICBASE)

        # More MSVC specific compilation flags
        ADD_DEFINITIONS(-D_SCL_SECURE_NO_WARNINGS)
        ADD_DEFINITIONS(-D_CRT_SECURE_NO_DEPRECATE)

        OPTION(MSVC_DISABLE_CHECKED_ITERATORS "Set to ON to disable Visual C++ checked iterators. If you do this you must ensure that every other project in your solution and all dependencies are compiled with _SECURE_SCL=0." OFF)
        MARK_AS_ADVANCED(MSVC_DISABLE_CHECKED_ITERATORS)
        IF(MSVC_DISABLE_CHECKED_ITERATORS)
            ADD_DEFINITIONS(-D_SECURE_SCL=0)
        ENDIF(MSVC_DISABLE_CHECKED_ITERATORS)

        OPTION(MSVC_USE_DEFAULT_STACK_SIZE "Set to ON to use the default Visual C++ stack size. CMake forces a high stack size by default, which can cause problems for applications with large number of threads." OFF)
        MARK_AS_ADVANCED(MSVC_USE_DEFAULT_STACK_SIZE)
        IF(MSVC_USE_DEFAULT_STACK_SIZE)
            STRING(REGEX REPLACE "/STACK:[0-9]+" "" CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS}")
            STRING(REGEX REPLACE "/STACK:[0-9]+" "" CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS}")
            STRING(REGEX REPLACE "/STACK:[0-9]+" "" CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS}")
        ENDIF(MSVC_USE_DEFAULT_STACK_SIZE)
        get_filename_component( CMAKE_MAKE_PROGRAM_NAME ${CMAKE_MAKE_PROGRAM} NAME)
        IF (CMAKE_MAKE_PROGRAM_NAME STREQUAL "VCExpress.exe")
            OPTION(MSVC_BUILD_USE_SOLUTION_FOLDERS "Enable project grouping in VS - VCExpress detected, not supported in VCExpress )" OFF)
        ELSE()
            OPTION(MSVC_BUILD_USE_SOLUTION_FOLDERS "Enable project grouping in VS" ON)
        ENDIF()
        SET_PROPERTY(GLOBAL PROPERTY USE_FOLDERS ${MSVC_BUILD_USE_SOLUTION_FOLDERS})
    ENDIF()

    #needed for net plugin
    SET (OSGEDITOR_SOCKET_LIBS wsock32)
    # Both Cygwin and Msys need -DNOMINMAX ???
    IF(UNIX)
        ADD_DEFINITIONS(-DNOMINMAX)
    ENDIF()

########################################################################################################
# the following options are MSVC specific,
# the first OSGEDITOR_MSVC_VERSIONED_DLL activate a custom build-time layout that should allow to run examples and application
# from bin folder without requiring installation step.
# it also prepend "osg${OPENSCENEGRAPH_SOVERSION}-" to only .dll files, leaving .lib files untouched in lib
# it also use a hack to get rid of Debug and Release folder in MSVC projects
# all the .dll and .pdb are in bin and all the .lib and .exp are in lib
#
# the second option disable incremental linking in debug build , that is enabled by default by CMake
##########################################################################################################

    IF(MSVC)
        IF(${CMAKE_MAJOR_VERSION} EQUAL 2 AND ${CMAKE_MINOR_VERSION} EQUAL 4 AND ${CMAKE_PATCH_VERSION} LESS 7)
            MESSAGE("Warning:  disabling versioned options 2.4.6 exibits inconsintencies in .pdb naming, at least under MSVC, suggested upgrading at least to 2.4.7")
            SET(OSGEDITOR_MSVC_VERSIONED_DLL OFF)
            SET(OSGEDITOR_MSVC_DEBUG_INCREMENTAL_LINK ON)
        ELSE()
            OPTION(OSGEDITOR_MSVC_VERSIONED_DLL "Set to ON to build OpenSceneGraph with versioned dll names" ON)
            MARK_AS_ADVANCED(OSGEDITOR_MSVC_VERSIONED_DLL)
            OPTION(OSGEDITOR_MSVC_DEBUG_INCREMENTAL_LINK "Set to OFF to build OpenSceneGraph without incremental linking in debug (release is off by default)" ON)
            MARK_AS_ADVANCED(OSGEDITOR_MSVC_DEBUG_INCREMENTAL_LINK)
            IF(NOT OSGEDITOR_MSVC_DEBUG_INCREMENTAL_LINK)
                SET(CMAKE_MODULE_LINKER_FLAGS_DEBUG "/debug /INCREMENTAL:NO")
                SET(CMAKE_SHARED_LINKER_FLAGS_DEBUG "/debug /INCREMENTAL:NO")
                SET(CMAKE_EXE_LINKER_FLAGS_DEBUG "/debug /INCREMENTAL:NO")
            ENDIF(NOT OSGEDITOR_MSVC_DEBUG_INCREMENTAL_LINK)
        ENDIF()
    ENDIF(MSVC)
ENDIF(WIN32 AND NOT ANDROID)


################################################################################
# Installation stuff

SET(CMAKE_DEBUG_POSTFIX "d" CACHE STRING "add a postfix, usually d on windows")
SET(CMAKE_RELEASE_POSTFIX "" CACHE STRING "add a postfix, usually empty on windows")
SET(CMAKE_RELWITHDEBINFO_POSTFIX "rd" CACHE STRING "add a postfix, usually empty on windows")
SET(CMAKE_MINSIZEREL_POSTFIX "s" CACHE STRING "add a postfix, usually empty on windows")

# Set the build postfix extension according to what configuration is being built.
IF (CMAKE_BUILD_TYPE MATCHES "Release")
    SET(CMAKE_BUILD_POSTFIX "${CMAKE_RELEASE_POSTFIX}")
ELSEIF (CMAKE_BUILD_TYPE MATCHES "MinSizeRel")
    SET(CMAKE_BUILD_POSTFIX "${CMAKE_MINSIZEREL_POSTFIX}")
ELSEIF(CMAKE_BUILD_TYPE MATCHES "RelWithDebInfo")
    SET(CMAKE_BUILD_POSTFIX "${CMAKE_RELWITHDEBINFO_POSTFIX}")
ELSEIF(CMAKE_BUILD_TYPE MATCHES "Debug")
    SET(CMAKE_BUILD_POSTFIX "${CMAKE_DEBUG_POSTFIX}")
ELSE()
    SET(CMAKE_BUILD_POSTFIX "")
ENDIF()

IF(UNIX AND NOT WIN32)
  SET(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -D_DEBUG")
  SET(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -D_DEBUG")
ENDIF()

IF(CYGWIN)
  SET(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -D_DEBUG")
  SET(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -D_DEBUG")
ENDIF()

IF(UNIX AND NOT WIN32 AND NOT APPLE)
  IF(CMAKE_SIZEOF_VOID_P MATCHES "8")
      SET(LIB_POSTFIX "64" CACHE STRING "suffix for 32/64 dir placement")
      MARK_AS_ADVANCED(LIB_POSTFIX)
  ENDIF()
ENDIF()
IF(NOT DEFINED LIB_POSTFIX)
    SET(LIB_POSTFIX "")
ENDIF()

# Here we apparantly do some funky stuff with making the bin/ and lib/
# folders which is probably needed to work around a very old CMake bug?

#SET(OUTPUT_BINDIR ${PROJECT_BINARY_DIR}/bin/${CMAKE_SYSTEM_NAME})
SET(OUTPUT_BINDIR ${PROJECT_BINARY_DIR}/bin)
MAKE_DIRECTORY(${OUTPUT_BINDIR})

#SET(OUTPUT_LIBDIR ${PROJECT_BINARY_DIR}/lib/${CMAKE_SYSTEM_NAME})
SET(OUTPUT_LIBDIR ${PROJECT_BINARY_DIR}/lib)
MAKE_DIRECTORY(${OUTPUT_LIBDIR})

# On CMake 2.4.x use EXECUTABLE_OUTPUT_PATH and LIBRARY_OUTPUT_PATH and later
# we work around the DLL placement by use of the PREFIX target property hack
#
# On CMake 2.6.x use the newly minted CMAKE_LIBRARY_OUTPUT_DIRECTORY,
# CMAKE_ARCHIVE_OUTPUT_DIRECTORY & CMAKE_RUNTIME_OUTPUT_DIRECTORY
#
# CMake >= 2.8.1 changed the output directory algorithm (See doc).
# Here we also set per-configuration directories (CMAKE_*_OUTPUT_DIRECTORY_<CONFIG>), or else binaries are generated in /bin/Debug and /bin/Release, etc. with MSVC and Xcode.
# (Doc reads "multi-configuration generators (VS, Xcode) do NOT append a per-configuration subdirectory to the specified directory").
# The workaround for 2.6.x (adding "../" as an output prefix for each target) seem to have no effect in >=2.8.1, so there is no need to change this.
IF(CMAKE_MAJOR_VERSION EQUAL 2 AND CMAKE_MINOR_VERSION LESS 5)
    # If CMake < 2.6.0
    SET(EXECUTABLE_OUTPUT_PATH ${OUTPUT_BINDIR})
    SET(LIBRARY_OUTPUT_PATH    ${OUTPUT_LIBDIR})
ELSE()
    # If CMake >= 2.6.0
    SET(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${OUTPUT_LIBDIR})
    SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${OUTPUT_BINDIR})
    IF(WIN32)
        SET(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${OUTPUT_BINDIR})
    ELSE(WIN32)
        SET(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${OUTPUT_LIBDIR})
    ENDIF(WIN32)

    # Testing CMAKE_VERSION is possible in >= 2.6.4 only
    BUILDER_VERSION_GREATER(2 8 0)
    IF(VALID_BUILDER_VERSION)  # If CMake >= 2.8.1
        FOREACH(CONF ${CMAKE_CONFIGURATION_TYPES})        # For each configuration (Debug, Release, MinSizeRel... and/or anything the user chooses)
            STRING(TOUPPER "${CONF}" CONF)                # Go uppercase (DEBUG, RELEASE...)
            SET("CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${CONF}" "${OUTPUT_LIBDIR}")
            SET("CMAKE_RUNTIME_OUTPUT_DIRECTORY_${CONF}" "${OUTPUT_BINDIR}")
            IF(WIN32)
                SET("CMAKE_LIBRARY_OUTPUT_DIRECTORY_${CONF}" "${OUTPUT_BINDIR}")
            ELSE()
                SET("CMAKE_LIBRARY_OUTPUT_DIRECTORY_${CONF}" "${OUTPUT_LIBDIR}")
            ENDIF()
        ENDFOREACH()
    ENDIF(VALID_BUILDER_VERSION)
ENDIF()

# This part is for the CMake menu option to toggle the warnings on/off.
# This will only be made available if we set values for OSGEDITOR_AGGRESSIVE_WARNING_FLAGS.
IF(OSGEDITOR_AGGRESSIVE_WARNING_FLAGS)

    SET(OSGEDITOR_AGGRESSIVE_WARNING_FLAGS ${OSGEDITOR_AGGRESSIVE_WARNING_FLAGS} CACHE STRING "Compiler flags to use when OSGEDITOR_AGGRESSIVE_WARNINGS is enabled." FORCE)

    IF (APPLE)
        SET(DEFAULT_USE_AGGRESSIVE_WARNINGS OFF)
    ELSE()
        SET(DEFAULT_USE_AGGRESSIVE_WARNINGS ON)
    ENDIF()

    OPTION(OSGEDITOR_AGGRESSIVE_WARNINGS "Enable to activate aggressive warnings" ${DEFAULT_USE_AGGRESSIVE_WARNINGS})

    IF(OSGEDITOR_AGGRESSIVE_WARNINGS)
        # Add flags defined by OSGEDITOR_AGGRESSIVE_WARNING_FLAGS if they aren't already there
        FOREACH(flag ${OSGEDITOR_AGGRESSIVE_WARNING_FLAGS})
            IF(NOT CMAKE_CXX_FLAGS MATCHES "${flag}")
                SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${flag}")
            ENDIF()
        ENDFOREACH()
    ELSE()
        # Remove all flags considered aggresive
        FOREACH(flag ${OSGEDITOR_AGGRESSIVE_WARNING_FLAGS})
            STRING(REGEX REPLACE "${flag}" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
        ENDFOREACH()
    ENDIF()
ENDIF()

IF(APPLE)

        #Here we check if the user specified IPhone SDK
    IF(OSGEDITOR_BUILD_PLATFORM_IPHONE OR OSGEDITOR_BUILD_PLATFORM_IPHONE_SIMULATOR)

        #set iphone arch and flags taken from http://sites.google.com/site/michaelsafyan/coding/resources/how-to-guides/cross-compile-for-the-iphone/how-to-cross-compile-for-the-iphone-using-cmake
        IF(OSGEDITOR_BUILD_PLATFORM_IPHONE)
            IF(${IPHONE_VERSION_MIN} LESS "7.0")
                SET(CMAKE_OSX_ARCHITECTURES "armv6;armv7" CACHE STRING "Build architectures for iOS" FORCE)
                SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mno-thumb -pipe -no-cpp-precomp" CACHE STRING "Flags used by the compiler during all build types." FORCE)
            ELSE()
                SET(CMAKE_OSX_ARCHITECTURES "armv7;armv7s;arm64" CACHE STRING "Build architectures for iOS" FORCE)
                SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pipe -no-cpp-precomp" CACHE STRING "Flags used by the compiler during all build types." FORCE)
            ENDIF()

            SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -miphoneos-version-min=${IPHONE_VERSION_MIN}" FORCE)

        ELSE()
            #simulator uses i386 architectures
            SET(CMAKE_OSX_ARCHITECTURES "i386" CACHE STRING "Build architectures for iOS Simulator" FORCE)
            SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mno-thumb -arch i386 -pipe -no-cpp-precomp" CACHE STRING "Flags used by the compiler during all build types." FORCE)

            SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mios-simulator-version-min=${IPHONE_VERSION_MIN}" FORCE)

        ENDIF()

        #here we set the specific iphone sdk version. We can only set either device or simulator sdk. So if you want both you currently have to have two seperate projects
        SET(CMAKE_OSX_SYSROOT "${IPHONE_SDKROOT}" CACHE STRING "System root for iOS" FORCE)

        #hack, force link to opengles
        set(CMAKE_EXE_LINKER_FLAGS "-framework Foundation -framework OpenGLES")

        #use the IPhone windowing system
        SET(OSGEDITOR_WINDOWING_SYSTEM "IOS" CACHE STRING "Forced IPhone windowing system on iOS"  FORCE)
        SET(OSGEDITOR_DEFAULT_IMAGE_PLUGIN_FOR_OSX "imageio" CACHE STRING "Forced imageio default image plugin for iOS" FORCE)

        #I think this or similar will be required for IPhone apps
        OPTION(OSGEDITOR_BUILD_APPLICATION_BUNDLES "Enable the building of applications and examples as OSX Bundles" ON)

    ELSE()

        # Set defaults for Universal Binaries. We want 32-bit Intel/PPC on 10.4
        # and 32/64-bit Intel/PPC on >= 10.5. Anything <= 10.3 doesn't support.

        # These are just defaults/recommendations, but how we want to build
        # out of the box. But the user needs to be able to change these options.
        # So we must only set the values the first time CMake is run, or we
        # will overwrite any changes the user sets.
        # FORCE is used because the options are not reflected in the UI otherwise.
        # Seems like a good place to add version specific compiler flags too.
        IF(NOT OSGEDITOR_CONFIG_HAS_BEEN_RUN_BEFORE)
          IF(OSGEDITOR_OSX_VERSION VERSION_GREATER 10.7)
            SET(OSGEDITOR_DEFAULT_IMAGE_PLUGIN_FOR_OSX "imageio" CACHE STRING "Forced imageio default image plugin for OSX" FORCE)
            SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fvisibility-inlines-hidden" CACHE STRING "Flags used by the compiler during all build types." FORCE)
          ELSEIF(OSGEDITOR_OSX_VERSION VERSION_EQUAL 10.7)
            SET(OSGEDITOR_DEFAULT_IMAGE_PLUGIN_FOR_OSX "imageio" CACHE STRING "Forced imageio default image plugin for OSX" FORCE)
            SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fvisibility-inlines-hidden" CACHE STRING "Flags used by the compiler during all build types." FORCE)
          ELSEIF(OSGEDITOR_OSX_VERSION VERSION_GREATER 10.4)
            SET(OSGEDITOR_DEFAULT_IMAGE_PLUGIN_FOR_OSX "imageio" CACHE STRING "Forced imageio default image plugin for OSX" FORCE)
            SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ftree-vectorize -fvisibility-inlines-hidden" CACHE STRING "Flags used by the compiler during all build types." FORCE)
          ELSEIF(OSGEDITOR_OSX_VERSION VERSION_EQUAL 10.4)
            SET(OSGEDITOR_DEFAULT_IMAGE_PLUGIN_FOR_OSX "quicktime" CACHE STRING "Forced imageio default image plugin for OSX" FORCE)
            SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ftree-vectorize -fvisibility-inlines-hidden" CACHE STRING "Flags used by the compiler during all build types." FORCE)
          ENDIF()
        ENDIF()

        OPTION(OSGEDITOR_BUILD_APPLICATION_BUNDLES "Enable the building of applications and examples as OSX Bundles" OFF)

    ENDIF()

ENDIF()

add_subdirectory(src)


# For Doxygen
INCLUDE(${CMAKE_ROOT}/Modules/Documentation.cmake OPTIONAL)
OPTION(BUILD_DOCUMENTATION "Build OpenSceneGraph reference documentation using doxygen (use: make doc_openscenegraph doc_openthreads)" OFF)
MARK_AS_ADVANCED(CLEAR BUILD_DOCUMENTATION)
# To build the documention, you will have to enable it
# and then do the equivalent of "make doc_openscenegraph doc_openthreads".
IF(BUILD_DOCUMENTATION)

    OPTION(BUILD_REF_DOCS_SEARCHENGINE "Enable doxygen's search engine (requires that documentation to be installed on a php enabled web server)" OFF)
    IF(BUILD_REF_DOCS_SEARCHENGINE)
        SET(SEARCHENGINE YES)
    ELSE()
        SET(SEARCHENGINE NO)
    ENDIF()

    OPTION(BUILD_REF_DOCS_TAGFILE "Generate a tag file named osg.tag on the documentation web server" OFF)
    IF(BUILD_REF_DOCS_TAGFILE)
        SET(GENERATE_TAGFILE "${OpenSceneGraph_BINARY_DIR}/doc/OpenSceneGraphReferenceDocs/osg.tag")
    ELSE()
        SET(GENERATE_TAGFILE "")
    ENDIF()

    IF(DOT)
        SET(HAVE_DOT YES)
    ELSE()
        SET(HAVE_DOT NO)
    ENDIF()

    # If html help generation was requested. DOCUMENTATION_HTML_HELP is defined by Documentation.cmake
    SET(GENERATE_HTMLHELP "NO")
    IF(DOCUMENTATION_HTML_HELP)
        # on windows Documentation.cmake finds the html help workshop if it exists. On u*ix we might have it with wine but no way to point it out
        IF(NOT WIN32)
            SET(HTML_HELP_COMPILER "" CACHE FILEPATH "Enter location of the HTML help compiler to let doxygen compile html")
            MARK_AS_ADVANCED(HTML_HELP_COMPILER)
        ENDIF()
        # this var sets a proper value in .doxygen files when configuring them below
        SET(GENERATE_HTMLHELP "YES")
    endif()

    # This processes our doxyfile.cmake and substitutes paths to generate
    # a final Doxyfile
    CONFIGURE_FILE(${PROJECT_SOURCE_DIR}/doc/Doxyfiles/doxyfile.cmake
        ${PROJECT_BINARY_DIR}/doc/openscenegraph.doxyfile
    )
    # copy the osg logo to documentations target folder
    CONFIGURE_FILE(${PROJECT_SOURCE_DIR}/PlatformSpecifics/Windows/icons/src/osg32-32.png
        ${PROJECT_BINARY_DIR}/doc/OpenSceneGraphReferenceDocs/osg32-32.png COPYONLY
    )
    #INSTALL(FILES ${PROJECT_BINARY_DIR}/doc/${PROJECT_NAME}ReferenceDocs-${OPENSCENEGRAPH_VERSION}.chm DESTINATION doc OPTIONAL COMPONENT openscenegraph-doc)
    INSTALL(DIRECTORY ${PROJECT_BINARY_DIR}/doc/OpenSceneGraphReferenceDocs DESTINATION doc COMPONENT openscenegraph-doc)

    # now set up openthreads documentation generation
    IF(BUILD_REF_DOCS_TAGFILE)
        SET(GENERATE_TAGFILE "${OpenSceneGraph_BINARY_DIR}/doc/OpenThreadsReferenceDocs/ot.tag")
    ENDIF()

    # copy the osg logo to documentations target folder
    CONFIGURE_FILE(${PROJECT_SOURCE_DIR}/PlatformSpecifics/Windows/icons/src/osg32-32.png
        ${PROJECT_BINARY_DIR}/doc/OpenThreadsReferenceDocs/osg32-32.png COPYONLY
    )
    #INSTALL(FILES ${PROJECT_BINARY_DIR}/doc/${PROJECT_NAME}ReferenceDocs-${OPENSCENEGRAPH_VERSION}.chm DESTINATION doc OPTIONAL COMPONENT openscenegraph-doc)
    INSTALL(DIRECTORY ${PROJECT_BINARY_DIR}/doc/OpenThreadsReferenceDocs DESTINATION doc COMPONENT openthreads-doc)

    # Process our other doxyfiles but don't create targets for these
    CONFIGURE_FILE(${PROJECT_SOURCE_DIR}/doc/Doxyfiles/all_Doxyfile
        ${PROJECT_BINARY_DIR}/doc/all_Doxyfile)
    CONFIGURE_FILE(${PROJECT_SOURCE_DIR}/doc/Doxyfiles/auto_Doxyfile
        ${PROJECT_BINARY_DIR}/doc/auto_Doxyfile)
    CONFIGURE_FILE(${PROJECT_SOURCE_DIR}/doc/Doxyfiles/core_Doxyfile
        ${PROJECT_BINARY_DIR}/doc/core_Doxyfile)

    # This creates a new target to build documentation.
    # It runs ${DOXYGEN} which is the full path and executable to
    # Doxygen on your system, set by the FindDoxygen.cmake module
    # (called by FindDocumentation.cmake).
    # It runs the final generated Doxyfile against it.
    # The DOT_PATH is substituted into the Doxyfile.
    ADD_CUSTOM_TARGET(doc_openscenegraph ${DOXYGEN}
        ${PROJECT_BINARY_DIR}/doc/openscenegraph.doxyfile
    )
    SET_TARGET_PROPERTIES(doc_openscenegraph PROPERTIES FOLDER "Documentation")

    ADD_CUSTOM_TARGET(doc_openthreads ${DOXYGEN}
        ${PROJECT_BINARY_DIR}/doc/openthreads.doxyfile
    )
    SET_TARGET_PROPERTIES(doc_openthreads PROPERTIES FOLDER "Documentation")
ENDIF(BUILD_DOCUMENTATION)

# Run this as late as possible so users can easier spot the message
IF (NOT DEFINED REQUIRES_LIBPATH_MESSAGE AND ${CMAKE_INSTALL_PREFIX} STREQUAL "/usr/local")
    SET(REQUIRES_LIBPATH_MESSAGE ON)
ENDIF()

IF(REQUIRES_LIBPATH_MESSAGE)
    IF (NOT OSGEDITOR_LIBPATH_MESSAGE_HAS_BEEN_RUN_BEFORE)
        SET(OSGEDITOR_LIBPATH_MESSAGE_HAS_BEEN_RUN_BEFORE 1 CACHE INTERNAL "Flag to track whether the libpath message has been reported before")

        MESSAGE("\nThe build system is configured to install libraries to ${CMAKE_INSTALL_PREFIX}/lib${LIB_POSTFIX}\n"
            "Your applications may not be able to find your installed libraries unless you:\n"
            "    set your LD_LIBRARY_PATH (user specific) or\n"
            "    update your ld.so configuration (system wide)")
        IF(IS_DIRECTORY /etc/ld.so.conf.d AND EXISTS ${PROJECT_SOURCE_DIR}/packaging/ld.so.conf.d/openscenegraph-osgQt.conf.in)
            MESSAGE("You have an ld.so.conf.d directory on your system, so if you wish to ensure that\n"
                "applications find the installed osg libraries, system wide, you could install an\n"
                "OpenSceneGraph specific ld.so configuration with:\n"
                "    sudo make install_ld_conf\n")
            CONFIGURE_FILE(${PROJECT_SOURCE_DIR}/packaging/ld.so.conf.d/openscenegraph-osgQt.conf.in
                ${PROJECT_BINARY_DIR}/packaging/ld.so.conf.d/openscenegraph-osgQt.conf
            )
            ADD_CUSTOM_TARGET(install_ld_conf ${CMAKE_COMMAND} -E copy_if_different
                ${PROJECT_BINARY_DIR}/packaging/ld.so.conf.d/openscenegraph-osgQt.conf
                /etc/ld.so.conf.d/openscenegraph-osgQt.conf
                COMMAND ldconfig
                COMMENT "Copying openscenegraph-osgQt.conf to /etc/ld.so.conf.d and running ldconfig"
            )
        ELSE()
            IF(EXISTS /etc/ld.so.conf)
                MESSAGE("You have an ld.so.conf file in /etc, if you wish to ensure \n"
                "that applications find the installed osg libraries, system wide, you\n"
                "could add ${CMAKE_INSTALL_PREFIX}/lib${LIB_POSTFIX} to it.")
            ENDIF()
        ENDIF()

        # emit a message during installation.
        INSTALL(CODE "MESSAGE(\"Libraries were installed to ${CMAKE_INSTALL_PREFIX}lib${LIB_POSTFIX}.\\nYou may need to update your ld.so configuration. \")")

    ENDIF(NOT OSGEDITOR_LIBPATH_MESSAGE_HAS_BEEN_RUN_BEFORE)

ELSE()
    SET(OSGEDITOR_LIBPATH_MESSAGE_HAS_BEEN_RUN_BEFORE 0 CACHE INTERNAL "Flag to track whether the libpath message has been reported before")
ENDIF()


# This needs to be run very last so other parts of the scripts can take
# advantage of this.
IF(NOT OSGEDITOR_CONFIG_HAS_BEEN_RUN_BEFORE)
    SET(OSGEDITOR_CONFIG_HAS_BEEN_RUN_BEFORE 1 CACHE INTERNAL "Flag to track whether this is the first time running CMake or if CMake has been configured before")
ENDIF()

#-----------------------------------------------------------------------------
### uninstall target
#-----------------------------------------------------------------------------
CONFIGURE_FILE(
  "${CMAKE_CURRENT_SOURCE_DIR}/CMakeModules/cmake_uninstall.cmake.in"
  "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
  IMMEDIATE @ONLY)
ADD_CUSTOM_TARGET(uninstall
  "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake")

#




