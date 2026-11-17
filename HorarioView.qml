import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: rootHorario

    // 0 = Lunes, 1 = Martes, 2 = Miércoles, 3 = Jueves, 4 = Viernes, 5 = Sábado
    function obtenerDiaActualUsuario() {
        var d = new Date().getDay(); // 0=Dom, 1=Lun, 2=Mar, 3=Mié, 4=Jue, 5=Vie, 6=Sáb
        return (d >= 1 && d <= 6) ? (d - 1) : 0;
    }

    property int diaSeleccionado: obtenerDiaActualUsuario()
    property int modoVista: 0 // 0 = Día, 1 = Malla

    onVisibleChanged: {
        if (visible) {
            rootHorario.diaSeleccionado = obtenerDiaActualUsuario()
        }
    }

    // Días de la semana vacíos por defecto (se llenan desde daeClient.diasHorarioAsignado del usuario autenticado)
    property var diasSemanaBase: [
        { corto: "Lun", nombre: "Lunes", bloques: 0, horas: "Libre", clases: [] },
        { corto: "Mar", nombre: "Martes", bloques: 0, horas: "Libre", clases: [] },
        { corto: "Mié", nombre: "Miércoles", bloques: 0, horas: "Libre", clases: [] },
        { corto: "Jue", nombre: "Jueves", bloques: 0, horas: "Libre", clases: [] },
        { corto: "Vie", nombre: "Viernes", bloques: 0, horas: "Libre", clases: [] },
        { corto: "Sáb", nombre: "Sábado", bloques: 0, horas: "Libre", clases: [] }
    ]

    property var diasSemana: (daeClient.diasHorarioAsignado && daeClient.diasHorarioAsignado.length === 6)
                             ? daeClient.diasHorarioAsignado
                             : diasSemanaBase

    property var mallaSemanalBase: []

    property var mallaSemanal: (daeClient.mallaHorarioAsignado && daeClient.mallaHorarioAsignado.length > 0)
                               ? daeClient.mallaHorarioAsignado
                               : mallaSemanalBase

    function colorPorCodigo(txt) {
        if (!txt || txt === "") return temaApp.panelAlt
        var codLimpio = txt.split("\n")[0].trim()
        return ventanaPrincipal.coloresTarjetaMateria(0, codLimpio).c1
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: colHorario.implicitHeight + 130
        clip: true

        ColumnLayout {
            id: colHorario
            width: parent.width
            spacing: 16

            // 1. CABECERA: "Horario Asignado" + CONMUTADOR (Día / Malla)
            RowLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: rootHorario.width - 44
                Layout.topMargin: 24
                Layout.leftMargin: 22
                Layout.rightMargin: 22
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    Layout.minimumWidth: 0
                    spacing: 2
                    Text {
                        text: "Horario Asignado"
                        color: temaApp.textoPrincipal
                        font.pixelSize: 22
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: daeClient.cedulaEstudiante + " • " + daeClient.escuelaCorta
                        color: temaApp.textoSubtitulo
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 124
                    Layout.preferredHeight: 36
                    Layout.fillWidth: false
                    radius: 18
                    color: temaApp.vidrio
                    border.color: temaApp.bordeVidrio
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 2

                        Rectangle {
                            Layout.fillWidth: true; Layout.fillHeight: true; radius: 15
                            color: rootHorario.modoVista === 0 ? temaApp.primario : "transparent"
                            Behavior on color { ColorAnimation { duration: 180 } }
                            Text {
                                anchors.centerIn: parent
                                text: "Día"
                                color: rootHorario.modoVista === 0 ? "white" : temaApp.textoPrincipal
                                font.pixelSize: 11
                                font.bold: true
                            }
                            MouseArea { anchors.fill: parent; onClicked: rootHorario.modoVista = 0 }
                        }

                        Rectangle {
                            Layout.fillWidth: true; Layout.fillHeight: true; radius: 15
                            color: rootHorario.modoVista === 1 ? temaApp.primario : "transparent"
                            Behavior on color { ColorAnimation { duration: 180 } }
                            Text {
                                anchors.centerIn: parent
                                text: "Malla"
                                color: rootHorario.modoVista === 1 ? "white" : temaApp.textoPrincipal
                                font.pixelSize: 11
                                font.bold: true
                            }
                            MouseArea { anchors.fill: parent; onClicked: rootHorario.modoVista = 1 }
                        }
                    }
                }
            }

            // 2. TARJETA RESUMEN PERFECTAMENTE CENTRADA (25 Bloques/Sem | 9 Materias | Botón Descargar)
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: rootHorario.width - 44
                Layout.leftMargin: 22
                Layout.rightMargin: 22
                Layout.preferredHeight: 80
                radius: 22
                color: temaApp.vidrio
                border.color: temaApp.bordeVidrio
                border.width: 1
                clip: true

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Columna 1: 25 Bloques / Sem
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        Layout.fillHeight: true
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                text: daeClient.totalBloquesHorario
                                color: temaApp.textoPrincipal
                                font.pixelSize: 22
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "Bloques / Sem"
                                color: temaApp.textoSubtitulo
                                font.pixelSize: 11
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 38; color: temaApp.bordeVidrio }

                    // Columna 2: 9 Materias
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        Layout.fillHeight: true
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                text: daeClient.totalMateriasHorario
                                color: temaApp.textoPrincipal
                                font.pixelSize: 22
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "Materias"
                                color: temaApp.textoSubtitulo
                                font.pixelSize: 11
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 38; color: temaApp.bordeVidrio }

                    // Columna 3: Botón para Descargar el Horario centrado
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        Layout.fillHeight: true

                        Rectangle {
                            id: btnDescargarHorario
                            width: 92; height: 48; radius: 15
                            anchors.centerIn: parent
                            border.color: temaApp.bordeAlt
                            border.width: 1

                            gradient: Gradient {
                                GradientStop { position: 0.0; color: temaApp.primario }
                                GradientStop { position: 1.0; color: temaApp.oscuro }
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2

                                // Icono vectorial de descarga
                                Canvas {
                                    Layout.preferredWidth: 18; Layout.preferredHeight: 18
                                    Layout.alignment: Qt.AlignHCenter
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.reset();
                                        ctx.strokeStyle = "#ffffff";
                                        ctx.lineWidth = 2.0;
                                        ctx.lineCap = "round";
                                        ctx.lineJoin = "round";

                                        // Flecha hacia abajo
                                        ctx.beginPath();
                                        ctx.moveTo(9, 2.5); ctx.lineTo(9, 12);
                                        ctx.moveTo(5.5, 8.5); ctx.lineTo(9, 12); ctx.lineTo(12.5, 8.5);
                                        // Bandeja inferior
                                        ctx.moveTo(3, 13.5); ctx.lineTo(3, 15.5); ctx.lineTo(15, 15.5); ctx.lineTo(15, 13.5);
                                        ctx.stroke();
                                    }
                                }

                                Text {
                                    text: daeClient.descargandoPdf ? "Bajando..." : "Descargar"
                                    color: "white"
                                    font.pixelSize: 10
                                    font.bold: true
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onPressed: btnDescargarHorario.scale = 0.92
                                onReleased: btnDescargarHorario.scale = 1.0
                                onClicked: {
                                    daeClient.descargarHorarioPdf()
                                    daeClient.registrarSolicitudReciente("HOR", "Horario Asignado",
                                                                           "PDF del horario del semestre", "Descargado")
                                }
                            }
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }
                    }
                }
            }

            // =====================================================================
            // VISTA A: SELECTOR DE DÍAS + LÍNEA DE TIEMPO
            // =====================================================================
            ColumnLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: rootHorario.width
                Layout.minimumWidth: 0
                spacing: 16
                visible: rootHorario.modoVista === 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.maximumWidth: rootHorario.width - 40
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    spacing: 6

                    Repeater {
                        model: rootHorario.diasSemana

                        delegate: Rectangle {
                            property bool seleccionado: rootHorario.diaSeleccionado === index
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            Layout.minimumWidth: 0
                            Layout.preferredHeight: 78
                            radius: 22
                            color: seleccionado ? temaApp.primario : temaApp.panelAlt
                            border.color: seleccionado ? temaApp.acentoVisible : temaApp.bordeAlt
                            border.width: seleccionado ? 1.5 : 1

                            Behavior on color { ColorAnimation { duration: 200 } }
                            Behavior on scale { NumberAnimation { duration: 120 } }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: modelData.corto
                                    color: seleccionado ? "white" : temaApp.textoSecundario
                                    font.pixelSize: 12
                                    font.bold: true
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                Rectangle {
                                    Layout.preferredWidth: 28; Layout.preferredHeight: 28; radius: 14
                                    color: seleccionado ? "white" : (modelData.bloques > 0 ? (temaApp.esClaro ? temaApp.suave : Qt.rgba(temaApp.primario.r, temaApp.primario.g, temaApp.primario.b, 0.22)) : temaApp.panel)
                                    Layout.alignment: Qt.AlignHCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.bloques > 0 ? modelData.bloques : "–"
                                        color: seleccionado ? temaApp.oscuro : (modelData.bloques > 0 ? (temaApp.esClaro ? temaApp.oscuro : temaApp.claro) : temaApp.textoMuted)
                                        font.pixelSize: 12
                                        font.bold: true
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onPressed: parent.scale = 0.93
                                onReleased: parent.scale = 1.0
                                onClicked: rootHorario.diaSeleccionado = index
                            }
                        }
                    }
                }

                // Subtítulo del día seleccionado
                RowLayout {
                    Layout.fillWidth: true
                    Layout.maximumWidth: rootHorario.width - 48
                    Layout.leftMargin: 24
                    Layout.rightMargin: 24

                    Text {
                        text: rootHorario.diasSemana[rootHorario.diaSeleccionado].nombre
                        color: temaApp.textoPrincipal
                        font.pixelSize: 18
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Rectangle {
                        Layout.preferredWidth: txtDuracionDia.implicitWidth + 20
                        Layout.preferredHeight: 24
                        Layout.fillWidth: false
                        radius: 12
                        color: temaApp.panelAlt
                        border.color: temaApp.bordeAlt
                        Text {
                            id: txtDuracionDia
                            anchors.centerIn: parent
                            text: rootHorario.diasSemana[rootHorario.diaSeleccionado].bloques + " bloques • " + rootHorario.diasSemana[rootHorario.diaSeleccionado].horas
                            color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }
                }

                // TARJETA DE DÍA LIBRE (Ej. Jueves)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.maximumWidth: rootHorario.width - 44
                    Layout.leftMargin: 22
                    Layout.rightMargin: 22
                    Layout.preferredHeight: 155
                    radius: 24
                    color: temaApp.panel
                    border.color: temaApp.bordePanel
                    border.width: 1
                    visible: rootHorario.diasSemana[rootHorario.diaSeleccionado].clases.length === 0

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        Rectangle {
                            Layout.preferredWidth: 48; Layout.preferredHeight: 48; radius: 24
                            color: temaApp.panelAlt
                            border.color: temaApp.bordeAlt
                            Layout.alignment: Qt.AlignHCenter
                            Text { anchors.centerIn: parent; text: "✓"; color: temaApp.acento; font.pixelSize: 22; font.bold: true }
                        }
                        Text {
                            text: "Día sin carga académica"
                            color: temaApp.textoPrincipal
                            font.pixelSize: 16
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: "Ideal para estudiar por tu cuenta 😉"
                            color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                            font.pixelSize: 12
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                // TARJETAS DE CLASES DEL DÍA (Incluyendo Nombre del Profesor)
                Repeater {
                    model: rootHorario.diasSemana[rootHorario.diaSeleccionado].clases

                    delegate: RowLayout {
                        id: filaClaseHorario
                        readonly property var colTema: ventanaPrincipal.coloresTarjetaMateria(index, modelData.codigo)
                        Layout.fillWidth: true
                        Layout.maximumWidth: rootHorario.width - 44
                        Layout.leftMargin: 22
                        Layout.rightMargin: 22
                        spacing: 12

                        // Columna Izquierda: Hora de Inicio / Fin
                        ColumnLayout {
                            Layout.preferredWidth: 48
                            Layout.fillWidth: false
                            Layout.alignment: Qt.AlignTop
                            spacing: 4

                            Text {
                                text: modelData.horaInicio
                                color: temaApp.textoPrincipal
                                font.pixelSize: 14
                                font.bold: true
                                Layout.alignment: Qt.AlignRight
                            }
                            Text {
                                text: modelData.horaFin
                                color: temaApp.textoMuted
                                font.pixelSize: 11
                                Layout.alignment: Qt.AlignRight
                            }
                            Rectangle {
                                Layout.preferredWidth: 2; Layout.preferredHeight: 82
                                radius: 1
                                Layout.alignment: Qt.AlignRight
                                Layout.rightMargin: 12
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: filaClaseHorario.colTema.c1 }
                                    GradientStop { position: 1.0; color: Qt.rgba(temaApp.primario.r, temaApp.primario.g, temaApp.primario.b, 0.1) }
                                }
                            }
                        }

                        // Tarjeta Derecha: Detalle de la Materia + Profesor + Aula
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            Layout.minimumWidth: 0
                            Layout.preferredHeight: 148
                            radius: 24
                            clip: true
                            border.color: "#55ffffff"
                            border.width: 1

                            gradient: Gradient {
                                GradientStop { position: 0.0; color: filaClaseHorario.colTema.c1 }
                                GradientStop { position: 1.0; color: filaClaseHorario.colTema.c2 }
                            }

                            Rectangle {
                                width: 120; height: 120; radius: 60
                                color: filaClaseHorario.colTema.c3
                                opacity: 0.22
                                x: parent.width - 70; y: -30
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 4

                                // Fila 1: Insignia TEORÍA/LAB + Código + Badge ADICIÓN DAE
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Rectangle {
                                        Layout.preferredWidth: lblTipo.implicitWidth + 14
                                        Layout.preferredHeight: 20
                                        Layout.fillWidth: false
                                        radius: 10
                                        color: "#35000000"
                                        Text {
                                            id: lblTipo
                                            anchors.centerIn: parent
                                            text: modelData.tipo
                                            color: temaApp.suave
                                            font.pixelSize: 9
                                            font.bold: true
                                        }
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: lblCod.implicitWidth + 14
                                        Layout.preferredHeight: 20
                                        Layout.fillWidth: false
                                        radius: 10
                                        color: "#30ffffff"
                                        Text {
                                            id: lblCod
                                            anchors.centerIn: parent
                                            text: modelData.codigo
                                            color: "white"
                                            font.pixelSize: 10
                                            font.bold: true
                                        }
                                    }

                                    Rectangle {
                                        visible: modelData.adicion
                                        Layout.preferredWidth: lblAdic.implicitWidth + 12
                                        Layout.preferredHeight: 20
                                        Layout.fillWidth: false
                                        radius: 10
                                        color: temaApp.acento
                                        Text {
                                            id: lblAdic
                                            anchors.centerIn: parent
                                            text: "ADICIÓN DAE"
                                            color: "#0f172a"
                                            font.pixelSize: 9
                                            font.bold: true
                                        }
                                    }

                                    Item { Layout.fillWidth: true }
                                }

                                // Fila 2: Nombre de la asignatura
                                Text {
                                    text: modelData.nombre
                                    color: "white"
                                    font.pixelSize: 15
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                // Fila 3: Nombre del Profesor
                                Text {
                                    text: modelData.profesor
                                    color: "#f1f5f9"
                                    font.pixelSize: 12
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Item { Layout.fillHeight: true }

                                // Fila 4: Sección, Bloques y Pill del Aula
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Text {
                                        text: modelData.seccion + "  •  " + modelData.bloquesTxt
                                        color: "#e2e8f0"
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 0
                                        Layout.minimumWidth: 0
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: rowAula.implicitWidth + 16
                                        Layout.preferredHeight: 26
                                        Layout.fillWidth: false
                                        radius: 13
                                        color: "white"

                                        RowLayout {
                                            id: rowAula
                                            anchors.centerIn: parent
                                            spacing: 4
                                            Text {
                                                text: "Aula " + modelData.aula
                                                color: "#0f172a"
                                                font.pixelSize: 11
                                                font.bold: true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =====================================================================
            // VISTA B: MALLA SEMANAL COMPLETA
            // =====================================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: rootHorario.width - 32
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.preferredHeight: 455
                radius: 24
                color: temaApp.panel
                border.color: temaApp.bordePanel
                border.width: 1
                visible: rootHorario.modoVista === 1
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: "HORA"
                            color: temaApp.textoMuted
                            font.pixelSize: 9
                            font.bold: true
                            Layout.preferredWidth: 36
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Repeater {
                            model: ["LUN", "MAR", "MIÉ", "JUE", "VIE", "SÁB"]
                            delegate: Text {
                                text: modelData
                                color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                                font.pixelSize: 10
                                font.bold: true
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    Repeater {
                        model: rootHorario.mallaSemanal

                        delegate: RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 4

                            Text {
                                text: modelData.hora
                                color: temaApp.textoSecundario
                                font.pixelSize: 10
                                font.bold: true
                                Layout.preferredWidth: 36
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Repeater {
                                model: modelData.celdas

                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 0
                                    Layout.fillHeight: true
                                    radius: 8
                                    color: modelData !== "" ? rootHorario.colorPorCodigo(modelData) : temaApp.panelAlt
                                    border.color: modelData !== "" ? "#60ffffff" : temaApp.bordeAlt
                                    border.width: 1
                                    clip: true

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: "white"
                                        font.pixelSize: 8
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        visible: modelData !== ""
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 3. TARJETAS INFERIORES: ASIGNATURAS SIN BLOQUE DE AULA FIJO (Servicio Comunitario, TEG, Pasantías, etc.)
            Repeater {
                model: daeClient.materiasSinBloqueHorario

                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.maximumWidth: rootHorario.width - 44
                    Layout.leftMargin: 22
                    Layout.rightMargin: 22
                    Layout.preferredHeight: 74
                    radius: 20
                    color: temaApp.panelAlt
                    border.color: temaApp.bordeAlt
                    border.width: 1
                    clip: true

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 14

                        Rectangle {
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44
                            Layout.fillWidth: false
                            radius: 14
                            color: temaApp.oscuro
                            border.color: temaApp.primario
                            Text {
                                anchors.centerIn: parent
                                text: modelData.codigo ? modelData.codigo.substring(0, 2) : "SC"
                                color: "white"
                                font.pixelSize: 14
                                font.bold: true
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            Layout.minimumWidth: 0
                            spacing: 2
                            Text {
                                text: modelData.nombre
                                color: temaApp.textoPrincipal
                                font.pixelSize: 12
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: "Código " + modelData.codigo + " • Sección " + modelData.sec + " • Sin bloque de aula fijo"
                                color: temaApp.textoSecundario
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }
    }
}
