AUX_SOURCE_DIRECTORY(. TARGET_SRC)
# SET( TARGET_SRC
#     osgviewerQt.cpp
# )
SET(TARGET_LIBRARIES  ${OPENSCENEGRAPH_LIBRARIES})
SET ( EXAMPLE_NAME osgviewerQt )

SETUP_EXAMPLE( ${EXAMPLE_NAME} )

# include_directories(${ACTUAL_3DPARTY_DIR}/include/osgQt)
# link_directories(${ACTUAL_3DPARTY_DIR}/lib)
# set(OSGQT ${ACTUAL_3DPARTY_DIR}/lib/libosgQt.dylib)
# target_link_libraries(${TARGET_TARGETNAME} ${OSGQT})

qt5_use_modules( example_${EXAMPLE_NAME} Widgets OpenGL )

