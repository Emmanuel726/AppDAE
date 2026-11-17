import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: rootSalones

    signal volver()
    signal verEnMapa(string codigoAula)

    // Día seleccionado: 0=Lun, 1=Mar, 2=Mié, 3=Jue, 4=Vie, 5=Sáb
    property int diaSeleccionado: obtenerDiaActualIndex()
    // Bloque de hora seleccionado: 0..14 (08:00 a 19:40)
    property int horaSeleccionada: obtenerHoraActualIndex()
    // Categoría: 0=Todos Libres, 1=Módulos AD, 2=Aulas A/AE/AF, 3=Salones Escuela, 4=Ocupados
    property int categoriaFiltro: 0
    property string textoBusqueda: ""

    readonly property var listaDias: [
        { corto: "Lun", nombre: "Lunes",     cod: "LU" },
        { corto: "Mar", nombre: "Martes",    cod: "MA" },
        { corto: "Mié", nombre: "Miércoles", cod: "MI" },
        { corto: "Jue", nombre: "Jueves",    cod: "JU" },
        { corto: "Vie", nombre: "Viernes",   cod: "VI" },
        { corto: "Sáb", nombre: "Sábado",    cod: "SA" }
    ]

    readonly property var listaHoras: [
        { cod: "0800", inicio: "08:00", fin: "08:50", etiqueta: "08:00 - 08:50", turno: "Mañana" },
        { cod: "0850", inicio: "08:50", fin: "09:40", etiqueta: "08:50 - 09:40", turno: "Mañana" },
        { cod: "0940", inicio: "09:40", fin: "10:30", etiqueta: "09:40 - 10:30", turno: "Mañana" },
        { cod: "1030", inicio: "10:30", fin: "11:20", etiqueta: "10:30 - 11:20", turno: "Mañana" },
        { cod: "1120", inicio: "11:20", fin: "12:10", etiqueta: "11:20 - 12:10", turno: "Mediodía" },
        { cod: "1210", inicio: "12:10", fin: "01:00", etiqueta: "12:10 - 01:00", turno: "Mediodía" },
        { cod: "1300", inicio: "01:00", fin: "01:50", etiqueta: "01:00 - 01:50", turno: "Tarde" },
        { cod: "1350", inicio: "01:50", fin: "02:40", etiqueta: "01:50 - 02:40", turno: "Tarde" },
        { cod: "1440", inicio: "02:40", fin: "03:30", etiqueta: "02:40 - 03:30", turno: "Tarde" },
        { cod: "1530", inicio: "03:30", fin: "04:20", etiqueta: "03:30 - 04:20", turno: "Tarde" },
        { cod: "1620", inicio: "04:20", fin: "05:10", etiqueta: "04:20 - 05:10", turno: "Tarde" },
        { cod: "1710", inicio: "05:10", fin: "06:00", etiqueta: "05:10 - 06:00", turno: "Tarde" },
        { cod: "1800", inicio: "06:00", fin: "06:50", etiqueta: "06:00 - 06:50", turno: "Noche" },
        { cod: "1850", inicio: "06:50", fin: "07:40", etiqueta: "06:50 - 07:40", turno: "Noche" },
        { cod: "1940", inicio: "07:40", fin: "08:30", etiqueta: "07:40 - 08:30", turno: "Noche" }
    ]

    function obtenerDiaActualIndex() {
        var jsDay = new Date().getDay(); // 0=Dom, 1=Lun .. 6=Sab
        if (jsDay >= 1 && jsDay <= 6) return jsDay - 1;
        return 0;
    }

    function obtenerHoraActualIndex() {
        var ahora = new Date();
        var minTotal = ahora.getHours() * 60 + ahora.getMinutes();
        // Límites superiores de cada bloque de 50 min:
        // 08:50(530), 09:40(580), 10:30(630), 11:20(680), 12:10(730), 13:00(780),
        // 13:50(830), 14:40(880), 15:30(930), 16:20(980), 17:10(1030), 18:00(1080),
        // 18:50(1130), 19:40(1180), 20:30(1230)
        var fines = [530, 580, 630, 680, 730, 780, 830, 880, 930, 980, 1030, 1080, 1130, 1180, 1230];
        if (minTotal < 480) return 0; // Antes de las 8:00 am -> mostrar bloque 08:00
        for (var i = 0; i < fines.length; i++) {
            if (minTotal < fines[i]) return i;
        }
        return 0;
    }

    function seleccionarAhoraMismo() {
        rootSalones.diaSeleccionado = obtenerDiaActualIndex();
        rootSalones.horaSeleccionada = obtenerHoraActualIndex();
        centrarChipHora(rootSalones.horaSeleccionada);
    }

    function centrarChipHora(idx) {
        var chipW = 104;
        var targetX = idx * (chipW + 8) - (flickHoras.width / 2) + (chipW / 2);
        flickHoras.contentX = Math.max(0, Math.min(targetX, Math.max(0, flickHoras.contentWidth - flickHoras.width)));
    }

    property int revisionHorarios: 0
    Connections {
        target: daeClient
        function onHorariosOfertaChanged() {
            rootSalones.revisionHorarios++;
        }
    }

    property var resultadoConsulta: {
        var rev = rootSalones.revisionHorarios;
        var tot = daeClient.totalSeccionesOferta;
        return daeClient.consultarSalonesDisponibles(
            rootSalones.diaSeleccionado,
            rootSalones.horaSeleccionada,
            rootSalones.categoriaFiltro,
            rootSalones.textoBusqueda
        );
    }

    readonly property int totalDisponibles: resultadoConsulta.totalDisponibles || 0
    readonly property int totalRestoDia: resultadoConsulta.totalRestoDia || 0
    readonly property int totalOcupados: resultadoConsulta.totalOcupados || 0
    readonly property var salonesFiltrados: resultadoConsulta.salones || []

    Component.onCompleted: {
        Qt.callLater(function() {
            centrarChipHora(rootSalones.horaSeleccionada);
        });
    }

    Flickable {
        id: flickPrincipal
        // Desplazamiento con el teclado:
        //   - Qt desplaza el contenido para dejar visible el campo enfocado
        //     cuando aparece el teclado, y no lo devuelve al cerrarlo;
        //   - por eso se guarda la posición del usuario (solo mientras él
        //     desplaza) y se restituye cuando el teclado se cierra.
        property real posicionScroll: 0
        property bool restaurandoScroll: false

        // Devuelve el contenido a la posición en la que estaba el usuario
        function restaurarPosicion() {
            restaurandoScroll = true;
            contentY = Math.max(0, Math.min(posicionScroll, Math.max(0, contentHeight - height)));
            restaurandoScroll = false;
        }

        // El temporizador va dentro de un Item: un Flickable solo admite
        // elementos gráficos como hijos, y un Timer suelto quedaría sin padre
        // (y por tanto nunca se dispararía).
        Item {
            width: 0
            height: 0

            Timer {
                id: timerTecladoSalones
                interval: 280
                onTriggered: {
                    flickPrincipal.restaurarPosicion();
                }
            }
        }

        // Cuando el teclado se cierra, Qt deja el contenido corrido:
        // se devuelve a la posición en la que estaba el usuario.
        Connections {
            target: daeClient
            function onTecladoVisibleChanged() {
                if (!daeClient.tecladoVisible) {
                    flickPrincipal.restaurarPosicion();
                }
            }
        }

        // Desplazamiento con el teclado:
        onContentYChanged: {
            if (!restaurandoScroll && (dragging || flicking)) {
                posicionScroll = contentY;
            }
        }

        anchors.fill: parent
        contentWidth: width
        contentHeight: colPrincipal.implicitHeight + 130
        clip: true

        ColumnLayout {
            id: colPrincipal
            width: parent.width
            spacing: 14

            // 1. CABECERA SUPERIOR CON BOTÓN VOLVER Y BOTÓN "AHORA MISMO"
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 22
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 12

                Rectangle {
                    id: btnVolver
                    width: 40; height: 40; radius: 20
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
                            ctx.lineWidth = 2.0;
                            ctx.lineCap = "round";
                            ctx.lineJoin = "round";
                            ctx.beginPath();
                            ctx.moveTo(11, 4); ctx.lineTo(5, 9); ctx.lineTo(11, 14);
                            ctx.moveTo(5, 9); ctx.lineTo(15, 9);
                            ctx.stroke();
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPressed: btnVolver.scale = 0.92
                        onReleased: btnVolver.scale = 1.0
                        onClicked: rootSalones.volver()
                    }
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: "Salones Disponibles"
                        color: temaApp.textoPrincipal
                        font.pixelSize: 20
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: "Aulas libres para estudiar por tu cuenta • DAE UC"
                        color: temaApp.textoSubtitulo
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    id: btnAhora
                    Layout.preferredHeight: 34
                    Layout.preferredWidth: rowAhora.implicitWidth + 22
                    radius: 17
                    color: Qt.rgba(temaApp.primario.r, temaApp.primario.g, temaApp.primario.b, temaApp.esClaro ? 0.14 : 0.25)
                    border.color: temaApp.acento
                    border.width: 1

                    RowLayout {
                        id: rowAhora
                        anchors.centerIn: parent
                        spacing: 5

                        Rectangle {
                            width: 7; height: 7; radius: 4
                            color: "#22c55e"
                        }

                        Text {
                            text: "Ahora"
                            color: temaApp.esClaro ? temaApp.primario : "#e0f2fe"
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPressed: btnAhora.scale = 0.93
                        onReleased: btnAhora.scale = 1.0
                        onClicked: rootSalones.seleccionarAhoraMismo()
                    }
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }
            }

            // 2. TARJETA RESUMEN DE DISPONIBILIDAD EN EL BLOQUE SELECCIONADO
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: 104
                radius: 22
                color: temaApp.vidrio
                border.color: temaApp.bordeVidrio
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: rootSalones.listaDias[rootSalones.diaSeleccionado].nombre + " • " +
                                  rootSalones.listaHoras[rootSalones.horaSeleccionada].etiqueta + " (" +
                                  rootSalones.listaHoras[rootSalones.horaSeleccionada].turno + ")"
                            color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                            font.pixelSize: 12
                            font.bold: true
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "54 salones monitoreados"
                            color: temaApp.textoMuted
                            font.pixelSize: 10
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Row {
                            anchors.fill: parent

                            // Métrica 1: Disponibles Ahora
                            Item {
                                width: parent.width / 3
                                height: parent.height

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 1
                                    Text {
                                        text: rootSalones.totalDisponibles
                                        color: temaApp.esClaro ? "#15803d" : "#4ade80"
                                        font.pixelSize: 22
                                        font.bold: true
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: "Salones Libres"
                                        color: temaApp.textoSubtitulo
                                        font.pixelSize: 10
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }

                                Rectangle {
                                    width: 1; height: 28
                                    color: temaApp.bordeVidrio
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            // Métrica 2: Libres todo el resto del día
                            Item {
                                width: parent.width / 3
                                height: parent.height

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 1
                                    Text {
                                        text: rootSalones.totalRestoDia
                                        color: temaApp.esClaro ? temaApp.primario : "#38bdf8"
                                        font.pixelSize: 22
                                        font.bold: true
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: "Libres Resto Día"
                                        color: temaApp.textoSubtitulo
                                        font.pixelSize: 10
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }

                                Rectangle {
                                    width: 1; height: 28
                                    color: temaApp.bordeVidrio
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            // Métrica 3: Con Clase / Ocupados
                            Item {
                                width: parent.width / 3
                                height: parent.height

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 1
                                    Text {
                                        text: rootSalones.totalOcupados
                                        color: temaApp.esClaro ? "#b45309" : "#fbbf24"
                                        font.pixelSize: 22
                                        font.bold: true
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: "Con Clases"
                                        color: temaApp.textoSubtitulo
                                        font.pixelSize: 10
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 3. SELECTOR DE DÍA DE LA SEMANA (LUNES A SÁBADO)
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 6

                Text {
                    text: "1. Selecciona el día"
                    color: temaApp.textoPrincipal
                    font.pixelSize: 12
                    font.bold: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: rootSalones.listaDias

                        delegate: Rectangle {
                            readonly property bool activo: index === rootSalones.diaSeleccionado
                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            radius: 12
                            color: activo
                                   ? (temaApp.esClaro ? temaApp.primario : temaApp.secundario)
                                   : temaApp.panel
                            border.color: activo ? temaApp.acento : temaApp.bordePanel
                            border.width: activo ? 1.5 : 1

                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.corto
                                color: activo ? "#ffffff" : temaApp.textoSecundario
                                font.pixelSize: 12
                                font.bold: activo
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: rootSalones.diaSeleccionado = index
                            }
                        }
                    }
                }
            }

            // 4. SELECTOR DE HORA / BLOQUE HORARIO (08:00 A 19:40)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20

                    Text {
                        text: "2. Selecciona el bloque de hora"
                        color: temaApp.textoPrincipal
                        font.pixelSize: 12
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "Desliza ↔"
                        color: temaApp.textoMuted
                        font.pixelSize: 10
                    }
                }

                Flickable {
                    id: flickHoras
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    contentWidth: rowHoras.implicitWidth + 40
                    contentHeight: 52
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Behavior on contentX {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }

                    Row {
                        id: rowHoras
                        x: 20
                        y: 2
                        spacing: 8

                        Repeater {
                            model: rootSalones.listaHoras

                            delegate: Rectangle {
                                readonly property bool activo: index === rootSalones.horaSeleccionada
                                width: 104
                                height: 46
                                radius: 14
                                color: activo
                                       ? (temaApp.esClaro ? temaApp.primario : temaApp.secundario)
                                       : temaApp.panel
                                border.color: activo ? temaApp.acento : temaApp.bordePanel
                                border.width: activo ? 1.5 : 1

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 1
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.etiqueta
                                        color: activo ? "#ffffff" : temaApp.textoPrincipal
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Bloque " + modelData.cod + " • " + modelData.turno
                                        color: activo ? "#dbeafe" : temaApp.textoMuted
                                        font.pixelSize: 9
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: rootSalones.horaSeleccionada = index
                                }
                            }
                        }
                    }
                }
            }

            // 5. BUSCADOR Y FILTROS POR TIPO DE SALÓN
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    Layout.preferredHeight: 44
                    radius: 16
                    color: temaApp.panel
                    border.color: inputBusqSalon.activeFocus ? temaApp.acento : temaApp.bordePanel
                    border.width: inputBusqSalon.activeFocus ? 1.5 : 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 12
                        spacing: 8

                        Canvas {
                            width: 16; height: 16
                            property color colorTrazo: temaApp.textoMuted
                            onColorTrazoChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.strokeStyle = colorTrazo;
                                ctx.lineWidth = 1.8;
                                ctx.lineCap = "round";
                                ctx.beginPath();
                                ctx.arc(7, 7, 4.8, 0, Math.PI * 2);
                                ctx.moveTo(10.5, 10.5); ctx.lineTo(14.5, 14.5);
                                ctx.stroke();
                            }
                        }

                        TextInput {
                            id: inputBusqSalon
                            Layout.fillWidth: true
                            color: temaApp.textoPrincipal
                            font.pixelSize: 13
                            clip: true
                            verticalAlignment: TextInput.AlignVCenter
                            onTextChanged: rootSalones.textoBusqueda = text

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "Buscar salón o zona (ej. A7E, AD1, Física, Eléctrica)..."
                                color: temaApp.textoMuted
                                font.pixelSize: 12
                                visible: !inputBusqSalon.text && !inputBusqSalon.activeFocus
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            width: 22; height: 22; radius: 11
                            color: temaApp.panelAlt
                            visible: inputBusqSalon.text.length > 0

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: temaApp.textoSecundario
                                font.pixelSize: 10
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    inputBusqSalon.text = ""
                                    rootSalones.textoBusqueda = ""
                                }
                            }
                        }
                    }
                }

                // Tira de filtros por categoría de salón
                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    contentWidth: rowCats.implicitWidth + 40
                    contentHeight: 34
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: rowCats
                        x: 20
                        spacing: 8

                        Repeater {
                            model: [
                                { id: 0, titulo: "Todos Libres (" + rootSalones.totalDisponibles + ")" },
                                { id: 1, titulo: "Módulos AD" },
                                { id: 2, titulo: "Aulas A / AE / AF" },
                                { id: 3, titulo: "Salones de Escuela" },
                                { id: 4, titulo: "Ocupados (" + rootSalones.totalOcupados + ")" }
                            ]

                            delegate: Rectangle {
                                readonly property bool activo: rootSalones.categoriaFiltro === modelData.id
                                height: 32
                                width: txtCat.implicitWidth + 24
                                radius: 16
                                color: activo
                                       ? (modelData.id === 4
                                          ? (temaApp.esClaro ? "#d97706" : "#b45309")
                                          : (temaApp.esClaro ? temaApp.primario : temaApp.secundario))
                                       : temaApp.panel
                                border.color: activo ? temaApp.acento : temaApp.bordePanel
                                border.width: 1

                                Text {
                                    id: txtCat
                                    anchors.centerIn: parent
                                    text: modelData.titulo
                                    color: activo ? "#ffffff" : temaApp.textoSecundario
                                    font.pixelSize: 11
                                    font.bold: activo
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: rootSalones.categoriaFiltro = modelData.id
                                }
                            }
                        }
                    }
                }
            }

            // 6. ESTADO VACÍO SI NO HAY COINCIDENCIAS
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: 130
                radius: 22
                color: temaApp.panel
                border.color: temaApp.bordePanel
                border.width: 1
                visible: rootSalones.salonesFiltrados.length === 0

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "No se encontraron salones con ese filtro"
                        color: temaApp.textoPrincipal
                        font.pixelSize: 14
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: "Prueba cambiando la categoría, el bloque de hora o el término buscado."
                        color: temaApp.textoMuted
                        font.pixelSize: 11
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // 7. LISTA DE TARJETAS DE SALONES DISPONIBLES (O OCUPADOS)
            Repeater {
                model: rootSalones.salonesFiltrados

                delegate: Rectangle {
                    id: cardSalon
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    Layout.preferredHeight: colCardSalon.implicitHeight + 26
                    radius: 22
                    color: temaApp.panel
                    border.color: modelData.disponible
                                  ? (modelData.todoElRestoDelDia ? "#4422c55e" : temaApp.bordePanel)
                                  : "#44f59e0b"
                    border.width: 1

                    ColumnLayout {
                        id: colCardSalon
                        anchors.fill: parent
                        anchors.margins: 13
                        spacing: 8

                        // Fila superior: Insignia del código de salón + Nombre + Ubicación + Botón "Mapa"
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 52
                                Layout.preferredHeight: 44
                                radius: 13
                                color: modelData.disponible
                                       ? (modelData.categoria === 1
                                          ? (temaApp.esClaro ? "#fef3c7" : "#3b2f13")
                                          : (modelData.categoria === 2
                                             ? (temaApp.esClaro ? "#dcfce7" : "#113225")
                                             : (temaApp.esClaro ? "#e0f2fe" : "#132a42")))
                                       : (temaApp.esClaro ? "#fee2e2" : "#3b181b")
                                border.color: modelData.disponible
                                              ? (modelData.categoria === 1
                                                 ? "#f59e0b"
                                                 : (modelData.categoria === 2 ? "#22c55e" : "#38bdf8"))
                                              : "#ef4444"
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.codigo
                                    color: modelData.disponible
                                           ? (modelData.categoria === 1
                                              ? (temaApp.esClaro ? "#b45309" : "#fbbf24")
                                              : (modelData.categoria === 2
                                                 ? (temaApp.esClaro ? "#15803d" : "#4ade80")
                                                 : (temaApp.esClaro ? "#0369a1" : "#38bdf8")))
                                           : (temaApp.esClaro ? "#b91c1c" : "#f87171")
                                    font.pixelSize: 13
                                    font.bold: true
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Text {
                                        text: modelData.nombre
                                        color: temaApp.textoPrincipal
                                        font.pixelSize: 14
                                        font.bold: true
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        height: 20
                                        width: lblEstado.implicitWidth + 14
                                        radius: 10
                                        color: modelData.disponible
                                               ? (modelData.todoElRestoDelDia
                                                  ? (temaApp.esClaro ? "#dcfce7" : "#133826")
                                                  : (temaApp.esClaro ? "#e0f2fe" : "#152c44"))
                                               : (temaApp.esClaro ? "#fef3c7" : "#3b2912")

                                        Text {
                                            id: lblEstado
                                            anchors.centerIn: parent
                                            text: modelData.estadoTexto
                                            color: modelData.disponible
                                                   ? (modelData.todoElRestoDelDia
                                                      ? (temaApp.esClaro ? "#15803d" : "#4ade80")
                                                      : (temaApp.esClaro ? "#0369a1" : "#38bdf8"))
                                                   : (temaApp.esClaro ? "#b45309" : "#fbbf24")
                                            font.pixelSize: 10
                                            font.bold: true
                                        }
                                    }
                                }

                                Text {
                                    text: modelData.sector
                                    color: temaApp.textoSubtitulo
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            // Botón rápido para ubicar el salón en el Mapa de la Facultad
                            Rectangle {
                                id: btnIrMapa
                                Layout.preferredWidth: 58
                                Layout.preferredHeight: 30
                                radius: 10
                                color: temaApp.panelAlt
                                border.color: temaApp.bordeAlt
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "Mapa ↗"
                                    color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                                    font.pixelSize: 10
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: rootSalones.verEnMapa(modelData.codigo)
                                }
                            }
                        }

                        // Fila intermedia: Próxima clase en ese salón (o clase actual si está ocupado)
                        Text {
                            text: modelData.detalleSub
                            color: modelData.disponible ? temaApp.textoSecundario : (temaApp.esClaro ? "#b45309" : "#fcd34d")
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        // Tira visual de ocupación del día (08:00 a 18:00 - 12 bloques diurnos)
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                Repeater {
                                    model: modelData.bloquesBarra

                                    delegate: ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: modelData.seleccionado ? 9 : 6
                                            radius: 3
                                            color: modelData.ocupado
                                                   ? (temaApp.esClaro ? "#fca5a5" : "#7f1d1d")
                                                   : (temaApp.esClaro ? "#4ade80" : "#16a34a")
                                            border.color: modelData.seleccionado
                                                          ? (temaApp.esClaro ? "#0f172a" : "#ffffff")
                                                          : "transparent"
                                            border.width: modelData.seleccionado ? 1.5 : 0
                                        }

                                        Text {
                                            text: modelData.hora.slice(0, 2)
                                            color: modelData.seleccionado ? temaApp.textoPrincipal : temaApp.textoMuted
                                            font.pixelSize: 8
                                            font.bold: modelData.seleccionado
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
