import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: rootRetiro
    signal volver()

    // 0 = Paso 1 (Tabla de asignaturas inscritas del estudiante con casilla RETIRAR)
    // 1 = Paso 2 (Confirmación de las asignaturas seleccionadas para retirar)
    // 2 = Paso 3 (Comprobante de solicitud de retiro procesada)
    property int pasoActual: 0

    // Lista reactiva sincronizada dinámicamente con daeClient.materiasRetiro del usuario autenticado
    property var estadoMaterias: []
    property int cantidadSeleccionadas: 0
    property var listaSeleccionadasConfirmar: []

    function sincronizarMateriasUsuario() {
        var origen = daeClient.materiasRetiro || []
        var seleccionPrevia = {}
        for (var p = 0; p < estadoMaterias.length; ++p) {
            seleccionPrevia[estadoMaterias[p].codigo] = estadoMaterias[p].checked
        }

        var nueva = []
        var conteo = 0
        for (var i = 0; i < origen.length; ++i) {
            var m = origen[i]
            var cod = m.codigo || ""
            var chk = seleccionPrevia[cod] === true
            if (chk) conteo++
            nueva.push({
                codigo: cod,
                nombre: m.nombre || "",
                sec: m.sec || "01",
                uc: m.uc !== undefined ? m.uc : 0,
                inputName: m.inputName || "retirar[]",
                inputValue: m.inputValue || cod,
                checked: chk
            })
        }
        estadoMaterias = nueva
        cantidadSeleccionadas = conteo
    }

    function toggleMateria(idx) {
        if (idx < 0 || idx >= estadoMaterias.length) return
        var copia = estadoMaterias.slice()
        copia[idx].checked = !copia[idx].checked
        var conteo = 0
        for (var i = 0; i < copia.length; ++i) {
            if (copia[i].checked) conteo++
        }
        estadoMaterias = copia
        cantidadSeleccionadas = conteo
    }

    function irAlSiguientePaso() {
        var elegidas = []
        for (var i = 0; i < estadoMaterias.length; ++i) {
            if (estadoMaterias[i].checked) {
                elegidas.push(estadoMaterias[i])
            }
        }
        if (elegidas.length === 0) {
            bannerRetiro.mostrar("⚠ Selecciona al menos una asignatura en la columna RETIRAR", false)
            return
        }
        listaSeleccionadasConfirmar = elegidas
        pasoActual = 1
    }

    Component.onCompleted: {
        sincronizarMateriasUsuario()
    }

    onVisibleChanged: {
        if (visible) {
            pasoActual = 0
            daeClient.cargarDatosRetiro()
            sincronizarMateriasUsuario()
        }
    }

    Connections {
        target: daeClient
        function onRetiroChanged() {
            rootRetiro.sincronizarMateriasUsuario()
        }
        function onHorarioAsignadoChanged() {
            rootRetiro.sincronizarMateriasUsuario()
        }
        function onTranscritasChanged() {
            rootRetiro.sincronizarMateriasUsuario()
        }
        function onSolicitudRetiroCompletada(exito, mensaje) {
            bannerRetiro.mostrar(mensaje, exito)
            if (exito) {
                rootRetiro.sincronizarMateriasUsuario()
                rootRetiro.pasoActual = 2
            }
        }
    }

    Flickable {
        id: flickRetiro
        anchors.fill: parent
        contentWidth: width
        contentHeight: colRetiro.implicitHeight + 130
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: colRetiro
            width: flickRetiro.width
            spacing: 14

            // =================================================================
            // 1. CABECERA DE NAVEGACIÓN
            // =================================================================
            RowLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: flickRetiro.width - 40
                Layout.topMargin: 22
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 10

                Rectangle {
                    id: btnVolverRetiro
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
                        onPressed: btnVolverRetiro.scale = 0.90
                        onReleased: btnVolverRetiro.scale = 1.0
                        onClicked: {
                            if (rootRetiro.pasoActual === 1) {
                                rootRetiro.pasoActual = 0
                            } else {
                                rootRetiro.volver()
                            }
                        }
                    }
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    spacing: 1

                    Text {
                        text: "Solicitud de Retiro " + daeClient.periodoRetiro
                        color: temaApp.textoPrincipal
                        font.pixelSize: 19
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: daeClient.fechaLimiteRetiro !== ""
                              ? ("Activo • " + daeClient.fechaLimiteRetiro)
                              : "Dirección de Asuntos Estudiantiles • Facultad de Ingeniería"
                        color: temaApp.textoSubtitulo
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    visible: daeClient.solicitudRetiroRegistrada.length > 0 && rootRetiro.pasoActual !== 2
                    Layout.preferredWidth: lblVerRecibo.implicitWidth + 18
                    Layout.preferredHeight: 30
                    radius: 15
                    color: temaApp.panelAlt
                    border.color: temaApp.acento
                    border.width: 1

                    Text {
                        id: lblVerRecibo
                        anchors.centerIn: parent
                        text: "Ver Recibo"
                        color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                        font.pixelSize: 10
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rootRetiro.pasoActual = 2
                    }
                }
            }

            // =================================================================
            // 2. IDENTIFICACIÓN DEL ESTUDIANTE AUTENTICADO
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: flickRetiro.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                implicitHeight: colIdentEst.implicitHeight + 24
                radius: 20
                color: temaApp.vidrio
                border.color: temaApp.bordeVidrio
                border.width: 1

                ColumnLayout {
                    id: colIdentEst
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 4

                    Text {
                        text: (daeClient.cedulaEstudiante + " " + daeClient.nombreEstudiante).toUpperCase()
                        color: temaApp.textoPrincipal
                        font.pixelSize: 13
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "ESCUELA DE " + daeClient.escuelaEstudiante.toUpperCase()
                        color: temaApp.textoSecundario
                        font.pixelSize: 10
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            // =================================================================
            // 3. NOTA DE ADVERTENCIA OFICIAL DAE EN ROJO
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: flickRetiro.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                implicitHeight: txtNotaRoja.implicitHeight + 22
                radius: 16
                color: temaApp.esClaro ? "#fef2f2" : "#28ef4444"
                border.color: "#ef4444"
                border.width: 1

                Text {
                    id: txtNotaRoja
                    anchors.centerIn: parent
                    width: parent.width - 24
                    text: "NOTA: LA ASIGNATURA RETIRADA NO PODRÁ SER ADICIONADA POSTERIORMENTE"
                    color: temaApp.esClaro ? "#b91c1c" : "#fca5a5"
                    font.pixelSize: 11
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }

            // =================================================================
            // 4. PASO 1: TABLA DE ASIGNATURAS DEL USUARIO (CÓDIGO | ASIGNATURA | SECCIÓN | RETIRAR)
            // =================================================================
            Rectangle {
                visible: rootRetiro.pasoActual === 0
                Layout.fillWidth: true
                Layout.maximumWidth: flickRetiro.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                implicitHeight: colTablaRetiro.implicitHeight + 28
                radius: 22
                color: temaApp.panel
                border.color: temaApp.bordePanel
                border.width: 1

                ColumnLayout {
                    id: colTablaRetiro
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 0

                    // Cabecera de la tabla oficial: CÓDIGO | ASIGNATURA | SECCIÓN | RETIRAR
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: 10
                        color: temaApp.panelAlt
                        border.color: temaApp.bordeAlt
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 6

                            Text {
                                Layout.preferredWidth: 62
                                text: "CÓDIGO"
                                color: temaApp.textoPrincipal
                                font.pixelSize: 10
                                font.bold: true
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "ASIGNATURA"
                                color: temaApp.textoPrincipal
                                font.pixelSize: 10
                                font.bold: true
                            }

                            Text {
                                Layout.preferredWidth: 54
                                text: "SECCIÓN"
                                color: temaApp.textoPrincipal
                                font.pixelSize: 10
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                Layout.preferredWidth: 52
                                text: "RETIRAR"
                                color: temaApp.textoPrincipal
                                font.pixelSize: 10
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    // Filas de asignaturas inscritas por el usuario actual
                    Repeater {
                        model: rootRetiro.estadoMaterias

                        delegate: Rectangle {
                            id: filaMateriaRetiro
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.max(48, txtNomAsig.implicitHeight + 20)
                            color: modelData.checked
                                   ? (temaApp.esClaro ? "#fee2e2" : "#2d131a")
                                   : (index % 2 === 1 ? Qt.rgba(temaApp.panelAlt.r, temaApp.panelAlt.g, temaApp.panelAlt.b, 0.45) : "transparent")
                            border.color: modelData.checked ? "#ef4444" : temaApp.bordePanel
                            border.width: modelData.checked ? 1 : 0.5
                            radius: 8

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 6

                                Text {
                                    Layout.preferredWidth: 62
                                    text: modelData.codigo
                                    color: modelData.checked
                                           ? (temaApp.esClaro ? "#b91c1c" : "#fca5a5")
                                           : (temaApp.esClaro ? temaApp.primario : temaApp.claro)
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                Text {
                                    id: txtNomAsig
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 0
                                    text: modelData.nombre
                                    color: temaApp.textoPrincipal
                                    font.pixelSize: 11
                                    font.bold: modelData.checked
                                    wrapMode: Text.WordWrap
                                }

                                Text {
                                    Layout.preferredWidth: 54
                                    text: modelData.sec
                                    color: temaApp.textoPrincipal
                                    font.pixelSize: 12
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                Item {
                                    Layout.preferredWidth: 52
                                    Layout.preferredHeight: 32

                                    Rectangle {
                                        width: 22
                                        height: 22
                                        radius: 6
                                        anchors.centerIn: parent
                                        color: modelData.checked ? "#dc2626" : (temaApp.esClaro ? "#ffffff" : temaApp.panelAlt)
                                        border.color: modelData.checked ? "#ef4444" : temaApp.textoMuted
                                        border.width: 1.6

                                        Text {
                                            anchors.centerIn: parent
                                            visible: modelData.checked
                                            text: "✓"
                                            color: "white"
                                            font.pixelSize: 13
                                            font.bold: true
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: rootRetiro.toggleMateria(index)
                            }
                        }
                    }

                    // Estado vacío cuando el estudiante no tiene asignaturas inscritas cargadas
                    ColumnLayout {
                        visible: rootRetiro.estadoMaterias.length === 0
                        Layout.fillWidth: true
                        Layout.topMargin: 24
                        Layout.bottomMargin: 20
                        spacing: 8

                        Text {
                            Layout.fillWidth: true
                            text: daeClient.cargandoRetiro
                                  ? "Cargando asignaturas inscritas..."
                                  : "No se encontraron asignaturas inscritas para retirar en este período."
                            color: temaApp.textoSecundario
                            font.pixelSize: 12
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: !daeClient.cargandoRetiro
                            text: "Tus asignaturas inscritas aparecerán listadas aquí automáticamente desde tu horario activo."
                            color: temaApp.textoMuted
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            // Resumen de selección y botón "IR AL SIGUIENTE PASO" (Paso 1)
            ColumnLayout {
                visible: rootRetiro.pasoActual === 0
                Layout.fillWidth: true
                Layout.maximumWidth: flickRetiro.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 10

                Text {
                    visible: rootRetiro.cantidadSeleccionadas > 0
                    Layout.fillWidth: true
                    text: rootRetiro.cantidadSeleccionadas === 1
                          ? "1 asignatura marcada para retirar"
                          : (rootRetiro.cantidadSeleccionadas + " asignaturas marcadas para retirar")
                    color: temaApp.esClaro ? "#b91c1c" : "#fca5a5"
                    font.pixelSize: 12
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle {
                    id: btnIrSiguientePaso
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    radius: 25
                    border.color: rootRetiro.cantidadSeleccionadas > 0 ? "#f87171" : temaApp.bordeAlt
                    border.width: 1
                    opacity: rootRetiro.estadoMaterias.length > 0 ? 1.0 : 0.55

                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: rootRetiro.cantidadSeleccionadas > 0 ? "#dc2626" : temaApp.panelAlt
                        }
                        GradientStop {
                            position: 1.0
                            color: rootRetiro.cantidadSeleccionadas > 0 ? "#991b1b" : temaApp.panel
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "IR AL SIGUIENTE PASO"
                        color: rootRetiro.cantidadSeleccionadas > 0 ? "white" : temaApp.textoPrincipal
                        font.pixelSize: 13
                        font.bold: true
                        font.letterSpacing: 0.6
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: rootRetiro.estadoMaterias.length > 0
                        cursorShape: Qt.PointingHandCursor
                        onPressed: btnIrSiguientePaso.scale = 0.97
                        onReleased: btnIrSiguientePaso.scale = 1.0
                        onClicked: rootRetiro.irAlSiguientePaso()
                    }
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }
            }

            // =================================================================
            // 5. PASO 2: CONFIRMACIÓN DE RETIRO DE ASIGNATURA
            // =================================================================
            Rectangle {
                visible: rootRetiro.pasoActual === 1
                Layout.fillWidth: true
                Layout.maximumWidth: flickRetiro.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                implicitHeight: colConfirmarRetiro.implicitHeight + 32
                radius: 22
                color: temaApp.panel
                border.color: "#ef4444"
                border.width: 1.5

                ColumnLayout {
                    id: colConfirmarRetiro
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Text {
                        Layout.fillWidth: true
                        text: "¿Confirmas el retiro de las siguientes asignaturas?"
                        color: temaApp.textoPrincipal
                        font.pixelSize: 15
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Verifica cuidadosamente el código, nombre y sección antes de confirmar. Una vez retirada la asignatura, no podrá ser adicionada posteriormente."
                        color: temaApp.textoSecundario
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }

                    Repeater {
                        model: rootRetiro.listaSeleccionadasConfirmar

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            radius: 12
                            color: temaApp.esClaro ? "#fef2f2" : "#261219"
                            border.color: "#ef4444"
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8

                                Text {
                                    Layout.preferredWidth: 62
                                    text: modelData.codigo
                                    color: temaApp.esClaro ? "#b91c1c" : "#fca5a5"
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                Text {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 0
                                    text: modelData.nombre
                                    color: temaApp.textoPrincipal
                                    font.pixelSize: 11
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: "Sec. " + modelData.sec
                                    color: temaApp.textoSecundario
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        spacing: 10

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            radius: 15
                            color: temaApp.panelAlt
                            border.color: temaApp.bordeAlt
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "VOLVER ATRÁS"
                                color: temaApp.textoPrincipal
                                font.pixelSize: 12
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: rootRetiro.pasoActual = 0
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            radius: 15
                            color: "#dc2626"
                            border.color: "#f87171"
                            border.width: 1
                            opacity: daeClient.enviandoRetiro ? 0.65 : 1.0

                            Text {
                                anchors.centerIn: parent
                                text: daeClient.enviandoRetiro ? "PROCESANDO..." : "CONFIRMAR RETIRO"
                                color: "white"
                                font.pixelSize: 12
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: !daeClient.enviandoRetiro
                                cursorShape: Qt.PointingHandCursor
                                onClicked: daeClient.enviarSolicitudRetiro(rootRetiro.listaSeleccionadasConfirmar)
                            }
                        }
                    }
                }
            }

            // =================================================================
            // 6. PASO 3: COMPROBANTE DE SOLICITUD DE RETIRO PROCESADA
            // =================================================================
            Rectangle {
                visible: rootRetiro.pasoActual === 2
                Layout.fillWidth: true
                Layout.maximumWidth: flickRetiro.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                implicitHeight: colReciboRetiro.implicitHeight + 32
                radius: 22
                color: temaApp.panel
                border.color: "#22c55e"
                border.width: 1.5

                ColumnLayout {
                    id: colReciboRetiro
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Text {
                        Layout.fillWidth: true
                        text: "REPORTE DE SOLICITUD DE RETIRO " + daeClient.periodoRetiro
                        color: temaApp.textoPrincipal
                        font.pixelSize: 14
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        visible: daeClient.fechaSolicitudRetiro !== ""
                        Layout.fillWidth: true
                        text: "FECHA DE SOLICITUD: " + daeClient.fechaSolicitudRetiro
                        color: temaApp.textoSecundario
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Repeater {
                        model: daeClient.solicitudRetiroRegistrada

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            radius: 12
                            color: temaApp.panelAlt
                            border.color: temaApp.bordeAlt
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8

                                Text {
                                    Layout.preferredWidth: 62
                                    text: modelData.codigo
                                    color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                Text {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 0
                                    text: modelData.nombre
                                    color: temaApp.textoPrincipal
                                    font.pixelSize: 11
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: "Sec. " + modelData.sec
                                    color: temaApp.textoSecundario
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 46
                        radius: 15
                        color: temaApp.secundario
                        border.color: temaApp.acento
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "VOLVER A MIS ASIGNATURAS"
                            color: "white"
                            font.pixelSize: 12
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: rootRetiro.pasoActual = 0
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
        id: bannerRetiro
        property string mensaje: ""
        property bool esExito: true

        function mostrar(txt, ok) {
            mensaje = txt
            esExito = ok
            opacity = 1.0
            timerBannerRetiro.restart()
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
            text: bannerRetiro.mensaje
            color: "white"
            font.pixelSize: 11
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        Timer {
            id: timerBannerRetiro
            interval: 3200
            onTriggered: bannerRetiro.opacity = 0
        }
    }
}
