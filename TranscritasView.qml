import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: rootReporte

    // 0 = Con Acta (42), 1 = Semestre en Curso / Sin Transcribir (9), 2 = Laboratorios (2)
    property int filtroEstado: 0
    property string textoBusqueda: ""

    // 1. ASIGNATURAS DEL SEMESTRE EN CURSO (Sincronizadas con el estudiante autenticado)
    property var materiasSemestreActualBase: []

    property var materiasSemestreActual: daeClient.materiasSinTranscribir || []

    // 2. HISTORIAL LIMPIO DE ACTAS TRANSCRITAS (Sincronizadas con el estudiante autenticado)
    property var listaRegistrosBase: []

    property var listaRegistros: daeClient.notasTranscritas || []

    function contarLaboratoriosTranscritos() {
        var c = 0;
        for (var i = 0; i < listaRegistros.length; i++) {
            var item = listaRegistros[i];
            if (item.codigo.indexOf("L") !== -1 || item.nombre.indexOf("LAB") !== -1) c++;
        }
        return c;
    }

    function obtenerUltimaFechaCorta() {
        if (!listaRegistros || listaRegistros.length === 0) return "—";
        var f = listaRegistros[0].fecha || "";
        var partes = f.split("/");
        if (partes.length >= 2) {
            var meses = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"];
            var mIdx = parseInt(partes[1], 10) - 1;
            if (mIdx >= 0 && mIdx < 12) return partes[0] + " " + meses[mIdx];
        }
        return f;
    }

    function normalizarTextoBusqueda(txt) {
        if (!txt) return "";
        return String(txt).toUpperCase()
            .replace(/[ÁÀÄÂ]/g, "A")
            .replace(/[ÉÈËÊ]/g, "E")
            .replace(/[ÍÌÏÎ]/g, "I")
            .replace(/[ÓÒÖÔ]/g, "O")
            .replace(/[ÚÙÜÛ]/g, "U")
            .replace(/Ñ/g, "N")
            .trim();
    }

    function coincideBusqueda(textoCompleto, busqueda) {
        var q = normalizarTextoBusqueda(busqueda);
        if (q === "") return true;
        var base = normalizarTextoBusqueda(textoCompleto);
        var palabras = q.split(/\s+/);
        for (var k = 0; k < palabras.length; k++) {
            if (palabras[k] !== "" && base.indexOf(palabras[k]) === -1) {
                return false;
            }
        }
        return true;
    }

    function filtrarRegistros(estado, busqueda) {
        var fuente = (estado === 1) ? materiasSemestreActual : listaRegistros;
        var salida = [];

        for (var i = 0; i < fuente.length; i++) {
            var item = fuente[i];

            // Si está en el filtro de Laboratorios (estado === 2)
            if (estado === 2 && item.codigo.indexOf("L") === -1 && item.nombre.indexOf("LAB") === -1) continue;

            // Filtro por buscador (insensible a tildes y mayúsculas/minúsculas)
            if (busqueda !== "") {
                var textoItem = (item.nombre || "") + " " + (item.codigo || "") + " " + (item.periodo || "") + " " + (item.fecha || "");
                if (!coincideBusqueda(textoItem, busqueda)) continue;
            }
            salida.push(item);
        }
        return salida;
    }

    function obtenerEstadoVisual(item) {
        if (item.sinTranscribir) return "PEND";
        var f = parseInt(item.nFin);
        if (!isNaN(f) && f >= 10) return "APROB";
        if (item.nRec !== "") {
            var r = parseInt(item.nRec);
            if (!isNaN(r) && r >= 10) return "REC";
        }
        return "REP";
    }

    function obtenerNotaDefinitiva(item) {
        if (item.sinTranscribir) return "—";
        if (item.nRec !== "") return item.nRec;
        return item.nFin;
    }

    Flickable {
        id: flickTranscritas
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
                id: timerTecladoTranscritas
                interval: 280
                onTriggered: {
                    flickTranscritas.restaurarPosicion();
                }
            }
        }

        // Cuando el teclado se cierra, Qt deja el contenido corrido:
        // se devuelve a la posición en la que estaba el usuario.
        Connections {
            target: daeClient
            function onTecladoVisibleChanged() {
                if (!daeClient.tecladoVisible) {
                    flickTranscritas.restaurarPosicion();
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

            // 1. CABECERA PRINCIPAL
            RowLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: rootReporte.width - 44
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
                        text: "Notas Transcritas"
                        color: temaApp.textoPrincipal
                        font.pixelSize: 22
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: daeClient.escuelaCorta + " • Auditoría de Actas"
                        color: temaApp.textoSubtitulo
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    Layout.preferredWidth: rowSync.implicitWidth + 20
                    Layout.preferredHeight: 34
                    Layout.fillWidth: false
                    radius: 17
                    color: temaApp.vidrio
                    border.color: temaApp.bordeVidrio
                    border.width: 1

                    RowLayout {
                        id: rowSync
                        anchors.centerIn: parent
                        spacing: 6

                        Rectangle {
                            Layout.preferredWidth: 8
                            Layout.preferredHeight: 8
                            radius: 4
                            color: "#22c55e"
                        }
                        Text {
                            text: "Actas al día"
                            color: temaApp.textoPrincipal
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }
                }
            }

            // 2. BANNER OFICIAL DE ADVERTENCIA DE PRELACIONES
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: rootReporte.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: 68
                radius: 20
                color: temaApp.esClaro ? "#fef3c7" : "#22f59e0b"
                border.color: temaApp.esClaro ? "#f59e0b" : "#60fbbf24"
                border.width: 1
                clip: true

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        Layout.fillWidth: false
                        radius: 12
                        color: temaApp.esClaro ? "#fde68a" : "#35f59e0b"
                        border.color: "#f59e0b"
                        border.width: 1

                        Canvas {
                            width: 20; height: 20
                            anchors.centerIn: parent
                            property bool modoClaro: temaApp.esClaro
                            onModoClaroChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.strokeStyle = modoClaro ? "#b45309" : "#fde68a";
                                ctx.fillStyle = modoClaro ? "#b45309" : "#fde68a";
                                ctx.lineWidth = 2.0;
                                ctx.lineCap = "round";
                                ctx.lineJoin = "round";

                                ctx.beginPath();
                                ctx.moveTo(10, 3);
                                ctx.lineTo(18, 17);
                                ctx.lineTo(2, 17);
                                ctx.closePath();
                                ctx.stroke();

                                ctx.beginPath();
                                ctx.moveTo(10, 8.5);
                                ctx.lineTo(10, 12);
                                ctx.stroke();
                                ctx.beginPath();
                                ctx.arc(10, 14.5, 1, 0, Math.PI * 2);
                                ctx.fill();
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        Layout.minimumWidth: 0
                        spacing: 2
                        Text {
                            text: "IMPORTANTE: ESTE ES SÓLO UN REPORTE"
                            color: temaApp.esClaro ? "#92400e" : "#fef08a"
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 0.4
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: "Es necesario revisar las prelaciones. Las calificaciones válidas son las registradas en Expediente."
                            color: temaApp.esClaro ? "#78350f" : "#e2e8f0"
                            font.pixelSize: 10
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // 3. TARJETA RESUMEN DE AUDITORÍA (4 Columnas 100% Centradas Matemáticamente)
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: rootReporte.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: 76
                radius: 22
                color: temaApp.vidrio
                border.color: temaApp.bordeVidrio
                border.width: 1

                Item {
                    anchors.fill: parent
                    anchors.margins: 10

                    Row {
                        anchors.fill: parent

                        // Columna 1: Actas Transcritas Oficiales
                        Item {
                            width: parent.width / 4; height: parent.height
                            Column {
                                anchors.centerIn: parent; spacing: 2
                                Text { text: rootReporte.listaRegistros.length; color: temaApp.esClaro ? "#15803d" : "#4ade80"; font.pixelSize: 21; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                                Text { text: "Transcritas"; color: temaApp.textoSubtitulo; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter }
                            }
                            Rectangle { width: 1; height: 30; color: temaApp.bordeVidrio; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter }
                        }

                        // Columna 2: En Curso (Por transcribir al final del semestre)
                        Item {
                            width: parent.width / 4; height: parent.height
                            Column {
                                anchors.centerIn: parent; spacing: 2
                                Text { text: rootReporte.materiasSemestreActual.length; color: temaApp.esClaro ? "#b45309" : "#fbbf24"; font.pixelSize: 21; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                                Text { text: "En Curso"; color: temaApp.textoSubtitulo; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter }
                            }
                            Rectangle { width: 1; height: 30; color: temaApp.bordeVidrio; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter }
                        }

                        // Columna 3: Laboratorios Transcritos
                        Item {
                            width: parent.width / 4; height: parent.height
                            Column {
                                anchors.centerIn: parent; spacing: 2
                                Text { text: rootReporte.contarLaboratoriosTranscritos(); color: temaApp.textoPrincipal; font.pixelSize: 21; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                                Text { text: "Labs (L)"; color: temaApp.textoSubtitulo; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter }
                            }
                            Rectangle { width: 1; height: 30; color: temaApp.bordeVidrio; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter }
                        }

                        // Columna 4: Última Fecha de Carga
                        Item {
                            width: parent.width / 4; height: parent.height
                            Column {
                                anchors.centerIn: parent; spacing: 2
                                Text { text: rootReporte.obtenerUltimaFechaCorta(); color: temaApp.esClaro ? temaApp.primario : temaApp.claro; font.pixelSize: 17; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                                Text { text: "Última Acta"; color: temaApp.textoSubtitulo; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter }
                            }
                        }
                    }
                }
            }

            // 4. BARRA DE BÚSQUEDA
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: rootReporte.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: 46
                radius: 23
                color: temaApp.panelAlt
                border.color: inputBuscarActa.activeFocus ? temaApp.acento : temaApp.bordeAlt
                border.width: 1
                clip: true

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 14
                    spacing: 10

                    Canvas {
                        Layout.preferredWidth: 18; Layout.preferredHeight: 18
                        Layout.fillWidth: false
                        Layout.alignment: Qt.AlignVCenter
                        property color colorTema: temaApp.esClaro ? temaApp.primario : temaApp.claro
                        onColorTemaChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = colorTema;
                            ctx.lineWidth = 2.0;
                            ctx.lineCap = "round";
                            ctx.beginPath(); ctx.arc(8, 8, 5.5, 0, Math.PI * 2); ctx.stroke();
                            ctx.beginPath(); ctx.moveTo(12.2, 12.2); ctx.lineTo(16, 16); ctx.stroke();
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        Layout.minimumWidth: 0
                        Layout.fillHeight: true
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Buscar por asignatura, código o fecha (ej. 2026)..."
                            color: temaApp.textoMuted
                            font.pixelSize: 12
                            visible: inputBuscarActa.text === ""
                            elide: Text.ElideRight
                            width: parent.width
                        }
                        TextInput {
                            id: inputBuscarActa
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            color: temaApp.textoPrincipal
                            font.pixelSize: 13
                            selectByMouse: true
                            clip: true
                            onTextChanged: rootReporte.textoBusqueda = text.trim().toUpperCase()
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 22; Layout.preferredHeight: 22; radius: 11
                        Layout.fillWidth: false
                        color: temaApp.esClaro ? "#e2e8f0" : "#28ffffff"
                        visible: inputBuscarActa.text !== ""
                        Canvas {
                            width: 10; height: 10
                            anchors.centerIn: parent
                            property color colorTrazo: temaApp.textoPrincipal
                            onColorTrazoChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.strokeStyle = colorTrazo;
                                ctx.lineWidth = 1.8;
                                ctx.lineCap = "round";
                                ctx.beginPath();
                                ctx.moveTo(2, 2); ctx.lineTo(8, 8);
                                ctx.moveTo(8, 2); ctx.lineTo(2, 8);
                                ctx.stroke();
                            }
                        }
                        MouseArea { anchors.fill: parent; onClicked: inputBuscarActa.text = "" }
                    }
                }
            }

            // 5. PÍLDORAS DE FILTRO RÁPIDO
            Flickable {
                Layout.fillWidth: true
                Layout.maximumWidth: rootReporte.width
                Layout.minimumWidth: 0
                Layout.preferredHeight: 36
                contentWidth: rowFiltros.implicitWidth + 40
                clip: true

                Row {
                    id: rowFiltros
                    x: 20
                    spacing: 8

                    Repeater {
                        model: [
                            { idx: 0, texto: "Transcritas (" + rootReporte.listaRegistros.length + ")" },
                            { idx: 1, texto: "Sin Transcribir • En Curso (" + rootReporte.materiasSemestreActual.length + ")" },
                            { idx: 2, texto: "Laboratorios (" + rootReporte.contarLaboratoriosTranscritos() + ")" }
                        ]

                        delegate: Rectangle {
                            property bool sel: rootReporte.filtroEstado === modelData.idx
                            width: txtPildora.implicitWidth + 24
                            height: 34; radius: 17
                            color: sel ? (modelData.idx === 1 ? "#d97706" : temaApp.primario) : temaApp.panelAlt
                            border.color: sel ? temaApp.claro : temaApp.bordeAlt
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 180 } }

                            Text {
                                id: txtPildora
                                anchors.centerIn: parent
                                text: modelData.texto
                                color: sel ? "white" : temaApp.textoSecundario
                                font.pixelSize: 11
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: rootReporte.filtroEstado = modelData.idx
                            }
                        }
                    }
                }
            }

            // 6. AVISO ESPECIAL CUANDO ESTÁS EN "SIN TRANSCRIBIR • EN CURSO"
            Rectangle {
                visible: rootReporte.filtroEstado === 1
                Layout.fillWidth: true
                Layout.maximumWidth: rootReporte.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: 74
                radius: 20
                color: temaApp.panelAlt
                border.color: temaApp.primario
                border.width: 1
                clip: true

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 40; Layout.preferredHeight: 40; radius: 12
                        Layout.fillWidth: false
                        color: temaApp.esClaro ? temaApp.suave : Qt.rgba(temaApp.primario.r, temaApp.primario.g, temaApp.primario.b, 0.22)
                        border.color: temaApp.acento
                        Canvas {
                            width: 20; height: 20
                            anchors.centerIn: parent
                            property color colorTema: temaApp.esClaro ? temaApp.primario : temaApp.claro
                            onColorTemaChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.strokeStyle = colorTema;
                                ctx.lineWidth = 1.8;
                                ctx.lineCap = "round";
                                ctx.strokeRect(3, 4, 14, 13);
                                ctx.beginPath();
                                ctx.moveTo(3, 8); ctx.lineTo(17, 8);
                                ctx.moveTo(7, 2); ctx.lineTo(7, 5);
                                ctx.moveTo(13, 2); ctx.lineTo(13, 5);
                                ctx.stroke();
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        Layout.minimumWidth: 0
                        spacing: 2
                        Text {
                            text: "Semana de Transcripción de Notas"
                            color: temaApp.textoPrincipal
                            font.pixelSize: 13
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: "Las materias del semestre en curso aparecerán reflejadas en el reporte oficial del DAE cuando inicie la semana de transcripción según el calendario."
                            color: temaApp.textoSubtitulo
                            font.pixelSize: 10
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // 7. LISTA DE TARJETAS DE REGISTRO (Con anclajes fijos para que el cuadro derecho JAMÁS se salga)
            Repeater {
                model: rootReporte.filtrarRegistros(rootReporte.filtroEstado, rootReporte.textoBusqueda)

                delegate: Rectangle {
                    property string est: rootReporte.obtenerEstadoVisual(modelData)

                    Layout.fillWidth: true
                    Layout.maximumWidth: rootReporte.width - 40
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    Layout.preferredHeight: 92
                    radius: 20
                    color: temaApp.panel
                    border.color: est === "PEND" ? "#60f59e0b" : temaApp.bordePanel
                    border.width: 1
                    clip: true

                    // 1. Barra vertical izquierda fija
                    Rectangle {
                        id: barraLateral
                        width: 4
                        height: 60
                        radius: 2
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        color: est === "APROB" ? "#22c55e" : (est === "REC" ? "#38bdf8" : (est === "PEND" ? "#fbbf24" : "#ef4444"))
                    }

                    // 2. Cuadro de Nota / "CURSANDO" FIJO a la derecha (Imposible que se salga)
                    Rectangle {
                        id: cajaNota
                        width: 52
                        height: 52
                        radius: 15
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        color: temaApp.esClaro
                               ? (est === "APROB" ? "#dcfce7" : (est === "REC" ? "#e0f2fe" : (est === "PEND" ? "#fef3c7" : "#fee2e2")))
                               : (est === "APROB" ? "#163828" : (est === "REC" ? "#0f2942" : (est === "PEND" ? "#3b2a10" : "#3b151e")))
                        border.color: est === "APROB" ? "#22c55e" : (est === "REC" ? "#38bdf8" : (est === "PEND" ? "#fbbf24" : "#ef4444"))
                        border.width: 1.5

                        Column {
                            anchors.centerIn: parent
                            spacing: 0

                            Text {
                                text: rootReporte.obtenerNotaDefinitiva(modelData)
                                color: temaApp.esClaro
                                       ? (est === "APROB" ? "#15803d" : (est === "REC" ? "#0369a1" : (est === "PEND" ? "#b45309" : "#b91c1c")))
                                       : (est === "APROB" ? "#4ade80" : (est === "REC" ? "#38bdf8" : (est === "PEND" ? "#fbbf24" : "#f87171")))
                                font.pixelSize: 16
                                font.bold: true
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: est === "PEND" ? "EN CURSO" : (est === "REC" ? "REC" : "FIN")
                                color: temaApp.esClaro ? "#475569" : "#cbd5e1"
                                font.pixelSize: 7
                                font.bold: true
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    // 3. Columna central encerrada estrictamente entre la barra izquierda y el cuadro derecho
                    Column {
                        anchors.left: barraLateral.right
                        anchors.leftMargin: 12
                        anchors.right: cajaNota.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        // Fila 1: Nombre de la Asignatura
                        Text {
                            width: parent.width
                            text: modelData.nombre
                            color: temaApp.textoPrincipal
                            font.pixelSize: 13
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        // Fila 2: Código + Período + Sección
                        Row {
                            spacing: 6

                            Rectangle {
                                width: txtCod.implicitWidth + 10
                                height: 18; radius: 6
                                color: temaApp.esClaro ? temaApp.suave : Qt.rgba(temaApp.primario.r, temaApp.primario.g, temaApp.primario.b, 0.22)
                                Text {
                                    id: txtCod
                                    anchors.centerIn: parent
                                    text: modelData.codigo
                                    color: temaApp.esClaro ? temaApp.oscuro : temaApp.claro
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }

                            Rectangle {
                                width: txtPer.implicitWidth + 10
                                height: 18; radius: 6
                                color: modelData.sinTranscribir
                                       ? (temaApp.esClaro ? "#fef3c7" : "#3b2a10")
                                       : (modelData.periodo.indexOf("V") !== -1 ? (temaApp.esClaro ? "#ede9fe" : "#3b1d6e") : temaApp.panelAlt)
                                border.color: modelData.sinTranscribir ? "#f59e0b" : (modelData.periodo.indexOf("V") !== -1 ? "#8b5cf6" : temaApp.bordeAlt)
                                Text {
                                    id: txtPer
                                    anchors.centerIn: parent
                                    text: modelData.periodo
                                    color: modelData.sinTranscribir
                                           ? (temaApp.esClaro ? "#b45309" : "#fde68a")
                                           : (modelData.periodo.indexOf("V") !== -1 ? (temaApp.esClaro ? "#6d28d9" : "#ddd6fe") : temaApp.textoSecundario)
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Sec. " + modelData.sec
                                color: temaApp.textoSecundario
                                font.pixelSize: 11
                            }

                            Rectangle {
                                visible: modelData.nRec !== ""
                                width: txtDesglose.implicitWidth + 10
                                height: 18; radius: 6
                                color: temaApp.panelAlt
                                Text {
                                    id: txtDesglose
                                    anchors.centerIn: parent
                                    text: "Fin: " + modelData.nFin + " → Rec: " + modelData.nRec
                                    color: temaApp.esClaro ? "#0369a1" : "#38bdf8"
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                            }
                        }

                        // Fila 3: Estado de transcripción o Fecha (con ancho controlado para no empujar nada)
                        Row {
                            width: parent.width
                            spacing: 5

                            Canvas {
                                id: iconoRelojito
                                width: 12; height: 12
                                anchors.verticalCenter: parent.verticalCenter
                                property bool modoClaro: temaApp.esClaro
                                onModoClaroChanged: requestPaint()
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.reset();
                                    ctx.strokeStyle = est === "PEND" ? (modoClaro ? "#d97706" : "#fbbf24") : "#64748b";
                                    ctx.lineWidth = 1.4;
                                    ctx.beginPath();
                                    ctx.arc(6, 6, 4.8, 0, Math.PI * 2);
                                    ctx.moveTo(6, 3.5); ctx.lineTo(6, 6.2); ctx.lineTo(8, 7.2);
                                    ctx.stroke();
                                }
                            }

                            Text {
                                width: parent.width - 18
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.sinTranscribir
                                      ? "SIN TRANSCRIBIR • " + modelData.hora
                                      : "Registrada: " + modelData.fecha + " (" + modelData.hora + ")"
                                color: modelData.sinTranscribir ? (temaApp.esClaro ? "#d97706" : "#fbbf24") : temaApp.textoMuted
                                font.pixelSize: 10
                                font.bold: modelData.sinTranscribir
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}
