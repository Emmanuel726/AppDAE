import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Effects
import "servicios"

ApplicationWindow {
    id: ventanaPrincipal
    flags: Qt.Window | Qt.ExpandedClientAreaHint | Qt.NoTitleBarBackgroundHint
    width: 395
    height: 820
    visible: true
    title: "DAE UC - Facultad de Ingeniería"
    color: temaApp.fondoBase
    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0

    readonly property real insetSuperior: daeClient.insetSuperior
    readonly property real insetInferior: daeClient.insetInferior

    background: Rectangle {
        color: temaApp.fondoBase
    }

    Material.theme: temaApp.esClaro ? Material.Light : Material.Dark
    Material.accent: temaApp.primario

    // =========================================================================
    // ESTADO GLOBAL DE APARIENCIA (Persistente en QSettings y sincronizado en toda la App)
    // =========================================================================
    // 3 = Sistema Operativo (por defecto), 0 = Oscuro, 1 = Claro DAE, 2 = OLED
    property int temaSeleccionado: daeClient.temaSeleccionado
    // El esquema real del sistema lo lleva el cliente (guarda aparte del que la
    // app impone para la barra de estado)
    readonly property bool sistemaEsClaro: daeClient.sistemaEsClaro
    property int paletaAuroraIndex: daeClient.paletaAuroraIndex
    property bool animacionAuroraActiva: daeClient.animacionAuroraActiva

    // Los iconos de la barra de estado de Android (hora, wifi, batería) se adaptan
    // al fondo: en modo claro van oscuros para que se lean sobre el fondo claro
    function aplicarEsquemaBarraEstado() {
        daeClient.aplicarEsquemaColorSistema(temaApp.esClaro);
    }

    Component.onCompleted: aplicarEsquemaBarraEstado()
    onActiveChanged: if (active) aplicarEsquemaBarraEstado()
    onVisibilityChanged: aplicarEsquemaBarraEstado()

    Connections {
        target: daeClient
        function onAparienciaChanged() {
            ventanaPrincipal.aplicarEsquemaBarraEstado();
        }
    }

    onTemaSeleccionadoChanged: {
        if (daeClient.temaSeleccionado !== temaSeleccionado) {
            daeClient.temaSeleccionado = temaSeleccionado
        }
    }
    onPaletaAuroraIndexChanged: {
        if (daeClient.paletaAuroraIndex !== paletaAuroraIndex) {
            daeClient.paletaAuroraIndex = paletaAuroraIndex
        }
    }
    onAnimacionAuroraActivaChanged: {
        if (daeClient.animacionAuroraActiva !== animacionAuroraActiva) {
            daeClient.animacionAuroraActiva = animacionAuroraActiva
        }
    }

    // Interceptar el botón / gesto "Atrás" de Android para volver al Home en vez de cerrar la App
    onClosing: (close) => {
        if (stackNavegacion.currentItem && typeof stackNavegacion.currentItem.manejarBotonAtras === "function") {
            if (stackNavegacion.currentItem.manejarBotonAtras()) {
                close.accepted = false
                return
            }
        }
    }

    property var paletasBase: [
        {
            nombre: "Vaulta",
            cBase: "#050914", cBaseClaro: "#eef4ff",
            l1: "#68a8f8", l2: "#2563eb", l3: "#bae6fd", l4: "#1e3a8a",
            primario: "#3b82f6", secundario: "#2563eb", oscuro: "#1d4ed8",
            acento: "#60a5fa", claro: "#93c5fd", suave: "#dbeafe", superficie: "#1e3a8a",
            panel: "#0d1526", panelAlt: "#131f38", panelEdit: "#172542",
            bordePanel: "#1e293b", bordeAlt: "#283c63",
            navGrad1: "#45152642", navGrad2: "#75080f1e",
            colores: ["#050914", "#1e3a8a", "#2563eb", "#3b82f6", "#93c5fd", "#1e293b"],
            tarjetas: [
                { c1: "#3b82f6", c2: "#1d4ed8", c3: "#bae6fd" },
                { c1: "#2563eb", c2: "#1e3a8a", c3: "#93c5fd" },
                { c1: "#0284c7", c2: "#1e3a8a", c3: "#bae6fd" },
                { c1: "#4f46e5", c2: "#1d4ed8", c3: "#dbeafe" }
            ]
        },
        {
            nombre: "Esmeralda",
            cBase: "#04120e", cBaseClaro: "#ecfdf5",
            l1: "#34d399", l2: "#059669", l3: "#a7f3d0", l4: "#064e3b",
            primario: "#10b981", secundario: "#059669", oscuro: "#047857",
            acento: "#34d399", claro: "#6ee7b7", suave: "#d1fae5", superficie: "#064e3b",
            panel: "#071f18", panelAlt: "#0c2e24", panelEdit: "#114234",
            bordePanel: "#134e4a", bordeAlt: "#059669",
            navGrad1: "#45064e3b", navGrad2: "#7504120e",
            colores: ["#04120e", "#064e3b", "#059669", "#10b981", "#a7f3d0", "#134e4a"],
            tarjetas: [
                { c1: "#10b981", c2: "#064e3b", c3: "#a7f3d0" },
                { c1: "#059669", c2: "#134e4a", c3: "#6ee7b7" },
                { c1: "#0d9488", c2: "#064e3b", c3: "#99f6e4" },
                { c1: "#047857", c2: "#042f2e", c3: "#a7f3d0" }
            ]
        },
        {
            nombre: "Nébula",
            cBase: "#0b0514", cBaseClaro: "#f5f0ff",
            l1: "#a855f7", l2: "#6d28d9", l3: "#e9d5ff", l4: "#3b0764",
            primario: "#8b5cf6", secundario: "#7c3aed", oscuro: "#5b21b6",
            acento: "#a855f7", claro: "#c4b5fd", suave: "#ede9fe", superficie: "#3b0764",
            panel: "#140924", panelAlt: "#22103b", panelEdit: "#2e1065",
            bordePanel: "#3b0764", bordeAlt: "#6d28d9",
            navGrad1: "#453b0764", navGrad2: "#750b0514",
            colores: ["#0b0514", "#3b0764", "#6d28d9", "#a855f7", "#e9d5ff", "#2e1065"],
            tarjetas: [
                { c1: "#8b5cf6", c2: "#3b0764", c3: "#e9d5ff" },
                { c1: "#6d28d9", c2: "#2e1065", c3: "#c4b5fd" },
                { c1: "#9333ea", c2: "#3b0764", c3: "#f3e8ff" },
                { c1: "#7c3aed", c2: "#1e1b4b", c3: "#ddd6fe" }
            ]
        },
        {
            nombre: "Carmesí",
            cBase: "#140509", cBaseClaro: "#fff1f3",
            l1: "#fb7185", l2: "#e11d48", l3: "#fecdd3", l4: "#881337",
            primario: "#f43f5e", secundario: "#e11d48", oscuro: "#be123c",
            acento: "#fb7185", claro: "#fda4af", suave: "#ffe4e6", superficie: "#881337",
            panel: "#210910", panelAlt: "#36101b", panelEdit: "#4c0519",
            bordePanel: "#4c0519", bordeAlt: "#be123c",
            navGrad1: "#45881337", navGrad2: "#75140509",
            colores: ["#140509", "#881337", "#e11d48", "#fb7185", "#fecdd3", "#4c0519"],
            tarjetas: [
                { c1: "#e11d48", c2: "#881337", c3: "#fecdd3" },
                { c1: "#f43f5e", c2: "#4c0519", c3: "#fda4af" },
                { c1: "#be123c", c2: "#4c0519", c3: "#ffe4e6" },
                { c1: "#db2777", c2: "#831843", c3: "#fbcfe8" }
            ]
        },
        {
            nombre: "Ámbar",
            cBase: "#120c04", cBaseClaro: "#fffbeb",
            l1: "#fbbf24", l2: "#d97706", l3: "#fde68a", l4: "#78350f",
            primario: "#f59e0b", secundario: "#d97706", oscuro: "#b45309",
            acento: "#fbbf24", claro: "#fcd34d", suave: "#fef3c7", superficie: "#78350f",
            panel: "#1f1407", panelAlt: "#33210b", panelEdit: "#451a03",
            bordePanel: "#451a03", bordeAlt: "#b45309",
            navGrad1: "#4578350f", navGrad2: "#75120c04",
            colores: ["#120c04", "#78350f", "#d97706", "#fbbf24", "#fde68a", "#451a03"],
            tarjetas: [
                { c1: "#d97706", c2: "#78350f", c3: "#fde68a" },
                { c1: "#f59e0b", c2: "#451a03", c3: "#fcd34d" },
                { c1: "#b45309", c2: "#451a03", c3: "#fef3c7" },
                { c1: "#ea580c", c2: "#7c2d12", c3: "#fed7aa" }
            ]
        },
        {
            nombre: "Amatista",
            cBase: "#0E0B1D", cBaseClaro: "#F4F2FA",
            l1: "#8B7CC7", l2: "#5A3B8C", l3: "#C9C2E3", l4: "#2A1E4D",
            primario: "#8B7CC7", secundario: "#5A3B8C", oscuro: "#2A1E4D",
            acento: "#8B7CC7", claro: "#C9C2E3", suave: "#C9C2E3", superficie: "#2A1E4D",
            panel: "#151029", panelAlt: "#2A1E4D", panelEdit: "#3A3A52",
            bordePanel: "#3A3A52", bordeAlt: "#5A3B8C",
            navGrad1: "#452A1E4D", navGrad2: "#750E0B1D",
            colores: ["#0E0B1D", "#2A1E4D", "#5A3B8C", "#8B7CC7", "#C9C2E3", "#3A3A52"],
            tarjetas: [
                { c1: "#5A3B8C", c2: "#2A1E4D", c3: "#C9C2E3" },
                { c1: "#8B7CC7", c2: "#3A3A52", c3: "#C9C2E3" },
                { c1: "#3A3A52", c2: "#2A1E4D", c3: "#8B7CC7" },
                { c1: "#5A3B8C", c2: "#3A3A52", c3: "#8B7CC7" }
            ]
        },
        {
            nombre: "Espresso",
            cBase: "#1A120E", cBaseClaro: "#FAF6F2",
            l1: "#A88462", l2: "#6B4A2E", l3: "#D5C4AE", l4: "#3A2418",
            primario: "#A88462", secundario: "#6B4A2E", oscuro: "#3A2418",
            acento: "#A88462", claro: "#D5C4AE", suave: "#D5C4AE", superficie: "#3A2418",
            panel: "#241812", panelAlt: "#3A2418", panelEdit: "#4A4A46",
            bordePanel: "#4A4A46", bordeAlt: "#6B4A2E",
            navGrad1: "#453A2418", navGrad2: "#751A120E",
            colores: ["#1A120E", "#3A2418", "#6B4A2E", "#A88462", "#D5C4AE", "#4A4A46"],
            tarjetas: [
                { c1: "#6B4A2E", c2: "#3A2418", c3: "#D5C4AE" },
                { c1: "#A88462", c2: "#4A4A46", c3: "#D5C4AE" },
                { c1: "#4A4A46", c2: "#3A2418", c3: "#A88462" },
                { c1: "#6B4A2E", c2: "#4A4A46", c3: "#A88462" }
            ]
        },
        {
            nombre: "Bosque",
            cBase: "#0F1F17", cBaseClaro: "#F3F6F2",
            l1: "#6B7F67", l2: "#3E5A3F", l3: "#C7CBB8", l4: "#1E3A2E",
            primario: "#6B7F67", secundario: "#3E5A3F", oscuro: "#1E3A2E",
            acento: "#6B7F67", claro: "#C7CBB8", suave: "#C7CBB8", superficie: "#1E3A2E",
            panel: "#15291F", panelAlt: "#1E3A2E", panelEdit: "#3D4337",
            bordePanel: "#3D4337", bordeAlt: "#3E5A3F",
            navGrad1: "#451E3A2E", navGrad2: "#750F1F17",
            colores: ["#0F1F17", "#1E3A2E", "#3E5A3F", "#6B7F67", "#C7CBB8", "#3D4337"],
            tarjetas: [
                { c1: "#3E5A3F", c2: "#1E3A2E", c3: "#C7CBB8" },
                { c1: "#6B7F67", c2: "#3D4337", c3: "#C7CBB8" },
                { c1: "#3D4337", c2: "#1E3A2E", c3: "#6B7F67" },
                { c1: "#3E5A3F", c2: "#3D4337", c3: "#6B7F67" }
            ]
        },
        {
            nombre: "Horizonte",
            cBase: "#0B132B", cBaseClaro: "#F0F6FA",
            l1: "#5BC0DE", l2: "#D97706", l3: "#F4D6B0", l4: "#1C2541",
            primario: "#5BC0DE", secundario: "#3A506B", oscuro: "#1C2541",
            acento: "#D97706", claro: "#F4D6B0", suave: "#F4D6B0", superficie: "#1C2541",
            panel: "#121B36", panelAlt: "#1C2541", panelEdit: "#3A506B",
            bordePanel: "#283856", bordeAlt: "#3A506B",
            navGrad1: "#451C2541", navGrad2: "#750B132B",
            colores: ["#0B132B", "#1C2541", "#3A506B", "#5BC0DE", "#F4D6B0", "#D97706"],
            tarjetas: [
                { c1: "#3A506B", c2: "#1C2541", c3: "#5BC0DE" },
                { c1: "#D97706", c2: "#1C2541", c3: "#F4D6B0" },
                { c1: "#5BC0DE", c2: "#3A506B", c3: "#F4D6B0" },
                { c1: "#D97706", c2: "#3A506B", c3: "#5BC0DE" }
            ]
        },
        {
            nombre: "Jade Dorado",
            cBase: "#0B0F0D", cBaseClaro: "#F5F7F4",
            l1: "#8CA98C", l2: "#B08D57", l3: "#D9C7A3", l4: "#1F2A1F",
            primario: "#8CA98C", secundario: "#3E5A3F", oscuro: "#1F2A1F",
            acento: "#B08D57", claro: "#D9C7A3", suave: "#D9C7A3", superficie: "#1F2A1F",
            panel: "#141C16", panelAlt: "#1F2A1F", panelEdit: "#3E5A3F",
            bordePanel: "#2C3B2D", bordeAlt: "#B08D57",
            navGrad1: "#451F2A1F", navGrad2: "#750B0F0D",
            colores: ["#0B0F0D", "#1F2A1F", "#3E5A3F", "#8CA98C", "#D9C7A3", "#B08D57"],
            tarjetas: [
                { c1: "#3E5A3F", c2: "#1F2A1F", c3: "#8CA98C" },
                { c1: "#B08D57", c2: "#1F2A1F", c3: "#D9C7A3" },
                { c1: "#8CA98C", c2: "#3E5A3F", c3: "#D9C7A3" },
                { c1: "#B08D57", c2: "#3E5A3F", c3: "#8CA98C" }
            ]
        },
        {
            nombre: "Abismo",
            cBase: "#0A0F14", cBaseClaro: "#F2F7F7",
            l1: "#7FB3B8", l2: "#C6601F", l3: "#EADCC8", l4: "#0F3D3E",
            primario: "#7FB3B8", secundario: "#2E6F73", oscuro: "#0F3D3E",
            acento: "#C6601F", claro: "#EADCC8", suave: "#EADCC8", superficie: "#0F3D3E",
            panel: "#0D2426", panelAlt: "#0F3D3E", panelEdit: "#2E6F73",
            bordePanel: "#1E5255", bordeAlt: "#2E6F73",
            navGrad1: "#450F3D3E", navGrad2: "#750A0F14",
            colores: ["#0A0F14", "#0F3D3E", "#2E6F73", "#7FB3B8", "#EADCC8", "#C6601F"],
            tarjetas: [
                { c1: "#2E6F73", c2: "#0F3D3E", c3: "#7FB3B8" },
                { c1: "#C6601F", c2: "#0F3D3E", c3: "#EADCC8" },
                { c1: "#7FB3B8", c2: "#2E6F73", c3: "#EADCC8" },
                { c1: "#C6601F", c2: "#2E6F73", c3: "#7FB3B8" }
            ]
        },
        {
            nombre: "Atardecer",
            cBase: "#1A0F2E", cBaseClaro: "#FDF4F5",
            l1: "#D6598F", l2: "#FF6B6B", l3: "#F4D7D4", l4: "#3B1B4F",
            primario: "#D6598F", secundario: "#7A2E6F", oscuro: "#3B1B4F",
            acento: "#FF6B6B", claro: "#F4D7D4", suave: "#F4D7D4", superficie: "#3B1B4F",
            panel: "#26143D", panelAlt: "#3B1B4F", panelEdit: "#7A2E6F",
            bordePanel: "#562360", bordeAlt: "#7A2E6F",
            navGrad1: "#453B1B4F", navGrad2: "#751A0F2E",
            colores: ["#1A0F2E", "#3B1B4F", "#7A2E6F", "#D6598F", "#F4D7D4", "#FF6B6B"],
            tarjetas: [
                { c1: "#7A2E6F", c2: "#3B1B4F", c3: "#D6598F" },
                { c1: "#FF6B6B", c2: "#3B1B4F", c3: "#F4D7D4" },
                { c1: "#D6598F", c2: "#7A2E6F", c3: "#F4D7D4" },
                { c1: "#FF6B6B", c2: "#7A2E6F", c3: "#D6598F" }
            ]
        },
        {
            nombre: "Cosmos",
            cBase: "#1A1A1F", cBaseClaro: "#F6F4FA",
            l1: "#A678B9", l2: "#F4A62A", l3: "#F0D9B5", l4: "#2D2B55",
            primario: "#A678B9", secundario: "#6A5ACD", oscuro: "#2D2B55",
            acento: "#F4A62A", claro: "#F0D9B5", suave: "#F0D9B5", superficie: "#2D2B55",
            panel: "#22213B", panelAlt: "#2D2B55", panelEdit: "#6A5ACD",
            bordePanel: "#463F7A", bordeAlt: "#6A5ACD",
            navGrad1: "#452D2B55", navGrad2: "#751A1A1F",
            colores: ["#1A1A1F", "#2D2B55", "#6A5ACD", "#A678B9", "#F0D9B5", "#F4A62A"],
            tarjetas: [
                { c1: "#6A5ACD", c2: "#2D2B55", c3: "#A678B9" },
                { c1: "#F4A62A", c2: "#2D2B55", c3: "#F0D9B5" },
                { c1: "#A678B9", c2: "#6A5ACD", c3: "#F0D9B5" },
                { c1: "#F4A62A", c2: "#6A5ACD", c3: "#A678B9" }
            ]
        },
        {
            nombre: "Cyberpunk",
            cBase: "#121212", cBaseClaro: "#F8FAFC",
            l1: "#EC4899", l2: "#64748B", l3: "#F1F5F9", l4: "#1F2937",
            primario: "#EC4899", secundario: "#334155", oscuro: "#1F2937",
            acento: "#EC4899", claro: "#F1F5F9", suave: "#F1F5F9", superficie: "#1F2937",
            panel: "#181F29", panelAlt: "#1F2937", panelEdit: "#334155",
            bordePanel: "#334155", bordeAlt: "#64748B",
            navGrad1: "#451F2937", navGrad2: "#75121212",
            colores: ["#121212", "#1F2937", "#334155", "#64748B", "#F1F5F9", "#EC4899"],
            tarjetas: [
                { c1: "#334155", c2: "#1F2937", c3: "#EC4899" },
                { c1: "#EC4899", c2: "#1F2937", c3: "#F1F5F9" },
                { c1: "#64748B", c2: "#1F2937", c3: "#EC4899" },
                { c1: "#EC4899", c2: "#334155", c3: "#F1F5F9" }
            ]
        }
    ]

    // Devuelve el trío de colores armónico de la paleta activa para cualquier tarjeta de materia o celda de horario
    function coloresTarjetaMateria(idx, codigo) {
        var p = paletasBase[paletaAuroraIndex] || paletasBase[0];
        var lista = p.tarjetas || [
            { c1: p.secundario, c2: p.oscuro, c3: p.suave },
            { c1: p.acento,     c2: p.oscuro, c3: p.claro }
        ];
        var pos = 0;
        if (codigo && codigo.length > 0) {
            var h = 0;
            for (var i = 0; i < codigo.length && codigo[i] !== "\n"; i++) {
                h = (h * 31 + codigo.charCodeAt(i));
            }
            pos = Math.abs(h + (idx || 0)) % lista.length;
        } else {
            pos = Math.abs(idx || 0) % lista.length;
        }
        return lista[pos];
    }

    // VARIABLE GLOBAL DE TEMA (Combina la paleta activa + el modo Sistema / Oscuro / Claro / OLED)
    // Devuelve un color del tema de forma segura (durante la reevaluacion
    // de temaApp algunas sub-propiedades pueden estar todavia sin definir).
    function colorTema(nombre, porDefecto) {
        var t = temaApp;
        if (!t) {
            return porDefecto;
        }
        var v = t[nombre];
        return (v === undefined || v === null) ? porDefecto : v;
    }

    property var temaApp: {
        var p = paletasBase[paletaAuroraIndex] || paletasBase[0];
        var esClaro = (temaSeleccionado === 3) ? ventanaPrincipal.sistemaEsClaro : (temaSeleccionado === 1);
        var esOled = (temaSeleccionado === 2);

        return {
            nombre: p.nombre,
            esClaro: esClaro,
            esOled: esOled,
            cBase: p.cBase,
            fondoBase: esOled ? "#000000" : (esClaro ? p.cBaseClaro : p.cBase),
            l1: p.l1,
            l2: p.l2,
            l3: p.l3,
            l4: esOled ? "#000000" : (esClaro ? p.l3 : p.l4),
            primario: p.primario,
            secundario: p.secundario,
            oscuro: p.oscuro,
            acento: p.acento,
            claro: p.claro,
            // Acento que se lee siempre: en modo claro se usa el primario porque
            // el tono claro de la paleta no contrasta sobre un fondo claro.
            acentoVisible: esClaro ? p.primario : p.claro,
            suave: p.suave,
            superficie: p.superficie,

            // Tokens adaptativos para tarjetas, bordes y textos según Oscuro / Claro / OLED + Paleta activa
            panel: esOled ? "#05070b" : (esClaro ? "#ffffff" : (p.panel || "#0d1526")),
            panelAlt: esOled ? "#0b0f19" : (esClaro ? "#f1f5f9" : (p.panelAlt || "#131f38")),
            panelEdit: esOled ? "#111827" : (esClaro ? "#e2e8f0" : (p.panelEdit || "#172542")),
            bordePanel: esOled ? "#151e2e" : (esClaro ? "#cbd5e1" : (p.bordePanel || "#1e293b")),
            bordeAlt: esOled ? "#1e293b" : (esClaro ? "#94a3b8" : (p.bordeAlt || "#283c63")),

            vidrio: esOled ? "#14ffffff" : (esClaro ? "#d8ffffff" : "#1cffffff"),
            bordeVidrio: esOled ? "#28ffffff" : (esClaro ? "#cbd5e1" : "#45ffffff"),

            textoPrincipal: esClaro ? "#0f172a" : "#ffffff",
            textoSubtitulo: esClaro ? p.oscuro : p.suave,
            textoSecundario: esClaro ? "#334155" : "#94a3b8",
            textoMuted: esClaro ? "#64748b" : "#64748b",

            navGrad1: esOled ? "#dd05070b" : (esClaro ? "#eeffffff" : (p.navGrad1 || "#45152642")),
            navGrad2: esOled ? "#f2000000" : (esClaro ? "#f5f1f5f9" : (p.navGrad2 || "#75080f1e")),
            navBorde: esOled ? "#30ffffff" : (esClaro ? "#cbd5e1" : "#45ffffff")
        };
    }

    // =========================================================================
    // COMPONENTE REUTILIZABLE: DIFUMINADO EN MOVIMIENTO (ESTILO GEMINI / VAULTA)
    // =========================================================================
    component FondoAurora: Item {
        id: rootAurora
        property color colorBase: temaApp.fondoBase
        property color luz1: temaApp.l1
        property color luz2: temaApp.l2
        property color luz3: temaApp.l3
        property color luz4: temaApp.l4
        property real alturaBrillo: parent.height * 0.58

        clip: true

        // Color de fondo base (Oscuro, Claro o Negro Puro OLED)
        Rectangle {
            anchors.fill: parent
            color: rootAurora.colorBase
            Behavior on color { ColorAnimation { duration: 400 } }
        }

        // Lienzo oculto donde se mueven las ondas de color antes de fundirse
        Item {
            id: lienzoLuces
            width: parent.width
            height: rootAurora.alturaBrillo
            visible: false

            // Luz 1: Núcleo principal superior izquierdo
            Rectangle {
                id: orbe1
                width: parent.width * 0.95
                height: width
                radius: width / 2
                color: rootAurora.luz1
                opacity: temaApp.esClaro ? 0.50 : (temaApp.esOled ? 0.72 : 0.85)
                x: -parent.width * 0.25
                y: -parent.height * 0.25
                Behavior on color { ColorAnimation { duration: 400 } }

                SequentialAnimation on x {
                    running: ventanaPrincipal.animacionAuroraActiva
                    loops: Animation.Infinite
                    NumberAnimation { to: parent.width * 0.30; duration: 4800; easing.type: Easing.InOutSine }
                    NumberAnimation { to: -parent.width * 0.25; duration: 4800; easing.type: Easing.InOutSine }
                }
                SequentialAnimation on y {
                    running: ventanaPrincipal.animacionAuroraActiva
                    loops: Animation.Infinite
                    NumberAnimation { to: parent.height * 0.05; duration: 3600; easing.type: Easing.InOutSine }
                    NumberAnimation { to: -parent.height * 0.25; duration: 3600; easing.type: Easing.InOutSine }
                }
            }

            // Luz 2: Onda derecha en sentido opuesto
            Rectangle {
                id: orbe2
                width: parent.width * 0.90
                height: width
                radius: width / 2
                color: rootAurora.luz2
                opacity: temaApp.esClaro ? 0.42 : (temaApp.esOled ? 0.75 : 0.90)
                x: parent.width * 0.30
                y: -parent.height * 0.10
                Behavior on color { ColorAnimation { duration: 400 } }

                SequentialAnimation on x {
                    running: ventanaPrincipal.animacionAuroraActiva
                    loops: Animation.Infinite
                    NumberAnimation { to: -parent.width * 0.20; duration: 5400; easing.type: Easing.InOutSine }
                    NumberAnimation { to: parent.width * 0.30; duration: 5400; easing.type: Easing.InOutSine }
                }
                SequentialAnimation on y {
                    running: ventanaPrincipal.animacionAuroraActiva
                    loops: Animation.Infinite
                    NumberAnimation { to: parent.height * 0.18; duration: 4200; easing.type: Easing.InOutSine }
                    NumberAnimation { to: -parent.height * 0.10; duration: 4200; easing.type: Easing.InOutSine }
                }
            }

            // Luz 3: Destello luminoso central (Efecto seda de Vaulta / Gemini)
            Rectangle {
                id: orbe3
                width: parent.width * 0.65
                height: width * 0.75
                radius: width / 2
                color: rootAurora.luz3
                opacity: temaApp.esClaro ? 0.65 : 0.70
                x: parent.width * 0.15
                y: parent.height * 0.02
                rotation: -25
                Behavior on color { ColorAnimation { duration: 400 } }

                SequentialAnimation on x {
                    running: ventanaPrincipal.animacionAuroraActiva
                    loops: Animation.Infinite
                    NumberAnimation { to: parent.width * 0.40; duration: 3900; easing.type: Easing.InOutSine }
                    NumberAnimation { to: -parent.width * 0.05; duration: 3900; easing.type: Easing.InOutSine }
                }
                SequentialAnimation on scale {
                    running: ventanaPrincipal.animacionAuroraActiva
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.25; duration: 3100; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.90; duration: 3100; easing.type: Easing.InOutSine }
                }
            }

            // Luz 4: Base de transición profunda
            Rectangle {
                id: orbe4
                width: parent.width * 1.1
                height: width * 0.6
                radius: width / 2
                color: rootAurora.luz4
                opacity: temaApp.esClaro ? 0.45 : 0.75
                x: -parent.width * 0.05
                y: parent.height * 0.25
                Behavior on color { ColorAnimation { duration: 400 } }

                SequentialAnimation on y {
                    running: ventanaPrincipal.animacionAuroraActiva
                    loops: Animation.Infinite
                    NumberAnimation { to: parent.height * 0.10; duration: 4500; easing.type: Easing.InOutSine }
                    NumberAnimation { to: parent.height * 0.28; duration: 4500; easing.type: Easing.InOutSine }
                }
            }
        }

        // Bajamos la resolución de las luces y aplicamos Blur masivo para que sea un degradado líquido sin bordes
        ShaderEffectSource {
            id: texturaAurora
            sourceItem: lienzoLuces
            textureSize: Qt.size(64, 64)
            live: true
            smooth: true
            visible: false
        }

        MultiEffect {
            width: parent.width
            height: rootAurora.alturaBrillo + 120
            source: texturaAurora
            blurEnabled: true
            blurMax: 64
            blur: 1.0
            blurMultiplier: 2.2
            saturation: temaApp.esClaro ? 0.12 : 0.25
            autoPaddingEnabled: false
        }

        // Fundido suave hacia el color base actual (sin residuos azules)
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(rootAurora.colorBase.r, rootAurora.colorBase.g, rootAurora.colorBase.b, 0.0) }
                GradientStop { position: 0.46; color: Qt.rgba(rootAurora.colorBase.r, rootAurora.colorBase.g, rootAurora.colorBase.b, 0.40) }
                GradientStop { position: 0.66; color: rootAurora.colorBase }
                GradientStop { position: 1.0; color: rootAurora.colorBase }
            }
        }
    }

    StackView {
        id: stackNavegacion
        anchors.fill: parent
        initialItem: pantallaLogin
    }

    // =========================================================================
    // PANTALLA 1: LOGIN CON LOGO COMPLETO CENTRADO + FONDO AURORA EN MOVIMIENTO
    // =========================================================================
    Component {
        id: pantallaLogin
        Page {
            topPadding: 0
            bottomPadding: 0
            leftPadding: 0
            rightPadding: 0

            background: FondoAurora {
                alturaBrillo: parent.height * 0.75
                colorBase: temaApp.fondoBase
                luz1: temaApp.l1
                luz2: temaApp.l2
                luz3: temaApp.l3
                luz4: temaApp.l4
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: ventanaPrincipal.insetSuperior
                anchors.bottomMargin: ventanaPrincipal.insetInferior
                anchors.leftMargin: 32
                anchors.rightMargin: 32
                spacing: 18

                Item { Layout.fillHeight: true; Layout.preferredHeight: 20 }

                // --- BLOQUE DEL LOGO DE LA FACULTAD DE INGENIERÍA UC (100% CENTRADO) ---
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8

                    // Contenedor exacto que centra el conjunto [Isotipo + FACULTAD DE INGENIERIA]
                    // Contenedor ajustado: las letras son más pequeñas y entran dentro de la abertura derecha del logo
                    Item {
                        Layout.preferredWidth: 226
                        Layout.preferredHeight: 136
                        Layout.alignment: Qt.AlignHCenter

                        // Parte 1: Geometría exacta del emblema
                        Canvas {
                            id: canvasEmblema
                            // Dentro de un Layout no se pueden usar anchors, así
                            // que se posiciona con x/y respecto al contenedor.
                            x: 0
                            y: 0
                            width: 132; height: 136
                            property color colorTema: ventanaPrincipal.colorTema(
                                "esClaro", true) ? ventanaPrincipal.colorTema("primario", "#a8813f")
                                                 : ventanaPrincipal.colorTema("claro", "#e3cd9d")
                            property color colorBaseLogo: temaApp.textoPrincipal
                            onColorTemaChanged: requestPaint()
                            onColorBaseLogoChanged: requestPaint()

                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.save();

                                var s = 26;
                                ctx.translate(18, 16);

                                ctx.strokeStyle = canvasEmblema.colorBaseLogo;
                                ctx.fillStyle = canvasEmblema.colorBaseLogo;
                                ctx.lineWidth = 2.4;
                                ctx.lineCap = "butt";
                                ctx.lineJoin = "miter";

                                // 1. Tres puntas triangulares rellenas
                                ctx.beginPath();
                                ctx.moveTo(s, 0); ctx.lineTo(2*s, 0); ctx.lineTo(1.5*s, -0.5*s);
                                ctx.closePath(); ctx.fill();

                                ctx.beginPath();
                                ctx.moveTo(0, s); ctx.lineTo(0, 2*s); ctx.lineTo(-0.5*s, 1.5*s);
                                ctx.closePath(); ctx.fill();

                                ctx.beginPath();
                                ctx.moveTo(s, 3*s); ctx.lineTo(2*s, 3*s); ctx.lineTo(1.5*s, 3.5*s);
                                ctx.closePath(); ctx.fill();

                                // 2. Tres cuadrados completos con sus diagonales en cruz ("X")
                                var cuadrados = [[1, 0], [0, 1], [1, 2]];
                                for (var i = 0; i < cuadrados.length; i++) {
                                    var cx = cuadrados[i][0] * s;
                                    var cy = cuadrados[i][1] * s;
                                    ctx.strokeRect(cx, cy, s, s);
                                    ctx.beginPath();
                                    ctx.moveTo(cx, cy); ctx.lineTo(cx + s, cy + s);
                                    ctx.moveTo(cx + s, cy); ctx.lineTo(cx, cy + s);
                                    ctx.stroke();
                                }

                                // 3. Tres triángulos exteriores con su mediatriz
                                ctx.beginPath();
                                ctx.moveTo(0, s); ctx.lineTo(s, 0); ctx.lineTo(s, s); ctx.closePath();
                                ctx.moveTo(s, s); ctx.lineTo(0.5*s, 0.5*s);
                                ctx.stroke();

                                ctx.beginPath();
                                ctx.moveTo(2*s, 0); ctx.lineTo(3*s, s); ctx.lineTo(2*s, s); ctx.closePath();
                                ctx.moveTo(2*s, s); ctx.lineTo(2.5*s, 0.5*s);
                                ctx.stroke();

                                ctx.beginPath();
                                ctx.moveTo(0, 2*s); ctx.lineTo(s, 2*s); ctx.lineTo(s, 3*s); ctx.closePath();
                                ctx.moveTo(s, 2*s); ctx.lineTo(0.5*s, 2.5*s);
                                ctx.stroke();

                                // 4. Contorno exterior continuo
                                ctx.beginPath();
                                ctx.moveTo(-0.5*s, 1.5*s); ctx.lineTo(1.5*s, -0.5*s); ctx.lineTo(3*s, s);
                                ctx.moveTo(-0.5*s, 1.5*s); ctx.lineTo(1.5*s, 3.5*s); ctx.lineTo(2*s, 3*s);
                                ctx.stroke();

                                // 5. Anillo circular central grueso
                                ctx.beginPath();
                                ctx.arc(1.5*s, 1.5*s, s * 0.36, 0, Math.PI * 2);
                                ctx.lineWidth = 6.2;
                                ctx.strokeStyle = canvasEmblema.colorTema;
                                ctx.stroke();

                                ctx.restore();
                            }
                        }

                        // Parte 2: Texto más pequeño y encajado dentro de la "C" derecha del logo (x: 78)
                        ColumnLayout {
                            x: 78 // Entra directamente al lado del círculo central, debajo del ala superior
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: 11
                            spacing: -3

                            Text {
                                text: "FACULTAD"
                                color: temaApp.textoPrincipal
                                font.pixelSize: 17
                                font.weight: Font.Black
                                font.letterSpacing: 1.0
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "DE"
                                color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                                font.pixelSize: 16
                                font.weight: Font.Black
                                font.letterSpacing: 1.2
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "INGENIERIA"
                                color: temaApp.textoPrincipal
                                font.pixelSize: 17
                                font.weight: Font.Black
                                font.letterSpacing: 0.8
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    Text {
                        text: "UNIVERSIDAD DE CARABOBO"
                        color: temaApp.textoSubtitulo
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 2.0
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 2
                    }

                    Text {
                        text: "Dirección de Asuntos Estudiantiles"
                        color: temaApp.textoPrincipal
                        font.pixelSize: 17
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                Item { Layout.preferredHeight: 12 }

                // --- CAMPO 1: CÉDULA ---
                Rectangle {
                    Layout.fillWidth: true
                    height: 56
                    radius: 28
                    color: temaApp.esClaro ? "#e6ffffff" : "#22ffffff"
                    border.color: temaApp.esClaro ? temaApp.bordePanel : "#45ffffff"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 20
                        spacing: 14

                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: "transparent"
                            border.color: temaApp.esClaro ? temaApp.primario : "#ccffffff"
                            border.width: 1.5
                            Text { anchors.centerIn: parent; text: "👤"; font.pixelSize: 14; color: temaApp.textoPrincipal }
                        }

                        TextField {
                            id: inputCedula
                            text: daeClient.tieneCredencialesBiometricas ? daeClient.cedulaBiometrica : ""
                            placeholderText: "Cédula de Identidad"
                            placeholderTextColor: temaApp.esClaro ? "#64748b" : "#aaffffff"
                            color: temaApp.textoPrincipal
                            font.pixelSize: 15
                            Layout.fillWidth: true
                            inputMethodHints: Qt.ImhDigitsOnly
                            enabled: !daeClient.cargandoLogin
                            onAccepted: inputPassword.forceActiveFocus()
                            background: Item {}
                        }
                    }
                }

                // --- CAMPO 2: CONTRASEÑA ---
                Rectangle {
                    Layout.fillWidth: true
                    height: 56
                    radius: 28
                    color: temaApp.esClaro ? "#e6ffffff" : "#22ffffff"
                    border.color: temaApp.esClaro ? temaApp.bordePanel : "#45ffffff"
                    border.width: 1

                    property bool mostrarClave: false

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 12

                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: "transparent"
                            border.color: temaApp.esClaro ? temaApp.primario : "#ccffffff"
                            border.width: 1.5
                            Text { anchors.centerIn: parent; text: "🔒"; font.pixelSize: 14; color: temaApp.textoPrincipal }
                        }

                        TextField {
                            id: inputPassword
                            placeholderText: "Contraseña"
                            placeholderTextColor: temaApp.esClaro ? "#64748b" : "#aaffffff"
                            color: temaApp.textoPrincipal
                            font.pixelSize: 15
                            echoMode: parent.parent.mostrarClave ? TextInput.Normal : TextInput.Password
                            Layout.fillWidth: true
                            enabled: !daeClient.cargandoLogin
                            onAccepted: daeClient.iniciarSesion(inputCedula.text, inputPassword.text)
                            background: Item {}
                        }

                        // Botón para mostrar/ocultar contraseña igual al portal DAE
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: parent.parent.parent.mostrarClave ? "🙈" : "👁"
                                font.pixelSize: 14
                                color: temaApp.textoSecundario
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: parent.parent.parent.mostrarClave = !parent.parent.parent.mostrarClave
                            }
                        }
                    }
                }

                Connections {
                    target: daeClient
                    function onLoginExitoso() {
                        txtError.text = ""
                        stackNavegacion.push(pantallaDashboard)
                    }
                    function onLoginFallido(razon) {
                        txtError.text = razon
                    }
                }

                Text {
                    id: txtError
                    Layout.fillWidth: true
                    text: daeClient.mensajeError
                    color: temaApp.esClaro ? "#dc2626" : "#fca5a5"
                    font.pixelSize: 12
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    Layout.alignment: Qt.AlignHCenter
                    visible: text !== ""
                }

                // --- BOTÓN DE ACCESO REAL AL SERVIDOR DAE UC ---
                Rectangle {
                    Layout.fillWidth: true
                    height: 56
                    radius: 28
                    Layout.topMargin: 6
                    opacity: daeClient.cargandoLogin ? 0.75 : 1.0
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: temaApp.secundario }
                        GradientStop { position: 1.0; color: temaApp.acento }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: daeClient.cargandoLogin ? "Conectando con DAE UC..." : "Ingresar al DAE"
                        color: "white"
                        font.pixelSize: 16
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !daeClient.cargandoLogin
                        cursorShape: Qt.PointingHandCursor
                        onPressed: parent.scale = 0.97
                        onReleased: parent.scale = 1.0
                        onClicked: {
                            daeClient.iniciarSesion(inputCedula.text, inputPassword.text)
                        }
                    }
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }

                // --- BOTÓN DE ACCESO BIOMÉTRICO / HUELLA DACTILAR ---
                Rectangle {
                    id: btnAccesoBiometricoLogin
                    visible: daeClient.tieneCredencialesBiometricas
                    Layout.fillWidth: true
                    height: 52
                    radius: 26
                    color: temaApp.esClaro ? "#e6ffffff" : "#24ffffff"
                    border.color: temaApp.acento
                    border.width: 1.5
                    opacity: daeClient.cargandoLogin ? 0.6 : 1.0

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 10

                        Canvas {
                            id: iconoHuellaLogin
                            width: 22; height: 22
                            property color colorTrazo: temaApp.esClaro ? temaApp.primario : temaApp.claro
                            onColorTrazoChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.strokeStyle = colorTrazo;
                                ctx.lineWidth = 1.8;
                                ctx.lineCap = "round";
                                // Arcos concéntricos de huella dactilar
                                ctx.beginPath();
                                ctx.arc(11, 11, 8.5, Math.PI * 0.85, Math.PI * 2.15, false);
                                ctx.stroke();
                                ctx.beginPath();
                                ctx.arc(11, 11, 5.5, Math.PI * 0.75, Math.PI * 2.25, false);
                                ctx.stroke();
                                ctx.beginPath();
                                ctx.arc(11, 11, 2.5, Math.PI * 0.6, Math.PI * 2.4, false);
                                ctx.stroke();
                                ctx.beginPath();
                                ctx.moveTo(11, 11); ctx.lineTo(11, 18);
                                ctx.stroke();
                            }
                        }

                        ColumnLayout {
                            spacing: 0
                            Text {
                                text: "Ingresar con Huella Dactilar"
                                color: temaApp.textoPrincipal
                                font.pixelSize: 13
                                font.bold: true
                            }
                            Text {
                                text: "Acceso rápido • V-" + daeClient.cedulaBiometricaFormateada
                                color: temaApp.textoSubtitulo
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !daeClient.cargandoLogin
                        cursorShape: Qt.PointingHandCursor
                        onPressed: btnAccesoBiometricoLogin.scale = 0.97
                        onReleased: btnAccesoBiometricoLogin.scale = 1.0
                        onClicked: daeClient.iniciarSesionConBiometria()
                    }
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }

                // CRÉDITO DEL DESARROLLO
                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    Layout.bottomMargin: 10
                    text: "Desarrollado por Emmanuel"
                    color: temaApp.textoSecundario
                    font.pixelSize: 10
                    font.italic: true
                    horizontalAlignment: Text.AlignHCenter
                }

                Item { Layout.fillHeight: true; Layout.preferredHeight: 20 }
            }
        }
    }

    // =========================================================================
    // PANTALLA 2: DASHBOARD VAULTA CON DIFUMINADO EN MOVIMIENTO (ESTILO GEMINI)
    // =========================================================================
    Component {
        id: pantallaDashboard
        Page {
            id: rootDashboard
            focus: true
            topPadding: 0
            bottomPadding: 0
            leftPadding: 0
            rightPadding: 0
            background: Item {}
            property int tabActual: 0
            property string servicioActivo: ""
            // Detecta automáticamente el día actual del reloj (0=Dom, 1=Lun, 2=Mar, 3=Mié, 4=Jue, 5=Vie, 6=Sáb)
            property int diaHoyIndex: new Date().getDay()
            property var nombresDias: ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"]

            // Abre la vista que corresponde a una solicitud reciente
            function abrirSolicitud(tipo) {
                if (tipo === "INS") {
                    rootDashboard.servicioActivo = "inscripcion";
                    vistaInscripcion.usuarioCambioPestanaManualmente = true;
                    vistaInscripcion.pasoActual = 2;
                } else if (tipo === "PDF") {
                    rootDashboard.servicioActivo = "constancias";
                } else if (tipo === "RAP") {
                    rootDashboard.servicioActivo = "rap";
                } else if (tipo === "CAR") {
                    rootDashboard.servicioActivo = "carnet";
                } else if (tipo === "CAL") {
                    rootDashboard.servicioActivo = "calendario";
                } else if (tipo === "HOR") {
                    rootDashboard.tabActual = 3;
                }
            }

            function manejarBotonAtras() {
                if (rootDashboard.modalAbierto) {
                    rootDashboard.cerrarModalMateria()
                    return true
                }
                if (rootDashboard.tabActual === 4) {
                    if (vistaPerfil.editorFotoAbierto) {
                        vistaPerfil.cerrarEditorFoto()
                        return true
                    }
                    if (vistaPerfil.selectorOpsuAbierto) {
                        vistaPerfil.selectorOpsuAbierto = false
                        return true
                    }
                    if (vistaPerfil.menuFotoAbierto) {
                        vistaPerfil.menuFotoAbierto = false
                        return true
                    }
                    if (vistaPerfil.modoEdicion) {
                        vistaPerfil.cancelarEdicion()
                        return true
                    }
                }
                if (rootDashboard.tabActual === 0 && rootDashboard.servicioActivo === "pensum" && vistaPensum.modalDetalleVisible) {
                    vistaPensum.modalDetalleVisible = false
                    return true
                }
                if (rootDashboard.tabActual === 0 && rootDashboard.servicioActivo === "carnet" && vistaCarnet.modalQrAbierto) {
                    vistaCarnet.modalQrAbierto = false
                    return true
                }
                if (rootDashboard.servicioActivo !== "") {
                    rootDashboard.servicioActivo = ""
                    return true
                }
                if (rootDashboard.tabActual !== 0) {
                    rootDashboard.tabActual = 0
                    return true
                }
                return false
            }

            Keys.onReleased: (event) => {
                if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape) {
                    if (rootDashboard.manejarBotonAtras()) {
                        event.accepted = true
                    }
                }
            }

            // Inicializado vacío para que nunca se muestren datos personales de otro estudiante si el servidor no responde
            property var materiasPorDiaBase: [[], [], [], [], [], [], []]

            property var materiasPorDia: (daeClient.clasesPorDiaDashboard && daeClient.clasesPorDiaDashboard.length === 7)
                                         ? daeClient.clasesPorDiaDashboard
                                         : [[], [], [], [], [], [], []]
            property var clasesHoy: (materiasPorDia && diaHoyIndex >= 0 && diaHoyIndex < materiasPorDia.length && materiasPorDia[diaHoyIndex])
                                    ? materiasPorDia[diaHoyIndex]
                                    : []
            property bool tieneClasesHoy: clasesHoy.length > 0

            // --- PROPIEDADES PARA EL MODAL EXPANDIBLE DE LA MATERIA ---
            property bool modalAbierto: false
            property real origenX: 0
            property real origenY: 0
            property real origenAncho: 185
            property real origenAlto: 188

            property string mDepto: ""
            property string mNombre: ""
            property string mSeccion: ""
            property string mProfesor: ""
            property string mCodigo: ""
            property string mColor1: temaApp.primario
            property string mColor2: temaApp.oscuro
            property string mColor3: temaApp.suave
            property string mHorario1: ""
            property string mHorario2: ""

            function abrirModalMateria(itemTarjeta, datos, colTema) {
                var pos = itemTarjeta.mapToItem(rootDashboard, 0, 0)
                origenX = pos.x
                origenY = pos.y
                origenAncho = itemTarjeta.width
                origenAlto = itemTarjeta.height

                var tCol = colTema || ventanaPrincipal.coloresTarjetaMateria(0, datos.codigo)
                mDepto = datos.departamento
                mNombre = datos.nombre
                mSeccion = datos.seccion
                mProfesor = datos.profesor
                mCodigo = datos.codigo
                mColor1 = tCol.c1
                mColor2 = tCol.c2
                mColor3 = tCol.c3
                mHorario1 = datos.horario1
                mHorario2 = datos.horario2

                tarjetaExpandible.x = origenX
                tarjetaExpandible.y = origenY
                tarjetaExpandible.width = origenAncho
                tarjetaExpandible.height = origenAlto
                modalAbierto = true
                animAbrirModal.restart()
            }

            function cerrarModalMateria() {
                modalAbierto = false
                animCerrarModal.restart()
            }

            // --- ESCENA PRINCIPAL ---
            Item {
                id: escenaPrincipal
                anchors.fill: parent
                layer.enabled: true

                // FONDO DIFUMINADO EN MOVIMIENTO CONECTADO GLOBALMENTE A TEMAAPP
                FondoAurora {
                    anchors.fill: parent
                    colorBase: temaApp.fondoBase
                    luz1: temaApp.l1
                    luz2: temaApp.l2
                    luz3: temaApp.l3
                    luz4: temaApp.l4
                    alturaBrillo: 410
                }

                // CONTENIDO DESLIZABLE
                Flickable {
                    id: areaScroll
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
                            id: timerTecladoPrincipal
                            interval: 280
                            onTriggered: {
                                areaScroll.restaurarPosicion();
                            }
                        }
                    }

                    // Cuando el teclado se cierra, Qt deja el contenido corrido:
                    // se devuelve a la posición en la que estaba el usuario.
                    Connections {
                        target: daeClient
                        function onTecladoVisibleChanged() {
                            if (!daeClient.tecladoVisible) {
                                areaScroll.restaurarPosicion();
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
                    anchors.topMargin: ventanaPrincipal.insetSuperior
                    contentHeight: columnaPrincipal.implicitHeight + 135 + ventanaPrincipal.insetInferior
                    clip: true
                    visible: rootDashboard.tabActual === 0 && rootDashboard.servicioActivo === ""

                    ColumnLayout {
                        id: columnaPrincipal
                        width: parent.width
                        spacing: 18

                        // 1. CABECERA (Avatar con Iniciales + Botón vectorial moderno de Cerrar Sesión)
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 24
                            Layout.leftMargin: 22
                            Layout.rightMargin: 22
                            spacing: 12

                            // Avatar circular sincronizado con la foto de PerfilView
                            Rectangle {
                                width: 44; height: 44; radius: 22
                                border.color: temaApp.esClaro ? temaApp.primario : "#90ffffff"
                                border.width: 1.5
                                clip: true
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: temaApp.primario }
                                    GradientStop { position: 1.0; color: temaApp.oscuro }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: daeClient.inicialesEstudiante
                                    color: "white"
                                    font.pixelSize: 15
                                    font.bold: true
                                    font.letterSpacing: 0.8
                                    visible: vistaPerfil.urlFotoPerfil === ""
                                }

                                Image {
                                    id: miniFotoHome
                                    anchors.fill: parent
                                    source: vistaPerfil.urlFotoPerfil
                                    fillMode: Image.PreserveAspectCrop
                                    visible: false
                                }
                                Item {
                                    id: mascaraMiniHome
                                    anchors.fill: parent
                                    layer.enabled: true
                                    visible: false
                                    Rectangle { anchors.fill: parent; radius: 22; color: "black" }
                                }
                                MultiEffect {
                                    anchors.fill: parent
                                    source: miniFotoHome
                                    visible: vistaPerfil.urlFotoPerfil !== ""
                                    maskEnabled: true
                                    maskSource: mascaraMiniHome
                                }

                                // Si tocas tu avatar en el Home, te lleva directo a tu Perfil
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: rootDashboard.tabActual = 4
                                }
                            }

                            ColumnLayout {
                                spacing: 1
                                Text {
                                    text: "Hola, " + (daeClient.primerNombre !== "" ? daeClient.primerNombre.charAt(0).toUpperCase() + daeClient.primerNombre.slice(1).toLowerCase() : "Estudiante") + "!"
                                    color: temaApp.textoPrincipal
                                    font.pixelSize: 17
                                    font.bold: true
                                }
                                Text {
                                    text: daeClient.escuelaCorta
                                    color: temaApp.textoSubtitulo
                                    font.pixelSize: 12
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Botón moderno de Cerrar Sesión (Icono vectorial minimalista de salida)
                            Rectangle {
                                id: btnLogout
                                width: 42; height: 42; radius: 21
                                color: temaApp.vidrio
                                border.color: temaApp.bordeVidrio
                                border.width: 1

                                Canvas {
                                    width: 20; height: 20
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

                                        // Puerta / Corchete izquierdo de salida
                                        ctx.beginPath();
                                        ctx.moveTo(8, 3);
                                        ctx.lineTo(4, 3);
                                        ctx.lineTo(4, 17);
                                        ctx.lineTo(8, 17);
                                        ctx.stroke();

                                        // Flecha apuntando hacia afuera a la derecha
                                        ctx.beginPath();
                                        ctx.moveTo(8, 10);
                                        ctx.lineTo(17, 10);
                                        ctx.moveTo(13.5, 6.5);
                                        ctx.lineTo(17, 10);
                                        ctx.lineTo(13.5, 13.5);
                                        ctx.stroke();
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: btnLogout.scale = 0.90
                                    onReleased: btnLogout.scale = 1.0
                                    onClicked: {
                                        daeClient.cerrarSesion()
                                        stackNavegacion.pop()
                                    }
                                }
                                Behavior on scale { NumberAnimation { duration: 100 } }
                            }
                        }

                        // 2. PROMEDIO PONDERADO + PROMEDIO ARITMÉTICO + UC INSCRITAS Y ACUMULADAS
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 22
                            Layout.rightMargin: 22
                            spacing: 10

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 20

                                ColumnLayout {
                                    spacing: 1
                                    Text { text: "Promedio Ponderado"; color: temaApp.textoSubtitulo; font.pixelSize: 12 }
                                    RowLayout {
                                        spacing: 1
                                        Text { text: daeClient.promedioPonderadoEntero; color: temaApp.textoPrincipal; font.pixelSize: 36; font.bold: true }
                                        Text { text: daeClient.promedioPonderadoDecimal; color: temaApp.esClaro ? temaApp.primario : temaApp.claro; font.pixelSize: 36 }
                                    }
                                }

                                Rectangle { width: 1; height: 44; color: temaApp.bordeVidrio }

                                ColumnLayout {
                                    spacing: 1
                                    Text { text: "Promedio Aritmético"; color: temaApp.textoSubtitulo; font.pixelSize: 12 }
                                    RowLayout {
                                        spacing: 1
                                        Text { text: daeClient.promedioAritmeticoEntero; color: temaApp.textoPrincipal; font.pixelSize: 36; font.bold: true }
                                        Text { text: daeClient.promedioAritmeticoDecimal; color: temaApp.esClaro ? temaApp.primario : temaApp.claro; font.pixelSize: 36 }
                                    }
                                }

                                Item { Layout.fillWidth: true }
                            }

                            RowLayout {
                                spacing: 10

                                Rectangle {
                                    width: 124; height: 28; radius: 14
                                    color: temaApp.vidrio
                                    border.color: temaApp.bordeVidrio
                                    border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: daeClient.ucInscritas + " UC Inscritas"
                                        color: temaApp.textoPrincipal
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }

                                Rectangle {
                                    width: 152; height: 28; radius: 14
                                    color: temaApp.superficie
                                    border.color: temaApp.acento
                                    border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: daeClient.ucAcumuladas + " UC Acumuladas"
                                        color: "white"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                            }
                        }

                        // 3. ENCABEZADO DINÁMICO: "Agenda de Hoy" + Indicador del día actual
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 22
                            Layout.rightMargin: 22

                            Text {
                                text: "Clases de Hoy"
                                color: temaApp.textoPrincipal
                                font.pixelSize: 16
                                font.bold: true
                            }

                            Item { Layout.fillWidth: true }

                            // Píldora con el día actual (Si la tocas, puedes previsualizar los otros días)
                            Rectangle {
                                width: rowDiaHoy.implicitWidth + 20
                                height: 26; radius: 13
                                color: temaApp.vidrio
                                border.color: temaApp.bordeVidrio
                                border.width: 1

                                RowLayout {
                                    id: rowDiaHoy
                                    anchors.centerIn: parent
                                    spacing: 5
                                    Text {
                                        text: rootDashboard.nombresDias[rootDashboard.diaHoyIndex]
                                        color: temaApp.textoPrincipal
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                    Canvas {
                                        Layout.preferredWidth: 13
                                        Layout.preferredHeight: 13
                                        property color colorTrazo: temaApp.esClaro ? temaApp.primario : temaApp.claro
                                        onColorTrazoChanged: requestPaint()
                                        onPaint: {
                                            var ctx = getContext("2d");
                                            ctx.reset();
                                            ctx.strokeStyle = colorTrazo;
                                            ctx.lineWidth = 1.6;
                                            ctx.lineCap = "round";
                                            ctx.lineJoin = "round";
                                            // Arco circular de recarga / cambio de día
                                            ctx.beginPath();
                                            ctx.arc(6.5, 6.5, 4.3, -Math.PI * 0.75, Math.PI * 0.75, false);
                                            ctx.stroke();
                                            // Punta de flecha superior derecha
                                            ctx.beginPath();
                                            ctx.moveTo(8.2, 1.8);
                                            ctx.lineTo(10.8, 3.6);
                                            ctx.lineTo(7.8, 4.8);
                                            ctx.stroke();
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: rootDashboard.diaHoyIndex = (rootDashboard.diaHoyIndex + 1) % 7
                                }
                            }
                        }

                        // 4A. ESTADO CUANDO HOY ES DÍA LIBRE (Jueves o Domingo)
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 22
                            Layout.rightMargin: 22
                            Layout.preferredHeight: 150
                            height: 150
                            radius: 22
                            color: temaApp.panel
                            border.color: temaApp.bordePanel
                            border.width: 1
                            visible: !rootDashboard.tieneClasesHoy

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Rectangle {
                                    width: 42; height: 42; radius: 21
                                    color: temaApp.panelAlt
                                    border.color: temaApp.bordeAlt
                                    Layout.alignment: Qt.AlignHCenter
                                    Text { anchors.centerIn: parent; text: "✓"; color: temaApp.primario; font.pixelSize: 18; font.bold: true }
                                }
                                Text {
                                    text: "Día sin carga académica"
                                    color: temaApp.textoPrincipal
                                    font.pixelSize: 15
                                    font.bold: true
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: "Ideal para estudiar por tu cuenta 😉 • Ver salones libres →"
                                    color: temaApp.textoSecundario
                                    font.pixelSize: 12
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: rootDashboard.servicioActivo = "salones"
                            }
                        }

                        // 4B. CARRUSEL DE LAS MATERIAS QUE TOCAN ESE DÍA
                        Flickable {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 192
                            height: 192
                            contentWidth: filaTarjetas.implicitWidth + 44
                            contentHeight: 192
                            clip: false
                            visible: rootDashboard.tieneClasesHoy

                            Row {
                                id: filaTarjetas
                                x: 22
                                y: 2
                                spacing: 14

                                Repeater {
                                    model: rootDashboard.clasesHoy

                                    delegate: Item {
                                        id: itemTarjetaMateria
                                        width: 185
                                        height: 188
                                        implicitWidth: 185
                                        implicitHeight: 188
                                        readonly property var colTema: ventanaPrincipal.coloresTarjetaMateria(index, modelData.codigo)

                                        Item {
                                            id: arteTarjeta
                                            anchors.fill: parent
                                            visible: false

                                            Rectangle {
                                                anchors.fill: parent
                                                gradient: Gradient {
                                                    GradientStop { position: 0.0; color: itemTarjetaMateria.colTema.c1 }
                                                    GradientStop { position: 1.0; color: itemTarjetaMateria.colTema.c2 }
                                                }
                                            }

                                            Rectangle {
                                                width: 150; height: 95; radius: 48
                                                color: itemTarjetaMateria.colTema.c3
                                                opacity: 0.65
                                                rotation: -35
                                                x: -25; y: 15

                                                SequentialAnimation on x {
                                                    loops: Animation.Infinite
                                                    NumberAnimation { to: 35; duration: 4200; easing.type: Easing.InOutSine }
                                                    NumberAnimation { to: -25; duration: 4200; easing.type: Easing.InOutSine }
                                                }
                                            }

                                            Rectangle {
                                                width: 120; height: 120; radius: 60
                                                color: itemTarjetaMateria.colTema.c2
                                                opacity: 0.80
                                                x: 80; y: 75
                                            }
                                        }

                                        Item {
                                            id: mascaraTarjeta
                                            anchors.fill: parent
                                            layer.enabled: true
                                            visible: false
                                            Rectangle {
                                                anchors.fill: parent
                                                radius: 22
                                                color: "black"
                                            }
                                        }

                                        MultiEffect {
                                            anchors.fill: parent
                                            source: arteTarjeta
                                            blurEnabled: true
                                            blurMax: 64
                                            blur: 1.0
                                            blurMultiplier: 1.4
                                            autoPaddingEnabled: false
                                            maskEnabled: true
                                            maskSource: mascaraTarjeta
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 22
                                            color: "transparent"
                                            border.color: "#65ffffff"
                                            border.width: 1
                                        }

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 14
                                            spacing: 4

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 4
                                                Text {
                                                    text: modelData.departamento
                                                    color: temaApp.suave
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                                Rectangle {
                                                    width: 54; height: 18; radius: 9
                                                    color: "#33ffffff"
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: modelData.codigo
                                                        color: "white"
                                                        font.pixelSize: 9
                                                        font.bold: true
                                                    }
                                                }
                                            }

                                            Text {
                                                text: modelData.nombre
                                                color: "white"
                                                font.pixelSize: 14
                                                font.bold: true
                                                wrapMode: Text.WordWrap
                                                maximumLineCount: 2
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                                Layout.topMargin: 2
                                            }

                                            Item { Layout.fillHeight: true }

                                            Text {
                                                text: modelData.seccion
                                                color: temaApp.suave
                                                font.pixelSize: 13
                                                font.bold: true
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            RowLayout {
                                                Layout.fillWidth: true
                                                Text {
                                                    text: modelData.profesor
                                                    color: "white"
                                                    font.pixelSize: 11
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                                Canvas {
                                                    Layout.preferredWidth: 13
                                                    Layout.preferredHeight: 13
                                                    property color colorTrazo: temaApp.suave
                                                    onColorTrazoChanged: requestPaint()
                                                    onPaint: {
                                                        var ctx = getContext("2d");
                                                        ctx.reset();
                                                        ctx.strokeStyle = colorTrazo;
                                                        ctx.lineWidth = 1.6;
                                                        ctx.lineCap = "round";
                                                        ctx.lineJoin = "round";
                                                        // Flecha diagonal de expandir (esquina superior derecha e inferior izquierda)
                                                        ctx.beginPath();
                                                        ctx.moveTo(7.5, 2.5); ctx.lineTo(10.5, 2.5); ctx.lineTo(10.5, 5.5);
                                                        ctx.moveTo(10.5, 2.5); ctx.lineTo(2.5, 10.5);
                                                        ctx.moveTo(5.5, 10.5); ctx.lineTo(2.5, 10.5); ctx.lineTo(2.5, 7.5);
                                                        ctx.stroke();
                                                    }
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onPressed: itemTarjetaMateria.scale = 0.96
                                            onReleased: itemTarjetaMateria.scale = 1.0
                                            onClicked: {
                                                rootDashboard.abrirModalMateria(itemTarjetaMateria, modelData, itemTarjetaMateria.colTema)
                                            }
                                        }
                                        Behavior on scale { NumberAnimation { duration: 100 } }
                                    }
                                }
                            }
                        }

                        // 5. PANEL "SERVICIOS DAE" (11 servicios con iconos vectoriales modernos)
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 20
                            Layout.rightMargin: 20
                            Layout.preferredHeight: 318
                            height: 318
                            radius: 26
                            color: temaApp.panel
                            border.color: temaApp.bordePanel
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 250 } }

                            // Componente para dibujar los 11 iconos modernos con trazos vectoriales centrados
                            component IconoServicio: Canvas {
                                id: canvasSrv
                                property string tipo: "rap"
                                property color colorTrazo: temaApp.acento
                                width: 22; height: 22
                                onColorTrazoChanged: requestPaint()
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.reset();
                                    ctx.strokeStyle = canvasSrv.colorTrazo;
                                    ctx.fillStyle = canvasSrv.colorTrazo;
                                    ctx.lineWidth = 1.8;
                                    ctx.lineCap = "round";
                                    ctx.lineJoin = "round";

                                    if (tipo === "rap") {
                                        // Barras de rendimiento académico + línea de tendencia
                                        ctx.beginPath();
                                        ctx.moveTo(3, 19); ctx.lineTo(19, 19);
                                        ctx.moveTo(6, 16); ctx.lineTo(6, 11);
                                        ctx.moveTo(11, 16); ctx.lineTo(11, 7);
                                        ctx.moveTo(16, 16); ctx.lineTo(16, 4);
                                        ctx.stroke();
                                    } else if (tipo === "constancias") {
                                        // Documento con sello de verificación
                                        ctx.beginPath();
                                        ctx.moveTo(13, 2); ctx.lineTo(5, 2); ctx.lineTo(5, 20); ctx.lineTo(17, 20); ctx.lineTo(17, 6);
                                        ctx.closePath();
                                        ctx.stroke();
                                        ctx.beginPath();
                                        ctx.moveTo(8, 9); ctx.lineTo(14, 9);
                                        ctx.moveTo(8, 13); ctx.lineTo(12, 13);
                                        ctx.stroke();
                                    } else if (tipo === "carnet") {
                                        // Carnet estudiantil (ID Card)
                                        ctx.strokeRect(2, 5, 18, 13);
                                        ctx.beginPath();
                                        ctx.arc(7.5, 10.5, 2, 0, Math.PI * 2);
                                        ctx.moveTo(5, 15); ctx.lineTo(10, 15);
                                        ctx.moveTo(13, 9.5); ctx.lineTo(17, 9.5);
                                        ctx.moveTo(13, 13); ctx.lineTo(16, 13);
                                        ctx.stroke();
                                    } else if (tipo === "horarios") {
                                        // Reloj minimalista para bloques de hora
                                        ctx.beginPath();
                                        ctx.arc(11, 11, 8.5, 0, Math.PI * 2);
                                        ctx.moveTo(11, 6.5); ctx.lineTo(11, 11.5); ctx.lineTo(14.5, 13.5);
                                        ctx.stroke();
                                    } else if (tipo === "calendario") {
                                        // Calendario académico
                                        ctx.strokeRect(3, 5, 16, 14);
                                        ctx.beginPath();
                                        ctx.moveTo(3, 9.5); ctx.lineTo(19, 9.5);
                                        ctx.moveTo(7.5, 2.5); ctx.lineTo(7.5, 6);
                                        ctx.moveTo(14.5, 2.5); ctx.lineTo(14.5, 6);
                                        ctx.stroke();
                                        ctx.fillRect(7, 12.5, 2, 2);
                                        ctx.fillRect(13, 12.5, 2, 2);
                                    } else if (tipo === "pensum") {
                                        // Nodos de prelación / malla curricular
                                        ctx.strokeRect(3, 3, 6, 5);
                                        ctx.strokeRect(13, 3, 6, 5);
                                        ctx.strokeRect(8, 14, 6, 5);
                                        ctx.beginPath();
                                        ctx.moveTo(6, 8); ctx.lineTo(11, 14);
                                        ctx.moveTo(16, 8); ctx.lineTo(11, 14);
                                        ctx.stroke();
                                    } else if (tipo === "reglamento") {
                                        // Libro abierto / Normativa de evaluación
                                        ctx.beginPath();
                                        ctx.moveTo(11, 5); ctx.lineTo(11, 19);
                                        ctx.moveTo(11, 5); ctx.lineTo(4, 3.5); ctx.lineTo(4, 17.5); ctx.lineTo(11, 19);
                                        ctx.moveTo(11, 5); ctx.lineTo(18, 3.5); ctx.lineTo(18, 17.5); ctx.lineTo(11, 19);
                                        ctx.stroke();
                                    } else if (tipo === "cambio_escuela") {
                                        // Flechas dobles opuestas de Cambio de Escuela (inspirado en el icono de DAE)
                                        ctx.beginPath();
                                        ctx.moveTo(4, 7.5); ctx.lineTo(18, 7.5);
                                        ctx.moveTo(14, 4); ctx.lineTo(18, 7.5); ctx.lineTo(14, 11);
                                        ctx.moveTo(18, 14.5); ctx.lineTo(4, 14.5);
                                        ctx.moveTo(8, 11); ctx.lineTo(4, 14.5); ctx.lineTo(8, 18);
                                        ctx.stroke();
                                    } else if (tipo === "inscripcion") {
                                        // Cuadro de selección con check de inscripción
                                        ctx.strokeRect(3, 3, 16, 16);
                                        ctx.beginPath();
                                        ctx.moveTo(7.5, 11.5); ctx.lineTo(10, 14); ctx.lineTo(15, 8.5);
                                        ctx.stroke();
                                    } else if (tipo === "retiro") {
                                        // Documento con signo menos (Retiro de asignatura)
                                        ctx.beginPath();
                                        ctx.arc(11, 11, 8.5, 0, Math.PI * 2);
                                        ctx.moveTo(7.5, 11); ctx.lineTo(14.5, 11);
                                        ctx.stroke();
                                    } else if (tipo === "mapa") {
                                        // Pin de ubicación sobre plano de la facultad
                                        ctx.beginPath();
                                        ctx.arc(11, 9, 3.2, 0, Math.PI * 2);
                                        ctx.stroke();
                                        ctx.beginPath();
                                        ctx.moveTo(11, 20);
                                        ctx.lineTo(5.5, 11.5);
                                        ctx.arc(11, 9, 6, Math.PI * 0.85, Math.PI * 0.15, false);
                                        ctx.closePath();
                                        ctx.stroke();
                                    } else if (tipo === "salones") {
                                        // Puerta de aula abierta con check de disponible
                                        ctx.strokeRect(4, 3, 11, 16);
                                        ctx.beginPath();
                                        ctx.arc(12.5, 11, 0.9, 0, Math.PI * 2);
                                        ctx.moveTo(14.5, 13.5); ctx.lineTo(16.5, 15.5); ctx.lineTo(20, 11.5);
                                        ctx.stroke();
                                    }
                                }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 12

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "Servicios DAE"
                                        color: temaApp.textoPrincipal
                                        font.pixelSize: 16
                                        font.bold: true
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: "12 disponibles"
                                        color: temaApp.textoMuted
                                        font.pixelSize: 11
                                    }
                                }

                                // Cuadrícula de 4 columnas x 3 filas para alojar los 12 servicios cómodamente
                                GridLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    columns: 4
                                    rowSpacing: 10
                                    columnSpacing: 6

                                    Repeater {
                                        model: [
                                            { tipo: "rap",            nombre: "Visualizar\nRAP" },
                                            { tipo: "constancias",    nombre: "Solicitud\nConstancias" },
                                            { tipo: "carnet",         nombre: "Carnet\nUniversitario" },
                                            { tipo: "horarios",       nombre: "Horarios" },
                                            { tipo: "calendario",     nombre: "Calendario" },
                                            { tipo: "pensum",         nombre: "Pensum\nde Estudio" },
                                            { tipo: "reglamento",     nombre: "Reglamento\nEvaluación" },
                                            { tipo: "cambio_escuela", nombre: "Cambio de\nEscuela" },
                                            { tipo: "inscripcion",    nombre: "Inscripción" },
                                            { tipo: "retiro",         nombre: "Retiro de\nAsignatura" },
                                            { tipo: "mapa",           nombre: "Mapa de la\nFacultad" },
                                            { tipo: "salones",        nombre: "Salones\nDisponibles" }
                                        ]

                                        delegate: Item {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 78

                                            Column {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                anchors.top: parent.top
                                                spacing: 6

                                                // Botón cuadrado redondeado con el icono perfectamente centrado
                                                Rectangle {
                                                    id: cajaIconoSrv
                                                    width: 44; height: 44; radius: 14
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    color: temaApp.panelAlt
                                                    border.color: temaApp.bordeAlt
                                                    border.width: 1

                                                    IconoServicio {
                                                        anchors.centerIn: parent
                                                        tipo: modelData.tipo
                                                        colorTrazo: temaApp.esClaro ? temaApp.primario : temaApp.claro
                                                    }

                                                    Behavior on scale { NumberAnimation { duration: 100 } }
                                                }

                                                // Etiqueta de 1 o 2 líneas centrada debajo del icono
                                                Text {
                                                    width: 64
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: modelData.nombre
                                                    color: temaApp.textoSecundario
                                                    font.pixelSize: 10
                                                    lineHeight: 0.95
                                                    horizontalAlignment: Text.AlignHCenter
                                                    wrapMode: Text.WordWrap
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onPressed: cajaIconoSrv.scale = 0.90
                                                onReleased: cajaIconoSrv.scale = 1.0
                                                onClicked: {
                                                    if (modelData.tipo === "rap") {
                                                        rootDashboard.servicioActivo = "rap"
                                                        daeClient.registrarSolicitudReciente("RAP", "Récord Académico Oficial",
                                                                                          "Consulta del RAP • firma digital DAE", "Actualizado")
                                                    } else if (modelData.tipo === "constancias") {
                                                        rootDashboard.servicioActivo = "constancias"
                                                    } else if (modelData.tipo === "carnet") {
                                                        rootDashboard.servicioActivo = "carnet"
                                                    } else if (modelData.tipo === "horarios") {
                                                        rootDashboard.servicioActivo = "horarios"
                                                    } else if (modelData.tipo === "calendario") {
                                                        rootDashboard.servicioActivo = "calendario"
                                                    } else if (modelData.tipo === "pensum") {
                                                        rootDashboard.servicioActivo = "pensum"
                                                    } else if (modelData.tipo === "reglamento") {
                                                        rootDashboard.servicioActivo = "reglamento"
                                                    } else if (modelData.tipo === "cambio_escuela") {
                                                        rootDashboard.servicioActivo = "cambio_escuela"
                                                    } else if (modelData.tipo === "inscripcion") {
                                                        rootDashboard.servicioActivo = "inscripcion"
                                                    } else if (modelData.tipo === "mapa") {
                                                        rootDashboard.servicioActivo = "mapa"
                                                    } else if (modelData.tipo === "salones") {
                                                        rootDashboard.servicioActivo = "salones"
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // 6. SECCIÓN INFERIOR ("Solicitudes Recientes")
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 22
                            Layout.rightMargin: 22

                            Text { text: "Solicitudes Recientes"; color: temaApp.textoPrincipal; font.pixelSize: 16; font.bold: true }
                            Item { Layout.fillWidth: true }
                        }

                        Repeater {
                            model: daeClient.solicitudesRecientes

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.leftMargin: 20
                                Layout.rightMargin: 20
                                Layout.preferredHeight: 68
                                height: 68
                                radius: 20
                                color: temaApp.panel
                                border.color: temaApp.bordePanel
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 250 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    spacing: 12

                                    Rectangle {
                                        Layout.preferredWidth: 42
                                        Layout.preferredHeight: 42
                                        Layout.alignment: Qt.AlignVCenter
                                        radius: 12
                                        color: temaApp.secundario
                                        border.color: temaApp.acento
                                        border.width: 1
                                        Behavior on color { ColorAnimation { duration: 250 } }
                                        Text { anchors.centerIn: parent; text: modelData.tipo; color: "white"; font.pixelSize: 11; font.bold: true }
                                    }

                                    // Textos: ocupan el espacio restante y se recortan con "..." sin empujar el estado fuera de la tarjeta
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 0
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 2
                                        Text { text: modelData.titulo; color: temaApp.textoPrincipal; font.pixelSize: 14; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
                                        Text { text: modelData.detalle; color: temaApp.textoMuted; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
                                    }

                                    // Estado en píldora compacta, siempre dentro del borde derecho de la tarjeta
                                    Rectangle {
                                        id: pildoraEstado
                                        property color colorEstado: temaApp.esClaro ? temaApp.acento : temaApp.claro
                                        Layout.alignment: Qt.AlignVCenter
                                        Layout.preferredWidth: txtEstadoSolicitud.implicitWidth + 18
                                        Layout.maximumWidth: 104
                                        Layout.preferredHeight: 26
                                        radius: 13
                                        color: Qt.rgba(colorEstado.r, colorEstado.g, colorEstado.b, 0.14)
                                        border.color: Qt.rgba(colorEstado.r, colorEstado.g, colorEstado.b, 0.45)
                                        border.width: 1

                                        Text {
                                            id: txtEstadoSolicitud
                                            anchors.centerIn: parent
                                            width: Math.min(implicitWidth, parent.width - 12)
                                            text: modelData.estado
                                            color: pildoraEstado.colorEstado
                                            font.pixelSize: 11
                                            font.bold: true
                                            elide: Text.ElideRight
                                            horizontalAlignment: Text.AlignHCenter
                                            Behavior on color { ColorAnimation { duration: 250 } }
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: rootDashboard.abrirSolicitud(modelData.tipo)
                                }
                            }
                        }

                        // Aviso cuando todavía no se ha hecho ninguna solicitud
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 20
                            Layout.rightMargin: 20
                            Layout.preferredHeight: 58
                            visible: daeClient.solicitudesRecientes.length === 0
                            radius: 20
                            color: temaApp.panel
                            border.color: temaApp.bordePanel
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                width: parent.width - 32
                                text: "Aquí verás tus últimas solicitudes. Pide una constancia, el carnet o el horario y aparecerán listadas."
                                color: temaApp.textoMuted
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                elide: Text.ElideRight
                            }
                        }
                        // SECCIÓN DE TAREAS Y EXÁMENES (PRÓXIMOS)
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 22
                            Layout.rightMargin: 22

                            Text {
                                text: "Tareas y Exámenes"
                                color: temaApp.textoPrincipal
                                font.pixelSize: 16
                                font.bold: true
                            }
                            Item { Layout.fillWidth: true }

                            // Botón para programar una tarea o un examen nuevo
                            Rectangle {
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 34
                                radius: 17
                                color: temaApp.secundario
                                border.color: temaApp.acento
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "+"
                                    color: "white"
                                    font.pixelSize: 18
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        rootDashboard.servicioActivo = "recordatorios";
                                        vistaRecordatorios.abrirFormulario(null);
                                    }
                                }
                            }

                            Text {
                                id: txtVerTodosRec
                                visible: daeClient.recordatoriosPendientes > 0
                                text: "Ver todos"
                                color: temaApp.acentoVisible
                                font.pixelSize: 12
                                font.bold: true

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -8
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: rootDashboard.servicioActivo = "recordatorios"
                                }
                            }
                        }

                        Repeater {
                            model: {
                                // Solo los tres mas proximos y pendientes
                                var lista = [];
                                var todos = daeClient.recordatorios;
                                for (var i = 0; i < todos.length && lista.length < 3; i++) {
                                    if (!todos[i].hecho) { lista.push(todos[i]); }
                                }
                                return lista;
                            }

                            delegate: Rectangle {
                                required property var modelData

                                Layout.fillWidth: true
                                Layout.leftMargin: 20
                                Layout.rightMargin: 20
                                Layout.preferredHeight: colTarea.implicitHeight + 22
                                radius: 18
                                color: temaApp.panel
                                border.color: temaApp.bordePanel
                                border.width: 1

                                ColumnLayout {
                                    id: colTarea
                                    anchors.fill: parent
                                    anchors.margins: 11
                                    spacing: 5

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Rectangle {
                                            Layout.preferredWidth: lblTipoT.implicitWidth + 14
                                            Layout.preferredHeight: 20
                                            radius: 10
                                            color: modelData.tipo === "examen" ? "#dc2626" : temaApp.secundario
                                            Text {
                                                id: lblTipoT
                                                anchors.centerIn: parent
                                                text: modelData.tipo === "examen" ? "EXAMEN" : "TAREA"
                                                color: "white"
                                                font.pixelSize: 8
                                                font.bold: true
                                                font.letterSpacing: 0.5
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.titulo !== "" ? modelData.titulo : (modelData.materia !== "" ? modelData.materia : "Recordatorio")
                                            color: temaApp.textoPrincipal
                                            font.pixelSize: 13
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: modelData.fecha + " " + modelData.hora
                                            color: temaApp.textoMuted
                                            font.pixelSize: 10
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        visible: modelData.tipo === "examen" && modelData.temas !== ""
                                        text: "📚 " + modelData.temas
                                        color: temaApp.textoSecundario
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        visible: modelData.tipo === "tarea" && modelData.descripcion !== ""
                                        text: modelData.descripcion
                                        color: temaApp.textoSecundario
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: rootDashboard.servicioActivo = "recordatorios"
                                }
                            }
                        }

                        // Aviso cuando no hay recordatorios pendientes
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 20
                            Layout.rightMargin: 20
                            Layout.preferredHeight: 52
                            visible: daeClient.recordatoriosPendientes === 0
                            radius: 18
                            color: temaApp.panel
                            border.color: temaApp.bordePanel
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 10

                                Text {
                                    text: "🗓"
                                    font.pixelSize: 18
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: "Pulsa + para programar una tarea o un examen y te avisaré cuando se acerque la fecha."
                                    color: temaApp.textoMuted
                                    font.pixelSize: 11
                                    wrapMode: Text.WordWrap
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    rootDashboard.servicioActivo = "recordatorios";
                                    vistaRecordatorios.abrirFormulario(null);
                                }
                            }
                        }

                    }
                }

                // SUB-VISTA DE SERVICIO DAE: TAREAS Y EXÁMENES
                RecordatoriosView {
                    id: vistaRecordatorios
                    anchors.fill: parent
                    anchors.topMargin: ventanaPrincipal.insetSuperior
                    visible: rootDashboard.tabActual === 0 && rootDashboard.servicioActivo === "recordatorios"
                    onCerrar: rootDashboard.servicioActivo = ""
                }

                // SUB-VISTA DE SERVICIO DAE: VISUALIZAR RAP (Requisitos de Avance en el Pensum)
                VisualizarRapView {
                    anchors.fill: parent
                    anchors.topMargin: ventanaPrincipal.insetSuperior
                    visible: rootDashboard.tabActual === 0 && rootDashboard.servicioActivo === "rap"
                    onVolver: rootDashboard.servicioActivo = ""
                }

                // SUB-VISTA DE SERVICIO DAE: SOLICITUD DE CONSTANCIAS EN PDF
                SolicitudConstanciasView {
                    anchors.fill: parent
                    anchors.topMargin: ventanaPrincipal.insetSuperior
                    visible: rootDashboard.tabActual === 0 && rootDashboard.servicioActivo === "constancias"
                    onVolver: rootDashboard.servicioActivo = ""
                }

                // SUB-VISTA DE SERVICIO DAE: CARNET UNIVERSITARIO VIRTUAL Y DESCARGA PDF
                CarnetUniversitarioView {
                    id: vistaCarnet
                    anchors.fill: parent
                    anchors.topMargin: ventanaPrincipal.insetSuperior
                    visible: rootDashboard.tabActual === 0 && rootDashboard.servicioActivo === "carnet"
                    urlFotoEstudiante: vistaPerfil.urlFotoPerfil
                    onVolver: rootDashboard.servicioActivo = ""
                    onIrAPerfil: {
                        rootDashboard.servicioActivo = ""
                        rootDashboard.tabActual = 4
                    }
                }

                // SUB-VISTA DE SERVICIO DAE: OFERTA DE HORARIOS DE MATERIAS Y PROFESORES
                OfertaHorariosView {
                    anchors.fill: parent
                    anchors.topMargin: ventanaPrincipal.insetSuperior
                    visible: rootDashboard.tabActual === 0 && rootDashboard.servicioActivo === "horarios"
                    onVolver: rootDashboard.servicioActivo = ""
                }

                // SUB-VISTA DE SERVICIO DAE: CALENDARIO ACADÉMICO (DESCARGA PDF)
                CalendarioView {
                    anchors.fill: parent
                    anchors.topMargin: ventanaPrincipal.insetSuperior
                    visible: rootDashboard.tabActual === 0 && rootDashboard.servicioActivo === "calendario"
                    onVolver: rootDashboard.servicioActivo = ""
                }

                // SUB-VISTA DE SERVICIO DAE: PENSUM DE ESTUDIOS (1997 / 2025 / PREGUNTAS FRECUENTES)
                PensumEstudioView {
                    id: vistaPensum
                    anchors.fill: parent
                    anchors.topMargin: ventanaPrincipal.insetSuperior
                    visible: rootDashboard.tabActual === 0 && rootDashboard.servicioActivo === "pensum"
                    onVolver: rootDashboard.servicioActivo = ""
                }

                // SUB-VISTA DE SERVICIO DAE: REGLAMENTO DE EVALUACIÓN (40 ARTÍCULOS)
                ReglamentoEvaluacionView {
                    anchors.fill: parent
                    anchors.topMargin: ventanaPrincipal.insetSuperior
                    visible: rootDashboard.tabActual === 0 && rootDashboard.servicioActivo === "reglamento"
                    onVolver: rootDashboard.servicioActivo = ""
                }

                // SUB-VISTA DE SERVICIO DAE: SOLICITUD DE CAMBIO DE ESCUELA
                CambioEscuelaView {
                    anchors.fill: parent
                    anchors.topMargin: ventanaPrincipal.insetSuperior
                    visible: rootDashboard.tabActual === 0 && rootDashboard.servicioActivo === "cambio_escuela"
                    onVolver: rootDashboard.servicioActivo = ""
                }

                // SUB-VISTA DE SERVICIO DAE: INSCRIPCIÓN DE ASIGNATURAS
                InscripcionView {
                    id: vistaInscripcion
                    anchors.fill: parent
                    anchors.topMargin: ventanaPrincipal.insetSuperior
                    visible: rootDashboard.tabActual === 0 && rootDashboard.servicioActivo === "inscripcion"
                    onVolver: rootDashboard.servicioActivo = ""
                }

                // SUB-VISTA DE SERVICIO DAE: MAPA INTERACTIVO DE LA FACULTAD DE INGENIERÍA UC
                MapaFacultadView {
                    id: vistaMapaFacultad
                    anchors.fill: parent
                    anchors.topMargin: ventanaPrincipal.insetSuperior
                    visible: rootDashboard.tabActual === 0 && rootDashboard.servicioActivo === "mapa"
                    onCerrarMapa: rootDashboard.servicioActivo = ""
                }

                // SUB-VISTA DE SERVICIO DAE: SALONES DISPONIBLES POR DÍA Y HORA PARA ESTUDIAR
                SalonesDisponiblesView {
                    anchors.fill: parent
                    anchors.topMargin: ventanaPrincipal.insetSuperior
                    visible: rootDashboard.tabActual === 0 && rootDashboard.servicioActivo === "salones"
                    onVolver: rootDashboard.servicioActivo = ""
                    onVerEnMapa: function(codigoAula) {
                        rootDashboard.servicioActivo = "mapa"
                        Qt.callLater(function() {
                            vistaMapaFacultad.enfocarAulaPorCodigo(codigoAula)
                        })
                    }
                }

                // PESTAÑA 1: EXPEDIENTE DE NOTAS (Por semestres y UC acumuladas)
                ExpedienteView {
                    anchors.fill: parent
                    anchors.topMargin: ventanaPrincipal.insetSuperior
                    visible: rootDashboard.tabActual === 1
                }

                // PESTAÑA 2: REPORTE DE NOTAS TRANSCRITAS (Con Fecha/Hora de acta y Sin Transcribir)
                TranscritasView {
                    anchors.fill: parent
                    anchors.topMargin: ventanaPrincipal.insetSuperior
                    visible: rootDashboard.tabActual === 2
                }

                // PESTAÑA 3: HORARIO ASIGNADO
                HorarioView {
                    anchors.fill: parent
                    anchors.topMargin: ventanaPrincipal.insetSuperior
                    visible: rootDashboard.tabActual === 3
                }

                // PESTAÑA 4: PERFIL Y ACTUALIZACIÓN DE DATOS DAE
                PerfilView {
                    id: vistaPerfil
                    anchors.fill: parent
                    anchors.topMargin: ventanaPrincipal.insetSuperior
                    visible: rootDashboard.tabActual === 4
                }

            } // Fin de escenaPrincipal

            // =========================================================================
            // BARRA DE NAVEGACIÓN FLOTANTE (4 ESQUINAS REDONDEADAS + BOTONES DINÁMICOS)
            // Orden: [Expediente] [Transcritas] ( HOME ) [Horario] [Perfil]
            // =========================================================================
            Item {
                id: barraIconly
                width: parent.width - 28
                height: 70
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 18 + ventanaPrincipal.insetInferior
                // Se oculta mientras hay un modal abierto en el perfil o en recordatorios para no tapar sus controles
                visible: !(rootDashboard.tabActual === 4 &&
                           (vistaPerfil.editorFotoAbierto || vistaPerfil.menuFotoAbierto || vistaPerfil.selectorOpsuAbierto || vistaPerfil.modalApoyoAbierto)) &&
                         !(rootDashboard.tabActual === 0 && rootDashboard.servicioActivo === "recordatorios" &&
                           (vistaRecordatorios.formularioAbierto || vistaRecordatorios.calendarioAbierto))

                component IconoModerno: Canvas {
                    id: rootIcono
                    property string tipo: "home"
                    property color colorTrazo: "#ffffff"
                    width: 22; height: 22
                    onColorTrazoChanged: requestPaint()

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.strokeStyle = rootIcono.colorTrazo;
                        ctx.fillStyle = rootIcono.colorTrazo;
                        ctx.lineWidth = 2.0;
                        ctx.lineCap = "round";
                        ctx.lineJoin = "round";

                        if (tipo === "expediente") {
                            ctx.strokeRect(3, 3, 16, 16);
                            ctx.beginPath();
                            ctx.moveTo(7, 14); ctx.lineTo(7, 11);
                            ctx.moveTo(11, 14); ctx.lineTo(11, 8);
                            ctx.moveTo(15, 14); ctx.lineTo(15, 10);
                            ctx.stroke();
                        } else if (tipo === "transcritas") {
                            ctx.beginPath();
                            ctx.moveTo(14, 2); ctx.lineTo(6, 2); ctx.lineTo(6, 20); ctx.lineTo(18, 20); ctx.lineTo(18, 6);
                            ctx.closePath();
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.moveTo(9, 9); ctx.lineTo(15, 9);
                            ctx.moveTo(9, 13); ctx.lineTo(12, 13);
                            ctx.moveTo(11, 16); ctx.lineTo(12.5, 17.5); ctx.lineTo(15.5, 14.5);
                            ctx.stroke();
                        } else if (tipo === "home") {
                            ctx.beginPath();
                            ctx.moveTo(3, 10);
                            ctx.lineTo(11, 3);
                            ctx.lineTo(19, 10);
                            ctx.lineTo(19, 19);
                            ctx.lineTo(3, 19);
                            ctx.closePath();
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.moveTo(9, 15); ctx.lineTo(13, 15);
                            ctx.stroke();
                        } else if (tipo === "horario") {
                            ctx.strokeRect(3, 5, 16, 15);
                            ctx.beginPath();
                            ctx.moveTo(3, 10); ctx.lineTo(19, 10);
                            ctx.moveTo(8, 2); ctx.lineTo(8, 6);
                            ctx.moveTo(14, 2); ctx.lineTo(14, 6);
                            ctx.stroke();
                            ctx.fillRect(7, 13, 2.5, 2.5);
                            ctx.fillRect(12.5, 13, 2.5, 2.5);
                        } else if (tipo === "perfil") {
                            ctx.beginPath();
                            ctx.arc(11, 7.5, 3.8, 0, Math.PI * 2);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.arc(11, 20, 6.5, Math.PI * 1.15, Math.PI * 1.85);
                            ctx.stroke();
                        }
                    }
                }

                component BotonNavExpandible: Rectangle {
                    id: btnRoot
                    property int tabIndex: 0
                    property string iconoTipo: "horario"
                    property string titulo: "Horario"
                    property bool activo: rootDashboard.tabActual === tabIndex

                    height: 44
                    radius: 22
                    width: activo ? (22 + 7 + lblBoton.implicitWidth + 24) : 44
                    color: activo ? (temaApp.esClaro ? temaApp.primario : temaApp.superficie) : "transparent"
                    border.color: activo ? temaApp.acento : "transparent"
                    border.width: 1
                    clip: true

                    Behavior on width {
                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                    }
                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        x: btnRoot.activo ? 12 : 11
                        spacing: 7

                        Behavior on x {
                            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                        }

                        IconoModerno {
                            anchors.verticalCenter: parent.verticalCenter
                            tipo: btnRoot.iconoTipo
                            colorTrazo: btnRoot.activo ? "#ffffff" : temaApp.textoSecundario
                        }

                        Text {
                            id: lblBoton
                            anchors.verticalCenter: parent.verticalCenter
                            text: btnRoot.titulo
                            color: "white"
                            font.pixelSize: 12
                            font.bold: true
                            opacity: btnRoot.activo ? 1.0 : 0.0

                            Behavior on opacity {
                                NumberAnimation { duration: 200 }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            rootDashboard.servicioActivo = ""
                            rootDashboard.tabActual = btnRoot.tabIndex
                        }
                    }
                }

                ShaderEffectSource {
                    id: fuenteBlur
                    sourceItem: escenaPrincipal
                    sourceRect: Qt.rect(barraIconly.x, barraIconly.y, barraIconly.width, barraIconly.height)
                    textureSize: Qt.size(Math.round(barraIconly.width / 5), Math.round(barraIconly.height / 5))
                    live: true
                    smooth: true
                    hideSource: false
                }

                Item {
                    id: mascaraBarra
                    anchors.fill: parent
                    layer.enabled: true
                    visible: false

                    Rectangle {
                        anchors.fill: parent
                        radius: 35
                        color: "black"
                    }
                }

                MultiEffect {
                    anchors.fill: parent
                    source: fuenteBlur
                    blurEnabled: true
                    blurMax: 64
                    blur: 1.0
                    blurMultiplier: 2.0
                    saturation: 0.35
                    brightness: 0.08
                    autoPaddingEnabled: false
                    maskEnabled: true
                    maskSource: mascaraBarra

                    shadowEnabled: true
                    shadowColor: temaApp.esClaro ? "#33000000" : "#88000000"
                    shadowBlur: 0.8
                    shadowVerticalOffset: 6
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 35
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: temaApp.navGrad1 }
                        GradientStop { position: 1.0; color: temaApp.navGrad2 }
                    }
                    border.color: temaApp.navBorde
                    border.width: 1
                }

                Row {
                    id: filaBotonesNav
                    anchors.centerIn: parent
                    spacing: rootDashboard.tabActual === 0 ? 16 : 8

                    Behavior on spacing {
                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                    }

                    BotonNavExpandible {
                        anchors.verticalCenter: parent.verticalCenter
                        tabIndex: 1
                        iconoTipo: "expediente"
                        titulo: "Expediente"
                    }

                    BotonNavExpandible {
                        anchors.verticalCenter: parent.verticalCenter
                        tabIndex: 2
                        iconoTipo: "transcritas"
                        titulo: "Transcritas"
                    }

                    Item {
                        width: 54
                        height: 54
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            width: 54; height: 54; radius: 27
                            anchors.centerIn: parent
                            color: rootDashboard.tabActual === 0 ? Qt.rgba(temaApp.primario.r, temaApp.primario.g, temaApp.primario.b, 0.25) : "transparent"
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }

                        Rectangle {
                            id: botonHomeCentral
                            width: 48; height: 48; radius: 24
                            anchors.centerIn: parent
                            border.color: rootDashboard.tabActual === 0 ? temaApp.claro : temaApp.bordeAlt
                            border.width: 1.5

                            gradient: Gradient {
                                GradientStop { position: 0.0; color: rootDashboard.tabActual === 0 ? temaApp.acento : (temaApp.esClaro ? "#475569" : temaApp.panelEdit) }
                                GradientStop { position: 1.0; color: rootDashboard.tabActual === 0 ? temaApp.secundario : (temaApp.esClaro ? "#334155" : temaApp.panelAlt) }
                            }

                            IconoModerno {
                                anchors.centerIn: parent
                                tipo: "home"
                                width: 22; height: 22
                                colorTrazo: "white"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onPressed: botonHomeCentral.scale = 0.91
                                onReleased: botonHomeCentral.scale = 1.0
                                onClicked: {
                                    rootDashboard.servicioActivo = ""
                                    rootDashboard.tabActual = 0
                                }
                            }
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }
                    }

                    BotonNavExpandible {
                        anchors.verticalCenter: parent.verticalCenter
                        tabIndex: 3
                        iconoTipo: "horario"
                        titulo: "Horario"
                    }

                    BotonNavExpandible {
                        anchors.verticalCenter: parent.verticalCenter
                        tabIndex: 4
                        iconoTipo: "perfil"
                        titulo: "Perfil"
                    }
                }
            }

            // =========================================================================
            // MODAL EXPANDIBLE (CON DIFUMINADO EN MOVIMIENTO INTERNO)
            // =========================================================================
            Item {
                id: capaModal
                anchors.fill: parent
                visible: opacidadFondoModal.opacity > 0

                Rectangle {
                    id: opacidadFondoModal
                    anchors.fill: parent
                    color: "#bb040812"
                    opacity: 0

                    MouseArea {
                        anchors.fill: parent
                        enabled: rootDashboard.modalAbierto
                        onClicked: rootDashboard.cerrarModalMateria()
                    }
                }

                Item {
                    id: tarjetaExpandible
                    readonly property real altoModalObjetivo: Math.max(440, Math.min(rootDashboard.height - 80, colContenidoModal.implicitHeight + 44))

                    Item {
                        id: arteModal
                        anchors.fill: parent
                        visible: false

                        Rectangle {
                            anchors.fill: parent
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: rootDashboard.mColor1 }
                                GradientStop { position: 1.0; color: rootDashboard.mColor2 }
                            }
                        }

                        Rectangle {
                            width: 240; height: 150; radius: 75
                            color: rootDashboard.mColor3
                            opacity: 0.60
                            rotation: -30
                            x: -30; y: 10
                        }
                    }

                    Item {
                        id: mascaraModal
                        anchors.fill: parent
                        layer.enabled: true
                        visible: false
                        Rectangle {
                            anchors.fill: parent
                            radius: 26
                            color: "black"
                        }
                    }

                    MultiEffect {
                        anchors.fill: parent
                        source: arteModal
                        blurEnabled: true
                        blurMax: 64
                        blur: 1.0
                        blurMultiplier: 1.5
                        autoPaddingEnabled: false
                        maskEnabled: true
                        maskSource: mascaraModal
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 26
                        color: "transparent"
                        border.color: "#90ffffff"
                        border.width: 1.5
                    }

                    ColumnLayout {
                        id: colContenidoModal
                        anchors.fill: parent
                        anchors.margins: 22
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            Rectangle {
                                width: 64; height: 24; radius: 12
                                color: "#35ffffff"
                                Text {
                                    anchors.centerIn: parent
                                    text: rootDashboard.mCodigo
                                    color: "white"
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                radius: 16
                                color: "#35000000"
                                border.color: "#45ffffff"
                                border.width: 1
                                visible: detallesExtraHorario.opacity > 0.3

                                Canvas {
                                    width: 14; height: 14
                                    anchors.centerIn: parent
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.reset();
                                        ctx.strokeStyle = "#ffffff";
                                        ctx.lineWidth = 2.2;
                                        ctx.lineCap = "round";
                                        ctx.beginPath();
                                        ctx.moveTo(3, 3); ctx.lineTo(11, 11);
                                        ctx.moveTo(11, 3); ctx.lineTo(3, 11);
                                        ctx.stroke();
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: rootDashboard.cerrarModalMateria()
                                }
                            }
                        }

                        Text {
                            text: rootDashboard.mDepto
                            color: "#e0f2fe"
                            font.pixelSize: 12
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        Text {
                            text: rootDashboard.mNombre
                            color: "white"
                            font.pixelSize: 21
                            font.bold: true
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Text {
                                text: rootDashboard.mSeccion
                                color: "#dbeafe"
                                font.pixelSize: 15
                                font.bold: true
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }
                            Text {
                                text: rootDashboard.mProfesor
                                color: "white"
                                font.pixelSize: 13
                                visible: rootDashboard.mProfesor !== ""
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }
                        }

                        ColumnLayout {
                            id: detallesExtraHorario
                            Layout.fillWidth: true
                            Layout.topMargin: 8
                            spacing: 10
                            opacity: 0

                            Rectangle { Layout.fillWidth: true; height: 1; color: "#40ffffff" }

                            Text {
                                text: "DÍAS Y HORARIO DE CLASES"
                                color: "#e0f2fe"
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 1.1
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Math.max(50, filaHorarioModal1.implicitHeight + 22)
                                radius: 14
                                color: "#28000000"
                                border.color: "#35ffffff"
                                border.width: 1

                                RowLayout {
                                    id: filaHorarioModal1
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    spacing: 10
                                    Text { text: "🕒"; font.pixelSize: 16 }
                                    Text {
                                        text: rootDashboard.mHorario1
                                        color: "white"
                                        font.pixelSize: 12
                                        font.bold: true
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 0
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Math.max(50, filaHorarioModal2.implicitHeight + 22)
                                radius: 14
                                color: "#28000000"
                                border.color: "#35ffffff"
                                border.width: 1

                                RowLayout {
                                    id: filaHorarioModal2
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    spacing: 10
                                    Text { text: "🔬"; font.pixelSize: 16 }
                                    Text {
                                        text: rootDashboard.mHorario2
                                        color: "white"
                                        font.pixelSize: 12
                                        font.bold: true
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 0
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 44
                                radius: 22
                                color: "white"

                                Text {
                                    anchors.centerIn: parent
                                    text: "Entendido"
                                    color: "#0f172a"
                                    font.pixelSize: 14
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: rootDashboard.cerrarModalMateria()
                                }
                            }
                        }
                    }
                }

                ParallelAnimation {
                    id: animAbrirModal
                    NumberAnimation { target: opacidadFondoModal; property: "opacity"; to: 1.0; duration: 280 }
                    NumberAnimation { target: tarjetaExpandible; property: "x"; to: (rootDashboard.width - 345) / 2; duration: 360; easing.type: Easing.OutBack }
                    NumberAnimation { target: tarjetaExpandible; property: "y"; to: (rootDashboard.height - tarjetaExpandible.altoModalObjetivo) / 2; duration: 360; easing.type: Easing.OutBack }
                    NumberAnimation { target: tarjetaExpandible; property: "width"; to: 345; duration: 360; easing.type: Easing.OutBack }
                    NumberAnimation { target: tarjetaExpandible; property: "height"; to: tarjetaExpandible.altoModalObjetivo; duration: 360; easing.type: Easing.OutBack }
                    NumberAnimation { target: detallesExtraHorario; property: "opacity"; to: 1.0; duration: 320 }
                }

                ParallelAnimation {
                    id: animCerrarModal
                    NumberAnimation { target: detallesExtraHorario; property: "opacity"; to: 0.0; duration: 150 }
                    NumberAnimation { target: opacidadFondoModal; property: "opacity"; to: 0.0; duration: 260 }
                    NumberAnimation { target: tarjetaExpandible; property: "x"; to: rootDashboard.origenX; duration: 260; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: tarjetaExpandible; property: "y"; to: rootDashboard.origenY; duration: 260; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: tarjetaExpandible; property: "width"; to: rootDashboard.origenAncho; duration: 260; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: tarjetaExpandible; property: "height"; to: rootDashboard.origenAlto; duration: 260; easing.type: Easing.InOutQuad }
                }
            }
        }
    }

    // =========================================================================
    // MODAL GLOBAL DE VERIFICACIÓN BIOMÉTRICA / SENSOR DE HUELLA DACTILAR
    // =========================================================================
    Item {
        id: modalBiometriaLocal
        anchors.fill: parent
        z: 999
        property bool abierto: false
        property bool escaneando: false
        property bool verificado: false
        property string tituloBio: "Acceso Biométrico DAE UC"
        property string subtituloBio: "Verifica tu identidad para continuar"
        visible: fondoBioModal.opacity > 0

        Connections {
            target: daeClient
            function onMostrarEscanerBiometricoLocal(titulo, subtitulo) {
                modalBiometriaLocal.tituloBio = titulo
                modalBiometriaLocal.subtituloBio = subtitulo
                modalBiometriaLocal.escaneando = false
                modalBiometriaLocal.verificado = false
                modalBiometriaLocal.abierto = true
            }
        }

        Rectangle {
            id: fondoBioModal
            anchors.fill: parent
            color: "#c8040812"
            opacity: modalBiometriaLocal.abierto ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 220 } }

            MouseArea {
                anchors.fill: parent
                enabled: modalBiometriaLocal.abierto && !modalBiometriaLocal.escaneando
                onClicked: {
                    modalBiometriaLocal.abierto = false
                    daeClient.confirmarEscanerBiometricoLocal(false)
                }
            }
        }

        Rectangle {
            width: Math.min(parent.width - 40, 340)
            height: 310
            radius: 28
            anchors.centerIn: parent
            color: temaApp.panel
            border.color: modalBiometriaLocal.verificado ? "#22c55e" : temaApp.acento
            border.width: 1.5
            scale: modalBiometriaLocal.abierto ? 1.0 : 0.88
            opacity: modalBiometriaLocal.abierto ? 1.0 : 0.0

            Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack } }
            Behavior on opacity { NumberAnimation { duration: 200 } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 12

                Text {
                    text: modalBiometriaLocal.tituloBio
                    color: temaApp.textoPrincipal
                    font.pixelSize: 16
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: modalBiometriaLocal.subtituloBio
                    color: temaApp.textoSubtitulo
                    font.pixelSize: 12
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                Item { Layout.preferredHeight: 4 }

                // Círculo interactivo del sensor de huella
                Rectangle {
                    id: circuloSensorHuella
                    Layout.preferredWidth: 88
                    Layout.preferredHeight: 88
                    radius: 44
                    Layout.alignment: Qt.AlignHCenter
                    color: modalBiometriaLocal.verificado
                           ? "#2222c55e"
                           : Qt.rgba(temaApp.acento.r, temaApp.acento.g, temaApp.acento.b, modalBiometriaLocal.escaneando ? 0.28 : 0.14)
                    border.color: modalBiometriaLocal.verificado ? "#22c55e" : temaApp.acento
                    border.width: modalBiometriaLocal.escaneando ? 2.5 : 1.5

                    SequentialAnimation on scale {
                        running: modalBiometriaLocal.escaneando
                        loops: Animation.Infinite
                        NumberAnimation { to: 1.08; duration: 320; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0.96; duration: 320; easing.type: Easing.InOutSine }
                    }

                    Canvas {
                        id: canvasSensorModal
                        width: 44; height: 44
                        anchors.centerIn: parent
                        property color colorTrazo: modalBiometriaLocal.verificado ? "#22c55e" : temaApp.acento
                        onColorTrazoChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = colorTrazo;
                            ctx.lineWidth = 2.4;
                            ctx.lineCap = "round";
                            ctx.beginPath();
                            ctx.arc(22, 22, 17, Math.PI * 0.85, Math.PI * 2.15, false);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.arc(22, 22, 11.5, Math.PI * 0.75, Math.PI * 2.25, false);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.arc(22, 22, 6, Math.PI * 0.65, Math.PI * 2.35, false);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.moveTo(22, 21); ctx.lineTo(22, 36);
                            ctx.stroke();
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !modalBiometriaLocal.escaneando && !modalBiometriaLocal.verificado
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            modalBiometriaLocal.escaneando = true
                            timerEscaneoBio.restart()
                        }
                    }
                }

                Text {
                    text: modalBiometriaLocal.verificado
                          ? "✓ Identidad verificada"
                          : (modalBiometriaLocal.escaneando
                             ? "Escaneando huella dactilar..."
                             : "Toca el sensor de huella para autenticar")
                    color: modalBiometriaLocal.verificado ? "#4ade80" : temaApp.textoSecundario
                    font.pixelSize: 12
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                Timer {
                    id: timerEscaneoBio
                    interval: 650
                    onTriggered: {
                        modalBiometriaLocal.escaneando = false
                        modalBiometriaLocal.verificado = true
                        timerCerrarBioExito.restart()
                    }
                }

                Timer {
                    id: timerCerrarBioExito
                    interval: 350
                    onTriggered: {
                        modalBiometriaLocal.abierto = false
                        daeClient.confirmarEscanerBiometricoLocal(true)
                    }
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    radius: 19
                    color: temaApp.panelAlt
                    border.color: temaApp.bordeAlt
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Cancelar"
                        color: temaApp.textoSecundario
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !modalBiometriaLocal.escaneando
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            modalBiometriaLocal.abierto = false
                            daeClient.confirmarEscanerBiometricoLocal(false)
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // MODAL DE DESCARGO DE RESPONSABILIDAD (Solo la primera vez que abre la app)
    // =========================================================================
    Item {
        id: modalDescargoResponsabilidad
        anchors.fill: parent
        z: 9999
        visible: !daeClient.descargoAceptado

        property bool terminosMarcados: false

        // Fondo oscuro semitransparente que bloquea toda interacción detrás
        Rectangle {
            anchors.fill: parent
            color: temaApp.esClaro ? "#aa0f172a" : "#cc040814"
        }

        // Captura de toques en el fondo para que no pasen a la pantalla de login
        MouseArea {
            anchors.fill: parent
        }

        Rectangle {
            id: tarjetaDescargo
            width: Math.min(parent.width - 32, 430)
            height: Math.min(parent.height - ventanaPrincipal.insetSuperior - ventanaPrincipal.insetInferior - 36, 650)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: (ventanaPrincipal.insetSuperior - ventanaPrincipal.insetInferior) * 0.5
            radius: 26
            color: temaApp.panel
            border.color: temaApp.acento
            border.width: 1.5

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                // Cabecera con icono de escudo informativo
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        radius: 14
                        color: Qt.rgba(temaApp.acento.r, temaApp.acento.g, temaApp.acento.b, 0.16)
                        border.color: temaApp.acento
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
                                ctx.beginPath();
                                ctx.moveTo(11, 2.5);
                                ctx.lineTo(18.5, 5.5);
                                ctx.lineTo(18.5, 11.2);
                                ctx.quadraticCurveTo(18.5, 16.5, 11, 19.5);
                                ctx.quadraticCurveTo(3.5, 16.5, 3.5, 11.2);
                                ctx.lineTo(3.5, 5.5);
                                ctx.closePath();
                                ctx.stroke();
                                ctx.beginPath();
                                ctx.moveTo(11, 7.5);
                                ctx.lineTo(11, 11.5);
                                ctx.stroke();
                                ctx.beginPath();
                                ctx.arc(11, 14.5, 0.9, 0, Math.PI * 2);
                                ctx.fillStyle = colorTrazo;
                                ctx.fill();
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Aviso Importante y Descargo de Responsabilidad"
                        color: temaApp.textoPrincipal
                        font.pixelSize: 16
                        font.bold: true
                        wrapMode: Text.WordWrap
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: temaApp.bordePanel
                }

                // Contenido desplazable con los 4 apartados
                Flickable {
                    id: flickDescargo
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: colTextoDescargo.implicitHeight + 8
                    clip: true
                    flickableDirection: Flickable.VerticalFlick
                    boundsBehavior: Flickable.DragAndOvershootBounds

                    ColumnLayout {
                        id: colTextoDescargo
                        width: flickDescargo.width
                        spacing: 12

                        Repeater {
                            model: [
                                {
                                    titulo: "1. Proyecto Estudiantil Independiente",
                                    cuerpo: "Esta aplicación es una iniciativa individual, gratuita y de código abierto desarrollada por un estudiante para facilitar el acceso móvil a los servicios académicos. No está afiliada, respaldada ni administrada por la Dirección de Asuntos Estudiantiles (DAE), la Facultad de Ingeniería ni la Universidad de Carabobo. Los nombres y emblemas institucionales se emplean únicamente con fines descriptivos y de referencia."
                                },
                                {
                                    titulo: "2. Privacidad y Seguridad de Credenciales",
                                    cuerpo: "Tus datos de acceso (cédula y contraseña) viajan cifrados directamente desde tu dispositivo hacia los servidores oficiales del DAE. Esta aplicación no utiliza servidores intermedios ni recopila, almacena o comparte tus credenciales o registros académicos con terceros."
                                },
                                {
                                    titulo: "3. Verificación Obligatoria de Trámites e Información",
                                    cuerpo: "La información mostrada (horarios, calificaciones y expedientes) tiene fines de consulta rápida. Si realizas inscripciones, adiciones o retiros de asignaturas a través de esta aplicación, es tu responsabilidad verificar directamente en el portal web oficial del DAE que el trámite haya sido procesado correctamente. Ante cualquier discrepancia, la única fuente válida es la plataforma oficial de la universidad."
                                },
                                {
                                    titulo: "4. Licencia y Uso Bajo tu Propia Responsabilidad",
                                    cuerpo: "Este software es libre y se distribuye bajo la licencia GNU General Public License v3.0 (GPL v3), entregándose \"tal cual\" (as-is) y sin garantías de disponibilidad continua, ya que depende del funcionamiento de los servidores universitarios."
                                }
                            ]

                            delegate: ColumnLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.titulo
                                    color: temaApp.acentoVisible
                                    font.pixelSize: 13
                                    font.bold: true
                                    wrapMode: Text.WordWrap
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.cuerpo
                                    color: temaApp.textoSecundario
                                    font.pixelSize: 12
                                    lineHeight: 1.28
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: temaApp.bordePanel
                }

                // Casilla de confirmación obligatoria
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: filaCheckTerminos.implicitHeight + 16
                    radius: 14
                    color: modalDescargoResponsabilidad.terminosMarcados
                           ? Qt.rgba(temaApp.secundario.r, temaApp.secundario.g, temaApp.secundario.b, 0.14)
                           : temaApp.panelAlt
                    border.color: modalDescargoResponsabilidad.terminosMarcados ? temaApp.acento : temaApp.bordeAlt
                    border.width: 1

                    RowLayout {
                        id: filaCheckTerminos
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            radius: 6
                            color: modalDescargoResponsabilidad.terminosMarcados ? temaApp.secundario : "transparent"
                            border.color: modalDescargoResponsabilidad.terminosMarcados ? temaApp.secundario : temaApp.textoMuted
                            border.width: 1.8

                            Canvas {
                                anchors.centerIn: parent
                                width: 14
                                height: 14
                                visible: modalDescargoResponsabilidad.terminosMarcados
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.reset();
                                    ctx.strokeStyle = "#ffffff";
                                    ctx.lineWidth = 2.2;
                                    ctx.lineCap = "round";
                                    ctx.lineJoin = "round";
                                    ctx.beginPath();
                                    ctx.moveTo(2.5, 7.2);
                                    ctx.lineTo(5.8, 10.5);
                                    ctx.lineTo(11.5, 3.8);
                                    ctx.stroke();
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "He leído y comprendo los términos de uso de este visor estudiantil."
                            color: temaApp.textoPrincipal
                            font.pixelSize: 12
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            modalDescargoResponsabilidad.terminosMarcados = !modalDescargoResponsabilidad.terminosMarcados;
                        }
                    }
                }

                // Botón Aceptar y Continuar (bloqueado hasta marcar la casilla)
                Rectangle {
                    id: btnAceptarDescargo
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    radius: 23
                    color: modalDescargoResponsabilidad.terminosMarcados ? temaApp.secundario : temaApp.panelAlt
                    border.color: modalDescargoResponsabilidad.terminosMarcados ? temaApp.acento : temaApp.bordeAlt
                    border.width: 1
                    opacity: modalDescargoResponsabilidad.terminosMarcados ? 1.0 : 0.48

                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Aceptar y Continuar"
                        color: modalDescargoResponsabilidad.terminosMarcados ? "#ffffff" : temaApp.textoMuted
                        font.pixelSize: 14
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: modalDescargoResponsabilidad.terminosMarcados
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onPressed: btnAceptarDescargo.scale = 0.97
                        onReleased: btnAceptarDescargo.scale = 1.0
                        onCanceled: btnAceptarDescargo.scale = 1.0
                        onClicked: {
                            daeClient.aceptarDescargoResponsabilidad();
                        }
                    }
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }
            }
        }
    }
}
