import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Effects

// =============================================================================
// MIS TAREAS Y EXÁMENES
// Allows programar recordatorios por materia (tareas o exámenes), indicar la
// descripción o los temas a estudiar, y recibir un aviso cuando se acerque la
// fecha. El listado va de lo más próximo a lo más lejano.
// =============================================================================
Item {
    id: rootRecordatorios

    signal cerrar()

    // La lista ya viene ordenada por fecha y hora (de lo más próximo a lo más lejano)
    readonly property var todos: daeClient.recordatorios
    readonly property var visibles: {
        var lista = [];
        for (var i = 0; i < todos.length; i++) {
            var r = todos[i];
            if (filtro === "todos") {
                lista.push(r);
            } else if (filtro === "pendientes" && !r.hecho) {
                lista.push(r);
            } else if (filtro === "hechos" && r.hecho) {
                lista.push(r);
            }
        }
        return lista;
    }

    property string filtro: "pendientes"
    property bool calendarioAbierto: false
    // "tarea" = eligiendo la fecha de la tarea/examen; "aviso" = eligiendo el día exacto del aviso
    property string modoCalendario: "tarea"

    // ---- Estado del formulario ----
    property bool formularioAbierto: false
    property string mensajeError: ""
    property string editandoId: ""
    property string fTipo: "tarea"
    property string fMateria: ""
    property string fTitulo: ""
    property string fDescripcion: ""
    property string fTemas: ""
    property string fFecha: ""
    property string fHora: "08:00"
    property string fHora12: "08:00"
    property string fAmPm: "AM"

    // Lista de avisos: cada uno puede ser relativo { tipo: "relativo", d, h, etiqueta }
    // o de fecha/hora exacta { tipo: "exacto", fecha: "YYYY-MM-DD", hora: "HH:MM", d: 0, h: 0, etiqueta }
    property var listaAvisos: []
    // Registro tal y como estaba antes de editarlo (para cancelar sus avisos)
    property var registroAnterior: null

    // Selector de día y hora exacta para un aviso personalizado (en formato 12 h + AM/PM)
    property string avisoFechaExacta: ""
    property string avisoHoraExacta: "08:00"
    property string avisoAmPm: "AM"
    property bool avisoExactoModificado: false
    property bool cargandoFormulario: false

    // Desplegable de materias
    property bool listaMateriasAbierta: false
    property string fMateriaSeleccionada: ""

    // Aviso que se está configurando (días y horas de antelación)
    property int avisoDias: 0
    property int avisoHoras: 2

    // Materias que cursa el estudiante (horario + RAP).
    // Se actualiza sola cuando llega el horario y tambien al abrir la lista.
    property var materiasDisponibles: daeClient.materiasParaRecordatorio

    // ---------------------------------------------------------------------
    // COLORES ADAPTATIVOS DEL FORMULARIO
    // Los campos tenian colores claros fijos (#f5ffffff), por lo que en
    // modo oscuro se veian como rectangulos blancos sobre el fondo negro.
    // Ahora se usan los tokens del tema, igual que en el resto de la app
    // (PerfilView usa temaApp.panelEdit para los campos editables).
    // ---------------------------------------------------------------------
    readonly property color campoFondo: temaApp.esClaro ? "#f7ffffff" : temaApp.panelEdit
    readonly property color campoBorde: temaApp.esClaro ? "#99ffffff" : temaApp.bordeAlt
    readonly property color campoTexto: temaApp.esClaro ? "#111827" : temaApp.textoPrincipal
    readonly property color campoPlaceholder: temaApp.esClaro ? "#6b7280" : temaApp.textoMuted
    readonly property color campoTrazo: temaApp.esClaro ? "#111827" : temaApp.textoPrincipal
    readonly property color campoEtiqueta: temaApp.esClaro ? "#4b5563" : temaApp.textoSecundario
    readonly property color listaFondo: temaApp.esClaro ? "#f7ffffff" : temaApp.panelAlt
    readonly property color subPanelFondo: temaApp.esClaro ? "#f5ffffff" : temaApp.panelAlt
    readonly property color subCampoFondo: temaApp.esClaro ? "#ffffff" : temaApp.panelEdit
    readonly property color chipFondo: temaApp.esClaro ? "#e6f2ec" : temaApp.panelAlt
    readonly property color chipTexto: temaApp.esClaro ? "#134e3a" : temaApp.acentoVisible
    readonly property color colorError: temaApp.esClaro ? "#dc2626" : "#f87171"
    // Panel donde va el contenido del formulario
    readonly property color fondoPanelForm: temaApp.esClaro ? temaApp.panelAlt : temaApp.panel

    // ---- Estado del selector de fecha ----
    property int anioVisible: 0
    property int mesVisible: 0
    property int diaVisible: 0

    readonly property var nombresMeses: ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
                                        "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]
    readonly property var nombresDias: ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"]

    // Vuelve a pedir la lista de materias al cliente (por si el horario
    // se cargo despues de abrir el formulario).
    function refrescarMaterias() {
        var lista = daeClient.materiasParaRecordatorio;
        if (lista && lista.length > 0) {
            materiasDisponibles = lista;
        }
    }

    function fechaIso(d, m, a) {
        var mes = (m + 1) < 10 ? "0" + (m + 1) : "" + (m + 1);
        var dia = d < 10 ? "0" + d : "" + d;
        return a + "-" + mes + "-" + dia;
    }

    // Convierte una hora interna "HH:MM" (24h) a partes de 12 horas { hora12: "hh:mm", ampm: "AM"|"PM" }
    function aHora12Partes(hora24Str) {
        var limpia = (hora24Str || "08:00").trim();
        var partes = limpia.split(":");
        var h = partes.length > 0 ? parseInt(partes[0], 10) : 8;
        var m = partes.length > 1 ? parseInt(partes[1], 10) : 0;
        if (isNaN(h)) h = 8;
        if (isNaN(m)) m = 0;
        var ampm = h >= 12 ? "PM" : "AM";
        var h12 = h % 12;
        if (h12 === 0) h12 = 12;
        var hTxt = h12 < 10 ? ("0" + h12) : ("" + h12);
        var mTxt = m < 10 ? ("0" + m) : ("" + m);
        return { hora12: hTxt + ":" + mTxt, ampm: ampm };
    }

    // Convierte lo que escribió el usuario en formato 12h + AM/PM a "HH:MM" (24h)
    function aHora24(hora12Texto, ampm) {
        var limpia = (hora12Texto || "").replace(/[^0-9:]/g, "");
        var partes = limpia.split(":");
        var h = partes.length > 0 && partes[0] !== "" ? parseInt(partes[0], 10) : 8;
        var m = partes.length > 1 && partes[1] !== "" ? parseInt(partes[1], 10) : 0;
        if (isNaN(h)) h = 8;
        if (isNaN(m)) m = 0;
        if (m < 0) m = 0;
        if (m > 59) m = 59;

        // Si el usuario escribió por costumbre una hora > 12 (ej. 20:33), se respeta directamente
        if (h >= 13 && h <= 23) {
            var h24Direct = h < 10 ? ("0" + h) : ("" + h);
            var m24Direct = m < 10 ? ("0" + m) : ("" + m);
            return h24Direct + ":" + m24Direct;
        }

        if (h < 1) h = 12;
        if (h > 12) h = 12;
        var esPm = (ampm || "AM").toUpperCase() === "PM";
        var h24 = h;
        if (esPm && h24 < 12) {
            h24 += 12;
        } else if (!esPm && h24 === 12) {
            h24 = 0;
        }
        var hTxt = h24 < 10 ? ("0" + h24) : ("" + h24);
        var mTxt = m < 10 ? ("0" + m) : ("" + m);
        return hTxt + ":" + mTxt;
    }

    // Formatea cualquier hora "HH:MM" (24h) a texto legible de 12 horas ("08:33 PM")
    function formatearHora12(hora24Str) {
        if (!hora24Str) return "08:00 AM";
        if (hora24Str.toUpperCase().indexOf("AM") !== -1 || hora24Str.toUpperCase().indexOf("PM") !== -1) {
            return hora24Str;
        }
        var p = aHora12Partes(hora24Str);
        return p.hora12 + " " + p.ampm;
    }

    // Calcula los milisegundos epoch en hora local del dispositivo (sin desfase UTC)
    function calcularTimestampLocal(fechaIsoStr, hora24Str) {
        if (!fechaIsoStr || fechaIsoStr.indexOf("-") === -1) return NaN;
        var pf = fechaIsoStr.trim().split("-");
        if (pf.length < 3) return NaN;
        var anio = parseInt(pf[0], 10);
        var mes = parseInt(pf[1], 10) - 1;
        var dia = parseInt(pf[2], 10);

        var ph = (hora24Str || "08:00").trim().split(":");
        var hora = ph.length > 0 ? parseInt(ph[0], 10) : 8;
        var min = ph.length > 1 ? parseInt(ph[1], 10) : 0;
        if (isNaN(anio) || isNaN(mes) || isNaN(dia) || isNaN(hora) || isNaN(min)) {
            return NaN;
        }
        return (new Date(anio, mes, dia, hora, min, 0, 0)).getTime();
    }

    function abrirCalendarioPara(modo) {
        modoCalendario = modo;
        var baseFecha = (modo === "aviso" && avisoFechaExacta !== "") ? avisoFechaExacta : fFecha;
        if (baseFecha && baseFecha.indexOf("-") !== -1) {
            var partes = baseFecha.split("-");
            anioVisible = parseInt(partes[0]);
            mesVisible = parseInt(partes[1]) - 1;
            diaVisible = parseInt(partes[2]);
        }
        calendarioAbierto = true;
    }

    function abrirFormulario(registro) {
        refrescarMaterias();

        cargandoFormulario = true;
        daeClient.solicitarPermisoNotificaciones();

        editandoId = "";
        fTipo = "tarea";
        fMateria = "";
        fTitulo = "";
        fDescripcion = "";
        fTemas = "";
        fFecha = "";
        fHora = "08:00";
        listaAvisos = [{ tipo: "relativo", d: 1, h: 0, etiqueta: "a0" }];

        if (registro) {
            editandoId = registro.id;
            fTipo = registro.tipo || "tarea";
            fMateria = registro.materia || "";
            fTitulo = registro.titulo || "";
            fDescripcion = registro.descripcion || "";
            fTemas = registro.temas || "";
            fFecha = registro.fecha || "";
            fHora = registro.hora || "08:00";

            // Avisos: se recuperan los ya programados (relativos o de fecha/hora exacta)
            var avisos = [];
            if (registro.avisos && registro.avisos.length > 0) {
                for (var i = 0; i < registro.avisos.length; i++) {
                    var av = registro.avisos[i];
                    if (av.tipo === "exacto" || (av.fecha && av.fecha !== "")) {
                        avisos.push({
                            tipo: "exacto",
                            fecha: av.fecha,
                            hora: av.hora || "08:00",
                            d: 0,
                            h: 0,
                            etiqueta: av.etiqueta || ("ex_" + i)
                        });
                    } else {
                        avisos.push({
                            tipo: "relativo",
                            d: av.d || 0,
                            h: av.h || 0,
                            etiqueta: av.etiqueta || ("a" + i)
                        });
                    }
                }
            } else {
                var dAnt = registro.avisarDias !== undefined ? registro.avisarDias : 1;
                var hAnt = registro.avisarHoras !== undefined ? registro.avisarHoras : 2;
                avisos.push({ tipo: "relativo", d: dAnt, h: hAnt, etiqueta: "a0" });
            }
            listaAvisos = avisos;
        }

        var hoy = new Date();
        if (!fFecha) {
            fFecha = fechaIso(hoy.getDate(), hoy.getMonth(), hoy.getFullYear());
        }
        var partes = fFecha.split("-");
        anioVisible = parseInt(partes[0]);
        mesVisible = parseInt(partes[1]) - 1;
        diaVisible = parseInt(partes[2]);

        // Si es un registro nuevo, se ofrece un aviso por defecto (1 día antes)
        if (!registro) {
            listaAvisos = [{ tipo: "relativo", d: 1, h: 0, etiqueta: "a0" }];
        }

        var pTarea = aHora12Partes(fHora);
        fHora12 = pTarea.hora12;
        fAmPm = pTarea.ampm;

        avisoFechaExacta = fFecha;
        avisoHoraExacta = pTarea.hora12;
        avisoAmPm = pTarea.ampm;
        avisoExactoModificado = false;
        registroAnterior = registro ? registro : null;
        mensajeError = "";

        // Volcar los valores a los campos
        campoMateria.text = fMateria;
        campoTitulo.text = fTitulo;
        campoDescripcion.text = fTipo === "examen" ? fTemas : fDescripcion;
        campoHora.text = fHora12;
        campoHoraAviso.text = avisoHoraExacta;

        listaMateriasAbierta = false;
        flickFormulario.contentY = 0;
        cargandoFormulario = false;
        formularioAbierto = true;
    }

    function guardarRegistro() {
        // Confirmar cualquier texto que siga en preedición en el teclado de Android
        Qt.inputMethod.commit();

        var titulo = (campoTitulo.text || "").trim();
        var materia = (campoMateria.text || "").trim();
        var descripcion = (campoDescripcion.text || "").trim();
        var hora24Tarea = aHora24(campoHora.text, fAmPm);

        if (titulo === "" && materia === "") {
            mensajeError = "Escribe un título o elige una materia.";
            return;
        }
        if (fFecha === "") {
            mensajeError = "Elige la fecha de la tarea o del examen.";
            return;
        }

        // Si el usuario modificó la fecha, hora o AM/PM del aviso exacto y pulsó Guardar
        // directamente sin tocar "+ Añadir", se agrega automáticamente ese aviso exacto.
        if (avisoExactoModificado && avisoFechaExacta !== "") {
            var hEx24 = aHora24(campoHoraAviso.text, avisoAmPm);
            agregarAvisoExacto(avisoFechaExacta, hEx24);
            avisoExactoModificado = false;
        }

        fTitulo = titulo;
        fMateria = materia;
        fDescripcion = fTipo === "examen" ? "" : descripcion;
        fTemas = fTipo === "examen" ? descripcion : "";
        fHora = hora24Tarea;

        var id = editandoId;
        if (!id) {
            id = "rec_" + Date.now() + "_" + Math.floor(Math.random() * 100000);
        }

        // Se guardan los avisos configurados (tanto relativos como de día y hora exacta)
        var avisosGuardados = [];
        var avisosProgramar = [];
        var ts = calcularTimestampLocal(fFecha, fHora);
        for (var i = 0; i < listaAvisos.length; i++) {
            var av = listaAvisos[i];
            if (av.tipo === "exacto" || (av.fecha && av.fecha !== "")) {
                var horaAv = (av.hora && av.hora.length >= 4) ? av.hora : "08:00";
                var tsEx = calcularTimestampLocal(av.fecha, horaAv);
                avisosGuardados.push({
                    tipo: "exacto",
                    fecha: av.fecha,
                    hora: horaAv,
                    d: 0,
                    h: 0,
                    etiqueta: av.etiqueta,
                    cuando: !isNaN(tsEx) ? tsEx : 0
                });
                if (!isNaN(tsEx)) {
                    avisosProgramar.push({
                        "tipo": "exacto",
                        "fecha": av.fecha,
                        "hora": horaAv,
                        "d": 0,
                        "h": 0,
                        "etiqueta": av.etiqueta,
                        "cuando": tsEx
                    });
                }
            } else {
                var dRel = av.d || 0;
                var hRel = av.h || 0;
                var cuandoRel = !isNaN(ts) ? (ts - (dRel * 86400000) - (hRel * 3600000)) : 0;
                avisosGuardados.push({
                    tipo: "relativo",
                    d: dRel,
                    h: hRel,
                    etiqueta: av.etiqueta,
                    cuando: cuandoRel
                });
                if (!isNaN(ts)) {
                    avisosProgramar.push({
                        "tipo": "relativo",
                        "d": dRel,
                        "h": hRel,
                        "etiqueta": av.etiqueta,
                        "cuando": cuandoRel
                    });
                }
            }
        }

        var registro = {
            "id": id,
            "tipo": fTipo,
            "materia": fMateria,
            "titulo": fTitulo,
            "descripcion": fDescripcion,
            "temas": fTemas,
            "fecha": fFecha,
            "hora": fHora,
            "avisos": avisosGuardados,
            "avisarDias": avisosGuardados.length > 0 ? (avisosGuardados[0].d || 0) : 0,
            "avisarHoras": avisosGuardados.length > 0 ? (avisosGuardados[0].h || 0) : 0,
            "hecho": false
        };

        // Se cancelan los avisos anteriores de este recordatorio
        if (editandoId !== "") {
            var viejos = (registroAnterior && registroAnterior.avisos) ? registroAnterior.avisos : [];
            if (viejos.length > 0) {
                daeClient.cancelarAvisosRecordatorio(id, viejos);
            }
        }

        daeClient.guardarRecordatorio(registro);

        // Se programan TODOS los avisos
        if (avisosProgramar.length > 0) {
            var tituloAviso = fTipo === "examen" ? "Examen: " + (fMateria || fTitulo)
                                                      : "Tarea: " + (fMateria || fTitulo);
            var cuerpo = fTipo === "examen"
                    ? ("Temas: " + (fTemas || "sin temas pendientes"))
                    : (fDescripcion || fTitulo);
            daeClient.programarAvisosRecordatorio(id, tituloAviso, cuerpo, avisosProgramar);
        }

        formularioAbierto = false;
    }

    // Añade un aviso por tiempo de antelación (evita duplicados)
    function agregarAviso(dias, horas) {
        for (var i = 0; i < listaAvisos.length; i++) {
            var item = listaAvisos[i];
            if (item.tipo !== "exacto" && !item.fecha && item.d === dias && item.h === horas) {
                return;
            }
        }
        var nueva = listaAvisos.slice();
        nueva.push({
            tipo: "relativo",
            d: dias,
            h: horas,
            etiqueta: "a" + nueva.length + "_" + dias + "_" + horas
        });
        listaAvisos = nueva;
    }

    // Añade un aviso con día y hora exacta (en 24h interna) elegidos por el usuario
    function agregarAvisoExacto(fechaIsoStr, hora24Str) {
        var fLimpia = (fechaIsoStr || fFecha || "").trim();
        var hLimpia = (hora24Str || "08:00").trim();
        if (fLimpia === "") {
            return;
        }
        for (var i = 0; i < listaAvisos.length; i++) {
            var item = listaAvisos[i];
            if ((item.tipo === "exacto" || item.fecha) && item.fecha === fLimpia && item.hora === hLimpia) {
                avisoExactoModificado = false;
                return;
            }
        }
        // Si es un recordatorio nuevo y solo tenía el aviso por defecto ("a0" de 1 día antes),
        // al añadir una fecha/hora exacta reemplazamos ese valor por defecto para que avise
        // exactamente cuando el usuario eligió.
        var nueva = listaAvisos.slice();
        if (editandoId === "" && nueva.length === 1 && nueva[0].etiqueta === "a0" && nueva[0].tipo !== "exacto") {
            nueva = [];
        }
        nueva.push({
            tipo: "exacto",
            fecha: fLimpia,
            hora: hLimpia,
            d: 0,
            h: 0,
            etiqueta: "ex_" + fLimpia + "_" + hLimpia.replace(":", "")
        });
        listaAvisos = nueva;
        avisoExactoModificado = false;
    }

    function quitarAviso(indice) {
        var nueva = listaAvisos.slice();
        if (indice >= 0 && indice < nueva.length) {
            nueva.splice(indice, 1);
        }
        listaAvisos = nueva;
    }

    function textoAviso(aviso) {
        if (!aviso) return "";
        if (aviso.tipo === "exacto" || (aviso.fecha && aviso.fecha !== "")) {
            return "El " + aviso.fecha + " a las " + formatearHora12(aviso.hora || "08:00");
        }
        var partes = [];
        if (aviso.d > 0) {
            partes.push(aviso.d === 1 ? "1 día antes" : (aviso.d + " días antes"));
        }
        if (aviso.h > 0) {
            partes.push(aviso.h === 1 ? "1 hora antes" : (aviso.h + " horas antes"));
        }
        if (partes.length === 0) {
            return "A la hora exacta";
        }
        return partes.join(" y ");
    }

    function resumenAvisoTarjeta(registro) {
        if (!registro) return "";
        if (registro.avisos && registro.avisos.length > 0) {
            var av0 = registro.avisos[0];
            var extra = registro.avisos.length > 1 ? (" (+" + (registro.avisos.length - 1) + ")") : "";
            if (av0.tipo === "exacto" || (av0.fecha && av0.fecha !== "")) {
                return "aviso " + av0.fecha + " · " + formatearHora12(av0.hora || "08:00") + extra;
            }
            if ((av0.d || 0) === 0 && (av0.h || 0) === 0) {
                return "aviso a la hora" + extra;
            }
            return "aviso " + (av0.d || 0) + "d " + (av0.h || 0) + "h" + extra;
        }
        return "aviso " + (registro.avisarDias || 0) + "d " + (registro.avisarHoras || 0) + "h";
    }

    function textoRestante(fecha, hora) {
        var ts = calcularTimestampLocal(fecha, hora);
        if (isNaN(ts)) return "";
        var dif = ts - new Date().getTime();
        var mins = Math.round(dif / 60000);
        if (mins < 0) return "Vencido";
        if (mins < 60) return "en " + mins + " min";
        var horas = Math.floor(mins / 60);
        if (horas < 24) return "en " + horas + " h";
        var dias = Math.floor(horas / 24);
        if (dias === 1) return "mañana";
        return "en " + dias + " días";
    }

    // =====================================================================
    // FONDO
    // =====================================================================
    Rectangle {
        anchors.fill: parent
        color: temaApp.fondoBase
    }

    // =====================================================================
    // CABECERA
    // =====================================================================
    Rectangle {
        id: cabRecordatorios
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 0
        height: 68
        color: temaApp.vidrio
        border.color: temaApp.bordeVidrio
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 18
            spacing: 12

            Rectangle {
                id: btnVolverRec
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 19
                color: temaApp.vidrio
                border.color: temaApp.bordeAlt
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
                    onClicked: rootRecordatorios.cerrar()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                spacing: 0

                Text {
                    text: "Tareas y Exámenes"
                    color: temaApp.textoPrincipal
                    font.pixelSize: 18
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: daeClient.recordatoriosPendientes + (daeClient.recordatoriosPendientes === 1 ? " pendiente" : " pendientes")
                    color: temaApp.textoSecundario
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Botón para crear uno nuevo
            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 20
                color: temaApp.secundario
                border.color: temaApp.acento
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    color: "white"
                    font.pixelSize: 22
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: rootRecordatorios.abrirFormulario(null)
                }
            }
        }
    }

    // =====================================================================
    // SWITCH DE PERMISO DE NOTIFICACIONES (Estilo Acceso Biométrico)
    // =====================================================================
    Rectangle {
        id: tarjetaPermisoNotif
        anchors.top: cabRecordatorios.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 10
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        height: 58
        radius: 18
        color: temaApp.panel
        border.color: temaApp.bordePanel
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 12
                color: temaApp.panelAlt
                border.color: temaApp.bordeAlt
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
                        ctx.lineWidth = 1.8;
                        ctx.lineCap = "round";
                        ctx.lineJoin = "round";
                        ctx.beginPath();
                        ctx.arc(9, 7.5, 4.5, Math.PI, 0, false);
                        ctx.lineTo(13.5, 12);
                        ctx.lineTo(15, 13.8);
                        ctx.lineTo(3, 13.8);
                        ctx.lineTo(4.5, 12);
                        ctx.closePath();
                        ctx.stroke();
                        ctx.beginPath();
                        ctx.arc(9, 15, 1.4, 0, Math.PI, false);
                        ctx.stroke();
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Permiso de Notificaciones"
                    color: temaApp.textoPrincipal
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: daeClient.permisoNotificacionesActivo
                          ? "Activo • Recibirás los avisos programados"
                          : "Activa el interruptor para permitir notificaciones"
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
                color: daeClient.permisoNotificacionesActivo ? temaApp.secundario : temaApp.panelAlt
                border.color: daeClient.permisoNotificacionesActivo ? temaApp.acento : temaApp.bordeAlt
                border.width: 1

                Behavior on color { ColorAnimation { duration: 180 } }

                Rectangle {
                    width: 20
                    height: 20
                    radius: 10
                    anchors.verticalCenter: parent.verticalCenter
                    x: daeClient.permisoNotificacionesActivo ? parent.width - width - 3 : 3
                    color: daeClient.permisoNotificacionesActivo ? "white" : (temaApp.esClaro ? "#64748b" : "white")

                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: daeClient.activarPermisoNotificaciones(!daeClient.permisoNotificacionesActivo)
                }
            }
        }
    }

    // =====================================================================
    // FILTROS
    // =====================================================================
    RowLayout {
        id: filaFiltrosRec
        anchors.top: tarjetaPermisoNotif.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 10
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 8

        Repeater {
            model: [
                { id: "pendientes", nombre: "Pendientes" },
                { id: "todos", nombre: "Todos" },
                { id: "hechos", nombre: "Completados" }
            ]

            delegate: Rectangle {
                property bool act: rootRecordatorios.filtro === modelData.id
                width: txtFiltro.implicitWidth + 24
                height: 32
                radius: 16
                color: act ? temaApp.primario : temaApp.panelAlt
                border.color: act ? temaApp.acentoVisible : temaApp.bordeAlt
                border.width: 1

                Text {
                    id: txtFiltro
                    anchors.centerIn: parent
                    text: modelData.nombre
                    color: act ? "white" : temaApp.textoSecundario
                    font.pixelSize: 11
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: rootRecordatorios.filtro = modelData.id
                }
            }
        }
    }

    // =====================================================================
    // LISTADO
    // =====================================================================
    Flickable {
        id: flickRec
        anchors.top: filaFiltrosRec.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        contentWidth: width
        contentHeight: colRec.implicitHeight + 130 + ventanaPrincipal.insetInferior
        clip: true
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.DragAndOvershootBounds
        pressDelay: 60

        ColumnLayout {
            id: colRec
            width: flickRec.width
            spacing: 10
            // Separación con la fila de filtros (Pendientes / Todos / Completados).
            // Se usa un espaciador porque los márgenes de Layout no se aplican
            // dentro de un Flickable.
            Layout.bottomMargin: 8

            // Separación con los botones de filtros
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 6
            }

            // Sin recordatorios
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: 142
                visible: rootRecordatorios.visibles.length === 0
                radius: 22
                color: temaApp.panel
                border.color: temaApp.bordePanel
                border.width: 1

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 46
                        height: 46
                        radius: 23
                        color: temaApp.panelAlt
                        border.color: temaApp.bordeAlt
                        border.width: 1

                        Canvas {
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            property color colorTrazo: temaApp.acentoVisible
                            onColorTrazoChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.strokeStyle = colorTrazo;
                                ctx.lineWidth = 1.9;
                                ctx.lineCap = "round";
                                ctx.lineJoin = "round";
                                // Cuerpo del calendario redondeado
                                ctx.beginPath();
                                ctx.roundedRect(2.5, 4.5, 17, 15, 3.5, 3.5);
                                ctx.stroke();
                                // Anillas superiores
                                ctx.beginPath();
                                ctx.moveTo(7, 2);
                                ctx.lineTo(7, 6);
                                ctx.moveTo(15, 2);
                                ctx.lineTo(15, 6);
                                // Línea divisoria superior
                                ctx.moveTo(2.5, 9);
                                ctx.lineTo(19.5, 9);
                                // Check central
                                ctx.moveTo(8, 14);
                                ctx.lineTo(10.3, 16.3);
                                ctx.lineTo(14.5, 12);
                                ctx.stroke();
                            }
                        }
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: rootRecordatorios.filtro === "hechos" ? "Todavía no has completado nada"
                                                      : "Sin recordatorios por ahora"
                        color: temaApp.textoPrincipal
                        font.pixelSize: 15
                        font.bold: true
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Pulsa + para programar una tarea o un examen"
                        color: temaApp.textoMuted
                        font.pixelSize: 11
                    }
                }
            }

            Repeater {
                model: rootRecordatorios.visibles

                delegate: Rectangle {
                    id: tarjetaRec
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    Layout.preferredHeight: colTarjeta.implicitHeight + 26
                    radius: 22
                    color: temaApp.panel
                    border.color: modelData.hecho ? temaApp.bordePanel : temaApp.acento
                    border.width: modelData.hecho ? 1 : 1.8
                    opacity: modelData.hecho ? 0.6 : 1
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    ColumnLayout {
                        id: colTarjeta
                        anchors.fill: parent
                        anchors.margins: 13
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            // Etiqueta del tipo
                            Rectangle {
                                Layout.preferredWidth: lblTipoRec.implicitWidth + 16
                                Layout.preferredHeight: 22
                                radius: 11
                                color: modelData.tipo === "examen" ? "#dc2626" : temaApp.secundario
                                Text {
                                    id: lblTipoRec
                                    anchors.centerIn: parent
                                    text: modelData.tipo === "examen" ? "EXAMEN" : "TAREA"
                                    color: "white"
                                    font.pixelSize: 9
                                    font.bold: true
                                    font.letterSpacing: 0.6
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.materia !== "" ? modelData.materia : "Sin materia"
                                color: temaApp.textoPrincipal
                                font.pixelSize: 13
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            ColumnLayout {
                                Layout.alignment: Qt.AlignRight
                                spacing: 0

                                Text {
                                    Layout.alignment: Qt.AlignRight
                                    text: rootRecordatorios.textoRestante(modelData.fecha, modelData.hora)
                                    color: modelData.hecho ? temaApp.textoMuted : temaApp.acentoVisible
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                                Text {
                                    Layout.alignment: Qt.AlignRight
                                    text: rootRecordatorios.resumenAvisoTarjeta(modelData)
                                    color: temaApp.textoMuted
                                    font.pixelSize: 9
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: modelData.titulo !== ""
                            text: modelData.titulo
                            color: temaApp.textoSecundario
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }

                        // Temas a estudiar (exámenes)
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: filaTemasRec.implicitHeight + 16
                            visible: modelData.tipo === "examen" && modelData.temas !== ""
                            radius: 12
                            color: temaApp.panelAlt
                            border.color: temaApp.bordeAlt
                            border.width: 1

                            RowLayout {
                                id: filaTemasRec
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                Canvas {
                                    Layout.preferredWidth: 15
                                    Layout.preferredHeight: 15
                                    Layout.alignment: Qt.AlignTop
                                    property color colorTrazo: temaApp.acentoVisible
                                    onColorTrazoChanged: requestPaint()
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.reset();
                                        ctx.strokeStyle = colorTrazo;
                                        ctx.lineWidth = 1.6;
                                        ctx.lineCap = "round";
                                        ctx.lineJoin = "round";
                                        ctx.beginPath();
                                        ctx.moveTo(2, 3);
                                        ctx.lineTo(7.5, 4.5);
                                        ctx.lineTo(13, 3);
                                        ctx.lineTo(13, 12);
                                        ctx.lineTo(7.5, 13.5);
                                        ctx.lineTo(2, 12);
                                        ctx.closePath();
                                        ctx.moveTo(7.5, 4.5);
                                        ctx.lineTo(7.5, 13.5);
                                        ctx.stroke();
                                    }
                                }

                                Text {
                                    id: txtTemasRec
                                    Layout.fillWidth: true
                                    text: modelData.temas
                                    color: temaApp.textoSecundario
                                    font.pixelSize: 11
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        // Descripción de la tarea
                        Text {
                            Layout.fillWidth: true
                            visible: modelData.tipo === "tarea" && modelData.descripcion !== ""
                            text: modelData.descripcion
                            color: temaApp.textoSecundario
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            // Fecha y hora con iconos vectoriales modernos
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 5

                                Canvas {
                                    Layout.preferredWidth: 14
                                    Layout.preferredHeight: 14
                                    property color colorTrazo: temaApp.textoMuted
                                    onColorTrazoChanged: requestPaint()
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.reset();
                                        ctx.strokeStyle = colorTrazo;
                                        ctx.lineWidth = 1.5;
                                        ctx.lineCap = "round";
                                        ctx.lineJoin = "round";
                                        ctx.beginPath();
                                        ctx.roundedRect(1.5, 2.8, 11, 9.7, 2, 2);
                                        ctx.stroke();
                                        ctx.beginPath();
                                        ctx.moveTo(4.5, 1.2);
                                        ctx.lineTo(4.5, 3.8);
                                        ctx.moveTo(9.5, 1.2);
                                        ctx.lineTo(9.5, 3.8);
                                        ctx.moveTo(1.5, 5.8);
                                        ctx.lineTo(12.5, 5.8);
                                        ctx.stroke();
                                    }
                                }

                                Text {
                                    text: modelData.fecha
                                    color: temaApp.textoMuted
                                    font.pixelSize: 10
                                    font.bold: true
                                }

                                Text {
                                    text: "·"
                                    color: temaApp.textoMuted
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                Canvas {
                                    Layout.preferredWidth: 14
                                    Layout.preferredHeight: 14
                                    property color colorTrazo: temaApp.textoMuted
                                    onColorTrazoChanged: requestPaint()
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.reset();
                                        ctx.strokeStyle = colorTrazo;
                                        ctx.lineWidth = 1.5;
                                        ctx.lineCap = "round";
                                        ctx.lineJoin = "round";
                                        ctx.beginPath();
                                        ctx.arc(7, 7, 5.4, 0, Math.PI * 2);
                                        ctx.stroke();
                                        ctx.beginPath();
                                        ctx.moveTo(7, 4.2);
                                        ctx.lineTo(7, 7.2);
                                        ctx.lineTo(9.2, 8.5);
                                        ctx.stroke();
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: rootRecordatorios.formatearHora12(modelData.hora)
                                    color: temaApp.textoMuted
                                    font.pixelSize: 10
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                            }

                            // 1. Marcar como hecho (Icono Check moderno)
                            Rectangle {
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 30
                                radius: 15
                                color: modelData.hecho ? temaApp.secundario : temaApp.panelAlt
                                border.color: modelData.hecho ? temaApp.secundario : temaApp.bordeAlt
                                border.width: 1

                                Canvas {
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 16
                                    property color colorTrazo: modelData.hecho ? "#ffffff" : temaApp.textoSecundario
                                    onColorTrazoChanged: requestPaint()
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.reset();
                                        ctx.strokeStyle = colorTrazo;
                                        ctx.lineWidth = 2.0;
                                        ctx.lineCap = "round";
                                        ctx.lineJoin = "round";
                                        ctx.beginPath();
                                        ctx.moveTo(3.5, 8.5);
                                        ctx.lineTo(6.8, 11.8);
                                        ctx.lineTo(12.8, 4.8);
                                        ctx.stroke();
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: daeClient.alternarRecordatorioHecho(modelData.id)
                                }
                            }

                            // 2. Editar (Icono Lápiz moderno en vector, nunca falla la fuente)
                            Rectangle {
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 30
                                radius: 15
                                color: temaApp.panelAlt
                                border.color: temaApp.bordeAlt
                                border.width: 1

                                Canvas {
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 16
                                    property color colorTrazo: temaApp.textoSecundario
                                    onColorTrazoChanged: requestPaint()
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.reset();
                                        ctx.strokeStyle = colorTrazo;
                                        ctx.lineWidth = 1.7;
                                        ctx.lineCap = "round";
                                        ctx.lineJoin = "round";
                                        ctx.beginPath();
                                        // Cuerpo del lápiz
                                        ctx.moveTo(10.5, 2.5);
                                        ctx.lineTo(13.5, 5.5);
                                        ctx.lineTo(6, 13);
                                        ctx.lineTo(2.5, 13.5);
                                        ctx.lineTo(3, 10);
                                        ctx.closePath();
                                        // Detalle de punta superior
                                        ctx.moveTo(9, 4);
                                        ctx.lineTo(12, 7);
                                        ctx.stroke();
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: rootRecordatorios.abrirFormulario(modelData)
                                }
                            }

                            // 3. Aviso inmediato / probar notificación (Icono Campana moderno en vector)
                            Rectangle {
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 30
                                radius: 15
                                color: temaApp.panelAlt
                                border.color: temaApp.bordeAlt
                                border.width: 1

                                Canvas {
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 16
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
                                        // Cúpula y falda de la campana
                                        ctx.moveTo(8, 2);
                                        ctx.lineTo(8, 3);
                                        ctx.moveTo(4.5, 7);
                                        ctx.bezierCurveTo(4.5, 4.2, 11.5, 4.2, 11.5, 7);
                                        ctx.lineTo(12.2, 10.8);
                                        ctx.lineTo(13.2, 11.8);
                                        ctx.lineTo(2.8, 11.8);
                                        ctx.lineTo(3.8, 10.8);
                                        ctx.closePath();
                                        ctx.stroke();
                                        // Badajo inferior
                                        ctx.beginPath();
                                        ctx.arc(8, 12.6, 1.3, 0.1 * Math.PI, 0.9 * Math.PI);
                                        ctx.stroke();
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        daeClient.avisarAhoraRecordatorio(modelData.id,
                                                modelData.titulo !== "" ? modelData.titulo : "Recordatorio",
                                                modelData.temas !== "" ? modelData.temas : modelData.descripcion);
                                    }
                                }
                            }

                            // 4. Eliminar (Icono Papelera moderno en vector)
                            Rectangle {
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 30
                                radius: 15
                                color: temaApp.panelAlt
                                border.color: temaApp.bordeAlt
                                border.width: 1

                                Canvas {
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 16
                                    property color colorTrazo: "#dc2626"
                                    onColorTrazoChanged: requestPaint()
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.reset();
                                        ctx.strokeStyle = colorTrazo;
                                        ctx.lineWidth = 1.65;
                                        ctx.lineCap = "round";
                                        ctx.lineJoin = "round";
                                        ctx.beginPath();
                                        // Tapa y asa
                                        ctx.moveTo(2.8, 4.5);
                                        ctx.lineTo(13.2, 4.5);
                                        ctx.moveTo(6, 4.5);
                                        ctx.lineTo(6.5, 2.5);
                                        ctx.lineTo(9.5, 2.5);
                                        ctx.lineTo(10, 4.5);
                                        // Cuerpo
                                        ctx.moveTo(4.2, 4.5);
                                        ctx.lineTo(4.8, 13.2);
                                        ctx.lineTo(11.2, 13.2);
                                        ctx.lineTo(11.8, 4.5);
                                        // Líneas verticales internas
                                        ctx.moveTo(6.8, 7);
                                        ctx.lineTo(6.8, 11);
                                        ctx.moveTo(9.2, 7);
                                        ctx.lineTo(9.2, 11);
                                        ctx.stroke();
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: daeClient.eliminarRecordatorio(modelData.id)
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 10 }
        }
    }

    // =====================================================================
    // FORMULARIO (alta / edición)
    // =====================================================================
    Rectangle {
        id: overlayFormulario
        anchors.fill: parent
        visible: rootRecordatorios.formularioAbierto
        color: temaApp.fondoBase
        z: 120

        MouseArea { anchors.fill: parent }

        // Cabecera fija del formulario
        RowLayout {
            id: cabFormulario
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 14
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            height: 44
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 19
                color: temaApp.vidrio
                border.color: temaApp.bordeAlt
                border.width: 1

                Canvas {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    property color colorTrazo: temaApp.textoPrincipal
                    onColorTrazoChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.strokeStyle = colorTrazo;
                        ctx.lineWidth = 2.1;
                        ctx.lineCap = "round";
                        ctx.beginPath();
                        ctx.moveTo(2, 2);
                        ctx.lineTo(12, 12);
                        ctx.moveTo(12, 2);
                        ctx.lineTo(2, 12);
                        ctx.stroke();
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Qt.inputMethod.hide();
                        rootRecordatorios.formularioAbierto = false;
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: rootRecordatorios.editandoId !== "" ? "Editar recordatorio" : "Nuevo recordatorio"
                color: temaApp.textoPrincipal
                font.pixelSize: 17
                font.bold: true
                elide: Text.ElideRight
            }

            Rectangle {
                Layout.preferredWidth: 84
                Layout.preferredHeight: 38
                radius: 19
                color: temaApp.secundario
                border.color: temaApp.acento
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "Guardar"
                    color: "white"
                    font.pixelSize: 12
                    font.bold: true
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Qt.inputMethod.hide();
                        rootRecordatorios.guardarRegistro();
                    }
                }
            }
        }

        // Contenido desplazable del formulario (anclado directamente para garantizar el scroll)
        Flickable {
            id: flickFormulario
            anchors.top: cabFormulario.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.topMargin: 10
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.bottomMargin: ventanaPrincipal.insetInferior + 8
            contentWidth: width
            contentHeight: colCamposForm.implicitHeight + (daeClient.tecladoVisible ? Math.max(260, daeClient.tecladoAltura + 80) : 140)
            clip: true
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.DragAndOvershootBounds
            pressDelay: 60

            ColumnLayout {
                id: colCamposForm
                width: flickFormulario.width
                spacing: 12

                    // Mensaje de error (si no se pudo guardar)
                    Text {
                        Layout.fillWidth: true
                        visible: rootRecordatorios.mensajeError !== ""
                        text: rootRecordatorios.mensajeError
                        color: rootRecordatorios.colorError
                        font.pixelSize: 11
                        font.bold: true
                        wrapMode: Text.WordWrap
                    }

                    // Tipo: tarea o examen (con iconos vectoriales modernos)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: [
                                { id: "tarea", nombre: "Tarea" },
                                { id: "examen", nombre: "Examen" }
                            ]

                            delegate: Rectangle {
                                property bool act: rootRecordatorios.fTipo === modelData.id
                                Layout.fillWidth: true
                                Layout.preferredHeight: 42
                                radius: 14
                                color: act ? temaApp.primario : "transparent"
                                border.color: act ? temaApp.acentoVisible : temaApp.bordeAlt
                                border.width: 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 7

                                    Canvas {
                                        Layout.preferredWidth: 16
                                        Layout.preferredHeight: 16
                                        property color colorTrazo: act ? "#ffffff" : temaApp.textoSecundario
                                        onColorTrazoChanged: requestPaint()
                                        onPaint: {
                                            var ctx = getContext("2d");
                                            ctx.reset();
                                            ctx.strokeStyle = colorTrazo;
                                            ctx.lineWidth = 1.7;
                                            ctx.lineCap = "round";
                                            ctx.lineJoin = "round";
                                            ctx.beginPath();
                                            if (modelData.id === "tarea") {
                                                ctx.roundedRect(3, 2, 10, 12, 2, 2);
                                                ctx.stroke();
                                                ctx.beginPath();
                                                ctx.moveTo(5.5, 6);
                                                ctx.lineTo(10.5, 6);
                                                ctx.moveTo(5.5, 9);
                                                ctx.lineTo(9, 9);
                                                ctx.stroke();
                                            } else {
                                                ctx.moveTo(2, 3.5);
                                                ctx.lineTo(8, 5);
                                                ctx.lineTo(14, 3.5);
                                                ctx.lineTo(14, 12.5);
                                                ctx.lineTo(8, 14);
                                                ctx.lineTo(2, 12.5);
                                                ctx.closePath();
                                                ctx.moveTo(8, 5);
                                                ctx.lineTo(8, 14);
                                                ctx.stroke();
                                            }
                                        }
                                    }

                                    Text {
                                        text: modelData.nombre
                                        color: act ? "#ffffff" : temaApp.textoSecundario
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: rootRecordatorios.fTipo = modelData.id
                                }
                            }
                        }
                    }

                    // Materia: se puede escribir o elegir de la lista desplegable
                    Rectangle {
                        id: recMateria
                        Layout.fillWidth: true
                        Layout.preferredHeight: 46
                        radius: 14
                        color: rootRecordatorios.campoFondo
                        border.color: (campoMateria.activeFocus || rootRecordatorios.listaMateriasAbierta)
                                      ? temaApp.acento : rootRecordatorios.campoBorde
                        border.width: 1

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 40
                            verticalAlignment: Text.AlignVCenter
                            visible: campoMateria.text === "" && !campoMateria.activeFocus
                            text: rootRecordatorios.materiasDisponibles.length > 0
                                  ? "Elige una de las materias que cursas..."
                                  : "Materia (ej. Fundamentos de Programación)"
                            color: rootRecordatorios.campoPlaceholder
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                        TextField {
                            id: campoMateria
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 40
                            verticalAlignment: TextInput.AlignVCenter
                            color: rootRecordatorios.campoTexto
                            font.pixelSize: 13
                            background: Item {}
                            onAccepted: rootRecordatorios.fMateria = text
                        }

                        Canvas {
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14
                            height: 8
                            property color colorTrazo: rootRecordatorios.campoPlaceholder
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.strokeStyle = colorTrazo;
                                ctx.lineWidth = 1.8;
                                ctx.lineCap = "round";
                                ctx.lineJoin = "round";
                                ctx.beginPath();
                                ctx.moveTo(2, 2);
                                ctx.lineTo(7, 6.5);
                                ctx.lineTo(12, 2);
                                ctx.stroke();
                            }
                        }

                        MouseArea {
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            width: 34
                            height: 40
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!rootRecordatorios.listaMateriasAbierta) {
                                    rootRecordatorios.refrescarMaterias();
                                }
                                rootRecordatorios.listaMateriasAbierta =
                                        !rootRecordatorios.listaMateriasAbierta;
                            }
                        }
                    }

                    // Desplegable con las materias que cursa el estudiante
                    Rectangle {
                        id: panelMaterias
                        visible: rootRecordatorios.listaMateriasAbierta
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(220, Math.max(44, rootRecordatorios.materiasDisponibles.length * 40 + 10))
                        radius: 14
                        color: rootRecordatorios.listaFondo
                        border.color: rootRecordatorios.campoBorde
                        border.width: 1
                        z: 20

                        Flickable {
                            anchors.fill: parent
                            anchors.margins: 6
                            contentWidth: width
                            contentHeight: listaMat.implicitHeight + 8
                            clip: true
                            flickableDirection: Flickable.VerticalFlick
                            boundsBehavior: Flickable.DragAndOvershootBounds
                            pressDelay: 50

                            ColumnLayout {
                                id: listaMat
                                width: parent.width
                                spacing: 2

                                Repeater {
                                    model: rootRecordatorios.materiasDisponibles

                                    delegate: Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 38
                                        radius: 10
                                        color: "transparent"

                                        Text {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 30
                                            verticalAlignment: Text.AlignVCenter
                                            text: modelData.texto
                                            color: rootRecordatorios.campoTexto
                                            font.pixelSize: 13
                                            elide: Text.ElideRight
                                        }

                                        Rectangle {
                                            visible: campoMateria.text === modelData.materia
                                            anchors.right: parent.right
                                            anchors.rightMargin: 8
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 18
                                            height: 18
                                            radius: 9
                                            color: temaApp.secundario

                                            Canvas {
                                                anchors.centerIn: parent
                                                width: 10
                                                height: 10
                                                onPaint: {
                                                    var ctx = getContext("2d");
                                                    ctx.reset();
                                                    ctx.strokeStyle = "#ffffff";
                                                    ctx.lineWidth = 1.8;
                                                    ctx.lineCap = "round";
                                                    ctx.lineJoin = "round";
                                                    ctx.beginPath();
                                                    ctx.moveTo(2, 5.2);
                                                    ctx.lineTo(4.2, 7.5);
                                                    ctx.lineTo(8.2, 2.8);
                                                    ctx.stroke();
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                campoMateria.text = modelData.materia;
                                                rootRecordatorios.fMateria = modelData.materia;
                                                rootRecordatorios.listaMateriasAbierta = false;
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 38
                                    radius: 10
                                    color: "transparent"
                                    visible: rootRecordatorios.materiasDisponibles.length === 0

                                    Text {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        verticalAlignment: Text.AlignVCenter
                                        text: "No se pudo cargar tu horario: escribe el nombre"
                                        color: rootRecordatorios.campoPlaceholder
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 46
                        radius: 14
                        color: rootRecordatorios.campoFondo
                        border.color: rootRecordatorios.campoBorde
                        border.width: 1
                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: Text.AlignVCenter
                            visible: campoTitulo.text === "" && !campoTitulo.activeFocus
                            text: rootRecordatorios.fTipo === "examen" ? "Título (ej. Parcial 2)" : "Tarea (ej. Taller 3)"
                            color: rootRecordatorios.campoPlaceholder
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                        TextField {
                            id: campoTitulo
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: TextInput.AlignVCenter
                            color: rootRecordatorios.campoTexto
                            font.pixelSize: 13
                            background: Item {}
                            onAccepted: rootRecordatorios.fTitulo = text
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: rootRecordatorios.fTipo === "examen" ? 96 : 70
                        radius: 14
                        color: rootRecordatorios.campoFondo
                        border.color: rootRecordatorios.campoBorde
                        border.width: 1
                        Text {
                            anchors.fill: parent
                            anchors.margins: 10
                            visible: campoDescripcion.text === "" && campoDescripcion.activeFocus === false
                            text: rootRecordatorios.fTipo === "examen" ? "Temas a estudiar (uno por línea)" : "Descripción de la tarea"
                            color: rootRecordatorios.campoPlaceholder
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                        TextEdit {
                            id: campoDescripcion
                            anchors.fill: parent
                            anchors.margins: 10
                            wrapMode: TextEdit.Wrap
                            color: rootRecordatorios.campoTexto
                            font.pixelSize: 12
                        }
                    }

                    // Fecha y hora de la tarea o examen
                    Text {
                        text: rootRecordatorios.fTipo === "examen" ? "Fecha y hora del examen" : "Fecha y hora de entrega"
                        color: temaApp.textoSecundario
                        font.pixelSize: 12
                        font.bold: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            radius: 14
                            color: rootRecordatorios.campoFondo
                            border.color: rootRecordatorios.campoBorde
                            border.width: 1
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 6

                                Canvas {
                                    Layout.preferredWidth: 16
                                    Layout.preferredHeight: 16
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.reset();
                                        ctx.strokeStyle = rootRecordatorios.campoTrazo;
                                        ctx.lineWidth = 1.6;
                                        ctx.lineCap = "round";
                                        ctx.lineJoin = "round";
                                        ctx.beginPath();
                                        ctx.roundedRect(2, 3, 12, 11, 2.2, 2.2);
                                        ctx.stroke();
                                        ctx.beginPath();
                                        ctx.moveTo(5, 1.5);
                                        ctx.lineTo(5, 4.2);
                                        ctx.moveTo(11, 1.5);
                                        ctx.lineTo(11, 4.2);
                                        ctx.moveTo(2, 6.5);
                                        ctx.lineTo(14, 6.5);
                                        ctx.stroke();
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: rootRecordatorios.fFecha
                                    color: rootRecordatorios.campoTexto
                                    font.pixelSize: 12
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: "cambiar"
                                    color: temaApp.acentoVisible
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: rootRecordatorios.abrirCalendarioPara("tarea")
                            }
                        }

                        // Hora en formato 12h + selector AM / PM
                        Rectangle {
                            Layout.preferredWidth: 158
                            Layout.preferredHeight: 46
                            radius: 14
                            color: rootRecordatorios.campoFondo
                            border.color: rootRecordatorios.campoBorde
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 6
                                spacing: 4

                                Canvas {
                                    Layout.preferredWidth: 14
                                    Layout.preferredHeight: 14
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.reset();
                                        ctx.strokeStyle = rootRecordatorios.campoTrazo;
                                        ctx.lineWidth = 1.6;
                                        ctx.lineCap = "round";
                                        ctx.lineJoin = "round";
                                        ctx.beginPath();
                                        ctx.arc(7, 7, 5.4, 0, Math.PI * 2);
                                        ctx.stroke();
                                        ctx.beginPath();
                                        ctx.moveTo(7, 4.2);
                                        ctx.lineTo(7, 7.2);
                                        ctx.lineTo(9.2, 8.5);
                                        ctx.stroke();
                                    }
                                }

                                TextField {
                                    id: campoHora
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: rootRecordatorios.campoTexto
                                    font.pixelSize: 13
                                    font.bold: true
                                    inputMask: "00:00"
                                    background: Item {}
                                    onTextChanged: {
                                        if (!rootRecordatorios.cargandoFormulario) {
                                            rootRecordatorios.fHora12 = text;
                                        }
                                    }
                                }

                                // Selector AM / PM
                                RowLayout {
                                    spacing: 2

                                    Repeater {
                                        model: ["AM", "PM"]
                                        delegate: Rectangle {
                                            required property string modelData
                                            property bool activo: rootRecordatorios.fAmPm === modelData
                                            Layout.preferredWidth: 30
                                            Layout.preferredHeight: 30
                                            radius: 8
                                            color: activo ? temaApp.secundario : "transparent"
                                            border.color: activo ? temaApp.secundario : temaApp.bordeAlt
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData
                                                color: parent.activo ? "#ffffff" : temaApp.textoSecundario
                                                font.pixelSize: 10
                                                font.bold: true
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: rootRecordatorios.fAmPm = modelData
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ---------------------------------------------------------------
                    // AVISOS: por antelación rápida o eligiendo día y hora exacta
                    // ---------------------------------------------------------------
                    Text {
                        text: "Avisos de notificación"
                        color: temaApp.textoSecundario
                        font.pixelSize: 12
                        font.bold: true
                    }

                    // Avisos ya programados
                    Repeater {
                        model: rootRecordatorios.listaAvisos

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            radius: 12
                            color: rootRecordatorios.chipFondo
                            border.color: temaApp.acentoVisible
                            border.width: 1

                            RowLayout {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.right: btnQuitarAviso.left
                                anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8

                                Canvas {
                                    Layout.preferredWidth: 15
                                    Layout.preferredHeight: 15
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.reset();
                                        ctx.strokeStyle = rootRecordatorios.chipTexto;
                                        ctx.lineWidth = 1.6;
                                        ctx.lineCap = "round";
                                        ctx.lineJoin = "round";
                                        ctx.beginPath();
                                        ctx.moveTo(7.5, 1.8);
                                        ctx.lineTo(7.5, 2.8);
                                        ctx.moveTo(4.2, 6.5);
                                        ctx.bezierCurveTo(4.2, 3.8, 10.8, 3.8, 10.8, 6.5);
                                        ctx.lineTo(11.4, 10);
                                        ctx.lineTo(12.4, 11);
                                        ctx.lineTo(2.6, 11);
                                        ctx.lineTo(3.6, 10);
                                        ctx.closePath();
                                        ctx.stroke();
                                        ctx.beginPath();
                                        ctx.arc(7.5, 11.8, 1.2, 0.1 * Math.PI, 0.9 * Math.PI);
                                        ctx.stroke();
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: rootRecordatorios.textoAviso(modelData)
                                    color: rootRecordatorios.chipTexto
                                    font.pixelSize: 12
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                            }

                            // Quitar este aviso
                            Rectangle {
                                id: btnQuitarAviso
                                anchors.right: parent.right
                                anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                width: 28
                                height: 28
                                radius: 14
                                color: "transparent"

                                Canvas {
                                    anchors.centerIn: parent
                                    width: 12
                                    height: 12
                                    property color colorTrazo: rootRecordatorios.chipTexto
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.reset();
                                        ctx.strokeStyle = colorTrazo;
                                        ctx.lineWidth = 2;
                                        ctx.lineCap = "round";
                                        ctx.beginPath();
                                        ctx.moveTo(1.5, 1.5);
                                        ctx.lineTo(10.5, 10.5);
                                        ctx.moveTo(10.5, 1.5);
                                        ctx.lineTo(1.5, 10.5);
                                        ctx.stroke();
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: rootRecordatorios.quitarAviso(index)
                                }
                            }
                        }
                    }

                    // 1. Selector rápido por tiempo antes
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 46
                        radius: 14
                        color: rootRecordatorios.campoFondo
                        border.color: rootRecordatorios.campoBorde
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 5

                            Text {
                                text: "Antes:"
                                color: rootRecordatorios.campoPlaceholder
                                font.pixelSize: 11
                            }

                            Repeater {
                                model: [
                                    { d: 0, h: 0, txt: "A la hora" },
                                    { d: 0, h: 1, txt: "1 h" },
                                    { d: 1, h: 0, txt: "1 día" },
                                    { d: 3, h: 0, txt: "3 días" },
                                    { d: 7, h: 0, txt: "1 sem." }
                                ]

                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.preferredWidth: txtAviso.implicitWidth + 12
                                    Layout.preferredHeight: 28
                                    radius: 14
                                    color: "transparent"
                                    border.color: temaApp.bordeAlt
                                    border.width: 1

                                    Text {
                                        id: txtAviso
                                        anchors.centerIn: parent
                                        text: modelData.txt
                                        color: rootRecordatorios.campoTexto
                                        font.pixelSize: 10
                                        font.bold: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: rootRecordatorios.agregarAviso(modelData.d, modelData.h)
                                    }
                                }
                            }
                        }
                    }

                    // 2. Selector de día y hora exacta del aviso (en formato 12h + AM/PM)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: colAvisoExacto.implicitHeight + 20
                        radius: 14
                        color: rootRecordatorios.subPanelFondo
                        border.color: rootRecordatorios.campoBorde
                        border.width: 1

                        ColumnLayout {
                            id: colAvisoExacto
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            Text {
                                Layout.fillWidth: true
                                text: "O elegir día y hora exacta del aviso (12 h AM/PM):"
                                color: rootRecordatorios.campoEtiqueta
                                font.pixelSize: 11
                                font.bold: true
                            }

                            // Fila 1: selector de Día del aviso + botón Añadir
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 38
                                    radius: 11
                                    color: rootRecordatorios.subCampoFondo
                                    border.color: temaApp.bordeAlt
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 6

                                        Canvas {
                                            Layout.preferredWidth: 14
                                            Layout.preferredHeight: 14
                                            onPaint: {
                                                var ctx = getContext("2d");
                                                ctx.reset();
                                                ctx.strokeStyle = rootRecordatorios.campoTrazo;
                                                ctx.lineWidth = 1.5;
                                                ctx.lineCap = "round";
                                                ctx.lineJoin = "round";
                                                ctx.beginPath();
                                                ctx.roundedRect(1.5, 2.8, 11, 9.7, 2, 2);
                                                ctx.stroke();
                                                ctx.beginPath();
                                                ctx.moveTo(4.5, 1.2);
                                                ctx.lineTo(4.5, 3.8);
                                                ctx.moveTo(9.5, 1.2);
                                                ctx.lineTo(9.5, 3.8);
                                                ctx.moveTo(1.5, 5.8);
                                                ctx.lineTo(12.5, 5.8);
                                                ctx.stroke();
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: rootRecordatorios.avisoFechaExacta !== "" ? rootRecordatorios.avisoFechaExacta : rootRecordatorios.fFecha
                                            color: rootRecordatorios.campoTexto
                                            font.pixelSize: 12
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: "cambiar día"
                                            color: temaApp.acentoVisible
                                            font.pixelSize: 10
                                            font.bold: true
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: rootRecordatorios.abrirCalendarioPara("aviso")
                                    }
                                }
                            }

                            // Fila 2: Hora (01:00 - 12:59) + AM / PM + Botón "+ Añadir"
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 40
                                    radius: 11
                                    color: rootRecordatorios.subCampoFondo
                                    border.color: temaApp.bordeAlt
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 6
                                        spacing: 6

                                        Canvas {
                                            Layout.preferredWidth: 14
                                            Layout.preferredHeight: 14
                                            onPaint: {
                                                var ctx = getContext("2d");
                                                ctx.reset();
                                                ctx.strokeStyle = rootRecordatorios.campoTrazo;
                                                ctx.lineWidth = 1.5;
                                                ctx.lineCap = "round";
                                                ctx.lineJoin = "round";
                                                ctx.beginPath();
                                                ctx.arc(7, 7, 5.4, 0, Math.PI * 2);
                                                ctx.stroke();
                                                ctx.beginPath();
                                                ctx.moveTo(7, 4.2);
                                                ctx.lineTo(7, 7.2);
                                                ctx.lineTo(9.2, 8.5);
                                                ctx.stroke();
                                            }
                                        }

                                        TextField {
                                            id: campoHoraAviso
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            verticalAlignment: TextInput.AlignVCenter
                                            color: rootRecordatorios.campoTexto
                                            font.pixelSize: 13
                                            font.bold: true
                                            inputMask: "00:00"
                                            text: rootRecordatorios.avisoHoraExacta
                                            background: Item {}
                                            onActiveFocusChanged: {
                                                if (activeFocus) {
                                                    Qt.callLater(function() {
                                                        var maxScroll = Math.max(0, colCamposForm.implicitHeight - flickFormulario.height + 160);
                                                        if (flickFormulario.contentY < maxScroll) {
                                                            flickFormulario.contentY = maxScroll;
                                                        }
                                                    });
                                                }
                                            }
                                            onTextChanged: {
                                                if (!rootRecordatorios.cargandoFormulario) {
                                                    rootRecordatorios.avisoHoraExacta = text;
                                                    rootRecordatorios.avisoExactoModificado = true;
                                                }
                                            }
                                            onAccepted: {
                                                rootRecordatorios.avisoHoraExacta = text;
                                                rootRecordatorios.avisoExactoModificado = true;
                                            }
                                        }

                                        // Selector AM / PM del aviso
                                        RowLayout {
                                            spacing: 3

                                            Repeater {
                                                model: ["AM", "PM"]
                                                delegate: Rectangle {
                                                    required property string modelData
                                                    property bool activo: rootRecordatorios.avisoAmPm === modelData
                                                    Layout.preferredWidth: 34
                                                    Layout.preferredHeight: 28
                                                    radius: 8
                                                    color: activo ? temaApp.secundario : "transparent"
                                                    border.color: activo ? temaApp.secundario : temaApp.bordeAlt
                                                    border.width: 1

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: modelData
                                                        color: parent.activo ? "#ffffff" : temaApp.textoSecundario
                                                        font.pixelSize: 10
                                                        font.bold: true
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            rootRecordatorios.avisoAmPm = modelData;
                                                            rootRecordatorios.avisoExactoModificado = true;
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // Botón para añadir el aviso exacto
                                Rectangle {
                                    Layout.preferredWidth: 82
                                    Layout.preferredHeight: 40
                                    radius: 11
                                    color: temaApp.secundario
                                    border.color: temaApp.acento
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "+ Añadir"
                                        color: rootRecordatorios.subCampoFondo
                                        font.pixelSize: 11
                                        font.bold: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Qt.inputMethod.commit();
                                            var h24 = rootRecordatorios.aHora24(campoHoraAviso.text, rootRecordatorios.avisoAmPm);
                                            rootRecordatorios.agregarAvisoExacto(
                                                rootRecordatorios.avisoFechaExacta !== "" ? rootRecordatorios.avisoFechaExacta : rootRecordatorios.fFecha,
                                                h24);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Espacio final para que todos los controles inferiores queden siempre a la vista al hacer scroll
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
                    }
                }
            }
        }

    // =====================================================================
    // CALENDARIO (selector de fecha para la tarea/examen o para el aviso)
    // =====================================================================
    Rectangle {
        id: overlayCalendario
        anchors.fill: parent
        visible: rootRecordatorios.calendarioAbierto
        color: temaApp.fondoBase
        z: 130

        MouseArea { anchors.fill: parent }

        Rectangle {
            id: panelCalendario
            width: parent.width - 40
            height: 396
            radius: 26
            color: temaApp.panel
            border.color: temaApp.bordeAlt
            border.width: 1
            anchors.centerIn: parent

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    text: rootRecordatorios.modoCalendario === "aviso"
                          ? "Selecciona el día exacto del aviso"
                          : "Selecciona la fecha de la tarea o examen"
                    color: temaApp.acentoVisible
                    font.pixelSize: 12
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        radius: 17
                        color: temaApp.panelAlt
                        border.color: temaApp.bordeAlt
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "‹"
                            color: temaApp.textoPrincipal
                            font.pixelSize: 20
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (rootRecordatorios.mesVisible === 0) {
                                    rootRecordatorios.mesVisible = 11;
                                    rootRecordatorios.anioVisible -= 1;
                                } else {
                                    rootRecordatorios.mesVisible -= 1;
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: rootRecordatorios.nombresMeses[rootRecordatorios.mesVisible] + " " + rootRecordatorios.anioVisible
                        color: temaApp.textoPrincipal
                        font.pixelSize: 15
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        radius: 17
                        color: temaApp.panelAlt
                        border.color: temaApp.bordeAlt
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "›"
                            color: temaApp.textoPrincipal
                            font.pixelSize: 20
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (rootRecordatorios.mesVisible === 11) {
                                    rootRecordatorios.mesVisible = 0;
                                    rootRecordatorios.anioVisible += 1;
                                } else {
                                    rootRecordatorios.mesVisible += 1;
                                }
                            }
                        }
                    }
                }

                // Encabezado de días
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Repeater {
                        model: rootRecordatorios.nombresDias
                        delegate: Text {
                            Layout.fillWidth: true
                            text: modelData
                            color: temaApp.textoMuted
                            font.pixelSize: 10
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                // Días del mes
                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    rowSpacing: 4
                    columnSpacing: 2

                    Repeater {
                        model: {
                            var primerDia = (new Date(rootRecordatorios.anioVisible, rootRecordatorios.mesVisible, 1)).getDay();
                            primerDia = (primerDia + 6) % 7;  // lunes = 0
                            var total = new Date(rootRecordatorios.anioVisible, rootRecordatorios.mesVisible + 1, 0).getDate();
                            var celdas = [];
                            for (var i = 0; i < primerDia; i++) { celdas.push(-1); }
                            for (var d = 1; d <= total; d++) { celdas.push(d); }
                            while (celdas.length % 7 !== 0) { celdas.push(-1); }
                            return celdas;
                        }

                        delegate: Rectangle {
                            required property int modelData
                            property string isoCelda: modelData > 0
                                    ? rootRecordatorios.fechaIso(modelData, rootRecordatorios.mesVisible, rootRecordatorios.anioVisible)
                                    : ""
                            property string fechaActiva: rootRecordatorios.modoCalendario === "aviso"
                                    ? rootRecordatorios.avisoFechaExacta
                                    : rootRecordatorios.fFecha
                            property bool seleccionada: modelData > 0 && fechaActiva === isoCelda

                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            radius: 10
                            visible: modelData > 0
                            color: seleccionada ? temaApp.primario : "transparent"
                            border.color: seleccionada ? temaApp.acentoVisible : temaApp.bordePanel
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData > 0 ? modelData : ""
                                color: parent.seleccionada ? "#ffffff" : temaApp.textoPrincipal
                                font.pixelSize: 12
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var nuevaFecha = rootRecordatorios.fechaIso(modelData,
                                                    rootRecordatorios.mesVisible, rootRecordatorios.anioVisible);
                                    if (rootRecordatorios.modoCalendario === "aviso") {
                                        rootRecordatorios.avisoFechaExacta = nuevaFecha;
                                        rootRecordatorios.avisoExactoModificado = true;
                                    } else {
                                        rootRecordatorios.fFecha = nuevaFecha;
                                        if (!rootRecordatorios.avisoExactoModificado) {
                                            rootRecordatorios.avisoFechaExacta = nuevaFecha;
                                        }
                                    }
                                    rootRecordatorios.calendarioAbierto = false;
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    radius: 14
                    color: temaApp.secundario
                    border.color: temaApp.acento
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "Listo"
                        color: "white"
                        font.pixelSize: 13
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rootRecordatorios.calendarioAbierto = false
                    }
                }
            }
        }
    }
}
