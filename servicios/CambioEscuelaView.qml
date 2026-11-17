import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts

Item {
    id: rootCambioEscuela

    signal volver()

    property string codigoDestinoSeleccionado: ""
    property string nombreDestinoSeleccionado: ""
    property bool selectorAbierto: false
    property bool modalConfirmacionAbierto: false

    onVisibleChanged: {
        if (visible) {
            codigoDestinoSeleccionado = ""
            nombreDestinoSeleccionado = ""
            selectorAbierto = false
            modalConfirmacionAbierto = false
        }
    }

    Connections {
        target: daeClient
        function onSolicitudCambioEscuelaCompletada(exito, mensaje) {
            modalConfirmacionAbierto = false
            bannerAviso.mostrar(mensaje, exito)
        }
    }

    Flickable {
        id: flickCambio
        anchors.fill: parent
        contentWidth: width
        contentHeight: colCambio.implicitHeight + 130
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: colCambio
            width: flickCambio.width
            spacing: 14

            // =================================================================
            // 1. CABECERA DE NAVEGACIÓN + FECHA LÍMITE DAE
            // =================================================================
            RowLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: flickCambio.width - 40
                Layout.topMargin: 22
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 10

                Rectangle {
                    id: btnVolverCambio
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 38
                    radius: 19
                    color: temaApp.vidrio
                    border.color: temaApp.bordeVidrio
                    border.width: 1

                    Canvas {
                        width: 18; height: 18
                        anchors.centerIn: parent
                        property color colorTrazo: temaApp.textoPrincipal
                        onColorTrazoChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = colorTrazo;
                            ctx.lineWidth = 2.2;
                            ctx.lineCap = "round";
                            ctx.lineJoin = "round";
                            ctx.beginPath();
                            ctx.moveTo(11.5, 4);
                            ctx.lineTo(5.5, 9);
                            ctx.lineTo(11.5, 14);
                            ctx.stroke();
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPressed: btnVolverCambio.scale = 0.90
                        onReleased: btnVolverCambio.scale = 1.0
                        onClicked: rootCambioEscuela.volver()
                    }
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    spacing: 1

                    Text {
                        text: "Cambio de Escuela"
                        color: temaApp.textoPrincipal
                        font.pixelSize: 20
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: daeClient.fechaLimiteCambioEscuela !== ""
                              ? ("Activo • " + daeClient.fechaLimiteCambioEscuela)
                              : "Solicitud para Cambio de Escuela • DAE UC"
                        color: temaApp.textoSubtitulo
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    Layout.preferredWidth: rowEstadoCambio.implicitWidth + 16
                    Layout.preferredHeight: 30
                    radius: 15
                    color: temaApp.vidrio
                    border.color: temaApp.bordeVidrio
                    border.width: 1

                    RowLayout {
                        id: rowEstadoCambio
                        anchors.centerIn: parent
                        spacing: 5

                        Rectangle {
                            width: 7; height: 7; radius: 3.5
                            color: "#22c55e"
                        }
                        Text {
                            text: "Habilitado"
                            color: temaApp.textoPrincipal
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }
                }
            }

            // =================================================================
            // 2. TARJETA DE DATOS DEL ESTUDIANTE Y ESCUELA ACTUAL
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: flickCambio.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                implicitHeight: colDatosEst.implicitHeight + 32
                radius: 24
                color: temaApp.vidrio
                border.color: temaApp.bordeVidrio
                border.width: 1

                ColumnLayout {
                    id: colDatosEst
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: 8
                            Layout.preferredHeight: 18
                            radius: 4
                            color: temaApp.primario
                        }
                        Text {
                            text: "Datos del Estudiante Registrados"
                            color: temaApp.textoPrincipal
                            font.pixelSize: 14
                            font.bold: true
                            Layout.fillWidth: true
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: temaApp.bordeVidrio
                    }

                    // Fila Cédula + Nombre Completo
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 110
                            Layout.preferredHeight: 54
                            radius: 14
                            color: temaApp.panel
                            border.color: temaApp.bordePanel
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 2

                                Text {
                                    text: "CÉDULA"
                                    color: temaApp.textoMuted
                                    font.pixelSize: 9
                                    font.bold: true
                                    font.letterSpacing: 0.5
                                }
                                Text {
                                    text: daeClient.cedulaEstudiante
                                    color: temaApp.textoPrincipal
                                    font.pixelSize: 14
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 54
                            radius: 14
                            color: temaApp.panel
                            border.color: temaApp.bordePanel
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 2

                                Text {
                                    text: "NOMBRE COMPLETO"
                                    color: temaApp.textoMuted
                                    font.pixelSize: 9
                                    font.bold: true
                                    font.letterSpacing: 0.5
                                }
                                Text {
                                    text: daeClient.nombreEstudiante
                                    color: temaApp.textoPrincipal
                                    font.pixelSize: 13
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }

                    // Escuela Actual (Bloqueada como en el select escuela_actual de DAE)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 58
                        radius: 16
                        color: temaApp.panel
                        border.color: temaApp.primario
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 34
                                radius: 10
                                color: temaApp.superficie
                                border.color: temaApp.acento
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: daeClient.codigoEscuelaActual
                                    color: "white"
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                spacing: 2

                                Text {
                                    text: "ESCUELA ACTUAL"
                                    color: temaApp.textoMuted
                                    font.pixelSize: 9
                                    font.bold: true
                                    font.letterSpacing: 0.6
                                }
                                Text {
                                    text: "ESCUELA DE " + daeClient.escuelaEstudiante
                                    color: temaApp.textoPrincipal
                                    font.pixelSize: 12
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }
            }

            // =================================================================
            // 3. SELECTOR DE ESCUELA SOLICITADA (DESTINO)
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: flickCambio.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                implicitHeight: colEscuelaDestino.implicitHeight + 32
                radius: 24
                color: temaApp.panel
                border.color: rootCambioEscuela.codigoDestinoSeleccionado !== "" ? temaApp.primario : temaApp.bordePanel
                border.width: rootCambioEscuela.codigoDestinoSeleccionado !== "" ? 1.5 : 1

                ColumnLayout {
                    id: colEscuelaDestino
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: 8
                            Layout.preferredHeight: 18
                            radius: 4
                            color: temaApp.acento
                        }
                        Text {
                            text: "Escuela Solicitada (Destino)"
                            color: temaApp.textoPrincipal
                            font.pixelSize: 14
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        Text {
                            text: daeClient.escuelasDestinoDisponibles.length + " opciones"
                            color: temaApp.textoMuted
                            font.pixelSize: 11
                        }
                    }

                    Text {
                        text: "Seleccione la escuela a la cual desea trasladar su expediente académico:"
                        color: temaApp.textoSecundario
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    // Lista interactiva de las 5 escuelas destino disponibles
                    Repeater {
                        model: daeClient.escuelasDestinoDisponibles

                        delegate: Rectangle {
                            id: cardEscDestino
                            property bool seleccionada: rootCambioEscuela.codigoDestinoSeleccionado === modelData.codigo

                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            radius: 14
                            color: seleccionada ? temaApp.panelAlt : (temaApp.esClaro ? "#f8fafc" : "#09101f")
                            border.color: seleccionada ? temaApp.primario : temaApp.bordePanel
                            border.width: seleccionada ? 1.5 : 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                // Radio Button circular
                                Rectangle {
                                    Layout.preferredWidth: 20
                                    Layout.preferredHeight: 20
                                    radius: 10
                                    color: "transparent"
                                    border.color: cardEscDestino.seleccionada ? temaApp.primario : temaApp.textoMuted
                                    border.width: 2

                                    Rectangle {
                                        width: 10; height: 10; radius: 5
                                        anchors.centerIn: parent
                                        color: temaApp.primario
                                        visible: cardEscDestino.seleccionada
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 0
                                    spacing: 1

                                    Text {
                                        text: modelData.nombre
                                        color: cardEscDestino.seleccionada
                                               ? (temaApp.esClaro ? temaApp.primario : temaApp.claro)
                                               : temaApp.textoPrincipal
                                        font.pixelSize: 11
                                        font.bold: cardEscDestino.seleccionada
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: "Código DAE: " + modelData.codigo
                                        color: temaApp.textoMuted
                                        font.pixelSize: 9
                                    }
                                }

                                Rectangle {
                                    visible: cardEscDestino.seleccionada
                                    Layout.preferredWidth: lblElegida.implicitWidth + 12
                                    Layout.preferredHeight: 20
                                    radius: 10
                                    color: temaApp.primario

                                    Text {
                                        id: lblElegida
                                        anchors.centerIn: parent
                                        text: "Elegida"
                                        color: "white"
                                        font.pixelSize: 9
                                        font.bold: true
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (rootCambioEscuela.codigoDestinoSeleccionado === modelData.codigo) {
                                        rootCambioEscuela.codigoDestinoSeleccionado = ""
                                        rootCambioEscuela.nombreDestinoSeleccionado = ""
                                    } else {
                                        rootCambioEscuela.codigoDestinoSeleccionado = modelData.codigo
                                        rootCambioEscuela.nombreDestinoSeleccionado = modelData.nombre
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =================================================================
            // 4. NOTA REGLAMENTARIA OFICIAL DEL SISTEMA DAE
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: flickCambio.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                implicitHeight: colNotaOficial.implicitHeight + 28
                radius: 22
                color: temaApp.esClaro ? "#fef3c7" : "#22f59e0b"
                border.color: temaApp.esClaro ? "#f59e0b" : "#60fbbf24"
                border.width: 1

                ColumnLayout {
                    id: colNotaOficial
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: 26
                            Layout.preferredHeight: 26
                            radius: 8
                            color: temaApp.esClaro ? "#fde68a" : "#35f59e0b"
                            border.color: "#f59e0b"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "!"
                                color: temaApp.esClaro ? "#b45309" : "#fde68a"
                                font.pixelSize: 14
                                font.bold: true
                            }
                        }

                        Text {
                            text: "NOTA IMPORTANTE • CONDICIONES DAE"
                            color: temaApp.esClaro ? "#92400e" : "#fde68a"
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 0.4
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        text: "• DEBE TENER APROBADO EL PRIMER SEMESTRE COMPLETAMENTE PARA QUE SE PUEDA PROCESAR ESTA SOLICITUD.\n\n• AL PROCESARSE EL CAMBIO DE ESCUELA, SE RECALCULARÁ EL RAP Y SE ANULARÁ CUALQUIER SOLICITUD DE INSCRIPCIÓN."
                        color: temaApp.esClaro ? "#78350f" : "#fef3c7"
                        font.pixelSize: 11
                        font.bold: true
                        lineHeight: 1.15
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            // =================================================================
            // 5. BOTÓN "SIGUIENTE PASO" (ABRE EL MODAL DE CONFIRMACIÓN)
            // =================================================================
            Rectangle {
                id: btnSiguientePaso
                Layout.fillWidth: true
                Layout.maximumWidth: flickCambio.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: 52
                radius: 26
                border.color: rootCambioEscuela.codigoDestinoSeleccionado !== "" ? temaApp.claro : temaApp.bordeAlt
                border.width: 1
                opacity: daeClient.enviandoCambioEscuela ? 0.65 : 1.0

                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: rootCambioEscuela.codigoDestinoSeleccionado !== "" ? temaApp.primario : temaApp.panelAlt
                    }
                    GradientStop {
                        position: 1.0
                        color: rootCambioEscuela.codigoDestinoSeleccionado !== "" ? temaApp.oscuro : temaApp.panel
                    }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: daeClient.enviandoCambioEscuela ? "PROCESANDO SOLICITUD..." : "SIGUIENTE PASO"
                        color: rootCambioEscuela.codigoDestinoSeleccionado !== "" ? "white" : temaApp.textoSecundario
                        font.pixelSize: 13
                        font.bold: true
                        font.letterSpacing: 0.6
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: !daeClient.enviandoCambioEscuela
                    onPressed: btnSiguientePaso.scale = 0.96
                    onReleased: btnSiguientePaso.scale = 1.0
                    onClicked: {
                        if (rootCambioEscuela.codigoDestinoSeleccionado === "") {
                            bannerAviso.mostrar("⚠ Debe seleccionar una escuela destino", false)
                        } else {
                            rootCambioEscuela.modalConfirmacionAbierto = true
                        }
                    }
                }
                Behavior on scale { NumberAnimation { duration: 100 } }
            }
        }
    }

    // =========================================================================
    // MODAL DE CONFIRMACIÓN (Equivalente seguro al confirm() de verifica_esc en DAE)
    // =========================================================================
    Item {
        anchors.fill: parent
        visible: fondoModalConfirm.opacity > 0

        Rectangle {
            id: fondoModalConfirm
            anchors.fill: parent
            color: "#cc040812"
            opacity: rootCambioEscuela.modalConfirmacionAbierto ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            MouseArea {
                anchors.fill: parent
                enabled: rootCambioEscuela.modalConfirmacionAbierto
                onClicked: rootCambioEscuela.modalConfirmacionAbierto = false
            }
        }

        Rectangle {
            width: parent.width - 40
            implicitHeight: colModalConfirm.implicitHeight + 36
            radius: 26
            anchors.centerIn: parent
            color: temaApp.panel
            border.color: temaApp.primario
            border.width: 1.5
            scale: rootCambioEscuela.modalConfirmacionAbierto ? 1.0 : 0.90
            opacity: rootCambioEscuela.modalConfirmacionAbierto ? 1.0 : 0.0

            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
            Behavior on opacity { NumberAnimation { duration: 180 } }

            ColumnLayout {
                id: colModalConfirm
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                Text {
                    text: "Confirmar Solicitud de Cambio"
                    color: temaApp.textoPrincipal
                    font.pixelSize: 16
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "¿Está seguro que desea registrar esta solicitud de cambio de escuela en el sistema DAE?"
                    color: temaApp.textoSecundario
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: colResumenCambio.implicitHeight + 20
                    radius: 16
                    color: temaApp.panelAlt
                    border.color: temaApp.bordeAlt
                    border.width: 1

                    ColumnLayout {
                        id: colResumenCambio
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 6

                        Text {
                            text: "DE: ESCUELA DE " + daeClient.escuelaEstudiante
                            color: temaApp.textoSecundario
                            font.pixelSize: 10
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "A: " + rootCambioEscuela.nombreDestinoSeleccionado
                            color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        radius: 14
                        color: temaApp.panelAlt
                        border.color: temaApp.bordeAlt
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Cancelar"
                            color: temaApp.textoPrincipal
                            font.pixelSize: 12
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: rootCambioEscuela.modalConfirmacionAbierto = false
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        radius: 14
                        color: "#dc2626"
                        border.color: "#f87171"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Sí, Registrar"
                            color: "white"
                            font.pixelSize: 12
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                daeClient.enviarSolicitudCambioEscuela(rootCambioEscuela.codigoDestinoSeleccionado)
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // BANNER FLOTANTE DE NOTIFICACIÓN
    // =========================================================================
    Rectangle {
        id: bannerAviso
        property string mensaje: ""
        property bool esExito: true

        function mostrar(txt, ok) {
            mensaje = txt
            esExito = ok
            opacity = 1.0
            timerBanner.restart()
        }

        width: parent.width - 40
        height: 46
        radius: 23
        anchors.horizontalCenter: parent.horizontalCenter
        y: opacity > 0 ? 18 : -50
        color: esExito ? "#ee064e3b" : "#ee7f1d1d"
        border.color: esExito ? "#4ade80" : "#f87171"
        border.width: 1
        opacity: 0
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 220 } }
        Behavior on y { NumberAnimation { duration: 280; easing.type: Easing.OutBack } }

        Text {
            anchors.centerIn: parent
            width: parent.width - 24
            text: bannerAviso.mensaje
            color: "white"
            font.pixelSize: 11
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        Timer {
            id: timerBanner
            interval: 3200
            onTriggered: bannerAviso.opacity = 0
        }
    }
}
