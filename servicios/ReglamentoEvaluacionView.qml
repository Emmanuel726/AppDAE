import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts

Item {
    id: rootReglamento

    signal volver()

    // 0 = Todos los Títulos, 1..7 = Título I..VII
    property int tituloFiltro: 0
    property string textoBusqueda: ""

    property var listaTitulos: [
        {
            idTitulo: 1,
            romano: "Título I",
            subtitulo: "Disposiciones fundamentales",
            rango: "Art. 1 – 4",
            articulos: [
                {
                    num: "Artículo 1",
                    cap: "",
                    texto: "El presente Reglamento tiene como finalidad regular la evaluación del rendimiento académico de los estudiantes de la Facultad de Ingeniería de la Universidad de Carabobo.",
                    extra: ""
                },
                {
                    num: "Artículo 2",
                    cap: "",
                    texto: "De acuerdo con lo establecido en el Artículo 63 de la Ley Orgánica de Educación, la evaluación del rendimiento estudiantil en la Universidad de Carabobo es un proceso sistemático, continuo, cooperativo, ético y científico de valoración de logros en función de los objetivos propuestos en el diseño curricular de la Facultad.",
                    extra: ""
                },
                {
                    num: "Artículo 3",
                    cap: "",
                    texto: "Esta evaluación tiene como finalidad proporcionar evidencias válidas y confiables que permitan certificar el rendimiento del estudiante, determinar las causas de los resultados insatisfactorios y establecer la orientación necesaria para su mejoramiento.",
                    extra: ""
                },
                {
                    num: "Artículo 4",
                    cap: "",
                    texto: "Para determinar el rendimiento estudiantil se desarrollarán actividades de evaluación que utilicen procedimientos científicos acordes con la naturaleza de los objetivos propuestos. La Facultad, para lograr el cumplimiento de este propósito, debe desarrollar actividades de formación continua dirigidas al personal docente y de investigación.",
                    extra: ""
                }
            ]
        },
        {
            idTitulo: 2,
            romano: "Título II",
            subtitulo: "De la evaluación del proceso enseñanza - aprendizaje",
            rango: "Art. 5 – 7",
            articulos: [
                {
                    num: "Artículo 5",
                    cap: "",
                    texto: "Los exámenes y pruebas son los instrumentos para la evaluación del aprovechamiento del alumno. Estos instrumentos, sin menoscabo de las estrategias de orden metodológico, pautados en el Artículo 94 del Reglamento General de la Ley Orgánica de Educación, serán diseñados y realizados dentro del marco conceptual previsto en los Artículos 149 y 150 de la Ley de Universidades.",
                    extra: ""
                },
                {
                    num: "Artículo 6",
                    cap: "",
                    texto: "La evaluación del rendimiento académico debe ser diagnóstica, formativa, sumativa de característica integral y reforzante. Corresponde a la cátedra o a la unidad académica respectiva la integración de estos tipos de evaluación, en la aplicación de dicho proceso.",
                    extra: "Parágrafo Primero: La evaluación diagnóstica tendrá por finalidad identificar las aptitudes, conocimientos, habilidades, destrezas, intereses y motivaciones que posee el alumno para el logro de los objetivos del proceso de aprendizaje que ha de iniciar. El resultado de esta evaluación no se tomará en cuenta para calificar cuantitativamente al alumno.\n\nParágrafo Segundo: La evaluación formativa tendrá por finalidad determinar en qué medida se están logrando los objetivos programáticos.\n\nParágrafo Tercero: La evaluación sumativa tendrá por finalidad determinar el logro de los objetivos programáticos a los fines de calificar al alumno y orientar las decisiones procedentes por parte del profesor."
                },
                {
                    num: "Artículo 7",
                    cap: "",
                    texto: "La evaluación del rendimiento estudiantil se realizará a través de un Plan de Trabajo Docente donde se indiquen los objetivos específicos y los objetivos terminales, los contenidos programáticos, las actividades que debe desarrollar el alumno, las actividades y funciones que debe cumplir el profesor, el plan de evaluación propuesto con indicación de fechas, características y porcentajes, y los recursos didácticos a utilizar en cada actividad. La cátedra o la unidad académica respectiva será responsable de la formulación y ejecución del plan de trabajo docente y de su información a los estudiantes en la primera semana de clase.",
                    extra: ""
                }
            ]
        },
        {
            idTitulo: 3,
            romano: "Título III",
            subtitulo: "De las estrategias de evaluación",
            rango: "Art. 8 – 25",
            articulos: [
                {
                    num: "Artículo 8",
                    cap: "",
                    texto: "Las estrategias de evaluación se aplicarán mediante técnicas e instrumentos, tales como: pruebas escritas, orales o prácticas, pasantías, trabajos de investigación, exposiciones, informes, entrevistas y cualquier otra actividad que sirva para estos fines. Quedando a libre arbitrio de las cátedras o unidades académicas respectivas asignarle el peso relativo a cada una de las estrategias de evaluación.",
                    extra: ""
                },
                {
                    num: "Artículo 9",
                    cap: "Capítulo Primero: Del régimen de evaluación con exámenes parciales, evaluación complementaria y de recuperación durante el período lectivo",
                    texto: "La evaluación, a los efectos de este régimen, se cumplirá a través de evaluaciones parciales y complementarias y una evaluación de recuperación; a excepción de las asignaturas tales como laboratorio, talleres, seminarios o proyectos, las cuales se regirán por el régimen indicado en el Artículo 15.",
                    extra: "Parágrafo Primero: Para fines de evaluación, cada cátedra o unidad académica dividirá sus contenidos programáticos en por lo menos tres (3) secciones o cortes y cada sección tendrá una evaluación parcial y por lo menos una evaluación complementaria. Las evaluaciones parciales, las cuales deben ser acumulativas y reforzantes, determinarán el logro de los objetivos previstos en cada sección, la cual para fines de este reglamento, se denominará corte. Para tal fin, se aplicará por lo menos una de las estrategias de evaluación señaladas en el Artículo 8 del presente Reglamento.\nEl alumno, para tener derecho a presentar la evaluación parcial de una asignatura, debe asistir y cumplir por lo menos el 75% de las actividades académicas programadas durante el corte correspondiente.\n\nParágrafo Segundo: La evaluación de recuperación determinará el logro de todos los objetivos desarrollados en la asignatura."
                },
                {
                    num: "Artículo 10",
                    cap: "",
                    texto: "El alumno que por haber empleado algún mecanismo fraudulento perjudique la eficacia e integridad de la evaluación que le es aplicada será retirado de ésta y se le considerará aplazado con la nota mínima.",
                    extra: ""
                },
                {
                    num: "Artículo 11",
                    cap: "",
                    texto: "El profesor debe publicar el resultado de la evaluación parcial dentro de los cinco días hábiles después de su aplicación.",
                    extra: ""
                },
                {
                    num: "Artículo 12",
                    cap: "",
                    texto: "Los objetivos programados para cada asignatura deben ser alcanzados en su totalidad durante el período lectivo, y sobre ellos versará la evaluación de recuperación. La cátedra o la unidad académica respectiva velará por el estricto cumplimiento de esta disposición.",
                    extra: ""
                },
                {
                    num: "Artículo 13",
                    cap: "",
                    texto: "La calificación final de la asignatura durante un período lectivo se formará con un rango que oscile entre el 60 – 80% de las evaluaciones parciales y el porcentaje restante (20 – 40) a la evaluación complementaria. Quedando a libre arbitrio de cada una de las cátedras o unidades académicas asignarle el respectivo peso a cada una de las evaluaciones parciales y complementarias de cada corte.",
                    extra: "Parágrafo Único: Si la calificación final de la asignatura durante el período lectivo resultase superior o igual a diez (10) puntos enteros, ésta será considerada como la calificación definitiva. Si la calificación de la asignatura es mayor o igual a cinco (05) puntos enteros, la calificación definitiva será la obtenida en el examen de recuperación. Si la calificación final es menor a cinco (05) puntos enteros, la calificación definitiva será la calificación final."
                },
                {
                    num: "Artículo 14",
                    cap: "",
                    texto: "Aquellos alumnos que hayan obtenido calificaciones reprobatorias de cinco (05) o más puntos, de conformidad con el artículo anterior, tendrán derecho a una evaluación de recuperación. Esta evaluación de recuperación debe efectuarse dentro de los siete días hábiles siguientes a la publicación de la calificación final o a más tardar en la semana sucesiva, una vez finalizado el período de clases. La calificación obtenida en esta oportunidad será la calificación definitiva.",
                    extra: ""
                },
                {
                    num: "Artículo 15",
                    cap: "",
                    texto: "Las asignaturas de naturaleza práctica, como por ejemplo los laboratorios, seminarios, talleres, proyectos, etc. serán evaluados a través de un régimen de evaluación continua haciendo uso para tal fin de pruebas parciales, pruebas cortas, informes y/o cualquier otra de las estrategias de evaluación señalada en el Artículo 8 del presente reglamento que permita determinar el logro de los objetivos propuestos.",
                    extra: "Parágrafo Único: Aquellos alumnos que hayan sido reprobados en una asignatura de naturaleza práctica no tendrán derecho a examen de recuperación."
                },
                {
                    num: "Artículo 16",
                    cap: "",
                    texto: "La duración de cada período lectivo será de dieciocho (18) semanas de clases con una (1) semana para la evaluación de recuperación.",
                    extra: ""
                },
                {
                    num: "Artículo 17",
                    cap: "",
                    texto: "El alumno que después de concluidos los exámenes de recuperación resultare reprobado en una sola asignatura, por primera vez, y habiendo aprobado las tres cuartas (¾) partes de las asignaturas inscritas, tendrá derecho a cursar esa única materia en las condiciones de escolaridad que el Consejo de Facultad determine a solicitud de la cátedra o de la unidad académica respectiva.",
                    extra: ""
                },
                {
                    num: "Artículo 18",
                    cap: "",
                    texto: "El alumno que resultare aplazado en la asignatura a que hace referencia el Artículo anterior tendrá derecho a presentar la evaluación de recuperación de las asignaturas del curso inmediato superior que no estén preladas por esa materia.\n\nEl Consejo de Facultad o el Consejo de Escuela, según sea el caso, elaborará el calendario de exámenes para garantizar el cumplimiento de esta disposición.",
                    extra: ""
                },
                {
                    num: "Artículo 19",
                    cap: "",
                    texto: "El alumno, que no asista a las evaluaciones establecidas y no ejerza el derecho previsto en el Artículo 14 de este Reglamento, obtendrá la calificación de cero puntos en dicha evaluación.",
                    extra: ""
                },
                {
                    num: "Artículo 20",
                    cap: "Capítulo Segundo: Disposiciones generales al capítulo precedente",
                    texto: "El Consejo de Escuela o el Consejo de Facultad, según sea el caso, designará al jurado evaluador del examen de recuperación a petición de la cátedra o de la unidad académica respectiva. El jurado evaluador estará integrado por tres miembros principales y por tres suplentes. El profesor de la asignatura respectiva será uno de los miembros principales y le corresponderá presidir dicho jurado. Para dar inicio a la evaluación de recuperación deben estar presentes todos los miembros principales o los suplentes respectivos.",
                    extra: "Parágrafo Único: El jurado evaluador designado debe publicarse en la cartelera de la Escuela respectiva."
                },
                {
                    num: "Artículo 21",
                    cap: "",
                    texto: "El jurado evaluador publicará el resultado de la evaluación practicada dentro de los cinco días hábiles siguientes a la fecha de su realización.",
                    extra: ""
                },
                {
                    num: "Artículo 22",
                    cap: "",
                    texto: "El resultado definitivo de la evaluación de recuperación se hará constar en el Acta que será levantada para tal efecto. Esta Acta debe ser firmada por la totalidad de los miembros del jurado evaluador que hayan intervenido en el referido acto y será consignada en la oficina local de Control de Estudios dentro de un lapso no menor de tres días hábiles ni mayor de siete, a criterio del respectivo Consejo de Facultad.",
                    extra: ""
                },
                {
                    num: "Artículo 23",
                    cap: "",
                    texto: "El alumno que irrespete de palabra o de hecho a cualquier miembro del jurado evaluador, o que de cualquier forma altere la marcha normal de la evaluación, o que menoscabe su seriedad, será sancionado de conformidad con lo establecido en la Ley de Universidades.",
                    extra: ""
                },
                {
                    num: "Artículo 24",
                    cap: "",
                    texto: "Todo miembro del personal docente y de investigación que haya sido designado como jurado evaluador debe asistir obligatoriamente a las evaluaciones para las cuales fue designado.",
                    extra: ""
                },
                {
                    num: "Artículo 25",
                    cap: "",
                    texto: "El jurado evaluador, actuando como cuerpo colegiado, es absolutamente responsable de la evaluación de recuperación que le haya sido encomendada, el veredicto del jurado que se derive de una evaluación de recuperación es inapelable sin menoscabo del derecho de revisión previsto en el Título V de este Reglamento.",
                    extra: ""
                }
            ]
        },
        {
            idTitulo: 4,
            romano: "Título IV",
            subtitulo: "Del régimen de evaluación de suficiencia",
            rango: "Art. 26 – 30",
            articulos: [
                {
                    num: "Artículo 26",
                    cap: "",
                    texto: "El Consejo de Facultad determinará las asignaturas en las que, sin escolaridad previa, puede concederse la aplicación de una prueba única de suficiencia.",
                    extra: ""
                },
                {
                    num: "Artículo 27",
                    cap: "",
                    texto: "Hecha la determinación, el alumno regular, dentro de los diez días siguientes al inicio del período lectivo, podrá solicitar formalmente al Consejo de Facultad la aplicación de la prueba única de suficiencia en cualquiera de las asignaturas previamente autorizadas.",
                    extra: "Parágrafo Único: Durante toda la permanencia del alumno en la Universidad de Carabobo el Consejo de Facultad concederá en una sola oportunidad la aplicación de la prueba de suficiencia en una misma asignatura."
                },
                {
                    num: "Artículo 28",
                    cap: "",
                    texto: "Al finalizar el lapso previsto en el encabezamiento del Artículo anterior el Consejo de Facultad, a proposición de la cátedra o de la unidad académica respectiva, designará al jurado evaluador, fijando, además, la fecha, la hora y el lugar en que será aplicada la prueba única de suficiencia.",
                    extra: ""
                },
                {
                    num: "Artículo 29",
                    cap: "",
                    texto: "Todos los objetivos programados en la asignatura deben ser evaluados en la prueba única de suficiencia.",
                    extra: ""
                },
                {
                    num: "Artículo 30",
                    cap: "",
                    texto: "La calificación mínima aprobatoria de la asignatura examinada mediante la prueba única de suficiencia será de doce puntos.\n\nEl alumno que apruebe esta evaluación queda exonerado de cursar dicha asignatura.",
                    extra: ""
                }
            ]
        },
        {
            idTitulo: 5,
            romano: "Título V",
            subtitulo: "De la revisión de los exámenes",
            rango: "Art. 31 – 34",
            articulos: [
                {
                    num: "Artículo 31",
                    cap: "",
                    texto: "Todo estudiante tiene el derecho de conocer la forma como será evaluado. Igualmente debe ser informado de cómo serán corregidas sus evaluaciones. También debe ser enterado de los errores que hayan cometido con el fin de que aplique los correctivos que conduzcan a su éxito escolar.",
                    extra: ""
                },
                {
                    num: "Artículo 32",
                    cap: "",
                    texto: "El profesor o el jurado evaluador, según sea el caso, está obligado a revisar la prueba escrita que haya aplicado. Para tal fin, el profesor o el jurado evaluador utilizará una de las siguientes modalidades:",
                    extra: "a.- En la oportunidad previamente indicada el profesor de la asignatura o el jurado evaluador, según sea el caso, devolverá a cada estudiante la prueba escrita corregida, sometiéndola de inmediato a su discusión y análisis. Al concluir la revisión, las pruebas podrán ser recogidas de nuevo para ser conservadas en el archivo destinado al efecto.\n\nb.- El profesor de la asignatura o el jurado evaluador, según sea el caso, publicará las calificaciones obtenidas por todos los alumnos conjuntamente con la solución del examen aplicado y fijará la fecha y la hora en la que los estudiantes interesados podrán participar en la revisión de sus pruebas.\n\nc.- El profesor de la asignatura o el jurado evaluador, según sea el caso, podrá realizar la revisión de la prueba en un cubículo previamente señalado. Esta revisión se realizará fuera del horario de clases, en la fecha y en la hora indicada en la cartelera de la Escuela respectiva.\n\nd.- Cualquiera otra modalidad especial prevista en la normativa interna de cada Facultad."
                },
                {
                    num: "Artículo 33",
                    cap: "",
                    texto: "Al inicio del período académico la cátedra o la unidad académica respectiva, por órgano del profesor de la Asignatura, informará a los estudiantes la modalidad escogida para la revisión de las evaluaciones parciales. En el caso de la evaluación de recuperación la modalidad seleccionada será informada en el momento de la apertura de la evaluación.",
                    extra: ""
                },
                {
                    num: "Artículo 34",
                    cap: "",
                    texto: "Cuando un profesor no dé cumplimiento oportuno a lo establecido en las normas precedentes el alumno afectado debe notificarlo al Jefe de la Cátedra o del Departamento o, en su defecto al director de la Escuela o del Ciclo Básico, según sea el caso, quien inmediatamente debe informarle al profesor el contenido de este título y la necesidad de su obligatoria aplicación.\n\nSi el profesor incumple definitivamente lo establecido en estas disposiciones reglamentarias, su conducta será considerada como un acto de indisciplina. En este caso el Consejo de Facultad recabará la información pertinente para la aplicación de la sanción prevista en la Ley de Universidades.",
                    extra: ""
                }
            ]
        },
        {
            idTitulo: 6,
            romano: "Título VI",
            subtitulo: "Disposiciones transitorias",
            rango: "Art. 35 – 36",
            articulos: [
                {
                    num: "Artículo 35",
                    cap: "",
                    texto: "Este régimen de evaluación será aplicado, desde el inicio del semestre posterior a la fecha de su aprobación.",
                    extra: ""
                },
                {
                    num: "Artículo 36",
                    cap: "",
                    texto: "El período de tiempo previsto en el Artículo 14 de este Reglamento, para la evaluación de recuperación, podrá ser modificado por el Consejo de Facultad cuando el tiempo señalado en estas disposiciones sea insuficiente para la realización de la mencionada evaluación.",
                    extra: ""
                }
            ]
        },
        {
            idTitulo: 7,
            romano: "Título VII",
            subtitulo: "Disposiciones finales",
            rango: "Art. 37 – 40",
            articulos: [
                {
                    num: "Artículo 37",
                    cap: "",
                    texto: "A los efectos de este Reglamento los términos o plazos se contarán siempre a partir del día hábil siguiente de aquel en que tenga lugar la publicación o notificación de un acto. Los términos o plazos que hayan sido establecidos por días se computarán por días hábiles, salvo disposición en contrario. Se entiende por días hábiles los días laborables previstos en el calendario de la Universidad de Carabobo.",
                    extra: ""
                },
                {
                    num: "Artículo 38",
                    cap: "",
                    texto: "El Consejo de Facultad dictará las normas internas que faciliten la operatividad de las disposiciones contenidas en este Reglamento. En todo caso, las normas internas de la Facultad no deben contrariar el espíritu, propósito y razón de este Reglamento. Si así ocurriese, las normas internas de la Facultad no producirán ningún efecto.",
                    extra: ""
                },
                {
                    num: "Artículo 39",
                    cap: "",
                    texto: "Los casos dudosos o no previstos en este Reglamento serán resueltos por el Consejo de Facultad.",
                    extra: ""
                },
                {
                    num: "Artículo 40",
                    cap: "",
                    texto: "Este reglamento deroga el Reglamento de Evaluación de los alumnos de la Facultad de Ingeniería de la Universidad de Carabobo, en el mes de noviembre de mil novecientos noventa y ocho.",
                    extra: ""
                }
            ]
        }
    ]

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

    function obtenerTitulosFiltrados() {
        var busq = normalizarTextoBusqueda(textoBusqueda);
        var resultado = [];

        for (var i = 0; i < listaTitulos.length; i++) {
            var tit = listaTitulos[i];
            if (tituloFiltro !== 0 && tit.idTitulo !== tituloFiltro) continue;

            var artsFiltrados = [];
            for (var j = 0; j < tit.articulos.length; j++) {
                var art = tit.articulos[j];
                if (busq !== "") {
                    var textoArt = (art.num || "") + " " + (art.texto || "") + " " + (art.extra || "") + " " + (art.cap || "") + " " + (tit.romano || "") + " " + (tit.subtitulo || "");
                    if (!coincideBusqueda(textoArt, busq)) continue;
                }
                artsFiltrados.push(art);
            }

            if (artsFiltrados.length > 0) {
                resultado.push({
                    idTitulo: tit.idTitulo,
                    romano: tit.romano,
                    subtitulo: tit.subtitulo,
                    rango: tit.rango,
                    articulos: artsFiltrados
                });
            }
        }
        return resultado;
    }

    Flickable {
        id: flickReglamento
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
                id: timerTecladoReglamento
                interval: 280
                onTriggered: {
                    flickReglamento.restaurarPosicion();
                }
            }
        }

        // Cuando el teclado se cierra, Qt deja el contenido corrido:
        // se devuelve a la posición en la que estaba el usuario.
        Connections {
            target: daeClient
            function onTecladoVisibleChanged() {
                if (!daeClient.tecladoVisible) {
                    flickReglamento.restaurarPosicion();
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
        contentHeight: colReglamento.implicitHeight + 135
        clip: true

        ColumnLayout {
            id: colReglamento
            width: flickReglamento.width
            spacing: 14

            // =================================================================
            // 1. CABECERA CON BOTÓN DE REGRESO
            // =================================================================
            RowLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: flickReglamento.width - 40
                Layout.topMargin: 24
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 10

                Rectangle {
                    id: btnVolverReg
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
                        onPressed: btnVolverReg.scale = 0.90
                        onReleased: btnVolverReg.scale = 1.0
                        onClicked: rootReglamento.volver()
                    }
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    spacing: 1
                    Text {
                        Layout.fillWidth: true
                        text: "Reglamento de Evaluación"
                        color: temaApp.textoPrincipal
                        font.pixelSize: 19
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "FACULTAD DE INGENIERÍA • UNIVERSIDAD DE CARABOBO"
                        color: temaApp.esClaro ? temaApp.primario : temaApp.acento
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 0.7
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
                        text: "40 Arts."
                        color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
            }

            // =================================================================
            // 2. RESUMEN RÁPIDO DE CRITERIOS CLAVE DEL REGLAMENTO
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: flickReglamento.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                implicitHeight: colClavesReg.implicitHeight + 24
                radius: 22
                color: temaApp.panel
                border.color: temaApp.bordePanel
                border.width: 1

                ColumnLayout {
                    id: colClavesReg
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            Layout.fillWidth: true
                            text: "Puntos Clave para el Estudiante"
                            color: temaApp.textoPrincipal
                            font.pixelSize: 13
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "Toca para ir al artículo"
                            color: temaApp.textoMuted
                            font.pixelSize: 10
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        rowSpacing: 6
                        columnSpacing: 6

                        Repeater {
                            model: [
                                { valor: "≥ 10 pts", etq: "Aprobatoria",    art: "Artículo 13", tit: 3 },
                                { valor: "≥ 05 pts", etq: "Recuperación",   art: "Artículo 14", tit: 3 },
                                { valor: "75% mín.", etq: "Asistencia",     art: "Artículo 9",  tit: 3 },
                                { valor: "60–80%",   etq: "Peso Parciales", art: "Artículo 13", tit: 3 },
                                { valor: "5 días",   etq: "Publicar Nota",  art: "Artículo 11", tit: 3 },
                                { valor: "≥ 12 pts", etq: "Suficiencia",    art: "Artículo 30", tit: 4 }
                            ]

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 48
                                radius: 12
                                color: temaApp.panelAlt
                                border.color: temaApp.bordeAlt
                                border.width: 1

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 1

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.valor
                                        color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                                        font.pixelSize: 12
                                        font.bold: true
                                    }

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.etq
                                        color: temaApp.textoSecundario
                                        font.pixelSize: 9
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        rootReglamento.tituloFiltro = 0
                                        inputBusquedaReg.text = modelData.art
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =================================================================
            // 3. BUSCADOR POR ARTÍCULO O PALABRA CLAVE
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.maximumWidth: flickReglamento.width - 40
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                height: 42
                radius: 14
                color: temaApp.panel
                border.color: inputBusquedaReg.activeFocus ? temaApp.primario : temaApp.bordePanel
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
                        id: inputBusquedaReg
                        Layout.fillWidth: true
                        color: temaApp.textoPrincipal
                        font.pixelSize: 12
                        clip: true
                        onTextChanged: rootReglamento.textoBusqueda = text

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Buscar artículo (ej. Artículo 13, recuperación, revisión...)"
                            color: temaApp.textoMuted
                            font.pixelSize: 11
                            visible: !inputBusquedaReg.text && !inputBusquedaReg.activeFocus
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        visible: inputBusquedaReg.text.length > 0
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
                            onClicked: inputBusquedaReg.text = ""
                        }
                    }
                }
            }

            // =================================================================
            // 4. PÍLDORAS DE NAVEGACIÓN POR TÍTULO (I AL VII)
            // =================================================================
            Flickable {
                Layout.fillWidth: true
                Layout.maximumWidth: flickReglamento.width
                height: 34
                contentWidth: rowTitulosPills.implicitWidth + 40
                contentHeight: 34
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Row {
                    id: rowTitulosPills
                    x: 20
                    spacing: 6

                    Repeater {
                        model: [
                            { idTit: 0, label: "Todos (40)" },
                            { idTit: 1, label: "Título I (1–4)" },
                            { idTit: 2, label: "Título II (5–7)" },
                            { idTit: 3, label: "Título III (8–25)" },
                            { idTit: 4, label: "Título IV (26–30)" },
                            { idTit: 5, label: "Título V (31–34)" },
                            { idTit: 6, label: "Título VI (35–36)" },
                            { idTit: 7, label: "Título VII (37–40)" }
                        ]

                        delegate: Rectangle {
                            width: txtTitPill.implicitWidth + 22
                            height: 32
                            radius: 16
                            color: rootReglamento.tituloFiltro === modelData.idTit
                                   ? temaApp.primario
                                   : temaApp.panel
                            border.color: rootReglamento.tituloFiltro === modelData.idTit
                                          ? temaApp.acento
                                          : temaApp.bordePanel
                            border.width: 1

                            Text {
                                id: txtTitPill
                                anchors.centerIn: parent
                                text: modelData.label
                                color: rootReglamento.tituloFiltro === modelData.idTit
                                       ? "white"
                                       : temaApp.textoSecundario
                                font.pixelSize: 11
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: rootReglamento.tituloFiltro = modelData.idTit
                            }
                        }
                    }
                }
            }

            // =================================================================
            // 5. LISTADO DE TÍTULOS, CAPÍTULOS, ARTÍCULOS Y PARÁGRAFOS
            // =================================================================
            Repeater {
                model: rootReglamento.obtenerTitulosFiltrados()

                delegate: Rectangle {
                    id: cardTitulo
                    Layout.fillWidth: true
                    Layout.maximumWidth: flickReglamento.width - 40
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    implicitHeight: colTitulo.implicitHeight + 24
                    radius: 22
                    color: temaApp.panel
                    border.color: temaApp.bordePanel
                    border.width: 1

                    property var datosTitulo: modelData

                    ColumnLayout {
                        id: colTitulo
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        // Cabecera del Título (I .. VII)
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: colHeaderTit.implicitHeight + 18
                            radius: 14
                            color: temaApp.esClaro
                                   ? Qt.rgba(temaApp.primario.r, temaApp.primario.g, temaApp.primario.b, 0.12)
                                   : Qt.rgba(temaApp.primario.r, temaApp.primario.g, temaApp.primario.b, 0.24)
                            border.color: temaApp.primario
                            border.width: 1

                            ColumnLayout {
                                id: colHeaderTit
                                anchors.fill: parent
                                anchors.margins: 9
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Text {
                                        Layout.fillWidth: true
                                        text: cardTitulo.datosTitulo.romano.toUpperCase()
                                        color: temaApp.esClaro ? temaApp.primario : temaApp.claro
                                        font.pixelSize: 11
                                        font.bold: true
                                        font.letterSpacing: 0.8
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: txtRangoArts.implicitWidth + 12
                                        Layout.preferredHeight: 18
                                        radius: 9
                                        color: temaApp.panel

                                        Text {
                                            id: txtRangoArts
                                            anchors.centerIn: parent
                                            text: cardTitulo.datosTitulo.rango
                                            color: temaApp.textoSecundario
                                            font.pixelSize: 9
                                            font.bold: true
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: cardTitulo.datosTitulo.subtitulo
                                    color: temaApp.textoPrincipal
                                    font.pixelSize: 14
                                    font.bold: true
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        // Artículos dentro del Título
                        Repeater {
                            model: cardTitulo.datosTitulo.articulos

                            delegate: ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                // Separador de Capítulo cuando aplica (Capítulo Primero / Capítulo Segundo en Título III)
                                Rectangle {
                                    Layout.fillWidth: true
                                    visible: modelData.cap !== ""
                                    implicitHeight: txtCapBanner.implicitHeight + 16
                                    radius: 10
                                    color: temaApp.esClaro ? "#FEF3C7" : "#451A03"
                                    border.color: "#F59E0B"
                                    border.width: 1

                                    Text {
                                        id: txtCapBanner
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        text: modelData.cap
                                        color: temaApp.esClaro ? "#B45309" : "#FCD34D"
                                        font.pixelSize: 11
                                        font.bold: true
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                // Tarjeta individual del Artículo
                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: colArticulo.implicitHeight + 22
                                    radius: 15
                                    color: temaApp.panelAlt
                                    border.color: temaApp.bordeAlt
                                    border.width: 1

                                    ColumnLayout {
                                        id: colArticulo
                                        anchors.fill: parent
                                        anchors.margins: 11
                                        spacing: 8

                                        // Etiqueta del Artículo
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            Rectangle {
                                                Layout.preferredWidth: txtNumArt.implicitWidth + 14
                                                Layout.preferredHeight: 22
                                                radius: 7
                                                color: temaApp.primario

                                                Text {
                                                    id: txtNumArt
                                                    anchors.centerIn: parent
                                                    text: modelData.num
                                                    color: "white"
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                }
                                            }

                                            Item { Layout.fillWidth: true }
                                        }

                                        // Texto principal del Artículo
                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.texto
                                            color: temaApp.textoPrincipal
                                            font.pixelSize: 12
                                            lineHeight: 1.28
                                            wrapMode: Text.WordWrap
                                        }

                                        // Bloque de Parágrafos o Literales (si existen)
                                        Rectangle {
                                            Layout.fillWidth: true
                                            visible: modelData.extra !== ""
                                            implicitHeight: txtExtraParagrafo.implicitHeight + 18
                                            radius: 11
                                            color: temaApp.panel
                                            border.color: temaApp.bordePanel
                                            border.width: 1

                                            Text {
                                                id: txtExtraParagrafo
                                                anchors.fill: parent
                                                anchors.margins: 9
                                                text: modelData.extra
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
                }
            }
        }
    }
}
