import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: rootRap

    signal volver()

    // 0 = Todas (68), 1 = Cumple Requisitos (6), 2 = Aprobadas (33), 3 = No Cumple / Preladas (29)
    property int filtroCondicion: 0
    // 0 = Todos los semestres, 5..10 = Semestre específico, 1 = Ciclo Básico (1 al 4)
    property int filtroSemestre: 0
    property string textoBusqueda: ""

    // Catálogo del RAP (Requisitos de Avance en el Pensum) sincronizado con el estudiante autenticado
    // Estados: "APROB"    = Asignatura Aprobada
    //          "CUMPLE"   = Cumple los Requisitos para Inscripción
    //          "ART17"    = Puede Inscribir por Artículo 17 (En paralelo con prelación reprobada)
    //          "NOCUMPLE" = NO Cumple con los Requisitos para su Inscripción
    property var listaRap: []

    property var fuenteRapActiva: daeClient.materiasRap || []

    function contarEstadoRap(estBuscado) {
        var c = 0;
        for (var i = 0; i < fuenteRapActiva.length; i++) {
            if (fuenteRapActiva[i].estado === estBuscado) c++;
        }
        return c;
    }

    function contarInscribiblesRap() {
        var c = 0;
        for (var i = 0; i < fuenteRapActiva.length; i++) {
            var e = fuenteRapActiva[i].estado;
            if (e === "CUMPLE" || e === "ART17") c++;
        }
        return c;
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

    function filtrarMateriasRap(condicion, semestre, busqueda) {
        var fuenteRap = fuenteRapActiva;
        var res = [];
        for (var i = 0; i < fuenteRap.length; i++) {
            var item = fuenteRap[i];

            if (condicion === 1 && item.estado !== "CUMPLE" && item.estado !== "ART17") continue;
            if (condicion === 2 && item.estado !== "APROB") continue;
            if (condicion === 3 && item.estado !== "NOCUMPLE") continue;
            if (condicion === 4 && item.estado !== "ART17") continue;

            if (semestre === 1 && item.sem > 4) continue;
            if (semestre >= 5 && item.sem !== semestre) continue;

            if (busqueda !== "") {
                var textoItem = (item.nombre || "") + " " + (item.codigo || "") + " " + (item.req || "");
                if (!coincideBusqueda(textoItem, busqueda)) continue;
            }

            res.push(item);
        }
        return res;
    }

    function textoCondicionOficial(estado) {
        if (estado === "APROB") return "Asignatura Aprobada";
        if (estado === "CUMPLE") return "Cumple los Requisitos para Inscripción";
        if (estado === "ART17") return "Puede Inscribir por Artículo 17";
        return "NO Cumple con los Requisitos para su Inscripción";
    }

    function obtenerListaRequisitos(reqStr) {
        if (!reqStr || reqStr === "") return [];
        return reqStr.split(",");
    }

    Flickable {
        id: flickRap
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
                id: timerTecladoRap
                interval: 280
                onTriggered: {
                    flickRap.restaurarPosicion();
                }
            }
        }

        // Cuando el teclado se cierra, Qt deja el contenido corrido:
        // se devuelve a la posición en la que estaba el usuario.
        Connections {
            target: daeClient
            function onTecladoVisibleChanged() {
                if (!daeClient.tecladoVisible) {
                    flickRap.restaurarPosicion();
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
        contentHeight: colRap.implicitHeight + 135
        clip: true

        ColumnLayout {
            id: colRap
            width: flickRap.width
            spacing: 14

            // 1. CABECERA CON BOTÓN DE REGRESO A SERVICIOS DAE
            RowLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: flickRap.width - 40
                Layout.topMargin: 24
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 10

                Rectangle {
                    id: btnVolverRap
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
                        onPressed: btnVolverRap.scale = 0.90
                        onReleased: btnVolverRap.scale = 1.0
                        onClicked: rootRap.volver()
                    }
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    spacing: 1
                    Text {
                        text: "Visualizar RAP"
                        color: temaApp.textoPrincipal
                        font.pixelSize: 20
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: daeClient.escuelaCorta + " • Prelaciones RAP"
                        color: temaApp.textoSubtitulo
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    Layout.preferredWidth: rowBadgeUc.implicitWidth + 16
                    Layout.preferredHeight: 32
                    radius: 16
                    color: temaApp.vidrio
                    border.color: temaApp.bordeVidrio
                    border.width: 1

                    RowLayout {
                        id: rowBadgeUc
                        anchors.centerIn: parent
                        spacing: 5

                        Rectangle {
                            width: 7; height: 7; radius: 3.5
                            color: temaApp.acento
                        }
                        Text {
                            text: daeClient.ucAprobadasCarrera + " U.C."
                            color: temaApp.textoPrincipal
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }
                }
            }

            // 2. TARJETA DE RESUMEN DE AVANCE Y HITOS DE U.C.
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: flickRap.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: 172
                radius: 24
                color: temaApp.vidrio
                border.color: temaApp.bordeVidrio
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 9

                    // 4 Métricas superiores centradas matemáticamente (25% c/u)
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44

                        Row {
                            anchors.fill: parent

                            // Col 1: Aprobadas
                            Item {
                                width: parent.width / 4; height: parent.height
                                Column {
                                    anchors.centerIn: parent; spacing: 2
                                    Text {
                                        text: rootRap.contarEstadoRap("APROB")
                                        color: temaApp.esClaro ? "#0369a1" : "#38bdf8"
                                        font.pixelSize: 21; font.bold: true
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: "Aprobadas"
                                        color: temaApp.textoSubtitulo
                                        font.pixelSize: 10
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                                Rectangle { width: 1; height: 28; color: temaApp.bordeVidrio; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter }
                            }

                            // Col 2: Cumple Requisitos + Artículo 17 (Inscribibles)
                            Item {
                                width: parent.width / 4; height: parent.height
                                Column {
                                    anchors.centerIn: parent; spacing: 2
                                    Text {
                                        text: rootRap.contarInscribiblesRap()
                                        color: temaApp.esClaro ? "#b45309" : "#fbbf24"
                                        font.pixelSize: 21; font.bold: true
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: "Inscribibles"
                                        color: temaApp.textoSubtitulo
                                        font.pixelSize: 10
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                                Rectangle { width: 1; height: 28; color: temaApp.bordeVidrio; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter }
                            }

                            // Col 3: Preladas / No Cumple
                            Item {
                                width: parent.width / 4; height: parent.height
                                Column {
                                    anchors.centerIn: parent; spacing: 2
                                    Text {
                                        text: rootRap.contarEstadoRap("NOCUMPLE")
                                        color: temaApp.textoPrincipal
                                        font.pixelSize: 21; font.bold: true
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: "Preladas"
                                        color: temaApp.textoSubtitulo
                                        font.pixelSize: 10
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                                Rectangle { width: 1; height: 28; color: temaApp.bordeVidrio; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter }
                            }

                            // Col 4: Porcentaje de avance
                            Item {
                                width: parent.width / 4; height: parent.height
                                Column {
                                    anchors.centerIn: parent; spacing: 2
                                    Text {
                                        text: rootRap.fuenteRapActiva.length > 0
                                              ? ((rootRap.contarEstadoRap("APROB") * 100.0) / rootRap.fuenteRapActiva.length).toFixed(1) + "%"
                                              : "0.0%"
                                        color: temaApp.esClaro ? "#15803d" : "#4ade80"
                                        font.pixelSize: 19; font.bold: true
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: "Avance RAP"
                                        color: temaApp.textoSubtitulo
                                        font.pixelSize: 10
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: temaApp.bordeVidrio }

                    // Barra de progreso segmentada limpia (Dibujada en Canvas con bordes redondeados perfectos)
                    Canvas {
                        id: barraProgresoRap
                        Layout.fillWidth: true
                        Layout.preferredHeight: 10
                        property bool modoClaro: temaApp.esClaro
                        property var fuenteDatos: rootRap.fuenteRapActiva
                        onModoClaroChanged: requestPaint()
                        onFuenteDatosChanged: requestPaint()
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            var w = width;
                            var h = height;
                            if (w <= 0 || h <= 0) return;

                            var r = h / 2;
                            var gap = 3;
                            var totalM = Math.max(1, rootRap.fuenteRapActiva.length);
                            var cAprob = rootRap.contarEstadoRap("APROB");
                            var cCumple = rootRap.contarInscribiblesRap();
                            var wAprob = Math.max(h, (w - gap * 2) * (cAprob / totalM));
                            var wCumple = Math.max(h, (w - gap * 2) * (cCumple / totalM));
                            var xCumple = wAprob + gap;
                            var xPrel = xCumple + wCumple + gap;
                            var wPrel = Math.max(h, w - xPrel);

                            function pildora(x, y, pw, ph, rad, color) {
                                ctx.beginPath();
                                ctx.moveTo(x + rad, y);
                                ctx.lineTo(x + pw - rad, y);
                                ctx.arc(x + pw - rad, y + rad, rad, -Math.PI / 2, Math.PI / 2);
                                ctx.lineTo(x + rad, y + ph);
                                ctx.arc(x + rad, y + rad, rad, Math.PI / 2, -Math.PI / 2);
                                ctx.closePath();
                                ctx.fillStyle = color;
                                ctx.fill();
                            }

                            // 1. Píldora Azul (Aprobadas)
                            pildora(0, 0, wAprob, h, r, "#38bdf8");
                            // 2. Píldora Ámbar (Cumple Requisitos / Artículo 17)
                            pildora(xCumple, 0, wCumple, h, r, "#fbbf24");
                            // 3. Píldora Restante (Preladas)
                            pildora(xPrel, 0, wPrel, h, r, modoClaro ? "#cbd5e1" : "#1e293b");
                        }
                    }

                    // Hitos de Unidades de Crédito (Divididos exactamente 50% y 50% sin desbordar)
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44

                        Row {
                            anchors.fill: parent
                            spacing: 8

                            // Hito 100 U.C.
                            Rectangle {
                                width: (parent.width - 8) / 2
                                height: parent.height
                                radius: 12
                                color: temaApp.panelAlt
                                border.color: temaApp.bordeAlt
                                border.width: 1
                                clip: true

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 7

                                    Rectangle {
                                        width: 26; height: 26; radius: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: temaApp.esClaro ? "#fef3c7" : "#3b2a10"
                                        border.color: "#f59e0b"
                                        Text {
                                            anchors.centerIn: parent
                                            text: "100"
                                            color: temaApp.esClaro ? "#b45309" : "#fbbf24"
                                            font.pixelSize: 9; font.bold: true
                                        }
                                    }

                                    Column {
                                        width: parent.width - 35
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 1
                                        Text {
                                            width: parent.width
                                            text: "Hito 100 U.C."
                                            color: temaApp.textoPrincipal
                                            font.pixelSize: 10; font.bold: true
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            width: parent.width
                                            text: daeClient.ucAprobadasCarrera >= 100
                                                  ? "✓ Hito alcanzado"
                                                  : ("Faltan " + (100 - daeClient.ucAprobadasCarrera) + " U.C.")
                                            color: temaApp.esClaro ? "#b45309" : "#fbbf24"
                                            font.pixelSize: 9
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }

                            // Hito 130 U.C.
                            Rectangle {
                                width: (parent.width - 8) / 2
                                height: parent.height
                                radius: 12
                                color: temaApp.panelAlt
                                border.color: temaApp.bordeAlt
                                border.width: 1
                                clip: true

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 7

                                    Rectangle {
                                        width: 26; height: 26; radius: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: temaApp.esClaro ? temaApp.suave : Qt.rgba(temaApp.primario.r, temaApp.primario.g, temaApp.primario.b, 0.22)
                                        border.color: temaApp.primario
                                        Text {
                                            anchors.centerIn: parent
                                            text: "130"
                                            color: temaApp.esClaro ? temaApp.oscuro : temaApp.claro
                                            font.pixelSize: 9; font.bold: true
                                        }
                                    }

                                    Column {
                                        width: parent.width - 35
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 1
                                        Text {
                                            width: parent.width
                                            text: "Hito 130 U.C. (TEG)"
                                            color: temaApp.textoPrincipal
                                            font.pixelSize: 10; font.bold: true
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            width: parent.width
                                            text: daeClient.ucAprobadasCarrera >= 130
                                                  ? "✓ Hito alcanzado"
                                                  : ("Faltan " + (130 - daeClient.ucAprobadasCarrera) + " U.C.")
                                            color: temaApp.textoSecundario
                                            font.pixelSize: 9
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // PROMEDIOS DEL ESTUDIANTE (se muestran aquí tras salir de la pantalla principal)
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: flickRap.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: 78
                radius: 24
                color: temaApp.vidrio
                border.color: temaApp.bordeVidrio
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    // Promedio Ponderado
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 16
                        color: temaApp.panelAlt
                        border.color: temaApp.bordeAlt
                        border.width: 1

                        Column {
                            anchors.centerIn: parent
                            spacing: 1

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 1
                                Text {
                                    text: daeClient.promedioPonderadoEntero
                                    color: temaApp.textoPrincipal
                                    font.pixelSize: 19; font.bold: true
                                }
                                Text {
                                    text: daeClient.promedioPonderadoDecimal
                                    color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                                    font.pixelSize: 19
                                }
                            }
                            Text {
                                text: "Promedio Ponderado"
                                color: temaApp.textoSubtitulo
                                font.pixelSize: 9
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    // Promedio Aritmético
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 16
                        color: temaApp.panelAlt
                        border.color: temaApp.bordeAlt
                        border.width: 1

                        Column {
                            anchors.centerIn: parent
                            spacing: 1

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 1
                                Text {
                                    text: daeClient.promedioAritmeticoEntero
                                    color: temaApp.textoPrincipal
                                    font.pixelSize: 19; font.bold: true
                                }
                                Text {
                                    text: daeClient.promedioAritmeticoDecimal
                                    color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                                    font.pixelSize: 19
                                }
                            }
                            Text {
                                text: "Promedio Aritmético"
                                color: temaApp.textoSubtitulo
                                font.pixelSize: 9
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }
            }

            // 3. BARRA DE BÚSQUEDA INTERACTIVA (Por materia, código o requisito)
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: flickRap.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: 46
                radius: 23
                color: temaApp.panelAlt
                border.color: inputBuscarRap.activeFocus ? temaApp.acento : temaApp.bordeAlt
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 14
                    spacing: 10

                    Canvas {
                        Layout.preferredWidth: 18; Layout.preferredHeight: 18
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
                        Layout.fillWidth: true; Layout.fillHeight: true
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Buscar código, materia o prelación (ej. ER7T03)..."
                            color: temaApp.textoMuted
                            font.pixelSize: 12
                            visible: inputBuscarRap.text === ""
                            elide: Text.ElideRight
                            width: parent.width
                        }
                        TextInput {
                            id: inputBuscarRap
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            color: temaApp.textoPrincipal
                            font.pixelSize: 13
                            selectByMouse: true
                            clip: true
                            onTextChanged: rootRap.textoBusqueda = text.trim().toUpperCase()
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 22; Layout.preferredHeight: 22; radius: 11
                        color: temaApp.esClaro ? "#e2e8f0" : "#28ffffff"
                        visible: inputBuscarRap.text !== ""
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
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: inputBuscarRap.text = ""
                        }
                    }
                }
            }

            // 4. FILTROS POR CONDICIÓN DEL RAP (Colores fieles al reporte DAE)
            Flickable {
                Layout.fillWidth: true
                Layout.maximumWidth: flickRap.width
                Layout.preferredHeight: 36
                contentWidth: rowCondiciones.implicitWidth + 40
                clip: true

                Row {
                    id: rowCondiciones
                    x: 20
                    spacing: 8

                    Repeater {
                        model: [
                            { idx: 0, texto: "Todas (" + rootRap.fuenteRapActiva.length + ")", colorActivo: temaApp.primario },
                            { idx: 1, texto: "Inscribibles (" + rootRap.contarInscribiblesRap() + ")", colorActivo: "#d97706" },
                            { idx: 4, texto: "Artículo 17 (" + rootRap.contarEstadoRap("ART17") + ")", colorActivo: "#9333ea" },
                            { idx: 2, texto: "Asignatura Aprobada (" + rootRap.contarEstadoRap("APROB") + ")", colorActivo: "#0284c7" },
                            { idx: 3, texto: "No Cumple Requisitos (" + rootRap.contarEstadoRap("NOCUMPLE") + ")", colorActivo: "#475569" }
                        ]

                        delegate: Rectangle {
                            property bool sel: rootRap.filtroCondicion === modelData.idx
                            width: txtCondPildora.implicitWidth + 24
                            height: 34; radius: 17
                            color: sel ? modelData.colorActivo : temaApp.panelAlt
                            border.color: sel ? temaApp.claro : temaApp.bordeAlt
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 180 } }

                            Text {
                                id: txtCondPildora
                                anchors.centerIn: parent
                                text: modelData.texto
                                color: sel ? "white" : temaApp.textoSecundario
                                font.pixelSize: 11
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: rootRap.filtroCondicion = modelData.idx
                            }
                        }
                    }
                }
            }

            // 5. FILTROS RÁPIDOS POR SEMESTRE / NIVEL
            Flickable {
                Layout.fillWidth: true
                Layout.maximumWidth: flickRap.width
                Layout.preferredHeight: 32
                contentWidth: rowSemestresRap.implicitWidth + 40
                clip: true

                Row {
                    id: rowSemestresRap
                    x: 20
                    spacing: 6

                    Repeater {
                        model: [
                            { sem: 0, label: "Todos los Niveles" },
                            { sem: 1, label: "Sem. 1–4 (Básico)" },
                            { sem: 5, label: "Sem. 5" },
                            { sem: 6, label: "Sem. 6" },
                            { sem: 7, label: "Sem. 7" },
                            { sem: 8, label: "Sem. 8" },
                            { sem: 9, label: "Sem. 9" },
                            { sem: 10, label: "Sem. 10 / Electivas" }
                        ]

                        delegate: Rectangle {
                            property bool activo: rootRap.filtroSemestre === modelData.sem
                            width: txtSemRap.implicitWidth + 20
                            height: 28; radius: 14
                            color: activo ? temaApp.oscuro : "transparent"
                            border.color: activo ? temaApp.primario : temaApp.bordeAlt
                            border.width: 1

                            Text {
                                id: txtSemRap
                                anchors.centerIn: parent
                                text: modelData.label
                                color: activo ? "white" : temaApp.textoMuted
                                font.pixelSize: 10
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: rootRap.filtroSemestre = modelData.sem
                            }
                        }
                    }
                }
            }

            // 6. LISTA DE ASIGNATURAS DEL RAP CON PRELACIONES INTERACTIVAS
            Repeater {
                id: repListaRap
                model: rootRap.filtrarMateriasRap(rootRap.filtroCondicion, rootRap.filtroSemestre, rootRap.textoBusqueda)

                delegate: Rectangle {
                    id: cardItemRap
                    property string est: modelData.estado
                    property var listaReqs: rootRap.obtenerListaRequisitos(modelData.req)
                    property bool tieneReqs: listaReqs.length > 0

                    Layout.fillWidth: true
                    Layout.maximumWidth: flickRap.width - 40
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    Layout.preferredHeight: tieneReqs ? 98 : 78
                    radius: 20
                    color: temaApp.panel
                    border.color: est === "CUMPLE"
                                  ? "#65f59e0b"
                                  : (est === "ART17"
                                     ? "#75a855f7"
                                     : (est === "APROB" ? "#4538bdf8" : temaApp.bordePanel))
                    border.width: 1
                    clip: true

                    // 1. Barra lateral izquierda con el color oficial de condición RAP
                    Rectangle {
                        id: barraCondicion
                        width: 4
                        height: parent.height - 26
                        radius: 2
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        color: est === "APROB"
                               ? "#38bdf8"
                               : (est === "CUMPLE"
                                  ? "#fbbf24"
                                  : (est === "ART17" ? "#c084fc" : "#64748b"))
                    }

                    // 2. Insignia derecha fija de estado RAP
                    Rectangle {
                        id: badgeDerechoRap
                        width: 58
                        height: 50
                        radius: 15
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        color: temaApp.esClaro
                               ? (est === "APROB"
                                  ? "#e0f2fe"
                                  : (est === "CUMPLE" ? "#fef3c7" : (est === "ART17" ? "#f3e8ff" : "#f1f5f9")))
                               : (est === "APROB"
                                  ? "#0f2942"
                                  : (est === "CUMPLE" ? "#3b2a10" : (est === "ART17" ? "#2e1065" : "#162032")))
                        border.color: est === "APROB"
                                      ? "#38bdf8"
                                      : (est === "CUMPLE" ? "#f59e0b" : (est === "ART17" ? "#a855f7" : temaApp.bordeAlt))
                        border.width: 1.5

                        Column {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                text: est === "APROB" ? "✓" : (est === "CUMPLE" ? "★" : (est === "ART17" ? "⚡" : "🔒"))
                                color: temaApp.esClaro
                                       ? (est === "APROB" ? "#0369a1" : (est === "CUMPLE" ? "#b45309" : (est === "ART17" ? "#7e22ce" : "#475569")))
                                       : (est === "APROB" ? "#38bdf8" : (est === "CUMPLE" ? "#fbbf24" : (est === "ART17" ? "#d8b4fe" : "#94a3b8")))
                                font.pixelSize: 14
                                font.bold: true
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: est === "APROB" ? "APROBADA" : (est === "CUMPLE" ? "HABILIT." : (est === "ART17" ? "ART. 17" : "PRELADA"))
                                color: temaApp.esClaro
                                       ? (est === "APROB" ? "#0369a1" : (est === "CUMPLE" ? "#b45309" : (est === "ART17" ? "#7e22ce" : "#64748b")))
                                       : (est === "APROB" ? "#bae6fd" : (est === "CUMPLE" ? "#fde68a" : (est === "ART17" ? "#e9d5ff" : "#94a3b8")))
                                font.pixelSize: 7
                                font.bold: true
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    // 3. Contenido central (Asignatura, Código, Condición Oficial y Prelaciones)
                    Column {
                        anchors.left: barraCondicion.right
                        anchors.leftMargin: 12
                        anchors.right: badgeDerechoRap.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        // Fila 1: Nombre de la asignatura
                        Text {
                            width: parent.width
                            text: modelData.nombre
                            color: temaApp.textoPrincipal
                            font.pixelSize: 12
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        // Fila 2: Código + Semestre + Condición Oficial DAE
                        Row {
                            width: parent.width
                            spacing: 6

                            Rectangle {
                                width: lblCodigoRap.implicitWidth + 10
                                height: 18; radius: 6
                                color: temaApp.esClaro ? temaApp.suave : Qt.rgba(temaApp.primario.r, temaApp.primario.g, temaApp.primario.b, 0.22)
                                Text {
                                    id: lblCodigoRap
                                    anchors.centerIn: parent
                                    text: modelData.codigo
                                    color: temaApp.esClaro ? temaApp.oscuro : temaApp.claro
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }

                            Rectangle {
                                width: lblSemRap.implicitWidth + 10
                                height: 18; radius: 6
                                color: temaApp.panelAlt
                                border.color: temaApp.bordeAlt
                                Text {
                                    id: lblSemRap
                                    anchors.centerIn: parent
                                    text: modelData.sem === 10 ? "Electiva / 10°" : ("Sem. " + modelData.sem)
                                    color: temaApp.textoSecundario
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - lblCodigoRap.width - lblSemRap.width - 36
                                text: rootRap.textoCondicionOficial(est)
                                color: est === "APROB"
                                       ? (temaApp.esClaro ? "#0284c7" : "#38bdf8")
                                       : (est === "CUMPLE"
                                          ? (temaApp.esClaro ? "#d97706" : "#fbbf24")
                                          : (est === "ART17"
                                             ? (temaApp.esClaro ? "#7e22ce" : "#d8b4fe")
                                             : temaApp.textoMuted))
                                font.pixelSize: 10
                                font.bold: est !== "NOCUMPLE"
                                elide: Text.ElideRight
                            }
                        }

                        // Fila 3: Píldoras de Prelaciones / Condición Artículo 17 (Cuando aplica)
                        Row {
                            visible: cardItemRap.tieneReqs
                            spacing: 6

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: cardItemRap.est === "ART17" ? "Condición:" : "Requiere:"
                                color: temaApp.textoMuted
                                font.pixelSize: 10
                                font.bold: true
                            }

                            Repeater {
                                model: cardItemRap.listaReqs

                                delegate: Rectangle {
                                    property string reqRaw: String(modelData || "").trim()
                                    property bool esUc: reqRaw.indexOf("U.C.") !== -1
                                    property bool esArt17: cardItemRap.est === "ART17" || reqRaw.toUpperCase().indexOf("ART") !== -1
                                    property string codigoParaleloExtraido: {
                                        var m = reqRaw.match(/([A-Z]{2}\d[A-Z0-9]{3,4})/i)
                                        return m ? m[1].toUpperCase() : reqRaw
                                    }
                                    property string textoChipFormateado: {
                                        if (esArt17 && codigoParaleloExtraido !== "" && codigoParaleloExtraido !== reqRaw) {
                                            return "Art. 17 • En paralelo con " + codigoParaleloExtraido
                                        }
                                        return reqRaw
                                    }

                                    width: txtChipReq.implicitWidth + 14
                                    height: 20
                                    radius: 7
                                    color: esArt17
                                           ? (temaApp.esClaro ? "#f3e8ff" : "#2e1065")
                                           : (esUc
                                              ? (temaApp.esClaro ? "#fef3c7" : "#3b2a10")
                                              : (temaApp.esClaro ? "#fee2e2" : "#3b151e"))
                                    border.color: esArt17 ? "#a855f7" : (esUc ? "#f59e0b" : "#ef4444")
                                    border.width: 1

                                    Text {
                                        id: txtChipReq
                                        anchors.centerIn: parent
                                        text: parent.textoChipFormateado
                                        color: parent.esArt17
                                               ? (temaApp.esClaro ? "#6b21a8" : "#e9d5ff")
                                               : (parent.esUc
                                                  ? (temaApp.esClaro ? "#b45309" : "#fde68a")
                                                  : (temaApp.esClaro ? "#b91c1c" : "#fca5a5"))
                                        font.pixelSize: 9
                                        font.bold: true
                                    }

                                    // Al tocar un código de prelación, busca esa asignatura automáticamente
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (!parent.esUc) {
                                                rootRap.filtroCondicion = 0
                                                rootRap.filtroSemestre = 0
                                                inputBuscarRap.text = parent.codigoParaleloExtraido
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 7. PIE INSTITUCIONAL DAE
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: flickRap.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.topMargin: 4
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
