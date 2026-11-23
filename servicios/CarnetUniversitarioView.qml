import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: rootCarnet

    signal volver()
    signal irAPerfil()

    property string urlFotoEstudiante: ""
    property bool descargaPdfExitosa: false
    property bool modalQrAbierto: false
    property bool modalAvisoNoOficialAbierto: false
    property string tituloQrModal: "QR de Identificación Estudiantil"
    property int semillaQrModal: 1

    // Componente reutilizable que dibuja el Código QR real de https://carnet.uc.edu.ve
    component CodigoQrCanvas: Canvas {
        id: qrCanvas
        property int semilla: 1
        property color colorModulo: "#0f172a"
        readonly property var matrizQr: daeClient.matrizQrCarnet()
        width: 84
        height: 84
        onSemillaChanged: requestPaint()
        onColorModuloChanged: requestPaint()
        onMatrizQrChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();

            var matriz = matrizQr;
            if (!matriz || matriz.length === 0) return;

            var n = matriz.length;
            var cel = Math.min(width, height) / (n + 2);
            var ox = (width - n * cel) / 2;
            var oy = (height - n * cel) / 2;

            ctx.fillStyle = "#ffffff";
            ctx.fillRect(0, 0, width, height);

            ctx.fillStyle = colorModulo;
            for (var r = 0; r < n; r++) {
                var fila = matriz[r];
                for (var c = 0; c < n; c++) {
                    if (fila[c] === 1) {
                        ctx.fillRect(ox + c * cel, oy + r * cel, Math.ceil(cel), Math.ceil(cel));
                    }
                }
            }
        }
    }

    Flickable {
        id: flickCarnet
        anchors.fill: parent
        contentWidth: width
        contentHeight: colCarnet.implicitHeight + 135
        clip: true

        ColumnLayout {
            id: colCarnet
            width: flickCarnet.width
            spacing: 14

            // 1. CABECERA PRINCIPAL
            RowLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: flickCarnet.width - 40
                Layout.topMargin: 24
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 10

                Rectangle {
                    id: btnVolverCarnet
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
                        onPressed: btnVolverCarnet.scale = 0.90
                        onReleased: btnVolverCarnet.scale = 1.0
                        onClicked: rootCarnet.volver()
                    }
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    spacing: 1
                    Text {
                        text: "Carnet Universitario"
                        color: temaApp.textoPrincipal
                        font.pixelSize: 20
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: "Credencial Electrónica Oficial • UC"
                        color: temaApp.textoSubtitulo
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    Layout.preferredWidth: rowVigencia.implicitWidth + 16
                    Layout.preferredHeight: 32
                    radius: 16
                    color: temaApp.vidrio
                    border.color: temaApp.bordeVidrio
                    border.width: 1

                    RowLayout {
                        id: rowVigencia
                        anchors.centerIn: parent
                        spacing: 5

                        Rectangle {
                            width: 7; height: 7; radius: 3.5
                            color: "#22c55e"
                        }
                        Text {
                            text: "Vigente"
                            color: temaApp.textoPrincipal
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }
                }
            }

            // =========================================================================
            // 2. CARNET VIRTUAL INTERACTIVO - ANVERSO (CARA FRONTAL OFICIAL UC)
            // =========================================================================
            Rectangle {
                id: cardAnverso
                Layout.fillWidth: true
                Layout.maximumWidth: flickCarnet.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: 224
                radius: 22
                color: temaApp.panel
                border.color: temaApp.primario
                border.width: 1.5

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    // Encabezado del Carnet: Escudo Oficial UC + UNIVERSIDAD DE CARABOBO + Tag ANVERSO
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        // Escudo Oficial de la Universidad de Carabobo
                        Image {
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 42
                            source: "logo_uc.png"
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            spacing: 0

                            Text {
                                text: "UNIVERSIDAD DE CARABOBO"
                                color: temaApp.textoPrincipal
                                font.pixelSize: 13
                                font.bold: true
                                font.letterSpacing: 0.5
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: "FACULTAD DE INGENIERÍA • CREDENCIAL ÚNICA"
                                color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                                font.pixelSize: 9
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: txtTagFrontal.implicitWidth + 12
                            Layout.preferredHeight: 20
                            radius: 10
                            color: temaApp.panelAlt
                            border.color: temaApp.bordeAlt
                            Text {
                                id: txtTagFrontal
                                anchors.centerIn: parent
                                text: "ANVERSO"
                                color: temaApp.textoSecundario
                                font.pixelSize: 8
                                font.bold: true
                            }
                        }
                    }

                    // Cuerpo central del Carnet: Foto 4x3 + Datos del Estudiante + QR Frontal
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 10

                        // Foto tipo carnet (Sincronizada con PerfilView)
                        Rectangle {
                            Layout.preferredWidth: 74
                            Layout.preferredHeight: 96
                            radius: 10
                            color: temaApp.panelAlt
                            border.color: temaApp.bordeAlt
                            border.width: 1.5
                            clip: true

                            // Iniciales por defecto si no ha cargado foto en Perfil
                            Column {
                                anchors.centerIn: parent
                                spacing: 4
                                visible: rootCarnet.urlFotoEstudiante === ""

                                Rectangle {
                                    width: 40; height: 40; radius: 20
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: temaApp.primario
                                    Text {
                                        anchors.centerIn: parent
                                        text: daeClient.inicialesEstudiante
                                        color: "white"
                                        font.pixelSize: 15
                                        font.bold: true
                                    }
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Foto 4×3"
                                    color: temaApp.textoMuted
                                    font.pixelSize: 8
                                    font.bold: true
                                }
                            }

                            Image {
                                id: imgCarnetEst
                                anchors.fill: parent
                                anchors.margins: 2
                                source: rootCarnet.urlFotoEstudiante
                                fillMode: Image.PreserveAspectCrop
                                visible: rootCarnet.urlFotoEstudiante !== ""
                            }
                        }

                        // Columna de Datos Oficiales del Carnet
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            spacing: 2

                            Text {
                                text: "V-" + daeClient.cedulaEstudiante
                                color: temaApp.textoPrincipal
                                font.pixelSize: 15
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: daeClient.primerApellido + (daeClient.segundoApellido !== "" ? " " + daeClient.segundoApellido.substring(0, 1) : "")
                                color: temaApp.textoPrincipal
                                font.pixelSize: 12
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: daeClient.primerNombre + (daeClient.segundoNombre !== "" ? " " + daeClient.segundoNombre.substring(0, 1) : "")
                                color: temaApp.textoSecundario
                                font.pixelSize: 11
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            // Cinta verde oficial "ESTUDIANTE" del Carnet UC
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 20
                                Layout.topMargin: 2
                                radius: 5
                                color: "#4d7c0f"
                                border.color: "#84cc16"
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "ESTUDIANTE"
                                    color: "white"
                                    font.pixelSize: 10
                                    font.bold: true
                                    font.letterSpacing: 1.0
                                }
                            }

                            Text {
                                text: "VENCE: 31-12-" + (new Date().getFullYear())
                                color: temaApp.esClaro ? "#b45309" : "#fbbf24"
                                font.pixelSize: 10
                                font.bold: true
                                Layout.topMargin: 2
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // QR Frontal (Fondo blanco para lectura óptica + toque para ampliar)
                        Rectangle {
                            id: cajaQrFrontal
                            Layout.preferredWidth: 88
                            Layout.preferredHeight: 96
                            radius: 10
                            color: "#ffffff"
                            border.color: temaApp.bordeAlt
                            border.width: 1

                            Column {
                                anchors.centerIn: parent
                                spacing: 2

                                CodigoQrCanvas {
                                    width: 72; height: 72
                                    semilla: 1
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "🔍 Tocar QR"
                                    color: "#334155"
                                    font.pixelSize: 8
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    rootCarnet.tituloQrModal = "QR Frontal • Identificación V-" + daeClient.cedulaEstudiante
                                    rootCarnet.semillaQrModal = 1
                                    rootCarnet.modalQrAbierto = true
                                }
                            }
                        }
                    }

                    // Franja inferior de carrera: ING - INGENIERIA TELECOM.
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 26
                        radius: 8
                        color: temaApp.panelAlt
                        border.color: temaApp.bordeAlt

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10

                            Text {
                                text: "ING - " + daeClient.escuelaEstudiante
                                color: temaApp.textoPrincipal
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 0.4
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: "Bárbula"
                                color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }
                    }
                }
            }

            // =========================================================================
            // 3. CARNET VIRTUAL INTERACTIVO - REVERSO (VERIFICACIÓN, QR Y FIRMA)
            // =========================================================================
            Rectangle {
                id: cardReverso
                Layout.fillWidth: true
                Layout.maximumWidth: flickCarnet.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: 176
                radius: 22
                color: temaApp.panel
                border.color: temaApp.bordePanel
                border.width: 1
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: 6; Layout.preferredHeight: 16; radius: 3
                            color: temaApp.acento
                        }

                        Text {
                            text: "REVERSO DE LA CREDENCIAL • VALIDACIÓN OFICIAL"
                            color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 0.5
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            Layout.preferredWidth: txtTagReverso.implicitWidth + 12
                            Layout.preferredHeight: 20
                            radius: 10
                            color: temaApp.panelAlt
                            border.color: temaApp.bordeAlt
                            Text {
                                id: txtTagReverso
                                anchors.centerIn: parent
                                text: "REVERSO"
                                color: temaApp.textoSecundario
                                font.pixelSize: 8
                                font.bold: true
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 12

                        // Texto institucional del Consejo Universitario + URL de verificación
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            spacing: 4

                            Text {
                                text: "Carnet único de la Universidad de Carabobo. Aprobado por el Consejo Universitario en sesión extraordinaria Nro. 1.915 de fecha 25 de febrero de 2021."
                                color: temaApp.textoSecundario
                                font.pixelSize: 10
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Text {
                                text: "Para verificar la validez ingrese a:"
                                color: temaApp.textoMuted
                                font.pixelSize: 9
                                Layout.topMargin: 2
                            }

                            Text {
                                text: "https://carnet.uc.edu.ve"
                                color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                                font.pixelSize: 10
                                font.bold: true
                                font.underline: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Bloque derecho del Reverso: QR de Verificación + Firma del Secretario
                        ColumnLayout {
                            Layout.preferredWidth: 104
                            spacing: 4

                            Rectangle {
                                Layout.preferredWidth: 82
                                Layout.preferredHeight: 82
                                Layout.alignment: Qt.AlignHCenter
                                radius: 10
                                color: "#ffffff"
                                border.color: temaApp.bordeAlt
                                border.width: 1

                                CodigoQrCanvas {
                                    width: 68; height: 68
                                    semilla: 4
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        rootCarnet.tituloQrModal = "QR Reverso • Verificación carnet.uc.edu.ve"
                                        rootCarnet.semillaQrModal = 4
                                        rootCarnet.modalQrAbierto = true
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =========================================================================
            // 4. TARJETA "MIS CARNETS ASIGNADOS" + BOTÓN DESCARGAR PDF DEL CARNET
            // =========================================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: flickCarnet.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: colAsignados.implicitHeight + 28
                radius: 22
                color: temaApp.vidrio
                border.color: temaApp.bordeVidrio
                border.width: 1

                ColumnLayout {
                    id: colAsignados
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "🪪"
                            font.pixelSize: 14
                        }

                        Text {
                            text: "MIS CARNETS ASIGNADOS"
                            color: temaApp.textoPrincipal
                            font.pixelSize: 12
                            font.bold: true
                            font.letterSpacing: 0.5
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "1 disponible"
                            color: temaApp.textoSubtitulo
                            font.pixelSize: 10
                        }
                    }

                    // Fila de resumen: Facultad | Carrera | Vencimiento
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 62
                        radius: 14
                        color: temaApp.panelAlt
                        border.color: temaApp.bordeAlt
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.margins: 8

                            Item {
                                id: colFacultad
                                width: parent.width * 0.24; height: parent.height
                                Column {
                                    anchors.centerIn: parent; spacing: 2
                                    Text {
                                        width: colFacultad.width
                                        text: "Facultad"
                                        color: temaApp.textoMuted
                                        font.pixelSize: 9
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        width: colFacultad.width
                                        text: "INGENIERÍA"
                                        color: temaApp.textoPrincipal
                                        font.pixelSize: 11
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            Rectangle { width: 1; height: 28; color: temaApp.bordeAlt; anchors.verticalCenter: parent.verticalCenter }

                            Item {
                                id: colCarrera
                                width: parent.width * 0.46; height: parent.height
                                Column {
                                    anchors.centerIn: parent; spacing: 2
                                    Text {
                                        width: colCarrera.width - 4
                                        text: "Carrera"
                                        color: temaApp.textoMuted
                                        font.pixelSize: 9
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                    }
                                    // La carrera es la del usuario (viene del DAE): baja de línea o
                                    // se recorta, nunca se sale de su columna
                                    Text {
                                        width: colCarrera.width - 4
                                        text: daeClient.autenticado
                                              ? (daeClient.escuelaEstudiante !== "" ? daeClient.escuelaEstudiante.toUpperCase()
                                                                                              : daeClient.escuelaCorta.toUpperCase())
                                              : "—"
                                        color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                                        font.pixelSize: 10
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                        lineHeight: 1.05
                                    }
                                }
                            }

                            Rectangle { width: 1; height: 28; color: temaApp.bordeAlt; anchors.verticalCenter: parent.verticalCenter }

                            Item {
                                id: colVencimiento
                                width: parent.width * 0.29; height: parent.height
                                Column {
                                    anchors.centerIn: parent; spacing: 2
                                    Text {
                                        width: colVencimiento.width
                                        text: "Vencimiento"
                                        color: temaApp.textoMuted
                                        font.pixelSize: 9
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        width: colVencimiento.width
                                        text: "31/12/" + (new Date().getFullYear())
                                        color: temaApp.textoPrincipal
                                        font.pixelSize: 11
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }

                    // Aviso visible: reconstrucción no oficial
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: colAvisoCarnet.implicitHeight + 20
                        radius: 14
                        color: temaApp.esClaro ? "#fef3c7" : "#22f59e0b"
                        border.color: temaApp.esClaro ? "#f59e0b" : "#60fbbf24"
                        border.width: 1

                        ColumnLayout {
                            id: colAvisoCarnet
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 4

                            Text {
                                Layout.fillWidth: true
                                text: "AVISO IMPORTANTE • MODELO NO OFICIAL"
                                color: temaApp.esClaro ? "#92400e" : "#fde68a"
                                font.pixelSize: 10
                                font.bold: true
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Este carnet no es oficial; es únicamente una reconstrucción del modelo oficial. Para su validez, debe descargarse directamente desde la página https://carnet.uc.edu.ve"
                                color: temaApp.esClaro ? "#78350f" : "#fef3c7"
                                font.pixelSize: 10
                                lineHeight: 1.15
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    // Botón principal: Descargar PDF del Carnet Electrónico
                    Rectangle {
                        id: btnDescargarCarnetPdf
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        radius: 24
                        border.color: temaApp.bordeAlt
                        border.width: 1

                        gradient: Gradient {
                            GradientStop { position: 0.0; color: temaApp.primario }
                            GradientStop { position: 1.0; color: temaApp.oscuro }
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Canvas {
                                width: 18; height: 18
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.reset();
                                    ctx.strokeStyle = "#ffffff";
                                    ctx.lineWidth = 2.0;
                                    ctx.lineCap = "round";
                                    ctx.lineJoin = "round";
                                    ctx.beginPath();
                                    ctx.moveTo(9, 2.5); ctx.lineTo(9, 12);
                                    ctx.moveTo(5.5, 8.5); ctx.lineTo(9, 12); ctx.lineTo(12.5, 8.5);
                                    ctx.moveTo(3, 14); ctx.lineTo(3, 16); ctx.lineTo(15, 16); ctx.lineTo(15, 14);
                                    ctx.stroke();
                                }
                            }

                            Text {
                                text: "DESCARGAR PDF DEL CARNET"
                                color: "white"
                                font.pixelSize: 12
                                font.bold: true
                                font.letterSpacing: 0.5
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onPressed: btnDescargarCarnetPdf.scale = 0.96
                            onReleased: btnDescargarCarnetPdf.scale = 1.0
                            onClicked: {
                                rootCarnet.modalAvisoNoOficialAbierto = true
                            }
                        }
                        Behavior on scale { NumberAnimation { duration: 100 } }
                    }

                    // Notificación de descarga exitosa del PDF
                    Rectangle {
                        visible: rootCarnet.descargaPdfExitosa
                        Layout.fillWidth: true
                        Layout.preferredHeight: 54
                        radius: 14
                        color: temaApp.esClaro ? "#dcfce7" : "#163828"
                        border.color: "#22c55e"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 30; Layout.preferredHeight: 30; radius: 15
                                color: "#22c55e"
                                Text { anchors.centerIn: parent; text: "✓"; color: "white"; font.pixelSize: 14; font.bold: true }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                spacing: 1
                                Text {
                                    text: "Carnet_Electronico_UC_" + daeClient.cedulaEstudiante + ".pdf descargado"
                                    color: temaApp.esClaro ? "#14532d" : "#4ade80"
                                    font.pixelSize: 11
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: "Listo para imprimir a color en calidad láser y sellar en DICAES"
                                    color: temaApp.esClaro ? "#166534" : "#bbf7d0"
                                    font.pixelSize: 9
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }
            }

            // =========================================================================
            // 5. TARJETA INFORMATIVA: INSTRUCCIONES DE IMPRESIÓN Y SELLADO DICAES
            // =========================================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: flickCarnet.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: colNormativaCarnet.implicitHeight + 30
                radius: 22
                color: temaApp.panel
                border.color: temaApp.bordePanel
                border.width: 1

                ColumnLayout {
                    id: colNormativaCarnet
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: 6
                            Layout.preferredHeight: 18
                            radius: 3
                            color: "#f59e0b"
                        }

                        Text {
                            text: "Instrucciones de Impresión y Validación"
                            color: temaApp.textoPrincipal
                            font.pixelSize: 13
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Repeater {
                        model: [
                            "Esta credencial es de uso personal, intransferible y de porte obligatorio dentro de las instalaciones de la universidad.",
                            "Imprimir a color en alta calidad (preferiblemente impresora láser). No plastifique el carnet hasta ser sellado.",
                            "Pegar foto tipo carnet (4×3 cm, fondo blanco, de frente, sin gorras ni accesorios, sin usar grapas).",
                            "Bárbula (DICAES): Acudir con el carnet impreso, foto pegada y cédula laminada. Horario: Martes y Jueves de 8:30 am a 11:00 am."
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
                                color: temaApp.textoSecundario
                                font.pixelSize: 11
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }

            // 6. PIE INSTITUCIONAL DAE
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: flickCarnet.width - 40
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
                    text: "UNIVERSIDAD DE CARABOBO • SECRETARÍA • DICAES"
                    color: temaApp.textoMuted
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 0.6
                }
            }
        }
    }

    // =========================================================================
    // MODAL DE ALTO CONTRASTE PARA ESCANEO RÁPIDO DEL QR EN LECTORES ÓPTICOS
    // =========================================================================
    Rectangle {
        anchors.fill: parent
        color: "#cc040812"
        visible: rootCarnet.modalQrAbierto
        opacity: rootCarnet.modalQrAbierto ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        MouseArea {
            anchors.fill: parent
            onClicked: rootCarnet.modalQrAbierto = false
        }

        Rectangle {
            width: Math.min(parent.width - 48, 310)
            height: 360
            radius: 26
            anchors.centerIn: parent
            color: temaApp.panel
            border.color: temaApp.acento
            border.width: 1.5

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                Text {
                    text: rootCarnet.tituloQrModal
                    color: temaApp.textoPrincipal
                    font.pixelSize: 13
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.preferredWidth: 210
                    Layout.preferredHeight: 210
                    Layout.alignment: Qt.AlignHCenter
                    radius: 18
                    color: "#ffffff"
                    border.color: temaApp.bordeAlt
                    border.width: 1

                    CodigoQrCanvas {
                        width: 180
                        height: 180
                        anchors.centerIn: parent
                        semilla: rootCarnet.semillaQrModal
                    }
                }

                Text {
                    text: "V-" + daeClient.cedulaEstudiante + " • " + daeClient.nombreEstudiante
                    color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                    font.pixelSize: 10
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    radius: 19
                    color: temaApp.primario

                    Text {
                        anchors.centerIn: parent
                        text: "Cerrar QR"
                        color: "white"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rootCarnet.modalQrAbierto = false
                    }
                }
            }
        }
    }

    // =========================================================================
    // MODAL DE AVISO ANTES DE DESCARGAR PDF DEL CARNET (NO OFICIAL)
    // =========================================================================
    Item {
        anchors.fill: parent
        visible: rootCarnet.modalAvisoNoOficialAbierto
        z: 100

        Rectangle {
            anchors.fill: parent
            color: "#cc040812"
            MouseArea {
                anchors.fill: parent
                onClicked: rootCarnet.modalAvisoNoOficialAbierto = false
            }
        }

        Rectangle {
            width: Math.min(parent.width - 40, 350)
            implicitHeight: colModalAvisoNoOficial.implicitHeight + 36
            radius: 24
            anchors.centerIn: parent
            color: temaApp.panel
            border.color: "#f59e0b"
            border.width: 1.5

            MouseArea { anchors.fill: parent }

            ColumnLayout {
                id: colModalAvisoNoOficial
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                Text {
                    Layout.fillWidth: true
                    text: "Aviso Importante"
                    color: temaApp.textoPrincipal
                    font.pixelSize: 16
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    Layout.fillWidth: true
                    text: "Este carnet no es oficial; es únicamente una reconstrucción del modelo oficial.\n\nPara su validez, debe descargarse directamente desde la página:\nhttps://carnet.uc.edu.ve"
                    color: temaApp.textoSecundario
                    font.pixelSize: 12
                    lineHeight: 1.2
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    radius: 14
                    color: temaApp.panelAlt
                    border.color: temaApp.acento
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Ir a https://carnet.uc.edu.ve"
                        color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.openUrlExternally("https://carnet.uc.edu.ve")
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
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
                            onClicked: rootCarnet.modalAvisoNoOficialAbierto = false
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        radius: 14
                        color: temaApp.primario

                        Text {
                            anchors.centerIn: parent
                            text: "Descargar PDF"
                            color: "white"
                            font.pixelSize: 12
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                rootCarnet.modalAvisoNoOficialAbierto = false
                                daeClient.descargarCarnetPdf(rootCarnet.urlFotoEstudiante)
                                rootCarnet.descargaPdfExitosa = true
                                daeClient.registrarSolicitudReciente("CAR", "Carnet Universitario",
                                                                       "Carnet vigente • V-" + daeClient.cedulaEstudiante, "Descargado")
                            }
                        }
                    }
                }
            }
        }
    }
}
