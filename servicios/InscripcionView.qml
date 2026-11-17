import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: rootInscripcion
    signal volver()

    // 0 = Paso 1 (Selección de Asignaturas + Horarios de Opción 1 y Opción 2)
    // 1 = Paso 2 (Confirmación: "¿Esta es la solicitud que desea registrar?")
    // 2 = Paso 3 (Reporte final: "REPORTE DE SOLICITUD DE INSCRIPCIÓN 2-2026")
    property int pasoActual: 0

    // Estado reactivo de selección por asignatura:
    // Cada elemento: { codigo, nombre, codParalelo, uc, checked, opc1, opc2, secciones: [...] }
    property var estadoMaterias: []
    property int revisionSeleccion: 0

    // Datos calculados en vivo para las mallas de Opción 1 y Opción 2 y validación de choques
    property var mallaOpcion1: crearMallaVacia()
    property var mallaOpcion2: crearMallaVacia()
    property int horasCoincidenciaOpc1: 0
    property int horasCoincidenciaOpc2: 0
    property bool choqueInvalidoOpc1: false
    property bool choqueInvalidoOpc2: false
    property string detalleChoqueOpc1: ""
    property string detalleChoqueOpc2: ""

    // Lista de asignaturas seleccionadas lista para confirmar y registrar
    property var listaSeleccionadasConfirmar: []

    // Modales
    property bool mostrarDialogoConfirmarEnvio: false
    property bool mostrarDialogoAlerta: false
    property string textoDialogoAlerta: ""

    readonly property var etiquetasHorasMalla: [
        "08:00-08:50",
        "08:50-09:40",
        "09:40-10:30",
        "10:30-11:20",
        "11:20-12:10",
        "12:10-01:00",
        "01:00-01:50",
        "01:50-02:40",
        "02:40-03:30",
        "03:30-04:20",
        "04:20-05:10",
        "05:10-06:00",
        "-",
        "-"
    ]

    readonly property var etiquetasDiasMalla: ["Lu", "Ma", "Mi", "Ju", "Vi", "Sa", "Do"]

    function crearMallaVacia() {
        var filas = []
        for (var h = 0; h < 14; ++h) {
            var celdasDia = []
            for (var d = 0; d < 7; ++d) {
                celdasDia.push({ count: 0, codigos: [], texto: "" })
            }
            filas.push(celdasDia)
        }
        return filas
    }

    function limpiarSeleccionEnBlanco() {
        var origen = daeClient.materiasInscripcion || []
        var nueva = []
        for (var i = 0; i < origen.length; ++i) {
            var m = origen[i]
            nueva.push({
                codigo: m.codigo || "",
                nombre: m.nombre || "",
                codParalelo: m.codParalelo || "",
                uc: m.uc !== undefined ? m.uc : 0,
                checked: false,
                opc1: "",
                opc2: "",
                secciones: m.secciones || []
            })
        }
        estadoMaterias = nueva
        recalcularHorariosYChoques()
    }

    function sincronizarDesdeCliente() {
        var origen = daeClient.materiasInscripcion || []
        var mapaPrevio = {}
        for (var p = 0; p < estadoMaterias.length; ++p) {
            var ant = estadoMaterias[p]
            mapaPrevio[ant.codigo] = ant
        }

        var nueva = []
        for (var i = 0; i < origen.length; ++i) {
            var m = origen[i]
            var cod = m.codigo || ""
            var secs = m.secciones || []
            var prev = mapaPrevio[cod]

            var chk = false
            var o1 = ""
            var o2 = ""

            if (prev !== undefined) {
                chk = prev.checked
                o1 = prev.opc1
                o2 = prev.opc2
            }

            nueva.push({
                codigo: cod,
                nombre: m.nombre || "",
                codParalelo: m.codParalelo || "",
                uc: m.uc !== undefined ? m.uc : 0,
                checked: chk,
                opc1: o1,
                opc2: o2,
                secciones: secs
            })
        }
        estadoMaterias = nueva
        recalcularHorariosYChoques()
    }

    function obtenerCeldasDeSeccion(materiaObj, secCodigo) {
        if (!materiaObj || !secCodigo || secCodigo === "") return []
        var secs = materiaObj.secciones || []
        for (var i = 0; i < secs.length; ++i) {
            if (secs[i].sec === secCodigo) {
                return secs[i].celdas || []
            }
        }
        return []
    }

    function evaluarOpcionMalla(numOpcion) {
        var malla = crearMallaVacia()
        for (var i = 0; i < estadoMaterias.length; ++i) {
            var mat = estadoMaterias[i]
            if (!mat.checked) continue
            var secElegida = (numOpcion === 1) ? mat.opc1 : (mat.opc2 !== "" ? mat.opc2 : mat.opc1)
            if (!secElegida || secElegida === "") continue

            var celdas = obtenerCeldasDeSeccion(mat, secElegida)
            for (var c = 0; c < celdas.length; ++c) {
                var d = celdas[c].dia
                var h = celdas[c].hora
                if (d >= 0 && d < 7 && h >= 0 && h < 14) {
                    var celda = malla[h][d]
                    if (celda.codigos.indexOf(mat.codigo) === -1) {
                        celda.codigos.push(mat.codigo)
                        celda.count = celda.codigos.length
                        celda.texto = celda.codigos.join("\n")
                    }
                }
            }
        }

        // Analizar coincidencias (choques de horario) según las reglas oficiales de DAE:
        // 1. Dos materias pueden coincidir en máximo 1 bloque. Si dos materias coinciden en 2 o más bloques -> Inválido.
        // 2. Pueden existir hasta dos pares de materias que coincidan 1 bloque cada uno (máximo 2 bloques de coincidencia en total).
        // 3. Si ya hay dos pares con 1 bloque de coincidencia, ninguna otra materia puede coincidir en ningún bloque.
        var bloquesPorPar = {}
        var horasChoqueTotal = 0
        var tripleChoqueDetectado = false
        var celdaTripleTexto = ""

        for (var fila = 0; fila < 14; ++fila) {
            for (var col = 0; col < 7; ++col) {
                var cods = malla[fila][col].codigos
                if (cods.length >= 2) {
                    horasChoqueTotal += (cods.length - 1)
                    if (cods.length >= 3) {
                        tripleChoqueDetectado = true
                        celdaTripleTexto = cods.join(", ")
                    }
                    for (var a = 0; a < cods.length; ++a) {
                        for (var b = a + 1; b < cods.length; ++b) {
                            var c1 = cods[a] < cods[b] ? cods[a] : cods[b]
                            var c2 = cods[a] < cods[b] ? cods[b] : cods[a]
                            var clavePar = c1 + " y " + c2
                            bloquesPorPar[clavePar] = (bloquesPorPar[clavePar] || 0) + 1
                        }
                    }
                }
            }
        }

        var invalido = false
        var motivo = ""
        var paresConChoque = 0

        if (tripleChoqueDetectado) {
            invalido = true
            motivo = "Tres asignaturas (" + celdaTripleTexto + ") coinciden en el mismo bloque horario."
        }

        for (var par in bloquesPorPar) {
            paresConChoque++
            var cantBloques = bloquesPorPar[par]
            if (cantBloques >= 2 && !invalido) {
                invalido = true
                motivo = "Las asignaturas " + par + " coinciden en " + cantBloques + " bloques (máximo permitido: 1 bloque por par)."
            }
        }

        if (!invalido && (paresConChoque > 2 || horasChoqueTotal > 2)) {
            invalido = true
            motivo = "Existen " + horasChoqueTotal + " bloques en coincidencia (el sistema solo permite hasta 2 coincidencias de 1 bloque cada una)."
        }

        return {
            malla: malla,
            horasCoincidencia: horasChoqueTotal,
            invalido: invalido,
            motivo: motivo
        }
    }

    function recalcularHorariosYChoques() {
        var res1 = evaluarOpcionMalla(1)
        mallaOpcion1 = res1.malla
        horasCoincidenciaOpc1 = res1.horasCoincidencia
        choqueInvalidoOpc1 = res1.invalido
        detalleChoqueOpc1 = res1.motivo

        var res2 = evaluarOpcionMalla(2)
        mallaOpcion2 = res2.malla
        horasCoincidenciaOpc2 = res2.horasCoincidencia
        choqueInvalidoOpc2 = res2.invalido
        detalleChoqueOpc2 = res2.motivo

        revisionSeleccion++
    }

    function toggleCheckMateria(idx, nuevoCheck) {
        if (idx < 0 || idx >= estadoMaterias.length) return
        var copia = estadoMaterias.slice()
        var item = copia[idx]
        item.checked = nuevoCheck

        if (nuevoCheck) {
            // Al igual que en eventos14.js (habilitar): si la asignatura tiene solo 1 sección, se autoselecciona
            if (item.secciones && item.secciones.length === 1) {
                var unicaSec = item.secciones[0].sec
                item.opc1 = unicaSec
                item.opc2 = unicaSec
            }
            // Si es un laboratorio con requisito paralelo (ej. SA6T01L -> SA6T01), marcar automáticamente su teoría si está en la lista
            if (item.codParalelo && item.codParalelo !== "") {
                for (var k = 0; k < copia.length; ++k) {
                    if (copia[k].codigo === item.codParalelo && !copia[k].checked) {
                        copia[k].checked = true
                        if (copia[k].secciones && copia[k].secciones.length === 1) {
                            copia[k].opc1 = copia[k].secciones[0].sec
                            copia[k].opc2 = copia[k].secciones[0].sec
                        }
                    }
                }
            }
        } else {
            item.opc1 = ""
            item.opc2 = ""
        }

        estadoMaterias = copia
        recalcularHorariosYChoques()
    }

    function cambiarSeccionMateria(idx, numOpcion, nuevaSec) {
        if (idx < 0 || idx >= estadoMaterias.length) return
        var copia = estadoMaterias.slice()
        var item = copia[idx]
        if (numOpcion === 1) {
            item.opc1 = nuevaSec
            // Si Opción 2 aún estaba en "Seccion" (vacía), igualarla a Opción 1 como hace el sistema DAE
            if (nuevaSec !== "" && item.opc2 === "") {
                item.opc2 = nuevaSec
            }
        } else {
            item.opc2 = nuevaSec
        }
        estadoMaterias = copia
        recalcularHorariosYChoques()
    }

    function validarYAvanzarPaso1() {
        var seleccionadas = []
        var mapaMarcadas = {}

        for (var i = 0; i < estadoMaterias.length; ++i) {
            var m = estadoMaterias[i]
            if (m.checked) {
                mapaMarcadas[m.codigo] = true
                if (!m.opc1 || m.opc1 === "") {
                    textoDialogoAlerta = "Debe seleccionar al menos la Opción 1 en la asignatura marcada:\n" + m.codigo + " - " + m.nombre
                    mostrarDialogoAlerta = true
                    return
                }
                seleccionadas.push({
                    codigo: m.codigo,
                    nombre: m.nombre,
                    opcion1: m.opc1,
                    opcion2: (m.opc2 && m.opc2 !== "") ? m.opc2 : m.opc1
                })
            }
        }

        if (seleccionadas.length === 0) {
            textoDialogoAlerta = "Debe seleccionar al menos una asignatura para continuar al siguiente paso."
            mostrarDialogoAlerta = true
            return
        }

        // Validar prelación en paralelo (eventos14.js -> validar_prelacion)
        for (var j = 0; j < estadoMaterias.length; ++j) {
            var mat = estadoMaterias[j]
            if (mat.checked && mat.codParalelo && mat.codParalelo !== "") {
                // Verificar si el requisito paralelo está en la oferta del estudiante y no fue marcado
                for (var p = 0; p < estadoMaterias.length; ++p) {
                    if (estadoMaterias[p].codigo === mat.codParalelo && !estadoMaterias[p].checked) {
                        textoDialogoAlerta = "Para inscribir " + mat.codigo + " (" + mat.nombre + ") debe inscribir en paralelo la asignatura " + mat.codParalelo + "."
                        mostrarDialogoAlerta = true
                        return
                    }
                }
            }
        }

        // Validar reglas de coincidencia de bloques en Opción 1 y Opción 2
        if (choqueInvalidoOpc1) {
            textoDialogoAlerta = "No es posible inscribir con la selección actual en HORARIO DE OPCIÓN 1:\n\n" + detalleChoqueOpc1
            mostrarDialogoAlerta = true
            return
        }
        if (choqueInvalidoOpc2) {
            textoDialogoAlerta = "No es posible inscribir con la selección actual en HORARIO DE OPCIÓN 2:\n\n" + detalleChoqueOpc2
            mostrarDialogoAlerta = true
            return
        }

        listaSeleccionadasConfirmar = seleccionadas
        mostrarDialogoConfirmarEnvio = true
    }

    property bool usuarioCambioPestanaManualmente: false

    Component.onCompleted: {
        daeClient.cargarDatosInscripcion()
        limpiarSeleccionEnBlanco()
        if (daeClient.reporteInscripcionDisponible && daeClient.solicitudInscripcionRegistrada.length > 0) {
            rootInscripcion.pasoActual = 2
        } else if (!daeClient.inscripcionDisponible && daeClient.reporteInscripcionDisponible) {
            rootInscripcion.pasoActual = 2
        }
    }

    onVisibleChanged: {
        if (visible) {
            usuarioCambioPestanaManualmente = false
            daeClient.cargarDatosInscripcion()
            limpiarSeleccionEnBlanco()
            if (daeClient.reporteInscripcionDisponible && daeClient.solicitudInscripcionRegistrada.length > 0) {
                rootInscripcion.pasoActual = 2
            }
        }
    }

    Connections {
        target: daeClient
        function onInscripcionChanged() {
            sincronizarDesdeCliente()
            if (!rootInscripcion.usuarioCambioPestanaManualmente &&
                rootInscripcion.pasoActual === 0 &&
                daeClient.reporteInscripcionDisponible &&
                daeClient.solicitudInscripcionRegistrada.length > 0) {
                rootInscripcion.pasoActual = 2
            }
        }
        function onRapChanged() {
            if (estadoMaterias.length === 0) {
                sincronizarDesdeCliente()
            }
        }
        function onSolicitudInscripcionCompletada(exito, mensaje) {
            if (exito) {
                rootInscripcion.limpiarSeleccionEnBlanco()
                rootInscripcion.pasoActual = 2
                flickInscripcion.contentY = 0
                daeClient.registrarSolicitudReciente(
                    "INS",
                    "Solicitud de Inscripción",
                    (daeClient.solicitudInscripcionRegistrada.length > 0
                        ? daeClient.solicitudInscripcionRegistrada.length + " Asignaturas • "
                        : "") + (daeClient.fechaSolicitudInscripcion !== "" ? daeClient.fechaSolicitudInscripcion : "Registrada"),
                    "Registrada")
            } else {
                rootInscripcion.textoDialogoAlerta = mensaje
                rootInscripcion.mostrarDialogoAlerta = true
            }
        }
    }

    // ========================================================================
    // COMPONENTE REUTILIZABLE: MALLA DE HORARIO DE OPCIÓN 1 / OPCIÓN 2
    // ========================================================================
    component TablaMallaOpcion: ColumnLayout {
        id: rootMalla
        property string tituloMalla: "HORARIO DE OPCION 1"
        property var datosMalla: []
        property int horasCoincidencia: 0
        property bool choqueInvalido: false
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            Text {
                text: rootMalla.tituloMalla
                color: temaApp.textoPrincipal
                font.pixelSize: 13
                font.bold: true
            }

            Rectangle {
                visible: rootMalla.horasCoincidencia > 0
                height: 20
                radius: 10
                width: txtBadgeChoque.implicitWidth + 14
                color: rootMalla.choqueInvalido ? "#35ef4444" : "#30f59e0b"
                border.color: rootMalla.choqueInvalido ? "#ef4444" : "#f59e0b"
                border.width: 1

                Text {
                    id: txtBadgeChoque
                    anchors.centerIn: parent
                    text: rootMalla.horasCoincidencia + (rootMalla.horasCoincidencia === 1 ? " coincidencia" : " coincidencias")
                    color: rootMalla.choqueInvalido ? "#fca5a5" : "#fcd34d"
                    font.pixelSize: 10
                    font.bold: true
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: colFilasMalla.implicitHeight + 2
            radius: 10
            color: temaApp.esClaro ? "#ffffff" : temaApp.panel
            border.color: rootMalla.choqueInvalido ? "#ef4444" : temaApp.bordePanel
            border.width: rootMalla.choqueInvalido ? 1.5 : 1
            clip: true

            ColumnLayout {
                id: colFilasMalla
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 1
                spacing: 0

                // Cabecera de días: [Hora] | Lu | Ma | Mi | Ju | Vi | Sa | Do
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 26
                    color: temaApp.esClaro ? "#e2e8f0" : temaApp.panelAlt

                    RowLayout {
                        anchors.fill: parent
                        spacing: 0

                        Item {
                            Layout.preferredWidth: 62
                            Layout.minimumWidth: 62
                            Layout.maximumWidth: 62
                            Layout.fillHeight: true
                            Rectangle {
                                width: 1; height: parent.height
                                anchors.right: parent.right
                                color: temaApp.bordePanel
                            }
                        }

                        Repeater {
                            model: rootInscripcion.etiquetasDiasMalla
                            delegate: Item {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                Layout.preferredWidth: 0
                                Layout.fillHeight: true

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: temaApp.textoPrincipal
                                    font.pixelSize: 10
                                    font.bold: true
                                }

                                Rectangle {
                                    visible: index < 6
                                    width: 1; height: parent.height
                                    anchors.right: parent.right
                                    color: temaApp.bordePanel
                                }
                            }
                        }
                    }

                    Rectangle {
                        height: 1; width: parent.width
                        anchors.bottom: parent.bottom
                        color: temaApp.bordePanel
                    }
                }

                // 14 Filas horarias (08:00-08:50 ... 05:10-06:00 y 2 filas "-")
                Repeater {
                    model: 14
                    delegate: Rectangle {
                        id: filaMallaItem
                        readonly property int filaIdx: index
                        Layout.fillWidth: true
                        Layout.preferredHeight: 23
                        color: filaIdx % 2 === 0
                               ? (temaApp.esClaro ? "#ffffff" : temaApp.panel)
                               : (temaApp.esClaro ? "#f8fafc" : "#12ffffff")

                        RowLayout {
                            anchors.fill: parent
                            spacing: 0

                            // Columna de hora (08:00-08:50)
                            Item {
                                Layout.preferredWidth: 62
                                Layout.minimumWidth: 62
                                Layout.maximumWidth: 62
                                Layout.fillHeight: true

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 3
                                    text: rootInscripcion.etiquetasHorasMalla[filaMallaItem.filaIdx]
                                    color: temaApp.textoSecundario
                                    font.pixelSize: 9
                                    font.bold: true
                                }

                                Rectangle {
                                    width: 1; height: parent.height
                                    anchors.right: parent.right
                                    color: temaApp.bordePanel
                                }
                            }

                            // 7 Celdas de día (Lu..Do)
                            Repeater {
                                model: 7
                                delegate: Rectangle {
                                    readonly property int diaIdx: index
                                    readonly property var infoCelda: (rootMalla.datosMalla &&
                                                                      rootMalla.datosMalla[filaMallaItem.filaIdx] &&
                                                                      rootMalla.datosMalla[filaMallaItem.filaIdx][diaIdx])
                                                                     ? rootMalla.datosMalla[filaMallaItem.filaIdx][diaIdx]
                                                                     : ({ count: 0, codigos: [], texto: "" })

                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    Layout.preferredWidth: 0
                                    Layout.fillHeight: true
                                    // Verde #00e600 cuando hay 1 materia, Rojo #ff1f1f cuando hay coincidencia (igual al sistema DAE)
                                    color: infoCelda.count === 0
                                           ? "transparent"
                                           : (infoCelda.count === 1 ? "#00e600" : "#ff1f1f")

                                    Text {
                                        anchors.centerIn: parent
                                        width: parent.width - 2
                                        text: infoCelda.count === 1
                                              ? infoCelda.codigos[0]
                                              : (infoCelda.count >= 2 ? infoCelda.codigos.join("/") : "")
                                        color: infoCelda.count === 1 ? "#052e05" : "#ffffff"
                                        font.pixelSize: infoCelda.count === 1 ? 8 : 7
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        visible: diaIdx < 6
                                        width: 1; height: parent.height
                                        anchors.right: parent.right
                                        color: temaApp.bordePanel
                                    }
                                }
                            }
                        }

                        Rectangle {
                            visible: filaMallaItem.filaIdx < 13
                            height: 1; width: parent.width
                            anchors.bottom: parent.bottom
                            color: temaApp.bordePanel
                        }
                    }
                }
            }
        }
    }

    // ========================================================================
    // CONTENIDO DESLIZABLE PRINCIPAL
    // ========================================================================
    Flickable {
        id: flickInscripcion
        anchors.fill: parent
        contentWidth: width
        contentHeight: colPrincipal.implicitHeight + 135
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: colPrincipal
            width: flickInscripcion.width
            spacing: 14

            // 1. BARRA SUPERIOR CON BOTÓN VOLVER Y SELECTOR DE VISTA
            RowLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.maximumWidth: flickInscripcion.width - 28
                Layout.topMargin: 22
                Layout.leftMargin: 14
                Layout.rightMargin: 14
                spacing: 10

                Rectangle {
                    id: btnBackInsc
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 38
                    Layout.minimumWidth: 38
                    Layout.maximumWidth: 38
                    width: 38; height: 38; radius: 19
                    color: temaApp.vidrio
                    border.color: temaApp.bordeVidrio
                    border.width: 1

                    Canvas {
                        width: 18; height: 18
                        anchors.centerIn: parent
                        property color cTrazo: temaApp.textoPrincipal
                        onCTrazoChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            ctx.strokeStyle = cTrazo
                            ctx.lineWidth = 2.2
                            ctx.lineCap = "round"
                            ctx.lineJoin = "round"
                            ctx.beginPath()
                            ctx.moveTo(11, 4)
                            ctx.lineTo(5, 9)
                            ctx.lineTo(11, 14)
                            ctx.stroke()
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPressed: btnBackInsc.scale = 0.90
                        onReleased: btnBackInsc.scale = 1.0
                        onClicked: {
                            if (rootInscripcion.pasoActual === 1) {
                                rootInscripcion.pasoActual = 0
                            } else {
                                rootInscripcion.volver()
                            }
                        }
                    }
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.preferredWidth: 0
                    spacing: 1
                    Text {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: "Inscripción de Asignaturas"
                        color: temaApp.textoPrincipal
                        font.pixelSize: 16
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: "Período Lectivo " + daeClient.periodoInscripcion + " • DAE Ingeniería UC"
                        color: temaApp.textoSubtitulo
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                // Botón rápido para ver el Reporte Registrado sin tener que volver a inscribirse
                Rectangle {
                    visible: rootInscripcion.pasoActual !== 2
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: txtVerReporte.implicitWidth + 18
                    Layout.minimumWidth: txtVerReporte.implicitWidth + 18
                    height: 30
                    radius: 15
                    width: txtVerReporte.implicitWidth + 18
                    color: temaApp.panelAlt
                    border.color: temaApp.primario
                    border.width: 1

                    Text {
                        id: txtVerReporte
                        anchors.centerIn: parent
                        text: "Ver Reporte"
                        color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                        font.pixelSize: 11
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            rootInscripcion.usuarioCambioPestanaManualmente = true
                            rootInscripcion.pasoActual = 2
                            flickInscripcion.contentY = 0
                        }
                    }
                }
            }

            // 2. SELECTOR DE VISTAS / PASOS (1. Solicitar Inscripción <-> Confirmar <-> 3. Reporte de Solicitud)
            Rectangle {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.maximumWidth: flickInscripcion.width - 24
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                height: 58
                radius: 12
                color: temaApp.panel
                border.color: temaApp.bordePanel
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    spacing: 3

                    Repeater {
                        model: [
                            { idx: 0, titulo: "1. Solicitar Inscripción", clicable: true },
                            { idx: 1, titulo: "2. Confirmación", clicable: false },
                            { idx: 2, titulo: "3. Reporte de Solicitud", clicable: true }
                        ]
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            Layout.preferredWidth: 0
                            Layout.preferredHeight: 44
                            radius: 8
                            readonly property bool activo: rootInscripcion.pasoActual === modelData.idx
                            color: activo ? temaApp.primario : "transparent"

                            Text {
                                anchors.centerIn: parent
                                width: parent.width - 6
                                text: modelData.titulo
                                color: parent.activo ? "#ffffff" : (modelData.clicable ? temaApp.textoPrincipal : temaApp.textoMuted)
                                font.pixelSize: 10
                                font.bold: parent.activo || modelData.clicable
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                wrapMode: Text.WordWrap
                                elide: Text.ElideRight
                                maximumLineCount: 2
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: modelData.clicable
                                cursorShape: modelData.clicable ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    rootInscripcion.usuarioCambioPestanaManualmente = true
                                    if (modelData.idx === 0 && rootInscripcion.pasoActual !== 0) {
                                        rootInscripcion.limpiarSeleccionEnBlanco()
                                    }
                                    rootInscripcion.pasoActual = modelData.idx
                                    flickInscripcion.contentY = 0
                                }
                            }
                        }
                    }
                }
            }

            // ====================================================================
            // AVISO CUANDO LAS INSCRIPCIONES NO ESTÁN DISPONIBLES (Cerradas en DAE)
            // ====================================================================
            Rectangle {
                visible: rootInscripcion.pasoActual === 0 && !daeClient.inscripcionDisponible && !daeClient.cargandoInscripcion
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.maximumWidth: flickInscripcion.width - 28
                Layout.leftMargin: 14
                Layout.rightMargin: 14
                implicitHeight: colInscripcionCerrada.implicitHeight + 36
                radius: 16
                color: temaApp.panel
                border.color: temaApp.bordePanel
                border.width: 1

                ColumnLayout {
                    id: colInscripcionCerrada
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 10

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 48; height: 48; radius: 24
                        color: temaApp.panelAlt
                        border.color: temaApp.bordeAlt
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "🔒"
                            font.pixelSize: 20
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: "Inscripciones No Disponibles"
                        color: temaApp.textoPrincipal
                        font.pixelSize: 16
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: "El proceso de solicitud de inscripción de asignaturas no se encuentra habilitado actualmente en el servidor de la DAE."
                        color: temaApp.textoSecundario
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        visible: daeClient.reporteInscripcionDisponible && daeClient.solicitudInscripcionRegistrada.length > 0
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 6
                        width: 220
                        height: 36
                        radius: 10
                        color: temaApp.primario

                        Text {
                            anchors.centerIn: parent
                            text: "Ver Reporte de Solicitud"
                            color: "#ffffff"
                            font.pixelSize: 12
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                rootInscripcion.usuarioCambioPestanaManualmente = true
                                rootInscripcion.pasoActual = 2
                                flickInscripcion.contentY = 0
                            }
                        }
                    }
                }
            }

            // ====================================================================
            // PASO 1: TABLA DE SELECCIÓN DE ASIGNATURAS + HORARIOS OPCIÓN 1 Y 2
            // ====================================================================
            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.maximumWidth: flickInscripcion.width - 24
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                spacing: 14
                visible: rootInscripcion.pasoActual === 0 && daeClient.inscripcionDisponible

                // Banner institucional con las instrucciones y datos del estudiante autenticado
                Rectangle {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    implicitHeight: colCabeceraPaso1.implicitHeight + 22
                    radius: 14
                    color: temaApp.panel
                    border.color: temaApp.bordeAlt
                    border.width: 1

                    ColumnLayout {
                        id: colCabeceraPaso1
                        anchors.fill: parent
                        anchors.margins: 11
                        spacing: 4

                        Text {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: "DEBE SELECCIONAR AL MENOS LA OPCIÓN 1 EN CADA ASIGNATURA MARCADA"
                            color: temaApp.esClaro ? temaApp.oscuro : temaApp.claro
                            font.pixelSize: 11
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: "ESTUDIANTE: " + daeClient.cedulaEstudiante + " " + daeClient.nombreEstudiante
                            color: temaApp.textoPrincipal
                            font.pixelSize: 11
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                // Tabla de asignaturas que el usuario puede inscribir según su RAP y la oferta vigente
                Rectangle {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    implicitHeight: colTablaMaterias.implicitHeight + 2
                    radius: 12
                    color: temaApp.panel
                    border.color: temaApp.bordePanel
                    border.width: 1
                    clip: true

                    ColumnLayout {
                        id: colTablaMaterias
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 1
                        spacing: 0

                        // Encabezado de columnas: Check | Materia | Nombre | Opcion1 | Opcion2
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            color: temaApp.esClaro ? "#e2e8f0" : temaApp.panelAlt

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 4
                                anchors.rightMargin: 4
                                spacing: 4

                                Text {
                                    Layout.preferredWidth: 32
                                    Layout.minimumWidth: 32
                                    Layout.maximumWidth: 32
                                    text: "Check"
                                    color: temaApp.textoPrincipal
                                    font.pixelSize: 10
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                Text {
                                    Layout.preferredWidth: 56
                                    Layout.minimumWidth: 56
                                    Layout.maximumWidth: 56
                                    text: "Materia"
                                    color: temaApp.textoPrincipal
                                    font.pixelSize: 10
                                    font.bold: true
                                }

                                Text {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    Layout.preferredWidth: 0
                                    text: "Nombre"
                                    color: temaApp.textoPrincipal
                                    font.pixelSize: 10
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                Text {
                                    Layout.preferredWidth: 60
                                    Layout.minimumWidth: 60
                                    Layout.maximumWidth: 60
                                    text: "Opcion1"
                                    color: temaApp.textoPrincipal
                                    font.pixelSize: 10
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                Text {
                                    Layout.preferredWidth: 60
                                    Layout.minimumWidth: 60
                                    Layout.maximumWidth: 60
                                    text: "Opcion2"
                                    color: temaApp.textoPrincipal
                                    font.pixelSize: 10
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            Rectangle {
                                height: 1; width: parent.width
                                anchors.bottom: parent.bottom
                                color: temaApp.bordePanel
                            }
                        }

                        // Estado de carga o sin materias disponibles
                        Item {
                            visible: rootInscripcion.estadoMaterias.length === 0
                            Layout.fillWidth: true
                            Layout.preferredHeight: 90

                            Text {
                                anchors.centerIn: parent
                                width: parent.width - 32
                                text: daeClient.cargandoInscripcion
                                      ? "Consultando asignaturas disponibles para tu RAP..."
                                      : "Sincronizando oferta de asignaturas habilitadas en tu RAP..."
                                color: temaApp.textoMuted
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                            }
                        }

                        // Filas de asignaturas disponibles para el estudiante
                        Repeater {
                            model: rootInscripcion.estadoMaterias
                            delegate: Rectangle {
                                id: filaMat
                                readonly property int rowIdx: index
                                readonly property var matData: modelData
                                readonly property var listaSecs: matData.secciones || []

                                Layout.fillWidth: true
                                Layout.preferredHeight: 44
                                color: matData.checked
                                       ? (temaApp.esClaro ? "#183b82f6" : "#22ffffff")
                                       : (rowIdx % 2 === 0 ? "transparent" : (temaApp.esClaro ? "#f8fafc" : "#0affffff"))

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 4
                                    anchors.rightMargin: 4
                                    spacing: 4

                                    // 1. Casilla Check
                                    Item {
                                        Layout.preferredWidth: 32
                                        Layout.minimumWidth: 32
                                        Layout.maximumWidth: 32
                                        Layout.fillHeight: true

                                        Rectangle {
                                            width: 20; height: 20; radius: 5
                                            anchors.centerIn: parent
                                            color: filaMat.matData.checked ? "#2563eb" : (temaApp.esClaro ? "#ffffff" : temaApp.panelAlt)
                                            border.color: filaMat.matData.checked ? "#2563eb" : temaApp.textoMuted
                                            border.width: 1.5

                                            Canvas {
                                                visible: filaMat.matData.checked
                                                width: 13; height: 13
                                                anchors.centerIn: parent
                                                onPaint: {
                                                    var ctx = getContext("2d")
                                                    ctx.reset()
                                                    ctx.strokeStyle = "#ffffff"
                                                    ctx.lineWidth = 2.2
                                                    ctx.lineCap = "round"
                                                    ctx.lineJoin = "round"
                                                    ctx.beginPath()
                                                    ctx.moveTo(2, 7)
                                                    ctx.lineTo(5.5, 10.5)
                                                    ctx.lineTo(11, 3)
                                                    ctx.stroke()
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: rootInscripcion.toggleCheckMateria(filaMat.rowIdx, !filaMat.matData.checked)
                                        }
                                    }

                                    // 2. Código de la Materia
                                    Text {
                                        Layout.preferredWidth: 56
                                        Layout.minimumWidth: 56
                                        Layout.maximumWidth: 56
                                        text: filaMat.matData.codigo
                                        color: temaApp.textoPrincipal
                                        font.pixelSize: 11
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }

                                    // 3. Nombre de la Materia
                                    Text {
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 0
                                        Layout.preferredWidth: 0
                                        text: filaMat.matData.nombre
                                        color: temaApp.textoPrincipal
                                        font.pixelSize: 11
                                        maximumLineCount: 2
                                        wrapMode: Text.Wrap
                                        elide: Text.ElideRight
                                    }

                                    // 4. Selector Opcion1
                                    ComboBox {
                                        id: comboOpc1
                                        Layout.preferredWidth: 60
                                        Layout.minimumWidth: 60
                                        Layout.maximumWidth: 60
                                        Layout.preferredHeight: 30
                                        padding: 0
                                        leftPadding: 4
                                        rightPadding: 14
                                        enabled: filaMat.matData.checked

                                        property var opcionesModelo: {
                                            var arr = ["Seccion"]
                                            for (var s = 0; s < filaMat.listaSecs.length; ++s) {
                                                arr.push(filaMat.listaSecs[s].sec)
                                            }
                                            return arr
                                        }
                                        model: opcionesModelo
                                        currentIndex: {
                                            if (!filaMat.matData.checked || !filaMat.matData.opc1 || filaMat.matData.opc1 === "") return 0
                                            var pos = opcionesModelo.indexOf(filaMat.matData.opc1)
                                            return pos >= 0 ? pos : 0
                                        }

                                        onActivated: function(idxSel) {
                                            var val = (idxSel <= 0) ? "" : opcionesModelo[idxSel]
                                            rootInscripcion.cambiarSeccionMateria(filaMat.rowIdx, 1, val)
                                        }

                                        indicator: Text {
                                            x: comboOpc1.width - width - 4
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "▾"
                                            font.pixelSize: 10
                                            color: comboOpc1.enabled ? temaApp.textoPrincipal : temaApp.textoMuted
                                        }

                                        background: Rectangle {
                                            radius: 6
                                            color: comboOpc1.enabled
                                                   ? (temaApp.esClaro ? "#ffffff" : temaApp.panelAlt)
                                                   : (temaApp.esClaro ? "#f1f5f9" : "#15ffffff")
                                            border.color: comboOpc1.enabled ? temaApp.bordeAlt : temaApp.bordePanel
                                            border.width: 1
                                        }

                                        contentItem: Text {
                                            leftPadding: 4
                                            rightPadding: 14
                                            text: comboOpc1.displayText
                                            color: comboOpc1.enabled ? temaApp.textoPrincipal : temaApp.textoMuted
                                            font.pixelSize: 10
                                            font.bold: comboOpc1.currentIndex > 0
                                            verticalAlignment: Text.AlignVCenter
                                            elide: Text.ElideRight
                                        }
                                    }

                                    // 5. Selector Opcion2
                                    ComboBox {
                                        id: comboOpc2
                                        Layout.preferredWidth: 60
                                        Layout.minimumWidth: 60
                                        Layout.maximumWidth: 60
                                        Layout.preferredHeight: 30
                                        padding: 0
                                        leftPadding: 4
                                        rightPadding: 14
                                        enabled: filaMat.matData.checked

                                        property var opcionesModelo: {
                                            var arr = ["Seccion"]
                                            for (var s = 0; s < filaMat.listaSecs.length; ++s) {
                                                arr.push(filaMat.listaSecs[s].sec)
                                            }
                                            return arr
                                        }
                                        model: opcionesModelo
                                        currentIndex: {
                                            if (!filaMat.matData.checked || !filaMat.matData.opc2 || filaMat.matData.opc2 === "") return 0
                                            var pos = opcionesModelo.indexOf(filaMat.matData.opc2)
                                            return pos >= 0 ? pos : 0
                                        }

                                        onActivated: function(idxSel) {
                                            var val = (idxSel <= 0) ? "" : opcionesModelo[idxSel]
                                            rootInscripcion.cambiarSeccionMateria(filaMat.rowIdx, 2, val)
                                        }

                                        indicator: Text {
                                            x: comboOpc2.width - width - 4
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "▾"
                                            font.pixelSize: 10
                                            color: comboOpc2.enabled ? temaApp.textoPrincipal : temaApp.textoMuted
                                        }

                                        background: Rectangle {
                                            radius: 6
                                            color: comboOpc2.enabled
                                                   ? (temaApp.esClaro ? "#ffffff" : temaApp.panelAlt)
                                                   : (temaApp.esClaro ? "#f1f5f9" : "#15ffffff")
                                            border.color: comboOpc2.enabled ? temaApp.bordeAlt : temaApp.bordePanel
                                            border.width: 1
                                        }

                                        contentItem: Text {
                                            leftPadding: 4
                                            rightPadding: 14
                                            text: comboOpc2.displayText
                                            color: comboOpc2.enabled ? temaApp.textoPrincipal : temaApp.textoMuted
                                            font.pixelSize: 10
                                            font.bold: comboOpc2.currentIndex > 0
                                            verticalAlignment: Text.AlignVCenter
                                            elide: Text.ElideRight
                                        }
                                    }
                                }

                                Rectangle {
                                    height: 1; width: parent.width
                                    anchors.bottom: parent.bottom
                                    color: temaApp.bordePanel
                                }
                            }
                        }

                        // Fila inferior con el botón "IR AL SIGUIENTE PASO" (igual a la tabla de DAE)
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            color: temaApp.esClaro ? "#f1f5f9" : temaApp.panelAlt

                            Rectangle {
                                id: btnSiguientePaso
                                width: 210
                                height: 34
                                radius: 8
                                anchors.centerIn: parent
                                color: temaApp.primario
                                border.color: temaApp.acento
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "IR AL SIGUIENTE PASO"
                                    color: "#ffffff"
                                    font.pixelSize: 12
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: btnSiguientePaso.scale = 0.96
                                    onReleased: btnSiguientePaso.scale = 1.0
                                    onClicked: rootInscripcion.validarYAvanzarPaso1()
                                }
                                Behavior on scale { NumberAnimation { duration: 100 } }
                            }
                        }
                    }
                }

                // Aviso en vivo si hay coincidencias o choques que exceden el límite permitido por DAE
                Rectangle {
                    visible: rootInscripcion.horasCoincidenciaOpc1 > 0 || rootInscripcion.horasCoincidenciaOpc2 > 0
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    implicitHeight: colAvisoChoque.implicitHeight + 18
                    radius: 12
                    readonly property bool hayErrorChoque: rootInscripcion.choqueInvalidoOpc1 || rootInscripcion.choqueInvalidoOpc2
                    color: hayErrorChoque ? "#28ef4444" : "#25f59e0b"
                    border.color: hayErrorChoque ? "#ef4444" : "#f59e0b"
                    border.width: 1

                    ColumnLayout {
                        id: colAvisoChoque
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 3

                        Text {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: parent.parent.hayErrorChoque
                                  ? "⚠ Límite de coincidencias superado (No permitido por el sistema DAE)"
                                  : "ℹ Coincidencia de horario permitida detectada (1 bloque por par, máx. 2 pares)"
                            color: parent.parent.hayErrorChoque ? "#fca5a5" : "#fde68a"
                            font.pixelSize: 11
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: {
                                if (rootInscripcion.choqueInvalidoOpc1) return "Opción 1: " + rootInscripcion.detalleChoqueOpc1
                                if (rootInscripcion.choqueInvalidoOpc2) return "Opción 2: " + rootInscripcion.detalleChoqueOpc2
                                return "Coincidencias actuales • Opción 1: " + rootInscripcion.horasCoincidenciaOpc1 + " h | Opción 2: " + rootInscripcion.horasCoincidenciaOpc2 + " h"
                            }
                            color: temaApp.textoPrincipal
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                // MALLAS DE HORARIO EN VIVO (HORARIO DE OPCION 1 y HORARIO DE OPCION 2)
                GridLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    columns: rootInscripcion.width >= 680 ? 2 : 1
                    columnSpacing: 12
                    rowSpacing: 14

                    TablaMallaOpcion {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        tituloMalla: "HORARIO DE OPCION 1"
                        datosMalla: rootInscripcion.mallaOpcion1
                        horasCoincidencia: rootInscripcion.horasCoincidenciaOpc1
                        choqueInvalido: rootInscripcion.choqueInvalidoOpc1
                    }

                    TablaMallaOpcion {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        tituloMalla: "HORARIO DE OPCION 2"
                        datosMalla: rootInscripcion.mallaOpcion2
                        horasCoincidencia: rootInscripcion.horasCoincidenciaOpc2
                        choqueInvalido: rootInscripcion.choqueInvalidoOpc2
                    }
                }
            }

            // ====================================================================
            // PASO 2: PANTALLA DE CONFIRMACIÓN ANTES DE REGISTRAR LA SOLICITUD
            // ====================================================================
            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.maximumWidth: flickInscripcion.width - 24
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                spacing: 14
                visible: rootInscripcion.pasoActual === 1

                Rectangle {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    implicitHeight: colPaso2.implicitHeight + 28
                    radius: 16
                    color: temaApp.panel
                    border.color: temaApp.bordePanel
                    border.width: 1
                    clip: true

                    ColumnLayout {
                        id: colPaso2
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        spacing: 12

                        Text {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: "¿Esta es la solicitud que desea registrar?"
                            color: temaApp.textoPrincipal
                            font.pixelSize: 17
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: "ATENCION: Cualquier solicitud de inscripción anterior, sera sobreescrita"
                            color: "#dc2626"
                            font.pixelSize: 11
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }

                        // Tabla resumen de confirmación: CÓDIGO | MATERIA | OPCION1 | OPCION2
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            implicitHeight: colTablaConfirm.implicitHeight + 2
                            radius: 10
                            color: temaApp.esClaro ? "#ffffff" : temaApp.panelAlt
                            border.color: temaApp.bordeAlt
                            border.width: 1
                            clip: true

                            ColumnLayout {
                                id: colTablaConfirm
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 1
                                spacing: 0

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 34
                                    color: temaApp.esClaro ? "#dbeafe" : temaApp.oscuro

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 6
                                        anchors.rightMargin: 6
                                        spacing: 4

                                        Text {
                                            Layout.preferredWidth: 58
                                            Layout.minimumWidth: 58
                                            Layout.maximumWidth: 58
                                            text: "CÓDIGO"
                                            color: temaApp.textoPrincipal
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            Layout.minimumWidth: 0
                                            Layout.preferredWidth: 0
                                            text: "MATERIA"
                                            color: temaApp.textoPrincipal
                                            font.pixelSize: 11
                                            font.bold: true
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                        Text {
                                            Layout.preferredWidth: 50
                                            Layout.minimumWidth: 50
                                            Layout.maximumWidth: 50
                                            text: "OPCION1"
                                            color: temaApp.textoPrincipal
                                            font.pixelSize: 10
                                            font.bold: true
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                        Text {
                                            Layout.preferredWidth: 50
                                            Layout.minimumWidth: 50
                                            Layout.maximumWidth: 50
                                            text: "OPCION2"
                                            color: temaApp.textoPrincipal
                                            font.pixelSize: 10
                                            font.bold: true
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                    }
                                }

                                Repeater {
                                    model: rootInscripcion.listaSeleccionadasConfirmar
                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 38
                                        color: index % 2 === 0
                                               ? "transparent"
                                               : (temaApp.esClaro ? "#f8fafc" : "#12ffffff")

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 6
                                            anchors.rightMargin: 6
                                            spacing: 4

                                            Text {
                                                Layout.preferredWidth: 58
                                                Layout.minimumWidth: 58
                                                Layout.maximumWidth: 58
                                                text: modelData.codigo
                                                color: temaApp.textoPrincipal
                                                font.pixelSize: 11
                                                font.bold: true
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                Layout.minimumWidth: 0
                                                Layout.preferredWidth: 0
                                                text: modelData.nombre
                                                color: temaApp.textoPrincipal
                                                font.pixelSize: 11
                                                maximumLineCount: 2
                                                wrapMode: Text.Wrap
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                Layout.preferredWidth: 50
                                                Layout.minimumWidth: 50
                                                Layout.maximumWidth: 50
                                                text: modelData.opcion1
                                                color: temaApp.textoPrincipal
                                                font.pixelSize: 11
                                                font.bold: true
                                                horizontalAlignment: Text.AlignHCenter
                                            }
                                            Text {
                                                Layout.preferredWidth: 50
                                                Layout.minimumWidth: 50
                                                Layout.maximumWidth: 50
                                                text: modelData.opcion2
                                                color: temaApp.textoPrincipal
                                                font.pixelSize: 11
                                                font.bold: true
                                                horizontalAlignment: Text.AlignHCenter
                                            }
                                        }

                                        Rectangle {
                                            height: 1; width: parent.width
                                            anchors.bottom: parent.bottom
                                            color: temaApp.bordePanel
                                        }
                                    }
                                }
                            }
                        }

                        // Botones de acción: REGISTRAR ESTA SOLICITUD y Volver a editar
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 6
                            spacing: 10

                            Rectangle {
                                id: btnRegistrarSol
                                Layout.alignment: Qt.AlignHCenter
                                width: Math.min(colPaso2.width, 250)
                                height: 40
                                radius: 8
                                color: "#0018cc"
                                border.color: "#60a5fa"
                                border.width: 1
                                opacity: daeClient.enviandoInscripcion ? 0.6 : 1.0

                                Text {
                                    anchors.centerIn: parent
                                    text: daeClient.enviandoInscripcion ? "REGISTRANDO SOLICITUD..." : "REGISTRAR ESTA SOLICITUD"
                                    color: "#ffffff"
                                    font.pixelSize: 13
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !daeClient.enviandoInscripcion
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: btnRegistrarSol.scale = 0.96
                                    onReleased: btnRegistrarSol.scale = 1.0
                                    onClicked: daeClient.registrarSolicitudInscripcion(rootInscripcion.listaSeleccionadasConfirmar)
                                }
                                Behavior on scale { NumberAnimation { duration: 100 } }
                            }

                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 190
                                height: 32
                                radius: 8
                                color: "transparent"
                                border.color: temaApp.bordePanel
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "← Modificar selección"
                                    color: temaApp.textoSecundario
                                    font.pixelSize: 11
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: rootInscripcion.pasoActual = 0
                                }
                            }
                        }
                    }
                }
            }

            // ====================================================================
            // PASO 3: REPORTE DE SOLICITUD DE INSCRIPCIÓN (Comprobante Oficial)
            // ====================================================================
            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.maximumWidth: flickInscripcion.width - 24
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                spacing: 14
                visible: rootInscripcion.pasoActual === 2

                // Estado vacío cuando no hay reporte existente o se cerró la ruta de reporte tras asignar horarios
                Rectangle {
                    visible: !daeClient.reporteInscripcionDisponible || daeClient.solicitudInscripcionRegistrada.length === 0
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    implicitHeight: colSinReporte.implicitHeight + 36
                    radius: 16
                    color: temaApp.panel
                    border.color: temaApp.bordePanel
                    border.width: 1

                    ColumnLayout {
                        id: colSinReporte
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 10

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 48; height: 48; radius: 24
                            color: temaApp.panelAlt
                            border.color: temaApp.bordeAlt
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "📋"
                                font.pixelSize: 20
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: "No Hay Reporte de Inscripción Existente"
                            color: temaApp.textoPrincipal
                            font.pixelSize: 16
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: !daeClient.reporteInscripcionDisponible
                                  ? "La consulta del reporte de solicitud de inscripción no se encuentra disponible (la ruta de reporte fue cerrada o ya fueron asignados los horarios definitivos)."
                                  : (daeClient.cargandoInscripcion
                                     ? "Consultando reporte de solicitud de inscripción en el servidor DAE..."
                                     : "No existe ningún reporte de solicitud de inscripción registrado para el período actual.")
                            color: temaApp.textoSecundario
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }

                        Rectangle {
                            visible: daeClient.inscripcionDisponible
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 6
                            width: 220
                            height: 36
                            radius: 10
                            color: temaApp.primario

                            Text {
                                anchors.centerIn: parent
                                text: "Ir a Solicitar Inscripción"
                                color: "#ffffff"
                                font.pixelSize: 12
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    rootInscripcion.usuarioCambioPestanaManualmente = true
                                    rootInscripcion.limpiarSeleccionEnBlanco()
                                    rootInscripcion.pasoActual = 0
                                    flickInscripcion.contentY = 0
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    visible: daeClient.reporteInscripcionDisponible && daeClient.solicitudInscripcionRegistrada.length > 0
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    implicitHeight: colPaso3.implicitHeight + 24
                    radius: 16
                    color: temaApp.panel
                    border.color: temaApp.bordePanel
                    border.width: 1
                    clip: true

                    ColumnLayout {
                        id: colPaso3
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: 12

                        // Franja azul institucional del encabezado del reporte
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            Layout.preferredHeight: 40
                            color: "#3b6ea5"

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                text: "REPORTE DE SOLICITUD DE INSCRIPCIÓN " + daeClient.periodoInscripcion
                                color: "#ffffff"
                                font.pixelSize: 12
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            spacing: 6

                            Text {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                text: "FECHA DE SOLICITUD INSCRIPCIÓN: " + (daeClient.fechaSolicitudInscripcion !== "" ? daeClient.fechaSolicitudInscripcion : "Registrada en el sistema")
                                color: temaApp.textoPrincipal
                                font.pixelSize: 11
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                text: "ESTUDIANTE: " + daeClient.cedulaEstudiante + " " + daeClient.nombreEstudiante
                                color: temaApp.textoPrincipal
                                font.pixelSize: 11
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                            }

                            // Tabla oficial ordenada por código: CÓDIGO | MATERIA | OPCION1 | OPCION2
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                Layout.topMargin: 6
                                implicitHeight: colTablaReporte.implicitHeight + 2
                                radius: 10
                                color: temaApp.esClaro ? "#ffffff" : temaApp.panelAlt
                                border.color: "#3b6ea5"
                                border.width: 1
                                clip: true

                                ColumnLayout {
                                    id: colTablaReporte
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 1
                                    spacing: 0

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 34
                                        color: temaApp.esClaro ? "#e0f2fe" : temaApp.oscuro

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 6
                                            anchors.rightMargin: 6
                                            spacing: 4

                                            Text {
                                                Layout.preferredWidth: 58
                                                Layout.minimumWidth: 58
                                                Layout.maximumWidth: 58
                                                text: "CÓDIGO"
                                                color: temaApp.textoPrincipal
                                                font.pixelSize: 11
                                                font.bold: true
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                Layout.minimumWidth: 0
                                                Layout.preferredWidth: 0
                                                text: "MATERIA"
                                                color: temaApp.textoPrincipal
                                                font.pixelSize: 11
                                                font.bold: true
                                                horizontalAlignment: Text.AlignHCenter
                                            }
                                            Text {
                                                Layout.preferredWidth: 50
                                                Layout.minimumWidth: 50
                                                Layout.maximumWidth: 50
                                                text: "OPCION1"
                                                color: temaApp.textoPrincipal
                                                font.pixelSize: 10
                                                font.bold: true
                                                horizontalAlignment: Text.AlignHCenter
                                            }
                                            Text {
                                                Layout.preferredWidth: 50
                                                Layout.minimumWidth: 50
                                                Layout.maximumWidth: 50
                                                text: "OPCION2"
                                                color: temaApp.textoPrincipal
                                                font.pixelSize: 10
                                                font.bold: true
                                                horizontalAlignment: Text.AlignHCenter
                                            }
                                        }
                                    }

                                    Repeater {
                                        model: daeClient.solicitudInscripcionRegistrada
                                        delegate: Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 38
                                            color: index % 2 === 0
                                                   ? (temaApp.esClaro ? "#f0f9ff" : "transparent")
                                                   : (temaApp.esClaro ? "#e0f2fe" : "#12ffffff")

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 6
                                                anchors.rightMargin: 6
                                                spacing: 4

                                                Text {
                                                    Layout.preferredWidth: 58
                                                    Layout.minimumWidth: 58
                                                    Layout.maximumWidth: 58
                                                    text: modelData.codigo
                                                    color: temaApp.textoPrincipal
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    elide: Text.ElideRight
                                                }
                                                Text {
                                                    Layout.fillWidth: true
                                                    Layout.minimumWidth: 0
                                                    Layout.preferredWidth: 0
                                                    text: modelData.nombre
                                                    color: temaApp.textoPrincipal
                                                    font.pixelSize: 11
                                                    maximumLineCount: 2
                                                    wrapMode: Text.Wrap
                                                    elide: Text.ElideRight
                                                }
                                                Text {
                                                    Layout.preferredWidth: 50
                                                    Layout.minimumWidth: 50
                                                    Layout.maximumWidth: 50
                                                    text: modelData.opcion1
                                                    color: temaApp.textoPrincipal
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    horizontalAlignment: Text.AlignHCenter
                                                }
                                                Text {
                                                    Layout.preferredWidth: 50
                                                    Layout.minimumWidth: 50
                                                    Layout.maximumWidth: 50
                                                    text: modelData.opcion2
                                                    color: temaApp.textoPrincipal
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    horizontalAlignment: Text.AlignHCenter
                                                }
                                            }

                                            Rectangle {
                                                height: 1; width: parent.width
                                                anchors.bottom: parent.bottom
                                                color: temaApp.bordePanel
                                            }
                                        }
                                    }
                                }
                            }

                            // Botón para realizar o modificar la solicitud de inscripción (solo si las inscripciones siguen abiertas)
                            Rectangle {
                                visible: daeClient.inscripcionDisponible
                                Layout.alignment: Qt.AlignHCenter
                                Layout.topMargin: 10
                                width: 220
                                height: 36
                                radius: 10
                                color: temaApp.panelAlt
                                border.color: temaApp.primario
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "Modificar Solicitud de Inscripción"
                                    color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                                    font.pixelSize: 12
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        rootInscripcion.usuarioCambioPestanaManualmente = true
                                        rootInscripcion.limpiarSeleccionEnBlanco()
                                        rootInscripcion.pasoActual = 0
                                        flickInscripcion.contentY = 0
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ========================================================================
    // MODAL DE CONFIRMACIÓN DE COINCIDENCIAS (Idéntico al aviso de dae.ing.uc.edu.ve)
    // ========================================================================
    Rectangle {
        anchors.fill: parent
        visible: rootInscripcion.mostrarDialogoConfirmarEnvio
        color: "#88000000"
        z: 90

        MouseArea { anchors.fill: parent }

        Rectangle {
            width: Math.min(parent.width - 40, 340)
            implicitHeight: colModalConf.implicitHeight + 36
            radius: 18
            anchors.centerIn: parent
            color: "#1e1f24"
            border.color: "#3f414a"
            border.width: 1

            ColumnLayout {
                id: colModalConf
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                Text {
                    text: "dae.ing.uc.edu.ve dice"
                    color: "#ffffff"
                    font.pixelSize: 16
                    font.bold: true
                }

                Text {
                    Layout.fillWidth: true
                    text: "Esta seguro que desea enviar esta informacion?\n\nCoincidencias:\n opcion1: " +
                          rootInscripcion.horasCoincidenciaOpc1 + " horas\n opcion2: " +
                          rootInscripcion.horasCoincidenciaOpc2 + " horas"
                    color: "#e2e8f0"
                    font.pixelSize: 13
                    lineHeight: 1.25
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    spacing: 10

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 92; height: 36; radius: 18
                        color: "transparent"
                        border.color: "#525866"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Cancelar"
                            color: "#c7d2fe"
                            font.pixelSize: 13
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: rootInscripcion.mostrarDialogoConfirmarEnvio = false
                        }
                    }

                    Rectangle {
                        width: 92; height: 36; radius: 18
                        color: "#c7d2fe"

                        Text {
                            anchors.centerIn: parent
                            text: "Aceptar"
                            color: "#1e1b4b"
                            font.pixelSize: 13
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                rootInscripcion.mostrarDialogoConfirmarEnvio = false
                                daeClient.prepararPasoConfirmacionInscripcion(rootInscripcion.listaSeleccionadasConfirmar)
                                rootInscripcion.pasoActual = 1
                                flickInscripcion.contentY = 0
                            }
                        }
                    }
                }
            }
        }
    }

    // ========================================================================
    // MODAL DE ALERTA DE VALIDACIÓN (Choques inválidos o falta de Opción 1)
    // ========================================================================
    Rectangle {
        anchors.fill: parent
        visible: rootInscripcion.mostrarDialogoAlerta
        color: "#88000000"
        z: 95

        MouseArea { anchors.fill: parent }

        Rectangle {
            width: Math.min(parent.width - 40, 340)
            implicitHeight: colModalAlerta.implicitHeight + 36
            radius: 18
            anchors.centerIn: parent
            color: "#1e1f24"
            border.color: "#dc2626"
            border.width: 1

            ColumnLayout {
                id: colModalAlerta
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                Text {
                    text: "dae.ing.uc.edu.ve dice"
                    color: "#fca5a5"
                    font.pixelSize: 16
                    font.bold: true
                }

                Text {
                    Layout.fillWidth: true
                    text: rootInscripcion.textoDialogoAlerta
                    color: "#e2e8f0"
                    font.pixelSize: 13
                    lineHeight: 1.25
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 96; height: 36; radius: 18
                        color: "#dc2626"

                        Text {
                            anchors.centerIn: parent
                            text: "Aceptar"
                            color: "#ffffff"
                            font.pixelSize: 13
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: rootInscripcion.mostrarDialogoAlerta = false
                        }
                    }
                }
            }
        }
    }
}
