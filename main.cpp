/**
 * Punto de entrada de AppDAE: inicializa la aplicación Qt Quick con el estilo
 * Material, registra el cliente DAE en el contexto QML y habilita la ventana
 * de borde a borde (pantalla completa bajo barras transparentes).
 */
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include "daeclient.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationVersion("1.1");

    // Estilo Material para controles nativos consistentes en Android
    QQuickStyle::setStyle("Material");

    // Instancia única del controlador de red, sesión, caché y utilidades nativas
    DaeClient clienteDae;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("daeClient", &clienteDae);

    // Si la carga del módulo QML principal falla, cerramos limpiamente la app
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("AppDAE", "Main");

    // Reforzamos las banderas de cliente expandido para dibujar detrás de las barras del sistema
    if (!engine.rootObjects().isEmpty()) {
        if (auto *win = qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst())) {
            win->setFlags(win->flags() | Qt::ExpandedClientAreaHint | Qt::NoTitleBarBackgroundHint);
        }
    }

    return app.exec();
}
