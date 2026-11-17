import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts

Item {
    id: rootCalendario

    signal volver()

    property bool descargaExitosa: false
    property string archivoDescargado: ""
    property string periodoDescargado: ""

    property var listaCalendarios: daeClient.calendariosOficiales.length > 0
                                   ? daeClient.calendariosOficiales
                                   : [
        {
            titulo: "Calendario 1-2026 (CF 23/07/2026)",
            periodo: "Período Lectivo 1-2026",
            aprobacion: "Aprobado en Consejo de Facultad (CF) el 23/07/2026",
            estado: "VIGENTE",
            esVigente: true,
            archivo: "calendario_1_2026rev3.pdf",
            url: "https://dae.ing.uc.edu.ve/docs/calendario_1_2026rev3.pdf",
            tamano: "PDF Oficial DAE"
        },
        {
            titulo: "Calendario 2-2026 (CF 06/08/2026)",
            periodo: "Período Lectivo 2-2026",
            aprobacion: "Aprobado en Consejo de Facultad (CF) el 06/08/2026",
            estado: "PUBLICADO",
            esVigente: false,
            archivo: "calendario_2_2026.pdf",
            url: "https://dae.ing.uc.edu.ve/docs/calendario_2_2026.pdf",
            tamano: "PDF Oficial DAE"
        }
    ]

    Connections {
        target: daeClient
        function onPdfDescargado(rutaLocal, nombreArchivo) {
            rootCalendario.archivoDescargado = rutaLocal
            rootCalendario.descargaExitosa = true
            timerToast.restart()
        }
    }

    Timer {
        id: timerToast
        interval: 3800
        repeat: false
        onTriggered: rootCalendario.descargaExitosa = false
    }

    Flickable {
        id: flickCalendario
        anchors.fill: parent
        contentWidth: width
        contentHeight: colCalendario.implicitHeight + 135
        clip: true

        ColumnLayout {
            id: colCalendario
            width: flickCalendario.width
            spacing: 14

            // =================================================================
            // 1. CABECERA CON BOTÓN DE REGRESO
            // =================================================================
            RowLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: flickCalendario.width - 40
                Layout.topMargin: 24
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 10

                Rectangle {
                    id: btnVolverCal
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
                        onPressed: btnVolverCal.scale = 0.90
                        onReleased: btnVolverCal.scale = 1.0
                        onClicked: rootCalendario.volver()
                    }
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    spacing: 1
                    Text {
                        Layout.fillWidth: true
                        text: "Calendario Académico"
                        color: temaApp.textoPrincipal
                        font.pixelSize: 20
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "FACULTAD DE INGENIERÍA • CONSEJO DE FACULTAD"
                        color: temaApp.esClaro ? temaApp.primario : temaApp.acento
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 0.8
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 68
                    Layout.preferredHeight: 28
                    radius: 14
                    color: temaApp.panelAlt
                    border.color: temaApp.bordeAlt
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "2 PDFs"
                        color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
            }

            // =================================================================
            // 2. BANNER INFORMATIVO INSTITUCIONAL
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: flickCalendario.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                implicitHeight: colBannerInfo.implicitHeight + 28
                radius: 22
                color: temaApp.panel
                border.color: temaApp.bordePanel
                border.width: 1

                ColumnLayout {
                    id: colBannerInfo
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 42
                            Layout.preferredHeight: 42
                            radius: 13
                            color: temaApp.panelAlt
                            border.color: temaApp.bordeAlt
                            border.width: 1

                            Canvas {
                                width: 22; height: 22
                                anchors.centerIn: parent
                                property color colorTrazo: temaApp.esClaro ? temaApp.primario : temaApp.claro
                                onColorTrazoChanged: requestPaint()
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.reset();
                                    ctx.strokeStyle = colorTrazo;
                                    ctx.fillStyle = colorTrazo;
                                    ctx.lineWidth = 1.8;
                                    ctx.lineCap = "round";
                                    ctx.lineJoin = "round";
                                    ctx.strokeRect(3, 5, 16, 14);
                                    ctx.beginPath();
                                    ctx.moveTo(3, 9.5); ctx.lineTo(19, 9.5);
                                    ctx.moveTo(7.5, 2.5); ctx.lineTo(7.5, 6);
                                    ctx.moveTo(14.5, 2.5); ctx.lineTo(14.5, 6);
                                    ctx.stroke();
                                    ctx.fillRect(7, 12.5, 2.2, 2.2);
                                    ctx.fillRect(12.8, 12.5, 2.2, 2.2);
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: "Cronogramas Oficiales en PDF"
                                color: temaApp.textoPrincipal
                                font.pixelSize: 14
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Selecciona el período lectivo para descargar el documento oficial avalado por el Consejo de Facultad (CF)."
                                color: temaApp.textoSecundario
                                font.pixelSize: 11
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }

            // =================================================================
            // 3. TÍTULO DE SECCIÓN
            // =================================================================
            RowLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: flickCalendario.width - 44
                Layout.leftMargin: 22
                Layout.rightMargin: 22

                Text {
                    text: "Documentos Disponibles"
                    color: temaApp.textoPrincipal
                    font.pixelSize: 15
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "Descarga directa"
                    color: temaApp.textoMuted
                    font.pixelSize: 11
                }
            }

            // =================================================================
            // 4. TARJETAS DE ENLACES DE DESCARGA PDF (1-2026 y 2-2026)
            // =================================================================
            Repeater {
                model: rootCalendario.listaCalendarios

                delegate: Rectangle {
                    id: cardCalendario
                    Layout.fillWidth: true
                    Layout.maximumWidth: flickCalendario.width - 40
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    implicitHeight: colCardCal.implicitHeight + 28
                    radius: 22
                    color: temaApp.panel
                    border.color: modelData.esVigente ? temaApp.primario : temaApp.bordePanel
                    border.width: modelData.esVigente ? 1.5 : 1

                    Behavior on scale { NumberAnimation { duration: 110 } }

                    ColumnLayout {
                        id: colCardCal
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            // Icono de documento PDF
                            Rectangle {
                                Layout.preferredWidth: 48
                                Layout.preferredHeight: 48
                                radius: 14
                                color: modelData.esVigente
                                       ? (temaApp.esClaro ? "#EFF6FF" : Qt.rgba(temaApp.primario.r, temaApp.primario.g, temaApp.primario.b, 0.22))
                                       : temaApp.panelAlt
                                border.color: modelData.esVigente ? temaApp.primario : temaApp.bordeAlt
                                border.width: 1

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 1

                                    Canvas {
                                        Layout.alignment: Qt.AlignHCenter
                                        width: 18; height: 18
                                        property color colorTrazo: modelData.esVigente
                                                                   ? (temaApp.esClaro ? temaApp.primario : temaApp.claro)
                                                                   : temaApp.textoSecundario
                                        onColorTrazoChanged: requestPaint()
                                        onPaint: {
                                            var ctx = getContext("2d");
                                            ctx.reset();
                                            ctx.strokeStyle = colorTrazo;
                                            ctx.lineWidth = 1.7;
                                            ctx.lineCap = "round";
                                            ctx.lineJoin = "round";
                                            ctx.beginPath();
                                            ctx.moveTo(4, 2);
                                            ctx.lineTo(11, 2);
                                            ctx.lineTo(15, 6);
                                            ctx.lineTo(15, 16);
                                            ctx.lineTo(4, 16);
                                            ctx.closePath();
                                            ctx.stroke();
                                            ctx.beginPath();
                                            ctx.moveTo(10.5, 2);
                                            ctx.lineTo(10.5, 6.5);
                                            ctx.lineTo(15, 6.5);
                                            ctx.stroke();
                                        }
                                    }

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: "PDF"
                                        color: modelData.esVigente
                                               ? (temaApp.esClaro ? temaApp.primario : temaApp.claro)
                                               : temaApp.textoSecundario
                                        font.pixelSize: 9
                                        font.bold: true
                                    }
                                }
                            }

                            // Información del calendario
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                spacing: 3

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Rectangle {
                                        Layout.preferredWidth: txtBadgeEstado.implicitWidth + 12
                                        Layout.preferredHeight: 18
                                        radius: 6
                                        color: modelData.esVigente
                                               ? (temaApp.esClaro ? "#DCFCE7" : "#064E3B")
                                               : (temaApp.esClaro ? "#E0E7FF" : "#1E293B")
                                        border.color: modelData.esVigente ? "#10B981" : temaApp.bordeAlt
                                        border.width: 1

                                        Text {
                                            id: txtBadgeEstado
                                            anchors.centerIn: parent
                                            text: modelData.estado
                                            color: modelData.esVigente
                                                   ? (temaApp.esClaro ? "#15803D" : "#34D399")
                                                   : (temaApp.esClaro ? temaApp.primario : temaApp.claro)
                                            font.pixelSize: 9
                                            font.bold: true
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.periodo
                                        color: temaApp.textoMuted
                                        font.pixelSize: 10
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }
                                }

                                // Nombre oficial tal como aparece en DAE
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.titulo
                                    color: temaApp.textoPrincipal
                                    font.pixelSize: 14
                                    font.bold: true
                                    wrapMode: Text.WordWrap
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.aprobacion
                                    color: temaApp.textoSecundario
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: temaApp.bordeVidrio
                        }

                        // Fila inferior con nombre de archivo + botón de descarga
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.archivo
                                    color: temaApp.textoMuted
                                    font.pixelSize: 10
                                    font.family: "monospace"
                                    elide: Text.ElideMiddle
                                }

                                Text {
                                    text: "Documento Oficial • " + modelData.tamano
                                    color: temaApp.textoSecundario
                                    font.pixelSize: 10
                                }
                            }

                            Rectangle {
                                id: btnDescargarItem
                                Layout.preferredWidth: rowBtnDesc.implicitWidth + 24
                                Layout.preferredHeight: 36
                                radius: 12
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: modelData.esVigente ? temaApp.primario : temaApp.panelAlt }
                                    GradientStop { position: 1.0; color: modelData.esVigente ? temaApp.secundario : temaApp.panelAlt }
                                }
                                border.color: modelData.esVigente ? temaApp.acento : temaApp.bordeAlt
                                border.width: 1

                                RowLayout {
                                    id: rowBtnDesc
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Canvas {
                                        width: 14; height: 14
                                        property color colorIcono: modelData.esVigente
                                                                   ? "white"
                                                                   : (temaApp.esClaro ? temaApp.primario : temaApp.claro)
                                        onColorIconoChanged: requestPaint()
                                        onPaint: {
                                            var ctx = getContext("2d");
                                            ctx.reset();
                                            ctx.strokeStyle = colorIcono;
                                            ctx.lineWidth = 1.8;
                                            ctx.lineCap = "round";
                                            ctx.lineJoin = "round";
                                            ctx.beginPath();
                                            ctx.moveTo(7, 2); ctx.lineTo(7, 10);
                                            ctx.moveTo(4, 7.2); ctx.lineTo(7, 10.2); ctx.lineTo(10, 7.2);
                                            ctx.moveTo(2.5, 12.5); ctx.lineTo(11.5, 12.5);
                                            ctx.stroke();
                                        }
                                    }

                                    Text {
                                        text: "Descargar PDF"
                                        color: modelData.esVigente
                                               ? "white"
                                               : (temaApp.esClaro ? temaApp.primario : temaApp.claro)
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: cardCalendario.scale = 0.98
                                    onReleased: cardCalendario.scale = 1.0
                                    onClicked: {
                                        rootCalendario.archivoDescargado = modelData.archivo
                                        rootCalendario.periodoDescargado = modelData.titulo
                                        daeClient.descargarCalendarioPdf(modelData.url || "", modelData.archivo)
                                        daeClient.registrarSolicitudReciente("CAL", "Calendario Académico",
                                                                               modelData.titulo || "Calendario oficial", "Descargado")
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =================================================================
            // 5. CONFIRMACIÓN DE DESCARGA DE PDF
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: flickCalendario.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                visible: rootCalendario.descargaExitosa
                implicitHeight: rowConfirmacion.implicitHeight + 22
                radius: 16
                color: temaApp.esClaro ? "#DCFCE7" : "#064E3B"
                border.color: "#10B981"
                border.width: 1

                RowLayout {
                    id: rowConfirmacion
                    anchors.fill: parent
                    anchors.margins: 11
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 14
                        color: "#10B981"

                        Text {
                            anchors.centerIn: parent
                            text: "✓"
                            color: "white"
                            font.pixelSize: 14
                            font.bold: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        spacing: 1

                        Text {
                            Layout.fillWidth: true
                            text: "Descargando " + rootCalendario.periodoDescargado
                            color: temaApp.esClaro ? "#065F46" : "#ECFDF5"
                            font.pixelSize: 12
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Archivo guardado: " + rootCalendario.archivoDescargado
                            color: temaApp.esClaro ? "#047857" : "#A7F3D0"
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            // =================================================================
            // 6. NOTA INFORMATIVA SOBRE EL CONTENIDO DEL CALENDARIO
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: flickCalendario.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                implicitHeight: colInfoContenido.implicitHeight + 26
                radius: 18
                color: temaApp.vidrio
                border.color: temaApp.bordeVidrio
                border.width: 1

                ColumnLayout {
                    id: colInfoContenido
                    anchors.fill: parent
                    anchors.margins: 13
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        text: "¿Qué incluye cada Calendario Académico?"
                        color: temaApp.textoPrincipal
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "• Fechas de inscripción de alumnos regulares y nuevos ingresos.\n• Inicio y culminación de las 16 semanas de clases.\n• Lapsos de retiro de asignaturas y carga de calificaciones.\n• Días feriados nacionales, regionales y universitarios."
                        color: temaApp.textoSecundario
                        font.pixelSize: 11
                        lineHeight: 1.25
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
