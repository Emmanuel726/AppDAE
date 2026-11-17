import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: rootTranscritas

    // -1 = Mostrar Todos los periodos; 0..8 = Filtrar un periodo específico
    property int periodoFiltro: -1
    property string textoBusqueda: ""

    // Historial completo sincronizado únicamente con el expediente del estudiante autenticado
    property var historialPeriodosBase: []

    property var historialPeriodos: daeClient.expedienteSemestres || []

    function contarMateriasPorEstado(tipo) {
        var total = 0;
        for (var i = 0; i < historialPeriodos.length; i++) {
            var mats = historialPeriodos[i].materias || [];
            for (var j = 0; j < mats.length; j++) {
                var e = estadoMateria(mats[j].nFin, mats[j].nRec);
                if (tipo === "APROB" && (e === "APROB" || e === "REC")) total++;
                else if (tipo === "REC" && e === "REC") total++;
            }
        }
        return total;
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

    // Devuelve una lista plana y junta de todas las materias que coinciden con la búsqueda
    function obtenerResultadosBusqueda(busqueda) {
        var res = [];
        if (normalizarTextoBusqueda(busqueda) === "") return res;
        for (var i = 0; i < historialPeriodos.length; i++) {
            var per = historialPeriodos[i];
            for (var j = 0; j < per.materias.length; j++) {
                var m = per.materias[j];
                if (coincideBusqueda(m.nombre + " " + m.codigo + " " + per.periodo, busqueda)) {
                    res.push({
                        periodo: per.periodo,
                        codigo: m.codigo,
                        sec: m.sec,
                        uc: m.uc,
                        nombre: m.nombre,
                        nFin: m.nFin,
                        nRec: m.nRec,
                        con: m.con
                    });
                }
            }
        }
        return res;
    }

    function notaDefinitiva(nFin, nRec) {
        if (nRec !== "" && nRec !== "SD") {
            return nRec;
        }
        return nFin;
    }

    function estadoMateria(nFin, nRec) {
        var f = parseInt(nFin);
        if (!isNaN(f) && f >= 10) return "APROB";
        if (nRec !== "" && nRec !== "SD") {
            var r = parseInt(nRec);
            if (!isNaN(r) && r >= 10) return "REC";
        }
        return "REP";
    }

    property var curvaProgresoBase: []

    property var curvaProgreso: daeClient.curvaProgresoExpediente || []

    // Componente reutilizable para dibujar la fila de una materia (perfectamente contenida sin salirse)
    component FilaMateria: Rectangle {
        id: rootFila
        property var datos: ({})
        property bool mostrarPeriodo: false
        property string est: rootTranscritas.estadoMateria(datos.nFin, datos.nRec)

        Layout.fillWidth: true
        Layout.preferredHeight: 64
        radius: 16
        color: temaApp.panelAlt
        border.color: est === "APROB" ? "#3022c55e" : (est === "REC" ? "#45f59e0b" : "#35ef4444")
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            // Barra vertical de estado
            Rectangle {
                Layout.preferredWidth: 4
                Layout.preferredHeight: 38
                radius: 2
                color: rootFila.est === "APROB" ? "#22c55e" : (rootFila.est === "REC" ? "#f59e0b" : "#ef4444")
            }

            // Textos de la izquierda (Con Layout.fillWidth para adaptarse sin empujar la nota hacia afuera)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: rootFila.datos.nombre
                    color: temaApp.textoPrincipal
                    font.pixelSize: 12
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        Layout.preferredWidth: lblCod.implicitWidth + 10
                        Layout.preferredHeight: 18
                        radius: 6
                        color: temaApp.esClaro ? temaApp.suave : Qt.rgba(temaApp.primario.r, temaApp.primario.g, temaApp.primario.b, 0.22)
                        Text {
                            id: lblCod
                            anchors.centerIn: parent
                            text: rootFila.datos.codigo
                            color: temaApp.esClaro ? temaApp.oscuro : temaApp.claro
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }

                    Rectangle {
                        visible: rootFila.mostrarPeriodo
                        Layout.preferredWidth: lblPer.implicitWidth + 10
                        Layout.preferredHeight: 18
                        radius: 6
                        color: temaApp.oscuro
                        border.color: temaApp.primario
                        Text {
                            id: lblPer
                            anchors.centerIn: parent
                            text: rootFila.datos.periodo || ""
                            color: "white"
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }

                    Text {
                        text: "Sec. " + rootFila.datos.sec + " • " + rootFila.datos.uc + " UC • Cond: " + rootFila.datos.con
                        color: temaApp.textoSecundario
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            // Bloque derecho: Nota Final / Recuperación (Ancho fijo garantizado dentro de la tarjeta)
            RowLayout {
                Layout.fillWidth: false
                spacing: 6

                Rectangle {
                    visible: rootFila.datos.nRec !== ""
                    Layout.preferredWidth: txtRec.implicitWidth + 10
                    Layout.preferredHeight: 22
                    radius: 7
                    color: temaApp.panel
                    border.color: temaApp.bordeAlt

                    Text {
                        id: txtRec
                        anchors.centerIn: parent
                        text: "Fin: " + rootFila.datos.nFin
                        color: temaApp.textoSecundario
                        font.pixelSize: 9
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42
                    radius: 13
                    color: temaApp.esClaro
                           ? (rootFila.est === "APROB" ? "#dcfce7" : (rootFila.est === "REC" ? "#fef3c7" : "#fee2e2"))
                           : (rootFila.est === "APROB" ? "#163828" : (rootFila.est === "REC" ? "#3b2a10" : "#3b151e"))
                    border.color: rootFila.est === "APROB" ? "#22c55e" : (rootFila.est === "REC" ? "#f59e0b" : "#ef4444")
                    border.width: 1.5

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: -2

                        Text {
                            text: rootTranscritas.notaDefinitiva(rootFila.datos.nFin, rootFila.datos.nRec)
                            color: temaApp.esClaro
                                   ? (rootFila.est === "APROB" ? "#15803d" : (rootFila.est === "REC" ? "#b45309" : "#b91c1c"))
                                   : (rootFila.est === "APROB" ? "#4ade80" : (rootFila.est === "REC" ? "#fbbf24" : "#f87171"))
                            font.pixelSize: 15
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: rootFila.est === "REC" ? "REC" : "PTS"
                            color: temaApp.esClaro ? "#475569" : "#cbd5e1"
                            font.pixelSize: 7
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }
    }

    Flickable {
        id: flickExpediente
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
                id: timerTecladoExpediente
                interval: 280
                onTriggered: {
                    flickExpediente.restaurarPosicion();
                }
            }
        }

        // Cuando el teclado se cierra, Qt deja el contenido corrido:
        // se devuelve a la posición en la que estaba el usuario.
        Connections {
            target: daeClient
            function onTecladoVisibleChanged() {
                if (!daeClient.tecladoVisible) {
                    flickExpediente.restaurarPosicion();
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
        contentHeight: colTranscritas.implicitHeight + 130
        clip: true

        ColumnLayout {
            id: colTranscritas
            width: parent.width
            spacing: 14

            // 1. CABECERA ("Récord Histórico Oficial • DAE Ing UC")
            RowLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: rootTranscritas.width - 44
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
                        text: "Expediente de Notas"
                        color: temaApp.textoPrincipal
                        font.pixelSize: 22
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: daeClient.escuelaCorta + " • DAE UC"
                        color: temaApp.textoSubtitulo
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    id: btnImprimir
                    Layout.preferredWidth: 104
                    Layout.preferredHeight: 38
                    Layout.fillWidth: false
                    radius: 19
                    color: temaApp.vidrio
                    border.color: temaApp.bordeVidrio
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Canvas {
                            width: 16; height: 16
                            property color colorTrazo: temaApp.textoPrincipal
                            onColorTrazoChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.strokeStyle = colorTrazo;
                                ctx.lineWidth = 1.8;
                                ctx.lineCap = "round";
                                ctx.lineJoin = "round";
                                ctx.strokeRect(4, 2, 8, 4);
                                ctx.strokeRect(2, 6, 12, 6);
                                ctx.strokeRect(4, 10, 8, 4);
                            }
                        }

                        Text {
                            text: "Imprimir"
                            color: temaApp.textoPrincipal
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPressed: btnImprimir.scale = 0.93
                        onReleased: btnImprimir.scale = 1.0
                        onClicked: {
                            daeClient.descargarConstanciaEstudiantil(2)
                            daeClient.registrarSolicitudReciente("PDF", "Constancia de Estudio",
                                                                   "Expediente • firms por DAE", "Descargada")
                        }
                    }
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }
            }

            // 2. TARJETA DE MÉTRICAS CENTRADAS + GRÁFICA CON ALTURA FIJA GARANTIZADA
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: 184
                radius: 24
                color: temaApp.vidrio
                border.color: temaApp.bordeVidrio
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    // Fila de 4 métricas dividida matemáticamente en 4 partes iguales (25% cada una)
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48

                        Row {
                            anchors.fill: parent

                            // Columna 1: UC Aprobadas
                            Item {
                                width: parent.width / 4
                                height: parent.height

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 2
                                    Text {
                                        text: daeClient.ucAprobadasCarrera
                                        color: temaApp.textoPrincipal
                                        font.pixelSize: 22
                                        font.bold: true
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: "UC Aprobadas"
                                        color: temaApp.textoSubtitulo
                                        font.pixelSize: 10
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }

                                // Línea divisoria derecha
                                Rectangle {
                                    width: 1; height: 30
                                    color: temaApp.bordeVidrio
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            // Columna 2: Períodos
                            Item {
                                width: parent.width / 4
                                height: parent.height

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 2
                                    Text {
                                        text: rootTranscritas.historialPeriodos.length
                                        color: temaApp.textoPrincipal
                                        font.pixelSize: 22
                                        font.bold: true
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: "Períodos"
                                        color: temaApp.textoSubtitulo
                                        font.pixelSize: 10
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }

                                Rectangle {
                                    width: 1; height: 30
                                    color: temaApp.bordeVidrio
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            // Columna 3: Aprobadas
                            Item {
                                width: parent.width / 4
                                height: parent.height

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 2
                                    Text {
                                        text: rootTranscritas.contarMateriasPorEstado("APROB")
                                        color: temaApp.esClaro ? "#15803d" : "#4ade80"
                                        font.pixelSize: 22
                                        font.bold: true
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: "Aprobadas"
                                        color: temaApp.textoSubtitulo
                                        font.pixelSize: 10
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }

                                Rectangle {
                                    width: 1; height: 30
                                    color: temaApp.bordeVidrio
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            // Columna 4: En Recup.
                            Item {
                                width: parent.width / 4
                                height: parent.height

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 2
                                    Text {
                                        text: rootTranscritas.contarMateriasPorEstado("REC")
                                        color: temaApp.esClaro ? "#b45309" : "#fbbf24"
                                        font.pixelSize: 22
                                        font.bold: true
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: "En Recup."
                                        color: temaApp.textoSubtitulo
                                        font.pixelSize: 10
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: temaApp.bordeVidrio }

                    // Gráfica con Layout.preferredHeight explícito (92px) para que jamás se aplaste
                    Canvas {
                        id: graficaUC
                        Layout.fillWidth: true
                        Layout.preferredHeight: 92
                        property color colorTema: temaApp.acento
                        property bool modoClaro: temaApp.esClaro
                        property var datosCurva: rootTranscritas.curvaProgreso
                        onColorTemaChanged: requestPaint()
                        onModoClaroChanged: requestPaint()
                        onDatosCurvaChanged: requestPaint()
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();

                            var datos = rootTranscritas.curvaProgreso;
                            var w = width;
                            var h = height;
                            if (w <= 0 || h <= 0 || !datos || datos.length === 0) return;

                            var padX = 20;
                            var padTop = 18;
                            var padBot = 18;
                            var utilW = w - padX * 2;
                            var utilH = h - padTop - padBot;
                            var denom = Math.max(1, datos.length - 1);
                            var maxUc = Math.max(100.0, datos[datos.length - 1].uc * 1.05);

                            var grad = ctx.createLinearGradient(0, padTop, 0, h - padBot);
                            grad.addColorStop(0, Qt.rgba(temaApp.acento.r, temaApp.acento.g, temaApp.acento.b, 0.38));
                            grad.addColorStop(1, Qt.rgba(temaApp.primario.r, temaApp.primario.g, temaApp.primario.b, 0.0));

                            ctx.beginPath();
                            for (var i = 0; i < datos.length; i++) {
                                var px = padX + (i / denom) * utilW;
                                var py = padTop + utilH - (datos[i].uc / maxUc) * utilH;
                                if (i === 0) ctx.moveTo(px, py);
                                else ctx.lineTo(px, py);
                            }
                            ctx.lineTo(padX + utilW, h - padBot);
                            ctx.lineTo(padX, h - padBot);
                            ctx.closePath();
                            ctx.fillStyle = grad;
                            ctx.fill();

                            ctx.beginPath();
                            for (var j = 0; j < datos.length; j++) {
                                var lx = padX + (j / denom) * utilW;
                                var ly = padTop + utilH - (datos[j].uc / maxUc) * utilH;
                                if (j === 0) ctx.moveTo(lx, ly);
                                else ctx.lineTo(lx, ly);
                            }
                            ctx.strokeStyle = temaApp.acento;
                            ctx.lineWidth = 2.4;
                            ctx.stroke();

                            ctx.font = "bold 9px sans-serif";
                            ctx.textAlign = "center";
                            for (var k = 0; k < datos.length; k++) {
                                var cx = padX + (k / denom) * utilW;
                                var cy = padTop + utilH - (datos[k].uc / maxUc) * utilH;

                                ctx.beginPath();
                                ctx.arc(cx, cy, 3.5, 0, Math.PI * 2);
                                ctx.fillStyle = temaApp.esClaro ? temaApp.primario : "#ffffff";
                                ctx.fill();

                                ctx.fillStyle = temaApp.textoPrincipal;
                                ctx.fillText(datos[k].uc, cx, cy - 6);

                                ctx.fillStyle = temaApp.textoSecundario;
                                ctx.fillText(datos[k].per, cx, h - 3);
                            }
                        }
                    }
                }
            }

            // 3. BARRA DE BÚSQUEDA (Con TextInput nativo para que el placeholder NO suba al borde)
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: 48
                radius: 24
                color: temaApp.panelAlt
                border.color: inputNativo.activeFocus ? temaApp.acento : temaApp.bordeAlt
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 14
                    spacing: 10

                    Canvas {
                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 18
                        Layout.alignment: Qt.AlignVCenter
                        property color colorTema: temaApp.esClaro ? temaApp.primario : temaApp.claro
                        onColorTemaChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = colorTema;
                            ctx.lineWidth = 2.0;
                            ctx.lineCap = "round";
                            ctx.beginPath();
                            ctx.arc(8, 8, 5.5, 0, Math.PI * 2);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.moveTo(12.2, 12.2);
                            ctx.lineTo(16, 16);
                            ctx.stroke();
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Buscar materia o código (ej. Física, FI, Electrónica)..."
                            color: temaApp.textoMuted
                            font.pixelSize: 13
                            visible: inputNativo.text === ""
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        TextInput {
                            id: inputNativo
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            color: temaApp.textoPrincipal
                            font.pixelSize: 13
                            selectByMouse: true
                            clip: true
                            onTextChanged: rootTranscritas.textoBusqueda = text.trim().toUpperCase()
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        radius: 12
                        color: temaApp.esClaro ? "#e2e8f0" : "#28ffffff"
                        visible: inputNativo.text !== ""
                        Layout.alignment: Qt.AlignVCenter
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
                            onClicked: inputNativo.text = ""
                        }
                    }
                }
            }

            // 4. CARRUSEL DE PÍLDORAS DE PERÍODO (Con Layout.preferredHeight correcto)
            Flickable {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                contentWidth: filaPildorasPeriodo.implicitWidth + 40
                clip: false
                visible: rootTranscritas.textoBusqueda === ""

                Row {
                    id: filaPildorasPeriodo
                    x: 20
                    spacing: 8

                    Rectangle {
                        width: 72; height: 34; radius: 17
                        color: rootTranscritas.periodoFiltro === -1 ? temaApp.primario : temaApp.panelAlt
                        border.color: rootTranscritas.periodoFiltro === -1 ? temaApp.claro : temaApp.bordeAlt
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Todos"
                            color: rootTranscritas.periodoFiltro === -1 ? "white" : temaApp.textoSecundario
                            font.pixelSize: 12
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: rootTranscritas.periodoFiltro = -1
                        }
                    }

                    Repeater {
                        model: rootTranscritas.historialPeriodos

                        delegate: Rectangle {
                            property bool activo: rootTranscritas.periodoFiltro === index
                            width: 76; height: 34; radius: 17
                            color: activo ? temaApp.primario : temaApp.panelAlt
                            border.color: activo ? temaApp.claro : temaApp.bordeAlt
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData.periodo
                                color: activo ? "white" : temaApp.textoSecundario
                                font.pixelSize: 12
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: rootTranscritas.periodoFiltro = index
                            }
                        }
                    }
                }
            }

            // =====================================================================
            // 5A. MODO RESULTADOS DE BÚSQUEDA (Todas las materias juntas sin espacios)
            // =====================================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: colResultadosBusqueda.implicitHeight + 32
                radius: 24
                color: temaApp.panel
                border.color: temaApp.bordePanel
                border.width: 1
                visible: rootTranscritas.textoBusqueda !== ""

                ColumnLayout {
                    id: colResultadosBusqueda
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle { Layout.preferredWidth: 8; Layout.preferredHeight: 20; radius: 4; color: temaApp.acento }

                        Text {
                            text: "Resultados para \"" + rootTranscritas.textoBusqueda + "\""
                            color: temaApp.textoPrincipal
                            font.pixelSize: 15
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: repBusqueda.count + " encontradas"
                            color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: temaApp.bordePanel }

                    Repeater {
                        id: repBusqueda
                        model: rootTranscritas.obtenerResultadosBusqueda(rootTranscritas.textoBusqueda)

                        delegate: FilaMateria {
                            datos: modelData
                            mostrarPeriodo: true
                        }
                    }
                }
            }

            // =====================================================================
            // 5B. MODO NORMAL POR PERÍODOS (Con Layout.preferredHeight para NO encimarse)
            // =====================================================================
            Repeater {
                model: rootTranscritas.historialPeriodos

                delegate: Rectangle {
                    id: cardPeriodo
                    property int idxPeriodo: index

                    visible: rootTranscritas.textoBusqueda === "" && (rootTranscritas.periodoFiltro === -1 || rootTranscritas.periodoFiltro === idxPeriodo)

                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    // USAR Layout.preferredHeight ES LA CLAVE PARA QUE NO SE APILEN NI DESAPAREZCAN
                    Layout.preferredHeight: colInternaPeriodo.implicitHeight + 32
                    radius: 24
                    color: temaApp.panel
                    border.color: temaApp.bordePanel
                    border.width: 1

                    ColumnLayout {
                        id: colInternaPeriodo
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10

                        // Cabecera del Período
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.preferredWidth: 8
                                Layout.preferredHeight: 20
                                radius: 4
                                color: temaApp.primario
                            }

                            Text {
                                text: "Período " + modelData.periodo
                                color: temaApp.textoPrincipal
                                font.pixelSize: 15
                                font.bold: true
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                Layout.preferredWidth: txtUcSem.implicitWidth + 14
                                Layout.preferredHeight: 22
                                radius: 11
                                color: temaApp.esClaro ? temaApp.suave : Qt.rgba(temaApp.primario.r, temaApp.primario.g, temaApp.primario.b, 0.20)
                                border.color: temaApp.bordeAlt
                                Text {
                                    id: txtUcSem
                                    anchors.centerIn: parent
                                    text: "+" + modelData.ucSemestre + " UC"
                                    color: temaApp.esClaro ? temaApp.oscuro : temaApp.claro
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: txtUcAcum.implicitWidth + 14
                                Layout.preferredHeight: 22
                                radius: 11
                                color: temaApp.oscuro
                                border.color: temaApp.primario
                                Text {
                                    id: txtUcAcum
                                    anchors.centerIn: parent
                                    text: "Acum: " + modelData.ucAcumuladas + " UC"
                                    color: "white"
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: temaApp.bordePanel }

                        // Materias del período
                        Repeater {
                            model: modelData.materias

                            delegate: FilaMateria {
                                datos: modelData
                                mostrarPeriodo: false
                            }
                        }
                    }
                }
            }
        }
    }
}
