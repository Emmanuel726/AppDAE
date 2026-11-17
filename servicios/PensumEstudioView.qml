import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts

Item {
    id: rootPensum

    signal volver()

    // 0 = Pensum Actual (1997), 1 = Pensum Nuevo (2025), 2 = Preguntas Frecuentes
    property int modoVista: 0

    // Escuelas oficiales de la Facultad de Ingeniería UC
    property var listaEscuelas: [
        "INGENIERÍA DE TELECOMUNICACIONES",
        "INGENIERÍA INDUSTRIAL",
        "INGENIERÍA ELÉCTRICA",
        "INGENIERÍA MECÁNICA",
        "INGENIERÍA QUÍMICA",
        "INGENIERÍA CIVIL"
    ]
    property int escuelaIdx: daeClient.escuelaIndexEstudiante
    property bool selectorEscuelaAbierto: false

    onVisibleChanged: {
        if (visible) {
            rootPensum.selectorEscuelaAbierto = false
            rootPensum.escuelaIdx = daeClient.escuelaIndexEstudiante
            daeClient.cargarPensum(rootPensum.modoVista, rootPensum.escuelaIdx)
        }
    }

    Connections {
        target: daeClient
        function onDatosEstudianteChanged() {
            rootPensum.escuelaIdx = daeClient.escuelaIndexEstudiante
            daeClient.cargarPensum(rootPensum.modoVista, rootPensum.escuelaIdx)
        }
    }

    // Filtros
    property int semestreFiltro: 0 // 0 = Todos, 1..10 = Semestre específico
    property string textoBusqueda: ""

    // Modal de detalle al pulsar el botón (...)
    property bool modalDetalleVisible: false
    property var materiaDetalle: null

    // Nombres e información de extinción de semestres (Pensum 1997)
    property var infoSemestres1997: [
        { sem: 1, titulo: "PRIMER SEMESTRE",   aviso: "SE DEJARÁ DE OFERTAR EN EL PERIODO 1-2026" },
        { sem: 2, titulo: "SEGUNDO SEMESTRE",  aviso: "SE DEJARÁ DE OFERTAR EN EL PERIODO 2-2026" },
        { sem: 3, titulo: "TERCER SEMESTRE",   aviso: "SE DEJARÁ DE OFERTAR EN EL PERIODO 1-2027" },
        { sem: 4, titulo: "CUARTO SEMESTRE",   aviso: "SE DEJARÁ DE OFERTAR EN EL PERIODO 2-2027" },
        { sem: 5, titulo: "QUINTO SEMESTRE",   aviso: "SE DEJARÁ DE OFERTAR EN EL PERIODO 1-2028" },
        { sem: 6, titulo: "SEXTO SEMESTRE",    aviso: "SE DEJARÁ DE OFERTAR EN EL PERIODO 2-2028" },
        { sem: 7, titulo: "SÉPTIMO SEMESTRE",  aviso: "SE DEJARÁ DE OFERTAR EN EL PERIODO 1-2029" },
        { sem: 8, titulo: "OCTAVO SEMESTRE",   aviso: "SE DEJARÁ DE OFERTAR EN EL PERIODO 2-2029" },
        { sem: 9, titulo: "NOVENO SEMESTRE",   aviso: "SE DEJARÁ DE OFERTAR EN EL PERIODO 1-2030" },
        { sem: 10, titulo: "DÉCIMO SEMESTRE",  aviso: "SE DEJARÁ DE OFERTAR EN EL PERIODO 2-2030" }
    ]

    property var infoSemestres2025: [
        { sem: 1, titulo: "PRIMER SEMESTRE",   aviso: "OFERTADO A PARTIR DEL PERIODO 1-2026" },
        { sem: 2, titulo: "SEGUNDO SEMESTRE",  aviso: "OFERTADO A PARTIR DEL PERIODO 2-2026" },
        { sem: 3, titulo: "TERCER SEMESTRE",   aviso: "OFERTADO A PARTIR DEL PERIODO 1-2027" },
        { sem: 4, titulo: "CUARTO SEMESTRE",   aviso: "OFERTADO A PARTIR DEL PERIODO 2-2027" },
        { sem: 5, titulo: "QUINTO SEMESTRE",   aviso: "OFERTADO A PARTIR DEL PERIODO 1-2028" },
        { sem: 6, titulo: "SEXTO SEMESTRE",    aviso: "OFERTADO A PARTIR DEL PERIODO 2-2028" },
        { sem: 7, titulo: "SÉPTIMO SEMESTRE",  aviso: "OFERTADO A PARTIR DEL PERIODO 1-2029" },
        { sem: 8, titulo: "OCTAVO SEMESTRE",   aviso: "OFERTADO A PARTIR DEL PERIODO 2-2029" }
    ]

    // Catálogo del Pensum Actual (1997) con datos exactos de DAE (Código, Asignatura, U.C., T, P, L, Requisitos)
    property var pensum1997Telecom: [
        // 1ER SEMESTRE
        { sem: 1, codigo: "DE1B01", nombre: "DEPORTE", uc: 0, t: 0, p: 2, l: 0, req: "NINGUNO" },
        { sem: 1, codigo: "DH1B01", nombre: "PROC. BASICOS DEL PENSAMIENTO", uc: 2, t: 0, p: 4, l: 0, req: "NINGUNO" },
        { sem: 1, codigo: "HU1B01", nombre: "INTROD. A LAS CIENCIAS HUMANAS", uc: 3, t: 3, p: 0, l: 0, req: "NINGUNO" },
        { sem: 1, codigo: "MA1B01", nombre: "ANALISIS MATEMATICO I", uc: 5, t: 4, p: 2, l: 0, req: "NINGUNO" },
        { sem: 1, codigo: "MA1B02", nombre: "GEOMETRIA ANALITICA", uc: 5, t: 4, p: 2, l: 0, req: "NINGUNO" },
        { sem: 1, codigo: "QM1B01", nombre: "QUIMICA GENERAL I", uc: 3, t: 3, p: 1, l: 0, req: "NINGUNO" },

        // 2DO SEMESTRE
        { sem: 2, codigo: "DH2B02", nombre: "RAZ. VERBAL Y SOL DE PROBLEMAS", uc: 1, t: 0, p: 3, l: 0, req: "DH1B01" },
        { sem: 2, codigo: "DI2B01", nombre: "DIBUJO I", uc: 2, t: 1, p: 3, l: 0, req: "MA1B02" },
        { sem: 2, codigo: "FI2B01", nombre: "FISICA I", uc: 4, t: 3, p: 2, l: 0, req: "MA1B01+MA1B02" },
        { sem: 2, codigo: "ID2B01", nombre: "INGLES I", uc: 3, t: 2, p: 2, l: 0, req: "12 U.C." },
        { sem: 2, codigo: "MA2B03", nombre: "ANALISIS MATEMATICO II", uc: 4, t: 3, p: 2, l: 0, req: "MA1B01+MA1B02" },
        { sem: 2, codigo: "MA2B04", nombre: "ALGEBRA LINEAL", uc: 3, t: 3, p: 1, l: 0, req: "MA1B01+MA1B02" },

        // 3ER SEMESTRE
        { sem: 3, codigo: "CA3B01", nombre: "COMPUTACION I", uc: 3, t: 2, p: 0, l: 2, req: "MA2B03+MA2B04" },
        { sem: 3, codigo: "FI3B02", nombre: "FISICA II", uc: 3, t: 2, p: 2, l: 0, req: "FI2B01+MA2B03" },
        { sem: 3, codigo: "FI3B03", nombre: "LABORATORIO I DE FISICA", uc: 2, t: 1, p: 0, l: 2, req: "FI2B01" },
        { sem: 3, codigo: "HU3B02", nombre: "CULTURA", uc: 0, t: 2, p: 0, l: 0, req: "20 U.C." },
        { sem: 3, codigo: "MA3B05", nombre: "FUNCIONES VECTORIALES", uc: 3, t: 3, p: 1, l: 0, req: "MA2B03+MA2B04" },
        { sem: 3, codigo: "MA3B06", nombre: "ECUACIONES DIFERENCIALES", uc: 3, t: 3, p: 1, l: 0, req: "MA2B03+MA2B04" },

        // 4TO SEMESTRE
        { sem: 4, codigo: "CA4B02", nombre: "COMPUTACION II", uc: 3, t: 2, p: 0, l: 2, req: "CA3B01" },
        { sem: 4, codigo: "CM4T01", nombre: "CIRCUITOS ELECTRICOS I", uc: 4, t: 4, p: 1, l: 0, req: "FI3B02+FI3B03+MA3B06" },
        { sem: 4, codigo: "FI4B06", nombre: "FISICA MODERNA Y ONDAS", uc: 3, t: 2, p: 2, l: 0, req: "FI3B02" },
        { sem: 4, codigo: "HU4B03", nombre: "METODOLOGIA DE INVESTIGACION", uc: 0, t: 2, p: 0, l: 0, req: "40 U.C." },
        { sem: 4, codigo: "ID4B02", nombre: "INGLES II", uc: 2, t: 2, p: 0, l: 0, req: "ID2B01" },
        { sem: 4, codigo: "MA4B07", nombre: "MATEMATICAS APLICADAS", uc: 3, t: 2, p: 2, l: 0, req: "MA3B05+MA3B06" },

        // 5TO SEMESTRE
        { sem: 5, codigo: "CM5T02", nombre: "CIRCUITOS ELECTRICOS II", uc: 4, t: 4, p: 1, l: 0, req: "CM4T01+MA4B07" },
        { sem: 5, codigo: "CM5T03", nombre: "MEDICIONES ELECTRICAS", uc: 5, t: 3, p: 0, l: 4, req: "CM4T01+MA4B07" },
        { sem: 5, codigo: "EC5T01", nombre: "ELECTRONICA I", uc: 3, t: 3, p: 1, l: 0, req: "CM4T01" },
        { sem: 5, codigo: "ER5T01", nombre: "TEORIA ELECTROMAGNETICA I", uc: 4, t: 3, p: 2, l: 0, req: "FI4B06+MA4B07" },
        { sem: 5, codigo: "HU5B06", nombre: "INTROD. AL SERVICIO COMUNITARIO", uc: 0, t: 2, p: 0, l: 0, req: "HU4B03" },
        { sem: 5, codigo: "SS5T01", nombre: "ANALISIS DE SEÑALES Y SIST. LINEALES", uc: 4, t: 3, p: 2, l: 0, req: "CM4T01+MA4B07" },

        // 6TO SEMESTRE
        { sem: 6, codigo: "CO6B01", nombre: "PROYECTO SERVICIO COMUNITARIO", uc: 0, t: 0, p: 4, l: 0, req: "HU5B06" },
        { sem: 6, codigo: "EC6T03", nombre: "ELECTRONICA II", uc: 5, t: 3, p: 1, l: 3, req: "CM5T02+CM5T03+EC5T01" },
        { sem: 6, codigo: "ER6T02", nombre: "TEORIA ELECTROMAGNETICA II", uc: 4, t: 3, p: 2, l: 0, req: "ER5T01" },
        { sem: 6, codigo: "IN6T01", nombre: "PROBABILIDADES Y PROC. ESTOCASTICOS", uc: 4, t: 3, p: 2, l: 0, req: "SS5T01" },
        { sem: 6, codigo: "SA6T01", nombre: "LOGICA DIGITAL", uc: 4, t: 3, p: 0, l: 3, req: "EC5T01" },

        // 7MO SEMESTRE
        { sem: 7, codigo: "EC7T04", nombre: "ELECTRONICA III", uc: 4, t: 3, p: 0, l: 3, req: "EC6T03" },
        { sem: 7, codigo: "ER7T03", nombre: "SISTEMAS DE ONDAS GUIADAS", uc: 5, t: 3, p: 1, l: 3, req: "ER6T02" },
        { sem: 7, codigo: "SS7T02", nombre: "PROCESAMIENTO DIGITAL DE SEÑALES", uc: 4, t: 3, p: 0, l: 3, req: "CA4B02+SS5T01" },
        { sem: 7, codigo: "SS7T03", nombre: "INSTRUMENTACION ELECTRONICA", uc: 4, t: 3, p: 0, l: 3, req: "EC6T03+SA6T01" },
        { sem: 7, codigo: "SS7T04", nombre: "SISTEMAS DE ENERGIA PARA TELECOMUNICACIONES", uc: 3, t: 2, p: 2, l: 0, req: "EC6T03" },

        // 8VO SEMESTRE
        { sem: 8, codigo: "ER8T04", nombre: "ANTENAS Y PROPAGACION", uc: 5, t: 3, p: 1, l: 3, req: "ER7T03+SS7T03" },
        { sem: 8, codigo: "GE8T01", nombre: "INGENIERIA ECONOMICA", uc: 3, t: 2, p: 2, l: 0, req: "100 U.C." },
        { sem: 8, codigo: "SA8T04", nombre: "MICROPROCESADORES", uc: 4, t: 3, p: 0, l: 3, req: "SA6T01" },
        { sem: 8, codigo: "SA8T06", nombre: "ARQUITECTURA DE COMPUTADORES", uc: 3, t: 2, p: 2, l: 0, req: "SA6T01+SS7T02" },
        { sem: 8, codigo: "SS8T06", nombre: "TEORIA DE LAS COMUNICACIONES I", uc: 5, t: 3, p: 1, l: 3, req: "IN6T01+SS7T03" },
        { sem: 8, codigo: "SS8T07", nombre: "GERENCIA DE SISTEMAS DE TELECOMUNICACIONES", uc: 3, t: 2, p: 2, l: 0, req: "100 U.C." },

        // 9NO SEMESTRE
        { sem: 9, codigo: "CA9T03", nombre: "ALGORITMOS Y PROGRAMACION AVANZADA", uc: 3, t: 2, p: 0, l: 2, req: "SS8T06" },
        { sem: 9, codigo: "ER9T05", nombre: "MICROONDAS", uc: 4, t: 3, p: 0, l: 3, req: "ER7T03+SS8T06" },
        { sem: 9, codigo: "ER9T06", nombre: "INGENIERIA DE LAS COMUNICACIONES I", uc: 4, t: 3, p: 2, l: 0, req: "ER7T03+SS8T06" },
        { sem: 9, codigo: "ER9T07", nombre: "INSTRUMENTACION DE LAS COMUNICACIONES", uc: 3, t: 2, p: 0, l: 3, req: "SS7T03+SS8T06" },
        { sem: 9, codigo: "SA9T05", nombre: "DISEÑO DIGITAL", uc: 4, t: 3, p: 0, l: 3, req: "SA8T04" },
        { sem: 9, codigo: "SS9T08", nombre: "TEORIA DE LAS COMUNICACIONES II", uc: 5, t: 3, p: 1, l: 3, req: "ER7T03+SS8T06" },
        { sem: 9, codigo: "SS9T09", nombre: "DISEÑO DE CIRCUITOS DE COMUNICACIONES", uc: 4, t: 3, p: 0, l: 3, req: "ER7T03+SS7T03+SS8T06" },

        // 10MO SEMESTRE
        { sem: 10, codigo: "HU0B02", nombre: "SEMINARIO DE LEGISLACION Y DEONTOLOGIA", uc: 2, t: 2, p: 0, l: 0, req: "130 U.C." },
        { sem: 10, codigo: "PG0T01", nombre: "TRABAJO ESPECIAL DE GRADO", uc: 6, t: 0, p: 6, l: 0, req: "130 U.C." },
        { sem: 10, codigo: "ER0T08", nombre: "COMUNICACIONES OPTICAS (ELECTIVA)", uc: 3, t: 3, p: 0, l: 0, req: "ER7T03+SS9T08" },
        { sem: 10, codigo: "SS0T10", nombre: "TRANSMISION DE DATOS (ELECTIVA)", uc: 3, t: 3, p: 0, l: 0, req: "IN6T01+SS9T08" },
        { sem: 10, codigo: "SS0T11", nombre: "COMUNICACIONES INALAMBRICAS (ELECTIVA)", uc: 3, t: 3, p: 0, l: 0, req: "SS9T08" },
        { sem: 10, codigo: "SS0T12", nombre: "REDES DE TELECOMUNICACIONES (ELECTIVA)", uc: 3, t: 3, p: 0, l: 0, req: "ER7T03+SS9T08" },
        { sem: 10, codigo: "SS0T16", nombre: "COMUNICACIONES POR SATELITE (ELECTIVA)", uc: 3, t: 3, p: 0, l: 0, req: "ER8T04+ER9T05+SS9T08" }
    ]

    // Catálogo del Pensum Nuevo (2025) - Formación Básica y Profesional
    property var pensum2025General: [
        // 1ER SEMESTRE (2025)
        { sem: 1, codigo: "FBTIE01", nombre: "INTRODUCCIÓN A LA INGENIERÍA", uc: 2, t: 2, p: 0, l: 0, req: "NINGUNO" },
        { sem: 1, codigo: "FBTIN02", nombre: "INGLÉS I", uc: 2, t: 1, p: 2, l: 0, req: "NINGUNO" },
        { sem: 1, codigo: "FBTMA01", nombre: "MATEMÁTICAS I", uc: 5, t: 4, p: 2, l: 0, req: "NINGUNO" },
        { sem: 1, codigo: "FBTQU02", nombre: "QUÍMICA GENERAL", uc: 4, t: 3, p: 2, l: 0, req: "NINGUNO" },
        { sem: 1, codigo: "FBTCS01", nombre: "COMUNICACIÓN Y LENGUAJE", uc: 2, t: 1, p: 2, l: 0, req: "NINGUNO" },
        { sem: 1, codigo: "FBTDE01", nombre: "ACTIVIDAD DEPORTIVA Y RECREATIVA", uc: 0, t: 0, p: 2, l: 0, req: "NINGUNO" },

        // 2DO SEMESTRE (2025)
        { sem: 2, codigo: "FBTCS03", nombre: "CIENCIA Y SOCIEDAD", uc: 2, t: 2, p: 0, l: 0, req: "FBTCS01" },
        { sem: 2, codigo: "FBTEC04", nombre: "ECOLOGÍA Y CONTAMINACIÓN AMBIENTAL", uc: 2, t: 2, p: 0, l: 0, req: "FBTQU02" },
        { sem: 2, codigo: "FBTFI03", nombre: "FÍSICA I", uc: 4, t: 3, p: 2, l: 0, req: "FBTMA01" },
        { sem: 2, codigo: "FBTMA03", nombre: "MATEMÁTICAS II", uc: 4, t: 3, p: 2, l: 0, req: "FBTMA01" },
        { sem: 2, codigo: "FBTMA04", nombre: "ÁLGEBRA LINEAL", uc: 3, t: 2, p: 2, l: 0, req: "FBTMA01" },
        { sem: 2, codigo: "FP1LP23", nombre: "LÓGICA Y PROGRAMACIÓN", uc: 3, t: 2, p: 0, l: 2, req: "FBTMA01" },

        // 3ER SEMESTRE (2025)
        { sem: 3, codigo: "FBTFI05", nombre: "FÍSICA II Y LABORATORIO", uc: 4, t: 3, p: 1, l: 2, req: "FBTFI03+FBTMA03" },
        { sem: 3, codigo: "FBTMA05", nombre: "CÁLCULO VECTORIAL Y ECUACIONES DIFERENCIALES", uc: 5, t: 4, p: 2, l: 0, req: "FBTMA03+FBTMA04" },
        { sem: 3, codigo: "FBTDG01", nombre: "DISEÑO GRÁFICO EN INGENIERÍA", uc: 2, t: 1, p: 3, l: 0, req: "FBTMA04" },
        { sem: 3, codigo: "FP1PA02", nombre: "PROGRAMACIÓN APLICADA", uc: 3, t: 2, p: 0, l: 2, req: "FP1LP23" },
        { sem: 3, codigo: "FBTIN04", nombre: "INGLÉS II", uc: 2, t: 1, p: 2, l: 0, req: "FBTIN02" },

        // 4TO SEMESTRE (2025)
        { sem: 4, codigo: "FP1SC04", nombre: "INDUCCIÓN AL SERVICIO COMUNITARIO", uc: 0, t: 2, p: 0, l: 0, req: "36 U.C." },
        { sem: 4, codigo: "FP2CE01", nombre: "ANÁLISIS DE CIRCUITOS ELÉCTRICOS I", uc: 4, t: 3, p: 2, l: 0, req: "FBTFI05+FBTMA05" },
        { sem: 4, codigo: "FP2FO01", nombre: "FÍSICA MODERNA Y ÓPTICA", uc: 3, t: 2, p: 2, l: 0, req: "FBTFI05" },
        { sem: 4, codigo: "FP2MA06", nombre: "MATEMÁTICAS AVANZADAS PARA INGENIERÍA", uc: 4, t: 3, p: 2, l: 0, req: "FBTMA05" },
        { sem: 4, codigo: "FP2PE01", nombre: "PROBABILIDAD Y ESTADÍSTICA EN INGENIERÍA", uc: 3, t: 2, p: 2, l: 0, req: "FBTMA03" },

        // 5TO SEMESTRE (2025)
        { sem: 5, codigo: "FP1SC05", nombre: "PROYECTO SERVICIO COMUNITARIO", uc: 0, t: 0, p: 4, l: 0, req: "FP1SC04" },
        { sem: 5, codigo: "FP3CE02", nombre: "CIRCUITOS Y MEDICIONES ELÉCTRICAS", uc: 5, t: 3, p: 1, l: 3, req: "FP2CE01" },
        { sem: 5, codigo: "FP3EL01", nombre: "DISPOSITIVOS Y CIRCUITOS ELECTRÓNICOS", uc: 4, t: 3, p: 0, l: 3, req: "FP2CE01" },
        { sem: 5, codigo: "FP3EM01", nombre: "CAMPOS Y ONDAS ELECTROMAGNÉTICAS", uc: 4, t: 3, p: 2, l: 0, req: "FP2FO01+FP2MA06" },
        { sem: 5, codigo: "FP3SS01", nombre: "SEÑALES Y SISTEMAS", uc: 4, t: 3, p: 2, l: 0, req: "FP2CE01+FP2MA06" },

        // 6TO SEMESTRE (2025)
        { sem: 6, codigo: "FP4SD01", nombre: "SISTEMAS DIGITALES Y MICROCONTROLADORES", uc: 4, t: 3, p: 0, l: 3, req: "FP3EL01+FP1PA02" },
        { sem: 6, codigo: "FP4EL02", nombre: "ELECTRÓNICA ANALÓGICA Y DE POTENCIA", uc: 4, t: 3, p: 0, l: 3, req: "FP3EL01" },
        { sem: 6, codigo: "FP4OG01", nombre: "MEDIOS DE TRANSMISIÓN Y ONDAS GUIADAS", uc: 4, t: 3, p: 0, l: 3, req: "FP3EM01" },
        { sem: 6, codigo: "FP4PD01", nombre: "PROCESAMIENTO DIGITAL DE SEÑALES", uc: 4, t: 3, p: 0, l: 3, req: "FP3SS01" },

        // 7MO SEMESTRE (2025)
        { sem: 7, codigo: "FP5CM01", nombre: "SISTEMAS DE COMUNICACIONES ANALÓGICAS Y DIGITALES", uc: 5, t: 3, p: 1, l: 3, req: "FP4PD01+FP2PE01" },
        { sem: 7, codigo: "FP5AN01", nombre: "ANTENAS, RADIOPROPAGACIÓN Y MICROONDAS", uc: 5, t: 3, p: 1, l: 3, req: "FP4OG01" },
        { sem: 7, codigo: "FP5RD01", nombre: "REDES DE TELECOMUNICACIONES Y PROTOCOLOS", uc: 4, t: 3, p: 0, l: 3, req: "FP4SD01" },
        { sem: 7, codigo: "FP5GE01", nombre: "GESTIÓN DE PROYECTOS E INGENIERÍA ECONÓMICA", uc: 3, t: 2, p: 2, l: 0, req: "90 U.C." },

        // 8VO SEMESTRE (2025)
        { sem: 8, codigo: "FP6CO01", nombre: "COMUNICACIONES ÓPTICAS E INALÁMBRICAS", uc: 4, t: 3, p: 0, l: 3, req: "FP5CM01+FP5AN01" },
        { sem: 8, codigo: "FP6CI01", nombre: "CIBERSEGURIDAD E INFRAESTRUCTURA EN LA NUBE", uc: 3, t: 2, p: 0, l: 2, req: "FP5RD01" },
        { sem: 8, codigo: "FP6ET01", nombre: "ÉTICA, LEGISLACIÓN Y DEONTOLOGÍA PROFESIONAL", uc: 2, t: 2, p: 0, l: 0, req: "110 U.C." },
        { sem: 8, codigo: "FP6TG01", nombre: "TRABAJO DE GRADO / PASANTÍA PROFESIONAL", uc: 6, t: 0, p: 6, l: 0, req: "115 U.C." }
    ]

    // Preguntas frecuentes sobre el Pensum 1997 y Pensum 2025
    property var preguntasFrecuentes: [
        {
            pregunta: "¿Qué significa el aviso 'Se dejará de ofertar en el período...'?",
            respuesta: "Indica el último período lectivo regular en el que las asignaturas de ese semestre del Pensum 1997 serán abiertas de forma ordinaria, debido a la implantación progresiva del Pensum Nuevo (2025) aprobada en Consejo Universitario."
        },
        {
            pregunta: "¿A quiénes aplica el Pensum Nuevo (2025)?",
            respuesta: "Aplica a todos los estudiantes de nuevo ingreso a partir del período 1-2026 y a aquellos estudiantes del Pensum 1997 que sean alcanzados por el cronograma de desincorporación semestral o soliciten su transición por equivalencia."
        },
        {
            pregunta: "¿Qué significan las columnas U.C., T, P y L en la tabla?",
            respuesta: "• U.C.: Unidades de Crédito que otorga la asignatura al aprobarla.\n• T: Horas de clase Teórica por semana.\n• P: Horas de clase Práctica por semana.\n• L: Horas de Laboratorio por semana."
        },
        {
            pregunta: "¿Cómo se leen los Requisitos de Prelación?",
            respuesta: "Cuando aparecen códigos separados por '+' (ej. MA1B01+MA1B02), significa que debes haber aprobado todas esas asignaturas previamente. Cuando indica un número de U.C. (ej. 12 U.C., 40 U.C., 100 U.C.), debes acumular al menos esa cantidad de créditos aprobados."
        },
        {
            pregunta: "¿El Ciclo Básico es común para las 6 Escuelas?",
            respuesta: "Sí. Los primeros semestres de formación básica (Matemáticas, Física, Química, Dibujo, Computación y Humanidades) son comunes para Industrial, Eléctrica, Mecánica, Química, Civil y Telecomunicaciones."
        }
    ]

    function obtenerCatalogoActual() {
        var base = (modoVista === 1) ? pensum2025General : pensum1997Telecom;
        return base;
    }

    Component.onCompleted: {
        daeClient.cargarPensum(rootPensum.modoVista, rootPensum.escuelaIdx)
        daeClient.cargarFaqPensum()
    }

    onModoVistaChanged: {
        daeClient.cargarPensum(rootPensum.modoVista, rootPensum.escuelaIdx)
    }

    onEscuelaIdxChanged: {
        daeClient.cargarPensum(rootPensum.modoVista, rootPensum.escuelaIdx)
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

    function obtenerSemestresVisibles() {
        var busq = normalizarTextoBusqueda(textoBusqueda);
        var resultado = [];

        // Si ya tenemos el pensum descargado en vivo desde dae.ing.uc.edu.ve/pensa/
        if (daeClient.semestresPensum && daeClient.semestresPensum.length > 0) {
            for (var k = 0; k < daeClient.semestresPensum.length; k++) {
                var semVivo = daeClient.semestresPensum[k];
                if (semestreFiltro !== 0 && semVivo.sem !== semestreFiltro) continue;

                var matsVivo = [];
                var ucSumVivo = 0;
                var listaM = semVivo.materias || [];
                for (var m = 0; m < listaM.length; m++) {
                    var itemM = listaM[m];
                    if (busq !== "") {
                        if (!coincideBusqueda((itemM.codigo || "") + " " + (itemM.nombre || "") + " " + (itemM.req || ""), busq)) continue;
                    }
                    matsVivo.push(itemM);
                    ucSumVivo += itemM.uc;
                }
                if (matsVivo.length > 0) {
                    resultado.push({
                        sem: semVivo.sem,
                        titulo: semVivo.titulo,
                        aviso: semVivo.aviso,
                        totalUc: Math.round(ucSumVivo * 10) / 10,
                        materias: matsVivo
                    });
                }
            }
            return resultado;
        }

        var listaSem = (modoVista === 1) ? infoSemestres2025 : infoSemestres1997;
        var catalogo = obtenerCatalogoActual();

        for (var i = 0; i < listaSem.length; i++) {
            var sInfo = listaSem[i];
            if (semestreFiltro !== 0 && sInfo.sem !== semestreFiltro) continue;

            var materiasDelSemestre = [];
            var totalUcSem = 0;
            for (var j = 0; j < catalogo.length; j++) {
                var mat = catalogo[j];
                if (mat.sem !== sInfo.sem) continue;

                if (busq !== "") {
                    if (!coincideBusqueda((mat.codigo || "") + " " + (mat.nombre || "") + " " + (mat.req || ""), busq)) continue;
                }
                materiasDelSemestre.push(mat);
                totalUcSem += mat.uc;
            }

            if (materiasDelSemestre.length > 0) {
                resultado.push({
                    sem: sInfo.sem,
                    titulo: sInfo.titulo,
                    aviso: sInfo.aviso,
                    totalUc: Math.round(totalUcSem * 10) / 10,
                    materias: materiasDelSemestre
                });
            }
        }
        return resultado;
    }

    function obtenerListaPlanaActiva() {
        if (daeClient.semestresPensum && daeClient.semestresPensum.length > 0) {
            var plana = [];
            for (var k = 0; k < daeClient.semestresPensum.length; k++) {
                var mats = daeClient.semestresPensum[k].materias || [];
                for (var m = 0; m < mats.length; m++) {
                    plana.push(mats[m]);
                }
            }
            if (plana.length > 0) return plana;
        }
        return obtenerCatalogoActual();
    }

    function buscarNombreMateria(codigoBuscado) {
        var codLimpio = codigoBuscado.trim();
        var catalogo = obtenerListaPlanaActiva();
        for (var i = 0; i < catalogo.length; i++) {
            if (catalogo[i].codigo === codLimpio) {
                return catalogo[i].nombre;
            }
        }
        return "Requisito de Unidades de Crédito";
    }

    function obtenerMateriasQueAbre(codigoActual) {
        if (!codigoActual) return [];
        var catalogo = obtenerListaPlanaActiva();
        var lista = [];
        for (var i = 0; i < catalogo.length; i++) {
            var reqs = catalogo[i].req.split("+");
            for (var r = 0; r < reqs.length; r++) {
                if (reqs[r].trim() === codigoActual) {
                    lista.push(catalogo[i].codigo + " • " + catalogo[i].nombre);
                    break;
                }
            }
        }
        return lista;
    }

    Flickable {
        id: flickPensum
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
                id: timerTecladoPensum
                interval: 280
                onTriggered: {
                    flickPensum.restaurarPosicion();
                }
            }
        }

        // Cuando el teclado se cierra, Qt deja el contenido corrido:
        // se devuelve a la posición en la que estaba el usuario.
        Connections {
            target: daeClient
            function onTecladoVisibleChanged() {
                if (!daeClient.tecladoVisible) {
                    flickPensum.restaurarPosicion();
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
        contentHeight: colPensum.implicitHeight + 135
        clip: true

        ColumnLayout {
            id: colPensum
            width: flickPensum.width
            spacing: 14

            // =================================================================
            // 1. CABECERA CON BOTÓN DE REGRESO
            // =================================================================
            RowLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: flickPensum.width - 40
                Layout.topMargin: 24
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 10

                Rectangle {
                    id: btnVolverPensum
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
                        onPressed: btnVolverPensum.scale = 0.90
                        onReleased: btnVolverPensum.scale = 1.0
                        onClicked: rootPensum.volver()
                    }
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    spacing: 1
                    Text {
                        Layout.fillWidth: true
                        text: "Pensum de Estudios"
                        color: temaApp.textoPrincipal
                        font.pixelSize: 20
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "FACULTAD DE INGENIERÍA • DAE UC"
                        color: temaApp.esClaro ? temaApp.primario : temaApp.acento
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 0.8
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 68
                    Layout.preferredHeight: 28
                    radius: 14
                    color: temaApp.panelAlt
                    border.color: temaApp.bordeAlt
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: rootPensum.modoVista === 1 ? "2025" : (rootPensum.modoVista === 0 ? "1997" : "FAQ")
                        color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
            }

            // =================================================================
            // 2. SELECTOR PRINCIPAL: PENSUM ACTUAL (1997) / NUEVO (2025) / FAQ
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: flickPensum.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                height: 44
                radius: 16
                color: temaApp.panel
                border.color: temaApp.bordePanel
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 4

                    Repeater {
                        model: [
                            { idx: 0, texto: "Actual (1997)" },
                            { idx: 1, texto: "Nuevo (2025)" },
                            { idx: 2, texto: "Preguntas" }
                        ]

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 12
                            color: rootPensum.modoVista === modelData.idx
                                   ? temaApp.primario
                                   : "transparent"

                            Behavior on color { ColorAnimation { duration: 160 } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.texto
                                color: rootPensum.modoVista === modelData.idx
                                       ? "white"
                                       : temaApp.textoSecundario
                                font.pixelSize: 11
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    rootPensum.modoVista = modelData.idx
                                    rootPensum.semestreFiltro = 0
                                }
                            }
                        }
                    }
                }
            }

            // =================================================================
            // 3. SELECTOR DE ESCUELA + FILTROS (SOLO EN PENSUM 1997 Y 2025)
            // =================================================================
            ColumnLayout {
                Layout.fillWidth: true
                visible: rootPensum.modoVista !== 2
                spacing: 10

                // Selector desplegable de Escuela (Las 6 escuelas de Ingeniería UC)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.maximumWidth: flickPensum.width - 40
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    implicitHeight: colSelectorEsc.implicitHeight + 20
                    radius: 18
                    color: temaApp.panel
                    border.color: rootPensum.selectorEscuelaAbierto ? temaApp.primario : temaApp.bordePanel
                    border.width: 1

                    ColumnLayout {
                        id: colSelectorEsc
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 34
                                radius: 10
                                color: temaApp.panelAlt
                                border.color: temaApp.bordeAlt
                                border.width: 1

                                Canvas {
                                    width: 18; height: 18
                                    anchors.centerIn: parent
                                    property color colorTrazo: temaApp.esClaro ? temaApp.primario : temaApp.claro
                                    onColorTrazoChanged: requestPaint()
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.reset();
                                        ctx.strokeStyle = colorTrazo;
                                        ctx.lineWidth = 1.7;
                                        ctx.lineCap = "round";
                                        ctx.lineJoin = "round";
                                        ctx.strokeRect(2.5, 2.5, 5, 4.5);
                                        ctx.strokeRect(10.5, 2.5, 5, 4.5);
                                        ctx.strokeRect(6.5, 11, 5, 4.5);
                                        ctx.beginPath();
                                        ctx.moveTo(5, 7); ctx.lineTo(9, 11);
                                        ctx.moveTo(13, 7); ctx.lineTo(9, 11);
                                        ctx.stroke();
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: rootPensum.escuelaIdx === daeClient.escuelaIndexEstudiante
                                          ? "ESCUELA SELECCIONADA • TU ESCUELA"
                                          : "ESCUELA SELECCIONADA"
                                    color: temaApp.textoMuted
                                    font.pixelSize: 9
                                    font.bold: true
                                    font.letterSpacing: 0.7
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: rootPensum.listaEscuelas[rootPensum.escuelaIdx]
                                    color: temaApp.textoPrincipal
                                    font.pixelSize: 12
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                radius: 14
                                color: temaApp.panelAlt

                                Text {
                                    anchors.centerIn: parent
                                    text: rootPensum.selectorEscuelaAbierto ? "▲" : "▼"
                                    color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }
                        }

                        // Opciones del desplegable de Escuelas
                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: rootPensum.selectorEscuelaAbierto
                            spacing: 4

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: temaApp.bordeVidrio
                            }

                            Repeater {
                                model: rootPensum.listaEscuelas

                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    height: 34
                                    radius: 10
                                    color: rootPensum.escuelaIdx === index
                                           ? (temaApp.esClaro ? "#EFF6FF" : Qt.rgba(temaApp.primario.r, temaApp.primario.g, temaApp.primario.b, 0.25))
                                           : "transparent"
                                    border.color: rootPensum.escuelaIdx === index ? temaApp.primario : "transparent"
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData
                                            color: rootPensum.escuelaIdx === index
                                                   ? (temaApp.esClaro ? temaApp.primario : temaApp.claro)
                                                   : temaApp.textoSecundario
                                            font.pixelSize: 11
                                            font.bold: rootPensum.escuelaIdx === index
                                            elide: Text.ElideRight
                                        }

                                        Rectangle {
                                            visible: index === daeClient.escuelaIndexEstudiante
                                            Layout.preferredWidth: lblTuEsc.implicitWidth + 10
                                            Layout.preferredHeight: 18
                                            radius: 9
                                            color: temaApp.esClaro ? "#dbeafe" : "#1e3a8a"
                                            border.color: temaApp.primario
                                            border.width: 1

                                            Text {
                                                id: lblTuEsc
                                                anchors.centerIn: parent
                                                text: "Tu escuela"
                                                color: temaApp.esClaro ? temaApp.primario : "#93c5fd"
                                                font.pixelSize: 9
                                                font.bold: true
                                            }
                                        }

                                        Text {
                                            visible: rootPensum.escuelaIdx === index
                                            text: "✓"
                                            color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                                            font.pixelSize: 12
                                            font.bold: true
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            rootPensum.escuelaIdx = index
                                            rootPensum.selectorEscuelaAbierto = false
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            Layout.fillWidth: true
                            height: 0
                        }
                    }

                    MouseArea {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 54
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rootPensum.selectorEscuelaAbierto = !rootPensum.selectorEscuelaAbierto
                    }
                }

                // Buscador por código, nombre o requisito
                Rectangle {
                    Layout.fillWidth: true
                    Layout.maximumWidth: flickPensum.width - 40
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    height: 42
                    radius: 14
                    color: temaApp.panel
                    border.color: inputBusquedaPensum.activeFocus ? temaApp.primario : temaApp.bordePanel
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Canvas {
                            width: 16; height: 16
                            property color colorLupa: temaApp.textoMuted
                            onColorLupaChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.strokeStyle = colorLupa;
                                ctx.lineWidth = 1.8;
                                ctx.lineCap = "round";
                                ctx.beginPath();
                                ctx.arc(7, 7, 4.8, 0, Math.PI * 2);
                                ctx.moveTo(10.5, 10.5);
                                ctx.lineTo(14.2, 14.2);
                                ctx.stroke();
                            }
                        }

                        TextInput {
                            id: inputBusquedaPensum
                            Layout.fillWidth: true
                            color: temaApp.textoPrincipal
                            font.pixelSize: 12
                            clip: true
                            onTextChanged: rootPensum.textoBusqueda = text

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "Buscar código (MA1B01), materia o requisito..."
                                color: temaApp.textoMuted
                                font.pixelSize: 11
                                visible: !inputBusquedaPensum.text && !inputBusquedaPensum.activeFocus
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            visible: inputBusquedaPensum.text.length > 0
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            radius: 10
                            color: temaApp.panelAlt
                            Canvas {
                                width: 10; height: 10
                                anchors.centerIn: parent
                                property color colorTrazo: temaApp.textoSecundario
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
                                onClicked: inputBusquedaPensum.text = ""
                            }
                        }
                    }
                }

                // Píldoras de filtro por Semestre
                Flickable {
                    Layout.fillWidth: true
                    Layout.maximumWidth: flickPensum.width
                    height: 32
                    contentWidth: rowSemPills.implicitWidth + 40
                    contentHeight: 32
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: rowSemPills
                        x: 20
                        spacing: 6

                        Repeater {
                            model: rootPensum.modoVista === 1
                                   ? [
                                       { sem: 0, label: "Todos" },
                                       { sem: 1, label: "1º Sem" },
                                       { sem: 2, label: "2º Sem" },
                                       { sem: 3, label: "3º Sem" },
                                       { sem: 4, label: "4º Sem" },
                                       { sem: 5, label: "5º Sem" },
                                       { sem: 6, label: "6º Sem" },
                                       { sem: 7, label: "7º Sem" },
                                       { sem: 8, label: "8º Sem" }
                                     ]
                                   : [
                                       { sem: 0, label: "Todos" },
                                       { sem: 1, label: "1º Sem" },
                                       { sem: 2, label: "2º Sem" },
                                       { sem: 3, label: "3º Sem" },
                                       { sem: 4, label: "4º Sem" },
                                       { sem: 5, label: "5º Sem" },
                                       { sem: 6, label: "6º Sem" },
                                       { sem: 7, label: "7º Sem" },
                                       { sem: 8, label: "8º Sem" },
                                       { sem: 9, label: "9º Sem" },
                                       { sem: 10, label: "10º Sem" }
                                     ]

                            delegate: Rectangle {
                                width: txtSemPill.implicitWidth + 22
                                height: 30
                                radius: 15
                                color: rootPensum.semestreFiltro === modelData.sem
                                       ? temaApp.primario
                                       : temaApp.panel
                                border.color: rootPensum.semestreFiltro === modelData.sem
                                              ? temaApp.acento
                                              : temaApp.bordePanel
                                border.width: 1

                                Text {
                                    id: txtSemPill
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: rootPensum.semestreFiltro === modelData.sem
                                           ? "white"
                                           : temaApp.textoSecundario
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: rootPensum.semestreFiltro = modelData.sem
                                }
                            }
                        }
                    }
                }
            }

            // =================================================================
            // 4. BLOQUES DE SEMESTRES Y TABLA DE ASIGNATURAS (PENSUM 1997 / 2025)
            // =================================================================
            Repeater {
                model: rootPensum.modoVista !== 2 ? rootPensum.obtenerSemestresVisibles() : []

                delegate: Rectangle {
                    id: bloqueSemestre
                    Layout.fillWidth: true
                    Layout.maximumWidth: flickPensum.width - 40
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    implicitHeight: colBloqueSem.implicitHeight + 24
                    radius: 22
                    color: temaApp.panel
                    border.color: temaApp.bordePanel
                    border.width: 1

                    property var datosSemestre: modelData

                    ColumnLayout {
                        id: colBloqueSem
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        // Banner oficial del semestre (ej. PRIMER SEMESTRE - SE DEJARÁ DE OFERTAR EN EL PERIODO 1-2026)
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: colHeaderSem.implicitHeight + 16
                            radius: 14
                            color: temaApp.esClaro
                                   ? Qt.rgba(temaApp.primario.r, temaApp.primario.g, temaApp.primario.b, 0.12)
                                   : Qt.rgba(temaApp.primario.r, temaApp.primario.g, temaApp.primario.b, 0.24)
                            border.color: temaApp.primario
                            border.width: 1

                            ColumnLayout {
                                id: colHeaderSem
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Text {
                                        Layout.fillWidth: true
                                        text: bloqueSemestre.datosSemestre.titulo
                                        color: temaApp.textoPrincipal
                                        font.pixelSize: 12
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: txtUcSem.implicitWidth + 12
                                        Layout.preferredHeight: 18
                                        radius: 9
                                        color: temaApp.panel

                                        Text {
                                            id: txtUcSem
                                            anchors.centerIn: parent
                                            text: bloqueSemestre.datosSemestre.totalUc + " U.C."
                                            color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                                            font.pixelSize: 9
                                            font.bold: true
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: bloqueSemestre.datosSemestre.aviso
                                    color: rootPensum.modoVista === 0
                                           ? (temaApp.esClaro ? "#B45309" : "#FBBF24")
                                           : (temaApp.esClaro ? "#047857" : "#34D399")
                                    font.pixelSize: 9
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        // Lista de asignaturas del semestre
                        Repeater {
                            model: bloqueSemestre.datosSemestre.materias

                            delegate: Rectangle {
                                id: filaMateria
                                Layout.fillWidth: true
                                implicitHeight: colFilaMat.implicitHeight + 18
                                radius: 14
                                color: temaApp.panelAlt
                                border.color: temaApp.bordeAlt
                                border.width: 1

                                ColumnLayout {
                                    id: colFilaMat
                                    anchors.fill: parent
                                    anchors.margins: 9
                                    spacing: 6

                                    // Primera línea: Código + Nombre de Asignatura + Botón circular (...)
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Rectangle {
                                            Layout.preferredWidth: txtCodMat.implicitWidth + 12
                                            Layout.preferredHeight: 22
                                            radius: 7
                                            color: temaApp.panel
                                            border.color: temaApp.bordePanel
                                            border.width: 1

                                            Text {
                                                id: txtCodMat
                                                anchors.centerIn: parent
                                                text: modelData.codigo
                                                color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                                                font.pixelSize: 10
                                                font.bold: true
                                                font.family: "monospace"
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.nombre
                                            color: temaApp.textoPrincipal
                                            font.pixelSize: 12
                                            font.bold: true
                                            wrapMode: Text.WordWrap
                                        }

                                        // Botón circular (...) igual a la columna derecha del sistema DAE
                                        Rectangle {
                                            id: btnPuntos
                                            Layout.preferredWidth: 26
                                            Layout.preferredHeight: 26
                                            radius: 13
                                            color: temaApp.esClaro ? "#E0E7FF" : Qt.rgba(temaApp.primario.r, temaApp.primario.g, temaApp.primario.b, 0.32)
                                            border.color: temaApp.primario
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: "•••"
                                                color: temaApp.esClaro ? temaApp.primario : "white"
                                                font.pixelSize: 8
                                                font.bold: true
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    rootPensum.materiaDetalle = modelData
                                                    rootPensum.modalDetalleVisible = true
                                                }
                                            }
                                        }
                                    }

                                    // Segunda línea: U.C. | T | P | L y Requisitos
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 4

                                        // Insignias compactas de U.C., T, P, L
                                        Repeater {
                                            model: [
                                                { etq: "U.C.", val: modelData.uc, dest: true },
                                                { etq: "T",    val: modelData.t,  dest: false },
                                                { etq: "P",    val: modelData.p,  dest: false },
                                                { etq: "L",    val: modelData.l,  dest: false }
                                            ]

                                            delegate: Rectangle {
                                                Layout.preferredWidth: rowMetrica.implicitWidth + 10
                                                Layout.preferredHeight: 20
                                                radius: 6
                                                color: modelData.dest
                                                       ? (temaApp.esClaro ? "#DBEAFE" : "#1E3A8A")
                                                       : temaApp.panel
                                                border.color: modelData.dest ? temaApp.primario : temaApp.bordeVidrio
                                                border.width: 1

                                                Row {
                                                    id: rowMetrica
                                                    anchors.centerIn: parent
                                                    spacing: 3

                                                    Text {
                                                        text: modelData.etq + ":"
                                                        color: temaApp.textoMuted
                                                        font.pixelSize: 9
                                                        font.bold: true
                                                    }
                                                    Text {
                                                        text: modelData.val
                                                        color: modelData.dest
                                                               ? (temaApp.esClaro ? temaApp.primario : "white")
                                                               : temaApp.textoPrincipal
                                                        font.pixelSize: 9
                                                        font.bold: true
                                                    }
                                                }
                                            }
                                        }

                                        Item { Layout.fillWidth: true }

                                        // Píldora de Requisitos
                                        Rectangle {
                                            Layout.preferredWidth: Math.min(txtReqPill.implicitWidth + 14, 155)
                                            Layout.preferredHeight: 20
                                            radius: 6
                                            color: modelData.req === "NINGUNO"
                                                   ? (temaApp.esClaro ? "#DCFCE7" : "#064E3B")
                                                   : (temaApp.esClaro ? "#FEF3C7" : "#451A03")
                                            border.color: modelData.req === "NINGUNO" ? "#10B981" : "#F59E0B"
                                            border.width: 1

                                            Text {
                                                id: txtReqPill
                                                width: parent.width - 10
                                                anchors.centerIn: parent
                                                horizontalAlignment: Text.AlignHCenter
                                                text: "Req: " + modelData.req
                                                color: modelData.req === "NINGUNO"
                                                       ? (temaApp.esClaro ? "#15803D" : "#6EE7B7")
                                                       : (temaApp.esClaro ? "#B45309" : "#FCD34D")
                                                font.pixelSize: 9
                                                font.bold: true
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    z: -1
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        rootPensum.materiaDetalle = modelData
                                        rootPensum.modalDetalleVisible = true
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =================================================================
            // 5. SECCIÓN DE PREGUNTAS FRECUENTES (MODO VISTA == 2)
            // =================================================================
            ColumnLayout {
                Layout.fillWidth: true
                visible: rootPensum.modoVista === 2
                spacing: 12

                Repeater {
                    model: (daeClient.preguntasFaqPensum && daeClient.preguntasFaqPensum.length > 0)
                           ? daeClient.preguntasFaqPensum
                           : rootPensum.preguntasFrecuentes

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.maximumWidth: flickPensum.width - 40
                        Layout.leftMargin: 20
                        Layout.rightMargin: 20
                        implicitHeight: colFaqItem.implicitHeight + 26
                        radius: 20
                        color: temaApp.panel
                        border.color: temaApp.bordePanel
                        border.width: 1

                        ColumnLayout {
                            id: colFaqItem
                            anchors.fill: parent
                            anchors.margins: 13
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    Layout.preferredWidth: 24
                                    Layout.preferredHeight: 24
                                    radius: 8
                                    color: temaApp.primario

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Q" + (index + 1)
                                        color: "white"
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.pregunta
                                    color: temaApp.textoPrincipal
                                    font.pixelSize: 13
                                    font.bold: true
                                    wrapMode: Text.WordWrap
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.respuesta
                                color: temaApp.textoSecundario
                                font.pixelSize: 11
                                lineHeight: 1.25
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // MODAL EMERGENTE AL PULSAR EL BOTÓN (...) DE UNA ASIGNATURA
    // =========================================================================
    Rectangle {
        anchors.fill: parent
        visible: rootPensum.modalDetalleVisible && rootPensum.materiaDetalle !== null
        color: Qt.rgba(0, 0, 0, 0.68)
        z: 99

        MouseArea {
            anchors.fill: parent
            onClicked: rootPensum.modalDetalleVisible = false
        }

        Rectangle {
            width: parent.width - 36
            implicitHeight: colModalDet.implicitHeight + 32
            anchors.centerIn: parent
            radius: 24
            color: temaApp.panel
            border.color: temaApp.primario
            border.width: 1.5

            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                id: colModalDet
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: txtCodModal.implicitWidth + 16
                        Layout.preferredHeight: 28
                        radius: 9
                        color: temaApp.primario

                        Text {
                            id: txtCodModal
                            anchors.centerIn: parent
                            text: rootPensum.materiaDetalle ? rootPensum.materiaDetalle.codigo : ""
                            color: "white"
                            font.pixelSize: 12
                            font.bold: true
                            font.family: "monospace"
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: rootPensum.materiaDetalle ? ("Semestre " + rootPensum.materiaDetalle.sem) : ""
                        color: temaApp.textoMuted
                        font.pixelSize: 11
                        font.bold: true
                    }

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 14
                        color: temaApp.panelAlt

                        Canvas {
                            width: 12; height: 12
                            anchors.centerIn: parent
                            property color colorTrazo: temaApp.textoPrincipal
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
                            onClicked: rootPensum.modalDetalleVisible = false
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: rootPensum.materiaDetalle ? rootPensum.materiaDetalle.nombre : ""
                    color: temaApp.textoPrincipal
                    font.pixelSize: 16
                    font.bold: true
                    wrapMode: Text.WordWrap
                }

                // Cuadrícula de U.C., Horas Teóricas, Prácticas y Laboratorio
                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    columnSpacing: 8

                    Repeater {
                        model: rootPensum.materiaDetalle ? [
                            { titulo: "Créditos",    valor: rootPensum.materiaDetalle.uc + " U.C." },
                            { titulo: "Teoría (T)",  valor: rootPensum.materiaDetalle.t + " h/sem" },
                            { titulo: "Práctica (P)",valor: rootPensum.materiaDetalle.p + " h/sem" },
                            { titulo: "Lab. (L)",    valor: rootPensum.materiaDetalle.l + " h/sem" }
                        ] : []

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 48
                            radius: 12
                            color: temaApp.panelAlt
                            border.color: temaApp.bordeAlt
                            border.width: 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.titulo
                                    color: temaApp.textoMuted
                                    font.pixelSize: 9
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.valor
                                    color: temaApp.textoPrincipal
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }
                        }
                    }
                }

                // Requisitos detallados
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: colReqDet.implicitHeight + 18
                    radius: 14
                    color: temaApp.panelAlt
                    border.color: temaApp.bordeAlt
                    border.width: 1

                    ColumnLayout {
                        id: colReqDet
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 4

                        Text {
                            text: "REQUISITOS DE PRELACIÓN"
                            color: temaApp.textoMuted
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 0.7
                        }

                        Repeater {
                            model: rootPensum.materiaDetalle ? rootPensum.materiaDetalle.req.split("+") : []

                            delegate: Text {
                                Layout.fillWidth: true
                                text: modelData === "NINGUNO"
                                      ? "• Sin prelación (Apta desde inicio de carrera)"
                                      : ("• " + modelData + " — " + rootPensum.buscarNombreMateria(modelData))
                                color: temaApp.textoPrincipal
                                font.pixelSize: 11
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }

                // Asignaturas que abre posteriormente
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: colAbreDet.implicitHeight + 18
                    radius: 14
                    color: temaApp.panelAlt
                    border.color: temaApp.bordeAlt
                    border.width: 1

                    property var listaAbre: rootPensum.materiaDetalle
                                            ? rootPensum.obtenerMateriasQueAbre(rootPensum.materiaDetalle.codigo)
                                            : []

                    ColumnLayout {
                        id: colAbreDet
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 4

                        Text {
                            text: "ASIGNATURAS QUE PRELA (ABRE)"
                            color: temaApp.textoMuted
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 0.7
                        }

                        Text {
                            visible: parent.parent.listaAbre.length === 0
                            Layout.fillWidth: true
                            text: "• No es prelación directa por código de otra asignatura."
                            color: temaApp.textoSecundario
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                        }

                        Repeater {
                            model: parent.parent.listaAbre

                            delegate: Text {
                                Layout.fillWidth: true
                                text: "• " + modelData
                                color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                                font.pixelSize: 11
                                font.bold: true
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }
    }
}
