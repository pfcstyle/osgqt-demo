
find_path(OSGQT5_INCLUDE_DIR 
    NAMES
        Export
        GraphicsWindowQt
        QFontImplementation
        QGraphicsViewAdapter
        QWebViewImage
        QWidgetImage
    PATHS
        ${ACTUAL_3DPARTY_DIR}/include
)

find_library(OSGQT5_LIBRARY
    NAMES
        osgQt5
    PATHS
        ${ACTUAL_3DPARTY_DIR}/lib
)

find_library(OSGQT5_LIBRARY_DEBUG
    NAMES
        osgQt5d
    PATHS
        ${ACTUAL_3DPARTY_DIR}/lib
)