cmake_minimum_required(VERSION 3.16)

project(AppDAE VERSION 1.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2 Network)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appAppDAE
    main.cpp
    daeclient.h
    daeclient.cpp
)

qt_add_qml_module(appAppDAE
    URI AppDAE
    NO_IMPORT_SCAN
    QML_FILES
        Main.qml
        HorarioView.qml
        ExpedienteView.qml
        TranscritasView.qml
        PerfilView.qml
        servicios/VisualizarRapView.qml
        servicios/SolicitudConstanciasView.qml
        servicios/CarnetUniversitarioView.qml
        servicios/OfertaHorariosView.qml
        servicios/CalendarioView.qml
        servicios/PensumEstudioView.qml
        servicios/ReglamentoEvaluacionView.qml
        servicios/CambioEscuelaView.qml
        servicios/InscripcionView.qml
        servicios/RetiroAsignaturaView.qml
        servicios/MapaFacultadView.qml
        servicios/SalonesDisponiblesView.qml
        servicios/RecordatoriosView.qml
    RESOURCES
        servicios/logo_uc.png
        servicios/logo_ing.png
        servicios/mapa_facultad.png
        servicios/horarios_base.html
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appAppDAE PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appAppDAE
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

if(ANDROID)
    # Plantilla Android propia: ícono de la Facultad y nombre "DAE ING"
    set_property(TARGET appAppDAE PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android")

    # Búsqueda flexible de OpenSSL para Android:
    # 1) Variable CMake -DANDROID_OPENSSL_DIR=...
    # 2) Variable de entorno ANDROID_OPENSSL_DIR
    # 3) Rutas estándar en el directorio del usuario
    set(_openssl_cmake "")
    foreach(_dir
        "${ANDROID_OPENSSL_DIR}"
        "$ENV{ANDROID_OPENSSL_DIR}"
        "$ENV{HOME}/Android/android_openssl"
        "$ENV{USERPROFILE}/Android/android_openssl"
        "/home/emmanuel/Android/android_openssl")
        if(_dir AND EXISTS "${_dir}/android_openssl.cmake")
            set(_openssl_cmake "${_dir}/android_openssl.cmake")
            break()
        endif()
    endforeach()

    if(_openssl_cmake)
        include("${_openssl_cmake}")
        add_android_openssl_libraries(appAppDAE)
    else()
        message(WARNING "No se encontró android_openssl.cmake. Define ANDROID_OPENSSL_DIR para habilitar HTTPS en Android.")
    endif()
endif()

target_link_libraries(appAppDAE
    PRIVATE Qt6::Quick Qt6::QuickControls2 Qt6::Network
)

include(GNUInstallDirs)
install(TARGETS appAppDAE
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
