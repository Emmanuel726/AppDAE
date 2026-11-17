import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: rootOfertaHorarios

    signal volver()

    // 0 = Ambos Pensums, 1 = Pensum Viejo (1997), 2 = Pensum Nuevo (2025)
    property int filtroPensum: 0
    // 0 = Todas, 1 = Abiertas, 2 = Nuevas / Actualizadas, 3 = Cerradas
    property int filtroEstado: 0
    property string textoBusqueda: ""

    // Paginación inteligente para no renderizar +1000 tarjetas de golpe y mantener 60 FPS en el teléfono
    property int pasoCarga: 30
    property int limiteVisible: 25

    onFiltroPensumChanged: {
        limiteVisible = 25
        flickOferta.contentY = 0
    }
    onFiltroEstadoChanged: {
        limiteVisible = 25
        flickOferta.contentY = 0
    }
    onTextoBusquedaChanged: {
        limiteVisible = 25
        flickOferta.contentY = 0
    }

    // Base de datos estructurada con las asignaturas, secciones, profesores y bloques de las capturas DAE
    // pensum: "1997" (Pensum Viejo) | "2025" (Pensum Nuevo)
    // estado: "NORMAL" | "NUEVA" | "CERRADA" | "ACTUALIZADA"
    property var catalogoSecciones: [
        // =====================================================================
        // PENSUM NUEVO (2025)
        // =====================================================================
        {
            pensum: "2025", codigo: "CA3013", nombre: "FUNDAMENTOS DE PROGRAMACIÓN", sec: "01",
            profesor: "PROF. ESTELLER L VICTOR A", estado: "NORMAL",
            bloques: ["LU0800 LC1", "LU0850 LC1", "MI0800 LC1", "MI0850 LC1"]
        },
        {
            pensum: "2025", codigo: "CA3013", nombre: "FUNDAMENTOS DE PROGRAMACIÓN", sec: "02",
            profesor: "PROF. ESTELLER L VICTOR A", estado: "NORMAL",
            bloques: ["LU0940 LC1", "LU1030 LC1", "MI0940 LC1", "MI1030 LC1"]
        },
        {
            pensum: "2025", codigo: "CA3013", nombre: "FUNDAMENTOS DE PROGRAMACIÓN", sec: "03",
            profesor: "PROF. ESTELLER L VICTOR A", estado: "NORMAL",
            bloques: ["LU1120 LC1", "LU1210 LC1", "MI1120 LC1", "MI1210 LC1"]
        },
        {
            pensum: "2025", codigo: "CA3013", nombre: "FUNDAMENTOS DE PROGRAMACIÓN", sec: "04",
            profesor: "PROF. PACHECO S LISBETH C", estado: "NORMAL",
            bloques: ["MA0800 LC1", "MA0850 LC1", "JU0800 LC1", "JU0850 LC1"]
        },
        {
            pensum: "2025", codigo: "CA3013", nombre: "FUNDAMENTOS DE PROGRAMACIÓN", sec: "05",
            profesor: "PROF. PACHECO S LISBETH C", estado: "NORMAL",
            bloques: ["MA0940 LC1", "MA1030 LC1", "JU0940 LC1", "JU1030 LC1"]
        },
        {
            pensum: "2025", codigo: "CA3013", nombre: "FUNDAMENTOS DE PROGRAMACIÓN", sec: "06",
            profesor: "PROF. PACHECO S LISBETH C", estado: "NORMAL",
            bloques: ["MA1120 LC1", "MA1210 LC1", "JU1120 LC1", "JU1210 LC1"]
        },
        {
            pensum: "2025", codigo: "DI2013", nombre: "FUNDAMENTOS DE DIBUJO PARA INGENIERÍA", sec: "01",
            profesor: "PROF. SEVERIAN G NEYDA M", estado: "NORMAL",
            bloques: ["LU0800 SD1", "LU0850 SD1", "MI0800 SD1", "MI0850 SD1"]
        },
        {
            pensum: "2025", codigo: "DI2013", nombre: "FUNDAMENTOS DE DIBUJO PARA INGENIERÍA", sec: "02",
            profesor: "PROF. SEVERIAN G NEYDA M", estado: "NORMAL",
            bloques: ["LU0940 SD1", "LU1030 SD1", "MI0940 SD1", "MI1030 SD1"]
        },
        {
            pensum: "2025", codigo: "DI2013", nombre: "FUNDAMENTOS DE DIBUJO PARA INGENIERÍA", sec: "03",
            profesor: "PROF. SEVERIAN G NEYDA M", estado: "NORMAL",
            bloques: ["LU1120 SD1", "LU1210 SD1", "MI1120 SD1", "MI1210 SD1"]
        },
        {
            pensum: "2025", codigo: "DI2013", nombre: "FUNDAMENTOS DE DIBUJO PARA INGENIERÍA", sec: "04",
            profesor: "PROF. MIRANDA G RICARDO A", estado: "NORMAL",
            bloques: ["LU0800 SD2", "LU0850 SD2", "MI0800 SD2", "MI0850 SD2"]
        },
        {
            pensum: "2025", codigo: "DI2013", nombre: "FUNDAMENTOS DE DIBUJO PARA INGENIERÍA", sec: "05",
            profesor: "PROF. MIRANDA G RICARDO A", estado: "NORMAL",
            bloques: ["LU0940 SD2", "LU1030 SD2", "MI0940 SD2", "MI1030 SD2"]
        },
        {
            pensum: "2025", codigo: "DI2013", nombre: "FUNDAMENTOS DE DIBUJO PARA INGENIERÍA", sec: "06",
            profesor: "PROF. MIRANDA G RICARDO A", estado: "NORMAL",
            bloques: ["LU1120 SD2", "LU1210 SD2", "MI1120 SD2", "MI1210 SD2"]
        },
        {
            pensum: "2025", codigo: "FI2015", nombre: "FÍSICA MECÁNICA", sec: "04",
            profesor: "PROF. CUERVA H YOEL R", estado: "NORMAL",
            bloques: ["MA1210 AD1", "MA1300 AD1", "MA1350 AD1", "JU1210 AD1", "JU1300 AD1", "JU1350 AD1"]
        },
        {
            pensum: "2025", codigo: "FI2015", nombre: "FÍSICA MECÁNICA", sec: "05",
            profesor: "PROF. CUERVA H YOEL R", estado: "CERRADA",
            bloques: ["MA1440 AVING", "MA1530 AVING", "MA1620 AVING", "JU1440 AVING", "JU1530 AVING", "JU1620 AVING"]
        },
        {
            pensum: "2025", codigo: "FI3023", nombre: "ELECTRICIDAD Y MAGNETISMO", sec: "01",
            profesor: "PROF. PEÑA T ELIANA", estado: "ACTUALIZADA",
            bloques: ["MA0940 A6E", "MA1030 A6E", "JU0940 A6E", "JU1030 A6E"]
        },
        {
            pensum: "2025", codigo: "FI3023", nombre: "ELECTRICIDAD Y MAGNETISMO", sec: "02",
            profesor: "PROF. MARQUEZ R MAIRIM H", estado: "NORMAL",
            bloques: ["MA0940 AF1", "MA1030 AF1", "JU0940 AF1", "JU1030 AF1"]
        },
        {
            pensum: "2025", codigo: "FI3023", nombre: "ELECTRICIDAD Y MAGNETISMO", sec: "03",
            profesor: "PROF. PEÑA T ELIANA", estado: "ACTUALIZADA",
            bloques: ["MA1440 A10", "MA1530 A10", "JU1440 A11", "JU1530 A11"]
        },
        {
            pensum: "2025", codigo: "FI3023", nombre: "ELECTRICIDAD Y MAGNETISMO", sec: "04",
            profesor: "PROF. MARQUEZ R MAIRIM H", estado: "NORMAL",
            bloques: ["MA1440 AF1", "MA1530 AF1", "JU1440 AF1", "JU1530 AF1"]
        },
        {
            pensum: "2025", codigo: "FI3033", nombre: "FÍSICA EXPERIMENTAL", sec: "19",
            profesor: "PROF. MONTILLA R LUYLLY R", estado: "NORMAL",
            bloques: ["VI1300 LF1A", "VI1350 LF1A", "VI1440 LF1A"]
        },
        {
            pensum: "2025", codigo: "FI3033", nombre: "FÍSICA EXPERIMENTAL", sec: "20",
            profesor: "PROF. PEÑA T ELIANA", estado: "CERRADA",
            bloques: ["MI1300 AVING", "MI1350 AVING", "MI1440 AVING"]
        },
        {
            pensum: "2025", codigo: "FI3033", nombre: "FÍSICA EXPERIMENTAL", sec: "21",
            profesor: "PROF. PEÑA T ELIANA", estado: "NUEVA",
            bloques: ["MI1300 LF1B", "MI1350 LF1B", "MI1440 LF1B"]
        },
        {
            pensum: "2025", codigo: "HU1013", nombre: "FUNDAMENTOS DE CIENCIAS HUMANAS", sec: "01",
            profesor: "PROF. LEON G CESAR O", estado: "NORMAL",
            bloques: ["LU0800 A10", "LU0850 A10", "LU0940 A10"]
        },
        {
            pensum: "2025", codigo: "HU1013", nombre: "FUNDAMENTOS DE CIENCIAS HUMANAS", sec: "02",
            profesor: "PROF. LEON G CESAR O", estado: "NORMAL",
            bloques: ["LU1030 A11", "LU1120 A11", "LU1210 A11"]
        },
        {
            pensum: "2025", codigo: "HU1013", nombre: "FUNDAMENTOS DE CIENCIAS HUMANAS", sec: "03",
            profesor: "PROF. LEON G CESAR O", estado: "NORMAL",
            bloques: ["JU0800 AE6", "JU0850 AE6", "JU0940 AE6"]
        },

        // =====================================================================
        // PENSUM VIEJO (1997)
        // =====================================================================
        {
            pensum: "1997", codigo: "CA3B01", nombre: "COMPUTACION I", sec: "01",
            profesor: "PROF. ESTELLER L VICTOR A", estado: "NORMAL",
            bloques: ["LU0800 LC1", "LU0850 LC1", "MI0800 LC1", "MI0850 LC1"]
        },
        {
            pensum: "1997", codigo: "CA3B01", nombre: "COMPUTACION I", sec: "02",
            profesor: "PROF. ESTELLER L VICTOR A", estado: "NORMAL",
            bloques: ["LU0940 LC1", "LU1030 LC1", "MI0940 LC1", "MI1030 LC1"]
        },
        {
            pensum: "1997", codigo: "CA3B01", nombre: "COMPUTACION I", sec: "03",
            profesor: "PROF. ESTELLER L VICTOR A", estado: "NORMAL",
            bloques: ["LU1120 LC1", "LU1210 LC1", "MI1120 LC1", "MI1210 LC1"]
        },
        {
            pensum: "1997", codigo: "CA3B01", nombre: "COMPUTACION I", sec: "04",
            profesor: "PROF. PACHECO S LISBETH C", estado: "NORMAL",
            bloques: ["MA0800 LC1", "MA0850 LC1", "JU0800 LC1", "JU0850 LC1"]
        },
        {
            pensum: "1997", codigo: "CA3B01", nombre: "COMPUTACION I", sec: "05",
            profesor: "PROF. PACHECO S LISBETH C", estado: "NORMAL",
            bloques: ["MA0940 LC1", "MA1030 LC1", "JU0940 LC1", "JU1030 LC1"]
        },
        {
            pensum: "1997", codigo: "CA3B01", nombre: "COMPUTACION I", sec: "06",
            profesor: "PROF. PACHECO S LISBETH C", estado: "NORMAL",
            bloques: ["MA1120 LC1", "MA1210 LC1", "JU1120 LC1", "JU1210 LC1"]
        },
        {
            pensum: "1997", codigo: "CA4B01", nombre: "COMPUTACION I", sec: "01",
            profesor: "PROF. ESTELLER L VICTOR A", estado: "NORMAL",
            bloques: ["LU0800 LC1", "LU0850 LC1", "MI0800 LC1", "MI0850 LC1"]
        },
        {
            pensum: "1997", codigo: "CA4B01", nombre: "COMPUTACION I", sec: "02",
            profesor: "PROF. ESTELLER L VICTOR A", estado: "NORMAL",
            bloques: ["LU0940 LC1", "LU1030 LC1", "MI0940 LC1", "MI1030 LC1"]
        },
        {
            pensum: "1997", codigo: "CA4B01", nombre: "COMPUTACION I", sec: "03",
            profesor: "PROF. ESTELLER L VICTOR A", estado: "NORMAL",
            bloques: ["LU1120 LC1", "LU1210 LC1", "MI1120 LC1", "MI1210 LC1"]
        },
        {
            pensum: "1997", codigo: "CA4B01", nombre: "COMPUTACION I", sec: "04",
            profesor: "PROF. PACHECO S LISBETH C", estado: "NORMAL",
            bloques: ["MA0800 LC1", "MA0850 LC1", "JU0800 LC1", "JU0850 LC1"]
        },
        {
            pensum: "1997", codigo: "CA4B01", nombre: "COMPUTACION I", sec: "05",
            profesor: "PROF. PACHECO S LISBETH C", estado: "NORMAL",
            bloques: ["MA0940 LC1", "MA1030 LC1", "JU0940 LC1", "JU1030 LC1"]
        },
        {
            pensum: "1997", codigo: "CM5T02", nombre: "CIRCUITOS ELECTRICOS II", sec: "41",
            profesor: "PROF. CASTILLO B ARTURO J", estado: "NORMAL",
            bloques: ["MA1300 SLM", "MA1350 SLM", "MA1440 SLM", "VI1300 SLM", "VI1350 SLM"]
        },
        {
            pensum: "1997", codigo: "CM5T03", nombre: "MEDICIONES ELECTRICAS", sec: "71",
            profesor: "PROF. STEBLINA G CHARLES", estado: "NORMAL",
            bloques: ["LU1120 SIE3", "LU1210 SIE3", "LU1300 SIE3"]
        },
        {
            pensum: "1997", codigo: "CM5T03L", nombre: "MEDICIONES ELECTRICAS (LAB)", sec: "01",
            profesor: "PROF. STEBLINA G CHARLES", estado: "ACTUALIZADA",
            bloques: ["LU0800 LCM", "LU0850 LCM", "LU0940 LCM", "LU1030 LCM"]
        },
        {
            pensum: "1997", codigo: "CM5T03L", nombre: "MEDICIONES ELECTRICAS (LAB)", sec: "02",
            profesor: "PROF. VARGAS P JOSE A", estado: "ACTUALIZADA",
            bloques: ["MI0850 LCM", "MI0940 LCM", "MI1030 LCM", "MI1120 LCM"]
        },
        {
            pensum: "1997", codigo: "CM5T03L", nombre: "MEDICIONES ELECTRICAS (LAB)", sec: "03",
            profesor: "PROF. CANELON B EMILIA R", estado: "ACTUALIZADA",
            bloques: ["JU0800 LCM", "JU0850 LCM", "JU0940 LCM", "JU1030 LCM"]
        },
        {
            pensum: "1997", codigo: "CM5T03L", nombre: "MEDICIONES ELECTRICAS (LAB)", sec: "04",
            profesor: "PROF. CANELON B EMILIA R", estado: "ACTUALIZADA",
            bloques: ["VI0800 LCM", "VI0850 LCM", "VI0940 LCM", "VI1030 LCM"]
        },
        {
            pensum: "1997", codigo: "CO6B01", nombre: "PROYECTO SERVICIO COMUNITARIO", sec: "07",
            profesor: "", estado: "NORMAL",
            bloques: []
        },
        {
            pensum: "1997", codigo: "CO8B01", nombre: "PROYECTO SERVICIO COMUNITARIO", sec: "01",
            profesor: "", estado: "NORMAL",
            bloques: []
        },
        {
            pensum: "1997", codigo: "CO8B01", nombre: "PROYECTO SERVICIO COMUNITARIO", sec: "02",
            profesor: "", estado: "NORMAL",
            bloques: []
        },
        {
            pensum: "1997", codigo: "CO8B01", nombre: "PROYECTO SERVICIO COMUNITARIO", sec: "03",
            profesor: "", estado: "NORMAL",
            bloques: []
        },
        {
            pensum: "1997", codigo: "CO8B01", nombre: "PROYECTO SERVICIO COMUNITARIO", sec: "04",
            profesor: "", estado: "NORMAL",
            bloques: []
        },
        {
            pensum: "1997", codigo: "CO8B01", nombre: "PROYECTO SERVICIO COMUNITARIO", sec: "06",
            profesor: "", estado: "NORMAL",
            bloques: []
        },
        {
            pensum: "1997", codigo: "DA0M12", nombre: "MANTENIMIENTO INDUSTRIAL", sec: "51",
            profesor: "PROF. MONTERO P FERNANDO", estado: "NORMAL",
            bloques: ["MA0800 ANM", "MA0850 ANM", "MA0940 ANM", "JU1030 SPG", "JU1120 SPG"]
        },
        {
            pensum: "1997", codigo: "DA0M13", nombre: "LUBRICACION Y COJINETES", sec: "51",
            profesor: "PROF. ROMERO C JORGE E", estado: "NORMAL",
            bloques: ["LU1030 ANM", "LU1120 ANM", "LU1210 ANM", "MA1030 ANM", "MA1120 ANM"]
        },
        {
            pensum: "1997", codigo: "DI3B01", nombre: "DIBUJO I", sec: "15",
            profesor: "PROF. PADRON M ANDRES A", estado: "NORMAL",
            bloques: ["MA1120 SD2", "MA1210 SD2", "VI1120 SD2", "VI1210 SD2"]
        },
        {
            pensum: "1997", codigo: "DI3B01", nombre: "DIBUJO I", sec: "16",
            profesor: "PROF. PADRON M ANDRES A", estado: "NORMAL",
            bloques: ["MA1300 SD2", "MA1350 SD2", "VI1300 SD2", "VI1350 SD2"]
        },
        {
            pensum: "1997", codigo: "DI3B01", nombre: "DIBUJO I", sec: "17",
            profesor: "PROF. PADRON M ANDRES A", estado: "NORMAL",
            bloques: ["MA1440 SD3", "MA1530 SD3", "VI1440 SD3", "VI1530 SD3"]
        },
        {
            pensum: "1997", codigo: "DI3B01", nombre: "DIBUJO I", sec: "18",
            profesor: "PROF. NO ASIGNADO", estado: "NUEVA",
            bloques: ["MA1620 SD1", "MA1710 SD1", "JU1620 SD1", "JU1710 SD1"]
        },
        {
            pensum: "1997", codigo: "DI4B02", nombre: "DIBUJO II", sec: "01",
            profesor: "PROF. CORALES H CARLOS J", estado: "NORMAL",
            bloques: ["VI0800 SD1", "VI0850 SD1", "VI0940 SD1", "VI1030 SD1"]
        },
        {
            pensum: "1997", codigo: "DQ5Q01", nombre: "QUIMICA ANALITICA", sec: "61",
            profesor: "PROF. DE SOUSA D S CRISTINA J", estado: "NORMAL",
            bloques: ["MA0800 AEIQ", "MA0850 AEIQ", "MA0940 AEIQ"]
        },
        {
            pensum: "1997", codigo: "DQ5Q01", nombre: "QUIMICA ANALITICA", sec: "62",
            profesor: "PROF. CESAR R LUIS A", estado: "NORMAL",
            bloques: ["MA1120 AEIQ", "MA1210 AEIQ", "MA1300 AEIQ"]
        },
        {
            pensum: "1997", codigo: "DQ6Q02", nombre: "LAB. QUIMICA ANALITICA", sec: "61",
            profesor: "PROF. DE SOUSA D S CRISTINA J", estado: "NORMAL",
            bloques: ["LU0800 LQA", "LU0850 LQA", "LU0940 LQA", "LU1030 LQA"]
        },
        {
            pensum: "1997", codigo: "DQ6Q02", nombre: "LAB. QUIMICA ANALITICA", sec: "62",
            profesor: "PROF. DE SOUSA D S CRISTINA J", estado: "NORMAL",
            bloques: ["LU1120 LQA", "LU1210 LQA", "LU1300 LQA", "LU1350 LQA"]
        },
        {
            pensum: "1997", codigo: "DQ6Q02", nombre: "LAB. QUIMICA ANALITICA", sec: "63",
            profesor: "PROF. CESAR R LUIS A", estado: "NORMAL",
            bloques: ["MA0800 LQA", "MA0850 LQA", "MA0940 LQA", "MA1030 LQA"]
        },
        {
            pensum: "1997", codigo: "DQ6Q03", nombre: "FISICOQUIMICA", sec: "61",
            profesor: "PROF. CRESPO P ISIS G", estado: "CERRADA",
            bloques: ["LU0800 AVING", "LU0850 AVING", "MA0800 AVING", "MA0850 AVING"]
        },
        {
            pensum: "1997", codigo: "DQ6Q03", nombre: "FISICOQUIMICA", sec: "62",
            profesor: "PROF. SIERRA F ADRIAN D", estado: "NORMAL",
            bloques: ["MA1300 A11", "MA1350 A11", "JU1120 A11", "JU1210 A11"]
        },
        {
            pensum: "1997", codigo: "ER6T02", nombre: "TEORIA ELECTROMAGNETICA II", sec: "71",
            profesor: "PROF. CASTILLO G MOISES E", estado: "NORMAL",
            bloques: ["MI0800 A7E", "MI0850 A7E", "MI0940 A7E", "MI1030 A7E"]
        },
        {
            pensum: "1997", codigo: "IN6T01", nombre: "PROBABILIDADES Y PROC. ESTOCASTICOS", sec: "31",
            profesor: "PROF. HERNANDEZ T CARLOS D", estado: "NORMAL",
            bloques: ["SA0800 LIM", "SA0850 LIM", "SA0940 LIM", "SA1030 LIM"]
        },
        {
            pensum: "1997", codigo: "SA6T01", nombre: "LOGICA DIGITAL", sec: "41",
            profesor: "PROF. VILLEGAS A RICARDO A", estado: "NORMAL",
            bloques: ["LU1300 SIE1", "LU1350 SIE1", "MA1030 SIE1", "MA1120 SIE1"]
        },
        {
            pensum: "1997", codigo: "SA6T01L", nombre: "LOGICA DIGITAL (LAB)", sec: "03",
            profesor: "PROF. VILLEGAS A RICARDO A", estado: "NORMAL",
            bloques: ["MA0850 LLOG", "MA0940 LLOG"]
        },
        {
            pensum: "1997", codigo: "SS7T02", nombre: "PROCESAMIENTO DIGITAL DE SEÑALES", sec: "72",
            profesor: "PROF. HIDALGO S ABRAHAM J", estado: "NUEVA",
            bloques: ["MI1120 LABSS", "MI1210 LABSS", "MI1300 LABSS", "MI1350 LABSS"]
        },
        {
            pensum: "1997", codigo: "SS7T02L", nombre: "PROCESAMIENTO DIGITAL DE SEÑALES (LAB)", sec: "01",
            profesor: "PROF. HIDALGO S ABRAHAM J", estado: "NORMAL",
            bloques: ["SA1120 LCTEL", "SA1210 LCTEL"]
        },
        {
            pensum: "1997", codigo: "SS7T03", nombre: "INSTRUMENTACION ELECTRONICA", sec: "71",
            profesor: "PROF. HERRERA M GERARDO R", estado: "NORMAL",
            bloques: ["VI0800 SEIN", "VI0850 SEIN"]
        },
        {
            pensum: "1997", codigo: "SS7T03L", nombre: "INSTRUMENTACION ELECTRONICA (LAB)", sec: "01",
            profesor: "PROF. HERRERA M GERARDO R", estado: "NORMAL",
            bloques: ["VI0940 SEIN", "VI1030 SEIN", "VI1120 SEIN"]
        }
    ]

    // Total de secciones que cumplen el filtro actual (calculado en C++ en <1ms)
    property int totalCoincidencias: {
        var dep = daeClient.totalSeccionesOferta;
        if (dep > 0) {
            return daeClient.contarHorariosOferta(rootOfertaHorarios.filtroPensum, rootOfertaHorarios.filtroEstado, rootOfertaHorarios.textoBusqueda);
        }
        return filtrarOfertaLocal(rootOfertaHorarios.filtroPensum, rootOfertaHorarios.filtroEstado, rootOfertaHorarios.textoBusqueda, 9999).length;
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

    function filtrarOfertaLocal(pensumIdx, estadoIdx, busqueda, maxItems) {
        var fuente = catalogoSecciones;
        var res = [];
        for (var i = 0; i < fuente.length; i++) {
            var item = fuente[i];

            if (pensumIdx === 1 && item.pensum !== "1997") continue;
            if (pensumIdx === 2 && item.pensum !== "2025") continue;

            if (estadoIdx === 1 && item.estado === "CERRADA") continue;
            if (estadoIdx === 2 && item.estado !== "NUEVA" && item.estado !== "ACTUALIZADA") continue;
            if (estadoIdx === 3 && item.estado !== "CERRADA") continue;
            if (estadoIdx === 4 && item.profesor !== "PROF. NO ASIGNADO") continue;

            if (busqueda !== "") {
                var bloquesStr = item.bloques.join(" ");
                var textoItem = (item.codigo || "") + " " + (item.nombre || "") + " " + (item.profesor || "") + " " + (item.sec || "") + " " + bloquesStr;
                if (!coincideBusqueda(textoItem, busqueda)) continue;
            }

            res.push(item);
            if (res.length >= maxItems) break;
        }
        return res;
    }

    function filtrarOfertaPaginada(pensumIdx, estadoIdx, busqueda, limite) {
        if (daeClient.totalSeccionesOferta > 0) {
            return daeClient.filtrarHorariosOferta(pensumIdx, estadoIdx, busqueda, limite);
        }
        return filtrarOfertaLocal(pensumIdx, estadoIdx, busqueda, limite);
    }

    function formatearBloqueConEscuela(bloqueStr) {
        if (!bloqueStr) return "";
        var partes = String(bloqueStr).trim().split(/\s+/);
        if (partes.length < 2) return bloqueStr;
        var hora = partes[0];
        var aula = partes.slice(1).join(" ").toUpperCase();
        var mapaEscuelas = {
            "LABSS":  "LABSS (Esc. Telecom)",
            "LABER":  "LABER (Esc. Telecom)",
            "LCTEL":  "LCTEL (Esc. Telecom)",
            "LABANT": "LABANT (Esc. Telecom)",
            "LLOG":   "LLOG (Esc. Eléctrica)",
            "LDD":    "LDD (Esc. Eléctrica)",
            "LABCOM": "LABCOM (Esc. Eléctrica)",
            "LAU1":   "LAU1 (Esc. Eléctrica)",
            "LAU2":   "LAU2 (Esc. Eléctrica)",
            "LCTR":   "LCTR (Esc. Eléctrica)",
            "LCM":    "LCM (Esc. Eléctrica)",
            "LE1":    "LE1 (Esc. Eléctrica)",
            "LE2":    "LE2 (Esc. Eléctrica)",
            "LE3":    "LE3 (Esc. Eléctrica)",
            "SIE4":   "SIE4 (Esc. Eléctrica)",
            "SIE6":   "SIE6 (Esc. Eléctrica)",
            "LM1":    "LM1 (Esc. Eléctrica)",
            "LM2":    "LM2 (Esc. Eléctrica)",
            "LM3":    "LM3 (Esc. Eléctrica)",
            "LDM":    "LDM (Esc. Mecánica)",
            "LCAU":   "LCAU (Esc. Mecánica)",
            "LMAT":   "LMAT (Esc. Mecánica)",
            "LPROC":  "LPROC (Esc. Mecánica)",
            "MPROC":  "MPROC (Esc. Mecánica)",
            "LTER":   "LTER (Esc. Mecánica)",
            "LMFM":   "LMFM (Esc. Mecánica)",
            "LMF":    "LMF (Esc. Mecánica)",
            "SPG":    "SPG (Esc. Mecánica)",
            "ADH2":   "ADH2 (Esc. Mecánica)",
            "AEIQ":   "AEIQ (Esc. Química)",
            "LCQ":    "LCQ (Esc. Química)",
            "LIQ":    "LIQ (Esc. Química)",
            "LQA":    "LQA (Esc. Química)",
            "LQO":    "LQO (Esc. Química)",
            "LOU1":   "LOU1 (Esc. Química)",
            "LOU2":   "LOU2 (Esc. Química)",
            "SH01":   "SH01 (Esc. Civil Hidráulica)",
            "SH02":   "SH02 (Esc. Civil Hidráulica)",
            "SH03":   "SH03 (Esc. Civil Hidráulica)",
            "LMFC":   "LMFC (Esc. Civil Hidráulica)",
            "LCA":    "LCA (Esc. Civil)",
            "ADP":    "ADP (Esc. Civil)",
            "LP":     "LP (Esc. Civil)",
            "LSL":    "LSL (Esc. Civil)",
            "LTOP":   "LTOP (Esc. Civil)",
            "LME":    "LME (Esc. Civil)",
            "LEM":    "LEM (Esc. Civil)",
            "LIM2":   "LIM2 (Esc. Industrial)",
            "LIO":    "LIO (Esc. Industrial)",
            "SUM":    "SUM (Esc. Industrial)",
            "LC1":    "LC1 (Dpto. Computación)",
            "LC3":    "LC3 (Dpto. Computación)",
            "LF1A":   "LF1A (Dpto. Física)",
            "LF1B":   "LF1B (Dpto. Física)",
            "LF2":    "LF2 (Dpto. Física)",
            "LQG":    "LQG (Dpto. Química)",
            "LFQ":    "LFQ (Lab. Fisicoquímica)",
            "DEP2":   "DEP2 (Canchas)",
            "AVING":  "AVING (Aula Virtual)"
        };
        if (mapaEscuelas[aula]) {
            return hora + " " + mapaEscuelas[aula];
        }
        return bloqueStr;
    }

    Flickable {
        id: flickOferta
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
                id: timerTecladoOferta
                interval: 280
                onTriggered: {
                    flickOferta.restaurarPosicion();
                }
            }
        }

        // Cuando el teclado se cierra, Qt deja el contenido corrido:
        // se devuelve a la posición en la que estaba el usuario.
        Connections {
            target: daeClient
            function onTecladoVisibleChanged() {
                if (!daeClient.tecladoVisible) {
                    flickOferta.restaurarPosicion();
                }
            }
        }

        // Desplazamiento con el teclado:
        anchors.fill: parent
        contentWidth: width
        contentHeight: colOferta.implicitHeight + 135
        clip: true

        // Carga progresiva automática al acercarse al final del scroll
        onContentYChanged: {
            if (!restaurandoScroll && (dragging || flicking)) {
                // el usuario está desplazando: su posición es la buena
                posicionScroll = contentY;
            }
            if (contentY < 0) {
                restaurandoScroll = true;
                contentY = 0;
                restaurandoScroll = false;
            }
            if (!dragging && !flicking) return;
            if (contentY + height > contentHeight - 280) {
                if (rootOfertaHorarios.limiteVisible < rootOfertaHorarios.totalCoincidencias) {
                    rootOfertaHorarios.limiteVisible += rootOfertaHorarios.pasoCarga
                }
            }
        }

        ColumnLayout {
            id: colOferta
            width: flickOferta.width
            spacing: 14

            // 1. CABECERA PRINCIPAL
            RowLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: flickOferta.width - 40
                Layout.topMargin: 24
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 10

                Rectangle {
                    id: btnVolverOferta
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
                        onPressed: btnVolverOferta.scale = 0.90
                        onReleased: btnVolverOferta.scale = 1.0
                        onClicked: rootOfertaHorarios.volver()
                    }
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    spacing: 1
                    Text {
                        text: {
                            // Dependencia explícita para refrescar cuando cambia el período publicado en el menú
                            var periodoMenu = daeClient.periodoInscripcion
                            return "Horarios Período " + daeClient.periodoOfertaHorarios + " R"
                        }
                        color: temaApp.textoPrincipal
                        font.pixelSize: 19
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: daeClient.fechaActualizacionHorarios !== "" ? daeClient.fechaActualizacionHorarios : "Actualizado al 22/10/2026 • 06:47 pm"
                        color: temaApp.textoSubtitulo
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    Layout.preferredWidth: rowConteoSec.implicitWidth + 16
                    Layout.preferredHeight: 32
                    radius: 16
                    color: temaApp.vidrio
                    border.color: temaApp.bordeVidrio
                    border.width: 1

                    RowLayout {
                        id: rowConteoSec
                        anchors.centerIn: parent
                        spacing: 5

                        Rectangle {
                            Layout.preferredWidth: 7
                            Layout.preferredHeight: 7
                            radius: 3.5
                            color: temaApp.acento
                        }
                        Text {
                            text: rootOfertaHorarios.totalCoincidencias + " Sec."
                            color: temaApp.textoPrincipal
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }
                }
            }

            // 2. AVISO OFICIAL DE LA COMISIÓN DE HORARIOS
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: flickOferta.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: 62
                radius: 18
                color: temaApp.esClaro ? "#fee2e2" : "#28ef4444"
                border.color: temaApp.esClaro ? "#ef4444" : "#65f87171"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        radius: 11
                        color: temaApp.esClaro ? "#fecaca" : "#40ef4444"
                        border.color: "#ef4444"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "!"
                            color: temaApp.esClaro ? "#b91c1c" : "#fca5a5"
                            font.pixelSize: 16
                            font.bold: true
                        }
                    }

                    Text {
                        text: "DAE SOLO MUESTRA LOS HORARIOS CARGADOS POR LA COMISIÓN DE HORARIOS, NO LOS MODIFICA."
                        color: temaApp.esClaro ? "#991b1b" : "#fecaca"
                        font.pixelSize: 10
                        font.bold: true
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            // 3. CONMUTADOR DE PENSUM (Ambos | Pensum Viejo 1997 | Pensum Nuevo 2025)
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: flickOferta.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: 44
                radius: 22
                color: temaApp.panel
                border.color: temaApp.bordePanel
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 4

                    Repeater {
                        model: [
                            { idx: 0, label: "Todos" },
                            { idx: 1, label: "Pensum Viejo (1997)" },
                            { idx: 2, label: "Pensum Nuevo (2025)" }
                        ]

                        delegate: Rectangle {
                            property bool sel: rootOfertaHorarios.filtroPensum === modelData.idx
                            width: modelData.idx === 0 ? parent.width * 0.22 : (parent.width * 0.39 - 4)
                            height: parent.height
                            radius: 18
                            color: sel ? temaApp.primario : "transparent"
                            Behavior on color { ColorAnimation { duration: 180 } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: sel ? "white" : temaApp.textoSecundario
                                font.pixelSize: 10
                                font.bold: true
                                elide: Text.ElideRight
                                width: parent.width - 8
                                horizontalAlignment: Text.AlignHCenter
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: rootOfertaHorarios.filtroPensum = modelData.idx
                            }
                        }
                    }
                }
            }

            // 4. BARRA DE BÚSQUEDA POR MATERIA, CÓDIGO, PROFESOR O AULA
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: flickOferta.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: 46
                radius: 23
                color: temaApp.panelAlt
                border.color: inputBuscarOferta.activeFocus ? temaApp.acento : temaApp.bordeAlt
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
                            text: "Buscar materia, código, profesor o aula (ej. Esteller, LC1)..."
                            color: temaApp.textoMuted
                            font.pixelSize: 11
                            visible: inputBuscarOferta.text === ""
                            elide: Text.ElideRight
                            width: parent.width
                        }
                        TextInput {
                            id: inputBuscarOferta
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            color: temaApp.textoPrincipal
                            font.pixelSize: 13
                            selectByMouse: true
                            clip: true
                            onTextChanged: rootOfertaHorarios.textoBusqueda = text.trim().toUpperCase()
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 22; Layout.preferredHeight: 22; radius: 11
                        color: temaApp.esClaro ? "#e2e8f0" : "#28ffffff"
                        visible: inputBuscarOferta.text !== ""
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
                            onClicked: inputBuscarOferta.text = ""
                        }
                    }
                }
            }

            // 5. PÍLDORAS DE FILTRO POR ESTADO DE SECCIÓN
            Flickable {
                Layout.fillWidth: true
                Layout.maximumWidth: flickOferta.width
                Layout.preferredHeight: 34
                contentWidth: rowFiltrosEstado.implicitWidth + 40
                clip: true

                Row {
                    id: rowFiltrosEstado
                    x: 20
                    spacing: 8

                    Repeater {
                        model: [
                            { idx: 0, texto: "Todas las Secciones", colorActivo: temaApp.primario },
                            { idx: 1, texto: "Abiertas", colorActivo: "#16a34a" },
                            { idx: 2, texto: "Nuevas / Actualizadas", colorActivo: "#0284c7" },
                            { idx: 3, texto: "Cerradas", colorActivo: "#dc2626" },
                            { idx: 4, texto: "Prof. No Asignado", colorActivo: "#d97706" }
                        ]

                        delegate: Rectangle {
                            property bool sel: rootOfertaHorarios.filtroEstado === modelData.idx
                            width: txtEstPildora.implicitWidth + 22
                            height: 32; radius: 16
                            color: sel ? modelData.colorActivo : temaApp.panelAlt
                            border.color: sel ? temaApp.claro : temaApp.bordeAlt
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 180 } }

                            Text {
                                id: txtEstPildora
                                anchors.centerIn: parent
                                text: modelData.texto
                                color: sel ? "white" : temaApp.textoSecundario
                                font.pixelSize: 11
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: rootOfertaHorarios.filtroEstado = modelData.idx
                            }
                        }
                    }
                }
            }

            // 6. LISTA PAGINADA DE TARJETAS DE HORARIOS DE MATERIAS Y PROFESORES
            Repeater {
                id: repOferta
                model: {
                    var dep = daeClient.totalSeccionesOferta;
                    return rootOfertaHorarios.filtrarOfertaPaginada(
                        rootOfertaHorarios.filtroPensum,
                        rootOfertaHorarios.filtroEstado,
                        rootOfertaHorarios.textoBusqueda,
                        rootOfertaHorarios.limiteVisible
                    );
                }

                delegate: Rectangle {
                    id: cardSeccion
                    property string est: modelData.estado
                    property bool esCerrada: est === "CERRADA"
                    property bool esNueva: est === "NUEVA"
                    property bool esActualizada: est === "ACTUALIZADA"
                    property bool sinProfAsignado: modelData.profesor === "PROF. NO ASIGNADO"

                    Layout.fillWidth: true
                    Layout.maximumWidth: flickOferta.width - 40
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    Layout.preferredHeight: colInternaSeccion.implicitHeight + 26
                    radius: 20
                    color: temaApp.panel
                    border.color: esCerrada
                                  ? "#70ef4444"
                                  : (esNueva || esActualizada ? "#6538bdf8" : temaApp.bordePanel)
                    border.width: 1

                    // Barra vertical izquierda según el color oficial DAE (Rojo = Cerrada, Azul = Nueva/Actualizada, Primario = Normal)
                    Rectangle {
                        id: barraColorSeccion
                        width: 4
                        height: parent.height - 24
                        radius: 2
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: esCerrada ? "#ef4444" : (esNueva || esActualizada ? "#38bdf8" : temaApp.primario)
                    }

                    ColumnLayout {
                        id: colInternaSeccion
                        anchors.left: barraColorSeccion.right
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        // Fila 1: Código + Sección + Pensum + Insignia (CERRADA / NUEVA)
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Rectangle {
                                Layout.preferredWidth: txtCodigoSec.implicitWidth + 10
                                Layout.preferredHeight: 20
                                radius: 6
                                color: esCerrada
                                       ? (temaApp.esClaro ? "#fee2e2" : "#3b151e")
                                       : (temaApp.esClaro ? temaApp.suave : Qt.rgba(temaApp.primario.r, temaApp.primario.g, temaApp.primario.b, 0.22))

                                Text {
                                    id: txtCodigoSec
                                    anchors.centerIn: parent
                                    text: modelData.codigo
                                    color: esCerrada
                                           ? (temaApp.esClaro ? "#b91c1c" : "#f87171")
                                           : (temaApp.esClaro ? temaApp.oscuro : temaApp.claro)
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: txtNumSec.implicitWidth + 10
                                Layout.preferredHeight: 20
                                radius: 6
                                color: temaApp.panelAlt
                                border.color: temaApp.bordeAlt

                                Text {
                                    id: txtNumSec
                                    anchors.centerIn: parent
                                    text: "Sec. " + modelData.sec
                                    color: temaApp.textoPrincipal
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: txtPensumTag.implicitWidth + 10
                                Layout.preferredHeight: 20
                                radius: 6
                                color: "transparent"
                                border.color: temaApp.bordeAlt

                                Text {
                                    id: txtPensumTag
                                    anchors.centerIn: parent
                                    text: "Pensum " + modelData.pensum
                                    color: temaApp.textoMuted
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Badge de estado (CERRADA / NUEVA / ACTUALIZADA / ABIERTA)
                            Rectangle {
                                Layout.preferredWidth: txtBadgeEst.implicitWidth + 12
                                Layout.preferredHeight: 20
                                radius: 10
                                color: esCerrada
                                       ? (temaApp.esClaro ? "#fee2e2" : "#3b151e")
                                       : (esNueva || esActualizada
                                          ? (temaApp.esClaro ? "#e0f2fe" : "#0f2942")
                                          : (temaApp.esClaro ? "#dcfce7" : "#163828"))
                                border.color: esCerrada ? "#ef4444" : (esNueva || esActualizada ? "#38bdf8" : "#22c55e")
                                border.width: 1

                                Text {
                                    id: txtBadgeEst
                                    anchors.centerIn: parent
                                    text: esCerrada ? "CERRADA" : (esNueva ? "NUEVA" : (esActualizada ? "ACTUALIZADA" : "ABIERTA"))
                                    color: esCerrada
                                           ? (temaApp.esClaro ? "#b91c1c" : "#f87171")
                                           : (esNueva || esActualizada
                                              ? (temaApp.esClaro ? "#0369a1" : "#38bdf8")
                                              : (temaApp.esClaro ? "#15803d" : "#4ade80"))
                                    font.pixelSize: 8
                                    font.bold: true
                                }
                            }
                        }

                        // Fila 2: Nombre de la Asignatura
                        Text {
                            text: modelData.nombre
                            color: esCerrada
                                   ? (temaApp.esClaro ? "#b91c1c" : "#fca5a5")
                                   : temaApp.textoPrincipal
                            font.pixelSize: 13
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        // Fila 3: Profesor Asignado (o Badge cuando sale PROF. NO ASIGNADO)
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            visible: modelData.profesor !== ""

                            Canvas {
                                Layout.preferredWidth: 14
                                Layout.preferredHeight: 14
                                property color colorTrazo: cardSeccion.sinProfAsignado
                                                           ? (temaApp.esClaro ? "#d97706" : "#fbbf24")
                                                           : temaApp.textoSecundario
                                onColorTrazoChanged: requestPaint()
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.reset();
                                    ctx.strokeStyle = colorTrazo;
                                    ctx.lineWidth = 1.5;
                                    ctx.beginPath();
                                    ctx.arc(7, 4.5, 2.5, 0, Math.PI * 2);
                                    ctx.stroke();
                                    ctx.beginPath();
                                    ctx.arc(7, 13, 4.5, Math.PI * 1.15, Math.PI * 1.85);
                                    ctx.stroke();
                                }
                            }

                            Text {
                                visible: !cardSeccion.sinProfAsignado
                                text: modelData.profesor
                                color: temaApp.textoSecundario
                                font.pixelSize: 11
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                visible: cardSeccion.sinProfAsignado
                                Layout.preferredWidth: txtSinProf.implicitWidth + 12
                                Layout.preferredHeight: 20
                                radius: 6
                                color: temaApp.esClaro ? "#fef3c7" : "#3b2a10"
                                border.color: "#f59e0b"
                                border.width: 1

                                Text {
                                    id: txtSinProf
                                    anchors.centerIn: parent
                                    text: "PROF. NO ASIGNADO"
                                    color: temaApp.esClaro ? "#b45309" : "#fde68a"
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                            }

                            Item {
                                visible: cardSeccion.sinProfAsignado
                                Layout.fillWidth: true
                            }
                        }

                        // Fila 4: Chips de Bloques Horarios y Aula (Flow responsivo para móviles)
                        Flow {
                            Layout.fillWidth: true
                            spacing: 6
                            visible: modelData.bloques.length > 0

                            Repeater {
                                model: modelData.bloques

                                delegate: Rectangle {
                                    width: txtBloqueAula.implicitWidth + 14
                                    height: 22
                                    radius: 7
                                    color: cardSeccion.esCerrada
                                           ? (temaApp.esClaro ? "#fef2f2" : "#2a1218")
                                           : (cardSeccion.esNueva || cardSeccion.esActualizada
                                              ? (temaApp.esClaro ? "#e0f2fe" : "#102a45")
                                              : temaApp.panelAlt)
                                    border.color: cardSeccion.esCerrada
                                                  ? "#ef4444"
                                                  : (cardSeccion.esNueva || cardSeccion.esActualizada ? "#38bdf8" : temaApp.bordeAlt)
                                    border.width: 1

                                    Text {
                                        id: txtBloqueAula
                                        anchors.centerIn: parent
                                        text: rootOfertaHorarios.formatearBloqueConEscuela(modelData)
                                        color: cardSeccion.esCerrada
                                               ? (temaApp.esClaro ? "#b91c1c" : "#fca5a5")
                                               : (cardSeccion.esNueva || cardSeccion.esActualizada
                                                  ? (temaApp.esClaro ? "#0369a1" : "#7dd3fc")
                                                  : temaApp.textoPrincipal)
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }
                            }
                        }

                        // Etiqueta cuando la materia no posee bloque de aula fijo (ej. Servicio Comunitario)
                        Text {
                            visible: modelData.bloques.length === 0
                            text: "Sin bloques de horario ni aula fija asignada"
                            color: temaApp.textoMuted
                            font.pixelSize: 10
                            font.italic: true
                        }
                    }
                }
            }

            // 6B. BOTÓN DE CARGA PROGRESIVA ("MOSTRAR MÁS HORARIOS") PARA EVITAR LENTITUD
            Rectangle {
                id: btnCargarMasHorarios
                visible: repOferta.count < rootOfertaHorarios.totalCoincidencias
                Layout.fillWidth: true
                Layout.maximumWidth: flickOferta.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.preferredHeight: 48
                radius: 18
                color: temaApp.vidrio
                border.color: temaApp.primario
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: "Mostrar más secciones (" + repOferta.count + " de " + rootOfertaHorarios.totalCoincidencias + ")"
                        color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Text {
                        text: "▼"
                        color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                        font.pixelSize: 10
                        font.bold: true
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: btnCargarMasHorarios.scale = 0.97
                    onReleased: btnCargarMasHorarios.scale = 1.0
                    onClicked: rootOfertaHorarios.limiteVisible += rootOfertaHorarios.pasoCarga
                }
                Behavior on scale { NumberAnimation { duration: 100 } }
            }

            // 7. PIE INSTITUCIONAL DAE
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: flickOferta.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.topMargin: 2
                Layout.preferredHeight: 46
                radius: 16
                color: temaApp.panelAlt
                border.color: temaApp.bordeAlt
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "COMISIÓN DE HORARIOS • FACULTAD DE INGENIERÍA UC"
                    color: temaApp.textoMuted
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 0.6
                }
            }
        }
    }
}
