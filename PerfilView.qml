import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Dialogs

Item {
    id: rootPerfil

    // Propiedad compartida y persistente (QSettings) para que la foto también se vea en el Home de Main.qml
    property string urlFotoPerfil: daeClient.urlFotoPerfil
    onUrlFotoPerfilChanged: {
        if (daeClient.urlFotoPerfil !== urlFotoPerfil) {
            daeClient.urlFotoPerfil = urlFotoPerfil
        }
    }
    property string iniciales: daeClient.inicialesEstudiante
    property bool modoEdicion: false
    property bool menuFotoAbierto: false
    property bool modalApoyoAbierto: false

    function copiarAlPortapapeles(texto, mensajeConfirmacion) {
        portapapelesOculto.text = texto
        portapapelesOculto.selectAll()
        portapapelesOculto.copy()
        bannerGuardado.mostrar(mensajeConfirmacion)
    }

    TextEdit {
        id: portapapelesOculto
        visible: false
    }

    // Datos del estudiante sincronizados con la sesión activa de DAE
    property string primerNombre: daeClient.primerNombre
    property string segundoNombre: daeClient.segundoNombre
    property string primerApellido: daeClient.primerApellido
    property string segundoApellido: daeClient.segundoApellido
    property string cedula: daeClient.cedulaFormateada
    property string escuela: daeClient.escuelaCorta

    property string correoPrincipal: daeClient.correoEstudiante
    property string correoAlternativo: daeClient.correoAlternativo
    property string telFijo: daeClient.telefonoFijo
    property string telMovil: daeClient.telefonoEstudiante

    property string fechaNacimiento: daeClient.fechaNacimiento
    property string sexo: daeClient.sexoEstudiante

    property string dirEstado: daeClient.dirEstado
    property string dirMunicipio: daeClient.dirMunicipio
    property string dirParroquia: daeClient.dirParroquia
    property string dirDetalle: daeClient.dirDetalle

    property string opsuEstadoCivil: daeClient.opsuEstadoCivil
    property string opsuEtnia: daeClient.opsuEtnia
    property string opsuDiscapacidad: daeClient.opsuDiscapacidad
    property string opsuManoAgil: daeClient.opsuManoAgil

    // Opciones oficiales exactas de actualizar_estudiantil.php (OPSU / DAE)
    readonly property var opcionesEstadoCivil: [
        "SOLTERO",
        "CASADO",
        "CONCUBINO",
        "DIVORCIADO",
        "SEPARADO DE CUERPOS",
        "VIUDO"
    ]

    readonly property var opcionesEtnia: [
        "NINGUNA",
        "AKAWAYO",
        "AMORUA",
        "AÑÚ/PARAUJANO",
        "ARAWAKO",
        "AYAMAN",
        "BANIVA",
        "BARÉ",
        "BARÍ",
        "CAMENTZA",
        "CARIBE",
        "CHAIMA",
        "CUBEO",
        "CUMANAGOTO",
        "EÑEPÁ/PANARE",
        "GAYÓN",
        "GUANONO",
        "GUAZABARA",
        "HOTI/HODI",
        "INGA",
        "JAPRERÍA",
        "JIVI/GUAJIBO",
        "KARIÑA",
        "KUIBA",
        "KURRIPACO",
        "MAKO",
        "MAKUSHÍ",
        "MATAKO",
        "ÑENGATÚ/YERAL",
        "OTROS GRUPOS",
        "PANARE",
        "PEMÓN",
        "PIAPOCO",
        "PUINAVE",
        "PUMÉ/YARURO",
        "QUINAROE",
        "RURRIPAKO",
        "SÁLIVA",
        "SANEMÁ",
        "SAPÉ",
        "TIMOTO-CUICAS/TIMOTES",
        "URUAK/ARUTANI",
        "WAIKA",
        "WAIKERÍ",
        "WANAI/MAPOYO",
        "WAPISHANA",
        "WARAO",
        "WAREKENA",
        "WAYUU",
        "WOTJUJA/PIAROA",
        "YABARANA",
        "YANOMAMI",
        "YEKUANA",
        "YUKPA"
    ]

    readonly property var opcionesDiscapacidad: [
        "NINGUNA",
        "FÍSICA",
        "MIXTA O PLURIDEFICIENTE",
        "PSÍQUICA-INTELECTUAL",
        "PSÍQUICA MENTAL",
        "SENSORIAL AUDITIVA",
        "SENSORIAL VISUAL"
    ]

    readonly property var opcionesManoAgil: [
        "DERECHA",
        "IZQUIERDA",
        "AMBAS"
    ]

    // Estado del selector desplegable modal para los campos OPSU
    property bool selectorOpsuAbierto: false
    property string tituloSelectorOpsu: ""
    property string campoSelectorOpsu: "" // "edoc", "etnia", "disca", "mag"
    property var listaOpcionesActiva: []

    function abrirSelectorOpsu(campo, titulo, opciones) {
        if (!rootPerfil.modoEdicion) {
            rootPerfil.modoEdicion = true
        }
        rootPerfil.campoSelectorOpsu = campo
        rootPerfil.tituloSelectorOpsu = titulo
        rootPerfil.listaOpcionesActiva = opciones
        rootPerfil.selectorOpsuAbierto = true
    }

    function obtenerValorActualSelector() {
        if (rootPerfil.campoSelectorOpsu === "edo") return rootPerfil.dirEstado
        if (rootPerfil.campoSelectorOpsu === "mun") return rootPerfil.dirMunicipio
        if (rootPerfil.campoSelectorOpsu === "paq") return rootPerfil.dirParroquia
        if (rootPerfil.campoSelectorOpsu === "edoc") return rootPerfil.opsuEstadoCivil
        if (rootPerfil.campoSelectorOpsu === "etnia") return rootPerfil.opsuEtnia
        if (rootPerfil.campoSelectorOpsu === "disca") return rootPerfil.opsuDiscapacidad
        if (rootPerfil.campoSelectorOpsu === "mag") return rootPerfil.opsuManoAgil
        return ""
    }

    function aplicarOpcionSelector(valorElegido) {
        if (rootPerfil.campoSelectorOpsu === "edo") {
            rootPerfil.dirEstado = valorElegido
            var muns = daeClient.obtenerMunicipiosPorEstado(valorElegido)
            if (muns.length > 0 && muns.indexOf(rootPerfil.dirMunicipio) === -1) {
                rootPerfil.dirMunicipio = muns[0]
            }
            var parroqs = daeClient.obtenerParroquiasPorMunicipio(rootPerfil.dirEstado, rootPerfil.dirMunicipio)
            if (parroqs.length > 0 && parroqs.indexOf(rootPerfil.dirParroquia) === -1) {
                rootPerfil.dirParroquia = parroqs[0]
            }
        } else if (rootPerfil.campoSelectorOpsu === "mun") {
            rootPerfil.dirMunicipio = valorElegido
            var parroqsMun = daeClient.obtenerParroquiasPorMunicipio(rootPerfil.dirEstado, valorElegido)
            if (parroqsMun.length > 0 && parroqsMun.indexOf(rootPerfil.dirParroquia) === -1) {
                rootPerfil.dirParroquia = parroqsMun[0]
            }
        } else if (rootPerfil.campoSelectorOpsu === "paq") {
            rootPerfil.dirParroquia = valorElegido
        } else if (rootPerfil.campoSelectorOpsu === "edoc") {
            rootPerfil.opsuEstadoCivil = valorElegido
        } else if (rootPerfil.campoSelectorOpsu === "etnia") {
            rootPerfil.opsuEtnia = valorElegido
        } else if (rootPerfil.campoSelectorOpsu === "disca") {
            rootPerfil.opsuDiscapacidad = valorElegido
        } else if (rootPerfil.campoSelectorOpsu === "mag") {
            rootPerfil.opsuManoAgil = valorElegido
        }
        rootPerfil.selectorOpsuAbierto = false
    }

    function cancelarEdicion() {
        rootPerfil.correoPrincipal = daeClient.correoEstudiante
        rootPerfil.correoAlternativo = daeClient.correoAlternativo
        rootPerfil.telFijo = daeClient.telefonoFijo
        rootPerfil.telMovil = daeClient.telefonoEstudiante
        rootPerfil.dirEstado = daeClient.dirEstado
        rootPerfil.dirMunicipio = daeClient.dirMunicipio
        rootPerfil.dirParroquia = daeClient.dirParroquia
        rootPerfil.dirDetalle = daeClient.dirDetalle
        rootPerfil.opsuEstadoCivil = daeClient.opsuEstadoCivil
        rootPerfil.opsuEtnia = daeClient.opsuEtnia
        rootPerfil.opsuDiscapacidad = daeClient.opsuDiscapacidad
        rootPerfil.opsuManoAgil = daeClient.opsuManoAgil
        rootPerfil.modoEdicion = false
        bannerGuardado.mostrar("• Edición cancelada • Se restauraron los datos originales")
    }

    function guardarCambiosEnServidor() {
        rootPerfil.modoEdicion = false
        bannerGuardado.mostrar("⏳ Guardando cambios en el servidor DAE...")
        daeClient.guardarDatosPersonales(
            rootPerfil.correoPrincipal,
            rootPerfil.correoAlternativo,
            rootPerfil.telFijo,
            rootPerfil.telMovil,
            rootPerfil.dirEstado,
            rootPerfil.dirMunicipio,
            rootPerfil.dirParroquia,
            rootPerfil.dirDetalle,
            rootPerfil.opsuEstadoCivil,
            rootPerfil.opsuEtnia,
            rootPerfil.opsuDiscapacidad,
            rootPerfil.opsuManoAgil
        )
    }

    Connections {
        target: daeClient
        function onDatosPersonalesGuardados(exito, mensaje) {
            bannerGuardado.mostrar(mensaje)
        }
        function onBiometriaNotificacion(exito, mensaje) {
            bannerGuardado.mostrar(mensaje)
        }
        function onSincronizacionCompletada() {
            bannerGuardado.mostrar("✓ Datos sincronizados con el servidor DAE UC")
        }
        function onSincronizacionFallida(mensaje) {
            bannerGuardado.mostrar(mensaje)
        }
    }

    // Propiedades compartidas de Apariencia y Configuración (Sincronizadas con ventanaPrincipal)
    property int temaSeleccionado: ventanaPrincipal.temaSeleccionado    // 0 = Oscuro, 1 = Claro DAE, 2 = OLED
    property int paletaAuroraIndex: ventanaPrincipal.paletaAuroraIndex   // 0 = Azul Vaulta, 1 = Esmeralda, 2 = Púrpura, 3 = Carmesí, 4 = Dorado
    property bool animacionAuroraActiva: ventanaPrincipal.animacionAuroraActiva

    property var paletasAurora: ventanaPrincipal.paletasBase

    // Selector nativo del sistema operativo para elegir una imagen
    FileDialog {
        id: selectorImagen
        title: "Seleccionar Foto de Perfil"
        nameFilters: ["Imágenes (*.png *.jpg *.jpeg *.webp)"]
        onAccepted: {
            // En lugar de aplicar la foto directamente, se abre el editor para encuadrarla
            rootPerfil.menuFotoAbierto = false
            rootPerfil.abrirEditorFoto(selectedFile.toString())
        }
    }

    // ===== Editor para encuadrar (mover y hacer zoom) la foto antes de guardarla =====
    property bool editorFotoAbierto: false
    property string urlFotoPendiente: ""
    property real zoomFoto: 1.0
    readonly property real zoomFotoMax: 5.0

    function abrirEditorFoto(url) {
        urlFotoPendiente = ""
        urlFotoPendiente = url
        zoomFoto = 1.0
        editorFotoAbierto = true
    }

    function cerrarEditorFoto() {
        editorFotoAbierto = false
        urlFotoPendiente = ""
    }

    // Componente reutilizable para cada campo de datos (Con ancho bloqueado para que NO se expanda al editar)
    component CampoPerfil: ColumnLayout {
        id: rootCampo
        property string etiqueta: ""
        property string valor: ""
        property bool editable: true
        property bool obligatorio: false
        signal valorCambiado(string nuevoTexto)

        Layout.fillWidth: true
        Layout.preferredWidth: 0 // CLAVE 1: Obliga a GridLayout y ColumnLayout a dividir el espacio exacto sin dejarse empujar
        Layout.maximumWidth: parent.width
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 3

            Text {
                text: rootCampo.etiqueta
                color: temaApp.textoSecundario
                font.pixelSize: 11
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true // Absorbe el espacio para que el asterisco o candado nunca empujen la columna
            }
            Text {
                visible: rootCampo.obligatorio
                text: "*"
                color: "#b91c1c"
                font.pixelSize: 12
                font.bold: true
            }
            Text {
                // CLAVE 2: Usamos opacity en vez de visible para que no altere el ancho del layout al pulsar Actualizar
                opacity: (!rootCampo.editable && rootPerfil.modoEdicion) ? 1.0 : 0.0
                text: "🔒"
                font.pixelSize: 9
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: 12
            clip: true // CLAVE 3: Garantiza que el contenido jamás desborde la caja
            color: (rootPerfil.modoEdicion && rootCampo.editable) ? temaApp.panelEdit : temaApp.panelAlt
            border.color: (rootPerfil.modoEdicion && rootCampo.editable)
                          ? (inputCampo.activeFocus ? temaApp.acento : temaApp.primario)
                          : temaApp.bordeAlt
            border.width: 1

            Behavior on color { ColorAnimation { duration: 180 } }

            TextInput {
                id: inputCampo
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                verticalAlignment: TextInput.AlignVCenter
                text: rootCampo.valor
                readOnly: !(rootPerfil.modoEdicion && rootCampo.editable)
                color: (rootPerfil.modoEdicion && !rootCampo.editable) ? temaApp.textoMuted : temaApp.textoPrincipal
                font.pixelSize: 13
                font.bold: true // Mantenemos el mismo grosor en ambos modos para que las letras no cambien de ancho
                selectByMouse: true
                clip: true
                onTextEdited: rootCampo.valorCambiado(text)
            }
        }
    }

    // Componente desplegable para campos de selección (OPSU)
    component CampoSelectPerfil: ColumnLayout {
        id: rootSelectCampo
        property string etiqueta: ""
        property string valor: ""
        property bool obligatorio: true
        signal abrirSelector()

        Layout.fillWidth: true
        Layout.preferredWidth: 0
        Layout.maximumWidth: parent.width
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 3

            Text {
                text: rootSelectCampo.etiqueta
                color: temaApp.textoSecundario
                font.pixelSize: 11
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Text {
                visible: rootSelectCampo.obligatorio
                text: "*"
                color: "#b91c1c"
                font.pixelSize: 12
                font.bold: true
            }
        }

        Rectangle {
            id: cajaSelect
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: 12
            clip: true
            color: rootPerfil.modoEdicion ? temaApp.panelEdit : temaApp.panelAlt
            border.color: rootPerfil.modoEdicion ? temaApp.primario : temaApp.bordeAlt
            border.width: 1

            Behavior on color { ColorAnimation { duration: 180 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 10
                spacing: 6

                Text {
                    text: rootSelectCampo.valor
                    color: temaApp.textoPrincipal
                    font.pixelSize: 12
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    radius: 6
                    color: rootPerfil.modoEdicion
                           ? Qt.rgba(temaApp.acento.r, temaApp.acento.g, temaApp.acento.b, 0.22)
                           : (temaApp.esClaro ? "#e2e8f0" : "#18ffffff")

                    Text {
                        anchors.centerIn: parent
                        text: "▼"
                        color: rootPerfil.modoEdicion ? temaApp.acento : temaApp.textoSecundario
                        font.pixelSize: 9
                        font.bold: true
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onPressed: cajaSelect.scale = 0.98
                onReleased: cajaSelect.scale = 1.0
                onClicked: rootSelectCampo.abrirSelector()
            }
            Behavior on scale { NumberAnimation { duration: 90 } }
        }
    }

    Flickable {
        id: flickPerfil
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
                id: timerTecladoPerfil
                interval: 280
                onTriggered: {
                    flickPerfil.restaurarPosicion();
                }
            }
        }

        // Cuando el teclado se cierra, Qt deja el contenido corrido:
        // se devuelve a la posición en la que estaba el usuario.
        Connections {
            target: daeClient
            function onTecladoVisibleChanged() {
                if (!daeClient.tecladoVisible) {
                    flickPerfil.restaurarPosicion();
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
        contentHeight: colPerfil.implicitHeight + 135
        clip: true

        ColumnLayout {
            id: colPerfil
            width: parent.width
            spacing: 16

            // 1. CABECERA PRINCIPAL + BOTÓN DE EDITAR / GUARDAR
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 24
                Layout.leftMargin: 22
                Layout.rightMargin: 22

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: "Mi Perfil DAE"
                        color: temaApp.textoPrincipal
                        font.pixelSize: 22
                        font.bold: true
                    }
                    Text {
                        text: rootPerfil.modoEdicion
                              ? "Modo edición activo • Los campos con * son obligatorios"
                              : "Ficha Personal y Datos OPSU • Ing UC"
                        color: rootPerfil.modoEdicion ? (temaApp.esClaro ? "#d97706" : "#fbbf24") : temaApp.textoSubtitulo
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Item { Layout.fillWidth: true }

                // Botón superior para cancelar la edición sin guardar
                Rectangle {
                    visible: rootPerfil.modoEdicion
                    Layout.preferredWidth: lblCancelarTop.implicitWidth + 20
                    Layout.preferredHeight: 36
                    radius: 18
                    color: temaApp.esClaro ? "#fee2e2" : "#3b151e"
                    border.color: "#ef4444"
                    border.width: 1

                    Text {
                        id: lblCancelarTop
                        anchors.centerIn: parent
                        text: "Cancelar"
                        color: temaApp.esClaro ? "#dc2626" : "#fca5a5"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rootPerfil.cancelarEdicion()
                    }
                }

                // Botón superior para activar edición o guardar cambios
                Rectangle {
                    id: btnToggleEdicion
                    Layout.preferredWidth: rowBtnEdit.implicitWidth + 24
                    Layout.preferredHeight: 36
                    radius: 18
                    color: rootPerfil.modoEdicion ? "#22c55e" : (temaApp.esClaro ? temaApp.primario : "#25ffffff")
                    border.color: rootPerfil.modoEdicion ? "#86efac" : (temaApp.esClaro ? temaApp.acento : "#55ffffff")
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 200 } }

                    RowLayout {
                        id: rowBtnEdit
                        anchors.centerIn: parent
                        spacing: 6

                        Canvas {
                            id: iconoBtnEditar
                            width: 14; height: 14
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.strokeStyle = "#ffffff";
                                ctx.lineWidth = 1.8;
                                ctx.lineCap = "round";
                                ctx.lineJoin = "round";
                                if (rootPerfil.modoEdicion) {
                                    // Check de Guardar
                                    ctx.beginPath();
                                    ctx.moveTo(2, 7.5); ctx.lineTo(5.5, 11); ctx.lineTo(12, 3.5);
                                    ctx.stroke();
                                } else {
                                    // Lápiz minimalista de Editar
                                    ctx.beginPath();
                                    ctx.moveTo(9.5, 2.5); ctx.lineTo(11.5, 4.5);
                                    ctx.lineTo(4.5, 11.5); ctx.lineTo(2, 12); ctx.lineTo(2.5, 9.5);
                                    ctx.closePath();
                                    ctx.stroke();
                                }
                            }
                            Connections {
                                target: rootPerfil
                                function onModoEdicionChanged() { iconoBtnEditar.requestPaint() }
                            }
                        }

                        Text {
                            text: rootPerfil.modoEdicion ? "Guardar" : "Actualizar"
                            color: "white"
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (rootPerfil.modoEdicion) {
                                rootPerfil.guardarCambiosEnServidor()
                            } else {
                                rootPerfil.modoEdicion = true
                            }
                        }
                    }
                }
            }

            // 2. TARJETA DE IDENTIDAD CON CÍRCULO DE AVATAR + NOMBRES + ESCUELA
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: 112
                radius: 26
                color: temaApp.vidrio
                border.color: temaApp.bordeVidrio
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 16

                    // CÍRCULO DEL AVATAR CON BOTÓN FLOTANTE DE CÁMARA
                    Item {
                        Layout.preferredWidth: 76
                        Layout.preferredHeight: 76

                        Rectangle {
                            id: circuloIniciales
                            anchors.fill: parent
                            radius: 38
                            border.color: temaApp.bordeAlt
                            border.width: 2

                            gradient: Gradient {
                                GradientStop { position: 0.0; color: temaApp.acento }
                                GradientStop { position: 1.0; color: temaApp.oscuro }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: rootPerfil.iniciales
                                color: "white"
                                font.pixelSize: 26
                                font.bold: true
                                font.letterSpacing: 1.0
                                visible: rootPerfil.urlFotoPerfil === ""
                            }
                        }

                        Image {
                            id: imgUsuario
                            anchors.fill: parent
                            source: rootPerfil.urlFotoPerfil
                            fillMode: Image.PreserveAspectCrop
                            visible: false
                        }

                        Item {
                            id: mascaraCircularFoto
                            anchors.fill: parent
                            layer.enabled: true
                            visible: false
                            Rectangle {
                                anchors.fill: parent
                                radius: 38
                                color: "black"
                            }
                        }

                        MultiEffect {
                            anchors.fill: parent
                            source: imgUsuario
                            visible: rootPerfil.urlFotoPerfil !== ""
                            maskEnabled: true
                            maskSource: mascaraCircularFoto
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 38
                            color: "transparent"
                            border.color: temaApp.esClaro ? temaApp.primario : "#90ffffff"
                            border.width: 2
                            visible: rootPerfil.urlFotoPerfil !== ""
                        }

                        // Icono de cámara para indicar que al tocar el círculo se edita la foto
                        Rectangle {
                            width: 28; height: 28; radius: 14
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            color: temaApp.secundario
                            border.color: "white"
                            border.width: 1.5

                            Canvas {
                                width: 14; height: 14
                                anchors.centerIn: parent
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.reset();
                                    ctx.strokeStyle = "#ffffff";
                                    ctx.lineWidth = 1.5;
                                    ctx.lineCap = "round";
                                    ctx.lineJoin = "round";
                                    ctx.strokeRect(1.5, 4, 11, 8);
                                    ctx.beginPath();
                                    ctx.moveTo(4.5, 4); ctx.lineTo(5.5, 2); ctx.lineTo(8.5, 2); ctx.lineTo(9.5, 4);
                                    ctx.stroke();
                                    ctx.beginPath();
                                    ctx.arc(7, 8, 2, 0, Math.PI * 2);
                                    ctx.stroke();
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onPressed: parent.scale = 0.94
                            onReleased: parent.scale = 1.0
                            onClicked: rootPerfil.menuFotoAbierto = true
                        }
                        Behavior on scale { NumberAnimation { duration: 100 } }
                    }

                    // NOMBRES Y APELLIDOS + CÉDULA Y ESCUELA DEBAJO
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: rootPerfil.primerNombre + " " + rootPerfil.segundoNombre
                            color: temaApp.textoPrincipal
                            font.pixelSize: 16
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: rootPerfil.primerApellido + " " + rootPerfil.segundoApellido
                            color: temaApp.textoPrincipal
                            font.pixelSize: 16
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            spacing: 6
                            Layout.topMargin: 3
                            Layout.fillWidth: true

                            // Píldora de Cédula
                            Rectangle {
                                Layout.preferredWidth: lblCed.implicitWidth + 12
                                Layout.preferredHeight: 22
                                radius: 11
                                color: temaApp.esClaro ? "#e2e8f0" : "#28ffffff"
                                Text {
                                    id: lblCed
                                    anchors.centerIn: parent
                                    text: "V-" + rootPerfil.cedula
                                    color: temaApp.textoPrincipal
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }

                            // Píldora dinámica con la Escuela del Estudiante
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredWidth: Math.min(lblEscuela.implicitWidth + 16, 165)
                                Layout.preferredHeight: 22
                                radius: 11
                                color: temaApp.superficie
                                border.color: temaApp.acento
                                border.width: 1

                                Text {
                                    id: lblEscuela
                                    width: parent.width - 12
                                    anchors.centerIn: parent
                                    text: rootPerfil.escuela
                                    color: "white"
                                    font.pixelSize: 10
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }

            // 3. SECCIÓN 1: DATOS DE IDENTIDAD PERSONAL
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: colIdentidad.implicitHeight + 32
                radius: 24
                color: temaApp.panel
                border.color: temaApp.bordePanel
                border.width: 1

                ColumnLayout {
                    id: colIdentidad
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Rectangle { Layout.preferredWidth: 8; Layout.preferredHeight: 18; radius: 4; color: temaApp.primario }
                        Text { text: "Datos Personales"; color: temaApp.textoPrincipal; font.pixelSize: 15; font.bold: true }
                        Item { Layout.fillWidth: true }
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: temaApp.bordePanel }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 10
                        columnSpacing: 10

                        CampoPerfil {
                            etiqueta: "Primer Nombre"
                            valor: rootPerfil.primerNombre
                            editable: false
                        }
                        CampoPerfil {
                            etiqueta: "Segundo Nombre"
                            valor: rootPerfil.segundoNombre
                            editable: false
                        }
                        CampoPerfil {
                            etiqueta: "Primer Apellido"
                            valor: rootPerfil.primerApellido
                            editable: false
                        }
                        CampoPerfil {
                            etiqueta: "Segundo Apellido"
                            valor: rootPerfil.segundoApellido
                            editable: false
                        }
                        CampoPerfil {
                            etiqueta: "Fecha de Nacimiento"
                            valor: rootPerfil.fechaNacimiento
                            editable: false
                        }
                        CampoPerfil {
                            etiqueta: "Sexo"
                            valor: rootPerfil.sexo
                            editable: false
                        }
                    }
                }
            }

            // 4. SECCIÓN 2: CORREOS Y TELÉFONOS DE CONTACTO
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: colContacto.implicitHeight + 32
                radius: 24
                color: temaApp.panel
                border.color: rootPerfil.modoEdicion ? temaApp.acento : temaApp.bordePanel
                border.width: 1

                ColumnLayout {
                    id: colContacto
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Rectangle { Layout.preferredWidth: 8; Layout.preferredHeight: 18; radius: 4; color: temaApp.secundario }
                        Text { text: "Correos y Teléfonos"; color: temaApp.textoPrincipal; font.pixelSize: 15; font.bold: true }
                        Item { Layout.fillWidth: true }
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: temaApp.bordePanel }

                    CampoPerfil {
                        etiqueta: "Correo Principal"
                        valor: rootPerfil.correoPrincipal
                        obligatorio: true
                        onValorCambiado: (t) => rootPerfil.correoPrincipal = t
                    }

                    CampoPerfil {
                        etiqueta: "Correo Alternativo"
                        valor: rootPerfil.correoAlternativo
                        onValorCambiado: (t) => rootPerfil.correoAlternativo = t
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 10
                        rowSpacing: 10

                        CampoPerfil {
                            etiqueta: "Teléfono Fijo"
                            valor: rootPerfil.telFijo
                            onValorCambiado: (t) => rootPerfil.telFijo = t
                        }

                        CampoPerfil {
                            etiqueta: "Teléfono Móvil"
                            valor: rootPerfil.telMovil
                            obligatorio: true
                            onValorCambiado: (t) => rootPerfil.telMovil = t
                        }
                    }
                }
            }

            // 5. SECCIÓN 3: DIRECCIÓN DE HABITACIÓN
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: colDireccion.implicitHeight + 32
                radius: 24
                color: temaApp.panel
                border.color: rootPerfil.modoEdicion ? temaApp.acento : temaApp.bordePanel
                border.width: 1

                ColumnLayout {
                    id: colDireccion
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Rectangle { Layout.preferredWidth: 8; Layout.preferredHeight: 18; radius: 4; color: temaApp.acento }
                        Text { text: "Dirección de Habitación"; color: temaApp.textoPrincipal; font.pixelSize: 15; font.bold: true }
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: temaApp.bordePanel }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 10
                        rowSpacing: 10

                        CampoSelectPerfil {
                            etiqueta: "Estado"
                            valor: rootPerfil.dirEstado
                            obligatorio: true
                            onAbrirSelector: rootPerfil.abrirSelectorOpsu(
                                "edo",
                                "Estado de Habitación",
                                daeClient.obtenerEstados()
                            )
                        }

                        CampoSelectPerfil {
                            etiqueta: "Municipio"
                            valor: rootPerfil.dirMunicipio
                            obligatorio: true
                            onAbrirSelector: rootPerfil.abrirSelectorOpsu(
                                "mun",
                                "Municipio (" + rootPerfil.dirEstado + ")",
                                daeClient.obtenerMunicipiosPorEstado(rootPerfil.dirEstado)
                            )
                        }
                    }

                    CampoSelectPerfil {
                        etiqueta: "Parroquia"
                        valor: rootPerfil.dirParroquia
                        obligatorio: true
                        onAbrirSelector: rootPerfil.abrirSelectorOpsu(
                            "paq",
                            "Parroquia (" + rootPerfil.dirMunicipio + ")",
                            daeClient.obtenerParroquiasPorMunicipio(rootPerfil.dirEstado, rootPerfil.dirMunicipio)
                        )
                    }

                    CampoPerfil {
                        etiqueta: "Dirección (Av, Calle, Urb, Edif, etc)"
                        valor: rootPerfil.dirDetalle
                        obligatorio: true
                        onValorCambiado: (t) => rootPerfil.dirDetalle = t
                    }
                }
            }

            // 6. SECCIÓN 4: OTROS DATOS (REQUERIDOS POR OPSU)
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: colOpsu.implicitHeight + 32
                radius: 24
                color: temaApp.panel
                border.color: rootPerfil.modoEdicion ? temaApp.acento : temaApp.bordePanel
                border.width: 1

                ColumnLayout {
                    id: colOpsu
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Rectangle { Layout.preferredWidth: 8; Layout.preferredHeight: 18; radius: 4; color: temaApp.acentoVisible }
                        Text { text: "Otros Datos (Requeridos por OPSU)"; color: temaApp.textoPrincipal; font.pixelSize: 15; font.bold: true }
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: temaApp.bordePanel }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 10
                        rowSpacing: 10

                        CampoSelectPerfil {
                            etiqueta: "Estado Civil"
                            valor: rootPerfil.opsuEstadoCivil
                            obligatorio: true
                            onAbrirSelector: rootPerfil.abrirSelectorOpsu("edoc", "Estado Civil", rootPerfil.opcionesEstadoCivil)
                        }

                        CampoSelectPerfil {
                            etiqueta: "Etnia"
                            valor: rootPerfil.opsuEtnia
                            obligatorio: true
                            onAbrirSelector: rootPerfil.abrirSelectorOpsu("etnia", "Etnia Indígena", rootPerfil.opcionesEtnia)
                        }

                        CampoSelectPerfil {
                            etiqueta: "Discapacidad"
                            valor: rootPerfil.opsuDiscapacidad
                            obligatorio: true
                            onAbrirSelector: rootPerfil.abrirSelectorOpsu("disca", "Tipo de Discapacidad", rootPerfil.opcionesDiscapacidad)
                        }

                        CampoSelectPerfil {
                            etiqueta: "Mano Ágil"
                            valor: rootPerfil.opsuManoAgil
                            obligatorio: true
                            onAbrirSelector: rootPerfil.abrirSelectorOpsu("mag", "Mano Ágil", rootPerfil.opcionesManoAgil)
                        }
                    }
                }
            }

            // 7. BOTÓN PRINCIPAL INFERIOR PARA ACTUALIZAR / ENVIAR DATOS AL DAE
            Rectangle {
                id: btnEnviarDatos
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: 54
                radius: 27
                border.color: rootPerfil.modoEdicion ? "#22c55e" : temaApp.bordeAlt
                border.width: 1

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: rootPerfil.modoEdicion ? "#16a34a" : temaApp.secundario }
                    GradientStop { position: 1.0; color: rootPerfil.modoEdicion ? "#22c55e" : temaApp.acento }
                }

                Text {
                    anchors.centerIn: parent
                    text: rootPerfil.modoEdicion ? "ENVIAR Y GUARDAR CAMBIOS" : "ACTUALIZAR DATOS DEL PERFIL"
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                    font.letterSpacing: 0.6
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: btnEnviarDatos.scale = 0.97
                    onReleased: btnEnviarDatos.scale = 1.0
                    onClicked: {
                        if (rootPerfil.modoEdicion) {
                            rootPerfil.guardarCambiosEnServidor()
                        } else {
                            rootPerfil.modoEdicion = true
                        }
                    }
                }
                Behavior on scale { NumberAnimation { duration: 100 } }
            }

            // Botón inferior de Cancelar cuando el modo edición está activo
            Rectangle {
                id: btnCancelarInferior
                visible: rootPerfil.modoEdicion
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: 46
                radius: 23
                color: temaApp.esClaro ? "#fee2e2" : "#2d1219"
                border.color: "#ef4444"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "CANCELAR CAMBIOS Y SALIR DE EDICIÓN"
                    color: temaApp.esClaro ? "#dc2626" : "#fca5a5"
                    font.pixelSize: 13
                    font.bold: true
                    font.letterSpacing: 0.4
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: btnCancelarInferior.scale = 0.97
                    onReleased: btnCancelarInferior.scale = 1.0
                    onClicked: rootPerfil.cancelarEdicion()
                }
                Behavior on scale { NumberAnimation { duration: 100 } }
            }

            // =====================================================================
            // 8. APARTADO DE CONFIGURACIÓN Y PREFERENCIAS DE LA APP
            // =====================================================================

            // Componente para dibujar iconos vectoriales modernos en Configuración
            component IconoConfig: Canvas {
                id: canvasCfg
                property string tipo: "aurora"
                property color colorTrazo: temaApp.acento
                width: 20; height: 20
                onColorTrazoChanged: requestPaint()

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    ctx.strokeStyle = canvasCfg.colorTrazo;
                    ctx.fillStyle = canvasCfg.colorTrazo;
                    ctx.lineWidth = 1.8;
                    ctx.lineCap = "round";
                    ctx.lineJoin = "round";

                    if (tipo === "aurora") {
                        // Estrella de 4 puntas estilo Gemini / Destello fluido
                        ctx.beginPath();
                        ctx.moveTo(10, 2);
                        ctx.quadraticCurveTo(10, 10, 18, 10);
                        ctx.quadraticCurveTo(10, 10, 10, 18);
                        ctx.quadraticCurveTo(10, 10, 2, 10);
                        ctx.quadraticCurveTo(10, 10, 10, 2);
                        ctx.closePath();
                        ctx.stroke();
                    } else if (tipo === "campana") {
                        // Campana minimalista de notificaciones
                        ctx.beginPath();
                        ctx.arc(10, 8, 5, Math.PI, 0, false);
                        ctx.lineTo(15, 13);
                        ctx.lineTo(17, 15);
                        ctx.lineTo(3, 15);
                        ctx.lineTo(5, 13);
                        ctx.closePath();
                        ctx.stroke();
                        ctx.beginPath();
                        ctx.arc(10, 16.5, 1.5, 0, Math.PI, false);
                        ctx.stroke();
                    } else if (tipo === "reloj") {
                        // Reloj con indicador de aula/alarma
                        ctx.beginPath();
                        ctx.arc(10, 10.5, 7, 0, Math.PI * 2);
                        ctx.moveTo(10, 6.5); ctx.lineTo(10, 10.5); ctx.lineTo(13, 12.5);
                        ctx.moveTo(4, 3.5); ctx.lineTo(6.5, 2);
                        ctx.moveTo(16, 3.5); ctx.lineTo(13.5, 2);
                        ctx.stroke();
                    } else if (tipo === "offline") {
                        // Rayo / Almacenamiento instantáneo Offline
                        ctx.beginPath();
                        ctx.moveTo(11, 2);
                        ctx.lineTo(4.5, 11);
                        ctx.lineTo(10, 11);
                        ctx.lineTo(9, 18);
                        ctx.lineTo(15.5, 9);
                        ctx.lineTo(10, 9);
                        ctx.closePath();
                        ctx.stroke();
                    } else if (tipo === "biometria") {
                        // Escudo con arcos de huella dactilar
                        ctx.beginPath();
                        ctx.moveTo(10, 2.5);
                        ctx.lineTo(16.5, 5);
                        ctx.lineTo(16.5, 10.5);
                        ctx.quadraticCurveTo(16.5, 15.5, 10, 18);
                        ctx.quadraticCurveTo(3.5, 15.5, 3.5, 10.5);
                        ctx.lineTo(3.5, 5);
                        ctx.closePath();
                        ctx.stroke();
                        ctx.beginPath();
                        ctx.arc(10, 10.5, 2.2, Math.PI * 0.8, Math.PI * 2.2, false);
                        ctx.stroke();
                    } else if (tipo === "sync") {
                        // Dos flechas circulares de sincronización
                        ctx.beginPath();
                        ctx.arc(10, 10, 6.5, Math.PI * 0.2, Math.PI * 0.85, false);
                        ctx.stroke();
                        ctx.beginPath();
                        ctx.arc(10, 10, 6.5, Math.PI * 1.2, Math.PI * 1.85, false);
                        ctx.stroke();
                        ctx.beginPath();
                        ctx.moveTo(14.5, 4); ctx.lineTo(15.5, 7); ctx.lineTo(12.5, 6.5);
                        ctx.moveTo(5.5, 16); ctx.lineTo(4.5, 13); ctx.lineTo(7.5, 13.5);
                        ctx.stroke();
                    }
                }
            }

            // Fila reutilizable con icono vectorial + Switch animado
            component FilaSwitchConfig: RowLayout {
                id: filaSw
                property string titulo: ""
                property string subtitulo: ""
                property string colorIcono: temaApp.primario
                property string iconoTipo: "aurora"
                property bool activo: true
                property bool controlExterno: false
                signal cambiado(bool nuevoEstado)

                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: 13
                    color: temaApp.panelAlt
                    border.color: temaApp.bordeAlt
                    border.width: 1

                    IconoConfig {
                        anchors.centerIn: parent
                        tipo: filaSw.iconoTipo
                        colorTrazo: filaSw.colorIcono
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: filaSw.titulo
                        color: temaApp.textoPrincipal
                        font.pixelSize: 13
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: filaSw.subtitulo
                        color: temaApp.textoSecundario
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 46
                    Layout.preferredHeight: 26
                    radius: 13
                    color: filaSw.activo ? temaApp.secundario : temaApp.panelAlt
                    border.color: filaSw.activo ? temaApp.acento : temaApp.bordeAlt
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 180 } }

                    Rectangle {
                        width: 20; height: 20; radius: 10
                        anchors.verticalCenter: parent.verticalCenter
                        x: filaSw.activo ? parent.width - width - 3 : 3
                        color: filaSw.activo ? "white" : (temaApp.esClaro ? "#64748b" : "white")

                        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var siguiente = !filaSw.activo
                            if (!filaSw.controlExterno) {
                                filaSw.activo = siguiente
                            }
                            filaSw.cambiado(siguiente)
                        }
                    }
                }
            }

            // Encabezado de Configuración
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 22
                Layout.rightMargin: 22
                Layout.topMargin: 10
                spacing: 8

                Text {
                    text: "Configuración de la App"
                    color: temaApp.textoPrincipal
                    font.pixelSize: 18
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
            }

            // TARJETA A: APARIENCIA, TEMA Y COLORES DEL EFECTO VAULTA/AURORA
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: colApariencia.implicitHeight + 32
                radius: 24
                color: temaApp.panel
                border.color: temaApp.bordePanel
                border.width: 1

                ColumnLayout {
                    id: colApariencia
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Rectangle { Layout.preferredWidth: 8; Layout.preferredHeight: 18; radius: 4; color: temaApp.primario }
                        Text { text: "Apariencia y Tema"; color: temaApp.textoPrincipal; font.pixelSize: 15; font.bold: true }
                    }

                    // 1. Selector de modo base (Sistema | Oscuro | Claro | OLED)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: [
                                { idx: 3, nombre: "Sistema", sub: "Automático",  cFondo: ventanaPrincipal.sistemaEsClaro ? "#f8fafc" : "#0f172a", cBorde: temaApp.acento },
                                { idx: 0, nombre: "Oscuro",  sub: "Modo Noche",  cFondo: "#0f172a", cBorde: temaApp.primario },
                                { idx: 1, nombre: "Claro",   sub: "Clásico DAE", cFondo: "#f8fafc", cBorde: temaApp.secundario },
                                { idx: 2, nombre: "OLED",    sub: "Negro Puro",  cFondo: "#000000", cBorde: temaApp.acento }
                            ]

                            delegate: Rectangle {
                                // Las paletas de solo claro (como Promo) siempre se ven en modo Claro
                                property bool activo: (ventanaPrincipal.temaSeleccionado === modelData.idx)
                                                  || (ventanaPrincipal.esTemaPromo && modelData.idx === 1)
                                Layout.fillWidth: true
                                Layout.preferredHeight: 66
                                radius: 16
                                color: activo ? temaApp.panelEdit : temaApp.panelAlt
                                border.color: activo ? temaApp.acento : temaApp.bordeAlt
                                border.width: activo ? 1.8 : 1
                                Behavior on color { ColorAnimation { duration: 180 } }

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 3

                                    Rectangle {
                                        width: 18; height: 18; radius: 9
                                        color: modelData.cFondo
                                        border.color: modelData.cBorde
                                        border.width: 2
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                    Text {
                                        text: modelData.nombre
                                        color: temaApp.textoPrincipal
                                        font.pixelSize: 11
                                        font.bold: true
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                    Text {
                                        text: modelData.sub
                                        color: temaApp.textoSecundario
                                        font.pixelSize: 9
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        // El tema Promo está diseñado sobre fondo crema: solo admite modo Claro
                                        if (ventanaPrincipal.esTemaPromo && modelData.idx !== 1) {
                                            ventanaPrincipal.temaSeleccionado = 1
                                            bannerGuardado.mostrar("✓ El tema Promo solo admite el modo Claro")
                                            return
                                        }
                                        ventanaPrincipal.temaSeleccionado = modelData.idx
                                        bannerGuardado.mostrar("✓ Tema: " + modelData.nombre + (modelData.idx === 3 ? " (Según tu dispositivo)" : ""))
                                    }
                                }
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: temaApp.bordePanel }

                    // 2. Selector de Paleta de Colores del Efecto Vaulta / Aurora
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Paletas de Colores"
                            color: temaApp.textoSecundario
                            font.pixelSize: 12
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: rootPerfil.paletasAurora[ventanaPrincipal.paletaAuroraIndex].nombre
                            color: temaApp.esClaro ? temaApp.primario : rootPerfil.paletasAurora[ventanaPrincipal.paletaAuroraIndex].l1
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    // Cuadrícula con todas las paletas (la primera es "Promo", el tema predeterminado)
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 5
                        rowSpacing: 8
                        columnSpacing: 6

                        Repeater {
                            model: rootPerfil.paletasAurora

                            delegate: Item {
                                property bool sel: ventanaPrincipal.paletaAuroraIndex === index
                                Layout.fillWidth: true
                                Layout.preferredHeight: 58

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Rectangle {
                                        width: 36; height: 36; radius: 18
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        border.color: sel ? (temaApp.esClaro ? temaApp.oscuro : "white") : "#35ffffff"
                                        border.width: sel ? 2.5 : 1
                                        scale: sel ? 1.08 : 1.0

                                        Behavior on scale { NumberAnimation { duration: 150 } }

                                        gradient: Gradient {
                                            GradientStop { position: 0.0; color: modelData.acento || modelData.l1 }
                                            GradientStop { position: 0.55; color: modelData.primario || modelData.l2 }
                                            GradientStop { position: 1.0; color: modelData.cPrevia || modelData.cBase }
                                        }

                                        // Punto blanco central cuando está seleccionado
                                        Rectangle {
                                            visible: sel
                                            width: 8; height: 8; radius: 4
                                            anchors.centerIn: parent
                                            color: "white"
                                        }
                                    }

                                    Text {
                                        text: modelData.nombre
                                        color: sel ? temaApp.textoPrincipal : temaApp.textoMuted
                                        font.pixelSize: 10
                                        font.bold: sel
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        ventanaPrincipal.paletaAuroraIndex = index
                                        // Las paletas de solo claro (Promo) exigen el modo claro
                                        if (modelData.soloClaro && ventanaPrincipal.temaSeleccionado !== 1) {
                                            ventanaPrincipal.temaSeleccionado = 1
                                        }
                                        bannerGuardado.mostrar("✓ Paleta cambiada a " + modelData.nombre)
                                    }
                                }
                            }
                        }
                    }

                    // Muestra de los 6 tonos exactos de la paleta seleccionada
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Repeater {
                            model: rootPerfil.paletasAurora[ventanaPrincipal.paletaAuroraIndex].colores || []

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 22
                                radius: 8
                                color: modelData
                                border.color: "#35ffffff"
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.toUpperCase()
                                    font.pixelSize: 8
                                    font.bold: true
                                    color: (index === 3 || index === 4) ? "#0f172a" : "#ffffff"
                                }
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: temaApp.bordePanel }

                    // 3. Switch para activar/pausar el movimiento de las ondas
                    FilaSwitchConfig {
                        titulo: "Difuminado Aurora en Movimiento"
                        subtitulo: "Animación fluida estilo Gemini en el fondo"
                        iconoTipo: "aurora"
                        colorIcono: temaApp.esClaro ? temaApp.primario : rootPerfil.paletasAurora[ventanaPrincipal.paletaAuroraIndex].l1
                        activo: ventanaPrincipal.animacionAuroraActiva
                        onCambiado: (est) => {
                            ventanaPrincipal.animacionAuroraActiva = est
                            bannerGuardado.mostrar(est ? "✓ Movimiento fluido activado" : "✓ Fondo estático activado")
                        }
                    }
                }
            }

            // TARJETA C: SEGURIDAD Y CUENTA DAE
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: colSeguridad.implicitHeight + 32
                radius: 24
                color: temaApp.panel
                border.color: temaApp.bordePanel
                border.width: 1

                ColumnLayout {
                    id: colSeguridad
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Rectangle { Layout.preferredWidth: 8; Layout.preferredHeight: 18; radius: 4; color: temaApp.secundario }
                        Text { text: "Seguridad y Cuenta"; color: temaApp.textoPrincipal; font.pixelSize: 15; font.bold: true }
                    }

                    FilaSwitchConfig {
                        titulo: "Acceso Biométrico / Huella"
                        subtitulo: daeClient.biometriaActiva
                                   ? ("Activo • Vinculado a V-" + daeClient.cedulaBiometricaFormateada)
                                   : "Iniciar sesión rápido con huella sin escribir la clave"
                        iconoTipo: "biometria"
                        colorIcono: temaApp.acento
                        activo: daeClient.biometriaActiva
                        controlExterno: true
                        onCambiado: (est) => {
                            daeClient.activarBiometria(est)
                        }
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: temaApp.bordePanel }

                    FilaSwitchConfig {
                        titulo: "Permiso de Notificaciones"
                        subtitulo: daeClient.permisoNotificacionesActivo
                                   ? "Activo • Avisos de tareas y exámenes habilitados"
                                   : "Activar permiso para recibir avisos de tareas y exámenes"
                        iconoTipo: "campana"
                        colorIcono: temaApp.primario
                        activo: daeClient.permisoNotificacionesActivo
                        controlExterno: true
                        onCambiado: (est) => {
                            daeClient.activarPermisoNotificaciones(est)
                        }
                    }

                    // Botón para forzar la sincronización real con el DAE.
                    // La app guarda una copia local de los datos de la sesión y
                    // solo vuelve a consultar al servidor cuando se pulsa aquí
                    // (o cuando la copia caduca).
                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: temaApp.bordePanel }

                    Rectangle {
                        id: botonSincronizarPerfil
                        Layout.fillWidth: true
                        Layout.preferredHeight: 46
                        radius: 14
                        color: temaApp.panelAlt
                        border.color: temaApp.bordeAlt
                        border.width: 1
                        opacity: daeClient.sincronizandoServidor ? 0.6 : 1.0

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 10

                            IconoConfig {
                                tipo: "sync"
                                colorTrazo: temaApp.esClaro ? temaApp.primario : temaApp.claro
                            }

                            Text {
                                text: daeClient.sincronizandoServidor
                                      ? "Sincronizando con el servidor..."
                                      : "Sincronizar con el servidor DAE"
                                color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                                font.pixelSize: 12
                                font.bold: true
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !daeClient.sincronizandoServidor
                            cursorShape: Qt.PointingHandCursor
                            onClicked: daeClient.sincronizarConServidor()
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: daeClient.actualizadoHace !== ""
                        text: daeClient.datosDesdeCache
                              ? ("Datos guardados en el teléfono • Actualizados " + daeClient.actualizadoHace)
                              : ("Datos actualizados " + daeClient.actualizadoHace)
                        color: temaApp.textoSecundario
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // TARJETA D: ACERCA DEL PROYECTO Y APOYO VOLUNTARIO
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: colAcercaProyecto.implicitHeight + 32
                radius: 24
                color: temaApp.panel
                border.color: temaApp.bordePanel
                border.width: 1

                ColumnLayout {
                    id: colAcercaProyecto
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: 8
                            Layout.preferredHeight: 18
                            radius: 4
                            color: temaApp.acento
                        }

                        Text {
                            text: "Acerca del Proyecto"
                            color: temaApp.textoPrincipal
                            font.pixelSize: 15
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            Layout.preferredWidth: lblLicenciaGpl.implicitWidth + 16
                            Layout.preferredHeight: 22
                            radius: 11
                            color: temaApp.panelAlt
                            border.color: temaApp.bordeAlt
                            border.width: 1

                            Text {
                                id: lblLicenciaGpl
                                anchors.centerIn: parent
                                text: "GNU GPL v3"
                                color: temaApp.acentoVisible
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Cliente móvil independiente y de código abierto desarrollado por un estudiante de Ingeniería de Telecomunicaciones de la UC. Esta aplicación es gratuita y sin fines de lucro."
                        color: temaApp.textoSecundario
                        font.pixelSize: 12
                        lineHeight: 1.3
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        id: btnAbrirGithub
                        Layout.fillWidth: true
                        Layout.preferredHeight: 46
                        radius: 14
                        color: temaApp.panelAlt
                        border.color: temaApp.bordeAlt
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 9

                            // Icono vectorial de repositorio / código en GitHub
                            Canvas {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                property color colorTrazo: temaApp.acentoVisible
                                onColorTrazoChanged: requestPaint()
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.reset();
                                    ctx.strokeStyle = colorTrazo;
                                    ctx.lineWidth = 1.7;
                                    ctx.lineCap = "round";
                                    ctx.lineJoin = "round";
                                    // Símbolo de código </>
                                    ctx.beginPath();
                                    ctx.moveTo(7, 6);
                                    ctx.lineTo(3, 10);
                                    ctx.lineTo(7, 14);
                                    ctx.moveTo(13, 6);
                                    ctx.lineTo(17, 10);
                                    ctx.lineTo(13, 14);
                                    ctx.moveTo(11, 4.5);
                                    ctx.lineTo(9, 15.5);
                                    ctx.stroke();
                                }
                            }

                            Text {
                                text: "Ver repositorio del proyecto en GitHub"
                                color: temaApp.textoPrincipal
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onPressed: btnAbrirGithub.scale = 0.97
                            onReleased: btnAbrirGithub.scale = 1.0
                            onCanceled: btnAbrirGithub.scale = 1.0
                            onClicked: Qt.openUrlExternally("https://github.com/Emmanuel726/AppDAE")
                        }
                        Behavior on scale { NumberAnimation { duration: 100 } }
                    }

                    Rectangle {
                        id: btnAbrirApoyo
                        Layout.fillWidth: true
                        Layout.preferredHeight: 46
                        radius: 14
                        color: temaApp.panelAlt
                        border.color: temaApp.acento
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 9

                            // Icono vectorial de taza de café
                            Canvas {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                property color colorTrazo: temaApp.acentoVisible
                                onColorTrazoChanged: requestPaint()
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.reset();
                                    ctx.strokeStyle = colorTrazo;
                                    ctx.lineWidth = 1.7;
                                    ctx.lineCap = "round";
                                    ctx.lineJoin = "round";
                                    // Cuerpo de la taza
                                    ctx.beginPath();
                                    ctx.moveTo(3.5, 8);
                                    ctx.lineTo(13.5, 8);
                                    ctx.lineTo(12.6, 15);
                                    ctx.quadraticCurveTo(12.3, 17, 8.5, 17);
                                    ctx.quadraticCurveTo(4.7, 17, 4.4, 15);
                                    ctx.closePath();
                                    ctx.stroke();
                                    // Asa derecha
                                    ctx.beginPath();
                                    ctx.arc(14.2, 11.4, 2.3, -Math.PI / 2, Math.PI / 2, false);
                                    ctx.stroke();
                                    // Vapor superior
                                    ctx.beginPath();
                                    ctx.moveTo(6.5, 3);
                                    ctx.quadraticCurveTo(5.8, 4.5, 6.8, 5.8);
                                    ctx.moveTo(10.2, 2.5);
                                    ctx.quadraticCurveTo(9.5, 4.2, 10.5, 5.6);
                                    ctx.stroke();
                                }
                            }

                            Text {
                                text: "Apoyar al desarrollador (Invítame un café)"
                                color: temaApp.textoPrincipal
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onPressed: btnAbrirApoyo.scale = 0.97
                            onReleased: btnAbrirApoyo.scale = 1.0
                            onCanceled: btnAbrirApoyo.scale = 1.0
                            onClicked: rootPerfil.modalApoyoAbierto = true
                        }
                        Behavior on scale { NumberAnimation { duration: 100 } }
                    }
                }
            }

            // CRÉDITO DEL DESARROLLO Y VERSIÓN
            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                Layout.bottomMargin: 14
                spacing: 3

                Text {
                    Layout.fillWidth: true
                    text: "Desarrollado por Emmanuel"
                    color: temaApp.textoSecundario
                    font.pixelSize: 11
                    font.italic: true
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    Layout.fillWidth: true
                    text: "Versión 1.1"
                    color: temaApp.textoMuted
                    font.pixelSize: 10
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    // =========================================================================
    // NOTIFICACIÓN FLOTANTE DE CONFIRMACIÓN (TOAST)
    // =========================================================================
    Rectangle {
        id: bannerGuardado
        property string mensaje: ""
        function mostrar(txt) {
            mensaje = txt
            opacity = 1.0
            timerOcultar.restart()
        }

        width: parent.width - 44
        height: 46
        radius: 23
        anchors.horizontalCenter: parent.horizontalCenter
        y: opacity > 0 ? 18 : -50
        color: "#ee064e3b"
        border.color: "#4ade80"
        border.width: 1
        opacity: 0
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 220 } }
        Behavior on y { NumberAnimation { duration: 280; easing.type: Easing.OutBack } }

        Text {
            anchors.centerIn: parent
            text: bannerGuardado.mensaje
            color: "white"
            font.pixelSize: 12
            font.bold: true
        }

        Timer {
            id: timerOcultar
            interval: 2600
            onTriggered: bannerGuardado.opacity = 0
        }
    }

    // =========================================================================
    // MODAL PARA SUBIR O QUITAR LA FOTO DE PERFIL
    // =========================================================================
    Item {
        anchors.fill: parent
        visible: fondoModalFoto.opacity > 0

        Rectangle {
            id: fondoModalFoto
            anchors.fill: parent
            color: "#bb040812"
            opacity: rootPerfil.menuFotoAbierto ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 220 } }

            MouseArea {
                anchors.fill: parent
                enabled: rootPerfil.menuFotoAbierto
                onClicked: rootPerfil.menuFotoAbierto = false
            }
        }

        Rectangle {
            width: parent.width - 40
            height: rootPerfil.urlFotoPerfil !== "" ? 235 : 185
            radius: 26
            anchors.centerIn: parent
            color: temaApp.panel
            border.color: temaApp.bordeVidrio
            border.width: 1
            scale: rootPerfil.menuFotoAbierto ? 1.0 : 0.88
            opacity: rootPerfil.menuFotoAbierto ? 1.0 : 0.0

            Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack } }
            Behavior on opacity { NumberAnimation { duration: 200 } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 10

                Text {
                    text: "Foto de Perfil del Estudiante"
                    color: temaApp.textoPrincipal
                    font.pixelSize: 16
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
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
                        text: "Subir nueva foto desde mi dispositivo"
                        color: "white"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: selectorImagen.open()
                    }
                }

                Rectangle {
                    visible: rootPerfil.urlFotoPerfil !== ""
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    radius: 15
                    color: "#3b151e"
                    border.color: "#ef4444"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Quitar foto actual (Usar iniciales " + rootPerfil.iniciales + ")"
                        color: "#fca5a5"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            rootPerfil.urlFotoPerfil = ""
                            rootPerfil.menuFotoAbierto = false
                            bannerGuardado.mostrar("✓ Se restauraron tus iniciales (EP)")
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: 15
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "Cancelar"
                        color: "#94a3b8"
                        font.pixelSize: 13
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rootPerfil.menuFotoAbierto = false
                    }
                }
            }
        }
    }

    // =========================================================================
    // EDITOR PARA ENCUADRAR LA FOTO DE PERFIL (Arrastrar para mover, pellizcar / rueda / deslizador para zoom)
    // =========================================================================
    Rectangle {
        id: editorFoto
        anchors.fill: parent
        visible: rootPerfil.editorFotoAbierto
        color: "#f2040812"
        z: 170

        // Bloquea los toques hacia el contenido de abajo
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: 28
            // Margen inferior extra: deja libres los botones de Cancelar / Guardar
            anchors.bottomMargin: 34
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 16

            Text {
                Layout.fillWidth: true
                text: "Ajustar Foto de Perfil"
                color: "#ffffff"
                font.pixelSize: 18
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                Layout.fillWidth: true
                text: "Arrastra para mover la foto y usa el zoom para encuadrarla dentro del círculo"
                color: "#cbd5e1"
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Item {
                id: contenedorRecorte
                Layout.fillWidth: true
                Layout.fillHeight: true

                readonly property real lado: Math.max(80, Math.min(width, height, 380))

                // Área cuadrada que se captura al guardar (solo contiene la imagen, sin la máscara)
                Item {
                    id: areaRecorte
                    width: contenedorRecorte.lado
                    height: contenedorRecorte.lado
                    anchors.centerIn: parent
                    clip: true

                    // Escala base tipo "cubrir": la foto siempre llena el área completa
                    readonly property real anchoFuente: imgRecorte.implicitWidth > 0 ? imgRecorte.implicitWidth : 1
                    readonly property real altoFuente: imgRecorte.implicitHeight > 0 ? imgRecorte.implicitHeight : 1
                    readonly property real escalaBase: Math.max(width / anchoFuente, height / altoFuente)

                    function limitarPosicion() {
                        imgRecorte.x = Math.min(0, Math.max(width - imgRecorte.width, imgRecorte.x))
                        imgRecorte.y = Math.min(0, Math.max(height - imgRecorte.height, imgRecorte.y))
                    }

                    // Aplica un nuevo zoom manteniendo fijo el punto (cx, cy) del área
                    function aplicarZoom(nuevoZoom, cx, cy) {
                        var z = Math.max(1.0, Math.min(rootPerfil.zoomFotoMax, nuevoZoom))
                        var anteriorAncho = imgRecorte.width
                        var anteriorAlto = imgRecorte.height
                        var px = (cx - imgRecorte.x) / Math.max(1, anteriorAncho)
                        var py = (cy - imgRecorte.y) / Math.max(1, anteriorAlto)
                        rootPerfil.zoomFoto = z
                        imgRecorte.x = cx - px * imgRecorte.width
                        imgRecorte.y = cy - py * imgRecorte.height
                        limitarPosicion()
                    }

                    function centrar() {
                        imgRecorte.x = (width - imgRecorte.width) / 2
                        imgRecorte.y = (height - imgRecorte.height) / 2
                    }

                    onWidthChanged: { centrar(); limitarPosicion() }

                    Image {
                        id: imgRecorte
                        source: rootPerfil.urlFotoPendiente
                        autoTransform: true          // Respeta la orientación EXIF de las fotos de la cámara
                        asynchronous: true
                        smooth: true
                        // Limita el tamaño decodificado: sin esto, una foto de 12 MP crea una
                        // textura enorme y el sistema puede cerrar la app por falta de memoria
                        sourceSize: Qt.size(2048, 2048)
                        width: areaRecorte.anchoFuente * areaRecorte.escalaBase * rootPerfil.zoomFoto
                        height: areaRecorte.altoFuente * areaRecorte.escalaBase * rootPerfil.zoomFoto
                        onStatusChanged: {
                            if (status === Image.Ready) {
                                rootPerfil.zoomFoto = 1.0
                                areaRecorte.centrar()
                            }
                        }
                    }

                    // Arrastrar con un dedo / ratón para mover (limitado para que la foto siempre cubra el área)
                    DragHandler {
                        id: arrastreFoto
                        target: imgRecorte
                        minimumPointCount: 1
                        maximumPointCount: 1
                        cursorShape: active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                        xAxis.minimum: Math.min(0, areaRecorte.width - imgRecorte.width)
                        xAxis.maximum: 0
                        yAxis.minimum: Math.min(0, areaRecorte.height - imgRecorte.height)
                        yAxis.maximum: 0
                    }

                    // Rueda del ratón para zoom (escritorio)
                    WheelHandler {
                        target: null
                        onWheel: (evento) => {
                            var factor = evento.angleDelta.y > 0 ? 1.1 : (1.0 / 1.1)
                            areaRecorte.aplicarZoom(rootPerfil.zoomFoto * factor, point.position.x, point.position.y)
                        }
                    }

                    // Pellizcar para hacer zoom (pantallas táctiles)
                    PinchHandler {
                        id: pellizcoFoto
                        target: null
                        property real zoomInicial: 1.0
                        onActiveChanged: if (active) zoomInicial = rootPerfil.zoomFoto
                        onActiveScaleChanged: {
                            if (active) {
                                areaRecorte.aplicarZoom(zoomInicial * activeScale, centroid.position.x, centroid.position.y)
                            }
                        }
                    }
                }

                // Máscara visual: oscurece las esquinas y marca el círculo que se verá en el avatar
                Canvas {
                    anchors.fill: areaRecorte
                    enabled: false
                    onWidthChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.reset()
                        var r = width / 2
                        ctx.fillStyle = "rgba(4, 8, 18, 0.62)"
                        ctx.beginPath()
                        ctx.rect(0, 0, width, height)
                        ctx.arc(r, r, r - 1, 0, Math.PI * 2, true)
                        ctx.closePath()
                        ctx.fill()
                        ctx.strokeStyle = "rgba(255, 255, 255, 0.9)"
                        ctx.lineWidth = 2
                        ctx.beginPath()
                        ctx.arc(r, r, r - 1, 0, Math.PI * 2)
                        ctx.stroke()
                    }
                }

                Text {
                    anchors.centerIn: areaRecorte
                    visible: imgRecorte.status === Image.Loading
                    text: "Cargando foto..."
                    color: "#ffffff"
                    font.pixelSize: 13
                }

                Text {
                    anchors.centerIn: areaRecorte
                    width: areaRecorte.width - 24
                    visible: imgRecorte.status === Image.Error
                    text: "No se pudo abrir la imagen seleccionada"
                    color: "#fca5a5"
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }

            // Control de zoom
            RowLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: 380
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

                Text { text: "−"; color: "#ffffff"; font.pixelSize: 20; font.bold: true }

                Slider {
                    id: deslizadorZoom
                    Layout.fillWidth: true
                    from: 1.0
                    to: rootPerfil.zoomFotoMax
                    value: rootPerfil.zoomFoto
                    onMoved: {
                        areaRecorte.aplicarZoom(value, areaRecorte.width / 2, areaRecorte.height / 2)
                        value = Qt.binding(function() { return rootPerfil.zoomFoto })
                    }
                }

                Text { text: "+"; color: "#ffffff"; font.pixelSize: 20; font.bold: true }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: 380
                Layout.alignment: Qt.AlignHCenter
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    radius: 15
                    color: "transparent"
                    border.color: "#64748b"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Cancelar"
                        color: "#cbd5e1"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rootPerfil.cerrarEditorFoto()
                    }
                }

                Rectangle {
                    id: btnGuardarRecorte
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    radius: 15
                    color: temaApp.secundario
                    border.color: temaApp.acento
                    border.width: 1
                    opacity: imgRecorte.status === Image.Ready ? 1.0 : 0.5

                    Text {
                        anchors.centerIn: parent
                        text: "Guardar Foto"
                        color: "white"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: imgRecorte.status === Image.Ready
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var ruta = daeClient.prepararRutaFotoPerfil()
                            // Captura únicamente el área cuadrada encuadrada a 600x600 px
                            areaRecorte.grabToImage(function(resultado) {
                                if (resultado.saveToFile(ruta)) {
                                    rootPerfil.urlFotoPerfil = "file://" + (ruta.charAt(0) === "/" ? "" : "/") + ruta
                                    bannerGuardado.mostrar("✓ Foto de perfil actualizada correctamente")
                                } else {
                                    // Si no se pudo guardar el recorte, se conserva la foto original
                                    rootPerfil.urlFotoPerfil = rootPerfil.urlFotoPendiente
                                    bannerGuardado.mostrar("Foto aplicada sin recorte (no se pudo guardar el ajuste)")
                                }
                                rootPerfil.cerrarEditorFoto()
                            }, Qt.size(600, 600))
                        }
                    }
                }
            }
        }
    }

    // 10. MODAL DESPLEGABLE PARA SELECCIONAR OPCIONES OPSU (Estado Civil, Etnia, Discapacidad, Mano Ágil)
    Rectangle {
        anchors.fill: parent
        visible: rootPerfil.selectorOpsuAbierto
        color: "#aa050b16"
        z: 160

        MouseArea {
            anchors.fill: parent
            onClicked: rootPerfil.selectorOpsuAbierto = false
        }

        Rectangle {
            width: parent.width - 36
            height: Math.min(colModalOpsu.implicitHeight + 36, parent.height * 0.72)
            anchors.centerIn: parent
            radius: 26
            color: temaApp.esClaro ? "#ffffff" : Qt.darker(temaApp.oscuro, 0.9)
            border.color: temaApp.acento
            border.width: 1
            clip: true

            MouseArea { anchors.fill: parent }

            ColumnLayout {
                id: colModalOpsu
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 8
                        Layout.preferredHeight: 20
                        radius: 4
                        color: temaApp.acento
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: "Seleccionar " + rootPerfil.tituloSelectorOpsu
                            color: temaApp.textoPrincipal
                            font.pixelSize: 15
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: "Opciones oficiales del registro DAE / OPSU"
                            color: temaApp.textoSecundario
                            font.pixelSize: 11
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 14
                        color: temaApp.esClaro ? "#f1f5f9" : "#1affffff"

                        Canvas {
                            width: 12; height: 12
                            anchors.centerIn: parent
                            property color colorTrazo: temaApp.textoSecundario
                            onColorTrazoChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.strokeStyle = colorTrazo;
                                ctx.lineWidth = 2.0;
                                ctx.lineCap = "round";
                                ctx.beginPath();
                                ctx.moveTo(2.5, 2.5); ctx.lineTo(9.5, 9.5);
                                ctx.moveTo(9.5, 2.5); ctx.lineTo(2.5, 9.5);
                                ctx.stroke();
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: rootPerfil.selectorOpsuAbierto = false
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: temaApp.bordePanel
                }

                ListView {
                    id: listaOpcionesView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: Math.min(rootPerfil.listaOpcionesActiva.length * 46, 320)
                    clip: true
                    spacing: 6
                    model: rootPerfil.listaOpcionesActiva

                    delegate: Rectangle {
                        required property string modelData
                        readonly property bool esSeleccionada: modelData.toUpperCase() === rootPerfil.obtenerValorActualSelector().toUpperCase()

                        width: listaOpcionesView.width
                        height: 42
                        radius: 12
                        color: esSeleccionada
                               ? Qt.rgba(temaApp.acento.r, temaApp.acento.g, temaApp.acento.b, 0.22)
                               : (temaApp.esClaro ? "#f8fafc" : "#14ffffff")
                        border.color: esSeleccionada ? temaApp.acento : temaApp.bordeAlt
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 10

                            Text {
                                text: modelData
                                color: esSeleccionada
                                       ? (temaApp.esClaro ? temaApp.primario : temaApp.claro)
                                       : temaApp.textoPrincipal
                                font.pixelSize: 13
                                font.bold: esSeleccionada
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                visible: esSeleccionada
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                radius: 10
                                color: "#22c55e"

                                Text {
                                    anchors.centerIn: parent
                                    text: "✓"
                                    color: "white"
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: rootPerfil.aplicarOpcionSelector(modelData)
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // MODAL EMERGENTE DE APOYO VOLUNTARIO AL DESARROLLADOR
    // =========================================================================
    Item {
        id: overlayModalApoyo
        anchors.fill: parent
        visible: rootPerfil.modalApoyoAbierto
        z: 1050

        Rectangle {
            anchors.fill: parent
            color: temaApp.esClaro ? "#aa0f172a" : "#bb040814"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: rootPerfil.modalApoyoAbierto = false
        }

        Rectangle {
            id: tarjetaModalApoyo
            width: Math.min(parent.width - 36, 400)
            height: Math.min(parent.height - 48, colModalApoyo.implicitHeight + 40)
            anchors.centerIn: parent
            radius: 26
            color: temaApp.panel
            border.color: temaApp.acento
            border.width: 1.5

            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                id: colModalApoyo
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                // Título del modal
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        radius: 12
                        color: temaApp.panelAlt
                        border.color: temaApp.acento
                        border.width: 1

                        Canvas {
                            anchors.centerIn: parent
                            width: 18
                            height: 18
                            property color colorTrazo: temaApp.acentoVisible
                            onColorTrazoChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.strokeStyle = colorTrazo;
                                ctx.lineWidth = 1.7;
                                ctx.lineCap = "round";
                                ctx.lineJoin = "round";
                                ctx.beginPath();
                                ctx.moveTo(9, 15.5);
                                ctx.bezierCurveTo(3.5, 12, 2, 8.2, 2, 5.8);
                                ctx.arc(5.5, 5.8, 3.5, Math.PI, 0, false);
                                ctx.arc(12.5, 5.8, 3.5, Math.PI, 0, false);
                                ctx.bezierCurveTo(16, 8.2, 14.5, 12, 9, 15.5);
                                ctx.stroke();
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Apoyar el Desarrollo"
                        color: temaApp.textoPrincipal
                        font.pixelSize: 17
                        font.bold: true
                        elide: Text.ElideRight
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "AppDAE es 100% gratuita y de código abierto (GPL v3). Si te resulta útil durante el semestre y deseas colaborar voluntariamente con el estudiante desarrollador, puedes hacerlo aquí:"
                    color: temaApp.textoSecundario
                    font.pixelSize: 12
                    lineHeight: 1.3
                    wrapMode: Text.WordWrap
                }

                // Tarjeta interactiva 1: Pago Móvil
                Rectangle {
                    id: cardPagoMovil
                    Layout.fillWidth: true
                    Layout.preferredHeight: colPagoMovil.implicitHeight + 22
                    radius: 16
                    color: temaApp.panelAlt
                    border.color: temaApp.bordeAlt
                    border.width: 1

                    ColumnLayout {
                        id: colPagoMovil
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                Layout.fillWidth: true
                                text: "Pago Móvil"
                                color: temaApp.acentoVisible
                                font.pixelSize: 13
                                font.bold: true
                            }

                            Text {
                                text: "Tocar para copiar"
                                color: temaApp.textoMuted
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Banco de Venezuela (0102)"
                            color: temaApp.textoPrincipal
                            font.pixelSize: 12
                            font.bold: true
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Teléfono: 04120332476  •  C.I.: 30094892"
                            color: temaApp.textoSecundario
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPressed: cardPagoMovil.scale = 0.98
                        onReleased: cardPagoMovil.scale = 1.0
                        onCanceled: cardPagoMovil.scale = 1.0
                        onClicked: {
                            rootPerfil.copiarAlPortapapeles(
                                "0102 30094892 04120332476",
                                "✓ Datos de Pago Móvil copiados al portapapeles"
                            )
                        }
                    }
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }

                // Tarjeta interactiva 2: Binance Pay
                Rectangle {
                    id: cardBinancePay
                    Layout.fillWidth: true
                    Layout.preferredHeight: colBinancePay.implicitHeight + 22
                    radius: 16
                    color: temaApp.panelAlt
                    border.color: temaApp.bordeAlt
                    border.width: 1

                    ColumnLayout {
                        id: colBinancePay
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                Layout.fillWidth: true
                                text: "Binance Pay"
                                color: temaApp.esClaro ? "#b45309" : "#fbbf24"
                                font.pixelSize: 13
                                font.bold: true
                            }

                            Text {
                                text: "Tocar para copiar"
                                color: temaApp.textoMuted
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "UID: 439479135"
                            color: temaApp.textoPrincipal
                            font.pixelSize: 12
                            font.bold: true
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Correo: perezemmanuel726@gmail.com"
                            color: temaApp.textoSecundario
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPressed: cardBinancePay.scale = 0.98
                        onReleased: cardBinancePay.scale = 1.0
                        onCanceled: cardBinancePay.scale = 1.0
                        onClicked: {
                            rootPerfil.copiarAlPortapapeles(
                                "439479135",
                                "✓ UID de Binance copiado (perezemmanuel726@gmail.com)"
                            )
                        }
                    }
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }

                // Botón Cerrar
                Rectangle {
                    id: btnCerrarApoyo
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    Layout.topMargin: 2
                    radius: 22
                    color: temaApp.primario
                    border.color: temaApp.acento
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Cerrar"
                        color: "#ffffff"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPressed: btnCerrarApoyo.scale = 0.97
                        onReleased: btnCerrarApoyo.scale = 1.0
                        onCanceled: btnCerrarApoyo.scale = 1.0
                        onClicked: rootPerfil.modalApoyoAbierto = false
                    }
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }
            }
        }
    }
}
