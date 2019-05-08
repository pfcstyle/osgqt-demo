AUX_SOURCE_DIRECTORY(. TARGET_SRC)

SET(TARGET_LIBRARIES_VARS
    OSG_LIBRARY
    OSGUTIL_LIBRARY
    OSGVIEWER_LIBRARY
    OSGGA_LIBRARY
    OSGDB_LIBRARY
    OPENTHREADS_LIBRARY
)

macro( config_project PROJECTNAME LIBNAME)
    include_directories(${${LIBNAME}_INCLUDE_DIR})
    target_link_libraries(${PROJECTNAME} ${${LIBNAME}_LIBRARY})
endmacro()

# add_executable()
# config_project()


SET (EXAMPLE_NAME osgviewerQt )

SETUP_EXAMPLE( ${EXAMPLE_NAME} )

SET(TARGET_LIBRARIES Qt5::Widgets Qt5::OpenGL)

target_link_libraries(example_${EXAMPLE_NAME} osgQOpenGL)

qt5_use_modules( example_${EXAMPLE_NAME} Widgets OpenGL )

