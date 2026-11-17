import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: rootConstancias

    signal volver()

    // 0 = Constancia de estudios, 1 = Constancia de notas, 2 = Reporte de inscripción, 3 = Constancia de buena conducta
    property int tipoSeleccionado: 0
    property bool descargaExitosa: false
    property string ultimoArchivoGenerado: ""

    Connections {
        target: daeClient
        function onPdfDescargado(rutaLocal, nombreArchivo) {
            rootConstancias.ultimoArchivoGenerado = nombreArchivo
            rootConstancias.descargaExitosa = true
        }
    }

    property var catalogoConstancias: [
        {
            idx: 0,
            titulo: "Constancia de Estudios",
            subtitulo: "Certifica condición de alumno activo en el período actual",
            requisito: "Activo en el período actual",
            codigoPrefijo: "DAE-CE-" + daeClient.cedulaEstudiante + "-26",
            archivo: "Constancia_Estudios_" + daeClient.cedulaEstudiante + ".pdf",
            icono: "estudios"
        },
        {
            idx: 1,
            titulo: "Constancia de Notas",
            subtitulo: "Relación oficial de calificaciones y promedio ponderado",
            requisito: "Calificaciones registradas",
            codigoPrefijo: "DAE-CN-" + daeClient.cedulaEstudiante + "-26",
            archivo: "Constancia_Notas_" + daeClient.cedulaEstudiante + ".pdf",
            icono: "notas"
        },
        {
            idx: 2,
            titulo: "Reporte de Inscripción",
            subtitulo: "Detalle de asignaturas y secciones del período actual",
            requisito: "Inscripción período actual",
            codigoPrefijo: "DAE-RI-" + daeClient.cedulaEstudiante + "-26",
            archivo: "Reporte_Inscripcion_" + daeClient.cedulaEstudiante + ".pdf",
            icono: "inscripcion"
        },
        {
            idx: 3,
            titulo: "Constancia de Buena Conducta",
            subtitulo: "Certificación de solvencia disciplinaria estudiantil",
            requisito: "Activo en el período actual",
            codigoPrefijo: "DAE-BC-" + daeClient.cedulaEstudiante + "-26",
            archivo: "Buena_Conducta_" + daeClient.cedulaEstudiante + ".pdf",
            icono: "conducta"
        }
    ]

    // Componente para dibujar los iconos vectoriales de cada tipo de constancia
    component IconoConstancia: Canvas {
        id: canvasIconoConst
        property string tipo: "estudios"
        property color colorTrazo: temaApp.acentoVisible
        width: 22; height: 22
        onColorTrazoChanged: requestPaint()
        onTipoChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.strokeStyle = colorTrazo;
            ctx.fillStyle = colorTrazo;
            ctx.lineWidth = 1.8;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";

            if (tipo === "estudios") {
                // Birrete académico
                ctx.beginPath();
                ctx.moveTo(11, 4);
                ctx.lineTo(20, 8.5);
                ctx.lineTo(11, 13);
                ctx.lineTo(2, 8.5);
                ctx.closePath();
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(6, 11);
                ctx.lineTo(6, 16);
                ctx.quadraticCurveTo(11, 19, 16, 16);
                ctx.lineTo(16, 11);
                ctx.moveTo(19, 9);
                ctx.lineTo(19, 15);
                ctx.stroke();
            } else if (tipo === "notas") {
                // Hoja con calificaciones y barras
                ctx.strokeRect(4, 2.5, 14, 17);
                ctx.beginPath();
                ctx.moveTo(7.5, 7); ctx.lineTo(14.5, 7);
                ctx.moveTo(7.5, 11); ctx.lineTo(14.5, 11);
                ctx.moveTo(7.5, 15); ctx.lineTo(11.5, 15);
                ctx.stroke();
            } else if (tipo === "inscripcion") {
                // Portapapeles con check de materias inscritas
                ctx.strokeRect(4, 4, 14, 16);
                ctx.beginPath();
                ctx.moveTo(8, 2.5); ctx.lineTo(14, 2.5);
                ctx.moveTo(8, 12); ctx.lineTo(10, 14); ctx.lineTo(14.5, 9.5);
                ctx.stroke();
            } else if (tipo === "conducta") {
                // Escudo con estrella / verificación
                ctx.beginPath();
                ctx.moveTo(11, 2.5);
                ctx.lineTo(18, 5.5);
                ctx.lineTo(18, 11);
                ctx.quadraticCurveTo(18, 16.5, 11, 19.5);
                ctx.quadraticCurveTo(4, 16.5, 4, 11);
                ctx.lineTo(4, 5.5);
                ctx.closePath();
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(8.5, 11);
                ctx.lineTo(10.3, 13);
                ctx.lineTo(14, 9);
                ctx.stroke();
            }
        }
    }

    Flickable {
        id: flickConstancias
        anchors.fill: parent
        contentWidth: width
        contentHeight: colConstancias.implicitHeight + 135
        clip: true

        ColumnLayout {
            id: colConstancias
            width: flickConstancias.width
            spacing: 14

            // 1. CABECERA CON BOTÓN DE REGRESO
            RowLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: flickConstancias.width - 40
                Layout.topMargin: 24
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 10

                Rectangle {
                    id: btnVolverConst
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
                        onPressed: btnVolverConst.scale = 0.90
                        onReleased: btnVolverConst.scale = 1.0
                        onClicked: rootConstancias.volver()
                    }
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    spacing: 1
                    Text {
                        text: "Solicitud de Constancias"
                        color: temaApp.textoPrincipal
                        font.pixelSize: 19
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: "Emisión Digital con Código de Barra • DAE"
                        color: temaApp.textoSubtitulo
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    Layout.preferredWidth: rowEstadoActivo.implicitWidth + 16
                    Layout.preferredHeight: 32
                    radius: 16
                    color: temaApp.vidrio
                    border.color: temaApp.bordeVidrio
                    border.width: 1

                    RowLayout {
                        id: rowEstadoActivo
                        anchors.centerIn: parent
                        spacing: 5

                        Rectangle {
                            width: 7; height: 7; radius: 3.5
                            color: "#22c55e"
                        }
                        Text {
                            text: "Activo"
                            color: temaApp.textoPrincipal
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }
                }
            }

            // 2. SECCIÓN: "SELECCIONE LA CONSTANCIA DE SU PREFERENCIA"
            RowLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: flickConstancias.width - 40
                Layout.leftMargin: 22
                Layout.rightMargin: 22

                Text {
                    text: "Seleccione la Constancia de su Preferencia"
                    color: temaApp.textoPrincipal
                    font.pixelSize: 14
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: "4 disponibles"
                    color: temaApp.textoMuted
                    font.pixelSize: 11
                }
            }

            // LISTA DE LAS 4 CONSTANCIAS CON RADIO BUTTON MODERNO
            Repeater {
                model: rootConstancias.catalogoConstancias

                delegate: Rectangle {
                    id: cardOpcionConst
                    property bool activo: rootConstancias.tipoSeleccionado === modelData.idx

                    Layout.fillWidth: true
                    Layout.maximumWidth: flickConstancias.width - 40
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    Layout.preferredHeight: 82
                    radius: 20
                    color: activo ? temaApp.panelAlt : temaApp.panel
                    border.color: activo ? temaApp.primario : temaApp.bordePanel
                    border.width: activo ? 1.5 : 1
                    clip: true

                    Behavior on color { ColorAnimation { duration: 180 } }
                    Behavior on border.color { ColorAnimation { duration: 180 } }

                    // Barra vertical izquierda cuando está seleccionada
                    Rectangle {
                        width: 4
                        height: parent.height - 26
                        radius: 2
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: activo ? temaApp.acento : "transparent"
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 24
                        anchors.rightMargin: 16
                        spacing: 12

                        // Icono vectorial del tipo de constancia
                        Rectangle {
                            Layout.preferredWidth: 42
                            Layout.preferredHeight: 42
                            radius: 13
                            color: activo
                                   ? temaApp.primario
                                   : (temaApp.esClaro ? temaApp.suave : Qt.rgba(temaApp.primario.r, temaApp.primario.g, temaApp.primario.b, 0.16))
                            border.color: activo ? temaApp.acentoVisible : temaApp.bordeAlt
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 180 } }

                            IconoConstancia {
                                anchors.centerIn: parent
                                tipo: modelData.icono
                                colorTrazo: activo ? "#ffffff" : (temaApp.esClaro ? temaApp.primario : temaApp.claro)
                            }
                        }

                        // Textos centrales
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            spacing: 3

                            Text {
                                text: modelData.titulo
                                color: temaApp.textoPrincipal
                                font.pixelSize: 14
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: modelData.subtitulo
                                color: temaApp.textoSecundario
                                font.pixelSize: 10
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Row {
                                spacing: 6

                                Rectangle {
                                    width: txtReqChip.implicitWidth + 10
                                    height: 16; radius: 5
                                    color: temaApp.esClaro ? "#dcfce7" : "#163828"
                                    border.color: "#22c55e"
                                    border.width: 0.8

                                    Text {
                                        id: txtReqChip
                                        anchors.centerIn: parent
                                        text: "✓ " + modelData.requisito
                                        color: temaApp.esClaro ? "#15803d" : "#4ade80"
                                        font.pixelSize: 8
                                        font.bold: true
                                    }
                                }
                            }
                        }

                        // Radio Button circular moderno a la derecha
                        Rectangle {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            radius: 12
                            color: activo ? Qt.rgba(temaApp.primario.r, temaApp.primario.g, temaApp.primario.b, 0.20) : "transparent"
                            border.color: activo ? temaApp.acento : temaApp.textoMuted
                            border.width: 2

                            Rectangle {
                                width: 12; height: 12; radius: 6
                                anchors.centerIn: parent
                                color: temaApp.acento
                                visible: activo
                                scale: activo ? 1.0 : 0.0
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPressed: cardOpcionConst.scale = 0.98
                        onReleased: cardOpcionConst.scale = 1.0
                        onClicked: {
                            rootConstancias.tipoSeleccionado = modelData.idx
                            rootConstancias.descargaExitosa = false
                        }
                    }
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }
            }

            // 4. BOTÓN DE ACCIÓN: "DESCARGUE CONSTANCIA EN PDF" + AVISO DE DESCARGA
            Rectangle {
                id: btnDescargarPdf
                Layout.fillWidth: true
                Layout.maximumWidth: flickConstancias.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: 52
                radius: 26
                border.color: temaApp.bordeAlt
                border.width: 1

                gradient: Gradient {
                    GradientStop { position: 0.0; color: temaApp.primario }
                    GradientStop { position: 1.0; color: temaApp.oscuro }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    Canvas {
                        width: 20; height: 20
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = "#ffffff";
                            ctx.lineWidth = 2.0;
                            ctx.lineCap = "round";
                            ctx.lineJoin = "round";
                            ctx.beginPath();
                            ctx.moveTo(10, 3); ctx.lineTo(10, 13);
                            ctx.moveTo(6, 9.5); ctx.lineTo(10, 13.5); ctx.lineTo(14, 9.5);
                            ctx.moveTo(3.5, 15); ctx.lineTo(3.5, 17); ctx.lineTo(16.5, 17); ctx.lineTo(16.5, 15);
                            ctx.stroke();
                        }
                    }

                    Text {
                        text: daeClient.descargandoPdf ? "GENERANDO CONSTANCIA EN DAE..." : "DESCARGUE CONSTANCIA EN PDF"
                        color: "white"
                        font.pixelSize: 13
                        font.bold: true
                        font.letterSpacing: 0.6
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: btnDescargarPdf.scale = 0.96
                    onReleased: btnDescargarPdf.scale = 1.0
                    onClicked: {
                        rootConstancias.ultimoArchivoGenerado = rootConstancias.catalogoConstancias[rootConstancias.tipoSeleccionado].archivo
                        daeClient.descargarConstanciaEstudiantil(rootConstancias.tipoSeleccionado + 1)
                        rootConstancias.descargaExitosa = true
                        daeClient.registrarSolicitudReciente(
                            "PDF",
                            "Constancia de Estudio",
                            rootConstancias.catalogoConstancias[rootConstancias.tipoSeleccionado].titulo || "Constancia de Estudios",
                            "Descargada")
                    }
                }
                Behavior on scale { NumberAnimation { duration: 100 } }
            }

            // Banner de confirmación cuando se descarga el PDF
            Rectangle {
                visible: rootConstancias.descargaExitosa
                Layout.fillWidth: true
                Layout.maximumWidth: flickConstancias.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: 62
                radius: 18
                color: temaApp.esClaro ? "#dcfce7" : "#163828"
                border.color: "#22c55e"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 34; Layout.preferredHeight: 34; radius: 17
                        color: "#22c55e"
                        Text { anchors.centerIn: parent; text: "✓"; color: "white"; font.pixelSize: 16; font.bold: true }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        spacing: 2
                        Text {
                            text: "¡Constancia generada en PDF!"
                            color: temaApp.esClaro ? "#14532d" : "#4ade80"
                            font.pixelSize: 12
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: rootConstancias.ultimoArchivoGenerado + " • Firma y Código de Barra DAE"
                            color: temaApp.esClaro ? "#166534" : "#bbf7d0"
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // 5. TARJETA INFORMATIVA OFICIAL DE AUTENTICIDAD Y VERIFICACIÓN
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: flickConstancias.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: colInfoVerificacion.implicitHeight + 32
                radius: 22
                color: temaApp.panel
                border.color: temaApp.bordePanel
                border.width: 1

                ColumnLayout {
                    id: colInfoVerificacion
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: 6
                            Layout.preferredHeight: 18
                            radius: 3
                            color: temaApp.primario
                        }

                        Text {
                            text: "Verificación y Condiciones de Uso"
                            color: temaApp.textoPrincipal
                            font.pixelSize: 13
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        text: "Las constancias obtenidas por este medio son para uso interno de la Universidad. Se puede corroborar la autenticidad de la constancia en la dirección:"
                        color: temaApp.textoSecundario
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    // Píldora destacada con el enlace oficial dae.ing.uc.edu.ve/verificar
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: 12
                        color: temaApp.panelAlt
                        border.color: temaApp.primario
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Text {
                                text: "🌐"
                                font.pixelSize: 13
                            }

                            Text {
                                text: "dae.ing.uc.edu.ve/verificar"
                                color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                                font.pixelSize: 12
                                font.bold: true
                                font.underline: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                Layout.preferredWidth: 66
                                Layout.preferredHeight: 22
                                radius: 7
                                color: temaApp.esClaro ? temaApp.suave : Qt.rgba(temaApp.primario.r, temaApp.primario.g, temaApp.primario.b, 0.22)
                                Text {
                                    anchors.centerIn: parent
                                    text: "Portal DAE"
                                    color: temaApp.esClaro ? temaApp.oscuro : temaApp.claro
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                            }
                        }
                    }

                    Text {
                        text: "Para ello se utiliza el número de cédula y el Código de Barra presente en la constancia. Existen 4 tipos de constancias:"
                        color: temaApp.textoSecundario
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: temaApp.bordePanel }

                    // Lista detallada de los 4 tipos como en el sistema DAE
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: [
                                "De estudios: es necesario estar activo en el período actual.",
                                "Calificaciones (notas).",
                                "Reporte de inscripción (del período actual).",
                                "De buena conducta: es necesario estar activo en el período actual."
                            ]

                            delegate: RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    Layout.preferredWidth: 6
                                    Layout.preferredHeight: 6
                                    radius: 3
                                    color: temaApp.acento
                                    Layout.alignment: Qt.AlignTop
                                    Layout.topMargin: 5
                                }

                                Text {
                                    text: modelData
                                    color: temaApp.textoPrincipal
                                    font.pixelSize: 11
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }
            }

            // 6. PIE INSTITUCIONAL DAE
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: flickConstancias.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.topMargin: 2
                Layout.preferredHeight: 46
                radius: 16
                color: temaApp.panelAlt
                border.color: temaApp.bordeAlt
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "FACULTAD DE INGENIERÍA • DIRECCIÓN DE ASUNTOS ESTUDIANTILES"
                    color: temaApp.textoMuted
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 0.6
                }
            }
        }
    }
}
