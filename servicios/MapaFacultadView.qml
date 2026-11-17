import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: rootMapa

    // Señal para volver al Home cuando se abre desde Servicios DAE
    signal cerrarMapa()

    property real zoomMapa: 1.0
    property string textoBusqueda: ""
    property int categoriaFiltro: 0 // 0=Todos, 1=Mis Aulas, 2=Pabellones AD, 3=Escuelas/Labs, 4=Servicios
    property int idSeleccionado: 4  // Por defecto selecciona A7E

    // =========================================================================
    // PALETA DEL PLANO: se adapta al tema activo.
    // Antes el plano estaba pintado con la paleta azul oscura de Vaulta y se veía
    // igual con cualquier otro tema; ahora toma los colores de temaApp.
    // =========================================================================
    // Terreno de fondo del plano
    readonly property color colorTerreno: temaApp.fondoBase
    // Rejilla técnica de fondo
    readonly property color colorRejilla: temaApp.esClaro
            ? Qt.rgba(temaApp.oscuro.r, temaApp.oscuro.g, temaApp.oscuro.b, 0.13)
            : "#0e1a30"
    // Avenidas, calzadas y estacionamientos
    readonly property color colorAvenida: temaApp.panelAlt
    readonly property color colorAvenidaBorde: temaApp.bordeAlt
    // Caminerías y pasillos peatonales
    readonly property color colorSenda: temaApp.panelAlt
    readonly property color colorSendaBorde: temaApp.bordeAlt
    // Recintos, patios y terrenos
    readonly property color colorRecinto: temaApp.panel
    // Edificios en general
    readonly property color colorEdificio: temaApp.panelEdit
    // Escuelas, módulos AD y recintos destacados
    readonly property color colorEscuela: temaApp.esClaro ? temaApp.panel : temaApp.panelEdit
    // Zonas verdes (jardines y plazas)
    readonly property color colorVerde: temaApp.esClaro ? "#22c55e" : "#15803d"
    readonly property color colorVerdeBorde: temaApp.esClaro ? "#15803d" : "#4ade80"
    // Bordes principales (contornos de edificios)
    readonly property color colorBorde: temaApp.esClaro ? temaApp.bordeAlt : "#94a3b8"
    // Trazos finos (caminos, terrenos y detalles)
    readonly property color colorTrazo: temaApp.esClaro ? temaApp.bordePanel : "#64748b"
    // Bordes de color por categoría
    readonly property color colorBordeEscuela: temaApp.esClaro ? temaApp.acento : "#93c5fd"
    readonly property color colorBordeDestacado: temaApp.esClaro ? temaApp.primario : "#38bdf8"
    readonly property color colorBordeDeporte: temaApp.esClaro ? temaApp.primario : "#06b6d4"
    readonly property color colorBordeMiAula: temaApp.esClaro ? temaApp.acento : "#60a5fa"
    // Textos dibujados sobre los edificios
    readonly property color colorTextoEdificio: temaApp.esClaro ? temaApp.textoPrincipal : "#ffffff"
    // Textos dibujados directamente sobre el terreno
    readonly property color colorTextoPlano: temaApp.esClaro ? temaApp.textoSecundario : "#f8fafc"
    // Blanco de papel (redomas y círculo central de la plaza)
    readonly property color colorPapel: temaApp.esClaro ? "#ffffff" : "#e2e8f0"
    // Tus aulas (resaltadas)
    readonly property color colorMiAula: temaApp.panelEdit

    // Base de datos vectorial con coordenadas exactas fieles al plano oficial
    // cat: 2 = Módulos AD, 3 = Escuelas, Departamentos, Aulas y Laboratorios, 4 = DAE, Servicios, Plazas y Canchas
    property var bloquesFacultad: [
        // =========================================================================================
        // SECTOR 1 (NOROESTE): PANADERÍA, IDIOMAS, A9I, A8I, A7E, SEIN, A6E, A5E, CIVIL, DIBUJO
        // Ningún salón ni edificio se monta sobre las caminerías (x=368..380 y x=438..450)
        // =========================================================================================
        { id: 0,  cod: "PANADERÍA",       sub: "Comedor / Cafetería",               cat: 4, aulasCodigos: [],                         x: 34,  y: 128, w: 58,  h: 42, colorTipo: "panaderia",  forma: "redondeado",    desc: "Sector Noroeste • Entrada por Av. Universidad", infoExtra: "Punto de encuentro y panadería estudiantil en el borde oeste" },
        { id: 1,  cod: "DPTO DE IDIOMAS", sub: "Coordinación de Idiomas • AID",     cat: 3, aulasCodigos: ["AID", "IDIOMAS"],         x: 240, y: 194, w: 82,  h: 30, colorTipo: "blanco",     forma: "idiomas",       desc: "Fila Superior Noroeste • Frente a Estac. de Profesores", infoExtra: "Departamento de Idiomas Modernos y sala AID" },
        { id: 2,  cod: "A9I",             sub: "Aula A9I (Pabellón Norte)",         cat: 3, aulasCodigos: ["A9I"],                    x: 322, y: 194, w: 32,  h: 30, colorTipo: "aula_roja",  forma: "rect",          desc: "Fila Superior Noroeste • Entre AID y A8I", infoExtra: "Aula de clases generales e Ingeniería Industrial / Básicos" },
        { id: 3,  cod: "A8I",             sub: "Aula A8I (Pabellón Norte)",         cat: 3, aulasCodigos: ["A8I"],                    x: 354, y: 194, w: 34,  h: 30, colorTipo: "aula_roja",  forma: "rect",          desc: "Fila Superior Noroeste • Frente al camino central de Civil", infoExtra: "Aula de clases generales de Ingeniería" },
        { id: 4,  cod: "A7E",             sub: "Aula A7E (Pabellón Norte)",         cat: 3, aulasCodigos: ["A7E"],                    x: 388, y: 194, w: 26,  h: 30, colorTipo: "aula_roja",  forma: "rect",          desc: "Fila Superior Noroeste • Entre A8I y SEIN", infoExtra: "Aula del pabellón norte de Ingeniería Eléctrica / Telecom" },
        { id: 5,  cod: "SEIN",            sub: "Laboratorio SEIN",                  cat: 3, aulasCodigos: ["SEIN"],                   x: 414, y: 194, w: 24,  h: 30, colorTipo: "aula_roja",  forma: "rect",          desc: "Extremo Este de la fila A9I-SEIN • Frente a AD4", infoExtra: "Laboratorio y sala de clases SEIN" },

        { id: 6,  cod: "A6E",             sub: "Aula A6E (Segundo Bloque)",         cat: 3, aulasCodigos: ["A6E"],                    x: 240, y: 236, w: 62,  h: 28, colorTipo: "aula_roja",  forma: "rect",          desc: "Segunda Fila Noroeste • Debajo de Dpto. de Idiomas", infoExtra: "Aula amplia del bloque E" },
        { id: 7,  cod: "A5E",             sub: "Aula A5E y Cubículo",               cat: 3, aulasCodigos: ["A5E"],                    x: 302, y: 236, w: 64,  h: 28, colorTipo: "aula_roja",  forma: "a5e",           desc: "Segunda Fila Noroeste • Al lado de A6E y del camino de A8I", infoExtra: "Aula A5E con anexo lateral derecho" },

        { id: 8,  cod: "LAB. Y OFICINAS", sub: "Laboratorios y Oficinas Civil",     cat: 3, aulasCodigos: ["LCA", "LP", "LSL", "LTOP", "LME", "LEM"], x: 258, y: 308, w: 108, h: 34, colorTipo: "blanco",     forma: "lab_civil",     desc: "Entre Jardín de A6E/A5E y Civil Hidráulica", infoExtra: "Laboratorios y Oficinas de Ingeniería Civil (LCA, LP, LSL, LTOP, LME)" },
        { id: 9,  cod: "FISICO QUÍMICA",  sub: "Laboratorio de Fisicoquímica",      cat: 3, aulasCodigos: ["LFQ", "FISICOQUIMICA"],   x: 238, y: 330, w: 30,  h: 18, colorTipo: "fisicoquim", forma: "fisicoquim_box",desc: "Esquina Oeste de Laboratorios y Oficinas Civil", infoExtra: "Laboratorio de Fisicoquímica (Bloque Rojo)" },
        { id: 10, cod: "CIVIL HIDRÁULICA",sub: "AT • AFP • AFG • SH01-SH03",        cat: 3, aulasCodigos: ["AT", "AFP", "AFG", "SH01", "SH02", "SH03", "LMFC"], x: 240, y: 350, w: 126, h: 68, colorTipo: "escuela",    forma: "hidraulica",    desc: "Debajo de Laboratorios y Oficinas • Al oeste del camino de A8I", infoExtra: "Escuela de Civil Hidráulica (Salas AT, AFP, AFG, SH01-SH03 y LMFC)" },
        { id: 11, cod: "ESCUELA DE CIVIL",sub: "Dirección Escuela de Civil",        cat: 3, aulasCodigos: ["ADP"],                    x: 382, y: 298, w: 54,  h: 66, colorTipo: "escuela",    forma: "esc_civil",     desc: "Entre los dos caminos verticales • Debajo del Jardín en Cruz", infoExtra: "Edificio de la Escuela de Ingeniería Civil (Vial, Ambiental y Estructural)" },

        // --- SECTOR CENTRAL-NORTE (AD1-AD4, INDUSTRIAL, BIBLIOTECA CENTRAL, SIE, DIBUJO) ---
        { id: 12, cod: "AD4",             sub: "Auditorio / Aula AD4",              cat: 2, aulasCodigos: ["AD4"],                    x: 456, y: 144, w: 34,  h: 34, colorTipo: "ad",         forma: "trapecio_d",    desc: "Entrada Norte • Entre patio oeste y pasillo hacia AD2", infoExtra: "Módulo de aulas tipo Anfiteatro AD4" },
        { id: 13, cod: "AD2",             sub: "Auditorio / Aula AD2",              cat: 2, aulasCodigos: ["AD2"],                    x: 456, y: 244, w: 34,  h: 32, colorTipo: "ad",         forma: "trapecio_d",    desc: "Debajo de la jardinería triangular • Conectado con AD4 y El Chileno", infoExtra: "Módulo de aulas tipo Anfiteatro AD2" },
        { id: 14, cod: "LIM",             sub: "Lab. Ing. de Métodos",              cat: 3, aulasCodigos: ["LIM"],                    x: 504, y: 118, w: 26,  h: 62, colorTipo: "blanco",     forma: "lim",           desc: "Pasillo Industrial Norte • Frente a la entrada de AD4", infoExtra: "Laboratorio de Ingeniería de Métodos (LIM)" },
        { id: 15, cod: "SIO / SOE / PUBL.",sub: "Salones Industrial y Publicaciones",cat: 3, aulasCodigos: ["SIO", "SOE", "LIO"],     x: 540, y: 118, w: 32,  h: 170,colorTipo: "blanco",     forma: "sio_publ",      desc: "Frente a LIM y Escuela de Industrial • Junto a AD3 y AD1", infoExtra: "Salas de Investigación Operativa (SIO, LIO), SOE y Publicaciones" },
        { id: 16, cod: "ESC. INDUSTRIAL", sub: "SGE • Escuela de Industrial",       cat: 3, aulasCodigos: ["SGE", "LIM2", "SUM"],     x: 504, y: 190, w: 26,  h: 80, colorTipo: "escuela",    forma: "industrial",    desc: "Frente al pasillo vertical AD4-AD2", infoExtra: "Escuela de Ingeniería Industrial (Métodos, Investigación Operativa y Gerencia)" },
        { id: 17, cod: "EL CHILENO",      sub: "Cafetín y Reproducción Estudiantil",cat: 4, aulasCodigos: [],                         x: 500, y: 274, w: 30,  h: 14, colorTipo: "aula_roja",  forma: "chileno",       desc: "Al pie de Escuela de Industrial • Conectado con el pasillo de AD2", infoExtra: "Cafetín y centro de copiado 'El Chileno'" },
        { id: 18, cod: "AD3",             sub: "Auditorio / Aula AD3",              cat: 2, aulasCodigos: ["AD3"],                    x: 574, y: 138, w: 30,  h: 34, colorTipo: "ad",         forma: "trapecio_i",    desc: "Debajo de la jardinera norte • Junto a SOE y Edificio Biblioteca", infoExtra: "Módulo de aulas tipo Anfiteatro AD3" },
        { id: 19, cod: "AD1",             sub: "Auditorio / Aula AD1",              cat: 2, aulasCodigos: ["AD1"],                    x: 574, y: 238, w: 30,  h: 34, colorTipo: "ad",         forma: "trapecio_i",    desc: "Debajo del módulo azul en C • Junto a Publicaciones", infoExtra: "Módulo central de aulas tipo Anfiteatro AD1" },
        { id: 20, cod: "BIBLIOTECA CENTRAL", sub: "Aulas 101-104 • 201-209 • 301-310 • Cultura", cat: 3, aulasCodigos: ["101","102","103","104","201","202","203","204","205","206","207","208","209","301","302","303","304","305","306","307","308","309","310"], x: 614, y: 132, w: 82, h: 72, colorTipo: "aula_roja", forma: "biblio", desc: "Edificio Central de 3 Pisos • Norte + Coordinación de Cultura", infoExtra: "Biblioteca Central, Coordinación de Cultura y Aulas 101-104, 201-209 y 301-310" },
        { id: 21, cod: "SIE 1 / SIE 2",   sub: "Salones Ing. Eléctrica y Sistemas", cat: 3, aulasCodigos: ["SIE1", "SIE2"],           x: 716, y: 158, w: 58,  h: 130,colorTipo: "blanco",     forma: "sie1_sie2",     desc: "Ala Este de Biblioteca Central • Conectado con Esc. Eléctrica y SLM", infoExtra: "Salas de clase SIE 1 y SIE 2" },
        { id: 22, cod: "SIE 5 / LED",     sub: "Lab. Electrónica Digital / LLOG",   cat: 3, aulasCodigos: ["SIE5", "LED", "LLOG", "LDD"], x: 716, y: 118, w: 30, h: 40, colorTipo: "aula_roja", forma: "sie5_led", desc: "Norte de SIE 1 y Esc. Eléctrica", infoExtra: "Laboratorios SIE 5, LED, LLOG y LDD (Sistemas y Automática)" },
        { id: 23, cod: "SLM / SIE 3",     sub: "Pabellón Eléctrica Norte",          cat: 3, aulasCodigos: ["SLM", "SIE3", "LCM"],     x: 786, y: 158, w: 110, h: 36, colorTipo: "blanco",     forma: "slm_sie3",      desc: "Rectángulo al este de SIE 1 con unión central hacia Esc. Eléctrica", infoExtra: "Salones SLM, LCM (Circuitos y Mediciones) y SIE 3" },
        { id: 24, cod: "ESC. ELÉCTRICA",  sub: "Escuela de Ing. Eléctrica",         cat: 3, aulasCodigos: ["LE1", "LE2", "LE3", "LAU1", "LAU2", "LCTR", "LABCOM", "SIE4", "SIE6"], x: 730, y: 194, w: 34,  h: 94, colorTipo: "escuela",    forma: "esc_elec",      desc: "Sector Este • Junto a SIE 1 y SIE 2", infoExtra: "Escuela de Ingeniería Eléctrica (Circuitos y Mediciones, Electrónica y Comunicaciones, Potencia, Sistemas y Automática)" },

        // --- BLOQUE CENTRAL: QUÍMICA, DIBUJO (SD3, SD2, SD1, SDC), ESTUDIOS BÁSICOS, DECANATO/CONTROL DE ESTUDIOS ---
        { id: 25, cod: "CUB. Y LAB QUÍMICA", sub: "Cubículos y Lab. de Química",    cat: 3, aulasCodigos: ["LQG", "LABQUIMICA"],      x: 452, y: 298, w: 78,  h: 24, colorTipo: "blanco",     forma: "quimica_cub",   desc: "Al este de Escuela de Civil y debajo del pasillo de El Chileno", infoExtra: "Cubículos de profesores y Laboratorio de Química General" },
        { id: 26, cod: "DPTO DE DIBUJO",  sub: "AGD • APD • SD3 • SD2 • SD1 • SDC", cat: 3, aulasCodigos: ["AGD","APD","SD1","SD2","SD3","SDC"], x: 452, y: 340, w: 78, h: 30, colorTipo: "blanco", forma: "dibujo", desc: "Debajo de la jardinera de Química y sobre Estudios Básicos", infoExtra: "Salas de Dibujo SD3, SD2, SD1, SDC, AGD y APD" },
        { id: 27, cod: "ESTUDIOS BÁSICOS",sub: "Dirección de Estudios Básicos",     cat: 4, aulasCodigos: [],                         x: 452, y: 376, w: 78,  h: 24, colorTipo: "blanco",     forma: "est_basicos",   desc: "Debajo de Dpto. de Dibujo • Con caminería inferior y 3 módulos", infoExtra: "Dirección de Estudios Básicos de Ingeniería" },
        { id: 28, cod: "A4M / A3M / DIREC", sub: "Aulas A4M, A3M y Direc. Académ.", cat: 3, aulasCodigos: ["A4M", "A3M"],             x: 286, y: 434, w: 80,  h: 26, colorTipo: "aula_roja",  forma: "a4m_a3m",       desc: "Borde Sur de Civil Hidráulica • Al oeste del camino hacia Los Mangos", infoExtra: "Aulas A4M, A3M y Dirección Académica" },

        // --- SECTOR ESTE (MATEMÁTICAS, IMYCA, REDUC, AD5-AD9, HUMANIDADES, QUÍMICA, CANCHAS) ---
        { id: 29, cod: "DPTO MATEMÁTICAS", sub: "Cubículos de Matemática",          cat: 3, aulasCodigos: [],                         x: 808, y: 228, w: 60,  h: 20, colorTipo: "blanco",     forma: "matematicas",   desc: "Sector Este • Frente a Estacionamiento de Profesores", infoExtra: "Departamento de Matemática (Análisis, Álgebra, EDO)" },
        { id: 30, cod: "I.M.Y.C.A.",      sub: "Instituto de Materiales",           cat: 3, aulasCodigos: ["IMYCA"],                  x: 860, y: 228, w: 38,  h: 74, colorTipo: "blanco",     forma: "imyca",         desc: "Sector Este • Entre Dpto. Matemáticas y REDUC", infoExtra: "Instituto de Materiales y Modelos Estructurales" },
        { id: 31, cod: "REDUC",           sub: "Red Universitaria UC",              cat: 4, aulasCodigos: [],                         x: 904, y: 230, w: 24,  h: 34, colorTipo: "panaderia",  forma: "reduc",         desc: "Extremo Este • Sobre AD6", infoExtra: "Centro de Servidores y Telecomunicaciones REDUC" },
        { id: 32, cod: "AD5",             sub: "Auditorio / Aula AD5",              cat: 2, aulasCodigos: ["AD5"],                    x: 804, y: 272, w: 34,  h: 34, colorTipo: "ad",         forma: "trapecio_d",    desc: "Sector Este • Debajo de Dpto. Matemáticas", infoExtra: "Módulo de aulas AD5" },
        { id: 33, cod: "AD6",             sub: "Auditorio / Aula AD6",              cat: 2, aulasCodigos: ["AD6"],                    x: 902, y: 272, w: 42,  h: 34, colorTipo: "ad",         forma: "trapecio_i",    desc: "Extremo Este • Debajo de REDUC", infoExtra: "Módulo de aulas AD6" },
        { id: 34, cod: "AD8",             sub: "Auditorio / Aula AD8",              cat: 2, aulasCodigos: ["AD8"],                    x: 802, y: 346, w: 34,  h: 36, colorTipo: "ad",         forma: "trapecio_d",    desc: "Sector Sureste • Al oeste de Humanidades", infoExtra: "Módulo de aulas AD8" },
        { id: 35, cod: "DPTO HUMANIDADES",sub: "HU • Dpto. de Ciencias Humanas",    cat: 3, aulasCodigos: ["HU"],                     x: 844, y: 352, w: 56,  h: 34, colorTipo: "blanco",     forma: "humanidades",   desc: "Entre AD8 y AD7 • Sector Sureste", infoExtra: "Departamento de Ciencias Humanas (HU)" },
        { id: 36, cod: "AD7",             sub: "Auditorio / Aula AD7",              cat: 2, aulasCodigos: ["AD7"],                    x: 902, y: 346, w: 42,  h: 36, colorTipo: "ad",         forma: "trapecio_i",    desc: "Extremo Sureste • Al este de Humanidades", infoExtra: "Módulo de aulas AD7" },
        { id: 37, cod: "AD9",             sub: "Auditorio / Aula AD9",              cat: 2, aulasCodigos: ["AD9"],                    x: 902, y: 408, w: 42,  h: 36, colorTipo: "ad",         forma: "trapecio_i",    desc: "Esquina Sureste • Al lado de Escuela de Química", infoExtra: "Módulo de aulas AD9" },
        { id: 38, cod: "CANCHAS DEPORTIVAS", sub: "Cancha Básquet y Cancha Fútbol", cat: 4, aulasCodigos: ["DEP2"],                   x: 988, y: 324, w: 54,  h: 120,colorTipo: "deporte",    forma: "canchas",       desc: "Ala Exterior Este • Junto a Entrada por Medicina", infoExtra: "Cancha de Básquet (arriba) y Cancha de Fútbol (abajo)" },

        // --- SECTOR CENTRAL (FÍSICA, COMPUTACIÓN, CAFETÍN, BOULEVARD, MÁQ. ELÉCTRICAS, PLAZA LOS MANGOS, DECANATO/DAE) ---
        { id: 39, cod: "CUB. Y LAB. FÍSICA", sub: "AF1 • AF2 • Lab. de Física",     cat: 3, aulasCodigos: ["AF1", "AF2", "LF1", "LF1A", "LF1B"], x: 538, y: 298, w: 122, h: 26, colorTipo: "blanco", forma: "fisica_af",   desc: "Centro • Debajo de Publicaciones y AD1", infoExtra: "Departamento de Física, Aulas AF1, AF2 y Laboratorios LF1A, LF1B" },
        { id: 40, cod: "LAB. MÁQ. ELÉCTRICAS", sub: "Máquinas Eléctricas • ALT • Lab. Procesos HP2", cat: 3, aulasCodigos: ["ALT","HP2","LM1","LM2","LM3"], x: 670, y: 298, w: 92, h: 78, colorTipo: "blanco", forma: "maq_procesos", desc: "Centro-Este • Debajo de Jardín de Cultura y SIE 2", infoExtra: "Laboratorio de Máquinas Eléctricas (LM1-LM3, Dpto. de Potencia), Sala ALT y Lab. HP2" },
        { id: 41, cod: "PLAZA LOS MANGOS", sub: "Corazón de Ingeniería",            cat: 4, aulasCodigos: [],                         x: 382, y: 374, w: 54,  h: 104,colorTipo: "verde",      forma: "mangos",        desc: "Zona Central • Entre los dos caminos verticales al sur de Civil", infoExtra: "Plaza icónica de descanso estudiantil con redoma central" },
        { id: 42, cod: "CAFETÍN CENTRAL", sub: "Cafetín junto al Boulevard",        cat: 4, aulasCodigos: [],                         x: 538, y: 386, w: 64,  h: 28, colorTipo: "blanco",     forma: "cafetin",       desc: "Centro • Entre Dirección de Estudios Básicos y el Boulevard", infoExtra: "Cafetín central estudiantil al norte del Decanato" },
        { id: 43, cod: "DECANATO / DAE",  sub: "CONTROL DE ESTUDIOS • FOTOCOPIAS",  cat: 4, aulasCodigos: [],                         x: 452, y: 421, w: 122, h: 57, colorTipo: "importante", forma: "decanato_t",    desc: "Edificio en 'T' al este de Plaza Los Mangos • Control de Estudios y Fotocopias", infoExtra: "Decanato de Ingeniería, DAE, Control de Estudios (recuadro azul) y Fotocopias" },

        // --- SECTOR OESTE Y SUR (MECÁNICA, IGUANAS, MANEIRO, AULAS AE, FACYT, TELECOM, SALUD) ---
        { id: 44, cod: "ESC. MECÁNICA",   sub: "C.I.Q. • ASOVAC • ANM • ASM • SPM • Biblio. • Lab. Térmicas", cat: 3, aulasCodigos: ["ANM","ASM","SPM","SPG","CIQ","LDM","LCAU","LMAT","LPROC","MPROC","LTER","LMFM","LMF","ADH2"], x: 42, y: 368, w: 184, h: 112, colorTipo: "blanco", forma: "complejo_mecanica", desc: "Sector Suroeste • Debajo de la curva de Panadería", infoExtra: "Escuela de Ingeniería Mecánica (Térmica y Energética, Diseño Mecánico y Automatización, Materiales y Procesos de Fabricación), C.I.Q., ANM, ASM y SPM" },
        { id: 45, cod: "PLAZA LAS IGUANAS", sub: "Jardín de Entrada a Ingeniería",  cat: 4, aulasCodigos: [],                         x: 38,  y: 516, w: 188, h: 58, colorTipo: "verde",      forma: "plaza_iguanas", desc: "Entrada Suroeste • Bajo Vigilancia de Ingeniería", infoExtra: "Plaza Las Iguanas con sus 3 redomas circulares y caminerías" },
        { id: 46, cod: "AUDITORIO MANEIRO", sub: "Auditorio Ninoska Maneiro",       cat: 4, aulasCodigos: [],                         x: 40,  y: 652, w: 28,  h: 48, colorTipo: "verde",      forma: "auditorio_maneiro", desc: "Esquina Suroeste • Debajo de FCU / AE1", infoExtra: "Auditorio Ninoska Maneiro de la Facultad de Ingeniería" },
        { id: 47, cod: "FACYT",           sub: "Facultad de Ciencias y Tecnología", cat: 3, aulasCodigos: ["FACYT"],                  x: 312, y: 526, w: 204, h: 162,colorTipo: "blanco",     forma: "facyt_area",    desc: "Sector Sur • Junto a Aulas A10, A11 e Imágenes", infoExtra: "Facultad de Ciencias y Tecnología (FACYT) y Estacionamiento de FACYT" },
        { id: 48, cod: "ESC. TELECOM",    sub: "Escuela de Ing. de Telecomunicaciones", cat: 3, aulasCodigos: ["TELECOM", "LABSS", "LABER", "LCTEL", "LABANT"], x: 606, y: 556, w: 54, h: 32, colorTipo: "importante", forma: "esc_telecom", desc: "Sector Sur • Pasillo Entrada por FACYT junto al parque verde", infoExtra: "Escuela de Ingeniería de Telecomunicaciones (Señales y Sistemas • Electromagnetismo y Radiación • LABSS, LABER, LCTEL, LABANT)" },
        { id: 49, cod: "AD1M",            sub: "Auditorio / Aula AD1M (Salud)",     cat: 2, aulasCodigos: ["AD1M"],                   x: 644, y: 598, w: 32,  h: 32, colorTipo: "ad",         forma: "trapecio_d",    desc: "Sector Sureste • Debajo de Escuela de Telecom", infoExtra: "Módulo de aulas tipo Anfiteatro AD1M (Ciencias de la Salud)" },
        { id: 50, cod: "C.E.I. / COMPUTACIÓN", sub: "Cubic. Física 2 • Computación",cat: 3, aulasCodigos: ["COMP", "LC1", "LC3", "LF2"], x: 538, y: 344, w: 88,  h: 24, colorTipo: "blanco",   forma: "cei_comp",      desc: "Centro • Entre la jardinera de Física y el Cafetín", infoExtra: "Departamento de Computación (LC1, LC3), Cubículos de Física 2 (LF2) y C.E.I." },
        { id: 51, cod: "BOULEVARD",       sub: "Pasillo Central y Baños",           cat: 4, aulasCodigos: [],                         x: 604, y: 368, w: 34,  h: 70, colorTipo: "ad",         forma: "boulevard",     desc: "Al este del Cafetín • Conecta Computación con la Plaza del Decanato", infoExtra: "Boulevard central estudiantil y módulo de Baños adyacente" },
        { id: 52, cod: "MANTENIMIENTO",   sub: "Coordinación de Mantenimiento",     cat: 4, aulasCodigos: [],                         x: 670, y: 384, w: 92,  h: 26, colorTipo: "importante", forma: "mantenim",      desc: "Debajo de Lab. Procesos HP2 • Norte del Estacionamiento Central", infoExtra: "Módulo de Mantenimiento y Servicios Generales de Ingeniería" },
        { id: 53, cod: "OPERACIONES UNITARIAS", sub: "Lab. de Operaciones Unitarias",  cat: 3, aulasCodigos: ["LOU", "LOU1", "LOU2"],  x: 766, y: 116, w: 78,  h: 28, colorTipo: "blanco",     forma: "op_unit",       desc: "Esquina Noreste • Conectado al este de LED / SIE 5", infoExtra: "Laboratorio de Operaciones Unitarias LOU1 y LOU2 (Ing. Química)" },
        { id: 54, cod: "COORD. ESTUDIANTIL", sub: "Coordinación Estudiantil",         cat: 4, aulasCodigos: [],                       x: 844, y: 390, w: 26,  h: 46, colorTipo: "blanco",     forma: "coord_est",     desc: "Debajo de Dpto. de Humanidades (HU)", infoExtra: "Coordinación de Asuntos Estudiantiles" },
        { id: 55, cod: "ESC. QUÍMICA",    sub: "Escuela de Ing. Química",           cat: 3, aulasCodigos: ["AEIQ", "LCQ", "LIQ", "LQA", "LQO"], x: 874, y: 404, w: 26, h: 40, colorTipo: "importante", forma: "esc_quim", desc: "Entre Coord. Estudiantil y AD9", infoExtra: "Escuela de Ingeniería Química (Química Tecnológica e Ingeniería Química • AEIQ, LCQ, LIQ, LQA, LQO)" },
        { id: 56, cod: "FCU / AE1 - AE3", sub: "FCU y Aulas Exteriores AE1, AE2, AE3", cat: 3, aulasCodigos: ["AE1","AE2","AE3","FCU"], x: 44, y: 588, w: 20, h: 48, colorTipo: "blanco",  forma: "fcu_ae1_3",     desc: "Sector Suroeste • Debajo de Plaza Las Iguanas", infoExtra: "Oficina FCU y Aulas Exteriores AE1, AE2 y AE3" },
        { id: 57, cod: "AE8 / AE9",       sub: "Aulas Exteriores AE8 y AE9",        cat: 3, aulasCodigos: ["AE8", "AE9"],             x: 92,  y: 622, w: 52,  h: 24, colorTipo: "deporte",    forma: "ae8_ae9",       desc: "Sector Suroeste • Entre los 3 árboles y AE4-AE7", infoExtra: "Aulas Exteriores AE8 y AE9" },
        { id: 58, cod: "AE4 - AE7",       sub: "Aulas Exteriores AE4, AE5, AE6 y AE7", cat: 3, aulasCodigos: ["AE4","AE5","AE6","AE7"], x: 84, y: 656, w: 48, h: 24, colorTipo: "aula_roja",  forma: "ae4_7",         desc: "Sector Suroeste • Al este de Auditorio Ninoska Maneiro", infoExtra: "Aulas Exteriores AE4, AE5, AE6 y AE7" },
        { id: 59, cod: "A10 / A11",       sub: "Aulas A10 y A11 (FACYT)",           cat: 3, aulasCodigos: ["A10", "A11"],             x: 286, y: 520, w: 18,  h: 88, colorTipo: "blanco",     forma: "a10_a11",       desc: "Entrada Norte de FACYT", infoExtra: "Aulas A10 y A11" },
        { id: 60, cod: "IMÁGENES",        sub: "Módulo de Imágenes",                cat: 3, aulasCodigos: ["IMAGENES"],               x: 262, y: 606, w: 22,  h: 70, colorTipo: "blanco",     forma: "imagenes_box",  desc: "Al suroeste de A11 • Sector FACYT", infoExtra: "Edificio de Imágenes" },
        { id: 61, cod: "AD2M",            sub: "Auditorio / Aula AD2M (Salud)",     cat: 2, aulasCodigos: ["AD2M"],                   x: 758, y: 604, w: 34,  h: 32, colorTipo: "ad",         forma: "trapecio_i",    desc: "Sector Sureste • Al este de Medicina", infoExtra: "Módulo de aulas tipo Anfiteatro AD2M (Ciencias de la Salud)" },
        { id: 62, cod: "MEDICINA (SALUD)",sub: "Facultad de Ciencias de la Salud",  cat: 3, aulasCodigos: [],                         x: 682, y: 566, w: 72,  h: 64, colorTipo: "escuela",    forma: "salud_area",    desc: "Sector Sureste • Entre AD1M y AD2M", infoExtra: "Facultad de Ciencias de la Salud • Escuela de Medicina" }
    ]

    readonly property var bloqueSeleccionadoObj: bloquesFacultad[idSeleccionado]

    Connections {
        target: daeClient
        function onHorarioAsignadoChanged() {
            canvasPlano.requestPaint();
        }
    }

    function seleccionarBloque(idx) {
        rootMapa.idSeleccionado = idx;
        canvasPlano.requestPaint();
        var b = bloquesFacultad[idx];
        var targetX = (b.x + b.w / 2) * rootMapa.zoomMapa - flickMapa.width / 2;
        var targetY = (b.y + b.h / 2) * rootMapa.zoomMapa - flickMapa.height / 2;
        flickMapa.contentX = Math.max(0, Math.min(targetX, flickMapa.contentWidth - flickMapa.width));
        flickMapa.contentY = Math.max(0, Math.min(targetY, flickMapa.contentHeight - flickMapa.height));
    }

    function enfocarAulaPorCodigo(codigoAula) {
        var codClean = String(codigoAula || "").split(" ")[0].toUpperCase().replace(/[^A-Z0-9]/g, "");
        if (codClean === "") return;
        rootMapa.categoriaFiltro = 0;
        for (var i = 0; i < bloquesFacultad.length; i++) {
            var b = bloquesFacultad[i];
            if (b.aulasCodigos) {
                for (var k = 0; k < b.aulasCodigos.length; k++) {
                    if (b.aulasCodigos[k] === codClean) {
                        seleccionarBloque(i);
                        return;
                    }
                }
            }
            if (String(b.cod).toUpperCase().replace(/[^A-Z0-9]/g, "") === codClean) {
                seleccionarBloque(i);
                return;
            }
        }
    }

    // Verifica en vivo si el bloque contiene alguna de las aulas inscritas en el horario del semestre actual
    function esMiAulaHorario(item) {
        if (!item || !item.aulasCodigos || item.aulasCodigos.length === 0) return false;
        var dias = daeClient.diasHorarioAsignado;
        if (!dias || dias.length === 0) return false;
        for (var d = 0; d < dias.length; d++) {
            var clases = dias[d].clases;
            if (!clases) continue;
            for (var c = 0; c < clases.length; c++) {
                var baseCod = clases[c].aulaCodigo ? clases[c].aulaCodigo : String(clases[c].aula || "").split(" ")[0];
                var aulaRaw = String(baseCod).toUpperCase().replace(/[^A-Z0-9]/g, "");
                if (aulaRaw === "") continue;
                for (var k = 0; k < item.aulasCodigos.length; k++) {
                    if (item.aulasCodigos[k] === aulaRaw) return true;
                }
            }
        }
        return false;
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

    function cumpleFiltro(item) {
        if (rootMapa.categoriaFiltro === 1 && !rootMapa.esMiAulaHorario(item)) return false;
        if (rootMapa.categoriaFiltro === 2 && item.cat !== 2) return false;
        if (rootMapa.categoriaFiltro === 3 && item.cat !== 3) return false;
        if (rootMapa.categoriaFiltro === 4 && item.cat !== 4) return false;

        if (rootMapa.textoBusqueda !== "") {
            var textoItem = (item.cod || "") + " " + (item.sub || "") + " " + (item.infoExtra || "");
            return rootMapa.coincideBusqueda(textoItem, rootMapa.textoBusqueda);
        }
        return true;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // 1. CABECERA + CONTROLES DE ZOOM
        RowLayout {
            Layout.fillWidth: true
            Layout.maximumWidth: rootMapa.width - 32
            Layout.topMargin: 20
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 38; Layout.preferredHeight: 38; radius: 19
                Layout.fillWidth: false
                color: "#25ffffff"
                border.color: "#45ffffff"
                border.width: 1

                Text { anchors.centerIn: parent; text: "←"; color: temaApp.textoPrincipal; font.pixelSize: 18; font.bold: true }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: rootMapa.cerrarMapa()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.minimumWidth: 0
                spacing: 1
                Text {
                    text: "Plano de Ingeniería UC"
                    color: temaApp.textoPrincipal
                    font.pixelSize: 18
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: "Geometría al Plano Oficial • Bárbula"
                    color: temaApp.textoSecundario
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Botones de Zoom (- / 100% / +)
            Rectangle {
                Layout.preferredWidth: 100; Layout.preferredHeight: 36; radius: 18
                Layout.fillWidth: false
                color: temaApp.panelAlt
                border.color: temaApp.bordeAlt
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 2

                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                        color: temaApp.panel
                        border.color: temaApp.bordeAlt
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "−"
                            color: temaApp.textoPrincipal
                            font.pixelSize: 15
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: rootMapa.zoomMapa = Math.max(0.65, rootMapa.zoomMapa - 0.25)
                        }
                    }

                    Text {
                        text: Math.round(rootMapa.zoomMapa * 100) + "%"
                        color: temaApp.textoSecundario
                        font.pixelSize: 10
                        font.bold: true
                    }

                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 14
                        color: temaApp.primario
                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            color: temaApp.esClaro ? temaApp.textoPrincipal : "#ffffff"
                            font.pixelSize: 15
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: rootMapa.zoomMapa = Math.min(2.6, rootMapa.zoomMapa + 0.25)
                        }
                    }
                }
            }
        }

        // 2. BUSCADOR INTELIGENTE DE AULAS Y PABELLONES
        Rectangle {
            Layout.fillWidth: true
            Layout.maximumWidth: rootMapa.width - 32
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.preferredHeight: 42
            radius: 21
            color: temaApp.panelEdit
            border.color: inputBuscarAula.activeFocus ? temaApp.acento : temaApp.bordePanel
            border.width: 1
            clip: true

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 12
                spacing: 8

                Canvas {
                    Layout.preferredWidth: 16; Layout.preferredHeight: 16
                    Layout.fillWidth: false
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.strokeStyle = temaApp.acentoVisible;
                        ctx.lineWidth = 2.0;
                        ctx.lineCap = "round";
                        ctx.beginPath(); ctx.arc(7, 7, 5, 0, Math.PI * 2); ctx.stroke();
                        ctx.beginPath(); ctx.moveTo(11, 11); ctx.lineTo(15, 15); ctx.stroke();
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    Layout.minimumWidth: 0
                    Layout.fillHeight: true
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Buscar aula o lugar (ej. A9I, A8I, A7E, SEIN, A6E, A5E, SD1)..."
                        color: temaApp.textoSecundario
                        font.pixelSize: 12
                        visible: inputBuscarAula.text === ""
                        elide: Text.ElideRight
                        width: parent.width
                    }
                    TextInput {
                        id: inputBuscarAula
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        // El color del texto debe seguir al tema (en claro va oscuro,
                        // si no las letras se verían blancas sobre fondo crema)
                        color: temaApp.textoPrincipal
                        selectionColor: temaApp.acento
                        selectedTextColor: "#ffffff"
                        font.pixelSize: 12
                        selectByMouse: true
                        clip: true
                        onTextChanged: {
                            rootMapa.textoBusqueda = text.trim().toUpperCase();
                            for (var i = 0; i < rootMapa.bloquesFacultad.length; i++) {
                                if (rootMapa.cumpleFiltro(rootMapa.bloquesFacultad[i])) {
                                    rootMapa.idSeleccionado = i;
                                    break;
                                }
                            }
                            canvasPlano.requestPaint();
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 20; Layout.preferredHeight: 20; radius: 10
                    Layout.fillWidth: false
                    color: Qt.rgba(temaApp.textoPrincipal.r, temaApp.textoPrincipal.g, temaApp.textoPrincipal.b, 0.12)
                    visible: inputBuscarAula.text !== ""
                    Canvas {
                        width: 10; height: 10
                        anchors.centerIn: parent
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.strokeStyle = temaApp.textoPrincipal;
                            ctx.lineWidth = 1.8;
                            ctx.lineCap = "round";
                            ctx.beginPath();
                            ctx.moveTo(2, 2); ctx.lineTo(8, 8);
                            ctx.moveTo(8, 2); ctx.lineTo(2, 8);
                            ctx.stroke();
                        }
                    }
                    MouseArea { anchors.fill: parent; onClicked: inputBuscarAula.text = "" }
                }
            }
        }

        // 3. PÍLDORAS DE FILTRO RÁPIDO
        Flickable {
            Layout.fillWidth: true
            Layout.maximumWidth: rootMapa.width
            Layout.minimumWidth: 0
            Layout.preferredHeight: 32
            contentWidth: rowCategorias.implicitWidth + 32
            clip: true

            Row {
                id: rowCategorias
                x: 16
                spacing: 8

                Repeater {
                    model: [
                        { idx: 0, nom: "Todo el Plano" },
                        { idx: 1, nom: "★ Mis Aulas" },
                        { idx: 2, nom: "Módulos AD1 - AD9" },
                        { idx: 3, nom: "Escuelas y Labs" },
                        { idx: 4, nom: "DAE y Plazas" }
                    ]

                    delegate: Rectangle {
                        property bool act: rootMapa.categoriaFiltro === modelData.idx
                        width: txtCat.implicitWidth + 22
                        height: 30; radius: 15
                        color: act ? temaApp.primario : temaApp.panelEdit
                        border.color: act ? temaApp.acentoVisible : temaApp.bordeAlt
                        border.width: 1

                        Text {
                            id: txtCat
                            anchors.centerIn: parent
                            text: modelData.nom
                            // El texto debe usar un color de TEXTO: con el tono de borde
                            // (gris azulado oscuro) quedaba ilegible en oscuro y OLED
                            color: act ? (temaApp.esClaro ? temaApp.textoPrincipal : "#ffffff")
                                       : temaApp.textoSecundario
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                rootMapa.categoriaFiltro = modelData.idx;
                                for (var k = 0; k < rootMapa.bloquesFacultad.length; k++) {
                                    if (rootMapa.cumpleFiltro(rootMapa.bloquesFacultad[k])) {
                                        rootMapa.idSeleccionado = k;
                                        break;
                                    }
                                }
                                canvasPlano.requestPaint();
                            }
                        }
                    }
                }
            }
        }

        // 4. VISOR INTERACTIVO DEL PLANO (ESCALADO EN GPU SIN LAG)
        Rectangle {
            Layout.fillWidth: true
            Layout.maximumWidth: rootMapa.width - 32
            Layout.minimumWidth: 0
            Layout.fillHeight: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            radius: 24
            color: temaApp.fondoBase
            border.color: temaApp.bordePanel
            border.width: 1.5
            clip: true

            Flickable {
                id: flickMapa
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
                        id: timerTecladoMapa
                        interval: 280
                        onTriggered: {
                            flickMapa.restaurarPosicion();
                        }
                    }
                }

                // Cuando el teclado se cierra, Qt deja el contenido corrido:
                // se devuelve a la posición en la que estaba el usuario.
                Connections {
                    target: daeClient
                    function onTecladoVisibleChanged() {
                        if (!daeClient.tecladoVisible) {
                            flickMapa.restaurarPosicion();
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
                contentWidth: 1060 * rootMapa.zoomMapa
                contentHeight: 740 * rootMapa.zoomMapa
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                WheelHandler {
                    onWheel: (event) => {
                        if (event.angleDelta.y > 0)
                            rootMapa.zoomMapa = Math.min(2.6, rootMapa.zoomMapa + 0.12);
                        else
                            rootMapa.zoomMapa = Math.max(0.65, rootMapa.zoomMapa - 0.12);
                    }
                }

                Item {
                    id: contenedorEscalable
                    width: 1060
                    height: 740
                    transformOrigin: Item.TopLeft
                    scale: rootMapa.zoomMapa

                    Canvas {
                        id: canvasPlano
                        anchors.fill: parent
                        renderTarget: Canvas.FramebufferObject
                        renderStrategy: Canvas.Cooperative

                        // El plano se repinta solo cuando cambia el tema activo
                        Connections {
                            target: rootMapa
                            function onColorTerrenoChanged() { canvasPlano.requestPaint(); }
                            function onColorEdificioChanged() { canvasPlano.requestPaint(); }
                            function onColorSendaChanged() { canvasPlano.requestPaint(); }
                            function onColorBordeChanged() { canvasPlano.requestPaint(); }
                            function onColorTrazoChanged() { canvasPlano.requestPaint(); }
                            function onColorTextoEdificioChanged() { canvasPlano.requestPaint(); }
                            function onColorVerdeChanged() { canvasPlano.requestPaint(); }
                            function onColorMiAulaChanged() { canvasPlano.requestPaint(); }
                        }

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();

                            // 1. FONDO RETICULADO TÉCNICO
                            ctx.fillStyle = rootMapa.colorTerreno;
                            ctx.fillRect(0, 0, 1060, 740);

                            ctx.strokeStyle = rootMapa.colorRejilla;
                            ctx.lineWidth = 1;
                            ctx.beginPath();
                            for (var gx = 0; gx < 1060; gx += 35) {
                                ctx.moveTo(gx, 0); ctx.lineTo(gx, 740);
                            }
                            for (var gy = 0; gy < 740; gy += 35) {
                                ctx.moveTo(0, gy); ctx.lineTo(1060, gy);
                            }
                            ctx.stroke();

                            // 2. AVENIDAS Y CONTORNOS ARQUITECTÓNICOS FIELES A LA IMAGEN
                            var hayFiltroActivo = (rootMapa.categoriaFiltro !== 0 || rootMapa.textoBusqueda !== "");
                            var alphaContexto = hayFiltroActivo ? 0.16 : 1.0;
                            ctx.globalAlpha = alphaContexto;

                            ctx.fillStyle = rootMapa.colorAvenida;
                            ctx.strokeStyle = rootMapa.colorAvenidaBorde;
                            ctx.lineWidth = 2.0;

                            // Av. Universidad (Oeste vertical)
                            ctx.fillRect(6, 60, 20, 650);
                            ctx.strokeRect(6, 60, 20, 650);

                            // Vía Norte (Estacionamiento de Estudiantes)
                            ctx.fillRect(26, 65, 930, 38);
                            ctx.strokeRect(26, 65, 930, 38);

                            // =========================================================================
                            // SECTOR NOROESTE FIEL A LA IMAGEN:
                            // - Gran terreno curvo de Panadería con puerta abatible en el acceso
                            // - Estacionamiento de profesores con bordes curvos de entrada
                            // - Franja verde con 3 círculos naranjas debajo de A6E / A5E
                            // - Jardín cuadrado verde dividido en 4 por caminería en cruz gris
                            // =========================================================================

                            // Gran manzana curva de la Panadería + Recinto exterior de Escuela de Mecánica (tal cual la imagen)
                            ctx.save();
                            // 1) Manzana superior de Panadería con su diagonal curva inferior derecha
                            ctx.beginPath();
                            ctx.moveTo(64, 118);
                            ctx.lineTo(222, 118);
                            ctx.lineTo(222, 240);
                            // Curva derecha que pasa a diagonal recta bajando hasta encima de Biblioteca Mecánica
                            ctx.bezierCurveTo(222, 292, 196, 314, 166, 336);
                            ctx.lineTo(68, 408);
                            ctx.lineTo(42, 408);
                            ctx.lineTo(42, 146);
                            ctx.quadraticCurveTo(42, 118, 64, 118);
                            ctx.closePath();
                            ctx.fillStyle = rootMapa.colorRecinto;
                            ctx.fill();
                            ctx.lineWidth = 2.0;
                            ctx.strokeStyle = rootMapa.colorTrazo;
                            ctx.stroke();

                            // 2) Recinto exterior de Escuela de Mecánica (con muesca semicircular superior y esquina inferior derecha curva)
                            ctx.beginPath();
                            ctx.moveTo(166, 336);
                            ctx.lineTo(166, 355);
                            // Pequeño semicírculo hacia la izquierda antes del borde superior horizontal de Mecánica
                            ctx.arc(166, 361.5, 6.5, -Math.PI / 2, Math.PI / 2, true);
                            ctx.lineTo(226, 368);
                            ctx.lineTo(226, 460);
                            ctx.lineTo(216, 460);
                            ctx.lineTo(224, 460);
                            ctx.quadraticCurveTo(224, 480, 218, 480);
                            ctx.lineTo(38, 480);
                            ctx.lineTo(38, 170);
                            ctx.moveTo(68, 408);
                            ctx.lineTo(166, 336);
                            ctx.fillStyle = rootMapa.colorRecinto;
                            ctx.fill();
                            ctx.lineWidth = 1.8;
                            ctx.strokeStyle = rootMapa.colorBorde;
                            ctx.stroke();

                            // Arco de puerta/portón a la derecha del terreno de Panadería (x=222, y=118..136)
                            ctx.beginPath();
                            ctx.moveTo(222, 118);
                            ctx.lineTo(244, 118);
                            ctx.arc(222, 118, 22, 0, Math.PI / 2, false);
                            ctx.closePath();
                            ctx.strokeStyle = rootMapa.colorBorde;
                            ctx.lineWidth = 1.5;
                            ctx.stroke();
                            ctx.restore();

                            // Borde superior del Estacionamiento de Profesores (con curva de entrada bajo Vigilancia)
                            ctx.save();
                            ctx.strokeStyle = rootMapa.colorTrazo;
                            ctx.lineWidth = 2.0;
                            ctx.beginPath();
                            ctx.moveTo(296, 142);
                            ctx.quadraticCurveTo(296, 118, 320, 118);
                            ctx.lineTo(448, 118);
                            ctx.lineTo(448, 190);
                            ctx.stroke();
                            ctx.restore();

                            // =========================================================================
                            // CAMINERÍAS PARALELAS DE CIVIL / PLAZA LOS MANGOS (SIN SOLAPAMIENTOS):
                            // - Camino vertical izquierdo frente a A8I: x=368..380 (y=224..480)
                            // - Camino vertical derecho paralelo (al lado de SEIN, Jardín Cruz, Esc. Civil y Los Mangos): x=438..450 (y=118..480)
                            // =========================================================================
                            ctx.fillStyle = rootMapa.colorSenda;
                            ctx.strokeStyle = rootMapa.colorSendaBorde;
                            ctx.lineWidth = 1.0;

                            // Pasillo horizontal superior frente a Dpto. Idiomas, A9I, A8I, A7E y SEIN
                            ctx.fillRect(240, 224, 210, 12);

                            // Pasillo vertical 1 (frente a A8I): baja recto entre (A5E / Lab. y Oficinas / Civil Hidráulica / Direc. Académica) y (Jardín Cruz / Esc. Civil / Plaza Los Mangos)
                            ctx.fillRect(368, 224, 12, 256);

                            // Pasillo vertical 2 (paralelo al otro lado de la plaza y de Esc. Civil): baja desde SEIN/AD4 hasta Plaza Los Mangos
                            ctx.fillRect(438, 118, 12, 362);

                            // Pasillos horizontales transversales que conectan ambos caminos verticales
                            ctx.fillRect(240, 342, 128, 8);  // Entre Laboratorios y Oficinas y Escuela de Civil Hidráulica
                            ctx.fillRect(272, 418, 96,  6);  // Pasillo delgado entre AFP/AFG (Civil Hidráulica) y el bloque de A4M/A3M/DIREC
                            ctx.fillRect(368, 290, 82,  8);  // Entre Jardín en Cruz y Escuela de Civil
                            ctx.fillRect(368, 364, 82,  10); // Entre Escuela de Civil y Plaza Los Mangos

                            // =========================================================================
                            // GEOMETRÍA EXACTA DE AD4, CAMINERÍA DIAGONAL, JARDINERÍA TRIANGULAR,
                            // CAMINO RECTO VERTICAL AD4 -> AD2 Y CONEXIÓN HORIZONTAL HACIA EL CHILENO
                            // =========================================================================

                            // 1) Camino recto vertical desde la entrada de AD4 hacia abajo hasta AD2 y El Chileno (x=492..502)
                            ctx.fillStyle = rootMapa.colorSenda;
                            ctx.fillRect(492, 118, 10, 180);

                            // Pasillo horizontal entre LIM (arriba) y SGE / Escuela de Industrial (abajo)
                            ctx.fillRect(492, 180, 48, 10);

                            // 2) Caminería en DIAGONAL desde el lado de SEIN subiendo hacia la entrada de AD4 / LIM
                            ctx.save();
                            ctx.beginPath();
                            ctx.moveTo(438, 210);
                            ctx.lineTo(492, 178);
                            ctx.lineTo(492, 190);
                            ctx.lineTo(450, 218);
                            ctx.closePath();
                            ctx.fillStyle = rootMapa.colorSenda;
                            ctx.fill();
                            ctx.restore();

                            // 3) Recinto / Patio de AD4 (Con pared inferior en diagonal paralela a la caminería)
                            ctx.save();
                            ctx.beginPath();
                            ctx.moveTo(452, 118);
                            ctx.lineTo(490, 118);
                            ctx.lineTo(490, 178);
                            ctx.lineTo(452, 204);
                            ctx.closePath();
                            ctx.fillStyle = rootMapa.colorRecinto;
                            ctx.fill();
                            ctx.strokeStyle = rootMapa.colorTrazo;
                            ctx.lineWidth = 1.6;
                            ctx.stroke();
                            ctx.restore();

                            // 4) Jardinería Triangular Verde (Triángulo rectángulo cerrado: por ahí NO pasa caminería)
                            ctx.save();
                            ctx.beginPath();
                            ctx.moveTo(490, 190); // Vértice superior derecho
                            ctx.lineTo(490, 222); // Cateto vertical derecho (frente a SGE)
                            ctx.lineTo(452, 222); // Cateto horizontal inferior
                            ctx.lineTo(452, 216); // Pequeño borde izquierdo
                            ctx.closePath();
                            ctx.fillStyle = rootMapa.colorVerde;
                            ctx.fill();
                            ctx.strokeStyle = rootMapa.colorVerdeBorde;
                            ctx.lineWidth = 1.5;
                            ctx.stroke();
                            ctx.restore();

                            // Pasillo horizontal debajo de la jardinería triangular (entre el triángulo y el recinto de AD2)
                            ctx.fillStyle = rootMapa.colorSenda;
                            ctx.fillRect(438, 222, 54, 10);

                            // 5) Recinto de AD2 (Polígono con esquina inferior izquierda biselada tal cual la imagen)
                            ctx.save();
                            ctx.beginPath();
                            ctx.moveTo(452, 232);
                            ctx.lineTo(490, 232);
                            ctx.lineTo(490, 288);
                            ctx.lineTo(460, 288);
                            ctx.lineTo(452, 268);
                            ctx.closePath();
                            ctx.fillStyle = rootMapa.colorRecinto;
                            ctx.fill();
                            ctx.strokeStyle = rootMapa.colorTrazo;
                            ctx.lineWidth = 1.6;
                            ctx.stroke();
                            ctx.restore();

                            // 6) Camino horizontal inferior que conecta ambos lados de AD2 con El Chileno (y=288..298)
                            ctx.fillStyle = rootMapa.colorSenda;
                            ctx.fillRect(438, 288, 102, 10);

                            // Franja verde debajo de A6E y A5E con los 3 árboles (x=240..366, sin pisar el camino x=368)
                            ctx.fillStyle = rootMapa.colorVerde;
                            ctx.strokeStyle = rootMapa.colorVerdeBorde;
                            ctx.lineWidth = 1.4;
                            ctx.fillRect(240, 264, 126, 18);
                            ctx.strokeRect(240, 264, 126, 18);

                            var arbolesNoroeste = [268, 306, 344];
                            for (var an = 0; an < arbolesNoroeste.length; an++) {
                                ctx.beginPath();
                                ctx.arc(arbolesNoroeste[an], 273, 5.5, 0, Math.PI * 2);
                                ctx.fillStyle = "#ea580c";
                                ctx.fill();
                                ctx.lineWidth = 1.2;
                                ctx.strokeStyle = "#fed7aa";
                                ctx.stroke();
                            }

                            // =========================================================================
                            // ESTACIONAMIENTO DE MECÁNICA, BLOQUE ANEXO A4M Y JARDINERA CURVA INFERIOR
                            // (Fiel al recorte de la esquina inferior izquierda de Civil Hidráulica)
                            // =========================================================================
                            ctx.save();
                            // Bahía del Estacionamiento de Mecánica (encaja en el escalón de Civil Hidráulica x=240..268, y=400..460)
                            ctx.fillStyle = rootMapa.colorRecinto;
                            ctx.fillRect(238, 400, 30, 60);
                            ctx.strokeStyle = rootMapa.colorBorde;
                            ctx.lineWidth = 1.6;
                            ctx.beginPath();
                            ctx.moveTo(240, 400);
                            ctx.lineTo(268, 400);
                            ctx.lineTo(268, 460);
                            ctx.lineTo(240, 460);
                            ctx.stroke();

                            // Texto vertical "Estacionamiento / de / MECANICA" dentro de la bahía
                            ctx.fillStyle = rootMapa.colorTextoEdificio;
                            ctx.font = "bold 6px sans-serif";
                            ctx.textAlign = "center";
                            ctx.save();
                            ctx.translate(246, 430);
                            ctx.rotate(-Math.PI / 2);
                            ctx.fillText("Estacionamiento", 0, 0);
                            ctx.restore();
                            ctx.save();
                            ctx.translate(254, 430);
                            ctx.rotate(-Math.PI / 2);
                            ctx.fillText("de", 0, 0);
                            ctx.restore();
                            ctx.save();
                            ctx.translate(262, 430);
                            ctx.rotate(-Math.PI / 2);
                            ctx.fillText("MECANICA", 0, 0);
                            ctx.restore();

                            // Patio superior sobre A4M/A3M/DIREC (x=272..366, y=424..434) y recuadro vertical izquierdo (x=272..283, y=434..460)
                            ctx.fillStyle = rootMapa.colorEdificio;
                            ctx.strokeStyle = rootMapa.colorBorde;
                            ctx.lineWidth = 1.4;
                            ctx.fillRect(272, 424, 94, 10);
                            ctx.strokeRect(272, 424, 94, 10);
                            ctx.fillRect(272, 434, 11, 26);
                            ctx.strokeRect(272, 434, 11, 26);

                            // Acera curva exterior que bordea la jardinera inferior (x=238..368, y=460..480)
                            ctx.strokeStyle = rootMapa.colorBorde;
                            ctx.lineWidth = 1.5;
                            ctx.beginPath();
                            ctx.moveTo(240, 460);
                            ctx.quadraticCurveTo(238, 480, 250, 480);
                            ctx.lineTo(368, 480);
                            ctx.stroke();

                            // Jardinera verde inferior con punta izquierda redondeada y 2 árboles naranjas bajo A4M y A3M
                            ctx.beginPath();
                            ctx.moveTo(252, 464);
                            ctx.lineTo(366, 464);
                            ctx.lineTo(366, 477);
                            ctx.lineTo(252, 477);
                            ctx.quadraticCurveTo(244, 477, 244, 470.5);
                            ctx.quadraticCurveTo(244, 464, 252, 464);
                            ctx.closePath();
                            ctx.fillStyle = rootMapa.colorVerde;
                            ctx.fill();
                            ctx.strokeStyle = rootMapa.colorVerdeBorde;
                            ctx.lineWidth = 1.3;
                            ctx.stroke();

                            var arbolesSurCivil = [302, 330];
                            for (var asIdx = 0; asIdx < arbolesSurCivil.length; asIdx++) {
                                ctx.beginPath();
                                ctx.arc(arbolesSurCivil[asIdx], 470.5, 4.5, 0, Math.PI * 2);
                                ctx.fillStyle = "#ea580c";
                                ctx.fill();
                                ctx.lineWidth = 1.1;
                                ctx.strokeStyle = "#fed7aa";
                                ctx.stroke();
                            }
                            ctx.restore();

                            // Jardín cuadrado de 4 cuadrantes verdes con caminería gris en cruz (x=382..436, entre ambos caminos verticales)
                            var jx = 382, jy = 236, jw = 54, jh = 54;
                            ctx.fillStyle = rootMapa.colorBorde;
                            ctx.fillRect(jx, jy, jw, jh);
                            ctx.strokeStyle = rootMapa.colorBorde;
                            ctx.lineWidth = 1.2;
                            ctx.strokeRect(jx, jy, jw, jh);

                            var cuadrantes = [
                                [jx + 2,  jy + 2,  20, 20],
                                [jx + 32, jy + 2,  20, 20],
                                [jx + 2,  jy + 32, 20, 20],
                                [jx + 32, jy + 32, 20, 20]
                            ];
                            for (var qd = 0; qd < cuadrantes.length; qd++) {
                                var cq = cuadrantes[qd];
                                ctx.fillStyle = rootMapa.colorVerde;
                                ctx.fillRect(cq[0], cq[1], cq[2], cq[3]);
                                ctx.strokeStyle = rootMapa.colorVerdeBorde;
                                ctx.lineWidth = 1;
                                ctx.strokeRect(cq[0], cq[1], cq[2], cq[3]);
                                ctx.fillStyle = rootMapa.colorBorde;
                                ctx.fillRect(cq[0] + 6, cq[1] + 5, 6, 10);
                                ctx.strokeRect(cq[0] + 6, cq[1] + 5, 6, 10);
                            }

                            // =========================================================================
                            // JARDINERA VERDE CON ÁRBOL SOBRE DPTO DE DIBUJO + 3 CUADROS SOBRE DECANATO
                            // + SECTOR AD3 / ESTRUCTURA AZUL EN "C" / AD1 / FÍSICA / COMPUTACIÓN / CAFETÍN / BOULEVARD
                            // =========================================================================
                            ctx.save();
                            // Jardinera verde con pequeño escalón superior izquierdo y árbol marrón a la derecha (x=452..530, y=329..340)
                            ctx.beginPath();
                            ctx.moveTo(452, 331);
                            ctx.lineTo(470, 331);
                            ctx.lineTo(470, 329);
                            ctx.lineTo(530, 329);
                            ctx.lineTo(530, 340);
                            ctx.lineTo(452, 340);
                            ctx.closePath();
                            ctx.fillStyle = rootMapa.colorVerde;
                            ctx.fill();
                            ctx.strokeStyle = rootMapa.colorVerdeBorde;
                            ctx.lineWidth = 1.3;
                            ctx.stroke();

                            // Árbol (círculo marrón con borde oscuro) dentro de la jardinera sobre Dibujo
                            ctx.beginPath();
                            ctx.arc(514, 334.5, 4.2, 0, Math.PI * 2);
                            ctx.fillStyle = "#78350f";
                            ctx.fill();
                            ctx.lineWidth = 1.2;
                            ctx.strokeStyle = "#fde68a";
                            ctx.stroke();

                            // Los 3 cuadros entre el camino inferior de Estudios Básicos (y=400..405) y el camino sobre Decanato (y=417..421)
                            ctx.fillStyle = rootMapa.colorEdificio;
                            ctx.strokeStyle = rootMapa.colorBorde;
                            ctx.lineWidth = 1.4;
                            var tresCuadros = [
                                [452, 405, 22, 12],
                                [478, 405, 22, 12],
                                [504, 405, 22, 12]
                            ];
                            for (var tc = 0; tc < tresCuadros.length; tc++) {
                                ctx.fillRect(tresCuadros[tc][0], tresCuadros[tc][1], tresCuadros[tc][2], tresCuadros[tc][3]);
                                ctx.strokeRect(tresCuadros[tc][0], tresCuadros[tc][1], tresCuadros[tc][2], tresCuadros[tc][3]);
                            }

                            // 1) Jardinera verde con árbol marrón arriba de AD3 (x=576..604, y=118..143)
                            ctx.beginPath();
                            ctx.moveTo(576, 118);
                            ctx.lineTo(604, 118);
                            ctx.lineTo(604, 138);
                            ctx.lineTo(576, 143);
                            ctx.closePath();
                            ctx.fillStyle = rootMapa.colorVerde;
                            ctx.fill();
                            ctx.strokeStyle = rootMapa.colorVerdeBorde;
                            ctx.lineWidth = 1.3;
                            ctx.stroke();

                            ctx.beginPath();
                            ctx.arc(590, 129, 4.8, 0, Math.PI * 2);
                            ctx.fillStyle = "#78350f";
                            ctx.fill();
                            ctx.lineWidth = 1.2;
                            ctx.strokeStyle = "#fde68a";
                            ctx.stroke();

                            // 2) Estructura azul en forma de "C" (abierta a la derecha) entre AD3 y AD1 (x=578..604, y=168..216)
                            ctx.beginPath();
                            ctx.moveTo(578, 168);
                            ctx.lineTo(604, 172);
                            ctx.lineTo(604, 185);
                            ctx.lineTo(590, 185);
                            ctx.lineTo(590, 202);
                            ctx.lineTo(604, 202);
                            ctx.lineTo(604, 216);
                            ctx.lineTo(578, 216);
                            ctx.closePath();
                            ctx.fillStyle = "#1d4ed8";
                            ctx.fill();
                            ctx.strokeStyle = rootMapa.colorBordeMiAula;
                            ctx.lineWidth = 1.4;
                            ctx.stroke();

                            // 3) Recintos superior e inferior de AD1 (x=578..604, y=224..288)
                            ctx.fillStyle = rootMapa.colorRecinto;
                            ctx.strokeStyle = rootMapa.colorBorde;
                            ctx.lineWidth = 1.4;
                            ctx.fillRect(578, 224, 26, 18);
                            ctx.strokeRect(578, 224, 26, 18);
                            ctx.fillRect(578, 268, 26, 20);
                            ctx.strokeRect(578, 268, 26, 20);

                            // 4) Jardines gemelos debajo de Edificio Biblioteca Central + Coordinación de Cultura + BAÑO
                            // 4a) Jardín izquierdo (al este de AD1) con recuadro de BAÑO y 1 árbol marrón (x=614..658, y=206..284)
                            ctx.beginPath();
                            ctx.moveTo(614, 206);
                            ctx.lineTo(632, 206);
                            ctx.lineTo(632, 230);
                            ctx.lineTo(658, 230);
                            ctx.lineTo(658, 284);
                            ctx.lineTo(614, 284);
                            ctx.closePath();
                            ctx.fillStyle = rootMapa.colorVerde;
                            ctx.fill();
                            ctx.strokeStyle = rootMapa.colorVerdeBorde;
                            ctx.lineWidth = 1.3;
                            ctx.stroke();

                            ctx.fillStyle = rootMapa.colorEdificio;
                            ctx.strokeStyle = rootMapa.colorBorde;
                            ctx.fillRect(618, 252, 24, 22);
                            ctx.strokeRect(618, 252, 24, 22);
                            ctx.fillStyle = rootMapa.colorTextoEdificio;
                            ctx.font = "bold 6px sans-serif";
                            ctx.textAlign = "center";
                            ctx.fillText("BAÑO", 630, 265);

                            // Árbol marrón a la derecha de BAÑO
                            ctx.beginPath();
                            ctx.arc(650, 260, 4.5, 0, Math.PI * 2);
                            ctx.fillStyle = "#78350f";
                            ctx.fill();
                            ctx.lineWidth = 1.2;
                            ctx.strokeStyle = "#fde68a";
                            ctx.stroke();

                            // 4b) Barra vertical azul al este de Edificio Biblioteca Central (x=700..714, y=122..206)
                            ctx.fillStyle = "#1d4ed8";
                            ctx.strokeStyle = rootMapa.colorBordeMiAula;
                            ctx.lineWidth = 1.3;
                            ctx.fillRect(700, 122, 14, 84);
                            ctx.strokeRect(700, 122, 14, 84);

                            // 4c) Jardín derecho debajo de Coordinación de Cultura y la barra azul (x=668..714, y=206..286) con 2 árboles marrones
                            ctx.beginPath();
                            ctx.moveTo(698, 206);
                            ctx.lineTo(714, 206);
                            ctx.lineTo(714, 286);
                            ctx.lineTo(668, 286);
                            ctx.lineTo(668, 230);
                            ctx.lineTo(698, 230);
                            ctx.closePath();
                            ctx.fillStyle = rootMapa.colorVerde;
                            ctx.fill();
                            ctx.strokeStyle = rootMapa.colorVerdeBorde;
                            ctx.lineWidth = 1.3;
                            ctx.stroke();

                            var arbolesCulturaDer = [[682, 268], [704, 250]];
                            for (var acd = 0; acd < arbolesCulturaDer.length; acd++) {
                                ctx.beginPath();
                                ctx.arc(arbolesCulturaDer[acd][0], arbolesCulturaDer[acd][1], 4.5, 0, Math.PI * 2);
                                ctx.fillStyle = "#78350f";
                                ctx.fill();
                                ctx.lineWidth = 1.2;
                                ctx.strokeStyle = "#fde68a";
                                ctx.stroke();
                            }

                            // 5) Jardinera verde alargada entre (AF1/AF2/Lab. de Física) y (C.E.I./Cubic. Física 2/Computación)
                            ctx.fillStyle = rootMapa.colorVerde;
                            ctx.strokeStyle = rootMapa.colorVerdeBorde;
                            ctx.lineWidth = 1.3;
                            ctx.fillRect(538, 330, 88, 10);
                            ctx.strokeRect(538, 330, 88, 10);

                            // Jardín verde al este de Computación dividido en 2 triángulos por la caminería diagonal hacia el Boulevard
                            ctx.fillStyle = rootMapa.colorVerde;
                            ctx.strokeStyle = rootMapa.colorVerdeBorde;
                            ctx.lineWidth = 1.2;
                            // Triángulo verde superior izquierdo
                            ctx.beginPath();
                            ctx.moveTo(630, 330);
                            ctx.lineTo(656, 330);
                            ctx.lineTo(630, 360);
                            ctx.closePath();
                            ctx.fill();
                            ctx.stroke();
                            // Triángulo verde inferior derecho (sobre BAÑOS)
                            ctx.beginPath();
                            ctx.moveTo(634, 366);
                            ctx.lineTo(658, 338);
                            ctx.lineTo(658, 366);
                            ctx.closePath();
                            ctx.fill();
                            ctx.stroke();

                            // 6) Explanada/Caminería gris que rodea la jardinera del Cafetín, el Cafetín, el Boulevard, BAÑOS y las 2 jardineras inclinadas
                            ctx.beginPath();
                            ctx.moveTo(530, 368);
                            ctx.lineTo(658, 368);
                            ctx.lineTo(658, 444);
                            ctx.lineTo(646, 456);
                            ctx.lineTo(632, 444);
                            ctx.lineTo(618, 456);
                            ctx.lineTo(604, 444);
                            ctx.lineTo(590, 452);
                            ctx.lineTo(574, 440);
                            ctx.lineTo(574, 421);
                            ctx.lineTo(530, 421);
                            ctx.closePath();
                            ctx.fillStyle = rootMapa.colorEdificio;
                            ctx.fill();
                            ctx.strokeStyle = rootMapa.colorTrazo;
                            ctx.lineWidth = 1.2;
                            ctx.stroke();

                            // Módulo de "BAÑOS" al lado derecho del Boulevard (x=638..658, y=372..396) y recuadro blanco inferior (x=646..658, y=424..440)
                            ctx.fillStyle = rootMapa.colorEdificio;
                            ctx.strokeStyle = rootMapa.colorBorde;
                            ctx.lineWidth = 1.3;
                            ctx.fillRect(638, 372, 20, 24);
                            ctx.strokeRect(638, 372, 20, 24);
                            ctx.fillStyle = rootMapa.colorTextoEdificio;
                            ctx.font = "bold 5.5px sans-serif";
                            ctx.textAlign = "center";
                            ctx.fillText("BAÑOS", 648, 386);

                            ctx.fillStyle = rootMapa.colorEdificio;
                            ctx.strokeStyle = rootMapa.colorBorde;
                            ctx.fillRect(646, 424, 12, 16);
                            ctx.strokeRect(646, 424, 12, 16);

                            // Jardinera verde entre C.E.I./Computación y Cafetín (x=540..582, y=371..381)
                            ctx.fillStyle = rootMapa.colorVerde;
                            ctx.strokeStyle = rootMapa.colorVerdeBorde;
                            ctx.lineWidth = 1.3;
                            ctx.fillRect(540, 371, 42, 10);
                            ctx.strokeRect(540, 371, 42, 10);

                            // Las 2 jardineras verdes inclinadas debajo de la base del Boulevard
                            var rombosBoulevard = [[616, 444], [644, 444]];
                            for (var rb = 0; rb < rombosBoulevard.length; rb++) {
                                ctx.save();
                                ctx.translate(rombosBoulevard[rb][0], rombosBoulevard[rb][1]);
                                ctx.rotate(0.62);
                                ctx.fillStyle = rootMapa.colorVerde;
                                ctx.strokeStyle = rootMapa.colorVerdeBorde;
                                ctx.lineWidth = 1.3;
                                ctx.fillRect(-6, -4.5, 12, 9);
                                ctx.strokeRect(-6, -4.5, 12, 9);
                                ctx.restore();
                            }

                            // 7) Estructura debajo de Mantenimiento (2 cuadritos amarillos + bloque blanco + polígono azul en diente de sierra)
                            ctx.fillStyle = "#eab308";
                            ctx.strokeStyle = "#fef08a";
                            ctx.lineWidth = 1.2;
                            ctx.fillRect(670, 418, 12, 9);
                            ctx.strokeRect(670, 418, 12, 9);
                            ctx.fillRect(670, 427, 12, 9);
                            ctx.strokeRect(670, 427, 12, 9);

                            ctx.fillStyle = rootMapa.colorEdificio;
                            ctx.strokeStyle = rootMapa.colorBorde;
                            ctx.fillRect(682, 418, 80, 18);
                            ctx.strokeRect(682, 418, 80, 18);

                            // Polígono azul con borde inferior en zig-zag (3 puntas sobre el Estacionamiento)
                            ctx.beginPath();
                            ctx.moveTo(670, 436);
                            ctx.lineTo(762, 436);
                            ctx.lineTo(762, 448);
                            ctx.lineTo(748, 456);
                            ctx.lineTo(732, 446);
                            ctx.lineTo(716, 456);
                            ctx.lineTo(700, 446);
                            ctx.lineTo(686, 456);
                            ctx.lineTo(670, 446);
                            ctx.closePath();
                            ctx.fillStyle = "#1d4ed8";
                            ctx.fill();
                            ctx.strokeStyle = rootMapa.colorBordeMiAula;
                            ctx.lineWidth = 1.3;
                            ctx.stroke();

                            // Pequeño triángulo verde a la derecha de la última punta azul
                            ctx.beginPath();
                            ctx.moveTo(760, 452);
                            ctx.lineTo(760, 464);
                            ctx.lineTo(750, 458);
                            ctx.closePath();
                            ctx.fillStyle = rootMapa.colorVerde;
                            ctx.fill();
                            ctx.strokeStyle = rootMapa.colorVerdeBorde;
                            ctx.lineWidth = 1.1;
                            ctx.stroke();

                            // Jardinera verde inferior en zig-zag (6 picos) que bordea el sur del Estacionamiento Central
                            ctx.beginPath();
                            ctx.moveTo(584, 488);
                            ctx.quadraticCurveTo(582, 478, 590, 476);
                            ctx.lineTo(602, 484);
                            ctx.lineTo(616, 476);
                            ctx.lineTo(630, 484);
                            ctx.lineTo(646, 476);
                            ctx.lineTo(662, 484);
                            ctx.lineTo(678, 476);
                            ctx.lineTo(694, 484);
                            ctx.lineTo(710, 476);
                            ctx.lineTo(726, 484);
                            ctx.lineTo(742, 476);
                            ctx.lineTo(758, 476);
                            ctx.lineTo(758, 488);
                            ctx.closePath();
                            ctx.fillStyle = rootMapa.colorVerde;
                            ctx.fill();
                            ctx.strokeStyle = rootMapa.colorVerdeBorde;
                            ctx.lineWidth = 1.3;
                            ctx.stroke();
                            ctx.restore();

                            // Avenida Central Horizontal (División Ingeniería / FACYT-Telecom)
                            ctx.fillStyle = rootMapa.colorAvenida;
                            ctx.strokeStyle = rootMapa.colorTrazo;
                            ctx.lineWidth = 2.0;
                            ctx.fillRect(26, 492, 918, 22);
                            ctx.strokeRect(26, 492, 918, 22);

                            // Avenida Oriental (Vertical completa junto a Canchas Deportivas y Entrada por Medicina)
                            ctx.fillRect(958, 65, 28, 668);
                            ctx.strokeRect(958, 65, 28, 668);

                            // Dos recuadros blancos juntos sobre Cancha Básquet (al este de la avenida oriental)
                            ctx.save();
                            ctx.fillStyle = rootMapa.colorEdificio;
                            ctx.strokeStyle = rootMapa.colorBorde;
                            ctx.lineWidth = 1.6;
                            ctx.fillRect(988, 264, 27, 44);
                            ctx.strokeRect(988, 264, 27, 44);
                            ctx.fillRect(1015, 264, 27, 44);
                            ctx.strokeRect(1015, 264, 27, 44);
                            ctx.restore();

                            // Resto de caminerías peatonales del campus (Alineadas entre bloques para que ningún cuadro las pise)
                            ctx.fillStyle = rootMapa.colorSenda;
                            ctx.strokeStyle = rootMapa.colorSendaBorde;
                            ctx.lineWidth = 1.0;
                            var camineriasResto = [
                                [530, 118, 8,   303], // Camino vertical entre (LIM/Industrial/Química/Dibujo/Básicos) y (SIO/Física/Computación/Cafetín)
                                [438, 323, 92,  6],   // Camino horizontal entre Cubículos y Lab de Química y la jardinera de abajo
                                [438, 370, 92,  6],   // Camino horizontal entre Dpto. de Dibujo y Dirección de Estudios Básicos
                                [438, 400, 92,  5],   // Camino horizontal debajo de Dirección de Estudios Básicos (sobre los 3 cuadros)
                                [474, 405, 4,   12],  // Pasillo vertical entre cuadro 1 y cuadro 2
                                [500, 405, 4,   12],  // Pasillo vertical entre cuadro 2 y cuadro 3
                                [438, 417, 136, 4],   // Camino horizontal entre los 3 cuadros/Cafetín y el edificio del Decanato
                                [604, 118, 10,  170], // Camino vertical entre (AD3 / C Azul / AD1) y Edificio Biblioteca Central
                                [572, 216, 32,  8],   // Pasillo horizontal entre la estructura azul en C y el recinto de AD1
                                [530, 288, 240, 10],  // Camino horizontal central bajo El Chileno, Publicaciones, AD1, Jardines de Cultura y Esc. Eléctrica
                                [530, 324, 130, 6],   // Camino horizontal debajo de AF1 / AF2 / Lab. de Física
                                [530, 340, 96,  4],   // Camino horizontal entre la jardinera de Física y C.E.I. / Computación
                                [660, 376, 104, 8],   // Camino horizontal entre Lab. Procesos HP2 y Mantenimiento
                                [660, 410, 104, 8],   // Camino horizontal debajo de Mantenimiento
                                [26,  488, 902, 4],   // Acera peatonal norte de la avenida principal
                                [658, 230, 10,  226], // Camino vertical central desde Coordinación de Cultura hasta el Estacionamiento Central
                                [764, 194, 4,   272], // Camino vertical al este de Esc. Eléctrica, Lab. Máq. Eléctricas y Mantenimiento
                                [784, 324, 160, 8],   // Camino horizontal este entre (AD5 / Bloque escalonado / AD6) y (AD8 / Cuadros / AD7)
                                [842, 248, 10,  28],  // Pasillo superior que baja de Matemáticas hacia AD5
                                [836, 294, 10,  30],  // Camino vertical que baja de AD5 al camino horizontal
                                [836, 332, 8,   28],  // Camino vertical que baja del camino horizontal hacia AD8
                                [836, 384, 8,   82],  // Camino vertical que sale por debajo de AD8 hasta el final del bloque inferior izquierdo
                                [898, 228, 8,   34],  // Camino vertical superior entre I.M.Y.C.A. y REDUC hacia AD6
                                [898, 294, 8,   30],  // Camino vertical entre el pie de AD6 y el camino horizontal
                                [898, 332, 8,   28],  // Camino vertical del camino horizontal hacia AD7
                                [900, 384, 8,   66],  // Camino vertical que sale de AD7 hacia AD9
                                [868, 332, 10,  20],  // Pasillo vertical entre los 2 cuadros sobre Humanidades
                                [768, 396, 68,  6],   // Pasillo horizontal entre el patio de AD8 y el bloque inferior izquierdo
                                [906, 392, 38,  8]    // Pasillo horizontal debajo del recinto de AD7
                            ];
                            for (var crIdx = 0; crIdx < camineriasResto.length; crIdx++) {
                                var cm = camineriasResto[crIdx];
                                ctx.fillRect(cm[0], cm[1], cm[2], cm[3]);
                                ctx.strokeRect(cm[0], cm[1], cm[2], cm[3]);
                            }

                            // =========================================================================
                            // SECTOR ESTE: CONECTORES, PUENTE SLM, PATIOS DE AD5/AD6/AD8/AD7, BLOQUE ESCALONADO Y JARDINERA
                            // =========================================================================
                            ctx.save();
                            // Borde exterior derecho del sector este (paralelo a la avenida oriental)
                            ctx.strokeStyle = rootMapa.colorTrazo;
                            ctx.lineWidth = 2.0;
                            ctx.beginPath();
                            ctx.moveTo(944, 214);
                            ctx.lineTo(944, 488);
                            ctx.stroke();

                            // Conector superior entre LED/SIE 5 y Operaciones Unitarias
                            ctx.fillStyle = rootMapa.colorEdificio;
                            ctx.strokeStyle = rootMapa.colorBorde;
                            ctx.lineWidth = 1.4;
                            ctx.fillRect(746, 116, 20, 14);
                            ctx.strokeRect(746, 116, 20, 14);

                            // Unión horizontal centrada entre SIE 1 / Escuela de Eléctrica (x=774) y el rectángulo SLM / SIE 3 (x=786)
                            ctx.fillRect(774, 171, 12, 10);
                            ctx.beginPath();
                            ctx.moveTo(774, 171); ctx.lineTo(786, 171);
                            ctx.moveTo(774, 181); ctx.lineTo(786, 181);
                            ctx.stroke();

                            // Recuadro rojo con X (a la derecha de Escuela de Eléctrica)
                            ctx.fillStyle = "#dc2626";
                            ctx.strokeStyle = "#fecaca";
                            ctx.lineWidth = 1.2;
                            ctx.fillRect(774, 202, 10, 15);
                            ctx.strokeRect(774, 202, 10, 15);
                            ctx.beginPath();
                            ctx.moveTo(775, 204); ctx.lineTo(783, 215);
                            ctx.moveTo(783, 204); ctx.lineTo(775, 215);
                            ctx.stroke();

                            // 1) Patio escalonado de AD5 (x=784..842 arriba de AD5 y x=784..836 debajo de AD5)
                            ctx.fillStyle = rootMapa.colorRecinto;
                            ctx.strokeStyle = rootMapa.colorTrazo;
                            ctx.lineWidth = 1.4;
                            ctx.beginPath();
                            ctx.moveTo(784, 258);
                            ctx.lineTo(842, 258);
                            ctx.lineTo(842, 276);
                            ctx.lineTo(836, 294);
                            ctx.lineTo(836, 324);
                            ctx.lineTo(784, 324);
                            ctx.closePath();
                            ctx.fill();
                            ctx.stroke();

                            // 2) Bloque escalonado entre el pasillo de AD5 e I.M.Y.C.A. (con peldaño superior bajo Matemáticas)
                            ctx.fillStyle = rootMapa.colorEdificio;
                            ctx.strokeStyle = rootMapa.colorBorde;
                            ctx.lineWidth = 1.4;
                            // Peldaño bajo el lado derecho de Matemáticas (x=852..872, y=248..256)
                            ctx.fillRect(852, 248, 20, 8);
                            ctx.strokeRect(852, 248, 20, 8);
                            // Cuerpo escalonado inferior (base x=846..898, y=302..324 + cuello vertical x=864..876, y=272..302)
                            ctx.beginPath();
                            ctx.moveTo(864, 272);
                            ctx.lineTo(876, 272);
                            ctx.lineTo(876, 302);
                            ctx.lineTo(898, 302);
                            ctx.lineTo(898, 324);
                            ctx.lineTo(846, 324);
                            ctx.lineTo(846, 302);
                            ctx.lineTo(864, 302);
                            ctx.closePath();
                            ctx.fill();
                            ctx.stroke();

                            // 3) Patios / recintos rectangulares: AD8, bloque grande inferior izquierdo, los 2 cuadros sobre Humanidades, y recintos de AD6 y AD7
                            ctx.fillStyle = rootMapa.colorRecinto;
                            ctx.strokeStyle = rootMapa.colorTrazo;
                            ctx.lineWidth = 1.4;
                            var patiosEste = [
                                [784, 332, 52, 64],  // Patio de AD8
                                [768, 402, 68, 64],  // Cuadro grande inferior izquierdo (sobresale más a la izq. que el patio de AD8)
                                [844, 332, 24, 20],  // Cuadro izquierdo sobre Humanidades
                                [878, 332, 22, 20],  // Cuadro derecho sobre Humanidades
                                [906, 294, 38, 30],  // Recinto bajo AD6
                                [906, 332, 38, 60]   // Recinto de AD7 (arriba y abajo de AD7)
                            ];
                            for (var pe = 0; pe < patiosEste.length; pe++) {
                                ctx.fillRect(patiosEste[pe][0], patiosEste[pe][1], patiosEste[pe][2], patiosEste[pe][3]);
                                ctx.strokeRect(patiosEste[pe][0], patiosEste[pe][1], patiosEste[pe][2], patiosEste[pe][3]);
                            }

                            // Árbol marrón en la esquina inferior izquierda del patio de AD5
                            var arbolesAD5 = [[796, 314]];
                            for (var a5 = 0; a5 < arbolesAD5.length; a5++) {
                                ctx.beginPath();
                                ctx.arc(arbolesAD5[a5][0], arbolesAD5[a5][1], 4.5, 0, Math.PI * 2);
                                ctx.fillStyle = "#78350f";
                                ctx.fill();
                                ctx.lineWidth = 1.2;
                                ctx.strokeStyle = "#fde68a";
                                ctx.stroke();
                            }

                            // Jardinera verde rectangular sobre Escuela de Química (entre Humanidades y Escuela de Química)
                            ctx.fillStyle = rootMapa.colorVerde;
                            ctx.strokeStyle = rootMapa.colorVerdeBorde;
                            ctx.lineWidth = 1.3;
                            ctx.fillRect(876, 386, 34, 16);
                            ctx.strokeRect(876, 386, 34, 16);
                            ctx.restore();

                            // =========================================================================
                            // SECTOR SUR COMPLETO FIEL A LA IMAGEN:
                            // - Entrada a Ingeniería + Vigilancia
                            // - Contorno diagonal y recinto de FACYT, FCU/AE, A10/A11 e IMÁGENES
                            // - Caminería escalonada gris junto a FCU/AE + recuadro blanco + 3 árboles marrones
                            // - Intersección de ARCO DE BÁRBULA con sus 2 triángulos verdes
                            // - Doble vía sur con las 2 bahías de Parada de buses y VIA FACES
                            // - Pasillo vertical ENTRADA POR FACYT
                            // - Recinto sureste de Escuela de Telecom, parque verde (2 círculos grises + 1 marrón),
                            //   AD1M, Medicina (Ciencias de la Salud), AD2M, VIGILANCIA y ENTRADA POR MEDICINA
                            // =========================================================================
                            ctx.save();

                            // 1) Barra vertical azul y línea horizontal de Entrada a Ingeniería / Vigilancia
                            ctx.fillStyle = "#1d4ed8";
                            ctx.fillRect(42, 480, 5, 36);
                            ctx.strokeStyle = rootMapa.colorBorde;
                            ctx.lineWidth = 1.5;
                            ctx.beginPath();
                            ctx.moveTo(47, 496); ctx.lineTo(176, 496);
                            ctx.moveTo(47, 501); ctx.lineTo(176, 501);
                            ctx.moveTo(200, 500); ctx.lineTo(525, 500);
                            ctx.moveTo(558, 502); ctx.lineTo(892, 502);
                            ctx.stroke();

                            // 2) Gran recinto de Suroeste / FACYT (Borde diagonal frente a Plaza Las Iguanas y esquina inf-der curva)
                            ctx.beginPath();
                            ctx.moveTo(38, 586);
                            ctx.lineTo(286, 516);
                            ctx.lineTo(525, 516);
                            ctx.lineTo(525, 686);
                            ctx.quadraticCurveTo(525, 700, 510, 700);
                            ctx.lineTo(482, 700);
                            ctx.lineTo(476, 695);
                            ctx.lineTo(404, 695);
                            ctx.lineTo(398, 700);
                            ctx.lineTo(228, 700);
                            ctx.moveTo(160, 695);
                            ctx.lineTo(38, 695);
                            ctx.lineTo(38, 586);
                            ctx.fillStyle = rootMapa.colorRecinto;
                            ctx.fill();
                            ctx.lineWidth = 1.8;
                            ctx.strokeStyle = rootMapa.colorBorde;
                            ctx.stroke();

                            // 3) Caminería gris escalonada a la derecha de FCU..AE1 y alrededor de AE7..AE4
                            ctx.beginPath();
                            ctx.moveTo(64, 584);
                            ctx.lineTo(86, 576);
                            ctx.lineTo(86, 586);
                            ctx.lineTo(76, 590);
                            ctx.lineTo(76, 636);
                            ctx.lineTo(92, 636);
                            ctx.lineTo(92, 646);
                            ctx.lineTo(84, 646);
                            ctx.lineTo(84, 680);
                            ctx.lineTo(132, 680);
                            ctx.lineTo(132, 686);
                            ctx.lineTo(74, 686);
                            ctx.lineTo(74, 646);
                            ctx.lineTo(64, 646);
                            ctx.closePath();
                            ctx.fillStyle = rootMapa.colorTrazo;
                            ctx.fill();
                            ctx.strokeStyle = rootMapa.colorTextoEdificio;
                            ctx.lineWidth = 1.2;
                            ctx.stroke();

                            // Recuadro blanco horizontal y los 3 árboles marrones arriba de AE8 / AE9
                            ctx.fillStyle = rootMapa.colorEdificio;
                            ctx.strokeStyle = rootMapa.colorBorde;
                            ctx.lineWidth = 1.4;
                            ctx.fillRect(88, 580, 34, 12);
                            ctx.strokeRect(88, 580, 34, 12);

                            var arbolesAE = [[90, 603], [104, 608], [120, 601]];
                            for (var aae = 0; aae < arbolesAE.length; aae++) {
                                ctx.beginPath();
                                ctx.arc(arbolesAE[aae][0], arbolesAE[aae][1], 4.2, 0, Math.PI * 2);
                                ctx.fillStyle = "#78350f";
                                ctx.fill();
                                ctx.lineWidth = 1.1;
                                ctx.strokeStyle = "#fde68a";
                                ctx.stroke();
                            }

                            // 4) Intersección de ARCO DE BÁRBULA + sus 2 triángulos verdes + Doble vía sur + Bahías de Parada de buses
                            ctx.strokeStyle = rootMapa.colorBorde;
                            ctx.lineWidth = 1.6;
                            ctx.beginPath();
                            // Columna vertical izquierda de la intersección del Arco (x=160..172)
                            ctx.moveTo(160, 668); ctx.lineTo(172, 668);
                            ctx.lineTo(172, 676); ctx.lineTo(204, 695);
                            ctx.moveTo(160, 668); ctx.lineTo(160, 695);
                            ctx.moveTo(160, 711); ctx.lineTo(160, 736);
                            ctx.moveTo(172, 736); ctx.lineTo(172, 728);
                            ctx.lineTo(204, 711);

                            // Doble línea horizontal sur (desde la izquierda hasta VIA FACES, con las muescas de Parada de buses)
                            ctx.moveTo(26, 702);  ctx.lineTo(204, 702);
                            ctx.moveTo(26, 706);  ctx.lineTo(204, 706);
                            ctx.moveTo(228, 702); ctx.lineTo(884, 702);
                            ctx.moveTo(228, 706); ctx.lineTo(884, 706);

                            // Bahía inferior de Parada de buses (y=711..716, x=398..482)
                            ctx.moveTo(228, 711);
                            ctx.lineTo(398, 711);
                            ctx.lineTo(404, 716);
                            ctx.lineTo(476, 716);
                            ctx.lineTo(482, 711);
                            ctx.lineTo(884, 711);
                            ctx.quadraticCurveTo(892, 711, 892, 724);
                            ctx.stroke();

                            // Los 2 triángulos verdes a la izquierda del Arco de Bárbula (uno arriba y otro abajo de la doble vía)
                            ctx.fillStyle = rootMapa.colorVerde;
                            ctx.strokeStyle = rootMapa.colorVerdeBorde;
                            ctx.lineWidth = 1.3;
                            // Triángulo verde superior
                            ctx.beginPath();
                            ctx.moveTo(173, 680);
                            ctx.lineTo(195, 695);
                            ctx.lineTo(173, 695);
                            ctx.closePath();
                            ctx.fill();
                            ctx.stroke();
                            // Triángulo verde inferior
                            ctx.beginPath();
                            ctx.moveTo(173, 711);
                            ctx.lineTo(195, 711);
                            ctx.lineTo(173, 726);
                            ctx.closePath();
                            ctx.fill();
                            ctx.stroke();

                            // Monumento rojo oscuro ARCO DE BÁRBULA
                            ctx.fillStyle = "#7f1d1d";
                            ctx.strokeStyle = "#f87171";
                            ctx.lineWidth = 1.6;
                            ctx.fillRect(204, 678, 24, 42);
                            ctx.strokeRect(204, 678, 24, 42);
                            ctx.fillStyle = "#f87171";
                            ctx.font = "bold 8.5px serif";
                            ctx.textAlign = "center";
                            ctx.fillText("ARCO DE", 216, 729);
                            ctx.fillText("BARBULA", 216, 738);

                            // 5) Gran recinto Sureste: Parque verde junto a Escuela de Telecom, AD1M, Medicina, AD2M y Vigilancia
                            ctx.beginPath();
                            ctx.moveTo(558, 518);
                            ctx.lineTo(892, 518);
                            ctx.lineTo(892, 706);
                            ctx.lineTo(570, 706);
                            ctx.quadraticCurveTo(558, 706, 558, 694);
                            ctx.closePath();
                            ctx.fillStyle = rootMapa.colorRecinto;
                            ctx.fill();
                            ctx.lineWidth = 1.8;
                            ctx.strokeStyle = rootMapa.colorBorde;
                            ctx.stroke();

                            // Parque verde vertical en la esquina sup-izq del bloque sureste (al lado izq. de Escuela de Telecom)
                            ctx.fillStyle = rootMapa.colorVerde;
                            ctx.strokeStyle = rootMapa.colorVerdeBorde;
                            ctx.lineWidth = 1.5;
                            ctx.fillRect(558, 518, 48, 84);
                            ctx.strokeRect(558, 518, 48, 84);

                            // 2 círculos grises y 1 círculo marrón dentro del parque verde de Telecom (tal cual la imagen)
                            var circulosGrisesTelecom = [[584, 533], [570, 568]];
                            for (var cgt = 0; cgt < circulosGrisesTelecom.length; cgt++) {
                                ctx.beginPath();
                                ctx.arc(circulosGrisesTelecom[cgt][0], circulosGrisesTelecom[cgt][1], 5.2, 0, Math.PI * 2);
                                ctx.fillStyle = rootMapa.colorTrazo;
                                ctx.fill();
                                ctx.lineWidth = 1.1;
                                ctx.strokeStyle = rootMapa.colorTextoEdificio;
                                ctx.stroke();
                            }
                            ctx.beginPath();
                            ctx.arc(588, 560, 5.2, 0, Math.PI * 2);
                            ctx.fillStyle = "#78350f";
                            ctx.fill();
                            ctx.lineWidth = 1.1;
                            ctx.strokeStyle = "#fde68a";
                            ctx.stroke();

                            // Líneas verticales de pared interna junto a AD1M (x=676) y AD2M (x=758)
                            ctx.strokeStyle = rootMapa.colorTextoEdificio;
                            ctx.lineWidth = 1.8;
                            ctx.beginPath();
                            ctx.moveTo(676, 582); ctx.lineTo(676, 650);
                            ctx.moveTo(758, 582); ctx.lineTo(758, 636);
                            ctx.stroke();
                            ctx.restore();

                            // Textos de las Avenidas y Accesos Principales
                            ctx.fillStyle = rootMapa.colorBorde;
                            ctx.font = "bold 10px sans-serif";
                            ctx.textAlign = "center";
                            ctx.fillText("ESTACIONAMIENTO DE ESTUDIANTES", 540, 88);
                            ctx.fillText("Estacionamiento de profesores", 345, 162);
                            ctx.fillText("Estacionamiento de", 860, 206);
                            ctx.fillText("Profesores", 860, 217);
                            ctx.fillText("Vigilancia", 312, 95);
                            ctx.fillStyle = rootMapa.colorTextoPlano;
                            ctx.font = "bold 8px serif";
                            ctx.fillText("Vigilancia", 222, 496);
                            ctx.font = "bold 7.5px serif";
                            ctx.fillText("Entrada a Ingeniería", 92, 510);
                            ctx.font = "bold 11px serif";
                            ctx.fillText("Estacionamiento", 666, 468);
                            ctx.fillStyle = rootMapa.colorTextoEdificio;
                            ctx.font = "bold 7px serif";
                            ctx.fillText("Parada de buses", 440, 692);
                            ctx.fillText("Parada de buses", 440, 726);
                            ctx.fillText("VIGILANCIA", 584, 673);
                            ctx.font = "bold 8px sans-serif";
                            ctx.fillText("VIA FACES", 805, 709);

                            // Texto rotado Av. Universidad
                            ctx.save();
                            ctx.translate(19, 390);
                            ctx.rotate(-Math.PI / 2);
                            ctx.fillStyle = rootMapa.colorBordeEscuela;
                            ctx.font = "bold 12px sans-serif";
                            ctx.fillText("AV. UNIVERSIDAD", 0, 0);
                            ctx.restore();

                            // Texto rotado Entrada por FACYT
                            ctx.save();
                            ctx.translate(544, 615);
                            ctx.rotate(-Math.PI / 2);
                            ctx.fillStyle = rootMapa.colorTextoEdificio;
                            ctx.font = "bold 8.5px serif";
                            ctx.fillText("ENTRADA POR FACYT", 0, 0);
                            ctx.restore();

                            // Texto rotado Entrada por Medicina y DKESCORPIO 26/10/2023 (borde derecho inferior)
                            ctx.save();
                            ctx.translate(973, 615);
                            ctx.rotate(-Math.PI / 2);
                            ctx.fillStyle = rootMapa.colorTextoEdificio;
                            ctx.font = "bold 8px serif";
                            ctx.fillText("ENTRADA POR MEDICINA", 0, 0);
                            ctx.restore();

                            ctx.save();
                            ctx.translate(998, 615);
                            ctx.rotate(-Math.PI / 2);
                            ctx.fillStyle = rootMapa.colorBorde;
                            ctx.font = "bold 8.5px serif";
                            ctx.fillText("DKESCORPIO 26/10/2023", 0, 0);
                            ctx.restore();

                            // Casetas de Vigilancia (Azules como en el plano original)
                            var vigilancias = [[268, 82, 20, 28], [176, 488, 24, 22], [558, 678, 22, 22]];
                            for (var v = 0; v < vigilancias.length; v++) {
                                ctx.fillStyle = "#1d4ed8";
                                ctx.fillRect(vigilancias[v][0], vigilancias[v][1], vigilancias[v][2], vigilancias[v][3]);
                                ctx.strokeStyle = rootMapa.colorBordeMiAula;
                                ctx.lineWidth = 1.5;
                                ctx.strokeRect(vigilancias[v][0], vigilancias[v][1], vigilancias[v][2], vigilancias[v][3]);
                            }

                            // 3. DIBUJAR TODOS LOS EDIFICIOS Y SALONES CON SUS FORMAS REALES
                            for (var i = 0; i < rootMapa.bloquesFacultad.length; i++) {
                                var b = rootMapa.bloquesFacultad[i];
                                var activo = (i === rootMapa.idSeleccionado);
                                var visiblePorFiltro = rootMapa.cumpleFiltro(b);
                                var esMiAula = rootMapa.esMiAulaHorario(b);

                                ctx.save();
                                ctx.globalAlpha = visiblePorFiltro ? 1.0 : 0.14;

                                var fillCol = rootMapa.colorEdificio;
                                var strokeCol = rootMapa.colorBorde;

                                if (b.colorTipo === "panaderia") {
                                    fillCol = "#ea580c"; // Naranja intenso como Panadería en la imagen
                                    strokeCol = "#fed7aa";
                                } else if (b.colorTipo === "fisicoquim") {
                                    fillCol = "#dc2626"; // Rojo intenso como Fisico Química en la imagen
                                    strokeCol = "#fecaca";
                                } else if (b.colorTipo === "aula_roja") {
                                    fillCol = rootMapa.colorEdificio;
                                    strokeCol = "#ef4444"; // Borde rojo como A9I, A8I, A6E, A5E
                                } else if (b.colorTipo === "miaula_roja") {
                                    fillCol = rootMapa.colorMiAula;
                                    strokeCol = "#f87171"; // Borde rojo brillante + fondo azul para tus aulas A7E / SEIN
                                } else if (b.colorTipo === "miaula") {
                                    fillCol = rootMapa.colorMiAula;
                                    strokeCol = rootMapa.colorBordeMiAula;
                                } else if (b.colorTipo === "ad") {
                                    fillCol = "#ca8a04"; // Amarillo/Dorado como los trapecios AD4 / AD2 de la imagen
                                    strokeCol = "#fef08a";
                                } else if (b.colorTipo === "verde") {
                                    fillCol = rootMapa.colorVerde;
                                    strokeCol = rootMapa.colorVerdeBorde;
                                } else if (b.colorTipo === "escuela") {
                                    fillCol = rootMapa.colorEscuela;
                                    strokeCol = rootMapa.colorBordeEscuela;
                                } else if (b.colorTipo === "importante") {
                                    fillCol = rootMapa.colorEscuela;
                                    strokeCol = rootMapa.colorBordeDestacado;
                                } else if (b.colorTipo === "deporte") {
                                    fillCol = rootMapa.colorEdificio;
                                    strokeCol = rootMapa.colorBordeDeporte;
                                } else if (b.colorTipo === "servicio") {
                                    fillCol = rootMapa.colorEdificio;
                                    strokeCol = "#fb923c";
                                } else if (b.colorTipo === "blanco") {
                                    fillCol = rootMapa.colorEdificio;
                                    strokeCol = rootMapa.colorBorde;
                                }

                                if (activo) {
                                    fillCol = temaApp.primario;
                                    strokeCol = rootMapa.colorTextoEdificio;
                                }

                                ctx.fillStyle = fillCol;
                                ctx.strokeStyle = strokeCol;
                                ctx.lineWidth = activo ? 2.5 : 1.6;

                                // Geometría específica según el edificio
                                if (b.forma === "trapecio_d") {
                                    // Trapecio tipo anfiteatro mirando a la derecha (AD4, AD2, AD5, AD8)
                                    ctx.beginPath();
                                    ctx.moveTo(b.x, b.y);
                                    ctx.lineTo(b.x + b.w, b.y + 6);
                                    ctx.lineTo(b.x + b.w, b.y + b.h - 6);
                                    ctx.lineTo(b.x, b.y + b.h);
                                    ctx.closePath();
                                    ctx.fill();
                                    ctx.stroke();
                                } else if (b.forma === "trapecio_i") {
                                    // Trapecio tipo anfiteatro con lado derecho más alto (AD3, AD1, AD6, AD7, AD9)
                                    ctx.beginPath();
                                    ctx.moveTo(b.x, b.y + 5);
                                    ctx.lineTo(b.x + b.w, b.y);
                                    ctx.lineTo(b.x + b.w, b.y + b.h);
                                    ctx.lineTo(b.x, b.y + b.h - 5);
                                    ctx.closePath();
                                    ctx.fill();
                                    ctx.stroke();
                                } else if (b.forma === "sio_publ") {
                                    // Pabellón vertical SIO / SOE / PUBLICACIONES con sus divisiones internas
                                    ctx.fillRect(b.x, b.y, b.w, b.h);
                                    ctx.strokeRect(b.x, b.y, b.w, b.h);
                                    ctx.beginPath();
                                    ctx.moveTo(b.x, b.y + 90);  ctx.lineTo(b.x + b.w, b.y + 90);
                                    ctx.moveTo(b.x, b.y + 110); ctx.lineTo(b.x + b.w, b.y + 110);
                                    ctx.moveTo(b.x, b.y + 130); ctx.lineTo(b.x + 12,  b.y + 130);
                                    ctx.stroke();
                                } else if (b.forma === "biblio") {
                                    // Cabecera superior blanca "EDIFICIO" + Cuerpo borde rojo "EDIFICIO BIBLIOTECA CENTRAL" + Anexo inferior "Coordinación de Cultura"
                                    ctx.fillStyle = rootMapa.colorEdificio;
                                    ctx.strokeStyle = rootMapa.colorBorde;
                                    ctx.lineWidth = 1.4;
                                    ctx.fillRect(b.x, b.y - 14, b.w, 14);
                                    ctx.strokeRect(b.x, b.y - 14, b.w, 14);

                                    // Anexo inferior en escalón de Coordinación de Cultura
                                    ctx.beginPath();
                                    ctx.moveTo(b.x + 18, b.y + b.h);
                                    ctx.lineTo(b.x + b.w, b.y + b.h);
                                    ctx.lineTo(b.x + b.w, b.y + b.h + 26);
                                    ctx.lineTo(b.x + 54, b.y + b.h + 26);
                                    ctx.lineTo(b.x + 54, b.y + b.h + 18);
                                    ctx.lineTo(b.x + 30, b.y + b.h + 18);
                                    ctx.lineTo(b.x + 30, b.y + b.h + 24);
                                    ctx.lineTo(b.x + 18, b.y + b.h + 24);
                                    ctx.closePath();
                                    ctx.fill();
                                    ctx.stroke();

                                    // Rectángulo principal de borde rojo (Aulas 101-104, 201-209, 301-310)
                                    ctx.fillStyle = fillCol;
                                    ctx.strokeStyle = activo ? rootMapa.colorTextoEdificio : "#ef4444";
                                    ctx.lineWidth = activo ? 2.6 : 2.0;
                                    ctx.fillRect(b.x, b.y, b.w, b.h);
                                    ctx.strokeRect(b.x, b.y, b.w, b.h);
                                } else if (b.forma === "sie5_led") {
                                    // Bloque LED con su cuello inferior que conecta con SIE 1 + recuadro superior borde rojo de SIE 5
                                    ctx.fillStyle = fillCol;
                                    ctx.strokeStyle = rootMapa.colorBorde;
                                    ctx.lineWidth = 1.5;
                                    ctx.beginPath();
                                    ctx.moveTo(b.x, b.y + 10);
                                    ctx.lineTo(b.x + b.w, b.y + 10);
                                    ctx.lineTo(b.x + b.w, b.y + 30);
                                    ctx.lineTo(b.x + 20, b.y + 30);
                                    ctx.lineTo(b.x + 20, b.y + b.h);
                                    ctx.lineTo(b.x + 4, b.y + b.h);
                                    ctx.lineTo(b.x + 4, b.y + 30);
                                    ctx.lineTo(b.x, b.y + 30);
                                    ctx.closePath();
                                    ctx.fill();
                                    ctx.stroke();

                                    ctx.fillStyle = rootMapa.colorEdificio;
                                    ctx.strokeStyle = activo ? rootMapa.colorTextoEdificio : "#ef4444";
                                    ctx.lineWidth = 2.0;
                                    ctx.fillRect(b.x + 6, b.y, b.w - 8, 11);
                                    ctx.strokeRect(b.x + 6, b.y, b.w - 8, 11);
                                } else if (b.forma === "sie1_sie2") {
                                    // Parte superior ancha (SIE 1, x=716..774, y=158..194) + franja vertical izquierda (SIE 2, x=716..730, y=194..288)
                                    ctx.beginPath();
                                    ctx.moveTo(b.x, b.y);
                                    ctx.lineTo(b.x + b.w, b.y);
                                    ctx.lineTo(b.x + b.w, b.y + 36);
                                    ctx.lineTo(b.x + 14, b.y + 36);
                                    ctx.lineTo(b.x + 14, b.y + b.h);
                                    ctx.lineTo(b.x, b.y + b.h);
                                    ctx.closePath();
                                    ctx.fill();
                                    ctx.stroke();
                                    // Líneas internas del pasillo de SIE 1 hacia el puente de SLM
                                    ctx.beginPath();
                                    ctx.moveTo(b.x + 14, b.y + 13);
                                    ctx.lineTo(b.x + b.w, b.y + 13);
                                    ctx.moveTo(b.x + 30, b.y + 36);
                                    ctx.lineTo(b.x + 30, b.y + 23);
                                    ctx.lineTo(b.x + b.w, b.y + 23);
                                    ctx.stroke();
                                } else if (b.forma === "esc_elec") {
                                    ctx.fillRect(b.x, b.y, b.w, b.h);
                                    ctx.strokeRect(b.x, b.y, b.w, b.h);
                                } else if (b.forma === "maq_procesos") {
                                    // 1) Bloque superior: LABORATORIO DE MAQ. ELECTRICAS (h=20)
                                    ctx.fillRect(b.x, b.y, b.w, 20);
                                    ctx.strokeRect(b.x, b.y, b.w, 20);

                                    // 2) Bloque inferior escalonado: ALT / Lab. Procesos / HP2
                                    ctx.beginPath();
                                    ctx.moveTo(b.x, b.y + 44);
                                    ctx.lineTo(b.x + 36, b.y + 44);
                                    ctx.lineTo(b.x + 36, b.y + 36);
                                    ctx.lineTo(b.x + b.w, b.y + 36);
                                    ctx.lineTo(b.x + b.w, b.y + b.h);
                                    ctx.lineTo(b.x, b.y + b.h);
                                    ctx.closePath();
                                    ctx.fill();
                                    ctx.stroke();

                                    // 3) Jardinera verde intermedia con escalón y 3 árboles marrones
                                    ctx.beginPath();
                                    ctx.moveTo(b.x, b.y + 20);
                                    ctx.lineTo(b.x + b.w, b.y + 20);
                                    ctx.lineTo(b.x + b.w, b.y + 36);
                                    ctx.lineTo(b.x + 36, b.y + 36);
                                    ctx.lineTo(b.x + 36, b.y + 44);
                                    ctx.lineTo(b.x, b.y + 44);
                                    ctx.closePath();
                                    ctx.fillStyle = rootMapa.colorVerde;
                                    ctx.fill();
                                    ctx.strokeStyle = rootMapa.colorVerdeBorde;
                                    ctx.lineWidth = 1.3;
                                    ctx.stroke();

                                    var arbolesMaq = [[b.x + 18, b.y + 33], [b.x + 46, b.y + 27], [b.x + 76, b.y + 29]];
                                    for (var am = 0; am < arbolesMaq.length; am++) {
                                        ctx.beginPath();
                                        ctx.arc(arbolesMaq[am][0], arbolesMaq[am][1], 4.5, 0, Math.PI * 2);
                                        ctx.fillStyle = "#78350f";
                                        ctx.fill();
                                        ctx.lineWidth = 1.2;
                                        ctx.strokeStyle = "#fde68a";
                                        ctx.stroke();
                                    }
                                } else if (b.forma === "mantenim") {
                                    // Marco azul oscuro grueso con recuadro interior claro de "Mantenimiento"
                                    ctx.fillStyle = activo ? temaApp.primario : rootMapa.colorMiAula;
                                    ctx.strokeStyle = activo ? rootMapa.colorTextoEdificio : rootMapa.colorBordeMiAula;
                                    ctx.fillRect(b.x, b.y, b.w, b.h);
                                    ctx.strokeRect(b.x, b.y, b.w, b.h);

                                    ctx.fillStyle = rootMapa.colorEdificio;
                                    ctx.strokeStyle = rootMapa.colorTextoEdificio;
                                    ctx.lineWidth = 1.2;
                                    ctx.fillRect(b.x + 5, b.y + 5, b.w - 10, b.h - 10);
                                    ctx.strokeRect(b.x + 5, b.y + 5, b.w - 10, b.h - 10);
                                } else if (b.forma === "fisica_af") {
                                    // Bloque superior: CUBÍCULOS Y OFIC FÍSICA + fila inferior dividida en AF1 | AF2 | LAB. DE FÍSICA
                                    ctx.fillRect(b.x, b.y, b.w, b.h);
                                    ctx.strokeRect(b.x, b.y, b.w, b.h);
                                    ctx.beginPath();
                                    ctx.moveTo(b.x, b.y + 12);      ctx.lineTo(b.x + b.w, b.y + 12);
                                    ctx.moveTo(b.x + 20, b.y + 12); ctx.lineTo(b.x + 20, b.y + b.h);
                                    ctx.moveTo(b.x + 40, b.y + 12); ctx.lineTo(b.x + 40, b.y + b.h);
                                    ctx.stroke();
                                } else if (b.forma === "cei_comp") {
                                    // Columna izquierda vertical C.E.I. + derecha dividida en Cubic. Física 2 (arriba) y COMPUTACIÓN (abajo)
                                    ctx.fillRect(b.x, b.y, b.w, b.h);
                                    ctx.strokeRect(b.x, b.y, b.w, b.h);
                                    ctx.beginPath();
                                    ctx.moveTo(b.x + 15, b.y);      ctx.lineTo(b.x + 15, b.y + b.h);
                                    ctx.moveTo(b.x + 15, b.y + 12); ctx.lineTo(b.x + b.w, b.y + 12);
                                    ctx.stroke();
                                } else if (b.forma === "boulevard") {
                                    // Marco amarillo grueso del Boulevard con rectángulo blanco central
                                    ctx.fillStyle = activo ? temaApp.primario : "#eab308";
                                    ctx.strokeStyle = activo ? rootMapa.colorTextoEdificio : "#fef08a";
                                    ctx.fillRect(b.x, b.y, b.w, b.h);
                                    ctx.strokeRect(b.x, b.y, b.w, b.h);
                                    ctx.fillStyle = rootMapa.colorEdificio;
                                    ctx.strokeStyle = rootMapa.colorTextoEdificio;
                                    ctx.lineWidth = 1.2;
                                    ctx.fillRect(b.x + 8, b.y + 8, b.w - 16, b.h - 16);
                                    ctx.strokeRect(b.x + 8, b.y + 8, b.w - 16, b.h - 16);
                                } else if (b.forma === "lab_civil") {
                                    // Polígono escalonado de "Laboratorios y Oficinas" tal cual la imagen
                                    ctx.beginPath();
                                    ctx.moveTo(b.x, b.y);
                                    ctx.lineTo(b.x + b.w, b.y);
                                    ctx.lineTo(b.x + b.w, b.y + b.h - 8);
                                    ctx.lineTo(b.x + b.w - 22, b.y + b.h - 8);
                                    ctx.lineTo(b.x + b.w - 22, b.y + b.h);
                                    ctx.lineTo(b.x + 12, b.y + b.h);
                                    ctx.lineTo(b.x + 12, b.y + 10);
                                    ctx.lineTo(b.x, b.y + 10);
                                    ctx.closePath();
                                    ctx.fill();
                                    ctx.stroke();
                                } else if (b.forma === "hidraulica") {
                                    // Polígono con escalón inferior izquierdo para el Estacionamiento de Mecánica
                                    ctx.beginPath();
                                    ctx.moveTo(b.x, b.y);
                                    ctx.lineTo(b.x + b.w, b.y);
                                    ctx.lineTo(b.x + b.w, b.y + b.h);
                                    ctx.lineTo(b.x + 32, b.y + b.h);
                                    ctx.lineTo(b.x + 32, b.y + b.h - 20);
                                    ctx.lineTo(b.x, b.y + b.h - 20);
                                    ctx.closePath();
                                    ctx.fill();
                                    ctx.stroke();
                                } else if (b.forma === "quimica_cub") {
                                    // Polígono de Cubículos y Lab de Química con pequeño escalón inferior izquierdo (tal cual la imagen)
                                    ctx.beginPath();
                                    ctx.moveTo(b.x, b.y);
                                    ctx.lineTo(b.x + b.w, b.y);
                                    ctx.lineTo(b.x + b.w, b.y + b.h - 2);
                                    ctx.lineTo(b.x + 16, b.y + b.h - 2);
                                    ctx.lineTo(b.x + 16, b.y + b.h);
                                    ctx.lineTo(b.x, b.y + b.h);
                                    ctx.closePath();
                                    ctx.fill();
                                    ctx.stroke();
                                } else if (b.forma === "dibujo") {
                                    // Bloque superior de Dibujo (AGD / APD) + bloque inferior izquierdo (SD3 SD2 SD1) + recuadro derecho (SDC)
                                    ctx.fillRect(b.x, b.y, b.w, 19);
                                    ctx.strokeRect(b.x, b.y, b.w, 19);
                                    ctx.fillRect(b.x, b.y + 19, 57, b.h - 19);
                                    ctx.strokeRect(b.x, b.y + 19, 57, b.h - 19);
                                    ctx.fillRect(b.x + 59, b.y + 19, b.w - 59, b.h - 19);
                                    ctx.strokeRect(b.x + 59, b.y + 19, b.w - 59, b.h - 19);
                                } else if (b.forma === "decanato_t") {
                                    // 1) Cuerpo en forma de "T" que une DECANATO (barra superior x=452..574) con CONTROL DE ESTUDIOS (x=480..523)
                                    ctx.beginPath();
                                    ctx.moveTo(b.x, b.y);                  // Esquina sup-izq de Decanato (452, 421)
                                    ctx.lineTo(b.x + b.w, b.y);            // Esquina sup-der de Decanato (574, 421)
                                    ctx.lineTo(b.x + b.w, b.y + 18);       // Esquina inf-der de Decanato (574, 439)
                                    ctx.lineTo(b.x + 71, b.y + 18);        // Unión derecha con Control de Estudios (523, 439)
                                    ctx.lineTo(b.x + 71, b.y + b.h);       // Esquina inf-der de Control de Estudios (523, 478)
                                    ctx.lineTo(b.x + 28, b.y + b.h);       // Esquina inf-izq de Control de Estudios (480, 478)
                                    ctx.lineTo(b.x + 28, b.y + 18);        // Unión izquierda con Control de Estudios (480, 439)
                                    ctx.lineTo(b.x, b.y + 18);             // Esquina inf-izq de Decanato (452, 439)
                                    ctx.closePath();
                                    ctx.fill();
                                    ctx.stroke();

                                    // 2) Recuadro azul celeste grueso sobre el ala vertical de CONTROL DE ESTUDIOS (x=480..523, y=439..478)
                                    ctx.strokeStyle = activo ? rootMapa.colorTextoEdificio : rootMapa.colorBordeMiAula;
                                    ctx.lineWidth = 2.6;
                                    ctx.strokeRect(b.x + 28, b.y + 18, 43, b.h - 18);

                                    // 3) Del lado izquierdo (bajo el ala izq. de Decanato): rectángulo azul arriba + pasillo blanco + rectángulo verde abajo
                                    ctx.fillStyle = "#0284c7";
                                    ctx.strokeStyle = rootMapa.colorBordeDestacado;
                                    ctx.lineWidth = 1.3;
                                    ctx.fillRect(b.x, b.y + 21, 25, 15);
                                    ctx.strokeRect(b.x, b.y + 21, 25, 15);

                                    ctx.fillStyle = rootMapa.colorTextoEdificio;
                                    ctx.fillRect(b.x, b.y + 37, 25, 4);

                                    ctx.fillStyle = rootMapa.colorVerde;
                                    ctx.strokeStyle = rootMapa.colorVerdeBorde;
                                    ctx.fillRect(b.x, b.y + 42, 25, 15);
                                    ctx.strokeRect(b.x, b.y + 42, 25, 15);

                                    // 4) Del lado derecho (junto a Control de Estudios): módulo vertical de "Fotocopias"
                                    ctx.fillStyle = rootMapa.colorEdificio;
                                    ctx.strokeStyle = rootMapa.colorBorde;
                                    ctx.lineWidth = 1.4;
                                    ctx.fillRect(b.x + 74, b.y + 21, 13, 36);
                                    ctx.strokeRect(b.x + 74, b.y + 21, 13, 36);
                                } else if (b.forma === "slm_sie3") {
                                    // Pabellón rectangular limpio SLM / SIE 3 (conectado por su centro izquierdo con Escuela de Eléctrica)
                                    ctx.fillRect(b.x, b.y, b.w, b.h);
                                    ctx.strokeRect(b.x, b.y, b.w, b.h);
                                } else if (b.forma === "imyca") {
                                    // I.M.Y.C.A.: edificio vertical (x=b.x+12..b.x+b.w) con saliente rectangular a la izquierda (y=b.y+28..b.y+44)
                                    ctx.beginPath();
                                    ctx.moveTo(b.x + 12, b.y);
                                    ctx.lineTo(b.x + b.w, b.y);
                                    ctx.lineTo(b.x + b.w, b.y + b.h);
                                    ctx.lineTo(b.x + 12, b.y + b.h);
                                    ctx.lineTo(b.x + 12, b.y + 44);
                                    ctx.lineTo(b.x,      b.y + 44);
                                    ctx.lineTo(b.x,      b.y + 28);
                                    ctx.lineTo(b.x + 12, b.y + 28);
                                    ctx.closePath();
                                    ctx.fill();
                                    ctx.stroke();
                                } else if (b.forma === "humanidades") {
                                    // Dpto. de Humanidades y HU en un solo polígono continuo con escalón inferior izquierdo bajo "HU"
                                    ctx.beginPath();
                                    ctx.moveTo(b.x, b.y);
                                    ctx.lineTo(b.x + b.w, b.y);
                                    ctx.lineTo(b.x + b.w, b.y + b.h - 5);
                                    ctx.lineTo(b.x + 28, b.y + b.h - 5);
                                    ctx.lineTo(b.x + 28, b.y + b.h);
                                    ctx.lineTo(b.x, b.y + b.h);
                                    ctx.closePath();
                                    ctx.fill();
                                    ctx.stroke();
                                } else if (b.forma === "canchas") {
                                    // Cancha Básquet (arriba) y Cancha Fútbol (abajo) en color cian como en la imagen
                                    ctx.fillStyle = activo ? temaApp.primario : rootMapa.colorBordeDeporte;
                                    ctx.strokeStyle = activo ? rootMapa.colorTextoEdificio : "#cffafe";
                                    ctx.lineWidth = 2.0;
                                    ctx.fillRect(b.x, b.y, b.w, b.h);
                                    ctx.strokeRect(b.x, b.y, b.w, b.h);
                                    ctx.beginPath();
                                    ctx.moveTo(b.x, b.y + b.h / 2);
                                    ctx.lineTo(b.x + b.w, b.y + b.h / 2);
                                    ctx.stroke();
                                } else if (b.forma === "complejo_mecanica") {
                                    // Complejo arquitectónico completo de la Escuela de Mecánica (fiel a la imagen)
                                    var fillMec = activo ? temaApp.primario : rootMapa.colorEdificio;
                                    var strokeMec = activo ? rootMapa.colorTextoEdificio : rootMapa.colorBorde;
                                    ctx.fillStyle = fillMec;
                                    ctx.strokeStyle = strokeMec;
                                    ctx.lineWidth = activo ? 2.2 : 1.5;

                                    // 1) Rectángulo superior izquierdo (sobre C.I.Q.)
                                    ctx.fillRect(124, 368, 42, 14);
                                    ctx.strokeRect(124, 368, 42, 14);

                                    // 2) Recuadro de "lab termicas" bajo la diagonal
                                    ctx.fillRect(78, 396, 36, 18);
                                    ctx.strokeRect(78, 396, 36, 18);

                                    // 3) Pequeña pestaña superior izquierda sobre Biblioteca Mecánica
                                    ctx.fillRect(42, 408, 24, 8);
                                    ctx.strokeRect(42, 408, 24, 8);

                                    // 4) Edificio de C.I.Q. / ASOVAC (con el pequeño cuadrito interno superior sobre ASOVAC)
                                    ctx.fillRect(124, 386, 92, 30);
                                    ctx.strokeRect(124, 386, 92, 30);
                                    ctx.strokeRect(194, 386, 12, 9);

                                    // 5) Rectángulo intermedio debajo de "lab termicas" (con borde doble izquierdo)
                                    ctx.fillRect(74, 416, 50, 20);
                                    ctx.strokeRect(74, 416, 50, 20);
                                    ctx.beginPath();
                                    ctx.moveTo(78, 416); ctx.lineTo(78, 436);
                                    ctx.stroke();

                                    // 6) Bloque de Biblioteca Mecánica (izquierda) + salón contiguo a su derecha
                                    ctx.fillRect(42, 416, 32, 44);
                                    ctx.strokeRect(42, 416, 32, 44);
                                    ctx.beginPath();
                                    ctx.moveTo(56, 416); ctx.lineTo(56, 438);
                                    ctx.stroke();

                                    ctx.fillRect(74, 438, 24, 20);
                                    ctx.strokeRect(74, 438, 24, 20);

                                    // 7) Pabellón en forma de "L" de ANM (ala izquierda) y Escuela de MECANICA (ala derecha que baja hasta y=478)
                                    ctx.beginPath();
                                    ctx.moveTo(102, 438);
                                    ctx.lineTo(216, 438);
                                    ctx.lineTo(216, 478);
                                    ctx.lineTo(166, 478);
                                    ctx.lineTo(166, 458);
                                    ctx.lineTo(102, 458);
                                    ctx.closePath();
                                    ctx.fill();
                                    ctx.stroke();

                                    // 8) Fila inferior: recuadro pequeño izquierdo + bloque alargado de ASM y SPM
                                    ctx.fillRect(42, 460, 8, 18);
                                    ctx.strokeRect(42, 460, 8, 18);
                                    ctx.fillRect(50, 460, 22, 14);
                                    ctx.strokeRect(50, 460, 22, 14);
                                    ctx.fillRect(72, 460, 94, 18);
                                    ctx.strokeRect(72, 460, 94, 18);

                                    // 9) Los 4 árboles marrones en los dos patios de Mecánica (2 arriba de ASOVAC y 2 debajo de ASOVAC)
                                    var arbolesMec = [[192, 377], [214, 377], [172, 427], [196, 427]];
                                    for (var amc = 0; amc < arbolesMec.length; amc++) {
                                        ctx.beginPath();
                                        ctx.arc(arbolesMec[amc][0], arbolesMec[amc][1], 4.6, 0, Math.PI * 2);
                                        ctx.fillStyle = "#78350f";
                                        ctx.fill();
                                        ctx.lineWidth = 1.2;
                                        ctx.strokeStyle = "#fde68a";
                                        ctx.stroke();
                                    }
                                } else if (b.forma === "esc_quim") {
                                    ctx.fillStyle = activo ? temaApp.primario : rootMapa.colorRecinto;
                                    ctx.strokeStyle = activo ? rootMapa.colorTextoEdificio : rootMapa.colorBordeMiAula;
                                    ctx.fillRect(b.x, b.y, b.w, b.h);
                                    ctx.strokeRect(b.x, b.y, b.w, b.h);
                                } else if (b.forma === "plaza_iguanas") {
                                    // Triángulo verde de Plaza las Iguanas con punta derecha redondeada, caminerías marrones y 3 redomas circulares
                                    ctx.beginPath();
                                    ctx.moveTo(b.x, b.y);
                                    ctx.lineTo(b.x + b.w - 4, b.y);
                                    ctx.quadraticCurveTo(b.x + b.w + 2, b.y, b.x + b.w - 2, b.y + 6);
                                    ctx.lineTo(b.x, b.y + b.h);
                                    ctx.closePath();
                                    ctx.fillStyle = activo ? temaApp.primario : rootMapa.colorVerde;
                                    ctx.fill();
                                    ctx.strokeStyle = activo ? rootMapa.colorTextoEdificio : rootMapa.colorVerdeBorde;
                                    ctx.lineWidth = activo ? 2.2 : 1.6;
                                    ctx.stroke();

                                    // Caminerías marrones ramificadas desde el borde superior (tal cual la imagen)
                                    ctx.save();
                                    ctx.strokeStyle = "#78350f";
                                    ctx.lineWidth = 4.2;
                                    ctx.lineCap = "round";
                                    ctx.beginPath();
                                    ctx.moveTo(b.x + 28, b.y + 2);  ctx.lineTo(b.x + 56, b.y + 24);
                                    ctx.moveTo(b.x + 48, b.y + 2);  ctx.lineTo(b.x + 58, b.y + 42);
                                    ctx.moveTo(b.x + 58, b.y + 24); ctx.lineTo(b.x + 96, b.y + 30);
                                    ctx.moveTo(b.x + 92, b.y + 2);  ctx.lineTo(b.x + 96, b.y + 34);
                                    ctx.moveTo(b.x + 126, b.y + 2); ctx.lineTo(b.x + 128, b.y + 24);
                                    ctx.stroke();

                                    // Las 3 redomas circulares blancas con 3 puntitos oscuros cada una
                                    var redomasIguanas = [[b.x + 38, b.y + 22], [b.x + 76, b.y + 26], [b.x + 110, b.y + 17]];
                                    for (var ri = 0; ri < redomasIguanas.length; ri++) {
                                        var rx = redomasIguanas[ri][0];
                                        var ry = redomasIguanas[ri][1];
                                        ctx.beginPath();
                                        ctx.arc(rx, ry, 9.5, 0, Math.PI * 2);
                                        ctx.fillStyle = rootMapa.colorPapel;
                                        ctx.fill();
                                        ctx.lineWidth = 1.4;
                                        ctx.strokeStyle = "#1e293b";
                                        ctx.stroke();

                                        var pts = [[-3.5, -2], [3.5, -2], [0, 3.5]];
                                        for (var p = 0; p < pts.length; p++) {
                                            ctx.beginPath();
                                            ctx.arc(rx + pts[p][0], ry + pts[p][1], 1.6, 0, Math.PI * 2);
                                            ctx.fillStyle = "#0f172a";
                                            ctx.fill();
                                        }
                                    }
                                    ctx.restore();
                                } else if (b.forma === "fcu_ae1_3") {
                                    // Columna de 4 recuadros con borde morado: FCU, AE3, AE2, AE1
                                    var hBox = b.h / 4;
                                    ctx.fillStyle = activo ? temaApp.primario : rootMapa.colorEdificio;
                                    ctx.strokeStyle = activo ? rootMapa.colorTextoEdificio : rootMapa.colorBordeEscuela;
                                    ctx.lineWidth = activo ? 2.2 : 1.6;
                                    for (var kAe = 0; kAe < 4; kAe++) {
                                        ctx.fillRect(b.x, b.y + kAe * hBox, b.w, hBox);
                                        ctx.strokeRect(b.x, b.y + kAe * hBox, b.w, hBox);
                                    }
                                } else if (b.forma === "ae8_ae9") {
                                    // Rectángulo horizontal con borde cian brillante de AE8 / AE9
                                    ctx.fillStyle = activo ? temaApp.primario : rootMapa.colorEscuela;
                                    ctx.strokeStyle = activo ? rootMapa.colorTextoEdificio : rootMapa.colorBordeDeporte;
                                    ctx.lineWidth = activo ? 2.4 : 1.8;
                                    ctx.fillRect(b.x, b.y, b.w, b.h);
                                    ctx.strokeRect(b.x, b.y, b.w, b.h);
                                } else if (b.forma === "ae4_7") {
                                    // Fila de 4 recuadros verticales con borde rojo: AE7, AE6, AE5, AE4
                                    var wAe = b.w / 4;
                                    ctx.fillStyle = activo ? temaApp.primario : rootMapa.colorEdificio;
                                    ctx.strokeStyle = activo ? rootMapa.colorTextoEdificio : "#ef4444";
                                    ctx.lineWidth = activo ? 2.2 : 1.6;
                                    for (var mAe = 0; mAe < 4; mAe++) {
                                        ctx.fillRect(b.x + mAe * wAe, b.y, wAe, b.h);
                                        ctx.strokeRect(b.x + mAe * wAe, b.y, wAe, b.h);
                                    }
                                } else if (b.forma === "auditorio_maneiro") {
                                    // Marco verde oliva con centro claro arriba + texto verde debajo
                                    ctx.fillStyle = activo ? temaApp.primario : "#65a30d";
                                    ctx.strokeStyle = activo ? rootMapa.colorTextoEdificio : rootMapa.colorVerdeBorde;
                                    ctx.lineWidth = 1.6;
                                    ctx.fillRect(b.x + 2, b.y + 2, 24, 18);
                                    ctx.strokeRect(b.x + 2, b.y + 2, 24, 18);

                                    ctx.fillStyle = rootMapa.colorBorde;
                                    ctx.fillRect(b.x + 7, b.y + 6, 14, 10);
                                } else if (b.forma === "a10_a11") {
                                    // Rectángulo vertical con borde morado dividido en A10 (arriba) y A11 (abajo)
                                    ctx.fillStyle = activo ? temaApp.primario : rootMapa.colorEdificio;
                                    ctx.strokeStyle = activo ? rootMapa.colorTextoEdificio : rootMapa.colorBordeEscuela;
                                    ctx.lineWidth = activo ? 2.4 : 1.8;
                                    ctx.fillRect(b.x, b.y, b.w, b.h);
                                    ctx.strokeRect(b.x, b.y, b.w, b.h);
                                    ctx.beginPath();
                                    ctx.moveTo(b.x, b.y + b.h / 2);
                                    ctx.lineTo(b.x + b.w, b.y + b.h / 2);
                                    ctx.stroke();
                                } else if (b.forma === "imagenes_box") {
                                    ctx.fillStyle = activo ? temaApp.primario : rootMapa.colorEdificio;
                                    ctx.strokeStyle = activo ? rootMapa.colorTextoEdificio : rootMapa.colorTextoEdificio;
                                    ctx.lineWidth = activo ? 2.2 : 1.6;
                                    ctx.fillRect(b.x, b.y, b.w, b.h);
                                    ctx.strokeRect(b.x, b.y, b.w, b.h);
                                } else if (b.forma === "facyt_area" || b.forma === "salud_area") {
                                    if (activo || (rootMapa.categoriaFiltro === 3)) {
                                        ctx.fillStyle = activo ? "#352563eb" : "#1838bdf8";
                                        ctx.strokeStyle = activo ? rootMapa.colorTextoEdificio : rootMapa.colorBordeDestacado;
                                        ctx.lineWidth = 1.5;
                                        ctx.fillRect(b.x, b.y, b.w, b.h);
                                        ctx.strokeRect(b.x, b.y, b.w, b.h);
                                    }
                                } else if (b.forma === "esc_telecom") {
                                    // Escuela de Telecom con su marco azul celeste grueso tal cual la imagen
                                    ctx.fillStyle = activo ? temaApp.primario : rootMapa.colorEdificio;
                                    ctx.strokeStyle = activo ? rootMapa.colorTextoEdificio : rootMapa.colorBordeMiAula;
                                    ctx.lineWidth = activo ? 3.2 : 2.8;
                                    ctx.fillRect(b.x, b.y, b.w, b.h);
                                    ctx.strokeRect(b.x, b.y, b.w, b.h);
                                } else if (b.forma === "redondeado" || b.forma === "fisicoquim_box") {
                                    var rr = 7;
                                    ctx.beginPath();
                                    ctx.moveTo(b.x + rr, b.y);
                                    ctx.lineTo(b.x + b.w - rr, b.y);
                                    ctx.quadraticCurveTo(b.x + b.w, b.y, b.x + b.w, b.y + rr);
                                    ctx.lineTo(b.x + b.w, b.y + b.h - rr);
                                    ctx.quadraticCurveTo(b.x + b.w, b.y + b.h, b.x + b.w - rr, b.y + b.h);
                                    ctx.lineTo(b.x + rr, b.y + b.h);
                                    ctx.quadraticCurveTo(b.x, b.y + b.h, b.x, b.y + b.h - rr);
                                    ctx.lineTo(b.x, b.y + rr);
                                    ctx.quadraticCurveTo(b.x, b.y, b.x + rr, b.y);
                                    ctx.closePath();
                                    ctx.fill();
                                    ctx.stroke();
                                } else {
                                    // Rectángulo arquitectónico exacto para bloques contiguos (A9I, A8I, A7E, SEIN, A6E, A5E...)
                                    ctx.fillRect(b.x, b.y, b.w, b.h);
                                    ctx.strokeRect(b.x, b.y, b.w, b.h);
                                }

                                // Si el filtro activo es "★ Mis Aulas" y este bloque tiene un aula inscrita, resaltar su borde en verde brillante
                                if (esMiAula && rootMapa.categoriaFiltro === 1) {
                                    ctx.strokeStyle = rootMapa.colorVerdeBorde;
                                    ctx.lineWidth = 2.6;
                                    ctx.strokeRect(b.x - 1, b.y - 1, b.w + 2, b.h + 2);
                                }

                                // Divisiones y textos internos fieles a la imagen
                                ctx.fillStyle = rootMapa.colorTextoEdificio;
                                ctx.textAlign = "center";

                                if (b.forma === "idiomas") {
                                    ctx.font = "bold 7px sans-serif";
                                    ctx.fillText("DPTO DE", b.x + 28, b.y + 12);
                                    ctx.fillText("IDIOMAS", b.x + 28, b.y + 22);
                                    // Texto vertical "AID" a la derecha dentro de Dpto de Idiomas
                                    ctx.save();
                                    ctx.translate(b.x + b.w - 9, b.y + b.h / 2);
                                    ctx.rotate(-Math.PI / 2);
                                    ctx.font = "bold 8px sans-serif";
                                    ctx.fillText("AID", 0, 0);
                                    ctx.restore();
                                } else if (b.forma === "a5e") {
                                    // División del pequeño cubículo a la derecha de A5E
                                    ctx.beginPath();
                                    ctx.moveTo(b.x + b.w - 14, b.y);
                                    ctx.lineTo(b.x + b.w - 14, b.y + b.h);
                                    ctx.stroke();
                                    ctx.font = "bold 9px sans-serif";
                                    ctx.fillText("A5E", b.x + (b.w - 14) / 2, b.y + b.h / 2 + 3);
                                } else if (b.forma === "hidraulica") {
                                    ctx.font = "bold 8px sans-serif";
                                    ctx.fillText("ESCUELA DE CIVIL", b.x + b.w / 2 + 6, b.y + 24);
                                    ctx.fillText("HIDRÁULICA", b.x + b.w / 2 + 6, b.y + 35);
                                    ctx.font = "bold 7px sans-serif";
                                    ctx.fillText("AT", b.x + b.w / 2 - 4, b.y + 10);
                                    ctx.fillText("AFP", b.x + 54, b.y + b.h - 6);
                                    ctx.fillText("AFG", b.x + b.w - 26, b.y + b.h - 6);
                                } else if (b.forma === "esc_civil") {
                                    ctx.font = "bold 8px sans-serif";
                                    ctx.fillText("Escuela", b.x + b.w / 2, b.y + 16);
                                    ctx.fillText("de", b.x + b.w / 2, b.y + 26);
                                    ctx.fillText("CIVIL", b.x + b.w / 2, b.y + 37);
                                    // Recuadros internos inferiores de Escuela de Civil
                                    ctx.strokeRect(b.x + 3, b.y + b.h - 24, 14, 14);
                                    ctx.strokeRect(b.x + b.w - 22, b.y + b.h - 14, 19, 11);
                                } else if (b.forma === "quimica_cub") {
                                    ctx.font = "bold 7px sans-serif";
                                    ctx.fillText("CUBÍCULOS Y LAB", b.x + b.w / 2, b.y + 10);
                                    ctx.fillText("DE QUÍMICA", b.x + b.w / 2 - 6, b.y + 19);
                                } else if (b.forma === "dibujo") {
                                    ctx.font = "bold 7px sans-serif";
                                    ctx.fillText("DPTO DE DIBUJO", b.x + b.w / 2 - 3, b.y + 9);
                                    ctx.fillText("AGD     APD", b.x + b.w / 2, b.y + 17);
                                    ctx.font = "bold 6px sans-serif";
                                    ctx.fillText("SD3   SD2   SD1", b.x + 28, b.y + 27);
                                    ctx.fillText("SDC", b.x + 68, b.y + 27);
                                } else if (b.forma === "est_basicos") {
                                    ctx.font = "bold 7px sans-serif";
                                    ctx.fillText("DIRECCIÓN DE", b.x + b.w / 2 - 4, b.y + 10);
                                    ctx.fillText("ESTUDIOS BÁSICOS", b.x + b.w / 2, b.y + 19);
                                } else if (b.forma === "decanato_t") {
                                    // Texto "DECANATO" en la barra horizontal superior de la "T"
                                    ctx.fillStyle = "#fca5a5";
                                    ctx.font = "bold 8px sans-serif";
                                    ctx.fillText("DECANATO", b.x + 50, b.y + 12);

                                    // Texto "CONTROL / DE / ESTUDIOS" dentro del cuadrado azul inferior de la "T"
                                    ctx.fillStyle = rootMapa.colorTextoEdificio;
                                    ctx.font = "bold 6.5px sans-serif";
                                    var cxCtrl = b.x + 49.5;
                                    ctx.fillText("CONTROL", cxCtrl, b.y + 30);
                                    ctx.fillText("DE", cxCtrl, b.y + 40);
                                    ctx.fillText("ESTUDIOS", cxCtrl, b.y + 50);

                                    // Texto vertical "Fotocopias" en el rectángulo derecho
                                    ctx.save();
                                    ctx.translate(b.x + 81, b.y + 39);
                                    ctx.rotate(-Math.PI / 2);
                                    ctx.fillStyle = rootMapa.colorTextoEdificio;
                                    ctx.font = "bold 6px sans-serif";
                                    ctx.fillText("Fotocopias", 0, 0);
                                    ctx.restore();
                                } else if (b.forma === "sio_publ") {
                                    // Textos verticales "SIO", "SOE" y "PUBLICACIONES"
                                    ctx.save();
                                    ctx.translate(b.x + 9, b.y + 36);
                                    ctx.rotate(-Math.PI / 2);
                                    ctx.font = "bold 7px sans-serif";
                                    ctx.fillText("SIO", 0, 0);
                                    ctx.restore();

                                    ctx.save();
                                    ctx.translate(b.x + b.w - 6, b.y + 68);
                                    ctx.rotate(-Math.PI / 2);
                                    ctx.font = "bold 7px sans-serif";
                                    ctx.fillText("SOE", 0, 0);
                                    ctx.restore();

                                    ctx.save();
                                    ctx.translate(b.x + 14, b.y + 126);
                                    ctx.rotate(-Math.PI / 2);
                                    ctx.font = "bold 6.5px sans-serif";
                                    ctx.fillText("PUBLICACIONES", 0, 0);
                                    ctx.restore();
                                } else if (b.forma === "fisica_af") {
                                    ctx.font = "bold 6.5px sans-serif";
                                    ctx.fillText("CUBÍCULOS Y OFIC FÍSICA", b.x + b.w / 2, b.y + 9);
                                    ctx.fillText("LAB. DE FÍSICA", b.x + 40 + (b.w - 40) / 2, b.y + 21);
                                    ctx.save();
                                    ctx.translate(b.x + 11, b.y + 19);
                                    ctx.rotate(-Math.PI / 2);
                                    ctx.font = "bold 5.5px sans-serif";
                                    ctx.fillText("AF1", 0, 0);
                                    ctx.restore();
                                    ctx.save();
                                    ctx.translate(b.x + 31, b.y + 19);
                                    ctx.rotate(-Math.PI / 2);
                                    ctx.font = "bold 5.5px sans-serif";
                                    ctx.fillText("AF2", 0, 0);
                                    ctx.restore();
                                } else if (b.forma === "cei_comp") {
                                    ctx.save();
                                    ctx.translate(b.x + 9, b.y + b.h / 2);
                                    ctx.rotate(-Math.PI / 2);
                                    ctx.font = "bold 6.5px sans-serif";
                                    ctx.fillText("C.E.I.", 0, 0);
                                    ctx.restore();
                                    ctx.font = "bold 6.5px sans-serif";
                                    ctx.fillText("Cubic. Física 2", b.x + 15 + (b.w - 15) / 2, b.y + 9);
                                    ctx.fillText("COMPUTACIÓN", b.x + 15 + (b.w - 15) / 2, b.y + 21);
                                } else if (b.forma === "cafetin") {
                                    ctx.fillStyle = "#f87171";
                                    ctx.font = "bold 8px sans-serif";
                                    ctx.fillText("CAFETÍN", b.x + b.w / 2, b.y + b.h / 2 + 3);
                                } else if (b.forma === "boulevard") {
                                    ctx.save();
                                    ctx.translate(b.x + b.w / 2 + 2, b.y + b.h / 2);
                                    ctx.rotate(-Math.PI / 2);
                                    ctx.fillStyle = "#f87171";
                                    ctx.font = "bold 8px sans-serif";
                                    ctx.fillText("Boulevard", 0, 0);
                                    ctx.restore();
                                } else if (b.forma === "biblio") {
                                    // Cabecera "EDIFICIO" arriba del recuadro rojo
                                    ctx.fillStyle = rootMapa.colorTextoEdificio;
                                    ctx.font = "bold 8px serif";
                                    ctx.fillText("EDIFICIO", b.x + b.w / 2, b.y - 4);

                                    // Textos verticales dentro del recuadro rojo de Biblioteca Central
                                    var colsBiblio = [
                                        [b.x + 10, "EDIFICIO"],
                                        [b.x + 19, "BIBLIOTECA"],
                                        [b.x + 28, "CENTRAL"],
                                        [b.x + 44, "AULAS 101-104"],
                                        [b.x + 57, "AULAS 201-209"],
                                        [b.x + 70, "AULAS 301-310"]
                                    ];
                                    for (var cb = 0; cb < colsBiblio.length; cb++) {
                                        ctx.save();
                                        ctx.translate(colsBiblio[cb][0], b.y + b.h / 2);
                                        ctx.rotate(-Math.PI / 2);
                                        ctx.font = "bold 6px sans-serif";
                                        ctx.fillText(colsBiblio[cb][1], 0, 0);
                                        ctx.restore();
                                    }

                                    // Texto inferior "Coordinación / de Cultura"
                                    ctx.fillStyle = rootMapa.colorTextoEdificio;
                                    ctx.font = "bold 6px sans-serif";
                                    ctx.fillText("Coordinación", b.x + 48, b.y + b.h + 8);
                                    ctx.fillText("de Cultura", b.x + 44, b.y + b.h + 16);
                                } else if (b.forma === "sie5_led") {
                                    ctx.fillStyle = "#f87171";
                                    ctx.font = "bold 6.5px sans-serif";
                                    ctx.fillText("SIE 5", b.x + b.w / 2 + 2, b.y - 2);
                                    ctx.fillStyle = rootMapa.colorTextoEdificio;
                                    ctx.font = "bold 7.5px sans-serif";
                                    ctx.fillText("L E D", b.x + b.w / 2, b.y + 23);
                                } else if (b.forma === "sie1_sie2") {
                                    ctx.save();
                                    ctx.translate(b.x + 9, b.y + 21);
                                    ctx.rotate(-Math.PI / 2);
                                    ctx.font = "bold 7px sans-serif";
                                    ctx.fillText("SIE 1", 0, 0);
                                    ctx.restore();
                                    ctx.save();
                                    ctx.translate(b.x + 8, b.y + b.h - 16);
                                    ctx.rotate(-Math.PI / 2);
                                    ctx.font = "bold 6.5px sans-serif";
                                    ctx.fillText("SIE2", 0, 0);
                                    ctx.restore();
                                } else if (b.forma === "esc_elec") {
                                    ctx.save();
                                    ctx.translate(b.x + 11, b.y + b.h / 2 + 4);
                                    ctx.rotate(-Math.PI / 2);
                                    ctx.font = "bold 6.5px sans-serif";
                                    ctx.fillText("ESCUELA DE", 0, 0);
                                    ctx.restore();
                                    ctx.save();
                                    ctx.translate(b.x + 22, b.y + b.h / 2 + 4);
                                    ctx.rotate(-Math.PI / 2);
                                    ctx.font = "bold 6.5px sans-serif";
                                    ctx.fillText("ELÉCTRICA", 0, 0);
                                    ctx.restore();
                                } else if (b.forma === "maq_procesos") {
                                    ctx.font = "bold 6px sans-serif";
                                    ctx.fillText("LABORATORIO DE", b.x + b.w / 2, b.y + 8);
                                    ctx.fillText("MAQ. ELÉCTRICAS", b.x + b.w / 2, b.y + 17);

                                    ctx.save();
                                    ctx.translate(b.x + 9, b.y + 62);
                                    ctx.rotate(-Math.PI / 2);
                                    ctx.font = "bold 6px sans-serif";
                                    ctx.fillText("ALT", 0, 0);
                                    ctx.restore();

                                    ctx.fillText("Lab.", b.x + 56, b.y + 47);
                                    ctx.fillText("Procesos", b.x + 60, b.y + 58);
                                    ctx.fillStyle = "#f87171";
                                    ctx.font = "bold 6.5px sans-serif";
                                    ctx.fillText("HP2", b.x + 60, b.y + 70);
                                } else if (b.forma === "mantenim") {
                                    ctx.fillStyle = rootMapa.colorBordeEscuela;
                                    ctx.font = "bold 7.5px sans-serif";
                                    ctx.fillText("Mantenimiento", b.x + b.w / 2, b.y + b.h / 2 + 3);
                                } else if (b.forma === "slm_sie3") {
                                    var colsSlm = [[b.x + 38, "SLM"], [b.x + 78, "SIE 3"]];
                                    for (var cs = 0; cs < colsSlm.length; cs++) {
                                        ctx.save();
                                        ctx.translate(colsSlm[cs][0], b.y + b.h / 2);
                                        ctx.rotate(-Math.PI / 2);
                                        ctx.font = "bold 7px sans-serif";
                                        ctx.fillText(colsSlm[cs][1], 0, 3);
                                        ctx.restore();
                                    }
                                } else if (b.forma === "op_unit") {
                                    ctx.font = "bold 6px sans-serif";
                                    ctx.fillText("OPERACIONES", b.x + b.w / 2 - 8, b.y + 10);
                                    ctx.fillText("UNITARIAS", b.x + b.w / 2 - 12, b.y + 20);
                                } else if (b.forma === "matematicas") {
                                    ctx.font = "bold 6px sans-serif";
                                    ctx.fillText("DPTO  DE", b.x + b.w / 2 - 6, b.y + 8);
                                    ctx.fillText("Matemáticas", b.x + b.w / 2 - 4, b.y + 17);
                                } else if (b.forma === "imyca") {
                                    ctx.save();
                                    ctx.translate(b.x + 25, b.y + 44);
                                    ctx.rotate(-Math.PI / 2);
                                    ctx.font = "bold 7px sans-serif";
                                    ctx.fillText("I.M.Y.C.A.", 0, 3);
                                    ctx.restore();
                                } else if (b.forma === "reduc") {
                                    ctx.save();
                                    ctx.translate(b.x + b.w / 2, b.y + b.h / 2);
                                    ctx.rotate(-Math.PI / 2);
                                    ctx.font = "bold 6.5px sans-serif";
                                    ctx.fillText("REDUC", 0, 3);
                                    ctx.restore();
                                } else if (b.forma === "humanidades") {
                                    ctx.font = "bold 6.5px sans-serif";
                                    ctx.fillText("DPTO DE", b.x + b.w / 2 - 2, b.y + 10);
                                    ctx.fillText("HUMANIDADES", b.x + b.w / 2, b.y + 19);
                                    ctx.font = "bold 6.5px sans-serif";
                                    ctx.fillText("HU", b.x + 14, b.y + b.h - 2);
                                } else if (b.forma === "canchas") {
                                    ctx.fillStyle = rootMapa.colorTextoEdificio;
                                    ctx.font = "bold 7.5px serif";
                                    ctx.fillText("Cancha", b.x + b.w / 2, b.y + 24);
                                    ctx.fillText("Básquet", b.x + b.w / 2, b.y + 36);
                                    ctx.fillText("Cancha", b.x + b.w / 2, b.y + b.h / 2 + 24);
                                    ctx.fillText("Fútbol", b.x + b.w / 2, b.y + b.h / 2 + 36);
                                } else if (b.forma === "coord_est") {
                                    var colsCoord = [[b.x + 9, "Coordinación"], [b.x + 18, "Estudiantil"]];
                                    for (var cc = 0; cc < colsCoord.length; cc++) {
                                        ctx.save();
                                        ctx.translate(colsCoord[cc][0], b.y + b.h / 2);
                                        ctx.rotate(-Math.PI / 2);
                                        ctx.font = "bold 5.5px sans-serif";
                                        ctx.fillText(colsCoord[cc][1], 0, 2);
                                        ctx.restore();
                                    }
                                } else if (b.forma === "esc_quim") {
                                    ctx.fillStyle = rootMapa.colorBordeEscuela;
                                    ctx.font = "bold 5.5px sans-serif";
                                    var colsQ = [[b.x + 7, "Escuela"], [b.x + 14, "de"], [b.x + 21, "Química"]];
                                    for (var cq2 = 0; cq2 < colsQ.length; cq2++) {
                                        ctx.save();
                                        ctx.translate(colsQ[cq2][0], b.y + b.h / 2);
                                        ctx.rotate(-Math.PI / 2);
                                        ctx.fillText(colsQ[cq2][1], 0, 2);
                                        ctx.restore();
                                    }
                                } else if (b.forma === "a4m_a3m") {
                                    var wCol = Math.round(b.w / 3);
                                    ctx.beginPath();
                                    ctx.moveTo(b.x + wCol, b.y); ctx.lineTo(b.x + wCol, b.y + b.h);
                                    ctx.moveTo(b.x + wCol * 2, b.y); ctx.lineTo(b.x + wCol * 2, b.y + b.h);
                                    ctx.stroke();
                                    ctx.font = "bold 7px sans-serif";
                                    ctx.fillText("A4M", b.x + wCol * 0.5, b.y + 17);
                                    ctx.fillText("A3M", b.x + wCol * 1.5, b.y + 17);
                                    ctx.fillText("DIREC", b.x + wCol * 2.5, b.y + 13);
                                    ctx.fillText("Académ", b.x + wCol * 2.5, b.y + 22);
                                } else if (b.forma === "lim") {
                                    ctx.save();
                                    ctx.translate(b.x + b.w - 8, b.y + 24);
                                    ctx.rotate(-Math.PI / 2);
                                    ctx.fillStyle = rootMapa.colorTextoEdificio;
                                    ctx.font = "bold 8px sans-serif";
                                    ctx.fillText("LIM", 0, 0);
                                    ctx.restore();
                                } else if (b.forma === "industrial") {
                                    ctx.font = "bold 8px sans-serif";
                                    ctx.fillStyle = "#f87171";
                                    ctx.fillText("SGE", b.x + b.w / 2, b.y + 14);
                                    ctx.save();
                                    ctx.translate(b.x + 10, b.y + 50);
                                    ctx.rotate(-Math.PI / 2);
                                    ctx.fillStyle = rootMapa.colorTextoEdificio;
                                    ctx.font = "bold 7px sans-serif";
                                    ctx.fillText("ESCUELA DE", 0, 0);
                                    ctx.restore();
                                    ctx.save();
                                    ctx.translate(b.x + 21, b.y + 50);
                                    ctx.rotate(-Math.PI / 2);
                                    ctx.fillStyle = rootMapa.colorTextoEdificio;
                                    ctx.font = "bold 7px sans-serif";
                                    ctx.fillText("INDUSTRIAL", 0, 0);
                                    ctx.restore();
                                } else if (b.forma === "chileno") {
                                    ctx.fillStyle = "#fca5a5";
                                    ctx.font = "bold 7px sans-serif";
                                    ctx.fillText("Chileno", b.x + b.w / 2, b.y + 10);
                                } else if (b.forma === "fisicoquim_box") {
                                    // Texto "Fisico / Química" en rojo a la izquierda del bloque rojo (tal cual la imagen)
                                    ctx.fillStyle = "#f87171";
                                    ctx.font = "bold 6.5px sans-serif";
                                    ctx.textAlign = "right";
                                    ctx.fillText("Fisico", b.x - 3, b.y + 7);
                                    ctx.fillText("Química", b.x - 3, b.y + 16);
                                    ctx.textAlign = "center";
                                } else if (b.forma === "complejo_mecanica") {
                                    ctx.fillStyle = rootMapa.colorTextoEdificio;
                                    // 1) "lab / termicas"
                                    ctx.font = "bold 5.5px serif";
                                    ctx.fillText("lab", 92, 404);
                                    ctx.fillText("termicas", 96, 412);

                                    // 2) "C.I.Q" (vertical) y "ASOVAC" (horizontal)
                                    ctx.save();
                                    ctx.translate(142, 401);
                                    ctx.rotate(-Math.PI / 2);
                                    ctx.font = "bold 7px sans-serif";
                                    ctx.fillText("C.I.Q", 0, 2);
                                    ctx.restore();

                                    ctx.font = "bold 7px serif";
                                    ctx.fillText("ASOVAC", 194, 410);

                                    // 3) "Biblioteca / Mecanica"
                                    ctx.font = "bold 6px serif";
                                    ctx.fillText("Biblioteca", 58, 446);
                                    ctx.fillText("Mecanica", 58, 455);

                                    // 4) "ANM" y "Escuela de / MECANICA"
                                    ctx.font = "bold 6.5px serif";
                                    ctx.fillText("ANM", 134, 451);
                                    ctx.fillText("Escuela de", 191, 452);
                                    ctx.fillText("MECANICA", 191, 463);

                                    // 5) "ASM" y "SPM"
                                    ctx.fillText("ASM", 88, 472);
                                    ctx.fillText("SPM", 126, 472);
                                } else if (b.forma === "plaza_iguanas") {
                                    ctx.fillStyle = rootMapa.colorTextoEdificio;
                                    ctx.font = "bold 6.5px serif";
                                    ctx.textAlign = "left";
                                    ctx.fillText("Plaza", b.x + 3, b.y + 18);
                                    ctx.fillText("las", b.x + 3, b.y + 26);
                                    ctx.fillText("iguanas", b.x + 3, b.y + 34);
                                    ctx.textAlign = "center";
                                } else if (b.forma === "fcu_ae1_3") {
                                    var lblsFcu = ["FCU", "AE3", "AE2", "AE1"];
                                    var hFcu = b.h / 4;
                                    ctx.font = "bold 6px serif";
                                    for (var lf = 0; lf < 4; lf++) {
                                        ctx.fillText(lblsFcu[lf], b.x + b.w / 2, b.y + lf * hFcu + 8.5);
                                    }
                                } else if (b.forma === "ae8_ae9") {
                                    var colsAe89 = [[b.x + 14, "AE8"], [b.x + 25, "AE9"]];
                                    for (var c89 = 0; c89 < colsAe89.length; c89++) {
                                        ctx.save();
                                        ctx.translate(colsAe89[c89][0], b.y + b.h / 2);
                                        ctx.rotate(-Math.PI / 2);
                                        ctx.font = "bold 6px serif";
                                        ctx.fillText(colsAe89[c89][1], 0, 2);
                                        ctx.restore();
                                    }
                                } else if (b.forma === "ae4_7") {
                                    var lblsAe47 = ["AE7", "AE6", "AE5", "AE4"];
                                    var wAe47 = b.w / 4;
                                    for (var l47 = 0; l47 < 4; l47++) {
                                        ctx.save();
                                        ctx.translate(b.x + l47 * wAe47 + wAe47 / 2, b.y + b.h / 2);
                                        ctx.rotate(-Math.PI / 2);
                                        ctx.font = "bold 6px serif";
                                        ctx.fillText(lblsAe47[l47], 0, 2);
                                        ctx.restore();
                                    }
                                } else if (b.forma === "auditorio_maneiro") {
                                    ctx.fillStyle = "#4ade80";
                                    ctx.font = "bold 6px sans-serif";
                                    ctx.fillText("Auditorio", b.x + b.w / 2, b.y + 27);
                                    ctx.fillText("Ninoska", b.x + b.w / 2, b.y + 35);
                                    ctx.fillText("Maneiro", b.x + b.w / 2, b.y + 43);
                                } else if (b.forma === "a10_a11") {
                                    ctx.save();
                                    ctx.translate(b.x + b.w / 2, b.y + b.h * 0.25);
                                    ctx.rotate(-Math.PI / 2);
                                    ctx.font = "bold 6.5px serif";
                                    ctx.fillText("A10", 0, 2.5);
                                    ctx.restore();

                                    ctx.save();
                                    ctx.translate(b.x + b.w / 2, b.y + b.h * 0.75);
                                    ctx.rotate(-Math.PI / 2);
                                    ctx.font = "bold 6.5px serif";
                                    ctx.fillText("A11", 0, 2.5);
                                    ctx.restore();
                                } else if (b.forma === "imagenes_box") {
                                    ctx.save();
                                    ctx.translate(b.x + b.w / 2, b.y + b.h / 2);
                                    ctx.rotate(-Math.PI / 2);
                                    ctx.font = "bold 7.5px serif";
                                    ctx.fillText("IMÁGENES", 0, 2.5);
                                    ctx.restore();
                                } else if (b.forma === "facyt_area") {
                                    ctx.fillStyle = rootMapa.colorTextoPlano;
                                    ctx.font = "bold 9px serif";
                                    ctx.fillText("FACULTAD DE CIENCIAS Y", b.x + 104, b.y + 44);
                                    ctx.fillText("TECNOLOGIA", b.x + 104, b.y + 56);
                                    ctx.font = "bold 10.5px serif";
                                    ctx.fillText("Estacionamiento", b.x + 154, b.y + 114);
                                    ctx.fillText("de", b.x + 154, b.y + 126);
                                    ctx.fillText("FACYT", b.x + 154, b.y + 139);
                                } else if (b.forma === "esc_telecom") {
                                    ctx.fillStyle = rootMapa.colorTextoEdificio;
                                    ctx.font = "bold 6.5px serif";
                                    ctx.fillText("Escuela de", b.x + b.w / 2, b.y + 13);
                                    ctx.fillText("Telecom", b.x + b.w / 2, b.y + 23);
                                } else if (b.forma === "salud_area") {
                                    ctx.fillStyle = rootMapa.colorTextoPlano;
                                    ctx.font = "bold 9.5px serif";
                                    ctx.fillText("Facultad de", b.x + b.w / 2, b.y + 16);
                                    ctx.fillText("ciencias", b.x + b.w / 2, b.y + 28);
                                    ctx.fillText("de la salud", b.x + b.w / 2, b.y + 40);
                                    ctx.fillText("MEDICINA", b.x + b.w / 2, b.y + 53);
                                } else if (b.forma === "mangos") {
                                    // Árbol superior izquierdo de Plaza Los Mangos
                                    ctx.beginPath();
                                    ctx.arc(b.x + 14, b.y + 12, 4.5, 0, Math.PI * 2);
                                    ctx.fillStyle = "#78350f";
                                    ctx.fill();
                                    // Caminos diagonales grises y redoma central de Plaza Los Mangos
                                    var cxM = b.x + b.w / 2;
                                    var cyM = b.y + 44;
                                    ctx.strokeStyle = rootMapa.colorTrazo;
                                    ctx.lineWidth = 4.5;
                                    ctx.beginPath();
                                    ctx.moveTo(b.x + 2, cyM + 20); ctx.lineTo(cxM, cyM);
                                    ctx.moveTo(b.x + b.w - 2, cyM - 20); ctx.lineTo(cxM, cyM);
                                    ctx.moveTo(b.x + b.w - 2, cyM + 24); ctx.lineTo(cxM, cyM);
                                    ctx.stroke();
                                    ctx.beginPath();
                                    ctx.arc(cxM, cyM, 16, 0, Math.PI * 2);
                                    ctx.fillStyle = rootMapa.colorTrazo;
                                    ctx.fill();
                                    ctx.strokeStyle = rootMapa.colorTextoEdificio;
                                    ctx.lineWidth = 1.2;
                                    ctx.stroke();
                                    ctx.beginPath();
                                    ctx.arc(cxM, cyM, 7.5, 0, Math.PI * 2);
                                    ctx.fillStyle = "#78350f";
                                    ctx.fill();
                                    ctx.strokeStyle = "#fde68a";
                                    ctx.stroke();
                                    ctx.fillStyle = rootMapa.colorTextoEdificio;
                                    ctx.font = "bold 8px sans-serif";
                                    ctx.fillText("Plaza", cxM, b.y + b.h - 16);
                                    ctx.fillText("Los Mangos", cxM, b.y + b.h - 6);
                                } else {
                                    ctx.font = (b.w < 42) ? "bold 8px sans-serif" : "bold 9px sans-serif";
                                    ctx.fillText(b.cod, b.x + b.w / 2, b.y + b.h / 2 + 3);
                                }

                                // Indicador verde si es una de TUS aulas del horario del semestre actual
                                if (esMiAula) {
                                    ctx.beginPath();
                                    ctx.arc(b.x + b.w - 5, b.y + 5, 3.5, 0, Math.PI * 2);
                                    ctx.fillStyle = "#4ade80";
                                    ctx.fill();
                                }

                                ctx.restore();
                            }
                        }
                    }

                    // 4. ANILLO DE RADAR PULSANTE ACELERADO POR GPU (Cero lag)
                    Rectangle {
                        id: anilloRadarGpu
                        readonly property real baseSize: Math.max(rootMapa.bloqueSeleccionadoObj.w, rootMapa.bloqueSeleccionadoObj.h) * 1.45
                        width: baseSize
                        height: baseSize
                        radius: baseSize / 2
                        x: rootMapa.bloqueSeleccionadoObj.x + (rootMapa.bloqueSeleccionadoObj.w - width) / 2
                        y: rootMapa.bloqueSeleccionadoObj.y + (rootMapa.bloqueSeleccionadoObj.h - height) / 2
                        color: "transparent"
                        border.color: temaApp.bordeAlt
                        border.width: 2.5

                        SequentialAnimation on scale {
                            running: rootMapa.visible
                            loops: Animation.Infinite
                            NumberAnimation { from: 0.85; to: 1.55; duration: 1400; easing.type: Easing.OutQuad }
                        }
                        SequentialAnimation on opacity {
                            running: rootMapa.visible
                            loops: Animation.Infinite
                            NumberAnimation { from: 0.95; to: 0.0; duration: 1400; easing.type: Easing.OutQuad }
                        }
                    }

                    // Zonas táctiles sobre cada edificio
                    Repeater {
                        model: rootMapa.bloquesFacultad

                        delegate: Item {
                            x: modelData.x
                            y: modelData.y
                            width: modelData.w
                            height: modelData.h

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    rootMapa.idSeleccionado = index;
                                    canvasPlano.requestPaint();
                                }
                            }
                        }
                    }
                }
            }

            // Leyenda flotante en la esquina superior izquierda del mapa
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 10
                width: Math.min(parent.width - 20, rowLeyenda.implicitWidth + 18)
                height: 26; radius: 13
                color: temaApp.esClaro ? "#cc2b2416" : "#cc070d19"
                border.color: "#35ffffff"
                border.width: 1
                clip: true

                RowLayout {
                    id: rowLeyenda
                    anchors.centerIn: parent
                    spacing: 10

                    Row {
                        spacing: 4
                        Rectangle { width: 8; height: 8; radius: 4; color: rootMapa.colorVerdeBorde; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "Tus Aulas"; color: "white"; font.pixelSize: 9; font.bold: true }
                    }
                    Row {
                        spacing: 4
                        Rectangle { width: 8; height: 8; radius: 2; color: "#ef4444"; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "Aulas A/E"; color: "#e2e8f0"; font.pixelSize: 9 }
                    }
                    Row {
                        spacing: 4
                        Rectangle { width: 8; height: 8; radius: 2; color: "#ca8a04"; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "AD1-AD9"; color: "#e2e8f0"; font.pixelSize: 9 }
                    }
                    Row {
                        spacing: 4
                        Rectangle { width: 8; height: 8; radius: 2; color: rootMapa.colorVerde; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "Jardines"; color: "#e2e8f0"; font.pixelSize: 9 }
                    }
                }
            }
        }

        // 5. TARJETA INFERIOR DE DETALLE DEL SALÓN / EDIFICIO SELECCIONADO
        Rectangle {
            id: cardDetalleMapa
            Layout.fillWidth: true
            Layout.maximumWidth: rootMapa.width - 32
            Layout.minimumWidth: 0
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.bottomMargin: 118
            Layout.preferredHeight: 96
            radius: 22
            color: temaApp.panelEdit
            border.color: temaApp.acento
            border.width: 1
            clip: true

            property var bloqueActual: rootMapa.bloqueSeleccionadoObj

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 64
                    Layout.fillWidth: false
                    radius: 16
                    color: temaApp.superficie
                    border.color: temaApp.bordeAlt
                    border.width: 1.5

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 0
                        Text {
                            text: cardDetalleMapa.bloqueActual.cod.split(" ")[0]
                            color: "white"
                            font.pixelSize: 13
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            visible: rootMapa.esMiAulaHorario(cardDetalleMapa.bloqueActual)
                            text: "★ MI AULA"
                            color: rootMapa.colorVerdeBorde
                            font.pixelSize: 7
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    Layout.minimumWidth: 0
                    spacing: 3

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: cardDetalleMapa.bloqueActual.cod + " • " + cardDetalleMapa.bloqueActual.sub
                            color: temaApp.textoPrincipal
                            font.pixelSize: 13
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        text: "📍 " + cardDetalleMapa.bloqueActual.desc
                        color: temaApp.acentoVisible
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: cardDetalleMapa.bloqueActual.infoExtra
                        color: temaApp.textoSecundario
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}
