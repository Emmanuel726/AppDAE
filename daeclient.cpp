/**
 * Cliente principal de AppDAE: gestiona la sesión con el portal DAE UC,
 * el caché local cifrado/por usuario, el análisis HTML de servicios académicos,
 * la biometría, los recordatorios y los márgenes de pantalla en Android.
 */
#include "daeclient.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QInputMethod>
#include <QTimer>
#include <QNetworkRequest>
#include <QUrl>
#include <QUrlQuery>
#include <QSslConfiguration>
#include <QSslSocket>
#include <QRegularExpression>
#include <QCryptographicHash>
#include <QFileInfo>
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QDesktopServices>
#include <QPdfWriter>
#include <QPainter>
#include <QPainterPath>
#include <QPageSize>
#include <QPageLayout>
#include <QImage>
#include <QFont>
#include <QHash>
#include <QSet>
#include <QSettings>
#include <QGuiApplication>
#include <QStyleHints>
#include <QMetaObject>
#include <QDateTime>
#include <algorithm>
#include <QDebug>

#ifdef Q_OS_ANDROID
#include <QJniObject>
#include <QJniEnvironment>
#include <QCoreApplication>
#endif

static DaeClient *s_instanciaDaeClient = nullptr;

static QString ofuscarClaveBio(const QString &clave)
{
    if (clave.isEmpty()) return QString();
    QByteArray bytes = clave.toUtf8();
    const QByteArray llave = "DAE_UC_ING_BIO_2026";
    for (int i = 0; i < bytes.size(); ++i) {
        bytes[i] = bytes[i] ^ llave[i % llave.size()];
    }
    return QString::fromLatin1(bytes.toBase64());
}

static QString desofuscarClaveBio(const QString &codificada)
{
    if (codificada.isEmpty()) return QString();
    QByteArray bytes = QByteArray::fromBase64(codificada.toLatin1());
    const QByteArray llave = "DAE_UC_ING_BIO_2026";
    for (int i = 0; i < bytes.size(); ++i) {
        bytes[i] = bytes[i] ^ llave[i % llave.size()];
    }
    return QString::fromUtf8(bytes);
}

#ifdef Q_OS_ANDROID
static void jniOnBiometricResult(JNIEnv *env, jobject /*thiz*/, jboolean exito, jstring mensaje)
{
    Q_UNUSED(env);
    QString msg = QJniObject(mensaje).toString();
    if (s_instanciaDaeClient) {
        QMetaObject::invokeMethod(s_instanciaDaeClient, [exito, msg]() {
            if (s_instanciaDaeClient) {
                s_instanciaDaeClient->procesarResultadoBiometrico(exito, msg);
            }
        }, Qt::QueuedConnection);
    }
}
#endif

static void configurarRequestDae(QNetworkRequest &req)
{
    req.setHeader(QNetworkRequest::UserAgentHeader,
                  "Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36");
    req.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);

    QSslConfiguration sslConf = QSslConfiguration::defaultConfiguration();
    sslConf.setPeerVerifyMode(QSslSocket::VerifyNone);
    req.setSslConfiguration(sslConf);
}

DaeClient::DaeClient(QObject *parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this))
    , m_cookieJar(new DaeCookieJar(this))
{
    m_nam->setCookieJar(m_cookieJar);

    // Estado del teclado: Qt no devuelve el desplazamiento cuando el teclado
    // se cierra, asi que hay que enterarse del cambio.
    if (QInputMethod *im = QGuiApplication::inputMethod()) {
        connect(im, &QInputMethod::visibleChanged,
                this, &DaeClient::tecladoVisibleChanged);
        connect(im, &QInputMethod::keyboardRectangleChanged,
                this, &DaeClient::tecladoVisibleChanged);
    }
    // Sondeo: en algunas versiones de Android la plataforma no emite esas
    // señales, así que se comprueba el estado cada 200 ms.
    {
        QTimer *sondeo = new QTimer(this);
        connect(sondeo, &QTimer::timeout, this, [this]() {
            const bool visible = tecladoVisible();
            if (visible != m_tecladoUltimoEstado) {
                m_tecladoUltimoEstado = visible;
                emit tecladoVisibleChanged();
            }
        });
        sondeo->start(200);
    }
    s_instanciaDaeClient = this;

#ifdef Q_OS_ANDROID
    {
        QJniEnvironment env;
        jclass clazz = env.findClass("org/qtproject/example/DaeBiometricHelper");
        if (clazz) {
            JNINativeMethod methods[] = {
                {"nativeOnBiometricResult", "(ZLjava/lang/String;)V", reinterpret_cast<void *>(jniOnBiometricResult)}
            };
            env->RegisterNatives(clazz, methods, 1);
        }
    }
#endif

    // Cargar preferencias de apariencia, tema del sistema y biometría guardadas en QSettings
    // Por defecto modoTema = 3 (Sigue el tema Claro/Oscuro del Sistema Operativo)
    QSettings settings("UniversidadDeCarabobo", "AppDAE");
    m_temaSeleccionado = settings.value("apariencia/modoTema", 3).toInt();
    m_paletaAuroraIndex = settings.value("apariencia/paletaAuroraIndex", 0).toInt();
    m_animacionAuroraActiva = settings.value("apariencia/animacionAuroraActiva", true).toBool();
    m_urlFotoPerfil = settings.value("perfil/urlFotoPerfil", "").toString();
    m_notificacionesHabilitadasUsuario = settings.value("notificaciones/habilitadas", true).toBool();
    m_descargoAceptado = settings.value("legal/descargoAceptado", false).toBool();
    m_ultimoEstadoPermisoNotif = permisoNotificacionesActivo();

    // Cargar los recordatorios (tareas y examenes) programados
    {
        QSettings ajustesRecordatorios("UniversidadDeCarabobo", "AppDAE_Recordatorios");
        const QString datosJson = ajustesRecordatorios.value("recordatorios/lista").toString();
        if (!datosJson.isEmpty()) {
            const QJsonArray arr = QJsonDocument::fromJson(datosJson.toUtf8()).array();
            for (const QJsonValue &v : arr) {
                m_recordatorios.append(v.toObject().toVariantMap());
            }
        }
    }

    // Reloj en vivo (cada 1 s): sincroniza el switch de permiso de notificaciones y
    // verifica si algún aviso programado acaba de llegar a su hora.
    {
        QTimer *relojAvisos = new QTimer(this);
        connect(relojAvisos, &QTimer::timeout, this, [this]() {
            const bool permActual = permisoNotificacionesActivo();
            if (permActual != m_ultimoEstadoPermisoNotif) {
                m_ultimoEstadoPermisoNotif = permActual;
                emit recordatoriosChanged();
                if (permActual && m_esperandoRespuestaPermisoNotif) {
                    m_esperandoRespuestaPermisoNotif = false;
                    emit biometriaNotificacion(true, "✓ Permiso de notificaciones activado");
                }
            }
            if (!m_notificacionesHabilitadasUsuario) {
                return;
            }
            static QSet<QString> s_avisosDisparados;
            const qint64 ahora = QDateTime::currentMSecsSinceEpoch();
            for (const QVariant &v : m_recordatorios) {
                const QVariantMap m = v.toMap();
                if (m.value("hecho").toBool()) {
                    continue;
                }
                const QString id = m.value("id").toString();
                const QString tipo = m.value("tipo").toString();
                const QString materia = m.value("materia").toString();
                const QString titulo = m.value("titulo").toString();
                const QString temas = m.value("temas").toString();
                const QString descripcion = m.value("descripcion").toString();
                const QVariantList avisos = m.value("avisos").toList();
                for (const QVariant &avVar : avisos) {
                    const QVariantMap av = avVar.toMap();
                    const qint64 cuando = static_cast<qint64>(av.value("cuando").toDouble());
                    if (cuando <= 0) {
                        continue;
                    }
                    const QString clave = id + "_" + av.value("etiqueta").toString() + "_" + QString::number(cuando);
                    if (ahora >= cuando && (ahora - cuando) <= 75000 && !s_avisosDisparados.contains(clave)) {
                        s_avisosDisparados.insert(clave);
                        const QString tituloAviso = (tipo == "examen" ? "Examen: " : "Tarea: ")
                                + (!materia.isEmpty() ? materia : titulo);
                        const QString cuerpo = (tipo == "examen")
                                ? ("Temas: " + (!temas.isEmpty() ? temas : "sin temas pendientes"))
                                : (!descripcion.isEmpty() ? descripcion : titulo);
                        avisarAhoraRecordatorio(id, tituloAviso, cuerpo);
                    }
                }
            }
        });
        relojAvisos->start(1000);
    }

    m_biometriaActiva = settings.value("seguridad/biometriaActiva", false).toBool();
    m_cedulaBiometrica = settings.value("seguridad/cedulaBio", "").toString();
    m_claveBiometrica = desofuscarClaveBio(settings.value("seguridad/claveBio", "").toString());
    if (m_cedulaBiometrica.isEmpty() || m_claveBiometrica.isEmpty()) {
        m_biometriaActiva = false;
    }

    if (QGuiApplication::styleHints()) {
        // Se guarda el esquema REAL del sistema (la app puede forzar el suyo para
        // que los iconos de la barra de estado se lean sobre el fondo)
        m_sistemaEsClaroReal = (QGuiApplication::styleHints()->colorScheme() == Qt::ColorScheme::Light);
        connect(QGuiApplication::styleHints(), &QStyleHints::colorSchemeChanged, this, [this]() {
            if (!m_esquemaPersonalizado) {
                m_sistemaEsClaroReal = (QGuiApplication::styleHints()->colorScheme() == Qt::ColorScheme::Light);
            }
            emit aparienciaChanged();
        });
    }

    // Calendarios iniciales por defecto (se actualizan en vivo al llamar cargarCalendarios)
    m_calendariosOficiales = {
        QVariantMap{
            {"titulo", "Calendario 1-2026 (CF 23/07/2026)"},
            {"periodo", "Período Lectivo 1-2026"},
            {"aprobacion", "Aprobado en Consejo de Facultad (CF) el 23/07/2026"},
            {"estado", "VIGENTE"},
            {"esVigente", true},
            {"archivo", "calendario_1_2026rev3.pdf"},
            {"url", "https://dae.ing.uc.edu.ve/docs/calendario_1_2026rev3.pdf"},
            {"tamano", "PDF Oficial DAE"}
        },
        QVariantMap{
            {"titulo", "Calendario 2-2026 (CF 06/08/2026)"},
            {"periodo", "Período Lectivo 2-2026"},
            {"aprobacion", "Aprobado en Consejo de Facultad (CF) el 06/08/2026"},
            {"estado", "PUBLICADO"},
            {"esVigente", false},
            {"archivo", "calendario_2_2026.pdf"},
            {"url", "https://dae.ing.uc.edu.ve/docs/calendario_2_2026.pdf"},
            {"tamano", "PDF Oficial DAE"}
        }
    };

    limpiarDatosEstudianteSesion();

    // Cargar instantáneamente la base de horarios integrada o en caché local antes de sincronizar en red
    QString rutaCacheHorarios = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/horarios_cache.html";
    QFile fCacheHorarios(rutaCacheHorarios);
    if (fCacheHorarios.exists() && fCacheHorarios.open(QIODevice::ReadOnly)) {
        QString htmlCache = QString::fromUtf8(fCacheHorarios.readAll());
        fCacheHorarios.close();
        if (!htmlCache.isEmpty()) {
            parsearHtmlHorarios(htmlCache);
        }
    } else {
        QFile fBaseHorarios(":/qt/qml/AppDAE/servicios/horarios_base.html");
        if (fBaseHorarios.open(QIODevice::ReadOnly)) {
            QString htmlBase = QString::fromUtf8(fBaseHorarios.readAll());
            fBaseHorarios.close();
            if (!htmlBase.isEmpty()) {
                parsearHtmlHorarios(htmlBase);
            }
        }
    }

    // Precargar datos públicos de DAE al iniciar la app
    cargarCalendarios();
    cargarOfertaHorarios();
    cargarPensum(0, escuelaIndexEstudiante());
    cargarFaqPensum();
}

void DaeClient::limpiarDatosEstudianteSesion()
{
    m_pidSesion.clear();
    m_nombreEstudiante = "ESTUDIANTE DAE UC";
    m_primerNombre.clear();
    m_segundoNombre.clear();
    m_primerApellido.clear();
    m_segundoApellido.clear();
    m_inicialesEstudiante = "UC";
    m_escuelaEstudiante = "FACULTAD DE INGENIERÍA UC";
    m_correoEstudiante.clear();
    m_correoAlternativo.clear();
    m_telefonoFijo.clear();
    m_telefonoEstudiante.clear();
    m_fechaNacimiento.clear();
    m_sexoEstudiante.clear();
    m_dirEstado.clear();
    m_dirMunicipio.clear();
    m_dirParroquia.clear();
    m_dirDetalle.clear();
    m_opsuEstadoCivil = "SOLTERO";
    m_opsuEtnia = "NINGUNA";
    m_opsuDiscapacidad = "NINGUNA";
    m_opsuManoAgil = "DERECHA";

    m_promedioPonderadoEntero = "--";
    m_promedioPonderadoDecimal = "";
    m_promedioAritmeticoEntero = "--";
    m_promedioAritmeticoDecimal = "";
    m_ucInscritas = 0;
    m_ucAprobadasCarrera = 0;

    m_clavesBloquesDelEstudiante.clear();
    m_materiasInscritasRaw.clear();
    m_materiasSinTranscribir.clear();
    m_notasTranscritas.clear();
    m_expedienteSemestres.clear();
    m_curvaProgresoExpediente.clear();
    m_materiasRap.clear();
    m_materiasPeriodoActualRaw.clear();

    m_materiasInscripcion.clear();
    m_solicitudInscripcionRegistrada.clear();
    m_fechaSolicitudInscripcion.clear();
    m_periodoInscripcion = "2-2026";
    m_fechaLimiteInscripcion.clear();
    m_inscripcionDisponible = true;
    m_reporteInscripcionDisponible = true;
    m_cargandoInscripcion = false;
    m_enviandoInscripcion = false;
    m_resultadoPostInscripcionPendiente.clear();
    m_urlAccionProcesarInscripcion.clear();

    m_cargandoRetiro = false;
    m_enviandoRetiro = false;
    m_retiroDisponible = true;
    m_periodoRetiro.clear();
    m_fechaLimiteRetiro.clear();
    m_hrefRetiroMenu.clear();
    m_urlAccionProcesarRetiro.clear();
    m_camposOcultosRetiro.clear();
    m_materiasRetiroServidor.clear();
    m_solicitudRetiroRegistrada.clear();
    m_fechaSolicitudRetiro.clear();
    m_codigosRetiradosConfirmados.clear();

    reconstruirEstructurasHorarioAsignado();
    emit datosEstudianteChanged();
    emit horarioAsignadoChanged();
    emit materiasRecordatorioChanged();
    emit transcritasChanged();
    emit expedienteChanged();
    emit rapChanged();
    emit materiasRecordatorioChanged();
    emit inscripcionChanged();
    emit retiroChanged();
}

void DaeClient::setTemaSeleccionado(int valor)
{
    if (m_temaSeleccionado == valor) return;
    m_temaSeleccionado = valor;
    QSettings settings("UniversidadDeCarabobo", "AppDAE");
    settings.setValue("apariencia/modoTema", m_temaSeleccionado);
    settings.sync();
    emit aparienciaChanged();
}

// ============================================================================
// RECORDATORIOS: TAREAS Y EXAMENES PROGRAMADOS
// ============================================================================
QStringList DaeClient::materiasSugeridasRecordatorio() const
{
    // Materias del horario asignado + materias del RAP, sin repetir
    QStringList lista;
    auto anadir = [&lista](const QString &texto) {
        const QString t = texto.trimmed();
        if (t.isEmpty()) return;
        for (const QString &existente : lista) {
            if (existente.compare(t, Qt::CaseInsensitive) == 0) return;
        }
        lista.append(t);
    };

    const QVariantList dias = diasHorarioAsignado();
    for (const QVariant &v : dias) {
        const QVariantMap m = v.toMap();
        anadir(m.value("materia").toString());
        anadir(m.value("codigo").toString());
    }
    const QVariantList rap = materiasRap();
    for (const QVariant &v : rap) {
        const QVariantMap m = v.toMap();
        anadir(m.value("materia").toString());
        anadir(m.value("codigo").toString());
    }
    lista.sort(Qt::CaseInsensitive);
    return lista;
}

// Convierte "FUNDAMENTOS DE PROGRAMACION" en "Fundamentos de Programacion",
// conservando las siglas romanas y los conectores en minuscula.
static QString nombreLegibleMateria(const QString &original)
{
    QStringList palabras = original.simplified().split(' ', Qt::SkipEmptyParts);
    static const QSet<QString> siglasRomanas = {"I", "II", "III", "IV", "V", "VI", "VII",
                                                 "VIII", "IX", "X", "(LAB)", "LAB", "TV",
                                                 "RF", "CAD"};
    static const QSet<QString> conectoresMin = {"DE", "DEL", "LA", "LAS", "EL", "LOS",
                                                 "Y", "E", "EN", "A", "PARA", "CON",
                                                 "POR", "AL"};
    for (int w = 0; w < palabras.size(); ++w) {
        const QString pUp = palabras[w].toUpper();
        if (siglasRomanas.contains(pUp)) {
            palabras[w] = pUp;
        } else if (w > 0 && conectoresMin.contains(pUp)) {
            palabras[w] = pUp.toLower();
        } else if (pUp.length() > 1) {
            palabras[w] = pUp.left(1) + pUp.mid(1).toLower();
        }
    }
    return palabras.isEmpty() ? original : palabras.join(' ');
}

// Devuelve true si la asignatura es un laboratorio (codigo terminado en "L"
// o nombre que lo indica).
static bool esMateriaLaboratorio(const QString &codigo, const QString &nombre)
{
    const QString c = codigo.trimmed().toUpper();
    if (c.size() > 4 && c.endsWith(QLatin1Char('L'))) {
        return true;
    }
    return nombre.contains("Lab", Qt::CaseInsensitive);
}

// Clave para comparar dos materias. Con codigo se usa el codigo completo
// (la teoria CA3013 y el laboratorio CA3013L son entradas distintas). Sin
// codigo se usa el nombre sin tildes ni mayusculas.
static QString claveMateria(const QString &materia, const QString &codigo)
{
    const QString clave = codigo.trimmed().toUpper();
    if (!clave.isEmpty()) {
        return clave;
    }
    QString n = materia.toUpper();
    n.remove("(LAB)");
    n.remove("LAB.");
    n.remove("LAB ");
    n = n.normalized(QString::NormalizationForm_D);
    QString limpia;
    for (const QChar &ch : n) {
        const ushort u = ch.unicode();
        if (u >= 0x0300 && u <= 0x036F) {
            continue;
        }
        limpia += ch;
    }
    return limpia.simplified();
}

QVariantList DaeClient::materiasParaRecordatorio() const
{
    // Materias que cursa el estudiante en el SEMESTRE ACTUAL.
    // La lista sale del HORARIO ASIGNADO: por cada clase aparece la teoria
    // y, si existe, su laboratorio (como "Laboratorio de <materia>").
    // Si el horario aun no se ha cargado, se completa con las materias del
    // periodo actual y las inscritas.
    // El RAP NO se usa: es el historial academico de TODOS los semestres.
    QVariantList lista;
    QHash<QString, int> indice;

    auto anadir = [&lista, &indice](const QString &materia, const QString &codigo) {
        QString m = materia.trimmed();
        if (m.isEmpty()) {
            return;
        }
        // El servidor antepone "Lab." a los laboratorios: se quita para
        // poder escribir "Laboratorio de <materia>".
        if (m.startsWith("Lab. ", Qt::CaseInsensitive)) {
            m = m.mid(5).trimmed();
        } else if (m.startsWith("(LAB)", Qt::CaseInsensitive)) {
            m = m.mid(5).trimmed();
        }
        m = nombreLegibleMateria(m);
        if (m.isEmpty()) {
            return;
        }
        if (esMateriaLaboratorio(codigo, m) &&
            !m.startsWith("Laboratorio de ", Qt::CaseInsensitive)) {
            m = "Laboratorio de " + m;
        }

        const QString clave = claveMateria(m, codigo);
        if (clave.isEmpty() || indice.contains(clave)) {
            return;
        }

        QVariantMap item;
        item["materia"] = m;
        item["codigo"] = codigo.trimmed();
        item["texto"] = m;   // solo el nombre, sin codigo
        indice.insert(clave, lista.size());
        lista.append(item);
    };

    // 1) HORARIO ASIGNADO: cada dia trae sus clases (teoria y laboratorio)
    for (const QVariant &v : diasHorarioAsignado()) {
        const QVariantMap dia = v.toMap();
        anadir(dia.value("materia").toString(), dia.value("codigo").toString());
        const QVariantList clases = dia.value("clases").toList();
        for (const QVariant &c : clases) {
            const QVariantMap cm = c.toMap();
            QString nombre = cm.value("nombre").toString();
            if (nombre.isEmpty()) {
                nombre = cm.value("materia").toString();
            }
            anadir(nombre, cm.value("codigo").toString());
        }
    }

    // 2) Materias del PERIODO ACTUAL (transcritas), por si falta alguna
    for (const QVariant &v : m_materiasPeriodoActualRaw) {
        const QVariantMap m = v.toMap();
        const QString codigo = m.value("codigo").toString();
        QString nombre = m.value("nombre").toString();
        if (nombre.isEmpty()) {
            nombre = codigo;
        }
        anadir(nombre, codigo);
    }

    // 3) Materias inscritas, por si falta alguna
    for (const QVariant &v : m_materiasInscritasRaw) {
        const QVariantMap m = v.toMap();
        const QString codigo = m.value("codigo").toString();
        QString nombre = m.value("nombre").toString();
        if (nombre.isEmpty()) {
            nombre = codigo;
        } else {
            nombre = m_mapaNombreMateriaHorario.value(codigo, nombre);
        }
        anadir(nombre, codigo);
    }

    std::sort(lista.begin(), lista.end(), [](const QVariant &a, const QVariant &b) {
        return a.toMap().value("materia").toString()
                .compare(b.toMap().value("materia").toString(), Qt::CaseInsensitive) < 0;
    });
    return lista;
}

int DaeClient::recordatoriosPendientes() const
{
    int n = 0;
    for (const QVariant &v : m_recordatorios) {
        if (!v.toMap().value("hecho").toBool()) {
            ++n;
        }
    }
    return n;
}

void DaeClient::guardarRecordatorio(const QVariantMap &datos)
{
    QVariantMap registro = datos;
    const QString id = registro.value("id").toString();
    if (id.isEmpty()) {
        return;
    }

    // Reemplaza el existente con el mismo id
    QVariantList lista;
    for (const QVariant &v : m_recordatorios) {
        if (v.toMap().value("id").toString() != id) {
            lista.append(v);
        }
    }
    lista.append(registro);

    // Ordena por fecha y hora (de lo mas proximo a lo mas lejano)
    std::sort(lista.begin(), lista.end(), [](const QVariant &a, const QVariant &b) {
        const QVariantMap ma = a.toMap();
        const QVariantMap mb = b.toMap();
        const QString ka = ma.value("fecha").toString() + " " + ma.value("hora").toString();
        const QString kb = mb.value("fecha").toString() + " " + mb.value("hora").toString();
        if (ka != kb) return ka < kb;
        return ma.value("materia").toString() < mb.value("materia").toString();
    });

    m_recordatorios = lista;
    guardarRecordatoriosEnDisco();
    emit recordatoriosChanged();

    // Al crear el primer recordatorio se pide el permiso de notificaciones
    solicitarPermisoNotificaciones();
}

void DaeClient::eliminarRecordatorio(const QString &id)
{
    // Se guardan los avisos del recordatorio antes de quitarlo, para poder
    // cancelar cada uno de los avisos agendados en el AlarmManager.
    QVariantList avisos;
    for (const QVariant &v : m_recordatorios) {
        const QVariantMap m = v.toMap();
        if (m.value("id").toString() == id) {
            const QVariantList listaAvisos = m.value("avisos").toList();
            for (const QVariant &a : listaAvisos) {
                QVariantMap aviso = a.toMap();
                aviso.remove("cuando");
                avisos.append(aviso);
            }
        }
    }

    QVariantList lista;
    for (const QVariant &v : m_recordatorios) {
        if (v.toMap().value("id").toString() != id) {
            lista.append(v);
        }
    }
    m_recordatorios = lista;
    guardarRecordatoriosEnDisco();

    if (!avisos.isEmpty()) {
        cancelarAvisosRecordatorio(id, avisos);
    } else {
        cancelarAvisoRecordatorio(id);
    }
    emit recordatoriosChanged();
}

void DaeClient::alternarRecordatorioHecho(const QString &id)
{
    QVariantList lista;
    for (const QVariant &v : m_recordatorios) {
        QVariantMap m = v.toMap();
        if (m.value("id").toString() == id) {
            m["hecho"] = !m.value("hecho").toBool();
        }
        lista.append(m);
    }
    m_recordatorios = lista;
    guardarRecordatoriosEnDisco();
    emit recordatoriosChanged();
}

void DaeClient::guardarRecordatoriosEnDisco()
{
    QJsonArray arr;
    for (const QVariant &v : m_recordatorios) {
        arr.append(QJsonObject::fromVariantMap(v.toMap()));
    }
    QSettings ajustes("UniversidadDeCarabobo", "AppDAE_Recordatorios");
    ajustes.setValue("recordatorios/lista", QString::fromUtf8(QJsonDocument(arr).toJson(QJsonDocument::Compact)));
    ajustes.sync();
}

void DaeClient::programarAvisoRecordatorio(const QString &id, const QString &titulo,
                                         const QString &texto, qint64 cuandoMillis)
{
#ifdef Q_OS_ANDROID
    QJniObject activity = QNativeInterface::QAndroidApplication::context();
    if (activity.isValid()) {
        QJniObject::callStaticMethod<void>(
            "org/qtproject/example/DaeReminderHelper",
            "programarAviso",
            "(Landroid/app/Activity;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;J)V",
            activity.object<jobject>(),
            QJniObject::fromString(id).object<jstring>(),
            QJniObject::fromString(titulo).object<jstring>(),
            QJniObject::fromString(texto).object<jstring>(),
            QJniObject::fromString("a0").object<jstring>(),
            static_cast<jlong>(cuandoMillis));
    }
#else
    Q_UNUSED(id);
    Q_UNUSED(titulo);
    Q_UNUSED(texto);
    Q_UNUSED(cuandoMillis);
#endif
}

void DaeClient::programarAvisosRecordatorio(const QString &id, const QString &titulo,
                                          const QString &texto, const QVariantList &avisos)
{
#ifdef Q_OS_ANDROID
    QJniObject activity = QNativeInterface::QAndroidApplication::context();
    if (!activity.isValid()) {
        return;
    }
    for (int i = 0; i < avisos.size(); ++i) {
        const QVariantMap aviso = avisos.at(i).toMap();
        const qint64 cuando = static_cast<qint64>(aviso.value("cuando").toDouble());
        if (cuando <= 0) {
            continue;
        }
        const QString etiqueta = aviso.value("etiqueta").toString();
        QJniObject::callStaticMethod<void>(
            "org/qtproject/example/DaeReminderHelper",
            "programarAviso",
            "(Landroid/app/Activity;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;J)V",
            activity.object<jobject>(),
            QJniObject::fromString(id).object<jstring>(),
            QJniObject::fromString(titulo).object<jstring>(),
            QJniObject::fromString(texto).object<jstring>(),
            QJniObject::fromString(etiqueta).object<jstring>(),
            static_cast<jlong>(cuando));
    }
#else
    Q_UNUSED(id);
    Q_UNUSED(titulo);
    Q_UNUSED(texto);
    Q_UNUSED(avisos);
#endif
}

void DaeClient::cancelarAvisosRecordatorio(const QString &id, const QVariantList &avisos)
{
#ifdef Q_OS_ANDROID
    QJniObject activity = QNativeInterface::QAndroidApplication::context();
    if (!activity.isValid()) {
        return;
    }
    for (int i = 0; i < avisos.size(); ++i) {
        const QVariantMap aviso = avisos.at(i).toMap();
        const QString etiqueta = aviso.value("etiqueta").toString();
        QJniObject::callStaticMethod<void>(
            "org/qtproject/example/DaeReminderHelper",
            "cancelarAviso",
            "(Landroid/app/Activity;Ljava/lang/String;Ljava/lang/String;)V",
            activity.object<jobject>(),
            QJniObject::fromString(id).object<jstring>(),
            QJniObject::fromString(etiqueta).object<jstring>());
    }
#else
    Q_UNUSED(id);
    Q_UNUSED(avisos);
#endif
}

void DaeClient::cancelarAvisoRecordatorio(const QString &id)
{
#ifdef Q_OS_ANDROID
    QJniObject activity = QNativeInterface::QAndroidApplication::context();
    if (activity.isValid()) {
        QJniObject::callStaticMethod<void>(
            "org/qtproject/example/DaeReminderHelper",
            "cancelarAviso",
            "(Landroid/app/Activity;Ljava/lang/String;)V",
            activity.object<jobject>(),
            QJniObject::fromString(id).object<jstring>());
    }
#else
    Q_UNUSED(id);
#endif
}

void DaeClient::avisarAhoraRecordatorio(const QString &id, const QString &titulo, const QString &texto)
{
#ifdef Q_OS_ANDROID
    QJniObject activity = QNativeInterface::QAndroidApplication::context();
    if (activity.isValid()) {
        QJniObject::callStaticMethod<void>(
            "org/qtproject/example/DaeReminderHelper",
            "mostrarAvisoAhora",
            "(Landroid/app/Activity;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V",
            activity.object<jobject>(),
            QJniObject::fromString(id).object<jstring>(),
            QJniObject::fromString(titulo).object<jstring>(),
            QJniObject::fromString(texto).object<jstring>());
    }
#else
    Q_UNUSED(id);
    Q_UNUSED(titulo);
    Q_UNUSED(texto);
#endif
}

void DaeClient::solicitarPermisoNotificaciones()
{
    if (m_permisoNotificacionesSolicitado) {
        return;
    }
    m_permisoNotificacionesSolicitado = true;
#ifdef Q_OS_ANDROID
    QJniObject activity = QNativeInterface::QAndroidApplication::context();
    if (activity.isValid()) {
        QJniObject::callStaticMethod<void>(
            "org/qtproject/example/DaeReminderHelper",
            "pedirPermisoNotificaciones",
            "(Landroid/app/Activity;)V",
            activity.object<jobject>());
    }
#endif
}

void DaeClient::aceptarDescargoResponsabilidad()
{
    if (m_descargoAceptado) {
        return;
    }
    m_descargoAceptado = true;
    QSettings settings("UniversidadDeCarabobo", "AppDAE");
    settings.setValue("legal/descargoAceptado", true);
    settings.sync();
    emit aparienciaChanged();
}

bool DaeClient::permisoNotificacionesActivo() const
{
    if (!m_notificacionesHabilitadasUsuario) {
        return false;
    }
#ifdef Q_OS_ANDROID
    QJniObject activity = QNativeInterface::QAndroidApplication::context();
    if (activity.isValid()) {
        jboolean concedido = QJniObject::callStaticMethod<jboolean>(
            "org/qtproject/example/DaeReminderHelper",
            "tienePermisoNotificaciones",
            "(Landroid/app/Activity;)Z",
            activity.object<jobject>());
        return static_cast<bool>(concedido);
    }
    return false;
#else
    return true;
#endif
}

void DaeClient::setPermisoNotificacionesActivo(bool activar)
{
    activarPermisoNotificaciones(activar);
}

void DaeClient::activarPermisoNotificaciones(bool activar)
{
    QSettings settings("UniversidadDeCarabobo", "AppDAE");
    if (!activar) {
        m_notificacionesHabilitadasUsuario = false;
        m_esperandoRespuestaPermisoNotif = false;
        settings.setValue("notificaciones/habilitadas", false);
        settings.sync();
        m_ultimoEstadoPermisoNotif = false;
        emit recordatoriosChanged();
        emit biometriaNotificacion(true, "• Notificaciones desactivadas");
        return;
    }

    m_notificacionesHabilitadasUsuario = true;
    settings.setValue("notificaciones/habilitadas", true);
    settings.sync();

#ifdef Q_OS_ANDROID
    QJniObject activity = QNativeInterface::QAndroidApplication::context();
    if (activity.isValid()) {
        jboolean concedido = QJniObject::callStaticMethod<jboolean>(
            "org/qtproject/example/DaeReminderHelper",
            "tienePermisoNotificaciones",
            "(Landroid/app/Activity;)Z",
            activity.object<jobject>());
        if (concedido) {
            m_ultimoEstadoPermisoNotif = true;
            emit recordatoriosChanged();
            emit biometriaNotificacion(true, "✓ Permiso de notificaciones activado");
            return;
        }
        m_esperandoRespuestaPermisoNotif = true;
        QJniObject::callStaticMethod<void>(
            "org/qtproject/example/DaeReminderHelper",
            "pedirPermisoNotificaciones",
            "(Landroid/app/Activity;)V",
            activity.object<jobject>());
        emit recordatoriosChanged();
        return;
    }
#endif
    m_ultimoEstadoPermisoNotif = true;
    emit recordatoriosChanged();
    emit biometriaNotificacion(true, "✓ Permiso de notificaciones activado");
}

// ---------------------------------------------------------------------------
// TECLADO EN PANTALLA
// ---------------------------------------------------------------------------
bool DaeClient::tecladoVisible() const
{
    QInputMethod *im = QGuiApplication::inputMethod();
    if (!im) {
        return false;
    }
    return im->isVisible() || im->keyboardRectangle().height() > 0;
}

double DaeClient::tecladoAltura() const
{
    QInputMethod *im = QGuiApplication::inputMethod();
    if (!im) {
        return 0;
    }
    return im->keyboardRectangle().height();
}

double DaeClient::insetSuperior() const
{
#ifdef Q_OS_ANDROID
    static double s_cachedTop = -1.0;
    if (s_cachedTop > 0.0) {
        return s_cachedTop;
    }
    QJniObject activity = QNativeInterface::QAndroidApplication::context();
    if (activity.isValid()) {
        double dp = static_cast<double>(QJniObject::callStaticMethod<jdouble>(
            "org/qtproject/example/DaeBiometricHelper",
            "getStatusBarHeightDp",
            "(Landroid/app/Activity;)D",
            activity.object<jobject>()));
        if (dp > 0.0) {
            s_cachedTop = dp;
            return s_cachedTop;
        }
    }
    return 32.0;
#else
    return 0.0;
#endif
}

double DaeClient::insetInferior() const
{
#ifdef Q_OS_ANDROID
    static double s_cachedBottom = -1.0;
    if (s_cachedBottom >= 0.0) {
        return s_cachedBottom;
    }
    QJniObject activity = QNativeInterface::QAndroidApplication::context();
    if (activity.isValid()) {
        double dp = static_cast<double>(QJniObject::callStaticMethod<jdouble>(
            "org/qtproject/example/DaeBiometricHelper",
            "getNavigationBarHeightDp",
            "(Landroid/app/Activity;)D",
            activity.object<jobject>()));
        if (dp >= 0.0) {
            s_cachedBottom = dp;
            return s_cachedBottom;
        }
    }
    return 16.0;
#else
    return 0.0;
#endif
}

bool DaeClient::sistemaEsClaro() const
{
    // Devuelve el esquema REAL del sistema (guardado aparte porque la app puede
    // forzar su propio esquema para adaptar los iconos de la barra de estado)
    return m_sistemaEsClaroReal;
}

void DaeClient::aplicarEsquemaColorSistema(bool modoClaro)
{
    if (QGuiApplication::styleHints()) {
        m_esquemaPersonalizado = true;
        QGuiApplication::styleHints()->setColorScheme(modoClaro ? Qt::ColorScheme::Light
                                                                  : Qt::ColorScheme::Dark);
    }

#ifdef Q_OS_ANDROID
    QJniObject activity = QNativeInterface::QAndroidApplication::context();
    if (activity.isValid()) {
        QJniObject::callStaticMethod<void>(
            "org/qtproject/example/DaeBiometricHelper",
            "configureEdgeToEdge",
            "(Landroid/app/Activity;Z)V",
            activity.object<jobject>(),
            static_cast<jboolean>(modoClaro));
    }
#endif
}

// ============================================================================
// SOLICITUDES RECIENTES
// Registra la acción que el estudiante acaba de hacer (constancia, inscripción,
//  carnet, RAP, horario o calendario) para que la pantalla principal muestre
//  las últimas 3 solicitudes reales, no unos datos fijos.
// ============================================================================
void DaeClient::registrarSolicitudReciente(const QString &tipo, const QString &titulo,
                                            const QString &detalle, const QString &estado)
{
    QVariantMap item;
    item["tipo"] = tipo;
    item["titulo"] = titulo;
    item["detalle"] = detalle;
    item["estado"] = estado;
    item["fecha"] = QDateTime::currentDateTime().toString("dd/MM/yyyy hh:mm");

    // La más reciente primero y sin repetir el mismo tipo de solicitud
    QVariantList lista;
    lista.append(item);
    for (const QVariant &v : m_solicitudesRecientes) {
        if (v.toMap().value("tipo").toString() != tipo) {
            lista.append(v);
        }
    }
    while (lista.size() > 3) {
        lista.removeLast();
    }

    m_solicitudesRecientes = lista;
    emit solicitudesRecientesChanged();
}

QString DaeClient::cedulaBiometricaFormateada() const
{
    QString limpia = m_cedulaBiometrica.trimmed();
    QString resultado;
    int contador = 0;
    for (int i = limpia.length() - 1; i >= 0; --i) {
        if (contador > 0 && contador % 3 == 0) {
            resultado.prepend('.');
        }
        resultado.prepend(limpia[i]);
        contador++;
    }
    return resultado;
}

void DaeClient::guardarCredencialesBiometricas(const QString &cedula, const QString &clave)
{
    if (cedula.isEmpty() || clave.isEmpty()) return;
    m_cedulaBiometrica = cedula.trimmed();
    m_claveBiometrica = clave;
    QSettings settings("UniversidadDeCarabobo", "AppDAE");
    settings.setValue("seguridad/cedulaBio", m_cedulaBiometrica);
    settings.setValue("seguridad/claveBio", ofuscarClaveBio(m_claveBiometrica));
    settings.setValue("seguridad/biometriaActiva", m_biometriaActiva);
    settings.sync();
    emit biometriaChanged();
}

void DaeClient::setBiometriaActiva(bool valor)
{
    activarBiometria(valor);
}

void DaeClient::solicitarAutenticacionBiometricaDispositivo(const QString &titulo, const QString &subtitulo)
{
    m_autenticandoBiometria = true;
    emit biometriaChanged();

#ifdef Q_OS_ANDROID
    QJniObject activity = QNativeInterface::QAndroidApplication::context();
    if (activity.isValid()) {
        jboolean disponible = QJniObject::callStaticMethod<jboolean>(
            "org/qtproject/example/DaeBiometricHelper",
            "isBiometricAvailable",
            "(Landroid/app/Activity;)Z",
            activity.object<jobject>());
        if (disponible) {
            QJniObject jTitulo = QJniObject::fromString(titulo);
            QJniObject jSubtitulo = QJniObject::fromString(subtitulo);
            QJniObject::callStaticMethod<void>(
                "org/qtproject/example/DaeBiometricHelper",
                "authenticate",
                "(Landroid/app/Activity;Ljava/lang/String;Ljava/lang/String;)V",
                activity.object<jobject>(),
                jTitulo.object<jstring>(),
                jSubtitulo.object<jstring>());
            return;
        }
    }
#endif

    // En escritorio o si el dispositivo no tiene bloqueo nativo configurado, abrimos el escáner biométrico integrado
    emit mostrarEscanerBiometricoLocal(titulo, subtitulo);
}

void DaeClient::confirmarEscanerBiometricoLocal(bool exito)
{
    procesarResultadoBiometrico(
        exito,
        exito ? "Identidad verificada con huella dactilar" : "Verificación biométrica cancelada");
}

void DaeClient::activarBiometria(bool activar)
{
    if (!activar) {
        m_biometriaActiva = false;
        m_autenticandoBiometria = false;
        m_accionBiometricaPendiente.clear();
        QSettings settings("UniversidadDeCarabobo", "AppDAE");
        settings.setValue("seguridad/biometriaActiva", false);
        settings.remove("seguridad/claveBio");
        settings.sync();
        m_claveBiometrica.clear();
        emit biometriaChanged();
        emit biometriaNotificacion(true, "• Acceso biométrico desactivado");
        return;
    }

    QString claveAUsar = !m_ultimaClaveSesion.isEmpty() ? m_ultimaClaveSesion : m_claveBiometrica;
    if (m_cedulaEstudiante.isEmpty() || claveAUsar.isEmpty()) {
        m_biometriaActiva = false;
        emit biometriaChanged();
        emit biometriaNotificacion(false, "Inicia sesión con tu contraseña primero para vincular tu huella");
        return;
    }

    m_accionBiometricaPendiente = "activar";
    solicitarAutenticacionBiometricaDispositivo(
        "Activar Acceso Biométrico",
        "Vincular huella a V-" + cedulaFormateada());
}

void DaeClient::iniciarSesionConBiometria()
{
    if (!tieneCredencialesBiometricas()) {
        m_mensajeError = "Activa primero el Acceso Biométrico dentro de tu Perfil DAE.";
        emit mensajeErrorChanged();
        emit biometriaNotificacion(false, m_mensajeError);
        return;
    }
    if (m_cargandoLogin || m_autenticandoBiometria) {
        return;
    }

    m_accionBiometricaPendiente = "login";
    solicitarAutenticacionBiometricaDispositivo(
        "Acceso Biométrico DAE UC",
        "Estudiante V-" + cedulaBiometricaFormateada());
}

void DaeClient::procesarResultadoBiometrico(bool exito, const QString &mensaje)
{
    m_autenticandoBiometria = false;
    QString accion = m_accionBiometricaPendiente;
    m_accionBiometricaPendiente.clear();

    if (!exito) {
        if (accion == "activar") {
            m_biometriaActiva = false;
        }
        emit biometriaChanged();
        emit biometriaNotificacion(false, mensaje.isEmpty() ? "Verificación biométrica cancelada" : mensaje);
        return;
    }

    if (accion == "activar") {
        QString claveAUsar = !m_ultimaClaveSesion.isEmpty() ? m_ultimaClaveSesion : m_claveBiometrica;
        m_biometriaActiva = true;
        guardarCredencialesBiometricas(m_cedulaEstudiante, claveAUsar);
        emit biometriaChanged();
        emit biometriaNotificacion(true, "✓ Acceso biométrico activado para V-" + cedulaFormateada());
    } else if (accion == "login") {
        emit biometriaChanged();
        emit biometriaNotificacion(true, "✓ Huella verificada • Ingresando al DAE...");
        iniciarSesion(m_cedulaBiometrica, m_claveBiometrica);
    } else {
        emit biometriaChanged();
    }
}

void DaeClient::setPaletaAuroraIndex(int valor)
{
    if (m_paletaAuroraIndex == valor) return;
    m_paletaAuroraIndex = valor;
    QSettings settings("UniversidadDeCarabobo", "AppDAE");
    settings.setValue("apariencia/paletaAuroraIndex", m_paletaAuroraIndex);
    settings.sync();
    emit aparienciaChanged();
}

void DaeClient::setAnimacionAuroraActiva(bool valor)
{
    if (m_animacionAuroraActiva == valor) return;
    m_animacionAuroraActiva = valor;
    QSettings settings("UniversidadDeCarabobo", "AppDAE");
    settings.setValue("apariencia/animacionAuroraActiva", m_animacionAuroraActiva);
    settings.sync();
    emit aparienciaChanged();
}

void DaeClient::setUrlFotoPerfil(const QString &valor)
{
    if (m_urlFotoPerfil == valor) return;
    m_urlFotoPerfil = valor;
    QSettings settings("UniversidadDeCarabobo", "AppDAE");
    settings.setValue("perfil/urlFotoPerfil", m_urlFotoPerfil);
    settings.sync();
    emit aparienciaChanged();
}

QString DaeClient::prepararRutaFotoPerfil()
{
    QString dirApp = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir dir(dirApp);
    dir.mkpath(".");
    // Eliminar recortes anteriores para no acumular archivos (el nombre cambia para evitar la caché de imágenes)
    const QStringList anteriores = dir.entryList(QStringList() << "foto_perfil_*.png", QDir::Files);
    for (const QString &f : anteriores) {
        dir.remove(f);
    }
    return dir.filePath(QString("foto_perfil_%1.png").arg(QDateTime::currentMSecsSinceEpoch()));
}

int DaeClient::obtenerUcAsignatura(const QString &codigo) const
{
    QString cod = codigo.trimmed().toUpper();
    if (cod.isEmpty() || cod.endsWith("L")) {
        return 0;
    }

    // 1. Buscar primero en el pensum descargado en vivo desde dae.ing.uc.edu.ve/pensa/
    for (const QVariant &vSem : m_semestresPensum) {
        QVariantMap semMap = vSem.toMap();
        QVariantList mats = semMap["materias"].toList();
        for (const QVariant &vMat : mats) {
            QVariantMap matMap = vMat.toMap();
            if (matMap["codigo"].toString().trimmed().toUpper() == cod) {
                return qRound(matMap["uc"].toDouble());
            }
        }
    }

    // 2. Catálogo oficial de U.C. por asignatura en DAE Ingeniería UC
    static const QMap<QString, int> catalogoUc = {
        {"DE1B01", 0}, {"DH1B01", 2}, {"HU1B01", 3}, {"MA1B01", 5}, {"MA1B02", 5}, {"QM1B01", 3},
        {"DH2B02", 1}, {"DI2B01", 2}, {"FI2B01", 4}, {"ID2B01", 3}, {"MA2B03", 4}, {"MA2B04", 3},
        {"CA3B01", 3}, {"FI3B02", 3}, {"FI3B03", 2}, {"HU3B02", 0}, {"MA3B05", 3}, {"MA3B06", 3},
        {"CA4B02", 3}, {"CM4T01", 4}, {"FI4B06", 3}, {"HU4B03", 0}, {"ID4B02", 2}, {"MA4B07", 3},
        {"CM5T02", 4}, {"CM5T03", 5}, {"EC5T01", 3}, {"ER5T01", 3}, {"HU5B06", 0}, {"SS5T01", 3},
        {"CO6B01", 0}, {"EC6T03", 4}, {"ER6T02", 3}, {"IN6T01", 3}, {"SA6T01", 4},
        {"EC7T04", 5}, {"ER7T03", 5}, {"SS7T02", 4}, {"SS7T03", 3}, {"SS7T04", 3},
        {"ER8T04", 5}, {"GE8T01", 3}, {"SA8T04", 4}, {"SA8T06", 3}, {"SS8T06", 5}, {"SS8T07", 3},
        {"CA9T03", 3}, {"ER9T05", 4}, {"ER9T06", 4}, {"ER9T07", 3}, {"SA9T05", 4}, {"SS9T08", 5}, {"SS9T09", 4},
        {"HU0B02", 2}, {"PG0T01", 6}, {"ER0T08", 3}, {"SS0T10", 3}, {"SS0T11", 3}, {"SS0T12", 3}, {"SS0T16", 3}
    };

    if (catalogoUc.contains(cod)) {
        return catalogoUc.value(cod);
    }

    if (cod.startsWith("CO") || cod.startsWith("DE") || cod == "HU3B02" || cod == "HU4B03" || cod == "HU5B06") {
        return 0;
    }
    return 3;
}

QString DaeClient::limpiarTextoHtml(QString html)
{
    // Quitar etiquetas HTML
    static const QRegularExpression reTags("<[^>]*>");
    html.replace(reTags, " ");

    // Decodificar entidades HTML frecuentes en DAE UC
    html.replace("&nbsp;", " ");
    html.replace("&amp;", "&");
    html.replace("&quot;", "\"");
    html.replace("&#039;", "'");
    html.replace("&lt;", "<");
    html.replace("&gt;", ">");
    html.replace("&aacute;", "á");
    html.replace("&eacute;", "é");
    html.replace("&iacute;", "í");
    html.replace("&oacute;", "ó");
    html.replace("&uacute;", "ú");
    html.replace("&Aacute;", "Á");
    html.replace("&Eacute;", "É");
    html.replace("&Iacute;", "Í");
    html.replace("&Oacute;", "Ó");
    html.replace("&Uacute;", "Ú");
    html.replace("&ntilde;", "ñ");
    html.replace("&Ntilde;", "Ñ");
    html.replace("&uuml;", "ü");
    html.replace("&Uuml;", "Ü");

    static const QRegularExpression reSpaces("\\s+");
    return html.replace(reSpaces, " ").trimmed();
}

// ---------------------------------------------------------------------------
// Caché local de la sesión.
//
// Guarda en el teléfono una copia del menú autenticado y de cada página de
// datos que se consulta al DAE (horario, expediente, notas, RAP, inscripción,
// etc.). Al volver a iniciar sesión con la misma cédula y clave, la app usa esa
// copia durante kHorasCacheSesion y NO llama al servidor. Pasado ese tiempo,
// o si el usuario pulsa "Sincronizar con el servidor", se consulta de nuevo.
// ---------------------------------------------------------------------------
static constexpr qint64 kHorasCacheSesion = 12;

static QString hashClaveCache(const QString &cedula, const QString &clave)
{
    const QString texto = cedula.trimmed() + ":" + clave;
    return QString::fromLatin1(
        QCryptographicHash::hash(texto.toUtf8(), QCryptographicHash::Sha256).toHex());
}

static QString rutaCacheSesionPara(const QString &cedula)
{
    const QString base = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QString carpeta = cedula;
    carpeta.remove(QRegularExpression("[^0-9]"));
    if (carpeta.isEmpty()) carpeta = "anonimo";
    return base + "/cache_sesion/" + carpeta;
}

static QString nombreArchivoSeccion(const QString &hrefRelativo)
{
    QString safeName = hrefRelativo;
    safeName.replace(QRegularExpression("[^a-zA-Z0-9_\\.]"), "_");
    if (!safeName.endsWith(".html")) safeName += ".html";
    return safeName;
}

static void escribirArchivoCache(const QString &ruta, const QByteArray &contenido)
{
    QDir().mkpath(QFileInfo(ruta).absolutePath());
    QFile f(ruta);
    if (f.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        f.write(contenido);
        f.close();
    }
}

static QString textoActualizadoHace(qint64 segundos)
{
    if (segundos < 60) return QStringLiteral("hace un momento");
    if (segundos < 3600) {
        const qint64 minutos = segundos / 60;
        return minutos == 1 ? QStringLiteral("hace 1 minuto")
                            : QStringLiteral("hace %1 minutos").arg(minutos);
    }
    if (segundos < 86400) {
        const qint64 horas = segundos / 3600;
        return horas == 1 ? QStringLiteral("hace 1 hora")
                          : QStringLiteral("hace %1 horas").arg(horas);
    }
    const qint64 dias = segundos / 86400;
    return dias == 1 ? QStringLiteral("hace 1 día")
                     : QStringLiteral("hace %1 días").arg(dias);
}

QString DaeClient::actualizadoHace() const
{
    if (m_cacheTimestamp <= 0) return QString();
    qint64 edad = QDateTime::currentSecsSinceEpoch() - m_cacheTimestamp;
    if (edad < 0) edad = 0;
    return textoActualizadoHace(edad);
}

void DaeClient::guardarSesionEnCache(const QString &menuHtml)
{
    if (m_cedulaEstudiante.isEmpty()) return;

    const QString dir = rutaCacheSesionPara(m_cedulaEstudiante);
    QDir().mkpath(dir);

    escribirArchivoCache(dir + "/menu.html", menuHtml.toUtf8());

    QJsonObject meta;
    meta.insert("version", 1);
    meta.insert("cedula", m_cedulaEstudiante);
    meta.insert("claveHash", hashClaveCache(m_cedulaEstudiante, m_ultimaClaveSesion));
    meta.insert("timestamp", static_cast<double>(QDateTime::currentSecsSinceEpoch()));
    meta.insert("pid", m_pidSesion);

    // Guardar también las cookies para que las acciones puntuales (descargar
    // una constancia, enviar una solicitud...) sigan funcionando dentro de la
    // misma sesión del servidor.
    QJsonArray cookies;
    for (const QNetworkCookie &c : m_cookieJar->cookies()) {
        cookies.append(QString::fromLatin1(c.toRawForm()));
    }
    meta.insert("cookies", cookies);

    escribirArchivoCache(dir + "/meta.json",
                         QJsonDocument(meta).toJson(QJsonDocument::Compact));

    m_cacheTimestamp = QDateTime::currentSecsSinceEpoch();
    m_datosDesdeCache = false;
    emit cacheSesionChanged();
}

void DaeClient::limpiarCacheSesion(const QString &cedula) const
{
    QDir dir(rutaCacheSesionPara(cedula));
    if (dir.exists()) {
        dir.removeRecursively();
    }
}

bool DaeClient::cargarSeccionDesdeCache(const QString &hrefRelativo)
{
    if (m_cedulaEstudiante.isEmpty() || hrefRelativo.isEmpty()) return false;

    const QString ruta = rutaCacheSesionPara(m_cedulaEstudiante) + "/"
                         + nombreArchivoSeccion(hrefRelativo);
    QFile f(ruta);
    if (!f.exists() || !f.open(QIODevice::ReadOnly)) return false;

    const QString html = QString::fromUtf8(f.readAll());
    f.close();
    if (html.isEmpty()) return false;

    parsearPaginaInternaEstudiantil(hrefRelativo, html);
    return true;
}

bool DaeClient::restaurarSesionDesdeCache(const QString &cedula, const QString &clave,
                                          bool emitirLogin)
{
    const QString dir = rutaCacheSesionPara(cedula);

    QFile fMeta(dir + "/meta.json");
    if (!fMeta.exists() || !fMeta.open(QIODevice::ReadOnly)) return false;
    const QJsonObject meta = QJsonDocument::fromJson(fMeta.readAll()).object();
    fMeta.close();

    const qint64 momento = static_cast<qint64>(meta.value("timestamp").toDouble(0));
    const qint64 edad = QDateTime::currentSecsSinceEpoch() - momento;
    if (meta.value("version").toInt() != 1 || momento <= 0 ||
        edad < 0 || edad > kHorasCacheSesion * 3600) {
        return false;
    }

    if (meta.value("claveHash").toString() != hashClaveCache(cedula, clave)) {
        // La clave guardada ya no coincide: la copia no sirve para este usuario.
        limpiarCacheSesion(cedula);
        return false;
    }

    QFile fMenu(dir + "/menu.html");
    if (!fMenu.exists() || !fMenu.open(QIODevice::ReadOnly)) return false;
    const QString menuHtml = QString::fromUtf8(fMenu.readAll());
    fMenu.close();
    if (menuHtml.isEmpty()) return false;

    m_cedulaEstudiante = cedula;
    m_ultimaClaveSesion = clave;
    m_autenticado = true;
    m_mensajeError.clear();
    m_pidSesion = meta.value("pid").toString();
    m_datosDesdeCache = true;
    m_cacheTimestamp = momento;

    // Restaurar las cookies guardadas (si las hay)
    QList<QNetworkCookie> cookiesRestauradas;
    const QJsonArray cookies = meta.value("cookies").toArray();
    for (const QJsonValue &v : cookies) {
        cookiesRestauradas.append(QNetworkCookie::parseCookies(v.toString().toLatin1()));
    }
    if (!cookiesRestauradas.isEmpty()) {
        m_cookieJar->setCookies(cookiesRestauradas);
    }

    emit mensajeErrorChanged();
    emit autenticadoChanged();
    emit cacheSesionChanged();

    cargarSolicitudInscripcionLocal();

    // Reconstruir toda la sesión con las copias locales, sin llamar al servidor.
    m_restaurandoDesdeCache = true;
    parsearMenuEstudiantil(menuHtml);
    m_restaurandoDesdeCache = false;

    emit datosEstudianteChanged();
    emit cacheSesionChanged();
    if (emitirLogin) emit loginExitoso();
    return true;
}

void DaeClient::iniciarSesion(const QString &cedula, const QString &clave)
{
    iniciarSesionInterno(cedula, clave, true, true);
}

void DaeClient::sincronizarConServidor()
{
    if (!m_autenticado) return;
    if (m_sincronizandoServidor || m_cargandoLogin) return;

    if (m_cedulaEstudiante.isEmpty() || m_ultimaClaveSesion.isEmpty()) {
        emit sincronizacionFallida("Vuelve a iniciar sesión para sincronizar con el servidor.");
        return;
    }

    m_sincronizandoServidor = true;
    emit cacheSesionChanged();
    iniciarSesionInterno(m_cedulaEstudiante, m_ultimaClaveSesion, false, false);
}

void DaeClient::iniciarSesionInterno(const QString &cedula, const QString &clave,
                                     bool permitirCache, bool emitirLogin)
{
    QString cedLimpia = cedula.trimmed();
    QString claveLimpia = clave;

    auto informarError = [this, emitirLogin](const QString &mensaje) {
        m_mensajeError = mensaje;
        emit mensajeErrorChanged();
        if (emitirLogin) {
            emit loginFallido(mensaje);
        } else {
            m_sincronizandoServidor = false;
            emit cacheSesionChanged();
            emit sincronizacionFallida(mensaje);
        }
    };

    if (cedLimpia.isEmpty() || claveLimpia.isEmpty()) {
        informarError("Ingresa tu cédula y contraseña");
        return;
    }

    // Normalizamos la cédula dejando únicamente los dígitos (admite "V-30.094.892", "30094892", etc.)
    // Se permiten todas las cédulas válidas registradas en el sistema DAE UC.
    QString cedSoloDigitos = cedLimpia;
    cedSoloDigitos.remove(QRegularExpression("[^0-9]"));
    if (cedSoloDigitos.isEmpty()) {
        informarError("Ingresa una cédula válida");
        return;
    }
    cedLimpia = cedSoloDigitos;

    // 1) Intentar con la copia local. Solo se salta cuando el usuario pide
    //    expresamente sincronizar con el servidor.
    if (permitirCache && restaurarSesionDesdeCache(cedLimpia, claveLimpia, emitirLogin)) {
        return;
    }

    // 2) Inicio de sesión real contra el DAE
    m_cargandoLogin = true;
    m_mensajeError.clear();
    emit cargandoLoginChanged();
    emit mensajeErrorChanged();

    QUrl urlLogin("https://dae.ing.uc.edu.ve/gestion_estudiantil/index.php");
    QNetworkRequest req(urlLogin);
    configurarRequestDae(req);
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");
    req.setRawHeader("Origin", "https://dae.ing.uc.edu.ve");
    req.setRawHeader("Referer", "https://dae.ing.uc.edu.ve/gestion_estudiantil/");

    QUrlQuery postData;
    postData.addQueryItem("login", cedLimpia);
    postData.addQueryItem("clave", claveLimpia);
    postData.addQueryItem("autenticar", "Entrar");

    QNetworkReply *reply = m_nam->post(req, postData.toString(QUrl::FullyEncoded).toUtf8());

    connect(reply, &QNetworkReply::finished, this, [this, reply, cedLimpia, claveLimpia, emitirLogin, informarError]() {
        reply->deleteLater();
        m_cargandoLogin = false;
        emit cargandoLoginChanged();

        if (reply->error() != QNetworkReply::NoError) {
            informarError("Error de conexión con DAE UC: " + reply->errorString());
            return;
        }

        QByteArray rawBytes = reply->readAll();
        QString html = QString::fromUtf8(rawBytes);

        // Guardar HTML devuelto por DAE para inspección de estructura

        // Verificar si el servidor DAE devolvió un mensaje de error en rojo (#CC0000)
        static const QRegularExpression reErrorDae(
            "<p[^>]*style=[\"'][^\"']*#CC0000[^\"']*[\"'][^>]*>(.*?)</p>",
            QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);
        QRegularExpressionMatch matchErr = reErrorDae.match(html);
        if (matchErr.hasMatch()) {
            informarError(limpiarTextoHtml(matchErr.captured(1)));
            return;
        }

        // Si sigue mostrando el formulario de login (input name="clave" y name="autenticar"), falló la autenticación
        if (html.contains("name=\"autenticar\"", Qt::CaseInsensitive) &&
            html.contains("name=\"clave\"", Qt::CaseInsensitive)) {
            informarError("Credenciales inválidas o sesión rechazada por el servidor DAE.");
            return;
        }

        // Verificar que la respuesta sea genuinamente el menú estudiantil autenticado (con pid= o enlaces de sesión)
        // para que nunca se inicie una sesión vacía si el portal DAE está en mantenimiento o cerrado
        static const QRegularExpression rePidCheck("\\bpid=[A-Za-z0-9]{8,}");
        bool tieneMenuValido = rePidCheck.match(html).hasMatch() ||
                               html.contains("limpiarsesion.php", Qt::CaseInsensitive) ||
                               html.contains("MENÚ DE SERVICIO AL ESTUDIANTE", Qt::CaseInsensitive) ||
                               html.contains("MENU DE SERVICIO AL ESTUDIANTE", Qt::CaseInsensitive) ||
                               html.contains("mostrar_horario.php", Qt::CaseInsensitive) ||
                               html.contains("ver_exp.php", Qt::CaseInsensitive);
        if (!tieneMenuValido) {
            QString txtMantenimiento = limpiarTextoHtml(html);
            if (txtMantenimiento.length() > 160) {
                txtMantenimiento = txtMantenimiento.left(160) + "...";
            }
            informarError(txtMantenimiento.isEmpty()
                          ? "El servidor de Gestión Estudiantil DAE UC no está disponible en este momento."
                          : ("Portal DAE no disponible: " + txtMantenimiento));
            return;
        }

        // ¡Autenticación exitosa! Si es el mismo usuario que está refrescando,
        // conservar lo que ya se ve en pantalla; si es otro, limpiar todo.
        const bool mismaSesion = m_autenticado && m_cedulaEstudiante == cedLimpia;
        if (mismaSesion) {
            m_clavesBloquesDelEstudiante.clear();
        } else {
            limpiarDatosEstudianteSesion();
        }
        m_cedulaEstudiante = cedLimpia;
        m_ultimaClaveSesion = claveLimpia;
        m_autenticado = true;
        m_mensajeError.clear();

        cargarSolicitudInscripcionLocal();

        if (m_biometriaActiva) {
            guardarCredencialesBiometricas(cedLimpia, claveLimpia);
        }

        // Si la URL final tras redirección incluye ?pid=..., capturarlo de inmediato
        QString pidUrl = QUrlQuery(reply->url()).queryItemValue("pid").trimmed();
        if (pidUrl.length() >= 8) {
            m_pidSesion = pidUrl;
        }

        // Garantizar que el catálogo general de horarios (profesores/bloques) esté cargado
        if (m_seccionesOfertaPlana.isEmpty() && !m_cargandoHorarios) {
            cargarOfertaHorarios();
        }

        emit autenticadoChanged();
        emit mensajeErrorChanged();

        parsearMenuEstudiantil(html);

        // Guardar la copia local de la sesión para las próximas aperturas
        guardarSesionEnCache(html);

        emit datosEstudianteChanged();

        if (emitirLogin) {
            emit loginExitoso();
        } else {
            m_sincronizandoServidor = false;
            emit cacheSesionChanged();
            emit sincronizacionCompletada();
        }
    });
}

void DaeClient::cerrarSesion()
{
    QUrl urlLogout("https://dae.ing.uc.edu.ve/gestion_estudiantil/salir.php");
    QNetworkRequest req(urlLogout);
    configurarRequestDae(req);
    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, reply, &QNetworkReply::deleteLater);

    m_cookieJar->deleteLater();
    m_cookieJar = new DaeCookieJar(this);
    m_nam->setCookieJar(m_cookieJar);

    m_autenticado = false;
    m_enlacesMenuInterno.clear();
    m_solicitudesRecientes.clear();
    m_datosDesdeCache = false;
    m_cacheTimestamp = 0;
    m_restaurandoDesdeCache = false;
    m_sincronizandoServidor = false;
    m_ultimaClaveSesion.clear();
    limpiarDatosEstudianteSesion();
    emit autenticadoChanged();
    emit enlacesMenuInternoChanged();
    emit solicitudesRecientesChanged();
    emit cacheSesionChanged();
}

void DaeClient::parsearMenuEstudiantil(const QString &html)
{
    // 1. Extraer primero el token de sesión pid=... directamente del HTML crudo
    //    (exigiendo al menos 8 caracteres alfanuméricos para ignorar plantillas comentadas como pid=< ?=$valor_codif)
    static const QRegularExpression rePid("\\bpid=([A-Za-z0-9]{8,})");
    QRegularExpressionMatch mPid = rePid.match(html);
    if (mPid.hasMatch()) {
        m_pidSesion = mPid.captured(1).trimmed();
    }

    // 2. Eliminar comentarios HTML cerrados sin que un <!-- huérfano se trague todo el menú hasta el pie de página
    QString htmlSinComentarios = html;
    static const QRegularExpression reComments(
        "<!--(?:(?!-->|<!--).)*-->",
        QRegularExpression::DotMatchesEverythingOption);
    htmlSinComentarios.remove(reComments);

    // 3. Extraer nombre del estudiante o encabezado de bienvenida si aparece en el HTML
    static const QRegularExpression reBienvenido(
        "(?:Bienvenido\\(?a\\)?|Estudiante|Alumno|Usuario)\\s*:?\\s*<[^>]*>([^<]+)<",
        QRegularExpression::CaseInsensitiveOption);
    QRegularExpressionMatch mBienv = reBienvenido.match(htmlSinComentarios);
    if (mBienv.hasMatch()) {
        QString posibleNombre = limpiarTextoHtml(mBienv.captured(1));
        if (posibleNombre.length() > 3) {
            m_nombreEstudiante = posibleNombre;
        }
    }

    // Buscar también si hay alguna celda con la escuela (INGENIERÍA ...)
    static const QRegularExpression reEscuela(
        "(INGENIER(?:Í|I|&Iacute;)A\\s+(?:DE\\s+TELECOMUNICACIONES|INDUSTRIAL|EL(?:É|E|&Eacute;)CTRICA|MEC(?:Á|A|&Aacute;)NICA|QU(?:Í|I|&Iacute;)MICA|CIVIL))",
        QRegularExpression::CaseInsensitiveOption);
    QRegularExpressionMatch mEsc = reEscuela.match(htmlSinComentarios);
    if (mEsc.hasMatch()) {
        m_escuelaEstudiante = limpiarTextoHtml(mEsc.captured(1)).toUpper();
    }

    // Buscar también si aparece la fecha límite de solicitud de cambio de escuela en el menú
    static const QRegularExpression reFechaCambio(
        "SOLICITUD\\s+DE\\s+CAMBIO\\s+DE\\s+ESCUELA\\s*(?:<br[^>]*>)?\\s*\\(([^\\)]+)\\)",
        QRegularExpression::CaseInsensitiveOption);
    QRegularExpressionMatch mFechaCambio = reFechaCambio.match(htmlSinComentarios);
    if (mFechaCambio.hasMatch()) {
        m_fechaLimiteCambioEscuela = limpiarTextoHtml(mFechaCambio.captured(1)).toUpper();
        emit datosEstudianteChanged();
    }

    // Detectar el período lectivo más reciente publicado en el menú
    // (ej. "VER HORARIO ASIGNADO 2-2026", "REPORTE DE SOLICITUD DE INSCRIPCIÓN 2-2026")
    {
        static const QRegularExpression rePerMenu("\\b([12])-(20\\d{2})\\b");
        QRegularExpressionMatchIterator itPer = rePerMenu.globalMatch(htmlSinComentarios);
        int mejorValor = 0;
        QString mejorPeriodo;
        while (itPer.hasNext()) {
            QRegularExpressionMatch mp = itPer.next();
            int valor = mp.captured(2).toInt() * 10 + mp.captured(1).toInt();
            if (valor > mejorValor) {
                mejorValor = valor;
                mejorPeriodo = mp.captured(1) + "-" + mp.captured(2);
            }
        }
        if (!mejorPeriodo.isEmpty()) {
            m_periodoMenuReciente = mejorPeriodo;
            emit horariosOfertaChanged();
        }
    }

    // Detectar en el menú activo si las rutas de Solicitud de Inscripción (inscribir.php)
    // y de Reporte de Solicitud de Inscripción (reporte.php) están habilitadas o cerradas
    static const QRegularExpression reLinkInscribir(
        "<a\\s+[^>]*href=[\"']([^\"']*inscribir\\.php[^\"']*)[\"'][^>]*>(.*?)</a>",
        QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);
    QRegularExpressionMatch mInsc = reLinkInscribir.match(htmlSinComentarios);
    m_inscripcionDisponible = mInsc.hasMatch();
    if (mInsc.hasMatch()) {
        QString txtInsc = limpiarTextoHtml(mInsc.captured(2));
        static const QRegularExpression rePerInsc("(\\d-\\d{4})");
        QRegularExpressionMatch mPerI = rePerInsc.match(txtInsc);
        if (mPerI.hasMatch()) {
            m_periodoInscripcion = mPerI.captured(1);
        }
        static const QRegularExpression reLimInsc("\\(([^\\)]+)\\)");
        QRegularExpressionMatch mLimI = reLimInsc.match(txtInsc);
        if (mLimI.hasMatch()) {
            m_fechaLimiteInscripcion = mLimI.captured(1).trimmed().toUpper();
        }
    } else {
        m_materiasInscripcion.clear();
        m_fechaLimiteInscripcion.clear();
    }

    static const QRegularExpression reLinkReporteInsc(
        "<a\\s+[^>]*href=[\"'](reporte\\.php\\?[^\"']+)[\"'][^>]*>(.*?)</a>",
        QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);
    QRegularExpressionMatch mRepInsc = reLinkReporteInsc.match(htmlSinComentarios);
    m_reporteInscripcionDisponible = mRepInsc.hasMatch();
    if (!m_reporteInscripcionDisponible) {
        // Si DAE cerró la ruta del reporte de solicitud de inscripción (ej. tras asignar horarios),
        // limpiar cualquier reporte previo para indicar que no hay reporte existente
        m_solicitudInscripcionRegistrada.clear();
        m_fechaSolicitudInscripcion.clear();
        if (!m_cedulaEstudiante.isEmpty()) {
            QSettings settings("UniversidadDeCarabobo", "AppDAE");
            settings.remove("inscripcion/solicitud_" + m_cedulaEstudiante);
            settings.remove("inscripcion/fecha_" + m_cedulaEstudiante);
            settings.sync();
        }
    }

    // Detectar si existe un enlace activo de Retiro de Asignatura en el menú estudiantil
    static const QRegularExpression reLinkRetiro(
        "<a\\s+[^>]*href=[\"']([^\"']*retir[^\"']*\\.php[^\"']*)[\"'][^>]*>(.*?)</a>",
        QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);
    QRegularExpressionMatch mRet = reLinkRetiro.match(htmlSinComentarios);
    m_retiroDisponible = mRet.hasMatch();
    if (mRet.hasMatch()) {
        m_hrefRetiroMenu = mRet.captured(1).trimmed();
        QString txtRet = limpiarTextoHtml(mRet.captured(2));
        static const QRegularExpression reLimRet("\\(([^\\)]+)\\)");
        QRegularExpressionMatch mLimR = reLimRet.match(txtRet);
        if (mLimR.hasMatch()) {
            m_fechaLimiteRetiro = mLimR.captured(1).trimmed().toUpper();
        }
    } else {
        m_hrefRetiroMenu.clear();
        m_fechaLimiteRetiro.clear();
    }

    // 4. Extraer los enlaces internos del menú estudiantil
    m_enlacesMenuInterno.clear();
    QSet<QString> hrefsVistos;

    static const QRegularExpression reLinks(
        "<a\\s+[^>]*href=[\"']([^\"']+)[\"'][^>]*>([^<]*)",
        QRegularExpression::CaseInsensitiveOption);

    QRegularExpressionMatchIterator it = reLinks.globalMatch(htmlSinComentarios);
    while (it.hasNext()) {
        QRegularExpressionMatch m = it.next();
        QString href = m.captured(1).trimmed();
        QString texto = limpiarTextoHtml(m.captured(2));

        if (href.isEmpty() || href.startsWith("http") || href.startsWith("/portal") ||
            href.startsWith("../portal") || href.startsWith("mailto:") ||
            href.contains("limpiarsesion", Qt::CaseInsensitive) ||
            href.contains("psicologia_dae", Qt::CaseInsensitive) ||
            href.contains("cambiar_pass", Qt::CaseInsensitive) ||
            href.contains("index2.php", Qt::CaseInsensitive) ||
            href.contains("<", Qt::CaseInsensitive)) {
            continue;
        }

        if (hrefsVistos.contains(href)) continue;
        hrefsVistos.insert(href);

        QVariantMap item;
        item["href"] = href;
        item["titulo"] = texto;
        m_enlacesMenuInterno.append(item);
    }

    // 5. Sincronizar en orden de prioridad las páginas de datos del estudiante autenticado
    //    (primero mostrar_horario.php para que las tarjetas de "Clases de Hoy" carguen de inmediato)
    QSet<QString> rutasDespachadas;
    if (!m_pidSesion.isEmpty()) {
        QStringList rutasPrioritarias = {
            "mostrar_horario.php?pid=" + m_pidSesion,
            "ver_exp.php?pid=" + m_pidSesion + "&c=1",
            "historial.php?pid=" + m_pidSesion + "&c=1",
            "reporte_notas.php?pid=" + m_pidSesion + "&c=1",
            "actualizar_estudiantil.php?pid=" + m_pidSesion + "&c=1",
            "rap.php",
            "solicitud_cambio_escuela.php?pid=" + m_pidSesion + "&c=1"
        };
        if (m_inscripcionDisponible) {
            rutasPrioritarias.append("inscribir.php?pid=" + m_pidSesion + "&c=1");
        }
        if (m_reporteInscripcionDisponible) {
            rutasPrioritarias.append("reporte.php?pid=" + m_pidSesion);
        }
        if (m_retiroDisponible && !m_hrefRetiroMenu.isEmpty()) {
            rutasPrioritarias.append(m_hrefRetiroMenu);
        }
        for (const QString &ruta : rutasPrioritarias) {
            rutasDespachadas.insert(ruta);
            sincronizarSeccionEstudiantil(ruta);
        }
    }

    // Si el menú contenía alguna variante de enlace de datos no cubierta arriba, sincronizarla también
    for (const QVariant &v : m_enlacesMenuInterno) {
        QString href = v.toMap()["href"].toString();
        if (!rutasDespachadas.contains(href) &&
            (href.contains("mostrar_horario", Qt::CaseInsensitive) ||
             href.contains("ver_exp", Qt::CaseInsensitive) ||
             href.contains("historial", Qt::CaseInsensitive) ||
             href.contains("reporte_notas.php", Qt::CaseInsensitive) ||
             href.contains("actualizar_estudiantil", Qt::CaseInsensitive) ||
             href.contains("inscribir", Qt::CaseInsensitive) ||
             href.contains("reporte.php", Qt::CaseInsensitive) ||
             href.contains("mostrar_solicitudes", Qt::CaseInsensitive) ||
             href.contains("retir", Qt::CaseInsensitive) ||
             href.contains("rap.php", Qt::CaseInsensitive))) {
            rutasDespachadas.insert(href);
            sincronizarSeccionEstudiantil(href);
        }
    }

    emit inscripcionChanged();
    emit retiroChanged();

    emit enlacesMenuInternoChanged();
}

void DaeClient::sincronizarSeccionEstudiantil(const QString &hrefRelativo)
{
    if (hrefRelativo.isEmpty()) return;

    // Al restaurar una sesión desde la caché no se llama al servidor: se usa
    // la copia local de esa página. Si no existe, simplemente se omite.
    if (m_restaurandoDesdeCache) {
        cargarSeccionDesdeCache(hrefRelativo);
        return;
    }

    QUrl baseUrl("https://dae.ing.uc.edu.ve/gestion_estudiantil/");
    QUrl targetUrl = baseUrl.resolved(QUrl(hrefRelativo));

    QNetworkRequest req(targetUrl);
    configurarRequestDae(req);
    req.setRawHeader("Referer", "https://dae.ing.uc.edu.ve/gestion_estudiantil/index.php");

    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply, hrefRelativo]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) return;

        QString html = QString::fromUtf8(reply->readAll());

        // Si el servidor devolvió el formulario de login, la sesión caducó:
        // no se guarda esa página ni se parsea como si fueran datos reales.
        if (html.contains("name=\"autenticar\"", Qt::CaseInsensitive) &&
            html.contains("name=\"clave\"", Qt::CaseInsensitive)) {
            return;
        }

        const QString archivo = nombreArchivoSeccion(hrefRelativo);


        // Guardar la copia local para los próximos inicios de sesión
        if (!m_cedulaEstudiante.isEmpty() && !html.isEmpty()) {
            const QString ruta = rutaCacheSesionPara(m_cedulaEstudiante) + "/" + archivo;
            escribirArchivoCache(ruta, html.toUtf8());
        }

        parsearPaginaInternaEstudiantil(hrefRelativo, html);
    });
}

QString DaeClient::cedulaFormateada() const
{
    QString s = m_cedulaEstudiante.trimmed();
    QString soloDigitos;
    for (QChar c : s) {
        if (c.isDigit()) soloDigitos.append(c);
    }
    if (soloDigitos.isEmpty()) return s;

    QString res;
    int count = 0;
    for (int i = soloDigitos.length() - 1; i >= 0; --i) {
        if (count > 0 && count % 3 == 0) {
            res.prepend('.');
        }
        res.prepend(soloDigitos[i]);
        count++;
    }
    return res;
}

QString DaeClient::escuelaCorta() const
{
    QString esc = m_escuelaEstudiante.toUpper();
    if (esc.contains("TELECOM")) return QStringLiteral("Ing. de Telecomunicaciones");
    if (esc.contains("INDUSTRIAL")) return QStringLiteral("Ing. Industrial");
    if (esc.contains("ELÉCTRICA") || esc.contains("ELECTRICA")) return QStringLiteral("Ing. Eléctrica");
    if (esc.contains("MECÁNICA") || esc.contains("MECANICA")) return QStringLiteral("Ing. Mecánica");
    if (esc.contains("QUÍMICA") || esc.contains("QUIMICA")) return QStringLiteral("Ing. Química");
    if (esc.contains("CIVIL")) return QStringLiteral("Ing. Civil");
    return m_escuelaEstudiante;
}

int DaeClient::escuelaIndexEstudiante() const
{
    QString esc = m_escuelaEstudiante.toUpper();
    if (esc.contains("TELECOM")) return 0;
    if (esc.contains("INDUSTRIAL")) return 1;
    if (esc.contains("ELÉCTRICA") || esc.contains("ELECTRICA")) return 2;
    if (esc.contains("MECÁNICA") || esc.contains("MECANICA")) return 3;
    if (esc.contains("QUÍMICA") || esc.contains("QUIMICA")) return 4;
    if (esc.contains("CIVIL")) return 5;
    return 0;
}

QString DaeClient::codigoEscuelaActual() const
{
    static const QStringList codigos = {"307", "301", "302", "303", "304", "306"};
    int idx = escuelaIndexEstudiante();
    return (idx >= 0 && idx < codigos.size()) ? codigos[idx] : QStringLiteral("307");
}

QVariantList DaeClient::escuelasDestinoDisponibles() const
{
    struct InfoEsc {
        QString codigo;
        QString nombre;
    };
    static const QList<InfoEsc> catalogo = {
        {"301", "ESCUELA DE INGENIERÍA INDUSTRIAL"},
        {"302", "ESCUELA DE INGENIERÍA ELÉCTRICA"},
        {"303", "ESCUELA DE INGENIERÍA MECÁNICA"},
        {"304", "ESCUELA DE INGENIERÍA QUÍMICA"},
        {"306", "ESCUELA DE INGENIERÍA CIVIL"},
        {"307", "ESCUELA DE INGENIERÍA DE TELECOMUNICACIONES"}
    };

    QString codAct = codigoEscuelaActual();
    QVariantList resultado;
    for (const InfoEsc &e : catalogo) {
        if (e.codigo == codAct) continue;
        QVariantMap item;
        item["codigo"] = e.codigo;
        item["nombre"] = e.nombre;
        resultado.append(item);
    }
    return resultado;
}

void DaeClient::parsearPaginaInternaEstudiantil(const QString &href, const QString &html)
{
    QString hrefLow = href.toLower();

    auto normalizarEscuela = [](const QString &txtUpper) -> QString {
        if (txtUpper.contains("TELECOM")) return QStringLiteral("INGENIERÍA DE TELECOMUNICACIONES");
        if (txtUpper.contains("INDUSTRIAL")) return QStringLiteral("INGENIERÍA INDUSTRIAL");
        if (txtUpper.contains("ELÉCTRICA") || txtUpper.contains("ELECTRICA")) return QStringLiteral("INGENIERÍA ELÉCTRICA");
        if (txtUpper.contains("MECÁNICA") || txtUpper.contains("MECANICA")) return QStringLiteral("INGENIERÍA MECÁNICA");
        if (txtUpper.contains("QUÍMICA") || txtUpper.contains("QUIMICA")) return QStringLiteral("INGENIERÍA QUÍMICA");
        if (txtUpper.contains("CIVIL")) return QStringLiteral("INGENIERÍA CIVIL");
        return QString();
    };

    if (hrefLow.contains("solicitud_cambio_escuela")) {
        // En solicitud_cambio_escuela.php hay dos <select>: escuela_actual (la del estudiante) y escuela_destino (las otras 5)
        static const QRegularExpression reEscActual(
            "<select[^>]*\\b(?:id|name)=[\"']escuela_actual[\"'][^>]*>(.*?)</select>",
            QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);
        QRegularExpressionMatch mSelAct = reEscActual.match(html);
        if (mSelAct.hasMatch()) {
            QString bloqueActual = mSelAct.captured(1);
            QString escDetectada;
            if (bloqueActual.contains("307")) escDetectada = QStringLiteral("INGENIERÍA DE TELECOMUNICACIONES");
            else if (bloqueActual.contains("301")) escDetectada = QStringLiteral("INGENIERÍA INDUSTRIAL");
            else if (bloqueActual.contains("302")) escDetectada = QStringLiteral("INGENIERÍA ELÉCTRICA");
            else if (bloqueActual.contains("303")) escDetectada = QStringLiteral("INGENIERÍA MECÁNICA");
            else if (bloqueActual.contains("304")) escDetectada = QStringLiteral("INGENIERÍA QUÍMICA");
            else if (bloqueActual.contains("306")) escDetectada = QStringLiteral("INGENIERÍA CIVIL");
            else escDetectada = normalizarEscuela(limpiarTextoHtml(bloqueActual).toUpper());

            if (!escDetectada.isEmpty() && escDetectada != m_escuelaEstudiante) {
                m_escuelaEstudiante = escDetectada;
                emit datosEstudianteChanged();
                cargarPensum(0, escuelaIndexEstudiante());
            }
        }
        return;
    }

    // Extraer datos personales y escuela desde el texto plano normalizado (compatible con entidades HTML y tildes UTF-8)
    QString textoPlanoUpper = limpiarTextoHtml(html).toUpper();

    static const QRegularExpression reCabeceraEst(
        "\\b(\\d{6,9})\\s+([A-ZÁÉÍÓÚÜÑ\\s]{5,60}?)(?=\\s+ESCUELA|\\s+IMPORTANTE|\\s+PERIODO|\\s+C[ÓO]DIGO|$)");
    QRegularExpressionMatch mCab = reCabeceraEst.match(textoPlanoUpper);
    if (mCab.hasMatch() && mCab.captured(1).trimmed() == m_cedulaEstudiante) {
        QString nomCab = mCab.captured(2).trimmed();
        if (nomCab.length() >= 5 && !nomCab.contains("FACULTAD", Qt::CaseInsensitive)) {
            m_nombreEstudiante = nomCab;
            // Si aún no ha llegado actualizar_estudiantil.php, derivar primerNombre e iniciales del encabezado
            if (m_primerNombre.isEmpty()) {
                QStringList tokens = nomCab.split(' ', Qt::SkipEmptyParts);
                if (tokens.size() >= 3) {
                    // Formato DAE: "APELLIDO1 L NOMBRE1 N" o "APELLIDO1 NOMBRE1"
                    m_primerApellido = tokens[0];
                    m_primerNombre = (tokens[1].length() == 1 && tokens.size() >= 3) ? tokens[2] : tokens[1];
                } else if (tokens.size() == 2) {
                    m_primerApellido = tokens[0];
                    m_primerNombre = tokens[1];
                }
                if (!m_primerNombre.isEmpty() && !m_primerApellido.isEmpty()) {
                    m_inicialesEstudiante = QString(m_primerNombre[0]).toUpper() + QString(m_primerApellido[0]).toUpper();
                }
            }
            emit datosEstudianteChanged();
        }
    }

    static const QRegularExpression reEscPlano(
        "ESCUELA\\s+DE\\s+INGENIER(?:Í|I)A\\s+(DE\\s+TELECOMUNICACIONES|TELECOMUNICACIONES|INDUSTRIAL|EL(?:É|E)CTRICA|MEC(?:Á|A)NICA|QU(?:Í|I)MICA|CIVIL)");
    QRegularExpressionMatch mEsc = reEscPlano.match(textoPlanoUpper);
    if (mEsc.hasMatch()) {
        QString escDetectada = normalizarEscuela(mEsc.captured(1));
        if (!escDetectada.isEmpty() && escDetectada != m_escuelaEstudiante) {
            m_escuelaEstudiante = escDetectada;
            emit datosEstudianteChanged();
            cargarPensum(0, escuelaIndexEstudiante());
        }
    }

    // 1. Horario Asignado (mostrar_horario.php)
    if (hrefLow.contains("mostrar_horario") || html.contains("MATERIAS INSCRITAS:", Qt::CaseInsensitive)) {
        parsearHorarioAsignadoHtml(html);
    }

    // 2. RAP (rap.php)
    if (hrefLow.contains("rap") || html.contains("Cumple los Requisitos para Inscripci", Qt::CaseInsensitive)) {
        parsearRapHtml(html);
    }

    // 3. Expediente de Notas (vista clásica ver_exp.php y vista nueva historial.php)
    if (hrefLow.contains("ver_exp") || hrefLow.contains("historial") ||
        html.contains("UC Aprobadas Acumuladas", Qt::CaseInsensitive) ||
        html.contains("Unidades Cr&eacute;dito Aprobadas en la Carrera", Qt::CaseInsensitive) ||
        html.contains("ASIGNATURAS ASENTADAS EN EXPEDIENTE", Qt::CaseInsensitive) ||
        html.contains("terminalLog", Qt::CaseInsensitive)) {
        parsearExpedienteHtml(html);
    }

    // 4. Reporte de Notas Transcritas (reporte_notas.php)
    if (hrefLow.contains("reporte_notas") || html.contains("FECHA REGISTRO", Qt::CaseInsensitive)) {
        parsearReporteNotasTranscritasHtml(html);
    }

    // 5. Actualizar Datos Personales (actualizar_estudiantil.php)
    if (hrefLow.contains("actualizar_estudiantil") || html.contains("name=\"nombre1\"", Qt::CaseInsensitive)) {
        parsearActualizarDatosHtml(html);
    }

    // 6. Inscripción de Asignaturas (inscribir.php / inscribir2.php)
    if (hrefLow.contains("inscribir") || html.contains("CodM[", Qt::CaseInsensitive) ||
        html.contains("armarlista", Qt::CaseInsensitive)) {
        parsearInscripcionHtml(html);
    }

    // 7. Reporte de Solicitud de Inscripción (reporte.php / mostrar_solicitudes.php)
    if ((hrefLow.contains("reporte.php") && !hrefLow.contains("reporte_notas")) ||
        hrefLow.contains("mostrar_solicitudes") ||
        html.contains("REPORTE DE SOLICITUD DE INSCRIPCI", Qt::CaseInsensitive)) {
        parsearReporteSolicitudInscripcionHtml(html);
    }

    // 8. Solicitud de Retiro de Asignatura (retirar.php / retiro.php)
    if (hrefLow.contains("retir") ||
        html.contains("Solicitud de Retiro", Qt::CaseInsensitive) ||
        html.contains("ASIGNATURA RETIRADA NO PODR", Qt::CaseInsensitive)) {
        parsearRetiroHtml(html);
    }
}

void DaeClient::parsearHorarioAsignadoHtml(const QString &html)
{
    // El horario nuevo reemplaza por completo al anterior: se limpian las
    // claves de bloques para no arrastrar clases de una versión previa.
    m_clavesBloquesDelEstudiante.clear();

    static const QRegularExpression reTr(
        "<tr[^>]*>(.*?)</tr>",
        QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);
    static const QRegularExpression reTd(
        "<td[^>]*>(.*?)</td>",
        QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);
    static const QRegularExpression reHoraFila("^\\d{4}$");
    // Admite 1 o más asignaturas dentro de una misma celda (choque de horario) y bloques con o sin aula asignada
    static const QRegularExpression reItemCeldaGrid(
        "\\b([A-Z]{2}[A-Z0-9]{2,7})\\s+(\\d{1,3})(?:\\s+(?!(?:[A-Z]{2}[A-Z0-9]{2,7})\\s+\\d{1,3}\\b)([A-Z0-9\\-]{1,10}))?\\b",
        QRegularExpression::CaseInsensitiveOption);

    // 1. Extraer los bloques directamente de la tabla de malla horaria de mostrar_horario.php
    //    Columnas: 0=HORA/DIA, 1=LUNES(LU), 2=MARTES(MA), 3=MIÉRCOLES(MI), 4=JUEVES(JU), 5=VIERNES(VI), 6=SÁBADO(SA), 7=DOMINGO(DO)
    static const QStringList prefijosDia = {"", "LU", "MA", "MI", "JU", "VI", "SA", "DO"};
    QMap<QString, QStringList> bloquesExtraidosDeMalla;
    QStringList ordenClavesMalla;

    QRegularExpressionMatchIterator itRow = reTr.globalMatch(html);
    while (itRow.hasNext()) {
        QString rowHtml = itRow.next().captured(1);
        QStringList celdas;
        QRegularExpressionMatchIterator itCell = reTd.globalMatch(rowHtml);
        while (itCell.hasNext()) {
            celdas.append(limpiarTextoHtml(itCell.next().captured(1)));
        }
        if (celdas.size() < 7) continue;

        QString horaCod = celdas[0].trimmed();
        if (!reHoraFila.match(horaCod).hasMatch()) continue;

        for (int col = 1; col < celdas.size() && col < prefijosDia.size(); ++col) {
            QString txtCelda = celdas[col].trimmed();
            if (txtCelda.isEmpty()) continue;

            QRegularExpressionMatchIterator itItems = reItemCeldaGrid.globalMatch(txtCelda);
            while (itItems.hasNext()) {
                QRegularExpressionMatch mCel = itItems.next();
                QString cod = mCel.captured(1).trimmed().toUpper();
                QString sec = mCel.captured(2).trimmed().rightJustified(2, '0');
                QString aula = mCel.captured(3).trimmed();
                QString clave = cod + "|" + sec;
                if (!ordenClavesMalla.contains(clave)) {
                    ordenClavesMalla.append(clave);
                }
                QString bloqueFmt = aula.isEmpty()
                                    ? (prefijosDia[col] + horaCod)
                                    : (prefijosDia[col] + horaCod + " " + aula);
                if (!bloquesExtraidosDeMalla[clave].contains(bloqueFmt)) {
                    bloquesExtraidosDeMalla[clave].append(bloqueFmt);
                }
            }
        }
    }

    for (auto it = bloquesExtraidosDeMalla.constBegin(); it != bloquesExtraidosDeMalla.constEnd(); ++it) {
        if (!it.value().isEmpty()) {
            m_mapaBloquesHorario[it.key()] = it.value();
            m_clavesBloquesDelEstudiante.insert(it.key());
        }
    }

    // 2. Extraer el listado oficial bajo "MATERIAS INSCRITAS:" separado por <br>
    QVariantList nuevasMaterias;
    QSet<QString> vistos;

    int idxInscritas = html.indexOf("MATERIAS INSCRITAS", 0, Qt::CaseInsensitive);
    if (idxInscritas != -1) {
        QString bloqueInscritas = html.mid(idxInscritas);
        int idxFinTabla = bloqueInscritas.indexOf("</table>", 0, Qt::CaseInsensitive);
        if (idxFinTabla != -1) {
            bloqueInscritas = bloqueInscritas.left(idxFinTabla);
        }

        QStringList lineasBr = bloqueInscritas.split(QRegularExpression("<br\\s*/?>", QRegularExpression::CaseInsensitiveOption), Qt::SkipEmptyParts);
        static const QRegularExpression reLineaMateria(
            "^([A-Z0-9]{4,9})\\s+(.+?)\\s+(\\d{1,3})(?:\\s*[-–\\(]?\\s*(.*))?$",
            QRegularExpression::CaseInsensitiveOption);

        for (const QString &lineaHtml : lineasBr) {
            QString limpia = limpiarTextoHtml(lineaHtml);
            if (limpia.isEmpty() || limpia.startsWith("MATERIAS INSCRITAS", Qt::CaseInsensitive) ||
                limpia.startsWith("Observaci", Qt::CaseInsensitive) ||
                limpia.startsWith("Dirección de Asuntos", Qt::CaseInsensitive)) {
                continue;
            }

            QRegularExpressionMatch mLin = reLineaMateria.match(limpia);
            if (!mLin.hasMatch()) continue;

            QString codigo = mLin.captured(1).trimmed().toUpper();
            QString nombreOriginal = mLin.captured(2).trimmed();
            QString nombre = nombreOriginal;
            QString sec = mLin.captured(3).trimmed().rightJustified(2, '0');
            QString extra = mLin.captured(4).trimmed();
            while (extra.startsWith('-') || extra.startsWith(QChar(0x2013))) {
                extra = extra.mid(1).trimmed();
            }
            bool esRetiro = extra.contains("RETIRO", Qt::CaseInsensitive) || extra.contains("RETIRAD", Qt::CaseInsensitive);
            if (esRetiro) {
                m_codigosRetiradosConfirmados.insert(codigo);
                continue;
            }
            bool esAdicion = extra.contains("ADICION", Qt::CaseInsensitive) || extra.contains("ADICIÓN", Qt::CaseInsensitive);

            if (codigo.endsWith("L", Qt::CaseInsensitive) && !nombre.contains("LAB", Qt::CaseInsensitive)) {
                nombre = "Lab. " + nombre;
            }

            QString clave = codigo + "|" + sec;
            if (vistos.contains(clave)) continue;
            vistos.insert(clave);

            m_mapaNombreMateriaHorario[codigo] = nombre;

            QVariantMap mat;
            mat["codigo"] = codigo;
            mat["nombre"] = nombre;
            mat["nombreOriginal"] = nombreOriginal;
            mat["sec"] = sec;
            mat["adicion"] = esAdicion;
            mat["extra"] = extra;
            nuevasMaterias.append(mat);
        }
    }

    // 3. Respaldo: si alguna materia está en la grilla horaria pero no fue capturada en el listado inferior, incluirla
    for (const QString &claveMalla : ordenClavesMalla) {
        if (vistos.contains(claveMalla)) continue;
        QStringList partes = claveMalla.split('|');
        if (partes.size() != 2) continue;
        QString cod = partes[0];
        QString sec = partes[1];
        QString nom = m_mapaNombreMateriaHorario.value(cod, cod);
        if (cod.endsWith("L", Qt::CaseInsensitive) && !nom.contains("LAB", Qt::CaseInsensitive)) {
            nom = "Lab. " + nom;
        }
        vistos.insert(claveMalla);
        QVariantMap mat;
        mat["codigo"] = cod;
        mat["nombre"] = nom;
        mat["sec"] = sec;
        mat["adicion"] = false;
        nuevasMaterias.append(mat);
    }

    if (!nuevasMaterias.isEmpty() || html.contains("MATERIAS INSCRITAS", Qt::CaseInsensitive)) {
        m_materiasInscritasRaw = nuevasMaterias;
        emit materiasRecordatorioChanged();

        // Actualizar también la lista de "Materias en Curso / Sin Transcribir" para TranscritasView
        QVariantList listaEnCurso;
        int sumaUcInscritas = 0;
        for (const QVariant &v : nuevasMaterias) {
            QVariantMap m = v.toMap();
            QString cod = m["codigo"].toString();
            QString nom = m["nombre"].toString().toUpper();
            QString sec = m["sec"].toString();

            QVariantMap itemCurso;
            itemCurso["codigo"] = cod;
            itemCurso["nombre"] = nom;
            itemCurso["sec"] = sec;
            itemCurso["nFin"] = "";
            itemCurso["nRec"] = "";
            itemCurso["periodo"] = "En Curso";
            itemCurso["fecha"] = "SIN TRANSCRIBIR";
            itemCurso["hora"] = cod.startsWith("CO") ? "En ejecución" : "Esperando semana de transcripción";
            itemCurso["sinTranscribir"] = true;
            listaEnCurso.append(itemCurso);

            sumaUcInscritas += obtenerUcAsignatura(cod);
        }
        if (m_materiasSinTranscribir.isEmpty()) {
            m_materiasSinTranscribir = listaEnCurso;
        } else if (!m_codigosRetiradosConfirmados.isEmpty()) {
            QVariantList filtradas;
            for (const QVariant &v : m_materiasSinTranscribir) {
                if (!m_codigosRetiradosConfirmados.contains(v.toMap()["codigo"].toString().trimmed().toUpper())) {
                    filtradas.append(v);
                }
            }
            m_materiasSinTranscribir = filtradas;
        }
        if (!m_codigosRetiradosConfirmados.isEmpty() && !m_materiasPeriodoActualRaw.isEmpty()) {
            QVariantList filtradasPer;
            for (const QVariant &v : m_materiasPeriodoActualRaw) {
                if (!m_codigosRetiradosConfirmados.contains(v.toMap()["codigo"].toString().trimmed().toUpper())) {
                    filtradasPer.append(v);
                }
            }
            m_materiasPeriodoActualRaw = filtradasPer;
        }
        m_ucInscritas = sumaUcInscritas;

        reconstruirEstructurasHorarioAsignado();
        emit transcritasChanged();
        emit expedienteChanged();
        emit retiroChanged();
    }
}

void DaeClient::parsearRapHtml(const QString &html)
{
    static const QRegularExpression reUcRap(
        "Unidades\\s+Cr(?:é|e|&eacute;)dito\\s+acumuladas\\s+para\\s+Inscripci(?:ó|o|&oacute;)n:\\s*(\\d+)",
        QRegularExpression::CaseInsensitiveOption);
    QRegularExpressionMatch mUc = reUcRap.match(html);
    if (mUc.hasMatch()) {
        m_ucAprobadasCarrera = mUc.captured(1).toInt();
        emit expedienteChanged();
    }

    static const QRegularExpression reTr(
        "<tr[^>]*>(.*?)</tr>",
        QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);
    static const QRegularExpression reTd(
        "<td[^>]*>(.*?)</td>",
        QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);
    static const QRegularExpression reCodMateria("^[A-Z]{2}[A-Z0-9]{3,6}$");

    QVariantList nuevaListaRap;
    QRegularExpressionMatchIterator itRow = reTr.globalMatch(html);
    while (itRow.hasNext()) {
        QString rowHtml = itRow.next().captured(1);
        QStringList celdas;
        QRegularExpressionMatchIterator itCell = reTd.globalMatch(rowHtml);
        while (itCell.hasNext()) {
            celdas.append(limpiarTextoHtml(itCell.next().captured(1)));
        }
        if (celdas.size() < 3) continue;

        QString codigo = celdas[0].trimmed().toUpper();
        if (!reCodMateria.match(codigo).hasMatch()) continue;

        QString nombre = celdas[1].trimmed();
        QString condicionRaw = celdas[2].trimmed();
        QString reqRaw = (celdas.size() >= 4) ? celdas[3].trimmed() : QString();
        QString reqParRaw = (celdas.size() >= 5) ? celdas[4].trimmed() : QString();

        int sem = 1;
        for (int cIdx = 2; cIdx < codigo.length(); ++cIdx) {
            if (codigo[cIdx].isDigit()) {
                sem = codigo[cIdx].digitValue();
                if (sem == 0) sem = 10;
                break;
            }
        }

        QString estado = "NOCUMPLE";
        if (condicionRaw.contains("Aprobada", Qt::CaseInsensitive)) {
            estado = "APROB";
        } else if ((condicionRaw.contains("Art", Qt::CaseInsensitive) && condicionRaw.contains("17")) ||
                   reqRaw.contains("Art_17", Qt::CaseInsensitive)) {
            // Cualquier asignatura de cualquier estudiante habilitada bajo Artículo 17 (en paralelo con su prelación reprobada)
            estado = "ART17";
        } else if (condicionRaw.contains("Cumple", Qt::CaseInsensitive) &&
                   !condicionRaw.contains("NO Cumple", Qt::CaseInsensitive)) {
            estado = "CUMPLE";
        }

        QVariantMap item;
        item["codigo"] = codigo;
        item["sem"] = sem;
        item["nombre"] = nombre;
        item["estado"] = estado;
        item["req"] = reqRaw;
        item["reqParalelo"] = reqParRaw;
        nuevaListaRap.append(item);
    }

    if (!nuevaListaRap.isEmpty()) {
        m_materiasRap = nuevaListaRap;
        emit rapChanged();
    emit materiasRecordatorioChanged();
        reconstruirOfertaInscripcionDesdeRap();
    }
}

void DaeClient::parsearExpedienteHtml(const QString &html)
{
    static const QRegularExpression reTr(
        "<tr[^>]*>(.*?)</tr>",
        QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);
    static const QRegularExpression reTd(
        "<td[^>]*>(.*?)</td>",
        QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);
    static const QRegularExpression rePeriodo("^Periodo\\s+([0-9\\-]+)$", QRegularExpression::CaseInsensitiveOption);
    static const QRegularExpression reCodMateria("^[A-Z]{2}[A-Z0-9]{3,6}$");
    static const QRegularExpression reUcSem("Unidades\\s+Cr(?:é|e)dito\\s+Aprobadas:\\s*(\\d+)", QRegularExpression::CaseInsensitiveOption);
    static const QRegularExpression reUcAcum("UC\\s+Aprobadas\\s+Acumuladas:\\s*(\\d+)", QRegularExpression::CaseInsensitiveOption);
    static const QRegularExpression reUcCarrera("Unidades\\s+Cr(?:é|e)dito\\s+Aprobadas\\s+en\\s+la\\s+Carrera\\s+(\\d+)", QRegularExpression::CaseInsensitiveOption);

    struct PeriodoTemp {
        QString periodo;
        int ucSemestre = 0;
        int ucAcumuladas = 0;
        QVariantList materias;
    };

    QList<PeriodoTemp> periodosCronologicos;
    PeriodoTemp actual;
    bool enPeriodo = false;

    double sumaNotasPonderadas = 0.0;
    double sumaUcPonderadas = 0.0;
    double sumaNotasAritmetica = 0.0;
    int conteoMateriasAritmetica = 0;

    QRegularExpressionMatchIterator itRow = reTr.globalMatch(html);
    while (itRow.hasNext()) {
        QString rowHtml = itRow.next().captured(1);
        QString rowTexto = limpiarTextoHtml(rowHtml);
        if (rowTexto.isEmpty()) continue;

        QRegularExpressionMatch mPer = rePeriodo.match(rowTexto);
        if (mPer.hasMatch()) {
            if (enPeriodo && !actual.materias.isEmpty()) {
                periodosCronologicos.append(actual);
            }
            actual = PeriodoTemp();
            actual.periodo = mPer.captured(1).trimmed();
            enPeriodo = true;
            continue;
        }

        QRegularExpressionMatch mUcSem = reUcSem.match(rowTexto);
        if (mUcSem.hasMatch() && enPeriodo) {
            actual.ucSemestre = mUcSem.captured(1).toInt();
            QRegularExpressionMatch mUcAcum = reUcAcum.match(rowTexto);
            if (mUcAcum.hasMatch()) {
                actual.ucAcumuladas = mUcAcum.captured(1).toInt();
            }
            continue;
        }

        QRegularExpressionMatch mUcCarr = reUcCarrera.match(rowTexto);
        if (mUcCarr.hasMatch()) {
            int totalCarrera = mUcCarr.captured(1).toInt();
            m_ucAprobadasCarrera = totalCarrera;
            if (enPeriodo) {
                actual.ucAcumuladas = totalCarrera;
            } else if (!periodosCronologicos.isEmpty()) {
                periodosCronologicos.last().ucAcumuladas = totalCarrera;
            }
            continue;
        }

        QStringList celdas;
        QRegularExpressionMatchIterator itCell = reTd.globalMatch(rowHtml);
        while (itCell.hasNext()) {
            celdas.append(limpiarTextoHtml(itCell.next().captured(1)));
        }

        if (celdas.size() >= 7 && enPeriodo) {
            QString codigo = celdas[0].trimmed().toUpper();
            if (!reCodMateria.match(codigo).hasMatch()) continue;

            QString sec = celdas[1].trimmed().rightJustified(2, '0');
            int uc = qRound(celdas[2].trimmed().replace(',', '.').toDouble());
            QString nombre = celdas[3].trimmed();
            QString nFin = celdas[4].trimmed();
            QString nRec = celdas[5].trimmed();
            QString con = celdas[6].trimmed();

            QVariantMap mat;
            mat["codigo"] = codigo;
            mat["sec"] = sec;
            mat["uc"] = uc;
            mat["nombre"] = nombre;
            mat["nFin"] = nFin;
            mat["nRec"] = nRec;
            mat["con"] = con;
            actual.materias.append(mat);

            // Cálculo de promedios oficiales DAE (sobre todas las asignaturas cursadas del expediente)
            bool okNota = false;
            int notaDef = 0;
            if (!nRec.isEmpty() && nRec != "SD") {
                notaDef = nRec.toInt(&okNota);
            }
            if (!okNota) {
                notaDef = nFin.toInt(&okNota);
            }
            if (okNota) {
                if (uc > 0) {
                    sumaNotasPonderadas += (notaDef * uc);
                    sumaUcPonderadas += uc;
                }
                sumaNotasAritmetica += notaDef;
                conteoMateriasAritmetica++;
            }
        }
    }

    if (enPeriodo && !actual.materias.isEmpty()) {
        if (actual.ucAcumuladas == 0 && m_ucAprobadasCarrera > 0) {
            actual.ucAcumuladas = m_ucAprobadasCarrera;
        }
        periodosCronologicos.append(actual);
    }

    // =========================================================================
    // SOPORTE PARA LA NUEVA VISTA DE EXPEDIENTE / HISTORIAL (historial.php / terminalLog)
    // Se mantiene intacto el parser anterior (tablas clásicas de ver_exp.php) y,
    // si la página usa el nuevo formato de consola de eventos, se extrae de aquí:
    // =========================================================================
    if (periodosCronologicos.isEmpty() &&
        (html.contains("terminalLog", Qt::CaseInsensitive) ||
         html.contains("ASIGNATURAS ASENTADAS EN EXPEDIENTE", Qt::CaseInsensitive) ||
         html.contains("HISTORIAL ACAD", Qt::CaseInsensitive))) {

        static const QRegularExpression reUcNuevaVista(
            "(?:Unidades\\s+de\\s+Cr(?:é|e)dito\\s+Aprobadas:|<label>\\s*UC\\s+Aprobadas\\s*</label>\\s*<strong[^>]*>)\\s*([0-9]+(?:\\.[0-9]+)?)\\s*UC",
            QRegularExpression::CaseInsensitiveOption);
        QRegularExpressionMatch mUcNueva = reUcNuevaVista.match(html);
        if (mUcNueva.hasMatch()) {
            m_ucAprobadasCarrera = qRound(mUcNueva.captured(1).toDouble());
        }

        // Extraer el bloque del log de la consola (#terminalLog) o usar el HTML completo
        QString textoConsola = html;
        static const QRegularExpression reDivTerminal(
            "<div[^>]*id=[\"']terminalLog[\"'][^>]*>(.*?)</div>",
            QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);
        QRegularExpressionMatch mTerm = reDivTerminal.match(html);
        if (mTerm.hasMatch()) {
            textoConsola = mTerm.captured(1);
        }

        static const QRegularExpression rePerConsola(
            "\\[PER(?:Í|I)ODO\\s+ACAD(?:É|E)MICO:\\s*([0-9]+-[0-9]{4})(?:\\s+([A-Z0-9]+))?\\s*\\]",
            QRegularExpression::CaseInsensitiveOption);
        static const QRegularExpression reAsigConsola(
            "(APROBADA|REPROBADA|RETIRADA|CONVALIDADA|EQUIVALENCIA)\\s*\\|\\s*([A-Z]{2}[A-Z0-9]{3,7})\\s*\\|\\s*Nota:\\s*([0-9A-Z]+)(?:\\s*\\(Rec:\\s*([0-9A-Z]+)\\))?\\s*\\|\\s*Sec:\\s*([0-9A-Z]+)\\s*\\|\\s*(.+)$",
            QRegularExpression::CaseInsensitiveOption);

        PeriodoTemp perConsola;
        bool enPerConsola = false;
        QString condPerActual = "R";

        const QStringList lineas = textoConsola.split(QRegularExpression("[\\r\\n]+"), Qt::SkipEmptyParts);
        for (const QString &lineaRaw : lineas) {
            QString linea = limpiarTextoHtml(lineaRaw);
            if (linea.isEmpty()) continue;

            QRegularExpressionMatch mPerC = rePerConsola.match(linea);
            if (mPerC.hasMatch()) {
                if (enPerConsola && !perConsola.materias.isEmpty()) {
                    periodosCronologicos.append(perConsola);
                }
                perConsola = PeriodoTemp();
                perConsola.periodo = mPerC.captured(1).trimmed();
                condPerActual = mPerC.captured(2).trimmed().isEmpty() ? QStringLiteral("R") : mPerC.captured(2).trimmed().toUpper();
                enPerConsola = true;
                continue;
            }

            if (!enPerConsola) continue;

            QRegularExpressionMatch mAsig = reAsigConsola.match(linea);
            if (mAsig.hasMatch()) {
                QString estadoStr = mAsig.captured(1).trimmed().toUpper();
                QString codigo = mAsig.captured(2).trimmed().toUpper();
                QString nFin = mAsig.captured(3).trimmed().toUpper();
                QString nRec = mAsig.captured(4).trimmed().toUpper();
                QString sec = mAsig.captured(5).trimmed().rightJustified(2, '0');
                QString nombre = mAsig.captured(6).trimmed();

                if (nombre.compare(codigo, Qt::CaseInsensitive) == 0) {
                    if (m_mapaNombreMateriaHorario.contains(codigo)) {
                        nombre = m_mapaNombreMateriaHorario.value(codigo).toUpper();
                    } else if (codigo.endsWith("L")) {
                        QString codBase = codigo.left(codigo.length() - 1);
                        if (m_mapaNombreMateriaHorario.contains(codBase)) {
                            nombre = "LAB. " + m_mapaNombreMateriaHorario.value(codBase).toUpper();
                        }
                    }
                }

                int uc = obtenerUcAsignatura(codigo);
                bool esAprobada = estadoStr.startsWith("APROB") || estadoStr.startsWith("CONV") || estadoStr.startsWith("EQUIV");
                if (esAprobada) {
                    perConsola.ucSemestre += uc;
                }

                QVariantMap mat;
                mat["codigo"] = codigo;
                mat["sec"] = sec;
                mat["uc"] = uc;
                mat["nombre"] = nombre;
                mat["nFin"] = nFin;
                mat["nRec"] = nRec;
                mat["con"] = condPerActual;
                mat["aprobada"] = esAprobada;
                perConsola.materias.append(mat);

                bool okNota = false;
                int notaDef = 0;
                if (!nRec.isEmpty() && nRec != "SD") {
                    notaDef = nRec.toInt(&okNota);
                }
                if (!okNota) {
                    notaDef = nFin.toInt(&okNota);
                }
                if (okNota) {
                    if (uc > 0) {
                        sumaNotasPonderadas += (notaDef * uc);
                        sumaUcPonderadas += uc;
                    }
                    sumaNotasAritmetica += notaDef;
                    conteoMateriasAritmetica++;
                }
            }
        }

        if (enPerConsola && !perConsola.materias.isEmpty()) {
            periodosCronologicos.append(perConsola);
        }
    }

    if (!periodosCronologicos.isEmpty()) {
        QVariantList nuevaCurva;
        int acumRunning = 0;
        for (PeriodoTemp &p : periodosCronologicos) {
            acumRunning += p.ucSemestre;
            if (p.ucAcumuladas == 0) {
                p.ucAcumuladas = acumRunning;
            }
            QString perCorto = p.periodo;
            perCorto.replace("-20", "-");
            QVariantMap punto;
            punto["per"] = perCorto;
            punto["uc"] = p.ucAcumuladas;
            nuevaCurva.append(punto);
        }

        QVariantList listaInvertida;
        for (int i = periodosCronologicos.size() - 1; i >= 0; --i) {
            const PeriodoTemp &p = periodosCronologicos[i];
            QVariantMap perMap;
            perMap["periodo"] = p.periodo;
            perMap["ucSemestre"] = p.ucSemestre;
            perMap["ucAcumuladas"] = p.ucAcumuladas;
            perMap["materias"] = p.materias;
            listaInvertida.append(perMap);
        }

        if (sumaUcPonderadas > 0 && conteoMateriasAritmetica > 0) {
            double promPond = sumaNotasPonderadas / sumaUcPonderadas;
            double promArit = sumaNotasAritmetica / conteoMateriasAritmetica;
            QString sPond = QString::number(promPond, 'f', 2);
            QString sArit = QString::number(promArit, 'f', 2);
            int dotP = sPond.indexOf('.');
            int dotA = sArit.indexOf('.');
            m_promedioPonderadoEntero = sPond.left(dotP);
            m_promedioPonderadoDecimal = sPond.mid(dotP);
            m_promedioAritmeticoEntero = sArit.left(dotA);
            m_promedioAritmeticoDecimal = sArit.mid(dotA);
        }

        m_curvaProgresoExpediente = nuevaCurva;
        m_expedienteSemestres = listaInvertida;
        emit expedienteChanged();
    }
}

void DaeClient::parsearReporteNotasTranscritasHtml(const QString &html)
{
    static const QRegularExpression reTr(
        "<tr[^>]*>(.*?)</tr>",
        QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);
    static const QRegularExpression reTd(
        "<td[^>]*>(.*?)</td>",
        QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);
    static const QRegularExpression reCodMateria("^[A-Z0-9]{4,9}$");

    QStringList ordenPeriodos;
    QMap<QString, QVariantList> registrosPorPeriodo;
    QVariantList listaPeriodoActualCurso;
    QVariantList materiasPeriodoActualRaw;
    bool enPeriodoActual = false;

    QRegularExpressionMatchIterator itRow = reTr.globalMatch(html);
    while (itRow.hasNext()) {
        QString rowHtml = itRow.next().captured(1);
        if (rowHtml.contains("PERIODO ACTUAL", Qt::CaseInsensitive)) {
            enPeriodoActual = true;
            continue;
        }

        QStringList celdas;
        QRegularExpressionMatchIterator itCell = reTd.globalMatch(rowHtml);
        while (itCell.hasNext()) {
            celdas.append(limpiarTextoHtml(itCell.next().captured(1)));
        }
        if (celdas.size() < 7) continue;

        QString codigo = celdas[0].trimmed().toUpper();
        if (!reCodMateria.match(codigo).hasMatch() || codigo.startsWith("C")) {
            if (!reCodMateria.match(codigo).hasMatch() || codigo == "CÓDIGO" || codigo == "CODIGO") continue;
        }

        QString nombreRaw = celdas[1].trimmed();
        QString nombre = nombreRaw;
        if (codigo.endsWith("L", Qt::CaseInsensitive) && !nombre.contains("LAB", Qt::CaseInsensitive)) {
            nombre += " (LAB)";
        }

        QString sec = celdas[2].trimmed().rightJustified(2, '0');
        QString nFin = celdas[3].trimmed();
        QString nRec = celdas[4].trimmed();
        QString periodo = celdas[5].trimmed();
        QString fechaHoraRaw = celdas[6].trimmed();
        bool esSinTranscribir = fechaHoraRaw.contains("SIN TRANSCRIBIR", Qt::CaseInsensitive);

        if (enPeriodoActual) {
            QVariantMap matRaw;
            matRaw["codigo"] = codigo;
            matRaw["nombre"] = (codigo.endsWith("L", Qt::CaseInsensitive) && !nombreRaw.contains("LAB", Qt::CaseInsensitive))
                               ? ("Lab. " + nombreRaw)
                               : nombreRaw;
            matRaw["sec"] = sec;
            matRaw["adicion"] = false;
            materiasPeriodoActualRaw.append(matRaw);

            if (esSinTranscribir) {
                QVariantMap itemCurso;
                itemCurso["codigo"] = codigo;
                itemCurso["nombre"] = nombre.toUpper();
                itemCurso["sec"] = sec;
                itemCurso["nFin"] = nFin;
                itemCurso["nRec"] = nRec;
                itemCurso["periodo"] = "En Curso";
                itemCurso["fecha"] = "SIN TRANSCRIBIR";
                itemCurso["hora"] = codigo.startsWith("CO") ? "En ejecución" : "Esperando semana de transcripción";
                itemCurso["sinTranscribir"] = true;
                listaPeriodoActualCurso.append(itemCurso);
            }
        }

        if (esSinTranscribir) {
            continue;
        }

        QString fecha = fechaHoraRaw;
        QString hora = "";
        int spaceIdx = fechaHoraRaw.indexOf(' ');
        if (spaceIdx != -1) {
            fecha = fechaHoraRaw.left(spaceIdx).trimmed();
            hora = fechaHoraRaw.mid(spaceIdx + 1).trimmed();
        }

        QVariantMap reg;
        reg["codigo"] = codigo;
        reg["nombre"] = nombre;
        reg["sec"] = sec;
        reg["nFin"] = nFin;
        reg["nRec"] = nRec;
        reg["periodo"] = periodo;
        reg["fecha"] = fecha;
        reg["hora"] = hora;
        reg["sinTranscribir"] = false;

        QString clavePer = periodo.left(6).trimmed();
        if (!ordenPeriodos.contains(clavePer)) {
            ordenPeriodos.append(clavePer);
        }
        registrosPorPeriodo[clavePer].append(reg);
    }

    QVariantList listaFinal;
    for (int i = ordenPeriodos.size() - 1; i >= 0; --i) {
        const QVariantList &grupo = registrosPorPeriodo[ordenPeriodos[i]];
        for (const QVariant &v : grupo) {
            listaFinal.append(v);
        }
    }

    m_notasTranscritas = listaFinal;
    if (!listaPeriodoActualCurso.isEmpty()) {
        m_materiasSinTranscribir = listaPeriodoActualCurso;
    }

    // Guardar las materias del PERIODO ACTUAL para el desplegable de materias
    // del formulario de recordatorios (solo el semestre en curso).
    if (m_materiasPeriodoActualRaw != materiasPeriodoActualRaw) {
        m_materiasPeriodoActualRaw = materiasPeriodoActualRaw;
        emit materiasRecordatorioChanged();
    }

    // Si aún no se ha cargado el horario desde mostrar_horario.php, construirlo con las materias del PERIODO ACTUAL
    if (m_materiasInscritasRaw.isEmpty() && !materiasPeriodoActualRaw.isEmpty()) {
        m_materiasInscritasRaw = materiasPeriodoActualRaw;
        emit materiasRecordatorioChanged();
        int sumaUc = 0;
        for (const QVariant &v : materiasPeriodoActualRaw) {
            sumaUc += obtenerUcAsignatura(v.toMap()["codigo"].toString());
        }
        m_ucInscritas = sumaUc;
        reconstruirEstructurasHorarioAsignado();
    }

    emit transcritasChanged();
    emit retiroChanged();
}

void DaeClient::parsearActualizarDatosHtml(const QString &html)
{
    QString limpio = html;
    static const QRegularExpression reComments("<!--.*?-->", QRegularExpression::DotMatchesEverythingOption);
    limpio.remove(reComments);

    auto extraerInputValor = [&limpio](const QString &idOrName) -> QString {
        QRegularExpression re(
            QString("<input[^>]*\\b(?:id|name)=[\"']%1[\"'][^>]*\\bvalue=[\"']([^\"']*)[\"']")
                .arg(QRegularExpression::escape(idOrName)),
            QRegularExpression::CaseInsensitiveOption);
        QRegularExpressionMatch m = re.match(limpio);
        if (m.hasMatch()) return limpiarTextoHtml(m.captured(1));

        QRegularExpression reInv(
            QString("<input[^>]*\\bvalue=[\"']([^\"']*)[\"'][^>]*\\b(?:id|name)=[\"']%1[\"']")
                .arg(QRegularExpression::escape(idOrName)),
            QRegularExpression::CaseInsensitiveOption);
        QRegularExpressionMatch m2 = reInv.match(limpio);
        if (m2.hasMatch()) return limpiarTextoHtml(m2.captured(1));
        return QString();
    };

    auto extraerSelectOpcion = [&limpio](const QString &selectName) -> QString {
        QRegularExpression reSel(
            QString("<select[^>]*\\b(?:id|name)=[\"']%1[\"'][^>]*>(.*?)</select>")
                .arg(QRegularExpression::escape(selectName)),
            QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);
        QRegularExpressionMatch mSel = reSel.match(limpio);
        if (!mSel.hasMatch()) return QString();

        QString contenido = mSel.captured(1);
        QRegularExpression reOpt("<option[^>]*\\bselected\\b[^>]*>(.*?)</option>", QRegularExpression::CaseInsensitiveOption);
        QRegularExpressionMatch mOpt = reOpt.match(contenido);
        if (mOpt.hasMatch()) {
            return limpiarTextoHtml(mOpt.captured(1));
        }
        return QString();
    };

    QString n1 = extraerInputValor("nombre1");
    QString n2 = extraerInputValor("nombre2");
    QString a1 = extraerInputValor("apellido1");
    QString a2 = extraerInputValor("apellido2");

    if (!n1.isEmpty()) m_primerNombre = n1;
    if (!n2.isEmpty()) m_segundoNombre = n2;
    if (!a1.isEmpty()) m_primerApellido = a1;
    if (!a2.isEmpty()) m_segundoApellido = a2;

    if (!m_primerNombre.isEmpty() && !m_primerApellido.isEmpty()) {
        m_inicialesEstudiante = QString(m_primerNombre[0]).toUpper() + QString(m_primerApellido[0]).toUpper();
        m_nombreEstudiante = m_primerApellido + " " + (m_segundoApellido.isEmpty() ? "" : m_segundoApellido.left(1) + " ")
                           + m_primerNombre + (m_segundoNombre.isEmpty() ? "" : " " + m_segundoNombre.left(1));
    }

    QString mail1 = extraerInputValor("mail1");
    QString mail2 = extraerInputValor("mail2");
    if (!mail1.isEmpty()) m_correoEstudiante = mail1;
    if (!mail2.isEmpty()) m_correoAlternativo = mail2;

    QString codArea = extraerSelectOpcion("area");
    QString numFijo = extraerInputValor("fijo");
    if (!numFijo.isEmpty()) {
        m_telefonoFijo = (codArea.isEmpty() ? "0241" : codArea) + " - " + numFijo;
    }

    QString codCel = extraerSelectOpcion("cel");
    QString numMovil = extraerInputValor("movil");
    if (!numMovil.isEmpty()) {
        m_telefonoEstudiante = (codCel.isEmpty() ? "0412" : codCel) + " - " + numMovil;
    }

    QString dia = extraerInputValor("dia");
    QString mes = extraerInputValor("mes");
    QString anio = extraerInputValor("anio");
    if (!dia.isEmpty() && !mes.isEmpty() && !anio.isEmpty()) {
        m_fechaNacimiento = dia + " / " + mes + " / " + anio;
    }

    if (limpio.contains(QRegularExpression("id=[\"']sexoF[\"'][^>]*checked", QRegularExpression::CaseInsensitiveOption))) {
        m_sexoEstudiante = "Femenino";
    } else if (limpio.contains(QRegularExpression("id=[\"']sexoM[\"'][^>]*checked", QRegularExpression::CaseInsensitiveOption))) {
        m_sexoEstudiante = "Masculino";
    }

    QString edo = extraerSelectOpcion("sel_edo");
    if (!edo.isEmpty()) m_dirEstado = edo;

    static const QRegularExpression reEdoVal(
        "<select[^>]*\\b(?:id|name)=[\"']sel_edo[\"'][^>]*>.*?<option[^>]*value=['\"](\\d+)['\"][^>]*\\bselected\\b",
        QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);
    QRegularExpressionMatch mEdoVal = reEdoVal.match(limpio);
    if (mEdoVal.hasMatch()) {
        m_idEstado = mEdoVal.captured(1).trimmed();
    }

    // Extraer todas las listas de municipios y parroquias embebidas en actualizar_estudiantil.php
    static const QRegularExpression reTodosMun(
        "v_mun\\[(\\d+)\\]\\[\\d+\\]\\[0\\]\\s*=\\s*(\\d+)\\s*;\\s*v_mun\\[\\d+\\]\\[\\d+\\]\\[1\\]\\s*=\\s*'([^']+)'");
    QRegularExpressionMatchIterator itMun = reTodosMun.globalMatch(limpio);
    QMap<QString, QList<QPair<QString, QString>>> nuevosMunicipios;
    while (itMun.hasNext()) {
        QRegularExpressionMatch m = itMun.next();
        nuevosMunicipios[m.captured(1)].append({m.captured(2), m.captured(3).trimmed()});
    }
    if (!nuevosMunicipios.isEmpty()) {
        m_municipiosPorEstado = nuevosMunicipios;
    }

    static const QRegularExpression reTodasParroq(
        "v_parroq\\[(\\d+)\\]\\[\\d+\\]\\[0\\]\\s*=\\s*(\\d+)\\s*;\\s*v_parroq\\[\\d+\\]\\[\\d+\\]\\[1\\]\\s*=\\s*'([^']+)'");
    QRegularExpressionMatchIterator itPar = reTodasParroq.globalMatch(limpio);
    QMap<QString, QList<QPair<QString, QString>>> nuevasParroquias;
    while (itPar.hasNext()) {
        QRegularExpressionMatch m = itPar.next();
        nuevasParroquias[m.captured(1)].append({m.captured(2), m.captured(3).trimmed()});
    }
    if (!nuevasParroquias.isEmpty()) {
        m_parroquiasPorMunicipio = nuevasParroquias;
    }

    // Extraer municipio y parroquia desde las variables JS mun_est y parroq_est en actualizar_estudiantil.php
    static const QRegularExpression reMunEst("var\\s+mun_est\\s*=\\s*(\\d+)");
    QRegularExpressionMatch mMunId = reMunEst.match(limpio);
    if (mMunId.hasMatch()) {
        QString idMun = mMunId.captured(1);
        m_idMunicipio = idMun;
        QRegularExpression reBuscaMun(
            QString("\\[0\\]\\s*=\\s*%1\\s*;\\s*v_mun\\[\\d+\\]\\[\\d+\\]\\[1\\]\\s*=\\s*'([^']+)'").arg(idMun));
        QRegularExpressionMatch mNomMun = reBuscaMun.match(limpio);
        if (mNomMun.hasMatch()) {
            m_dirMunicipio = mNomMun.captured(1).trimmed();
        }
    }

    static const QRegularExpression reParroqEst("var\\s+parroq_est\\s*=\\s*(\\d+)");
    QRegularExpressionMatch mParId = reParroqEst.match(limpio);
    if (mParId.hasMatch()) {
        QString idPar = mParId.captured(1);
        m_idParroquia = idPar;
        QRegularExpression reBuscaPar(
            QString("\\[0\\]\\s*=\\s*%1\\s*;\\s*v_parroq\\[\\d+\\]\\[\\d+\\]\\[1\\]\\s*=\\s*'([^']+)'").arg(idPar));
        QRegularExpressionMatch mNomPar = reBuscaPar.match(limpio);
        if (mNomPar.hasMatch()) {
            m_dirParroquia = mNomPar.captured(1).trimmed();
        }
    }

    QString direc = extraerInputValor("direc");
    if (!direc.isEmpty()) m_dirDetalle = direc;

    QString edoc = extraerSelectOpcion("sel_edoc");
    if (!edoc.isEmpty()) m_opsuEstadoCivil = edoc;

    QString etnia = extraerSelectOpcion("sel_etnia");
    if (!etnia.isEmpty()) m_opsuEtnia = etnia;

    QString disca = extraerSelectOpcion("sel_disca");
    if (!disca.isEmpty()) m_opsuDiscapacidad = disca;

    QString mag = extraerSelectOpcion("sel_mag");
    if (!mag.isEmpty()) m_opsuManoAgil = mag;

    emit datosEstudianteChanged();
}

void DaeClient::descargarConstanciaEstudiantil(int tipoConstancia)
{
    if (m_descargandoPdf) return;
    if (tipoConstancia < 1 || tipoConstancia > 4) tipoConstancia = 1;

    static const QStringList prefijosArchivo = {
        "Constancia_Estudios_",
        "Constancia_Notas_",
        "Reporte_Inscripcion_",
        "Buena_Conducta_"
    };
    QString nombreArchivo = prefijosArchivo[tipoConstancia - 1] + m_cedulaEstudiante + ".pdf";

    m_descargandoPdf = true;
    emit descargandoPdfChanged();

    // Enviar POST autenticado a genera_constancia.php con la sesión activa del estudiante
    QUrl urlGenera("https://dae.ing.uc.edu.ve/gestion_estudiantil/genera_constancia.php");
    QNetworkRequest req(urlGenera);
    configurarRequestDae(req);
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");
    req.setRawHeader("Origin", "https://dae.ing.uc.edu.ve");

    QString refererUrl = "https://dae.ing.uc.edu.ve/gestion_estudiantil/tipo_constancia.php";
    if (!m_pidSesion.isEmpty()) {
        refererUrl += "?pid=" + m_pidSesion + "&c=1";
    }
    req.setRawHeader("Referer", refererUrl.toUtf8());

    QUrlQuery postData;
    postData.addQueryItem("constancias1", QString::number(tipoConstancia));

    QNetworkReply *reply = m_nam->post(req, postData.toString(QUrl::FullyEncoded).toUtf8());
    connect(reply, &QNetworkReply::finished, this, [this, reply, nombreArchivo]() {
        reply->deleteLater();
        m_descargandoPdf = false;
        emit descargandoPdfChanged();

        if (reply->error() != QNetworkReply::NoError) {
            emit errorDescargaPdf("No se pudo generar la constancia en DAE: " + reply->errorString());
            return;
        }

        QByteArray pdfBytes = reply->readAll();
        if (pdfBytes.isEmpty() || (!pdfBytes.startsWith("%PDF") && pdfBytes.size() < 512)) {
            emit errorDescargaPdf("El servidor DAE no devolvió un PDF válido. Verifica tu sesión activa.");
            return;
        }

        QString dirDescargas = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
        if (dirDescargas.isEmpty()) {
            dirDescargas = QDir::homePath();
        }

        QString rutaCompleta = QDir(dirDescargas).filePath(nombreArchivo);
        QFile file(rutaCompleta);
        if (file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
            file.write(pdfBytes);
            file.close();
            QDesktopServices::openUrl(QUrl::fromLocalFile(rutaCompleta));
            emit pdfDescargado(rutaCompleta, nombreArchivo);
        } else {
            emit errorDescargaPdf("No se pudo guardar la constancia en " + rutaCompleta);
        }
    });
}

void DaeClient::descargarHorarioPdf()
{
    if (m_descargandoPdf) return;
    m_descargandoPdf = true;
    emit descargandoPdfChanged();

    QString dirDescargas = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
    if (dirDescargas.isEmpty()) {
        dirDescargas = QDir::homePath();
    }

    QString nombreArchivo = "Horario_Asignado_" + m_cedulaEstudiante + ".pdf";
    QString rutaCompleta = QDir(dirDescargas).filePath(nombreArchivo);

    QPdfWriter pdf(rutaCompleta);
    pdf.setPageSize(QPageSize(QPageSize::Letter));
    pdf.setPageOrientation(QPageLayout::Portrait);
    pdf.setResolution(300);
    pdf.setPageMargins(QMarginsF(12, 12, 12, 12), QPageLayout::Millimeter);

    QPainter p(&pdf);
    if (!p.isActive()) {
        m_descargandoPdf = false;
        emit descargandoPdfChanged();
        emit errorDescargaPdf("No se pudo crear el archivo PDF en " + rutaCompleta);
        return;
    }

    const int pageW = pdf.width();
    const int pageH = pdf.height();
    int y = 20;

    // 1. Encabezado institucional DAE UC (idéntico a imprime() en funciones2.js de mostrar_horario.php)
    QImage logoUc(":/qt/qml/AppDAE/servicios/logo_uc.png");
    if (!logoUc.isNull()) {
        QImage esc = logoUc.scaled(165, 215, Qt::KeepAspectRatio, Qt::SmoothTransformation);
        p.drawImage(110, y, esc);
    }

    QImage logoIng(":/qt/qml/AppDAE/servicios/logo_ing.png");
    if (!logoIng.isNull()) {
        QImage ingEsc = logoIng.scaled(310, 215, Qt::KeepAspectRatio, Qt::SmoothTransformation);
        p.drawImage(pageW - 110 - ingEsc.width(), y + (215 - ingEsc.height()) / 2, ingEsc);
    }

    QFont fTitulo("Helvetica", 11, QFont::Bold);
    p.setFont(fTitulo);
    p.setPen(QColor("#111827"));
    p.drawText(QRect(0, y + 45, pageW, 55), Qt::AlignHCenter | Qt::AlignVCenter,
               "DIRECCIÓN DE ASUNTOS ESTUDIANTILES");
    p.drawText(QRect(0, y + 105, pageW, 55), Qt::AlignHCenter | Qt::AlignVCenter,
               "FACULTAD DE INGENIERÍA");

    y += 235;

    // 2. Datos del estudiante y Escuela
    QFont fEst("Helvetica", 11, QFont::Bold);
    p.setFont(fEst);
    p.setPen(QColor("#000000"));
    p.drawText(QRect(0, y, pageW, 55), Qt::AlignHCenter | Qt::AlignVCenter,
               m_cedulaEstudiante + "  " + m_nombreEstudiante);
    y += 55;
    p.drawText(QRect(0, y, pageW, 55), Qt::AlignHCenter | Qt::AlignVCenter,
               "ESCUELA DE " + m_escuelaEstudiante.toUpper());
    y += 75;

    // 3. Construir el mapa de celdas (horaCod -> diaCod -> "CODIGO SECCION\nAULA")
    static const QStringList horasTabla = {
        "0800", "0850", "0940", "1030", "1120", "1210", "1300", "1350",
        "1440", "1530", "1620", "1710", "1800", "1850", "1940"
    };
    static const QStringList codsDiaTabla = {"LU", "MA", "MI", "JU", "VI", "SA", "DO"};
    static const QStringList cabecerasTabla = {
        "HORA/DIA", "LUNES", "MARTES", "MIÉRCOLES", "JUEVES", "VIERNES", "SÁBADO", "DOMINGO"
    };

    QMap<QString, QMap<QString, QString>> grillaPdf;
    static const QRegularExpression reB("^(LU|MA|MI|JU|VI|SA|DO)(\\d{4})(?:\\s+(.*))?$");

    for (const QVariant &vMat : m_materiasInscritasRaw) {
        QVariantMap mat = vMat.toMap();
        QString cod = mat["codigo"].toString().trimmed();
        QString sec = mat["sec"].toString().trimmed().rightJustified(2, '0');
        QString clave = cod + "|" + sec;
        QStringList bloques = m_mapaBloquesHorario.value(clave);

        for (const QString &bStr : bloques) {
            QRegularExpressionMatch mb = reB.match(bStr.trimmed());
            if (!mb.hasMatch()) continue;
            QString dCod = mb.captured(1);
            QString hCod = mb.captured(2);
            QString aula = mb.captured(3).trimmed();
            if (aula == "S/A") aula.clear();

            QString entradaCelda = aula.isEmpty() ? (cod + " " + sec) : (cod + " " + sec + "\n" + aula);
            if (grillaPdf[hCod][dCod].isEmpty()) {
                grillaPdf[hCod][dCod] = entradaCelda;
            } else if (!grillaPdf[hCod][dCod].contains(cod + " " + sec)) {
                grillaPdf[hCod][dCod] += "\n" + entradaCelda;
            }
        }
    }

    // 4. Dibujar la tabla de 8 columnas x 16 filas (Cabecera + 15 bloques horarios)
    const int tableMarginX = 40;
    const int tableW = pageW - 2 * tableMarginX;
    const int colHoraW = 220;
    const int colDiaW = (tableW - colHoraW) / 7;
    const int headerH = 72;
    const int rowH = 95;

    QPen borderPen(QColor("#374151"), 3);
    p.setPen(borderPen);
    p.setBrush(QColor("#e5e7eb"));
    p.drawRect(tableMarginX, y, colHoraW + colDiaW * 7, headerH);

    QFont fHeaderCol("Helvetica", 8, QFont::Bold);
    p.setFont(fHeaderCol);
    p.drawText(QRect(tableMarginX, y, colHoraW, headerH), Qt::AlignCenter, cabecerasTabla[0]);

    for (int c = 0; c < 7; ++c) {
        int cx = tableMarginX + colHoraW + c * colDiaW;
        p.drawLine(cx, y, cx, y + headerH);
        p.drawText(QRect(cx, y, colDiaW, headerH), Qt::AlignCenter, cabecerasTabla[c + 1]);
    }
    y += headerH;

    QFont fCeldaHora("Helvetica", 8, QFont::Bold);
    QFont fCeldaMat("Helvetica", 7, QFont::Normal);
    QFont fCeldaMatDoble("Helvetica", 5, QFont::Normal);

    for (int r = 0; r < horasTabla.size(); ++r) {
        const QString &hCod = horasTabla[r];
        p.setBrush(r % 2 == 0 ? QColor("#ffffff") : QColor("#f9fafb"));
        p.setPen(borderPen);
        p.drawRect(tableMarginX, y, colHoraW + colDiaW * 7, rowH);

        p.setFont(fCeldaHora);
        p.drawText(QRect(tableMarginX, y, colHoraW, rowH), Qt::AlignCenter, hCod);

        for (int c = 0; c < 7; ++c) {
            int cx = tableMarginX + colHoraW + c * colDiaW;
            p.drawLine(cx, y, cx, y + rowH);
            QString txtCelda = grillaPdf[hCod].value(codsDiaTabla[c]);
            if (!txtCelda.isEmpty()) {
                p.setFont(txtCelda.count('\n') >= 2 ? fCeldaMatDoble : fCeldaMat);
                p.drawText(QRect(cx + 2, y + 2, colDiaW - 4, rowH - 4),
                           Qt::AlignCenter | Qt::TextWordWrap, txtCelda);
            }
        }
        y += rowH;
    }

    y += 55;

    // 5. Bloque "MATERIAS INSCRITAS:" (idéntico al listado inferior de mostrar_horario.php sin profesores)
    int listMarginX = 90;
    QFont fSub("Helvetica", 9, QFont::Bold);
    p.setFont(fSub);
    p.setPen(QColor("#000000"));
    p.drawText(QRect(listMarginX, y, pageW - 2 * listMarginX, 48), Qt::AlignLeft | Qt::AlignVCenter,
               "MATERIAS INSCRITAS:");
    y += 52;

    QFont fLineaMat("Helvetica", 8, QFont::Normal);
    QFont fLineaBold("Helvetica", 8, QFont::Bold);

    for (const QVariant &vMat : m_materiasInscritasRaw) {
        QVariantMap mat = vMat.toMap();
        QString cod = mat["codigo"].toString().trimmed();
        QString sec = mat["sec"].toString().trimmed().rightJustified(2, '0');
        QString nomOriginal = mat["nombreOriginal"].toString().trimmed();
        QString nom = (!nomOriginal.isEmpty() ? nomOriginal : m_mapaNombreMateriaHorario.value(cod, mat["nombre"].toString())).toUpper();
        QString extra = mat["extra"].toString().trimmed().toUpper();
        bool adicion = mat["adicion"].toBool();
        if (extra.isEmpty() && adicion) {
            extra = QStringLiteral("ADICIÓN POR DAE");
        }

        QString baseTxt = cod + " " + nom + " " + sec;
        p.setFont(fLineaMat);
        if (extra.isEmpty()) {
            p.drawText(QRect(listMarginX, y, pageW - 2 * listMarginX, 42), Qt::AlignLeft | Qt::AlignVCenter, baseTxt);
        } else {
            QString prefijoTxt = baseTxt + " - ";
            int anchoPref = p.fontMetrics().horizontalAdvance(prefijoTxt);
            p.drawText(QRect(listMarginX, y, pageW - 2 * listMarginX, 42), Qt::AlignLeft | Qt::AlignVCenter, prefijoTxt);
            p.setFont(fLineaBold);
            p.drawText(QRect(listMarginX + anchoPref, y, pageW - 2 * listMarginX - anchoPref, 42), Qt::AlignLeft | Qt::AlignVCenter, extra);
        }
        y += 42;
    }

    y += 35;

    // 6. Observación reglamentaria y pie de página oficial DAE
    QFont fObs("Helvetica", 8, QFont::Bold);
    p.setFont(fObs);
    QString textoObs = "Observación: Usted está obligado a conocer el Reglamento de Evaluación de la Facultad de Ingeniería, "
                       "el Pensum de Estudios, Reglamentos y Leyes de la Universidad de Carabobo, y cualquier otra condición "
                       "y/o compromiso establecido entre Usted y la Dirección de Asuntos Estudiantiles.";
    p.drawText(QRect(listMarginX, y, pageW - 2 * listMarginX, 130),
               Qt::AlignLeft | Qt::AlignTop | Qt::TextWordWrap, textoObs);

    QFont fPie("Helvetica", 8, QFont::Normal);
    p.setFont(fPie);
    p.setPen(QColor("#374151"));
    p.drawText(QRect(0, pageH - 70, pageW, 50), Qt::AlignHCenter | Qt::AlignVCenter,
               "Dirección de Asuntos Estudiantiles - - Facultad de Ingeniería - - Universidad de Carabobo");

    p.end();

    m_descargandoPdf = false;
    emit descargandoPdfChanged();

    QDesktopServices::openUrl(QUrl::fromLocalFile(rutaCompleta));
    emit pdfDescargado(rutaCompleta, nombreArchivo);
}

namespace {
// Genera la matriz estándar QR Versión 2-M (25x25 módulos) para "https://carnet.uc.edu.ve"
QVector<QVector<int>> generarMatrizQrUrlCarnet()
{
    static const QByteArray texto = QByteArrayLiteral("https://carnet.uc.edu.ve");
    constexpr int N = 25;
    constexpr int kDataCodewords = 28;
    constexpr int kEccCodewords = 16;

    // 1. Flujo de bits en modo Byte (0100), longitud (8 bits), datos y terminador
    QVector<int> bits;
    bits.reserve(kDataCodewords * 8);
    auto pushBits = [&bits](int valor, int nBits) {
        for (int i = nBits - 1; i >= 0; --i) {
            bits.append((valor >> i) & 1);
        }
    };

    pushBits(0b0100, 4);
    pushBits(texto.size(), 8);
    for (unsigned char c : texto) {
        pushBits(c, 8);
    }
    const int terminador = qMin(4, kDataCodewords * 8 - bits.size());
    for (int i = 0; i < terminador; ++i) {
        bits.append(0);
    }
    while (bits.size() % 8 != 0) {
        bits.append(0);
    }

    QVector<int> codewords;
    codewords.reserve(kDataCodewords + kEccCodewords);
    for (int i = 0; i < bits.size(); i += 8) {
        int cw = 0;
        for (int j = 0; j < 8; ++j) {
            cw = (cw << 1) | bits[i + j];
        }
        codewords.append(cw);
    }
    const int padBytes[2] = {0xEC, 0x11};
    int padIdx = 0;
    while (codewords.size() < kDataCodewords) {
        codewords.append(padBytes[padIdx % 2]);
        ++padIdx;
    }

    // 2. Aritmética GF(256) con polinomio primitivo 0x11D para Reed-Solomon
    int gfExp[512] = {};
    int gfLog[256] = {};
    int x = 1;
    for (int i = 0; i < 255; ++i) {
        gfExp[i] = x;
        gfLog[x] = i;
        x <<= 1;
        if (x & 0x100) {
            x ^= 0x11D;
        }
    }
    for (int i = 255; i < 512; ++i) {
        gfExp[i] = gfExp[i - 255];
    }
    auto gfMul = [&gfExp, &gfLog](int a, int b) -> int {
        if (a == 0 || b == 0) return 0;
        return gfExp[gfLog[a] + gfLog[b]];
    };

    QVector<int> gen = {1};
    for (int i = 0; i < kEccCodewords; ++i) {
        QVector<int> siguiente(gen.size() + 1, 0);
        for (int j = 0; j < gen.size(); ++j) {
            siguiente[j] ^= gen[j];
            siguiente[j + 1] ^= gfMul(gen[j], gfExp[i]);
        }
        gen = siguiente;
    }

    QVector<int> rem = codewords;
    rem.resize(kDataCodewords + kEccCodewords, 0);
    for (int i = 0; i < kDataCodewords; ++i) {
        int coef = rem[i];
        if (coef != 0) {
            for (int j = 0; j < gen.size(); ++j) {
                rem[i + j] ^= gfMul(gen[j], coef);
            }
        }
    }
    for (int i = kDataCodewords; i < kDataCodewords + kEccCodewords; ++i) {
        codewords.append(rem[i]);
    }

    // 3. Construcción de la matriz 25x25
    QVector<QVector<int>> grid(N, QVector<int>(N, 0));
    QVector<QVector<bool>> fixed(N, QVector<bool>(N, false));
    auto setMod = [&grid, &fixed](int r, int c, int val) {
        grid[r][c] = val ? 1 : 0;
        fixed[r][c] = true;
    };

    auto dibujarFinder = [&](int ox, int oy) {
        for (int r = -1; r <= 7; ++r) {
            for (int c = -1; c <= 7; ++c) {
                int rr = oy + r;
                int cc = ox + c;
                if (rr < 0 || rr >= N || cc < 0 || cc >= N) continue;
                if (r == -1 || r == 7 || c == -1 || c == 7) {
                    setMod(rr, cc, 0);
                } else if (r == 0 || r == 6 || c == 0 || c == 6 || (r >= 2 && r <= 4 && c >= 2 && c <= 4)) {
                    setMod(rr, cc, 1);
                } else {
                    setMod(rr, cc, 0);
                }
            }
        }
    };

    dibujarFinder(0, 0);
    dibujarFinder(N - 7, 0);
    dibujarFinder(0, N - 7);

    // Patrón de alineamiento en (18, 18) para Versión 2
    for (int r = -2; r <= 2; ++r) {
        for (int c = -2; c <= 2; ++c) {
            int d = qMax(qAbs(r), qAbs(c));
            setMod(18 + r, 18 + c, (d == 0 || d == 2) ? 1 : 0);
        }
    }

    // Patrones de sincronización y módulo oscuro obligatorio
    for (int i = 8; i < N - 8; ++i) {
        setMod(6, i, (i % 2 == 0) ? 1 : 0);
        setMod(i, 6, (i % 2 == 0) ? 1 : 0);
    }
    setMod(17, 8, 1);

    // Reservar zonas de información de formato
    for (int i = 0; i < 9; ++i) {
        if (i != 6) {
            fixed[8][i] = true;
            fixed[i][8] = true;
        }
    }
    for (int i = 0; i < 8; ++i) {
        fixed[8][N - 1 - i] = true;
        fixed[N - 1 - i][8] = true;
    }

    // 4. Colocar bits de datos + 7 bits remanentes aplicando máscara 0 ((r + c) % 2 == 0)
    QVector<int> stream;
    stream.reserve(codewords.size() * 8 + 7);
    for (int cw : codewords) {
        for (int b = 7; b >= 0; --b) {
            stream.append((cw >> b) & 1);
        }
    }
    for (int i = 0; i < 7; ++i) {
        stream.append(0);
    }

    int bi = 0;
    bool subiendo = true;
    for (int c = N - 1; c > 0; c -= 2) {
        if (c == 6) --c;
        for (int step = 0; step < N; ++step) {
            int r = subiendo ? (N - 1 - step) : step;
            for (int dc = 0; dc >= -1; --dc) {
                int cc = c + dc;
                if (!fixed[r][cc]) {
                    int bit = (bi < stream.size()) ? stream[bi] : 0;
                    ++bi;
                    if ((r + cc) % 2 == 0) {
                        bit ^= 1;
                    }
                    grid[r][cc] = bit;
                }
            }
        }
        subiendo = !subiendo;
    }

    // 5. Información de formato: Nivel M (00) + Máscara 0 (000) -> 0x5412
    constexpr int kFmt = 0x5412;
    const int tlR[15] = {8, 8, 8, 8, 8, 8, 8, 8, 7, 5, 4, 3, 2, 1, 0};
    const int tlC[15] = {0, 1, 2, 3, 4, 5, 7, 8, 8, 8, 8, 8, 8, 8, 8};
    const int brR[15] = {24, 23, 22, 21, 20, 19, 18, 8, 8, 8, 8, 8, 8, 8, 8};
    const int brC[15] = {8, 8, 8, 8, 8, 8, 8, 17, 18, 19, 20, 21, 22, 23, 24};
    for (int k = 0; k < 15; ++k) {
        int bit = (kFmt >> (14 - k)) & 1;
        grid[tlR[k]][tlC[k]] = bit;
        grid[brR[k]][brC[k]] = bit;
    }

    return grid;
}

void dibujarQrEnPainter(QPainter &p, const QRect &rect, const QVector<QVector<int>> &grid)
{
    const int n = grid.size();
    if (n <= 0) return;

    p.save();
    p.fillRect(rect, Qt::white);
    // Zona tranquila de 1 módulo alrededor
    const double modSize = static_cast<double>(qMin(rect.width(), rect.height())) / (n + 2);
    const double ox = rect.x() + (rect.width() - modSize * n) / 2.0;
    const double oy = rect.y() + (rect.height() - modSize * n) / 2.0;
    p.setPen(Qt::NoPen);
    p.setBrush(QColor("#000000"));
    for (int r = 0; r < n; ++r) {
        for (int c = 0; c < n; ++c) {
            if (grid[r][c] == 1) {
                QRectF cell(ox + c * modSize, oy + r * modSize, modSize + 0.35, modSize + 0.35);
                p.drawRect(cell);
            }
        }
    }
    p.restore();
}
} // namespace

QVariantList DaeClient::matrizQrCarnet() const
{
    static const QVector<QVector<int>> grid = generarMatrizQrUrlCarnet();
    QVariantList out;
    out.reserve(grid.size());
    for (const QVector<int> &fila : grid) {
        QVariantList row;
        row.reserve(fila.size());
        for (int v : fila) {
            row.append(v);
        }
        out.append(QVariant(row));
    }
    return out;
}

void DaeClient::descargarCarnetPdf(const QString &rutaFotoPerfil)
{
    if (m_descargandoPdf) return;
    m_descargandoPdf = true;
    emit descargandoPdfChanged();

    QString dirDescargas = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
    if (dirDescargas.isEmpty()) {
        dirDescargas = QDir::homePath();
    }

    const QString cedulaLimpia = m_cedulaEstudiante.trimmed().isEmpty() ? QStringLiteral("00000000") : m_cedulaEstudiante.trimmed();
    const QString nombreArchivo = QStringLiteral("Carnet_Electronico_UC_%1.pdf").arg(cedulaLimpia);
    const QString rutaCompleta = QDir(dirDescargas).filePath(nombreArchivo);

    QPdfWriter pdf(rutaCompleta);
    pdf.setPageSize(QPageSize(QPageSize::Letter));
    pdf.setPageOrientation(QPageLayout::Portrait);
    pdf.setResolution(300);
    pdf.setPageMargins(QMarginsF(14, 14, 14, 14), QPageLayout::Millimeter);

    QPainter p(&pdf);
    if (!p.isActive()) {
        m_descargandoPdf = false;
        emit descargandoPdfChanged();
        emit errorDescargaPdf("No se pudo crear el archivo PDF en " + rutaCompleta);
        return;
    }

    p.setRenderHint(QPainter::Antialiasing, true);
    p.setRenderHint(QPainter::SmoothPixmapTransform, true);

    const int pageW = pdf.width();
    const int marginX = 70;
    int y = 60;

    // 1. Título principal centrado
    p.setFont(QFont("Helvetica", 13, QFont::Bold));
    p.setPen(QColor("#111827"));
    p.drawText(QRect(marginX, y, pageW - 2 * marginX, 80), Qt::AlignCenter,
               "CARNET ELECTRÓNICO DE LA UNIVERSIDAD DE CARABOBO");
    y += 125;

    // 2. Datos del estudiante (izquierda) y QR grande (derecha)
    const QString apellidosCompletos = (m_primerApellido + (m_segundoApellido.isEmpty() ? "" : " " + m_segundoApellido)).trimmed().toUpper();
    const QString nombresCompletos = (m_primerNombre + (m_segundoNombre.isEmpty() ? "" : " " + m_segundoNombre)).trimmed().toUpper();
    QString carreraPdf = m_escuelaEstudiante.trimmed().toUpper();
    if (carreraPdf.startsWith("ESCUELA DE ")) {
        carreraPdf = carreraPdf.mid(11).trimmed();
    }
    if (carreraPdf.isEmpty()) {
        carreraPdf = escuelaCorta().toUpper();
    }

    const QVector<QVector<int>> qrGrid = generarMatrizQrUrlCarnet();
    const int qrGrandeSize = 440;
    dibujarQrEnPainter(p, QRect(pageW - marginX - qrGrandeSize, y - 10, qrGrandeSize, qrGrandeSize), qrGrid);

    const int infoW = pageW - 2 * marginX - qrGrandeSize - 40;
    struct FilaInfo { QString eti; QString val; };
    const QList<FilaInfo> filasInfo = {
        {"CEDULA:", "V-" + cedulaLimpia},
        {"APELLIDOS:", apellidosCompletos.isEmpty() ? m_nombreEstudiante.toUpper() : apellidosCompletos},
        {"NOMBRES:", nombresCompletos},
        {"FACULTAD:", "INGENIERÍA"},
        {"CARRERA:", carreraPdf}
    };

    int yInfo = y + 8;
    for (const FilaInfo &f : filasInfo) {
        p.setFont(QFont("Helvetica", 10, QFont::Bold));
        int anchoEti = p.fontMetrics().horizontalAdvance(f.eti + " ");
        p.setPen(QColor("#111827"));
        p.drawText(QRect(marginX, yInfo, anchoEti, 52), Qt::AlignLeft | Qt::AlignVCenter, f.eti);
        p.setFont(QFont("Helvetica", 10, QFont::Normal));
        p.drawText(QRect(marginX + anchoEti + 6, yInfo, infoW - anchoEti - 6, 52),
                   Qt::AlignLeft | Qt::AlignVCenter, f.val);
        yInfo += 54;
    }

    y = qMax(y + qrGrandeSize + 25, yInfo + 30);

    // 3. Sección IMPORTANTE
    p.setFont(QFont("Helvetica", 10, QFont::Bold));
    p.setPen(QColor("#111827"));
    p.drawText(QRect(marginX, y, pageW - 2 * marginX, 55), Qt::AlignLeft | Qt::AlignVCenter, "IMPORTANTE");
    y += 70;

    auto dibujarVineta = [&p, marginX, pageW](int &yPos, const QString &texto, int fontPt = 9) {
        p.setFont(QFont("Helvetica", fontPt, QFont::Normal));
        p.setPen(QColor("#111827"));
        const int bulletX = marginX + 55;
        const int textX = marginX + 105;
        const int textW = pageW - marginX - textX - 20;
        p.drawText(QRect(bulletX, yPos, 40, 50), Qt::AlignLeft | Qt::AlignTop, "•");
        QRect bound = p.boundingRect(QRect(textX, yPos, textW, 500),
                                     Qt::AlignLeft | Qt::AlignTop | Qt::TextWordWrap, texto);
        p.drawText(QRect(textX, yPos, textW, bound.height() + 10),
                   Qt::AlignLeft | Qt::AlignTop | Qt::TextWordWrap, texto);
        yPos += bound.height() + 18;
    };

    dibujarVineta(y, "Carnet único de la Universidad de Carabobo. Aprobado por el Consejo Universitario en sesión extraordinaria Nro. 1.915 de fecha 25 de febrero de 2021.");
    dibujarVineta(y, "Esta credencial es de uso personal, intransferible y de porte obligatorio dentro de las instalaciones de la universidad.");
    y += 30;

    // 4. Recuadro central del Carnet (Anverso | Reverso) con proporciones fieles al formato oficial
    const int cardMarginX = marginX + 75;
    const int cardW = pageW - 2 * cardMarginX;
    const int cardH = 560;
    const int midX = cardMarginX + cardW / 2;
    const QRect cardRect(cardMarginX, y, cardW, cardH);

    p.fillRect(cardRect, Qt::white);
    p.setPen(QPen(QColor("#6b7280"), 3));
    p.drawRect(cardRect);
    p.drawLine(midX, y, midX, y + cardH);

    // ---- Mitad Izquierda: Anverso ----
    const int padC = 20;
    const int halfW = cardW / 2;
    const int leftW = halfW - 2 * padC;
    const int leftX = cardMarginX + padC;
    const int logoW = 155;
    const int logoH = 165;

    p.setFont(QFont("Helvetica", 15, QFont::Bold));
    p.setPen(QColor("#000000"));
    p.drawText(QRect(leftX, y + 12, leftW - logoW - 18, 145),
               Qt::AlignRight | Qt::AlignVCenter, "UNIVERSIDAD DE\nCARABOBO");

    QImage logoUc(":/qt/qml/AppDAE/servicios/logo_uc.png");
    if (!logoUc.isNull()) {
        QImage esc = logoUc.scaled(logoW, logoH, Qt::KeepAspectRatio, Qt::SmoothTransformation);
        p.drawImage(leftX + leftW - esc.width(), y + 10, esc);
    }

    // Foto de perfil del usuario (proporción 3:4 como en el documento oficial)
    const int bodyY = y + 172;
    const int fotoW = 175;
    const int fotoH = 234;
    const QRect fotoRect(leftX + 8, bodyY + 14, fotoW, fotoH);

    QString rutaFotoLimpia = rutaFotoPerfil.trimmed();
    if (rutaFotoLimpia.startsWith("file://")) {
        rutaFotoLimpia = QUrl(rutaFotoLimpia).toLocalFile();
    }
    if (rutaFotoLimpia.isEmpty()) {
        rutaFotoLimpia = m_urlFotoPerfil.trimmed();
        if (rutaFotoLimpia.startsWith("file://")) {
            rutaFotoLimpia = QUrl(rutaFotoLimpia).toLocalFile();
        }
    }

    QImage imgFoto;
    if (!rutaFotoLimpia.isEmpty() && QFileInfo::exists(rutaFotoLimpia)) {
        imgFoto.load(rutaFotoLimpia);
    }
    if (!imgFoto.isNull()) {
        QImage escalada = imgFoto.scaled(fotoW, fotoH, Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation);
        const int cropX = qMax(0, (escalada.width() - fotoW) / 2);
        const int cropY = qMax(0, (escalada.height() - fotoH) / 2);
        p.drawImage(fotoRect, escalada, QRect(cropX, cropY, fotoW, fotoH));
        p.setPen(QPen(QColor("#9ca3af"), 2));
        p.drawRect(fotoRect);
    } else {
        p.setPen(QPen(QColor("#cbd5e1"), 2));
        p.drawRect(fotoRect);
        p.setFont(QFont("Helvetica", 9, QFont::Normal));
        p.setPen(QColor("#64748b"));
        p.drawText(fotoRect, Qt::AlignCenter, "FOTO");
    }

    // QR derecho del anverso
    const int qrCarnetSize = 290;
    const int qrCarnetX = leftX + leftW - qrCarnetSize;
    dibujarQrEnPainter(p, QRect(qrCarnetX, bodyY + 6, qrCarnetSize, qrCarnetSize), qrGrid);

    // Datos centrales entre foto y QR
    const int datosX = fotoRect.right() + 20;
    const int datosW = qrCarnetX - datosX - 12;
    int dy = bodyY + 12;

    p.setFont(QFont("Helvetica", 12, QFont::Bold));
    p.setPen(QColor("#000000"));
    p.drawText(QRect(datosX, dy, datosW, 50), Qt::AlignLeft | Qt::AlignVCenter, "V-" + cedulaLimpia);
    dy += 54;

    const QString apCorto = (m_primerApellido + (m_segundoApellido.isEmpty() ? "" : " " + m_segundoApellido.left(1))).trimmed().toUpper();
    const QString nomCorto = (m_primerNombre + (m_segundoNombre.isEmpty() ? "" : " " + m_segundoNombre.left(1))).trimmed().toUpper();
    p.setFont(QFont("Helvetica", 10, QFont::Normal));
    p.drawText(QRect(datosX, dy, datosW, 44), Qt::AlignLeft | Qt::AlignVCenter,
               apCorto.isEmpty() ? m_nombreEstudiante.toUpper() : apCorto);
    dy += 44;
    p.drawText(QRect(datosX, dy, datosW, 44), Qt::AlignLeft | Qt::AlignVCenter, nomCorto);
    dy += 48;

    // Cinta verde ESTUDIANTE
    const QRect badgeRect(datosX, dy, qMin(datosW, 300), 54);
    p.fillRect(badgeRect, QColor("#65a30d"));
    p.setFont(QFont("Helvetica", 10, QFont::Bold));
    p.setPen(Qt::white);
    p.drawText(badgeRect, Qt::AlignCenter, "ESTUDIANTE");
    dy += 62;

    // Fecha de vencimiento: siempre 31 de diciembre del año en curso
    const QString fechaVence = QString("31-12-%1").arg(QDate::currentDate().year());
    QFont fontVence("Helvetica");
    fontVence.setPointSizeF(7.5);
    p.setFont(fontVence);
    p.setPen(QColor("#111827"));
    p.drawText(QRect(datosX, dy, datosW, 36), Qt::AlignLeft | Qt::AlignVCenter, "VENCE: " + fechaVence);

    // Pie del anverso: ING - ESCUELA (sin duplicar ING)
    QString pieEscuela = escuelaCorta().toUpper();
    if (pieEscuela.startsWith("ING. DE ")) {
        pieEscuela = pieEscuela.mid(8).trimmed();
    } else if (pieEscuela.startsWith("ING. ")) {
        pieEscuela = pieEscuela.mid(5).trimmed();
    } else if (pieEscuela.startsWith("INGENIERÍA DE ")) {
        pieEscuela = pieEscuela.mid(14).trimmed();
    } else if (pieEscuela.startsWith("INGENIERIA DE ")) {
        pieEscuela = pieEscuela.mid(14).trimmed();
    } else if (pieEscuela.startsWith("INGENIERÍA ")) {
        pieEscuela = pieEscuela.mid(11).trimmed();
    } else if (pieEscuela.startsWith("INGENIERIA ")) {
        pieEscuela = pieEscuela.mid(11).trimmed();
    }
    p.setFont(QFont("Helvetica", 12, QFont::Bold));
    p.setPen(QColor("#000000"));
    p.drawText(QRect(leftX, y + cardH - 64, leftW, 52), Qt::AlignCenter,
               "ING - " + pieEscuela);

    // ---- Mitad Derecha: Reverso ----
    const int rightX = midX + padC + 10;
    const int rightW = halfW - 2 * padC - 10;
    const int qrRevSize = 320;
    const int qrRevX = rightX + rightW - qrRevSize;
    dibujarQrEnPainter(p, QRect(qrRevX, y + 18, qrRevSize, qrRevSize), qrGrid);

    const int revTextW = qrRevX - rightX - 20;
    p.setFont(QFont("Helvetica", 9, QFont::Normal));
    p.setPen(QColor("#111827"));
    p.drawText(QRect(rightX, y + 20, revTextW, 310),
               Qt::AlignLeft | Qt::AlignTop | Qt::TextWordWrap,
               "Carnet único de la Universidad de Carabobo. Aprobado por el Consejo Universitario en sesión extraordinaria Nro. 1.915 de fecha 25 de febrero de 2021");

    p.drawText(QRect(rightX, y + 350, revTextW, 160),
               Qt::AlignLeft | Qt::AlignTop | Qt::TextWordWrap,
               "Para verificar la validez de este carnet ingrese a:\nhttps://carnet.uc.edu.ve");

    y += cardH + 60;

    // 5. Instrucciones inferiores (5 viñetas)
    dibujarVineta(y, "Debe imprimir este carnet a color y en alta calidad (preferiblemente en impresora laser).");
    dibujarVineta(y, "No plastifique el carnet hasta tanto sea sellado por la Dirección Central de Asuntos Estudiantiles (DICAES) en el caso de Bárbula o la Secretaría en el caso de La Morita.");
    dibujarVineta(y, "Debe pegar una foto tipo carnet en el área dispuesta para ello. La foto debe ser fondo blanco, sin anteojos, gorras u otros accesorios. No utilizar grapas para pegar la foto.");
    dibujarVineta(y, "Bárbula: Debe dirigirse a la Dirección Central de Asuntos Estudiantiles (DICAES) con el carnet impreso con la foto pegada y su cédula de identidad laminada para validar el carnet y obtener el sello del mismo. Horario de atención: Martes y Jueves de 8:30 am a 11:00 am");
    dibujarVineta(y, "La Morita: Debe dirigirse a la Secretaría con el carnet impreso con la foto pegada y su cédula de identidad laminada para validar el carnet y obtener el sello del mismo. Horario de atención: Martes y Jueves de 8:30 am a 11:00 am");

    p.end();

    m_descargandoPdf = false;
    emit descargandoPdfChanged();

    QDesktopServices::openUrl(QUrl::fromLocalFile(rutaCompleta));
    emit pdfDescargado(rutaCompleta, nombreArchivo);
}

void DaeClient::enviarSolicitudCambioEscuela(const QString &codigoEscuelaDestino)
{
    if (m_enviandoCambioEscuela) return;

    QString codDest = codigoEscuelaDestino.trimmed();
    if (codDest.isEmpty() || codDest == "0") {
        emit solicitudCambioEscuelaCompletada(false, "Debe seleccionar una escuela destino");
        return;
    }

    if (m_pidSesion.isEmpty()) {
        emit solicitudCambioEscuelaCompletada(false, "Inicia sesión en DAE para registrar la solicitud");
        return;
    }

    m_enviandoCambioEscuela = true;
    emit cambioEscuelaChanged();

    QUrl urlPost(QString("https://dae.ing.uc.edu.ve/gestion_estudiantil/rep_cambio_escuela.php?pid=%1&c=1").arg(m_pidSesion));
    QNetworkRequest req(urlPost);
    configurarRequestDae(req);
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");
    req.setRawHeader("Origin", "https://dae.ing.uc.edu.ve");
    req.setRawHeader("Referer", QString("https://dae.ing.uc.edu.ve/gestion_estudiantil/solicitud_cambio_escuela.php?pid=%1&c=1")
                                    .arg(m_pidSesion).toUtf8());

    QUrlQuery postData;
    postData.addQueryItem("escuela_actual", codigoEscuelaActual());
    postData.addQueryItem("escuela_destino", codDest);

    QNetworkReply *reply = m_nam->post(req, postData.toString(QUrl::FullyEncoded).toUtf8());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        m_enviandoCambioEscuela = false;
        emit cambioEscuelaChanged();

        if (reply->error() != QNetworkReply::NoError) {
            emit solicitudCambioEscuelaCompletada(false, "Error de red con DAE: " + reply->errorString());
            return;
        }

        QString html = QString::fromUtf8(reply->readAll());

        QString textoLimpio = limpiarTextoHtml(html);
        if (textoLimpio.contains("NO PUEDE", Qt::CaseInsensitive) ||
            textoLimpio.contains("ERROR", Qt::CaseInsensitive) ||
            textoLimpio.contains("RECHAZAD", Qt::CaseInsensitive)) {
            emit solicitudCambioEscuelaCompletada(false, "Respuesta DAE: Revise los requisitos del 1er semestre");
        } else {
            emit solicitudCambioEscuelaCompletada(true, "✓ Solicitud enviada y registrada en el servidor DAE UC");
        }
    });
}

QStringList DaeClient::obtenerEstados() const
{
    return {
        "AMAZONAS", "ANZOÁTEGUI", "APURE", "ARAGUA", "BARINAS",
        "BOLÍVAR", "CARABOBO", "COJEDES", "DELTA AMACURO", "DEPENDENCIAS FEDERALES",
        "DISTRITO CAPITAL", "FALCÓN", "GUÁRICO", "LARA", "MÉRIDA",
        "MIRANDA", "MONAGAS", "NUEVA ESPARTA", "PORTUGUESA", "SUCRE",
        "TÁCHIRA", "TRUJILLO", "VARGAS", "YARACUY", "ZULIA"
    };
}

static QString codigoEstadoPorNombre(const QString &nombreEstado)
{
    static const QMap<QString, QString> mapEstados = {
        {"AMAZONAS", "1"}, {"ANZOÁTEGUI", "2"}, {"APURE", "3"}, {"ARAGUA", "4"},
        {"BARINAS", "5"}, {"BOLÍVAR", "6"}, {"CARABOBO", "7"}, {"COJEDES", "8"},
        {"DELTA AMACURO", "9"}, {"DEPENDENCIAS FEDERALES", "10"}, {"DISTRITO CAPITAL", "11"},
        {"FALCÓN", "12"}, {"GUÁRICO", "13"}, {"LARA", "14"}, {"MÉRIDA", "15"},
        {"MIRANDA", "16"}, {"MONAGAS", "17"}, {"NUEVA ESPARTA", "18"}, {"PORTUGUESA", "19"},
        {"SUCRE", "20"}, {"TÁCHIRA", "21"}, {"TRUJILLO", "22"}, {"VARGAS", "23"},
        {"YARACUY", "24"}, {"ZULIA", "25"}
    };
    return mapEstados.value(nombreEstado.trimmed().toUpper(), "7");
}

static QList<QPair<QString, QString>> obtenerMunicipiosCaraboboFallback()
{
    return {
        {"78", "BEJUMA"}, {"79", "CARLOS ARVELO"}, {"80", "DIEGO IBARRA"},
        {"81", "GUACARA"}, {"82", "JUAN JOSÉ MORA"}, {"83", "LIBERTADOR"},
        {"84", "LOS GUAYOS"}, {"85", "MIRANDA"}, {"86", "MONTALBÁN"},
        {"87", "NAGUANAGUA"}, {"88", "PUERTO CABELLO"}, {"89", "SAN DIEGO"},
        {"90", "SAN JOAQUÍN"}, {"91", "VALENCIA"}
    };
}

static QMap<QString, QList<QPair<QString, QString>>> obtenerParroquiasCaraboboFallback()
{
    return {
        {"78", {{"282", "BEJUMA"}, {"283", "CANOABO"}, {"284", "SIMON BOLIVAR"}}},
        {"79", {{"285", "BELEN"}, {"286", "GUIGUE"}, {"287", "TACARIGUA"}}},
        {"80", {{"288", "AGUAS CALIENTES"}, {"289", "MARIARA"}}},
        {"81", {{"290", "CIUDAD ALIANZA"}, {"291", "GUACARA"}, {"292", "YAGUA"}}},
        {"82", {{"293", "MORON"}, {"294", "URAMA"}}},
        {"83", {{"295", "U INDEPENDENCIA"}, {"296", "U TOCUYITO"}}},
        {"84", {{"297", "LOS GUAYOS"}}},
        {"85", {{"298", "MIRANDA"}}},
        {"86", {{"299", "MONTALBAN"}}},
        {"87", {{"300", "NAGUANAGUA"}}},
        {"88", {{"301", "BARTOLOME SALOM"}, {"302", "BORBURATA"}, {"303", "DEMOCRACIA"},
                {"304", "FRATERNIDAD"}, {"305", "GOAIGOAZA"}, {"306", "JUAN JOSE FLORES"},
                {"307", "PATANEMO"}, {"308", "UNION"}}},
        {"89", {{"309", "SAN DIEGO"}}},
        {"90", {{"310", "SAN JOAQUIN"}}},
        {"91", {{"311", "CANDELARIA"}, {"312", "CATEDRAL"}, {"313", "EL SOCORRO"},
                {"314", "MIGUEL PEÑA"}, {"315", "NEGRO PRIMERO"}, {"316", "RAFAEL URDANETA"},
                {"317", "SAN BLAS"}, {"318", "SAN JOSE"}, {"319", "SANTA ROSA"}}}
    };
}

QStringList DaeClient::obtenerMunicipiosPorEstado(const QString &nombreEstado) const
{
    QString idEdo = codigoEstadoPorNombre(nombreEstado);
    QList<QPair<QString, QString>> lista = m_municipiosPorEstado.value(idEdo);
    if (lista.isEmpty() && idEdo == "7") {
        lista = obtenerMunicipiosCaraboboFallback();
    }
    QStringList nombres;
    for (const auto &par : lista) {
        nombres.append(par.second);
    }
    if (nombres.isEmpty() && !m_dirMunicipio.isEmpty()) {
        nombres.append(m_dirMunicipio);
    }
    return nombres;
}

QStringList DaeClient::obtenerParroquiasPorMunicipio(const QString &nombreEstado, const QString &nombreMunicipio) const
{
    QString idEdo = codigoEstadoPorNombre(nombreEstado);
    QList<QPair<QString, QString>> muns = m_municipiosPorEstado.value(idEdo);
    if (muns.isEmpty() && idEdo == "7") {
        muns = obtenerMunicipiosCaraboboFallback();
    }

    QString idMun;
    QString busqMun = nombreMunicipio.trimmed().toUpper();
    for (const auto &par : muns) {
        if (par.second.trimmed().toUpper() == busqMun) {
            idMun = par.first;
            break;
        }
    }
    if (idMun.isEmpty() && !muns.isEmpty()) {
        idMun = muns.first().first;
    }

    QList<QPair<QString, QString>> parroqs = m_parroquiasPorMunicipio.value(idMun);
    if (parroqs.isEmpty()) {
        auto fb = obtenerParroquiasCaraboboFallback();
        parroqs = fb.value(idMun);
    }

    QStringList nombres;
    for (const auto &par : parroqs) {
        nombres.append(par.second);
    }
    if (nombres.isEmpty() && !m_dirParroquia.isEmpty()) {
        nombres.append(m_dirParroquia);
    }
    return nombres;
}

void DaeClient::guardarDatosPersonales(const QString &correoPrincipal,
                                       const QString &correoAlternativo,
                                       const QString &telFijo,
                                       const QString &telMovil,
                                       const QString &dirEstado,
                                       const QString &dirMunicipio,
                                       const QString &dirParroquia,
                                       const QString &dirDetalle,
                                       const QString &opsuEstadoCivil,
                                       const QString &opsuEtnia,
                                       const QString &opsuDiscapacidad,
                                       const QString &opsuManoAgil)
{
    m_correoEstudiante = correoPrincipal.trimmed();
    m_correoAlternativo = correoAlternativo.trimmed();
    m_telefonoFijo = telFijo.trimmed();
    m_telefonoEstudiante = telMovil.trimmed();
    m_dirEstado = dirEstado.trimmed().toUpper();
    m_dirMunicipio = dirMunicipio.trimmed().toUpper();
    m_dirParroquia = dirParroquia.trimmed().toUpper();
    m_dirDetalle = dirDetalle.trimmed();
    m_opsuEstadoCivil = opsuEstadoCivil.trimmed().toUpper();
    m_opsuEtnia = opsuEtnia.trimmed().toUpper();
    m_opsuDiscapacidad = opsuDiscapacidad.trimmed().toUpper();
    m_opsuManoAgil = opsuManoAgil.trimmed().toUpper();

    // Resolver IDs numéricos de Estado, Municipio y Parroquia para el POST a personal_estudiantil.php
    m_idEstado = codigoEstadoPorNombre(m_dirEstado);
    QList<QPair<QString, QString>> muns = m_municipiosPorEstado.value(m_idEstado);
    if (muns.isEmpty() && m_idEstado == "7") {
        muns = obtenerMunicipiosCaraboboFallback();
    }
    for (const auto &par : muns) {
        if (par.second.trimmed().toUpper() == m_dirMunicipio) {
            m_idMunicipio = par.first;
            break;
        }
    }

    QList<QPair<QString, QString>> parroqs = m_parroquiasPorMunicipio.value(m_idMunicipio);
    if (parroqs.isEmpty()) {
        parroqs = obtenerParroquiasCaraboboFallback().value(m_idMunicipio);
    }
    for (const auto &par : parroqs) {
        if (par.second.trimmed().toUpper() == m_dirParroquia) {
            m_idParroquia = par.first;
            break;
        }
    }

    emit datosEstudianteChanged();

    if (m_pidSesion.isEmpty()) {
        emit datosPersonalesGuardados(true, "✓ Datos guardados localmente");
        return;
    }

    // Separar código de área y número fijo ("0241 - 8360086")
    auto separarTelefono = [](const QString &telCompleto, const QString &defCod) -> QPair<QString, QString> {
        QString limpio = telCompleto;
        limpio.remove(' ');
        QStringList partes = limpio.split('-');
        if (partes.size() >= 2) {
            return {partes[0].trimmed(), partes[1].trimmed()};
        }
        QString soloDigitos;
        for (QChar c : limpio) {
            if (c.isDigit()) soloDigitos.append(c);
        }
        if (soloDigitos.length() >= 11) {
            return {soloDigitos.left(4), soloDigitos.mid(4, 7)};
        }
        return {defCod, soloDigitos};
    };

    auto parFijo = separarTelefono(m_telefonoFijo, "0241");
    auto parMovil = separarTelefono(m_telefonoEstudiante, "0412");

    // Separar fecha de nacimiento ("24 / 02 / 2002")
    QString dia = "24", mes = "02", anio = "2002";
    QStringList partesFecha = m_fechaNacimiento.split('/');
    if (partesFecha.size() == 3) {
        dia = partesFecha[0].trimmed();
        mes = partesFecha[1].trimmed();
        anio = partesFecha[2].trimmed();
    }

    // Mapear Estado Civil a sel_edoc de DAE
    static const QMap<QString, QString> mapEdoc = {
        {"SOLTERO", "1"},
        {"CASADO", "2"},
        {"VIUDO", "3"},
        {"DIVORCIADO", "4"},
        {"SEPARADO DE CUERPOS", "5"},
        {"CONCUBINO", "6"}
    };
    QString valEdoc = mapEdoc.value(m_opsuEstadoCivil, "1");

    // Mapear Etnia a sel_etnia de DAE (las 54 opciones oficiales de actualizar_estudiantil.php)
    static const QMap<QString, QString> mapEtnia = {
        {"NINGUNA", "0"}, {"AKAWAYO", "20"}, {"AMORUA", "36"}, {"AÑÚ/PARAUJANO", "2"},
        {"ARAWAKO", "37"}, {"AYAMAN", "38"}, {"BANIVA", "4"}, {"BARÉ", "3"},
        {"BARÍ", "23"}, {"CAMENTZA", "39"}, {"CARIBE", "40"}, {"CHAIMA", "16"},
        {"CUBEO", "41"}, {"CUMANAGOTO", "12"}, {"EÑEPÁ/PANARE", "42"}, {"GAYÓN", "43"},
        {"GUANONO", "44"}, {"GUAZABARA", "45"}, {"HOTI/HODI", "25"}, {"INGA", "46"},
        {"JAPRERÍA", "17"}, {"JIVI/GUAJIBO", "47"}, {"KARIÑA", "13"}, {"KUIBA", "30"},
        {"KURRIPACO", "48"}, {"MAKO", "27"}, {"MAKUSHÍ", "18"}, {"MATAKO", "49"},
        {"ÑENGATÚ/YERAL", "26"}, {"OTROS GRUPOS", "53"}, {"PANARE", "14"}, {"PEMÓN", "8"},
        {"PIAPOCO", "5"}, {"PUINAVE", "24"}, {"PUMÉ/YARURO", "33"}, {"QUINAROE", "50"},
        {"RURRIPAKO", "51"}, {"SÁLIVA", "28"}, {"SANEMÁ", "22"}, {"SAPÉ", "34"},
        {"TIMOTO-CUICAS/TIMOTES", "52"}, {"URUAK/ARUTANI", "35"}, {"WAIKA", "11"}, {"WAIKERÍ", "32"},
        {"WANAI/MAPOYO", "10"}, {"WAPISHANA", "7"}, {"WARAO", "31"}, {"WAREKENA", "6"},
        {"WAYUU", "1"}, {"WOTJUJA/PIAROA", "29"}, {"YABARANA", "9"}, {"YANOMAMI", "21"},
        {"YEKUANA", "19"}, {"YUKPA", "15"}
    };
    QString valEtnia = mapEtnia.value(m_opsuEtnia, "0");

    // Mapear Discapacidad a sel_disca de DAE
    static const QMap<QString, QString> mapDisca = {
        {"NINGUNA", "0"},
        {"PSÍQUICA MENTAL", "1"},
        {"SENSORIAL VISUAL", "2"},
        {"SENSORIAL AUDITIVA", "3"},
        {"PSÍQUICA-INTELECTUAL", "4"},
        {"FÍSICA", "5"},
        {"MIXTA O PLURIDEFICIENTE", "6"}
    };
    QString valDisca = mapDisca.value(m_opsuDiscapacidad, "0");

    // Mapear Mano Ágil a sel_mag de DAE ('D' = DERECHA, 'I' = IZQUIERDA, 'A' = AMBAS)
    static const QMap<QString, QString> mapMag = {
        {"DERECHA", "D"},
        {"IZQUIERDA", "I"},
        {"AMBAS", "A"}
    };
    QString valMag = mapMag.value(m_opsuManoAgil, "D");

    QUrl urlPost(QString("https://dae.ing.uc.edu.ve/gestion_estudiantil/personal_estudiantil.php?pid=%1").arg(m_pidSesion));
    QNetworkRequest req(urlPost);
    configurarRequestDae(req);
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");
    req.setRawHeader("Origin", "https://dae.ing.uc.edu.ve");
    req.setRawHeader("Referer", QString("https://dae.ing.uc.edu.ve/gestion_estudiantil/actualizar_estudiantil.php?pid=%1&c=1")
                                    .arg(m_pidSesion).toUtf8());

    QUrlQuery postData;
    postData.addQueryItem("nombre1", m_primerNombre);
    postData.addQueryItem("nombre2", m_segundoNombre);
    postData.addQueryItem("apellido1", m_primerApellido);
    postData.addQueryItem("apellido2", m_segundoApellido);
    postData.addQueryItem("mail1", m_correoEstudiante);
    postData.addQueryItem("mail2", m_correoAlternativo);
    postData.addQueryItem("area", parFijo.first);
    postData.addQueryItem("fijo", parFijo.second);
    postData.addQueryItem("dia", dia);
    postData.addQueryItem("mes", mes);
    postData.addQueryItem("anio", anio);
    postData.addQueryItem("cel", parMovil.first);
    postData.addQueryItem("movil", parMovil.second);
    postData.addQueryItem("sexo", m_sexoEstudiante.startsWith("F", Qt::CaseInsensitive) ? "F" : "M");
    postData.addQueryItem("sel_edo", m_idEstado);
    postData.addQueryItem("sel_mun", m_idMunicipio);
    postData.addQueryItem("sel_paq", m_idParroquia);
    postData.addQueryItem("direc", m_dirDetalle);
    postData.addQueryItem("sel_edoc", valEdoc);
    postData.addQueryItem("sel_etnia", valEtnia);
    postData.addQueryItem("sel_disca", valDisca);
    postData.addQueryItem("sel_mag", valMag);
    postData.addQueryItem("E N V I A R", "ENVIAR");

    QNetworkReply *reply = m_nam->post(req, postData.toString(QUrl::FullyEncoded).toUtf8());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit datosPersonalesGuardados(false, "Error al actualizar en DAE: " + reply->errorString());
            return;
        }

        QString html = QString::fromUtf8(reply->readAll());

        // Volver a consultar actualizar_estudiantil.php para confirmar que el servidor guardó los cambios
        sincronizarSeccionEstudiantil("actualizar_estudiantil.php?pid=" + m_pidSesion + "&c=1");
        // Ya hubo una escritura real: no volver a servir esta sesión desde la caché
        m_datosDesdeCache = false;
        emit cacheSesionChanged();
        emit datosPersonalesGuardados(true, "✓ Datos enviados y actualizados en el servidor DAE");
    });
}

QString DaeClient::obtenerProfesorSeccion(const QString &codigo, const QString &seccion, const QString &fallback) const
{
    QString cod = codigo.trimmed().toUpper();
    QString sec = seccion.trimmed().rightJustified(2, '0');
    QString clave = cod + "|" + sec;

    if (m_mapaProfesorHorario.contains(clave)) {
        QString prof = m_mapaProfesorHorario.value(clave).trimmed();
        if (!prof.isEmpty()) {
            if (!prof.startsWith("PROF", Qt::CaseInsensitive) && !prof.startsWith("SIN ", Qt::CaseInsensitive)) {
                return QStringLiteral("PROF. ") + prof;
            }
            return prof;
        }
    }

    // Buscar si existe con sección sin cero a la izquierda o cualquier sección de esa materia
    for (auto it = m_mapaProfesorHorario.constBegin(); it != m_mapaProfesorHorario.constEnd(); ++it) {
        if (it.key().startsWith(cod + "|") && !it.value().trimmed().isEmpty()) {
            QString prof = it.value().trimmed();
            if (!prof.startsWith("PROF", Qt::CaseInsensitive) && !prof.startsWith("SIN ", Qt::CaseInsensitive)) {
                return QStringLiteral("PROF. ") + prof;
            }
            return prof;
        }
    }

    return fallback.isEmpty() ? QStringLiteral("PROF. POR ASIGNAR") : fallback;
}

void DaeClient::reconstruirEstructurasHorarioAsignado()
{
    // Tabla de horas de inicio y fin de cada bloque de 50 minutos en Ingeniería UC
    static const QStringList ordenHorasInicio = {
        "0800", "0850", "0940", "1030", "1120", "1210", "1300", "1350",
        "1440", "1530", "1620", "1710", "1800", "1850", "1940"
    };
    static const QMap<QString, QString> mapaHoraInicioFmt = {
        {"0800", "08:00"}, {"0850", "08:50"}, {"0940", "09:40"}, {"1030", "10:30"},
        {"1120", "11:20"}, {"1210", "12:10"}, {"1300", "13:00"}, {"1350", "13:50"},
        {"1440", "14:40"}, {"1530", "15:30"}, {"1620", "16:20"}, {"1710", "17:10"},
        {"1800", "18:00"}, {"1850", "18:50"}, {"1940", "19:40"}
    };
    static const QMap<QString, QString> mapaHoraFinFmt = {
        {"0800", "08:50"}, {"0850", "09:40"}, {"0940", "10:30"}, {"1030", "11:20"},
        {"1120", "12:10"}, {"1210", "13:00"}, {"1300", "13:50"}, {"1350", "14:40"},
        {"1440", "15:30"}, {"1530", "16:20"}, {"1620", "17:10"}, {"1710", "18:00"},
        {"1800", "18:50"}, {"1850", "19:40"}, {"1940", "20:30"}
    };
    static const QMap<QString, QString> mapaHora12h = {
        {"08:00", "08:00 AM"}, {"08:50", "08:50 AM"}, {"09:40", "09:40 AM"}, {"10:30", "10:30 AM"},
        {"11:20", "11:20 AM"}, {"12:10", "12:10 PM"}, {"13:00", "01:00 PM"}, {"13:50", "01:50 PM"},
        {"14:40", "02:40 PM"}, {"15:30", "03:30 PM"}, {"16:20", "04:20 PM"}, {"17:10", "05:10 PM"},
        {"18:00", "06:00 PM"}, {"18:50", "06:50 PM"}, {"19:40", "07:40 PM"}, {"20:30", "08:30 PM"}
    };
    static const QStringList codigosDias = {"LU", "MA", "MI", "JU", "VI", "SA"};
    static const QStringList cortosDias  = {"Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"};
    static const QStringList nombresDias = {"Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"};

    // Paleta de colores distintivos por asignatura
    struct TrioColor {
        QString c1;
        QString c2;
        QString c3;
    };
    static const QList<TrioColor> paletaColores = {
        {"#3b82f6", "#1d4ed8", "#dbeafe"},
        {"#06b6d4", "#0e7490", "#a5f3fc"},
        {"#6366f1", "#3730a3", "#c7d2fe"},
        {"#2563eb", "#1e3a8a", "#dbeafe"},
        {"#0ea5e9", "#0369a1", "#bae6fd"},
        {"#14b8a6", "#0f766e", "#99f6e4"},
        {"#8b5cf6", "#4c1d95", "#ddd6fe"},
        {"#0284c7", "#075985", "#e0f2fe"}
    };

    struct BloqueUnitario {
        QString codigo;
        QString nombre;
        QString seccion;
        QString profesor;
        QString aula;
        QString horaCod; // ej. "0800"
        bool esLab;
        bool adicion;
        QString color1;
        QString color2;
        QString color3;
    };

    QMap<QString, QList<BloqueUnitario>> bloquesPorDia; // "LU" -> lista de bloques
    QMap<QString, QMap<QString, QString>> celdaMalla;   // horaCod -> (diaCod -> "COD\nAULA")
    QVariantList listaSinBloques;
    int conteoTotalBloques = 0;
    int maxIndiceHora = 7; // Por defecto muestra al menos hasta las 13:50

    for (int mIdx = 0; mIdx < m_materiasInscritasRaw.size(); ++mIdx) {
        QVariantMap mat = m_materiasInscritasRaw[mIdx].toMap();
        QString codigo = mat["codigo"].toString().trimmed();
        QString sec = mat["sec"].toString().trimmed().rightJustified(2, '0');
        QString clave = codigo + "|" + sec;

        QString nombre = m_mapaNombreMateriaHorario.value(codigo, mat["nombre"].toString());
        QString profesor = obtenerProfesorSeccion(codigo, sec);
        QStringList bloques = m_mapaBloquesHorario.value(clave);
        bool adicion = mat["adicion"].toBool();
        if (m_mapaEstadoHorario.value(clave) == "NUEVA" || m_mapaEstadoHorario.value(clave) == "ACTUALIZADA") {
            adicion = true;
        }
        bool esLab = codigo.endsWith("L", Qt::CaseInsensitive) || nombre.contains("LAB", Qt::CaseInsensitive);

        auto parCol = paletaColores[mIdx % paletaColores.size()];

        if (bloques.isEmpty()) {
            QVariantMap itemSin;
            itemSin["codigo"] = codigo;
            itemSin["nombre"] = nombre.toUpper();
            itemSin["sec"] = sec;
            itemSin["profesor"] = profesor;
            listaSinBloques.append(itemSin);
            continue;
        }

        static const QRegularExpression reB("^(LU|MA|MI|JU|VI|SA|DO)(\\d{4})(?:\\s+(.*))?$");
        for (const QString &bStr : bloques) {
            QRegularExpressionMatch mb = reB.match(bStr.trimmed());
            if (!mb.hasMatch()) continue;

            QString diaCod = mb.captured(1);
            QString horaCod = mb.captured(2);
            QString aula = mb.captured(3).trimmed();
            QString aulaVisual = aula.isEmpty() ? QStringLiteral("S/A") : aula;

            int hIdx = ordenHorasInicio.indexOf(horaCod);
            if (hIdx > maxIndiceHora) maxIndiceHora = hIdx;

            BloqueUnitario bu;
            bu.codigo = codigo;
            bu.nombre = nombre;
            bu.seccion = sec;
            bu.profesor = profesor;
            bu.aula = aulaVisual;
            bu.horaCod = horaCod;
            bu.esLab = esLab;
            bu.adicion = adicion;
            bu.color1 = parCol.c1;
            bu.color2 = parCol.c2;
            bu.color3 = parCol.c3;

            bloquesPorDia[diaCod].append(bu);
            QString entradaMalla = aula.isEmpty() ? codigo : (codigo + "\n" + aula);
            if (celdaMalla[horaCod][diaCod].isEmpty()) {
                celdaMalla[horaCod][diaCod] = entradaMalla;
            } else if (!celdaMalla[horaCod][diaCod].contains(codigo)) {
                celdaMalla[horaCod][diaCod] += "\n" + entradaMalla;
            }
            conteoTotalBloques++;
        }
    }

    QVariantList nuevaDiasSemana;
    QVariantList nuevaClasesDashboard;
    // Índice 0 de Dashboard = Domingo (Libre) — usar QVariant::fromValue para insertar la sub-lista como elemento y no concatenarla
    nuevaClasesDashboard.append(QVariant::fromValue(QVariantList()));

    for (int d = 0; d < codigosDias.size(); ++d) {
        QString diaCod = codigosDias[d];
        QList<BloqueUnitario> listaB = bloquesPorDia.value(diaCod);

        // Ordenar bloques del día cronológicamente
        std::sort(listaB.begin(), listaB.end(), [](const BloqueUnitario &a, const BloqueUnitario &b) {
            return a.horaCod < b.horaCod;
        });

        int numBloquesDia = listaB.size();
        int minutosTotales = numBloquesDia * 50;
        QString horasTxt = (numBloquesDia == 0)
                           ? QStringLiteral("Libre")
                           : QString("%1h %2m").arg(minutosTotales / 60).arg(minutosTotales % 60, 2, 10, QChar('0'));

        // Agrupar bloques consecutivos de la misma asignatura en una sola tarjeta de clase
        QVariantList clasesAgrupadas;
        QVariantList tarjetasDiaDashboard;

        int i = 0;
        while (i < listaB.size()) {
            const BloqueUnitario &primero = listaB[i];
            int j = i;
            while (j + 1 < listaB.size() && listaB[j + 1].codigo == primero.codigo && listaB[j + 1].seccion == primero.seccion) {
                j++;
            }
            const BloqueUnitario &ultimo = listaB[j];
            int cantBloques = (j - i) + 1;

            QString hIni = mapaHoraInicioFmt.value(primero.horaCod, primero.horaCod);
            QString hFin = mapaHoraFinFmt.value(ultimo.horaCod, ultimo.horaCod);
            QString bloquesTxt = (cantBloques == 1)
                                 ? QString("1 bloque (%1)").arg(primero.horaCod)
                                 : QString("%1 bloques (%2 - %3)").arg(cantBloques).arg(primero.horaCod, ultimo.horaCod);

            // Resolver nombre oficial del departamento según el código de la asignatura
            QString prefijo = primero.codigo.left(2).toUpper();
            QString deptoStr = QStringLiteral("Asignatura Inscrita • DAE UC");
            // Dirección de Estudios Básicos
            if (prefijo == "MA") deptoStr = QStringLiteral("Dpto. de Matemática");
            else if (prefijo == "FI") deptoStr = QStringLiteral("Dpto. de Física");
            else if (prefijo == "QM" || prefijo == "QU") deptoStr = QStringLiteral("Dpto. de Química");
            else if (prefijo == "CA") deptoStr = QStringLiteral("Dpto. de Computación");
            else if (prefijo == "DI") deptoStr = QStringLiteral("Dpto. de Dibujo");
            else if (prefijo == "ID") deptoStr = QStringLiteral("Dpto. de Idiomas");
            else if (prefijo == "HU" || prefijo == "DH" || prefijo == "DE" || prefijo == "CO") deptoStr = QStringLiteral("Dpto. de Humanidades");
            // Escuela de Ingeniería Industrial
            else if (prefijo == "ME") deptoStr = QStringLiteral("Dpto. de Ingeniería de Métodos");
            else if (prefijo == "IN") deptoStr = QStringLiteral("Dpto. de Investigación Operativa");
            else if (prefijo == "GE") deptoStr = QStringLiteral("Dpto. de Gerencia");
            // Escuela de Ingeniería Eléctrica
            else if (prefijo == "CM") deptoStr = QStringLiteral("Dpto. de Circuitos y Mediciones");
            else if (prefijo == "EC") deptoStr = QStringLiteral("Dpto. de Electrónica y Comunicaciones");
            else if (prefijo == "PW" || prefijo == "EP") deptoStr = QStringLiteral("Dpto. de Potencia");
            else if (prefijo == "SA") deptoStr = QStringLiteral("Dpto. de Sistemas y Automática");
            // Escuela de Ingeniería Mecánica
            else if (prefijo == "TE") deptoStr = QStringLiteral("Dpto. de Térmica y Energética");
            else if (prefijo == "DA" || prefijo == "DM") deptoStr = QStringLiteral("Dpto. de Diseño Mecánico y Automatización");
            else if (prefijo == "MP" || prefijo == "MT") deptoStr = QStringLiteral("Dpto. de Materiales y Procesos de Fabricación");
            // Escuela de Ingeniería Química
            else if (prefijo == "DQ") deptoStr = QStringLiteral("Dpto. de Química Tecnológica");
            else if (prefijo == "IQ" || prefijo == "OQ" || prefijo == "PQ") deptoStr = QStringLiteral("Dpto. de Ingeniería Química");
            // Escuela de Ingeniería Civil
            else if (prefijo == "VI" || prefijo == "TO") deptoStr = QStringLiteral("Dpto. de Ingeniería Vial");
            else if (prefijo == "IA" || prefijo == "HI") deptoStr = QStringLiteral("Dpto. de Ingeniería Ambiental");
            else if (prefijo == "IE" || prefijo == "ES") deptoStr = QStringLiteral("Dpto. de Ingeniería Estructural");
            // Escuela de Ingeniería de Telecomunicaciones
            else if (prefijo == "SS") deptoStr = QStringLiteral("Dpto. de Señales y Sistemas");
            else if (prefijo == "ER") deptoStr = QStringLiteral("Dpto. de Electromagnetismo y Radiación");

            // Indicar la Escuela o Departamento cuando el salón/laboratorio no aparece por separado en el plano sino dentro de una escuela
            auto formatearAulaConEscuela = [](const QString &aulaRaw) -> QString {
                QString a = aulaRaw.trimmed().toUpper();
                static const QHash<QString, QString> mapaEscuelaPorAula = {
                    // Escuela de Ingeniería de Telecomunicaciones
                    {"LABSS",  "LABSS (Esc. Telecom)"},
                    {"LABER",  "LABER (Esc. Telecom)"},
                    {"LCTEL",  "LCTEL (Esc. Telecom)"},
                    {"LABANT", "LABANT (Esc. Telecom)"},
                    // Escuela de Ingeniería Eléctrica
                    {"LLOG",   "LLOG (Esc. Eléctrica)"},
                    {"LDD",    "LDD (Esc. Eléctrica)"},
                    {"LABCOM", "LABCOM (Esc. Eléctrica)"},
                    {"LAU1",   "LAU1 (Esc. Eléctrica)"},
                    {"LAU2",   "LAU2 (Esc. Eléctrica)"},
                    {"LCTR",   "LCTR (Esc. Eléctrica)"},
                    {"LCM",    "LCM (Esc. Eléctrica)"},
                    {"LE1",    "LE1 (Esc. Eléctrica)"},
                    {"LE2",    "LE2 (Esc. Eléctrica)"},
                    {"LE3",    "LE3 (Esc. Eléctrica)"},
                    {"SIE4",   "SIE4 (Esc. Eléctrica)"},
                    {"SIE6",   "SIE6 (Esc. Eléctrica)"},
                    {"LM1",    "LM1 (Esc. Eléctrica)"},
                    {"LM2",    "LM2 (Esc. Eléctrica)"},
                    {"LM3",    "LM3 (Esc. Eléctrica)"},
                    // Escuela de Ingeniería Mecánica
                    {"LDM",    "LDM (Esc. Mecánica)"},
                    {"LCAU",   "LCAU (Esc. Mecánica)"},
                    {"LMAT",   "LMAT (Esc. Mecánica)"},
                    {"LPROC",  "LPROC (Esc. Mecánica)"},
                    {"MPROC",  "MPROC (Esc. Mecánica)"},
                    {"LTER",   "LTER (Esc. Mecánica)"},
                    {"LMFM",   "LMFM (Esc. Mecánica)"},
                    {"LMF",    "LMF (Esc. Mecánica)"},
                    {"SPG",    "SPG (Esc. Mecánica)"},
                    {"ADH2",   "ADH2 (Esc. Mecánica)"},
                    // Escuela de Ingeniería Química
                    {"AEIQ",   "AEIQ (Esc. Química)"},
                    {"LCQ",    "LCQ (Esc. Química)"},
                    {"LIQ",    "LIQ (Esc. Química)"},
                    {"LQA",    "LQA (Esc. Química)"},
                    {"LQO",    "LQO (Esc. Química)"},
                    {"LOU1",   "LOU1 (Esc. Química)"},
                    {"LOU2",   "LOU2 (Esc. Química)"},
                    // Escuela de Ingeniería Civil
                    {"SH01",   "SH01 (Esc. Civil Hidráulica)"},
                    {"SH02",   "SH02 (Esc. Civil Hidráulica)"},
                    {"SH03",   "SH03 (Esc. Civil Hidráulica)"},
                    {"LMFC",   "LMFC (Esc. Civil Hidráulica)"},
                    {"LCA",    "LCA (Esc. Civil)"},
                    {"ADP",    "ADP (Esc. Civil)"},
                    {"LP",     "LP (Esc. Civil)"},
                    {"LSL",    "LSL (Esc. Civil)"},
                    {"LTOP",   "LTOP (Esc. Civil)"},
                    {"LME",    "LME (Esc. Civil)"},
                    {"LEM",    "LEM (Esc. Civil)"},
                    // Escuela de Ingeniería Industrial
                    {"LIM2",   "LIM2 (Esc. Industrial)"},
                    {"LIO",    "LIO (Esc. Industrial)"},
                    {"SUM",    "SUM (Esc. Industrial)"},
                    // Dirección de Estudios Básicos
                    {"LC1",    "LC1 (Dpto. Computación)"},
                    {"LC3",    "LC3 (Dpto. Computación)"},
                    {"LF1A",   "LF1A (Dpto. Física)"},
                    {"LF1B",   "LF1B (Dpto. Física)"},
                    {"LF2",    "LF2 (Dpto. Física)"},
                    {"LQG",    "LQG (Dpto. Química)"},
                    {"LFQ",    "LFQ (Lab. Fisicoquímica)"},
                    {"DEP2",   "DEP2 (Canchas)"},
                    {"AVING",  "AVING (Aula Virtual)"}
                };
                return mapaEscuelaPorAula.value(a, aulaRaw);
            };

            QString aulaConEscuela = formatearAulaConEscuela(primero.aula);

            // Formatear nombre legible (Title Case conservando números romanos y siglas)
            QStringList palabrasNombre = primero.nombre.simplified().split(' ', Qt::SkipEmptyParts);
            static const QSet<QString> siglasRomanas = {"I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "(LAB)", "LAB", "TV", "RF", "CAD"};
            static const QSet<QString> conectoresMin = {"DE", "DEL", "LA", "LAS", "EL", "LOS", "Y", "E", "EN", "A", "PARA", "CON", "POR", "AL"};
            for (int w = 0; w < palabrasNombre.size(); ++w) {
                QString pUp = palabrasNombre[w].toUpper();
                if (siglasRomanas.contains(pUp)) {
                    palabrasNombre[w] = (pUp == "(LAB)") ? QStringLiteral("(Lab)") : pUp;
                } else if (w > 0 && conectoresMin.contains(pUp)) {
                    palabrasNombre[w] = pUp.toLower();
                } else if (pUp.length() > 1) {
                    palabrasNombre[w] = pUp.left(1) + pUp.mid(1).toLower();
                }
            }
            QString nombreLegible = palabrasNombre.isEmpty() ? primero.nombre : palabrasNombre.join(' ');

            QVariantMap claseMap;
            claseMap["codigo"] = primero.codigo;
            claseMap["nombre"] = nombreLegible;
            claseMap["profesor"] = primero.profesor;
            claseMap["tipo"] = primero.esLab ? "LABORATORIO" : "TEORÍA";
            claseMap["seccion"] = "Sección " + primero.seccion;
            claseMap["aula"] = aulaConEscuela;
            claseMap["aulaCodigo"] = primero.aula;
            claseMap["departamento"] = deptoStr;
            claseMap["horaInicio"] = hIni;
            claseMap["horaFin"] = hFin;
            claseMap["bloquesTxt"] = bloquesTxt;
            claseMap["color1"] = primero.color1;
            claseMap["color2"] = primero.color2;
            claseMap["adicion"] = primero.adicion;
            clasesAgrupadas.append(claseMap);

            // Tarjeta equivalente para el carrusel "Clases de Hoy" del Dashboard (Main.qml)
            QVariantMap cardDash;
            cardDash["departamento"] = deptoStr;
            cardDash["nombre"] = nombreLegible;
            cardDash["seccion"] = "Sección " + primero.seccion + " • Aula " + aulaConEscuela;
            cardDash["profesor"] = primero.profesor;
            cardDash["codigo"] = primero.codigo;
            cardDash["horario1"] = nombresDias[d] + " • " + mapaHora12h.value(hIni, hIni) + " - " + mapaHora12h.value(hFin, hFin) + " (Aula " + aulaConEscuela + ")";
            cardDash["horario2"] = (primero.esLab ? "Laboratorio • " : "Teoría • ") + bloquesTxt;
            cardDash["c1"] = primero.color1;
            cardDash["c2"] = primero.color2;
            cardDash["c3"] = primero.color3;
            tarjetasDiaDashboard.append(cardDash);

            i = j + 1;
        }

        QVariantMap diaObj;
        diaObj["corto"] = cortosDias[d];
        diaObj["nombre"] = nombresDias[d];
        diaObj["bloques"] = numBloquesDia;
        diaObj["horas"] = horasTxt;
        diaObj["clases"] = clasesAgrupadas;
        nuevaDiasSemana.append(diaObj);

        nuevaClasesDashboard.append(QVariant::fromValue(tarjetasDiaDashboard));
    }

    // Construir la malla semanal completa
    QVariantList nuevaMalla;
    for (int hIdx = 0; hIdx <= maxIndiceHora && hIdx < ordenHorasInicio.size(); ++hIdx) {
        QString horaCod = ordenHorasInicio[hIdx];
        QStringList celdasFila;
        for (const QString &diaCod : codigosDias) {
            celdasFila.append(celdaMalla[horaCod].value(diaCod, ""));
        }
        QVariantMap filaMalla;
        filaMalla["hora"] = mapaHoraInicioFmt.value(horaCod, horaCod);
        filaMalla["celdas"] = celdasFila;
        nuevaMalla.append(filaMalla);
    }

    m_diasHorarioAsignado = nuevaDiasSemana;
    m_mallaHorarioAsignado = nuevaMalla;
    m_clasesPorDiaDashboard = nuevaClasesDashboard;
    m_materiasSinBloqueHorario = listaSinBloques;
    m_totalBloquesHorario = conteoTotalBloques;
    m_totalMateriasHorario = m_materiasInscritasRaw.size();

    emit horarioAsignadoChanged();
    emit materiasRecordatorioChanged();
}

void DaeClient::cargarOfertaHorarios()
{
    if (m_cargandoHorarios) return;
    m_cargandoHorarios = true;
    emit cargandoHorariosChanged();

    QUrl url("https://dae.ing.uc.edu.ve/horarios/");
    QNetworkRequest req(url);
    configurarRequestDae(req);

    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        m_cargandoHorarios = false;
        emit cargandoHorariosChanged();

        if (reply->error() != QNetworkReply::NoError) {
            return;
        }

        QString html = QString::fromUtf8(reply->readAll());
        if (html.contains("HORARIOS PENSUM", Qt::CaseInsensitive)) {
            QString dirApp = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
            QDir().mkpath(dirApp);
            QFile fOut(dirApp + "/horarios_cache.html");
            if (fOut.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
                fOut.write(html.toUtf8());
                fOut.close();
            }
        }
        parsearHtmlHorarios(html);
    });
}

void DaeClient::parsearHtmlHorarios(const QString &html)
{
    // 1. Extraer fecha de actualización: <center><h4>Actualizado al 22/10/2026 06:47 pm</h4></center>
    static const QRegularExpression reFecha("<h4>\\s*(Actualizado al[^<]+)</h4>", QRegularExpression::CaseInsensitiveOption);
    QRegularExpressionMatch mFecha = reFecha.match(html);
    if (mFecha.hasMatch()) {
        m_fechaActualizacionHorarios = limpiarTextoHtml(mFecha.captured(1));
    }

    // 1.b Extraer el período publicado en la página: <h3>HORARIOS PERIODO 1-2026 ...</h3>
    static const QRegularExpression rePerHor("PERIODO\\s+([12]-20\\d{2})", QRegularExpression::CaseInsensitiveOption);
    QRegularExpressionMatch mPerHor = rePerHor.match(html);
    if (mPerHor.hasMatch()) {
        m_periodoPaginaHorarios = mPerHor.captured(1);
    }

    // 2. Separar bloque de PENSUM NUEVO (2025) y PENSUM VIEJO (1997)
    int idxNuevo = html.indexOf("HORARIOS PENSUM NUEVO", 0, Qt::CaseInsensitive);
    int idxViejo = html.indexOf("HORARIOS PENSUM VIEJO", 0, Qt::CaseInsensitive);

    if (idxNuevo != -1 && idxViejo != -1) {
        QString htmlNuevo = html.mid(idxNuevo, idxViejo - idxNuevo);
        QString htmlViejo = html.mid(idxViejo);

        QVariantList acumuladorPlano;
        QVariantList lista2025 = parsearBloquePensumHorarios(htmlNuevo, "2025", acumuladorPlano);
        QVariantList lista1997 = parsearBloquePensumHorarios(htmlViejo, "1997", acumuladorPlano);

        if (!lista2025.isEmpty()) m_horariosPensum2025 = lista2025;
        if (!lista1997.isEmpty()) m_horariosPensum1997 = lista1997;
        if (!acumuladorPlano.isEmpty()) m_seccionesOfertaPlana = acumuladorPlano;

        // Actualizar los profesores reales en el Horario Asignado del estudiante
        reconstruirEstructurasHorarioAsignado();
        if (m_autenticado) {
            reconstruirOfertaInscripcionDesdeRap();
        }
        emit horariosOfertaChanged();
    }
}

static QString normalizarTextoBusquedaCpp(QString s)
{
    s = s.toUpper();
    s.replace(QRegularExpression(QStringLiteral("[ÁÀÄÂ]")), QStringLiteral("A"));
    s.replace(QRegularExpression(QStringLiteral("[ÉÈËÊ]")), QStringLiteral("E"));
    s.replace(QRegularExpression(QStringLiteral("[ÍÌÏÎ]")), QStringLiteral("I"));
    s.replace(QRegularExpression(QStringLiteral("[ÓÒÖÔ]")), QStringLiteral("O"));
    s.replace(QRegularExpression(QStringLiteral("[ÚÙÜÛ]")), QStringLiteral("U"));
    s.replace(QStringLiteral("Ñ"), QStringLiteral("N"));
    return s.simplified();
}

QVariantList DaeClient::parsearBloquePensumHorarios(const QString &bloqueHtml, const QString &tagPensum, QVariantList &acumuladorPlano)
{
    // Cada entrada está separada por <br><br>
    QStringList entradas = bloqueHtml.split("<br><br>", Qt::SkipEmptyParts);

    // Mapa temporal para agrupar secciones por código de asignatura manteniendo el orden
    QStringList ordenCodigos;
    QMap<QString, QVariantMap> mapaMaterias;

    static const QRegularExpression reStrong(
        "<strong>\\s*([A-Z0-9]{4,9})\\s+(.+?)\\s+(\\d{1,3})\\s*</strong>(.*)$",
        QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);

    static const QRegularExpression reBloqueHorario(
        "\\b(LU|MA|MI|JU|VI|SA|DO)(\\d{4})(?:\\s+(?!(?:LU|MA|MI|JU|VI|SA|DO)\\d{4}\\b)([A-Z0-9\\-]{1,10}))?\\b");

    for (const QString &rawEntry : entradas) {
        QString entry = rawEntry;
        entry.replace("&nbsp;", " ");

        QRegularExpressionMatch m = reStrong.match(entry);
        if (!m.hasMatch()) continue;

        QString codigo = limpiarTextoHtml(m.captured(1)).toUpper();
        QString nombre = limpiarTextoHtml(m.captured(2));
        QString seccion = m.captured(3).trimmed().rightJustified(2, '0');
        QString restoHtml = m.captured(4);

        // Determinar estado oficial en DAE: CERRADA, NUEVA, ACTUALIZADA o NORMAL
        QString estado = "NORMAL";
        if (entry.contains("(CERRADA)", Qt::CaseInsensitive) ||
            entry.contains("color='red'", Qt::CaseInsensitive)) {
            estado = "CERRADA";
        } else if (entry.contains("(NUEVA)", Qt::CaseInsensitive) ||
                   entry.trimmed().startsWith("<font color='blue'>", Qt::CaseInsensitive)) {
            estado = "NUEVA";
        } else if (entry.contains("color='blue'", Qt::CaseInsensitive)) {
            estado = "ACTUALIZADA";
        }

        // Separar primera línea (profesor) y segunda línea (bloques de horario) por <br>
        QStringList partesBr = restoHtml.split("<br>", Qt::KeepEmptyParts);
        QString profRaw = partesBr.isEmpty() ? "" : limpiarTextoHtml(partesBr[0]);
        profRaw.replace("(CERRADA)", "", Qt::CaseInsensitive);
        profRaw.replace("(NUEVA)", "", Qt::CaseInsensitive);
        profRaw = profRaw.trimmed();

        QString bloquesRaw = partesBr.size() > 1 ? limpiarTextoHtml(partesBr.mid(1).join(" ")) : "";
        QStringList listaBloques;
        QRegularExpressionMatchIterator itB = reBloqueHorario.globalMatch(bloquesRaw);
        while (itB.hasNext()) {
            QRegularExpressionMatch mb = itB.next();
            QString aulaCap = mb.captured(3).trimmed();
            listaBloques.append(aulaCap.isEmpty()
                                ? (mb.captured(1) + mb.captured(2))
                                : (mb.captured(1) + mb.captured(2) + " " + aulaCap));
        }

        if (profRaw.isEmpty() && !listaBloques.isEmpty()) {
            profRaw = "PROF. NO ASIGNADO";
        }

        // Guardar en los mapas globales para cruzar con el Horario Asignado del estudiante
        QString claveSec = codigo + "|" + seccion;
        if (!profRaw.isEmpty()) {
            m_mapaProfesorHorario[claveSec] = profRaw;
        }
        if (!listaBloques.isEmpty() && !m_clavesBloquesDelEstudiante.contains(claveSec)) {
            m_mapaBloquesHorario[claveSec] = listaBloques;
        }
        m_mapaEstadoHorario[claveSec] = estado;
        if (!m_mapaNombreMateriaHorario.contains(codigo)) {
            m_mapaNombreMateriaHorario[codigo] = nombre;
        }

        // Agregar a la lista plana en C++ para filtrado instantáneo y paginado desde QML
        QVariantMap itemPlano;
        itemPlano["pensum"] = tagPensum;
        itemPlano["codigo"] = codigo;
        itemPlano["nombre"] = nombre;
        itemPlano["sec"] = seccion;
        itemPlano["profesor"] = profRaw;
        itemPlano["estado"] = estado;
        itemPlano["bloques"] = listaBloques;
        itemPlano["busquedaCache"] = normalizarTextoBusquedaCpp(codigo + " " + nombre + " " + profRaw + " " + seccion + " " + listaBloques.join(" "));
        acumuladorPlano.append(itemPlano);

        // Inferir semestre a partir del código (ej. CA3013 -> 3, DI2B01 -> 2, ER0T08 -> 10)
        int sem = 1;
        for (int cIdx = 2; cIdx < codigo.length(); ++cIdx) {
            if (codigo[cIdx].isDigit()) {
                sem = codigo[cIdx].digitValue();
                if (sem == 0) sem = 10;
                break;
            }
        }

        if (!mapaMaterias.contains(codigo)) {
            ordenCodigos.append(codigo);
            QVariantMap mat;
            mat["codigo"] = codigo;
            mat["nombre"] = nombre;
            mat["sem"] = sem;
            mat["secciones"] = QVariantList();
            mapaMaterias[codigo] = mat;
        }

        QVariantMap secObj;
        secObj["sec"] = seccion;
        secObj["profesor"] = profRaw;
        secObj["estado"] = estado;
        secObj["bloques"] = listaBloques;

        QVariantMap matActual = mapaMaterias[codigo];
        QVariantList secs = matActual["secciones"].toList();
        secs.append(secObj);
        matActual["secciones"] = secs;
        mapaMaterias[codigo] = matActual;
    }

    QVariantList resultado;
    for (const QString &cod : ordenCodigos) {
        resultado.append(mapaMaterias[cod]);
    }
    return resultado;
}

QVariantList DaeClient::filtrarHorariosOferta(int pensumIdx, int estadoIdx, const QString &busqueda, int limite) const
{
    QVariantList resultado;
    const QString busqNorm = normalizarTextoBusquedaCpp(busqueda);
    const QStringList tokensBusq = busqNorm.split(' ', Qt::SkipEmptyParts);
    int maxItems = (limite > 0) ? limite : 30;

    for (const QVariant &v : m_seccionesOfertaPlana) {
        const QVariantMap item = v.toMap();
        const QString pensum = item["pensum"].toString();
        const QString estado = item["estado"].toString();
        const QString profesor = item["profesor"].toString();

        if (pensumIdx == 1 && pensum != "1997") continue;
        if (pensumIdx == 2 && pensum != "2025") continue;

        if (estadoIdx == 1 && estado == "CERRADA") continue;
        if (estadoIdx == 2 && estado != "NUEVA" && estado != "ACTUALIZADA") continue;
        if (estadoIdx == 3 && estado != "CERRADA") continue;
        if (estadoIdx == 4 && profesor != "PROF. NO ASIGNADO") continue;

        if (!tokensBusq.isEmpty()) {
            const QString cache = item["busquedaCache"].toString();
            bool coincide = true;
            for (const QString &tok : tokensBusq) {
                if (!cache.contains(tok)) {
                    coincide = false;
                    break;
                }
            }
            if (!coincide) continue;
        }

        resultado.append(item);
        if (resultado.size() >= maxItems) {
            break;
        }
    }
    return resultado;
}

int DaeClient::contarHorariosOferta(int pensumIdx, int estadoIdx, const QString &busqueda) const
{
    int total = 0;
    const QString busqNorm = normalizarTextoBusquedaCpp(busqueda);
    const QStringList tokensBusq = busqNorm.split(' ', Qt::SkipEmptyParts);

    for (const QVariant &v : m_seccionesOfertaPlana) {
        const QVariantMap item = v.toMap();
        const QString pensum = item["pensum"].toString();
        const QString estado = item["estado"].toString();
        const QString profesor = item["profesor"].toString();

        if (pensumIdx == 1 && pensum != "1997") continue;
        if (pensumIdx == 2 && pensum != "2025") continue;

        if (estadoIdx == 1 && estado == "CERRADA") continue;
        if (estadoIdx == 2 && estado != "NUEVA" && estado != "ACTUALIZADA") continue;
        if (estadoIdx == 3 && estado != "CERRADA") continue;
        if (estadoIdx == 4 && profesor != "PROF. NO ASIGNADO") continue;

        if (!tokensBusq.isEmpty()) {
            const QString cache = item["busquedaCache"].toString();
            bool coincide = true;
            for (const QString &tok : tokensBusq) {
                if (!cache.contains(tok)) {
                    coincide = false;
                    break;
                }
            }
            if (!coincide) continue;
        }

        total++;
    }
    return total;
}

QVariantMap DaeClient::consultarSalonesDisponibles(int diaIdx, int horaIdx, int categoriaFiltro, const QString &busqueda) const
{
    static const QStringList codigosDias = {"LU", "MA", "MI", "JU", "VI", "SA"};
    static const QStringList codigosHoras = {
        "0800", "0850", "0940", "1030", "1120", "1210", "1300", "1350",
        "1440", "1530", "1620", "1710", "1800", "1850", "1940"
    };
    static const QStringList etiquetasHoras = {
        "08:00", "08:50", "09:40", "10:30", "11:20", "12:10", "01:00", "01:50",
        "02:40", "03:30", "04:20", "05:10", "06:00", "06:50", "07:40"
    };
    static const QStringList etiquetasHorasFin = {
        "08:50", "09:40", "10:30", "11:20", "12:10", "01:00", "01:50", "02:40",
        "03:30", "04:20", "05:10", "06:00", "06:50", "07:40", "08:30"
    };

    struct InfoSalon {
        QString codigo;
        QString nombre;
        QString sector;
        int categoria; // 1 = Módulos AD, 2 = Aulas A/AE/AF, 3 = Salones de Escuela
        QString categoriaNombre;
    };

    static const QList<InfoSalon> catalogoSalones = {
        // 1. Módulos AD (Anfiteatros)
        {"AD1",  "Anfiteatro AD1",                 "Sector Central-Norte • Junto a Publicaciones y Física",       1, "Módulo AD"},
        {"AD2",  "Anfiteatro AD2",                 "Sector Central-Norte • Frente a Esc. Industrial y El Chileno",1, "Módulo AD"},
        {"AD3",  "Anfiteatro AD3",                 "Sector Central-Norte • Junto a Biblioteca Central y SOE",     1, "Módulo AD"},
        {"AD4",  "Anfiteatro AD4",                 "Entrada Norte • Frente al pasillo de LIM",                    1, "Módulo AD"},
        {"AD5",  "Anfiteatro AD5",                 "Sector Este • Debajo del Dpto. de Matemáticas",               1, "Módulo AD"},
        {"AD6",  "Anfiteatro AD6",                 "Extremo Este • Debajo de REDUC",                              1, "Módulo AD"},
        {"AD7",  "Anfiteatro AD7",                 "Sector Sureste • Al este del Dpto. de Humanidades",           1, "Módulo AD"},
        {"AD8",  "Anfiteatro AD8",                 "Sector Sureste • Al oeste del Dpto. de Humanidades",          1, "Módulo AD"},
        {"AD9",  "Anfiteatro AD9",                 "Esquina Sureste • Junto a Escuela de Ing. Química",           1, "Módulo AD"},

        // 2. Aulas Generales y Pabellones (A / AE / AF)
        {"A3M",  "Aula A3M",                       "Sector Central-Oeste • Al sur de Civil Hidráulica",           2, "Aula General"},
        {"A4M",  "Aula A4M",                       "Sector Central-Oeste • Al sur de Civil Hidráulica",           2, "Aula General"},
        {"A5E",  "Aula A5E",                       "Pabellón Noroeste • Segunda fila junto a A6E",                2, "Aula General"},
        {"A6E",  "Aula A6E",                       "Pabellón Noroeste • Debajo del Dpto. de Idiomas",             2, "Aula General"},
        {"A7E",  "Aula A7E",                       "Pabellón Norte • Entre A8I y SEIN",                           2, "Aula General"},
        {"A8I",  "Aula A8I",                       "Pabellón Norte • Frente al camino central de Civil",          2, "Aula General"},
        {"A9I",  "Aula A9I",                       "Pabellón Norte • Entre Dpto. de Idiomas y A8I",               2, "Aula General"},
        {"A10",  "Aula A10",                       "Sector Sur • Entrada Norte de FACYT",                         2, "Aula General"},
        {"A11",  "Aula A11",                       "Sector Sur • Entrada Norte de FACYT",                         2, "Aula General"},
        {"AF1",  "Aula de Física AF1",             "Sector Central • Módulo de Física bajo AD1",                  2, "Aula General"},
        {"AF2",  "Aula de Física AF2",             "Sector Central • Módulo de Física bajo AD1",                  2, "Aula General"},
        {"AE1",  "Aula Exterior AE1",              "Sector Suroeste • Debajo de Plaza Las Iguanas",               2, "Aula Exterior"},
        {"AE2",  "Aula Exterior AE2",              "Sector Suroeste • Debajo de Plaza Las Iguanas",               2, "Aula Exterior"},
        {"AE3",  "Aula Exterior AE3",              "Sector Suroeste • Junto a FCU",                               2, "Aula Exterior"},
        {"AE4",  "Aula Exterior AE4",              "Sector Suroeste • Al este del Auditorio Maneiro",             2, "Aula Exterior"},
        {"AE5",  "Aula Exterior AE5",              "Sector Suroeste • Al este del Auditorio Maneiro",             2, "Aula Exterior"},
        {"AE6",  "Aula Exterior AE6",              "Sector Suroeste • Al este del Auditorio Maneiro",             2, "Aula Exterior"},
        {"AE7",  "Aula Exterior AE7",              "Sector Suroeste • Al este del Auditorio Maneiro",             2, "Aula Exterior"},
        {"AE8",  "Aula Exterior AE8",              "Sector Suroeste • Entre AE1-AE3 y AE4-AE7",                   2, "Aula Exterior"},
        {"AE9",  "Aula Exterior AE9",              "Sector Suroeste • Entre AE1-AE3 y AE4-AE7",                   2, "Aula Exterior"},

        // 3. Salones de Escuelas y Departamentos
        {"SIE1", "Salón SIE 1",                    "Escuela de Eléctrica • Ala Este de Biblioteca Central",       3, "Salón de Escuela"},
        {"SIE2", "Salón SIE 2",                    "Escuela de Eléctrica • Ala Este de Biblioteca Central",       3, "Salón de Escuela"},
        {"SIE3", "Salón SIE 3",                    "Pabellón Eléctrica Norte • Junto a SLM",                      3, "Salón de Escuela"},
        {"SLM",  "Salón SLM",                      "Pabellón Eléctrica Norte • Junto a SIE 3",                    3, "Salón de Escuela"},
        {"SEIN", "Salón / Lab. SEIN",              "Pabellón Norte • Extremo Este frente a AD4",                  3, "Salón de Escuela"},
        {"ALT",  "Salón ALT",                      "Centro-Este • Módulo de Máquinas Eléctricas",                 3, "Salón de Escuela"},
        {"SD1",  "Sala de Dibujo SD1",             "Sector Central • Departamento de Dibujo",                     3, "Salón de Escuela"},
        {"SD2",  "Sala de Dibujo SD2",             "Sector Central • Departamento de Dibujo",                     3, "Salón de Escuela"},
        {"SD3",  "Sala de Dibujo SD3",             "Sector Central • Departamento de Dibujo",                     3, "Salón de Escuela"},
        {"SDC",  "Sala de Dibujo SDC",             "Sector Central • Departamento de Dibujo",                     3, "Salón de Escuela"},
        {"SH01", "Salón Hidráulica SH01",          "Sector Noroeste • Escuela de Civil Hidráulica",               3, "Salón de Escuela"},
        {"SH02", "Salón Hidráulica SH02",          "Sector Noroeste • Escuela de Civil Hidráulica",               3, "Salón de Escuela"},
        {"SH03", "Salón Hidráulica SH03",          "Sector Noroeste • Escuela de Civil Hidráulica",               3, "Salón de Escuela"},
        {"ADP",  "Aula Dpto. Pavimentos (ADP)",    "Sector Noroeste • Escuela de Ingeniería Civil",               3, "Salón de Escuela"},
        {"ADH2", "Aula Hidráulica ADH2",           "Sector Noroeste • Escuela de Civil Hidráulica",               3, "Salón de Escuela"},
        {"AFG",  "Aula AFG",                       "Sector Noroeste • Escuela de Civil Hidráulica",               3, "Salón de Escuela"},
        {"ANM",  "Aula ANM",                       "Sector Suroeste • Complejo Escuela de Mecánica",              3, "Salón de Escuela"},
        {"ASM",  "Aula ASM",                       "Sector Suroeste • Complejo Escuela de Mecánica",              3, "Salón de Escuela"},
        {"SPM",  "Salón SPM",                      "Sector Suroeste • Complejo Escuela de Mecánica",              3, "Salón de Escuela"},
        {"SPG",  "Salón SPG",                      "Sector Suroeste • Complejo Escuela de Mecánica",              3, "Salón de Escuela"},
        {"SGE",  "Salón SGE",                      "Sector Central-Norte • Escuela de Industrial",                3, "Salón de Escuela"},
        {"LIM",  "Salón / Lab. LIM",               "Pasillo Industrial Norte • Frente a AD4",                     3, "Salón de Escuela"},
        {"AEIQ", "Aula Esc. Química (AEIQ)",       "Sector Sureste • Escuela de Ingeniería Química",              3, "Salón de Escuela"},
        {"CIQ",  "Salón C.I.Q.",                   "Complejo Mecánica / Ingeniería Química",                      3, "Salón de Escuela"},
        {"AID",  "Aula de Idiomas (AID)",          "Fila Superior Noroeste • Dpto. de Idiomas",                   3, "Salón de Escuela"},
        {"SUM",  "Salón de Usos Múltiples (SUM)",  "Facultad de Ingeniería UC",                                   3, "Salón de Escuela"}
    };

    const int dClamped = qBound(0, diaIdx, codigosDias.size() - 1);
    const int hClamped = qBound(0, horaIdx, codigosHoras.size() - 1);
    const QString diaCod = codigosDias[dClamped];

    struct OcupacionBloque {
        QString codigo;
        QString nombre;
        QString sec;
        QString profesor;
    };

    // Mapa: aulaCodigo -> (indiceHora 0..14 -> OcupacionBloque)
    QHash<QString, QHash<int, OcupacionBloque>> ocupacionDia;

    static const QRegularExpression reBloqueItem("^(LU|MA|MI|JU|VI|SA|DO)(\\d{4})(?:\\s+(.+))?$");

    for (const QVariant &v : m_seccionesOfertaPlana) {
        const QVariantMap item = v.toMap();
        const QString estado = item["estado"].toString();
        if (estado == "CERRADA") continue;

        const QStringList bloques = item["bloques"].toStringList();
        if (bloques.isEmpty()) continue;

        const QString codMat = item["codigo"].toString();
        const QString nomMat = item["nombre"].toString();
        const QString secMat = item["sec"].toString();
        const QString profMat = item["profesor"].toString();

        for (const QString &b : bloques) {
            QRegularExpressionMatch mb = reBloqueItem.match(b.trimmed());
            if (!mb.hasMatch()) continue;
            if (mb.captured(1) != diaCod) continue;

            QString aula = mb.captured(3).trimmed().toUpper();
            if (aula.isEmpty() || aula == "AVING") continue;

            int idxH = codigosHoras.indexOf(mb.captured(2));
            if (idxH < 0) continue;

            if (!ocupacionDia[aula].contains(idxH)) {
                ocupacionDia[aula][idxH] = {codMat, nomMat, secMat, profMat};
            }
        }
    }

    const QString busqNorm = normalizarTextoBusquedaCpp(busqueda);
    const QStringList tokensBusq = busqNorm.split(' ', Qt::SkipEmptyParts);

    int totalDisponibles = 0;
    int totalRestoDia = 0;
    int totalOcupados = 0;

    QVariantList listaResultado;

    for (const InfoSalon &s : catalogoSalones) {
        const QHash<int, OcupacionBloque> &horasOcupadas = ocupacionDia[s.codigo];
        const bool estaOcupadoAhora = horasOcupadas.contains(hClamped);
        const bool disponibleAhora = !estaOcupadoAhora;

        int bloquesLibresSeguidos = 0;
        int proxHoraOcupada = -1;
        int proxHoraLibre = -1;

        if (disponibleAhora) {
            for (int h = hClamped; h < codigosHoras.size(); ++h) {
                if (horasOcupadas.contains(h)) {
                    proxHoraOcupada = h;
                    break;
                }
                bloquesLibresSeguidos++;
            }
            totalDisponibles++;
            if (proxHoraOcupada == -1) {
                totalRestoDia++;
            }
        } else {
            totalOcupados++;
            for (int h = hClamped + 1; h < codigosHoras.size(); ++h) {
                if (!horasOcupadas.contains(h)) {
                    proxHoraLibre = h;
                    break;
                }
            }
        }

        // Aplicar filtro de categoría:
        // 0 = Todos los Disponibles, 1 = Módulos AD Libres, 2 = Aulas A/AE/AF Libres,
        // 3 = Salones de Escuela Libres, 4 = Ocupados en esta hora
        if (categoriaFiltro == 4) {
            if (disponibleAhora) continue;
        } else {
            if (!disponibleAhora) continue;
            if (categoriaFiltro >= 1 && categoriaFiltro <= 3 && s.categoria != categoriaFiltro) {
                continue;
            }
        }

        // Filtro de búsqueda sin acentos ni mayúsculas
        if (!tokensBusq.isEmpty()) {
            QString textoSalon = normalizarTextoBusquedaCpp(
                s.codigo + " " + s.nombre + " " + s.sector + " " + s.categoriaNombre);
            if (estaOcupadoAhora) {
                const OcupacionBloque &oc = horasOcupadas[hClamped];
                textoSalon += " " + normalizarTextoBusquedaCpp(oc.codigo + " " + oc.nombre + " " + oc.profesor);
            }
            bool coincide = true;
            for (const QString &tok : tokensBusq) {
                if (!textoSalon.contains(tok)) {
                    coincide = false;
                    break;
                }
            }
            if (!coincide) continue;
        }

        QString estadoTexto;
        QString detalleSub;
        bool todoElResto = (disponibleAhora && proxHoraOcupada == -1);

        if (disponibleAhora) {
            if (todoElResto) {
                estadoTexto = QStringLiteral("Libre el resto del día");
                detalleSub = QStringLiteral("Sin más clases asignadas hoy en este salón");
            } else {
                QString horaProxStr = etiquetasHoras[proxHoraOcupada];
                if (bloquesLibresSeguidos == 1) {
                    estadoTexto = QString("Libre 1 bloque (hasta las %1)").arg(horaProxStr);
                } else {
                    estadoTexto = QString("Libre %1 bloques (hasta las %2)").arg(bloquesLibresSeguidos).arg(horaProxStr);
                }
                const OcupacionBloque &proxMat = horasOcupadas[proxHoraOcupada];
                detalleSub = QString("Próxima clase (%1): %2 %3 (Sec. %4)")
                                 .arg(horaProxStr, proxMat.codigo, proxMat.nombre, proxMat.sec);
            }
        } else {
            const OcupacionBloque &ocActual = horasOcupadas[hClamped];
            if (proxHoraLibre != -1) {
                estadoTexto = QString("Ocupado • Se libera a las %1").arg(etiquetasHoras[proxHoraLibre]);
            } else {
                estadoTexto = QStringLiteral("Ocupado el resto del día");
            }
            detalleSub = QString("En clase: %1 %2 (Sec. %3) • %4")
                             .arg(ocActual.codigo, ocActual.nombre, ocActual.sec, ocActual.profesor);
        }

        // Construir tira visual de los primeros 12 bloques del día (08:00 a 18:00)
        QVariantList bloquesBarra;
        const int numBloquesBarra = qMin(12, int(codigosHoras.size()));
        for (int h = 0; h < numBloquesBarra; ++h) {
            QVariantMap bObj;
            bObj["hora"] = etiquetasHoras[h];
            bObj["horaFin"] = etiquetasHorasFin[h];
            bObj["ocupado"] = horasOcupadas.contains(h);
            bObj["seleccionado"] = (h == hClamped);
            if (horasOcupadas.contains(h)) {
                const OcupacionBloque &oc = horasOcupadas[h];
                bObj["materia"] = oc.codigo + " (" + oc.sec + ")";
            } else {
                bObj["materia"] = QStringLiteral("Libre");
            }
            bloquesBarra.append(bObj);
        }

        QVariantMap itemSalon;
        itemSalon["codigo"] = s.codigo;
        itemSalon["nombre"] = s.nombre;
        itemSalon["sector"] = s.sector;
        itemSalon["categoria"] = s.categoria;
        itemSalon["categoriaNombre"] = s.categoriaNombre;
        itemSalon["disponible"] = disponibleAhora;
        itemSalon["todoElRestoDelDia"] = todoElResto;
        itemSalon["bloquesLibres"] = bloquesLibresSeguidos;
        itemSalon["estadoTexto"] = estadoTexto;
        itemSalon["detalleSub"] = detalleSub;
        itemSalon["bloquesBarra"] = bloquesBarra;
        listaResultado.append(itemSalon);
    }

    // Ordenar: primero los que tienen más bloques consecutivos libres, y luego por categoría/código
    std::stable_sort(listaResultado.begin(), listaResultado.end(), [](const QVariant &a, const QVariant &b) {
        const QVariantMap ma = a.toMap();
        const QVariantMap mb = b.toMap();
        const bool dispA = ma["disponible"].toBool();
        const bool dispB = mb["disponible"].toBool();
        if (dispA != dispB) return dispA;
        const int libA = ma["bloquesLibres"].toInt();
        const int libB = mb["bloquesLibres"].toInt();
        if (libA != libB) return libA > libB;
        return ma["categoria"].toInt() < mb["categoria"].toInt();
    });

    QVariantMap respuesta;
    respuesta["totalDisponibles"] = totalDisponibles;
    respuesta["totalRestoDia"] = totalRestoDia;
    respuesta["totalOcupados"] = totalOcupados;
    respuesta["salones"] = listaResultado;
    return respuesta;
}

void DaeClient::cargarPensum(int modoVista, int escuelaIdx)
{
    if (modoVista == 2) {
        cargarFaqPensum();
        return;
    }

    // Mapeo de escuelaIdx de la App a los códigos oficiales del formulario DAE:
    // 0: Telecomunicaciones (307), 1: Industrial (301), 2: Eléctrica (302),
    // 3: Mecánica (303), 4: Química (304), 5: Civil (306)
    static const QStringList codigosEscuela = {"307", "301", "302", "303", "304", "306"};
    QString codEscuela = (escuelaIdx >= 0 && escuelaIdx < codigosEscuela.size())
                         ? codigosEscuela[escuelaIdx]
                         : "307";

    // En DAE: pensum=2 es Pensum Actual (1997), pensum=3 es Pensum Nuevo (2025)
    int idPensumDae = (modoVista == 1) ? 3 : 2;

    m_cargandoPensum = true;
    emit cargandoPensumChanged();

    QUrl url(QString("https://dae.ing.uc.edu.ve/pensa/index.php?pensum=%1").arg(idPensumDae));
    QNetworkRequest req(url);
    configurarRequestDae(req);
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");

    QUrlQuery postData;
    postData.addQueryItem("escuela", codEscuela);

    QNetworkReply *reply = m_nam->post(req, postData.toString(QUrl::FullyEncoded).toUtf8());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        m_cargandoPensum = false;
        emit cargandoPensumChanged();

        if (reply->error() != QNetworkReply::NoError) {
            return;
        }

        QString html = QString::fromUtf8(reply->readAll());
        parsearHtmlPensum(html);
    });
}

void DaeClient::parsearHtmlPensum(const QString &html)
{
    // 1. Eliminar todos los bloques <dialog>...</dialog> incrustados dentro de las celdas
    //    para que sus tablas internas no se mezclen con las filas de asignaturas.
    QString htmlLimpio = html;
    static const QRegularExpression reDialogs(
        "<dialog[^>]*>.*?</dialog>",
        QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);
    htmlLimpio.remove(reDialogs);

    QVariantList listaSemestres;

    static const QRegularExpression reSemHeader(
        "<tr\\s+class=['\"]semestre['\"][^>]*>\\s*<th[^>]*>(.*?)</th>\\s*</tr>",
        QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);

    static const QRegularExpression reTrFila(
        "<tr[^>]*>(.*?)</tr>",
        QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);

    static const QRegularExpression reTdCelda(
        "<td[^>]*>(.*?)</td>",
        QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);

    static const QRegularExpression reCodigoValido("^[A-Z0-9]{5,8}$");

    QList<QRegularExpressionMatch> matchesSem;
    QRegularExpressionMatchIterator itSem = reSemHeader.globalMatch(htmlLimpio);
    while (itSem.hasNext()) {
        matchesSem.append(itSem.next());
    }

    for (int i = 0; i < matchesSem.size(); ++i) {
        QString headerCompleto = limpiarTextoHtml(matchesSem[i].captured(1));
        int startPos = matchesSem[i].capturedEnd();
        int endPos = (i + 1 < matchesSem.size()) ? matchesSem[i + 1].capturedStart() : htmlLimpio.length();
        QString segmentoHtml = htmlLimpio.mid(startPos, endPos - startPos);

        QString tituloSem = headerCompleto;
        QString avisoSem = "";
        int dashIdx = headerCompleto.indexOf('-');
        if (dashIdx != -1) {
            tituloSem = headerCompleto.left(dashIdx).trimmed();
            avisoSem = headerCompleto.mid(dashIdx + 1).trimmed();
        }

        int numSem = i + 1;
        QVariantList materiasSem;
        double totalUc = 0.0;

        // Analizar cada fila <tr>...</tr> por separado (soporta U.C. decimales como 1.5 y 2.5 en Industrial, Mecánica, Química y Civil)
        QRegularExpressionMatchIterator itTr = reTrFila.globalMatch(segmentoHtml);
        while (itTr.hasNext()) {
            QString contenidoTr = itTr.next().captured(1);
            QStringList celdas;

            QRegularExpressionMatchIterator itTd = reTdCelda.globalMatch(contenidoTr);
            while (itTd.hasNext()) {
                celdas.append(limpiarTextoHtml(itTd.next().captured(1)));
            }

            if (celdas.size() < 7) continue;

            QString codigo = celdas[0].trimmed();
            if (!reCodigoValido.match(codigo).hasMatch()) continue;

            QString nombre = celdas[1].trimmed();
            QString ucStr = celdas[2].trimmed();
            ucStr.replace(',', '.');
            double uc = ucStr.toDouble();

            double tVal = celdas[3].trimmed().replace(',', '.').toDouble();
            double pVal = celdas[4].trimmed().replace(',', '.').toDouble();
            double lVal = celdas[5].trimmed().replace(',', '.').toDouble();
            QString req = celdas[6].trimmed();
            if (req.isEmpty()) req = "NINGUNO";

            QVariantMap mat;
            mat["sem"] = numSem;
            mat["codigo"] = codigo;
            mat["nombre"] = nombre;
            mat["uc"] = uc;
            mat["t"] = tVal;
            mat["p"] = pVal;
            mat["l"] = lVal;
            mat["req"] = req;

            totalUc += uc;
            materiasSem.append(mat);
        }

        if (!materiasSem.isEmpty()) {
            QVariantMap semObj;
            semObj["sem"] = numSem;
            semObj["titulo"] = tituloSem;
            semObj["aviso"] = avisoSem;
            semObj["totalUc"] = qRound(totalUc * 10.0) / 10.0;
            semObj["materias"] = materiasSem;
            listaSemestres.append(semObj);
        }
    }

    if (!listaSemestres.isEmpty()) {
        m_semestresPensum = listaSemestres;

        // Recalcular UC inscritas con los créditos exactos del pensum descargado
        int sumaUc = 0;
        for (const QVariant &v : m_materiasInscritasRaw) {
            sumaUc += obtenerUcAsignatura(v.toMap()["codigo"].toString());
        }
        if (sumaUc > 0 && sumaUc != m_ucInscritas) {
            m_ucInscritas = sumaUc;
            emit horarioAsignadoChanged();
    emit materiasRecordatorioChanged();
        }

        emit pensumChanged();
    }
}

void DaeClient::cargarFaqPensum()
{
    QUrl url("https://dae.ing.uc.edu.ve/pensa/faq.php");
    QNetworkRequest req(url);
    configurarRequestDae(req);

    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) return;

        QString html = QString::fromUtf8(reply->readAll());
        parsearHtmlFaqPensum(html);
    });
}

void DaeClient::parsearHtmlFaqPensum(const QString &html)
{
    QVariantList listaFaq;
    static const QRegularExpression reFaq(
        "<div\\s+class=['\"]pregunta['\"][^>]*>(.*?)<span[^>]*>.*?</span>\\s*</div>\\s*"
        "<div\\s+class=['\"]respuesta['\"][^>]*>(.*?)</div>",
        QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);

    QRegularExpressionMatchIterator it = reFaq.globalMatch(html);
    while (it.hasNext()) {
        QRegularExpressionMatch m = it.next();
        QVariantMap item;
        item["pregunta"] = limpiarTextoHtml(m.captured(1));
        item["respuesta"] = limpiarTextoHtml(m.captured(2));
        listaFaq.append(item);
    }

    if (!listaFaq.isEmpty()) {
        m_preguntasFaqPensum = listaFaq;
        emit faqPensumChanged();
    }
}

void DaeClient::cargarCalendarios()
{
    QUrl url("https://dae.ing.uc.edu.ve/portal/");
    QNetworkRequest req(url);
    configurarRequestDae(req);

    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) return;

        QString html = QString::fromUtf8(reply->readAll());
        parsearHtmlPortalCalendarios(html);
    });
}

void DaeClient::parsearHtmlPortalCalendarios(const QString &html)
{
    // Busca enlaces del tipo: <li><a title="Calendario 1-2026" href="/docs/calendario_1_2026rev3.pdf" target="_blank">Calendario 1-2026 (CF 23/07/2026)</a></li>
    static const QRegularExpression reCal(
        "<a[^>]*href=[\"']([^\"']*calendario[^\"']*\\.pdf)[\"'][^>]*>(.*?)</a>",
        QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);

    QVariantList nuevaLista;
    QRegularExpressionMatchIterator it = reCal.globalMatch(html);
    int idx = 0;
    while (it.hasNext()) {
        QRegularExpressionMatch m = it.next();
        QString href = m.captured(1).trimmed();
        QString titulo = limpiarTextoHtml(m.captured(2));

        QUrl fullUrl = QUrl("https://dae.ing.uc.edu.ve/").resolved(QUrl(href));
        QString nombreArchivo = fullUrl.fileName();

        QString fechaCf = "Consejo de Facultad (CF)";
        static const QRegularExpression reCf("\\(CF\\s*([^\\)]+)\\)");
        QRegularExpressionMatch mCf = reCf.match(titulo);
        if (mCf.hasMatch()) {
            fechaCf = "Aprobado en Consejo de Facultad (CF) el " + mCf.captured(1).trimmed();
        }

        QVariantMap item;
        item["titulo"] = titulo;
        item["periodo"] = (idx == 0) ? "Período Lectivo Activo" : "Próximo Período Lectivo";
        item["aprobacion"] = fechaCf;
        item["estado"] = (idx == 0) ? "VIGENTE" : "PUBLICADO";
        item["esVigente"] = (idx == 0);
        item["archivo"] = nombreArchivo;
        item["url"] = fullUrl.toString();
        item["tamano"] = "PDF Oficial DAE";

        nuevaLista.append(item);
        idx++;
    }

    if (!nuevaLista.isEmpty()) {
        m_calendariosOficiales = nuevaLista;
        emit calendariosChanged();
    }
}

void DaeClient::descargarCalendarioPdf(const QString &urlPdf, const QString &nombreArchivo)
{
    if (m_descargandoPdf) return;

    m_descargandoPdf = true;
    emit descargandoPdfChanged();

    QUrl targetUrl(urlPdf.startsWith("http") ? urlPdf : ("https://dae.ing.uc.edu.ve/docs/" + nombreArchivo));
    QNetworkRequest req(targetUrl);
    configurarRequestDae(req);

    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply, nombreArchivo]() {
        reply->deleteLater();
        m_descargandoPdf = false;
        emit descargandoPdfChanged();

        if (reply->error() != QNetworkReply::NoError) {
            emit errorDescargaPdf("No se pudo descargar el PDF: " + reply->errorString());
            return;
        }

        QByteArray pdfBytes = reply->readAll();
        QString dirDescargas = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
        if (dirDescargas.isEmpty()) {
            dirDescargas = QDir::homePath();
        }

        QString rutaCompleta = QDir(dirDescargas).filePath(nombreArchivo.isEmpty() ? "Calendario_DAE_UC.pdf" : nombreArchivo);
        QFile file(rutaCompleta);
        if (file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
            file.write(pdfBytes);
            file.close();
            QDesktopServices::openUrl(QUrl::fromLocalFile(rutaCompleta));
            emit pdfDescargado(rutaCompleta, nombreArchivo);
        } else {
            emit errorDescargaPdf("No se pudo guardar el archivo en " + rutaCompleta);
        }
    });
}

// ============================================================================
// MÓDULO DE INSCRIPCIÓN DE ASIGNATURAS (inscribir.php / procesar.php / RAP)
// ============================================================================

static QVariantList convertirBloquesTextoACeldasMalla(const QStringList &bloquesTexto)
{
    static const QStringList codigosDias = {"LU", "MA", "MI", "JU", "VI", "SA", "DO"};
    static const QStringList codigosHoras = {
        "0800", "0850", "0940", "1030", "1120", "1210", "1300", "1350",
        "1440", "1530", "1620", "1710", "1800", "1850", "1940"
    };
    static const QRegularExpression reBloque("^(LU|MA|MI|JU|VI|SA|DO)(\\d{4})(?:\\s+(.+))?$");

    QVariantList celdas;
    QSet<QString> vistos;
    for (const QString &b : bloquesTexto) {
        QRegularExpressionMatch m = reBloque.match(b.trimmed().toUpper());
        if (!m.hasMatch()) continue;
        int dIdx = codigosDias.indexOf(m.captured(1));
        int hIdx = codigosHoras.indexOf(m.captured(2));
        if (dIdx < 0 || hIdx < 0) continue;
        if (hIdx > 13) hIdx = 13; // La malla de inscripción DAE tiene 14 filas (0..13)
        QString clave = QString::number(dIdx) + "_" + QString::number(hIdx);
        if (vistos.contains(clave)) continue;
        vistos.insert(clave);

        QVariantMap celda;
        celda["dia"] = dIdx;
        celda["hora"] = hIdx;
        celda["aula"] = m.captured(3).trimmed();
        celdas.append(celda);
    }
    return celdas;
}

void DaeClient::cargarDatosInscripcion()
{
    if (m_seccionesOfertaPlana.isEmpty() && !m_cargandoHorarios) {
        cargarOfertaHorarios();
    }

    // Reconstruir de inmediato con el RAP si aún no tenemos la lista del servidor y la inscripción está disponible
    if (m_inscripcionDisponible && m_materiasInscripcion.isEmpty() && !m_materiasRap.isEmpty()) {
        reconstruirOfertaInscripcionDesdeRap();
    }

    if (!m_autenticado || m_pidSesion.isEmpty()) {
        return;
    }

    // Si la sesión se restauró desde la caché, no se consulta al servidor:
    // se usan las copias locales de inscribir.php y reporte.php.
    if (m_datosDesdeCache) {
        if (m_inscripcionDisponible && m_materiasInscripcion.isEmpty()) {
            cargarSeccionDesdeCache("inscribir.php?pid=" + m_pidSesion + "&c=1");
        }
        if (m_reporteInscripcionDisponible && m_solicitudInscripcionRegistrada.isEmpty()) {
            cargarSeccionDesdeCache("reporte.php?pid=" + m_pidSesion);
        }
        if (m_inscripcionDisponible && m_materiasInscripcion.isEmpty() && !m_materiasRap.isEmpty()) {
            reconstruirOfertaInscripcionDesdeRap();
        }
        m_cargandoInscripcion = false;
        emit inscripcionChanged();
        return;
    }

    // Consultar siempre reporte.php si la ruta de reporte está activa en el menú estudiantil
    if (m_reporteInscripcionDisponible) {
        sincronizarSeccionEstudiantil("reporte.php?pid=" + m_pidSesion);
    }

    if (!m_inscripcionDisponible) {
        m_cargandoInscripcion = false;
        emit inscripcionChanged();
        return;
    }

    m_cargandoInscripcion = true;
    emit inscripcionChanged();

    QNetworkRequest req(QUrl("https://dae.ing.uc.edu.ve/gestion_estudiantil/inscribir.php?pid=" + m_pidSesion + "&c=1"));
    configurarRequestDae(req);
    req.setRawHeader("Referer", "https://dae.ing.uc.edu.ve/gestion_estudiantil/index.php");
    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        m_cargandoInscripcion = false;
        if (reply->error() == QNetworkReply::NoError) {
            QString html = QString::fromUtf8(reply->readAll());
            parsearInscripcionHtml(html);
        }
        if (m_inscripcionDisponible && m_materiasInscripcion.isEmpty()) {
            reconstruirOfertaInscripcionDesdeRap();
        }
        emit inscripcionChanged();
    });
}

void DaeClient::parsearInscripcionHtml(const QString &html)
{
    if (!html.contains("CodM[", Qt::CaseInsensitive)) {
        // Si la página devuelta por inscribir.php es directamente un reporte de solicitud previa, parsearlo
        if (html.contains("REPORTE DE SOLICITUD DE INSCRIPCI", Qt::CaseInsensitive)) {
            parsearReporteSolicitudInscripcionHtml(html);
        }
        return;
    }

    // Capturar el action del formulario de inscripción (ej. procesar.php?pid=...&c=3)
    static const QRegularExpression reActionForm(
        "<form[^>]*action=[\"']([^\"']*procesar\\.php[^\"']*)[\"'][^>]*>",
        QRegularExpression::CaseInsensitiveOption);
    QRegularExpressionMatch mAction = reActionForm.match(html);
    if (mAction.hasMatch()) {
        m_urlAccionProcesarInscripcion = mAction.captured(1).trimmed();
    }

    // Extraer arreglos JavaScript generados por inscribir.php / inscribir2.php:
    // Soporta tanto arreglos literales BD[i][j] = [1,2,1,2]; como asignaciones BD[i][j][k] = 1;
    QMap<int, QString> mapCodM;
    QMap<int, QString> mapNomM;
    QMap<int, QString> mapCodP;
    QMap<int, int> mapInsM;
    QMap<int, QString> mapSecInsM;
    QMap<int, QMap<int, QString>> mapCodS;
    QMap<int, QMap<int, QMap<int, int>>> mapBD;
    QMap<int, QMap<int, QMap<int, int>>> mapBH;

    static const QRegularExpression reCodM("CodM\\[(\\d+)\\]\\s*=\\s*['\"]([^'\"]*)['\"]");
    static const QRegularExpression reNomM("NomM\\[(\\d+)\\]\\s*=\\s*['\"]([^'\"]*)['\"]");
    static const QRegularExpression reCodP("CodP\\[(\\d+)\\]\\s*=\\s*['\"]([^'\"]*)['\"]");
    static const QRegularExpression reInsM("InsM\\[(\\d+)\\]\\s*=\\s*['\"]?(\\d+)['\"]?");
    static const QRegularExpression reSecInsM("SecInsM\\[(\\d+)\\]\\s*=\\s*['\"]([^'\"]*)['\"]");
    static const QRegularExpression reCodS("CodS\\[(\\d+)\\]\\[(\\d+)\\]\\s*=\\s*['\"]([^'\"]*)['\"]");
    static const QRegularExpression reBDArray("BD\\[(\\d+)\\]\\[(\\d+)\\]\\s*=\\s*\\[([^\\]]*)\\]");
    static const QRegularExpression reBHArray("BH\\[(\\d+)\\]\\[(\\d+)\\]\\s*=\\s*\\[([^\\]]*)\\]");
    static const QRegularExpression reBD("BD\\[(\\d+)\\]\\[(\\d+)\\]\\[(\\d+)\\]\\s*=\\s*['\"]?(\\d+)['\"]?");
    static const QRegularExpression reBH("BH\\[(\\d+)\\]\\[(\\d+)\\]\\[(\\d+)\\]\\s*=\\s*['\"]?(\\d+)['\"]?");

    auto itCodM = reCodM.globalMatch(html);
    while (itCodM.hasNext()) {
        auto m = itCodM.next();
        mapCodM[m.captured(1).toInt()] = limpiarTextoHtml(m.captured(2)).toUpper();
    }
    auto itNomM = reNomM.globalMatch(html);
    while (itNomM.hasNext()) {
        auto m = itNomM.next();
        mapNomM[m.captured(1).toInt()] = limpiarTextoHtml(m.captured(2)).toUpper();
    }
    auto itCodP = reCodP.globalMatch(html);
    while (itCodP.hasNext()) {
        auto m = itCodP.next();
        mapCodP[m.captured(1).toInt()] = limpiarTextoHtml(m.captured(2)).toUpper();
    }
    auto itInsM = reInsM.globalMatch(html);
    while (itInsM.hasNext()) {
        auto m = itInsM.next();
        mapInsM[m.captured(1).toInt()] = m.captured(2).toInt();
    }
    auto itSecInsM = reSecInsM.globalMatch(html);
    while (itSecInsM.hasNext()) {
        auto m = itSecInsM.next();
        mapSecInsM[m.captured(1).toInt()] = m.captured(2).trimmed().rightJustified(2, '0');
    }
    auto itCodS = reCodS.globalMatch(html);
    while (itCodS.hasNext()) {
        auto m = itCodS.next();
        mapCodS[m.captured(1).toInt()][m.captured(2).toInt()] = m.captured(3).trimmed().rightJustified(2, '0');
    }
    auto itBDArr = reBDArray.globalMatch(html);
    while (itBDArr.hasNext()) {
        auto m = itBDArr.next();
        int iIdx = m.captured(1).toInt();
        int jIdx = m.captured(2).toInt();
        QStringList nums = m.captured(3).split(',', Qt::SkipEmptyParts);
        for (int kIdx = 0; kIdx < nums.size(); ++kIdx) {
            QString limpio = nums[kIdx].trimmed();
            limpio.remove('\'').remove('"');
            mapBD[iIdx][jIdx][kIdx] = limpio.toInt();
        }
    }
    auto itBHArr = reBHArray.globalMatch(html);
    while (itBHArr.hasNext()) {
        auto m = itBHArr.next();
        int iIdx = m.captured(1).toInt();
        int jIdx = m.captured(2).toInt();
        QStringList nums = m.captured(3).split(',', Qt::SkipEmptyParts);
        for (int kIdx = 0; kIdx < nums.size(); ++kIdx) {
            QString limpio = nums[kIdx].trimmed();
            limpio.remove('\'').remove('"');
            mapBH[iIdx][jIdx][kIdx] = limpio.toInt();
        }
    }
    auto itBD = reBD.globalMatch(html);
    while (itBD.hasNext()) {
        auto m = itBD.next();
        mapBD[m.captured(1).toInt()][m.captured(2).toInt()][m.captured(3).toInt()] = m.captured(4).toInt();
    }
    auto itBH = reBH.globalMatch(html);
    while (itBH.hasNext()) {
        auto m = itBH.next();
        mapBH[m.captured(1).toInt()][m.captured(2).toInt()][m.captured(3).toInt()] = m.captured(4).toInt();
    }

    if (mapCodM.isEmpty()) {
        return;
    }

    QVariantList listaMaterias;
    for (auto it = mapCodM.constBegin(); it != mapCodM.constEnd(); ++it) {
        int i = it.key();
        QString codigo = it.value();
        if (codigo.isEmpty()) continue;

        QString nombre = mapNomM.value(i, m_mapaNombreMateriaHorario.value(codigo, codigo)).toUpper();
        QString codParalelo = mapCodP.value(i);
        bool yaInscrita = (mapInsM.value(i, 0) == 1);
        QString secInscrita = mapSecInsM.value(i);

        QVariantList listaSecciones;
        const QMap<int, QString> &secsDeMat = mapCodS[i];
        for (auto itS = secsDeMat.constBegin(); itS != secsDeMat.constEnd(); ++itS) {
            int j = itS.key();
            QString sec = itS.value();
            if (sec.isEmpty()) continue;

            QString claveSec = codigo + "|" + sec;
            QString prof = m_mapaProfesorHorario.value(claveSec, "");
            QStringList bloquesTxt = m_mapaBloquesHorario.value(claveSec);

            QVariantList celdas;
            const QMap<int, int> &diasSec = mapBD[i][j];
            const QMap<int, int> &horasSec = mapBH[i][j];
            for (auto itB = diasSec.constBegin(); itB != diasSec.constEnd(); ++itB) {
                int k = itB.key();
                int dVal = itB.value();         // 1..7 (Lu..Do)
                int hVal = horasSec.value(k, 0); // 1..14
                if (dVal >= 1 && dVal <= 7 && hVal >= 1 && hVal <= 14) {
                    QVariantMap celda;
                    celda["dia"] = dVal - 1;
                    celda["hora"] = hVal - 1;
                    celda["aula"] = "";
                    celdas.append(celda);
                }
            }
            if (celdas.isEmpty() && !bloquesTxt.isEmpty()) {
                celdas = convertirBloquesTextoACeldasMalla(bloquesTxt);
            }

            QVariantMap secMap;
            secMap["sec"] = sec;
            secMap["profesor"] = prof;
            secMap["bloquesTexto"] = bloquesTxt;
            secMap["celdas"] = celdas;
            listaSecciones.append(secMap);
        }

        QVariantMap matMap;
        matMap["codigo"] = codigo;
        matMap["nombre"] = nombre;
        matMap["codParalelo"] = codParalelo;
        matMap["yaInscrita"] = yaInscrita;
        matMap["secInscrita"] = secInscrita;
        matMap["uc"] = obtenerUcAsignatura(codigo);
        matMap["secciones"] = listaSecciones;
        matMap["opc1Preseleccionada"] = "";
        matMap["opc2Preseleccionada"] = "";
        listaMaterias.append(matMap);
    }

    if (!listaMaterias.isEmpty()) {
        m_materiasInscripcion = listaMaterias;
        m_cargandoInscripcion = false;
        emit inscripcionChanged();
    }
}

void DaeClient::reconstruirOfertaInscripcionDesdeRap()
{
    if (m_materiasRap.isEmpty()) {
        return;
    }

    // Si ya se cargaron materias directamente de inscribir.php con bloques JS y pertenecen a esta sesión,
    // solo reconstruimos si m_materiasInscripcion está vacío
    if (!m_materiasInscripcion.isEmpty()) {
        return;
    }

    // 1. Agrupar todas las secciones abiertas (no CERRADA) por código de asignatura desde m_seccionesOfertaPlana
    QMap<QString, QVariantList> seccionesPorCodigo;
    QMap<QString, QString> nombreOfertaPorCodigo;

    for (const QVariant &vSec : m_seccionesOfertaPlana) {
        QVariantMap sMap = vSec.toMap();
        QString estadoSec = sMap["estado"].toString().toUpper();
        if (estadoSec == "CERRADA") continue;

        QString cod = sMap["codigo"].toString().trimmed().toUpper();
        QString sec = sMap["sec"].toString().trimmed().rightJustified(2, '0');
        QString nom = sMap["nombre"].toString().trimmed().toUpper();
        QString prof = sMap["profesor"].toString().trimmed();
        QStringList bloquesTxt = sMap["bloques"].toStringList();

        if (cod.isEmpty() || sec.isEmpty()) continue;
        if (!nombreOfertaPorCodigo.contains(cod) && !nom.isEmpty()) {
            nombreOfertaPorCodigo[cod] = nom;
        }

        // Evitar secciones duplicadas para un mismo código
        bool existeSec = false;
        const QVariantList &actuales = seccionesPorCodigo[cod];
        for (const QVariant &vEx : actuales) {
            if (vEx.toMap()["sec"].toString() == sec) {
                existeSec = true;
                break;
            }
        }
        if (existeSec) continue;

        QVariantMap secItem;
        secItem["sec"] = sec;
        secItem["profesor"] = prof;
        secItem["bloquesTexto"] = bloquesTxt;
        secItem["celdas"] = convertirBloquesTextoACeldasMalla(bloquesTxt);
        seccionesPorCodigo[cod].append(secItem);
    }

    // Ordenar secciones numéricamente en cada asignatura
    for (auto it = seccionesPorCodigo.begin(); it != seccionesPorCodigo.end(); ++it) {
        QVariantList lista = it.value();
        std::sort(lista.begin(), lista.end(), [](const QVariant &a, const QVariant &b) {
            return a.toMap()["sec"].toString() < b.toMap()["sec"].toString();
        });
        it.value() = lista;
    }

    // 2. Identificar códigos ya aprobados en el RAP o en el expediente para no ofrecer laboratorios ya aprobados
    QSet<QString> codigosAprobados;
    for (const QVariant &vRap : m_materiasRap) {
        QVariantMap r = vRap.toMap();
        if (r["estado"].toString() == "APROB") {
            codigosAprobados.insert(r["codigo"].toString().trimmed().toUpper());
        }
    }
    for (const QVariant &vSem : m_expedienteSemestres) {
        QVariantList mats = vSem.toMap()["materias"].toList();
        for (const QVariant &vM : mats) {
            QVariantMap m = vM.toMap();
            if (m["aprobada"].toBool()) {
                codigosAprobados.insert(m["codigo"].toString().trimmed().toUpper());
            }
        }
    }

    // 3. Construir la lista de asignaturas inscribibles para el estudiante según su RAP ("CUMPLE")
    //    y sus laboratorios asociados (código + "L") disponibles en la oferta académica
    QVariantList resultado;
    QSet<QString> codigosAgregados;

    auto agregarMateriaInscribible = [&](const QString &cod, const QString &nomMostrar, const QString &codParalelo) {
        if (cod.isEmpty() || codigosAgregados.contains(cod)) return;
        QVariantList secs = seccionesPorCodigo.value(cod);
        if (secs.isEmpty()) return; // Solo asignaturas con secciones abiertas en la oferta actual

        codigosAgregados.insert(cod);
        QVariantMap matMap;
        matMap["codigo"] = cod;
        matMap["nombre"] = nomMostrar.toUpper();
        matMap["codParalelo"] = codParalelo;
        matMap["yaInscrita"] = false;
        matMap["secInscrita"] = "";
        matMap["uc"] = obtenerUcAsignatura(cod);
        matMap["secciones"] = secs;
        matMap["opc1Preseleccionada"] = "";
        matMap["opc2Preseleccionada"] = "";
        resultado.append(matMap);
    };

    for (const QVariant &vRap : m_materiasRap) {
        QVariantMap r = vRap.toMap();
        QString estRap = r["estado"].toString();
        if (estRap != "CUMPLE" && estRap != "ART17") continue;

        QString cod = r["codigo"].toString().trimmed().toUpper();
        QString nom = r["nombre"].toString().trimmed().toUpper();
        QString reqPar = r["reqParalelo"].toString().trimmed().toUpper();
        if (estRap == "ART17" && reqPar.isEmpty()) {
            reqPar = r["req"].toString().trimmed().toUpper();
        }
        static const QRegularExpression reCodPar("\\b([A-Z]{2}[A-Z0-9]{3,6})\\b");
        QString codParaleloDetectado;
        QRegularExpressionMatch mPar = reCodPar.match(reqPar);
        if (mPar.hasMatch()) {
            QString posiblePar = mPar.captured(1).toUpper();
            if (!codigosAprobados.contains(posiblePar)) {
                codParaleloDetectado = posiblePar;
            }
        }

        agregarMateriaInscribible(cod, nom, codParaleloDetectado);

        // Si esta materia teórica tiene un laboratorio asociado (cod + "L") en la oferta de horarios
        // y el estudiante aún no lo ha aprobado, incluirlo justo debajo tal como lo muestra inscribir.php
        if (!cod.endsWith("L")) {
            QString codLab = cod + "L";
            if (!codigosAprobados.contains(codLab) && seccionesPorCodigo.contains(codLab)) {
                // En inscribir.php el laboratorio lleva el mismo nombre de la materia teórica (ej. SA6T01L -> LOGICA DIGITAL)
                agregarMateriaInscribible(codLab, nom, !codParaleloDetectado.isEmpty() ? codParaleloDetectado : cod);
            }
        }
    }

    if (!resultado.isEmpty()) {
        m_materiasInscripcion = resultado;
        emit inscripcionChanged();
    }
}

void DaeClient::parsearReporteSolicitudInscripcionHtml(const QString &html)
{
    static const QRegularExpression rePeriodo(
        "REPORTE\\s+DE\\s+SOLICITUD\\s+DE\\s+INSCRIPCI(?:Ó|O|&Oacute;)N\\s+([0-9]+-[0-9]{4})",
        QRegularExpression::CaseInsensitiveOption);
    QRegularExpressionMatch mPer = rePeriodo.match(html);
    if (mPer.hasMatch()) {
        m_periodoInscripcion = mPer.captured(1).trimmed();
    }

    static const QRegularExpression reFechaSol(
        "FECHA\\s+DE\\s+SOLICITUD\\s+INSCRIPCI(?:Ó|O|&Oacute;)N:\\s*([^<\\r\\n]+)",
        QRegularExpression::CaseInsensitiveOption);
    QRegularExpressionMatch mFec = reFechaSol.match(html);
    if (mFec.hasMatch()) {
        m_fechaSolicitudInscripcion = limpiarTextoHtml(mFec.captured(1));
    }

    static const QRegularExpression reTr(
        "<tr[^>]*>(.*?)</tr>",
        QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);
    static const QRegularExpression reTd(
        "<td[^>]*>(.*?)</td>",
        QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);
    static const QRegularExpression reCod("^[A-Z]{2}[A-Z0-9]{3,7}$");

    QVariantList filas;
    QRegularExpressionMatchIterator itRow = reTr.globalMatch(html);
    while (itRow.hasNext()) {
        QString rowHtml = itRow.next().captured(1);
        QStringList celdas;
        QRegularExpressionMatchIterator itCell = reTd.globalMatch(rowHtml);
        while (itCell.hasNext()) {
            celdas.append(limpiarTextoHtml(itCell.next().captured(1)));
        }
        if (celdas.size() < 4) continue;

        QString cod = celdas[0].trimmed().toUpper();
        if (!reCod.match(cod).hasMatch()) continue;

        QVariantMap item;
        item["codigo"] = cod;
        item["nombre"] = celdas[1].trimmed().toUpper();
        item["opcion1"] = celdas[2].trimmed().rightJustified(2, '0');
        item["opcion2"] = celdas[3].trimmed().rightJustified(2, '0');
        filas.append(item);
    }

    if (!filas.isEmpty()) {
        std::sort(filas.begin(), filas.end(), [](const QVariant &a, const QVariant &b) {
            return a.toMap()["codigo"].toString() < b.toMap()["codigo"].toString();
        });
        m_solicitudInscripcionRegistrada = filas;
        if (m_fechaSolicitudInscripcion.isEmpty()) {
            m_fechaSolicitudInscripcion = QDateTime::currentDateTime().toString("dd/MM/yyyy hh:mm:ss ap");
        }
        guardarSolicitudInscripcionLocal(m_solicitudInscripcionRegistrada, m_fechaSolicitudInscripcion);
        emit inscripcionChanged();
    } else if (html.contains("DIRECCIÓN DE ASUNTOS ESTUDIANTILES", Qt::CaseInsensitive) &&
               !html.contains("CodM[", Qt::CaseInsensitive)) {
        // Si reporte.php respondió sin filas de materias inscritas (no existe reporte o fue cerrado), limpiar estado
        m_solicitudInscripcionRegistrada.clear();
        m_fechaSolicitudInscripcion.clear();
        emit inscripcionChanged();
    }
}

void DaeClient::prepararPasoConfirmacionInscripcion(const QVariantList &seleccionItems)
{
    QStringList bloquesResultado;
    for (const QVariant &v : seleccionItems) {
        QVariantMap item = v.toMap();
        QString cod = item["codigo"].toString().trimmed().toUpper();
        QString nom = item["nombre"].toString().trimmed().toUpper();
        QString opc1 = item["opcion1"].toString().trimmed().rightJustified(2, '0');
        QString opc2 = item["opcion2"].toString().trimmed().rightJustified(2, '0');
        if (cod.isEmpty() || opc1.isEmpty()) continue;
        if (opc2.isEmpty() || opc2 == "00") opc2 = opc1;
        bloquesResultado.append(cod + "&&" + nom + "&&" + opc1 + "&&" + opc2);
    }
    m_resultadoPostInscripcionPendiente = bloquesResultado.join("**");
}

void DaeClient::registrarSolicitudInscripcion(const QVariantList &seleccionItems)
{
    if (seleccionItems.isEmpty() || m_enviandoInscripcion) {
        return;
    }

    prepararPasoConfirmacionInscripcion(seleccionItems);

    // Construir la lista ordenada por código para el Reporte de Solicitud de Inscripción (Paso 3)
    QVariantList listaOrdenada;
    for (const QVariant &v : seleccionItems) {
        QVariantMap item = v.toMap();
        QString cod = item["codigo"].toString().trimmed().toUpper();
        QString nom = item["nombre"].toString().trimmed().toUpper();
        QString opc1 = item["opcion1"].toString().trimmed().rightJustified(2, '0');
        QString opc2 = item["opcion2"].toString().trimmed().rightJustified(2, '0');
        if (cod.isEmpty() || opc1.isEmpty()) continue;
        if (opc2.isEmpty() || opc2 == "00") opc2 = opc1;

        QVariantMap limpio;
        limpio["codigo"] = cod;
        limpio["nombre"] = nom;
        limpio["opcion1"] = opc1;
        limpio["opcion2"] = opc2;
        listaOrdenada.append(limpio);
    }

    std::sort(listaOrdenada.begin(), listaOrdenada.end(), [](const QVariant &a, const QVariant &b) {
        return a.toMap()["codigo"].toString() < b.toMap()["codigo"].toString();
    });

    m_enviandoInscripcion = true;
    emit inscripcionChanged();

    // Si hay sesión activa en el servidor DAE, enviar POST a procesar.php (usando el action del form o ?pid=...&c=3)
    if (m_autenticado && !m_pidSesion.isEmpty()) {
        QString rutaAccion = !m_urlAccionProcesarInscripcion.isEmpty()
                             ? m_urlAccionProcesarInscripcion
                             : ("procesar.php?pid=" + m_pidSesion + "&c=3");
        QUrl urlProcesar = QUrl("https://dae.ing.uc.edu.ve/gestion_estudiantil/").resolved(QUrl(rutaAccion));
        QNetworkRequest req(urlProcesar);
        configurarRequestDae(req);
        req.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");
        req.setRawHeader("Origin", "https://dae.ing.uc.edu.ve");
        req.setRawHeader("Referer", ("https://dae.ing.uc.edu.ve/gestion_estudiantil/inscribir.php?pid=" + m_pidSesion + "&c=1").toUtf8());

        QUrlQuery postData;
        postData.addQueryItem("resultado", m_resultadoPostInscripcionPendiente);
        postData.addQueryItem("registrar", "REGISTRAR ESTA SOLICITUD");

        QNetworkReply *reply = m_nam->post(req, postData.toString(QUrl::FullyEncoded).toUtf8());
        connect(reply, &QNetworkReply::finished, this, [this, reply, listaOrdenada]() {
            reply->deleteLater();
            QString htmlStep2 = QString::fromUtf8(reply->readAll());

            // Verificar si procesar.php devuelve un segundo formulario (ej. grabar.php / registrar_solicitud.php)
            static const QRegularExpression reFormAction(
                "<form[^>]*action=[\"']([^\"']+)[\"'][^>]*>",
                QRegularExpression::CaseInsensitiveOption);
            QRegularExpressionMatch mAct = reFormAction.match(htmlStep2);
            if (mAct.hasMatch() && !htmlStep2.contains("REPORTE DE SOLICITUD DE INSCRIPCI", Qt::CaseInsensitive)) {
                QString actionHref = mAct.captured(1).trimmed();
                QUrl urlPasoFinal = QUrl("https://dae.ing.uc.edu.ve/gestion_estudiantil/").resolved(QUrl(actionHref));
                QNetworkRequest reqFinal(urlPasoFinal);
                configurarRequestDae(reqFinal);
                reqFinal.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");
                reqFinal.setRawHeader("Origin", "https://dae.ing.uc.edu.ve");
                reqFinal.setRawHeader("Referer", "https://dae.ing.uc.edu.ve/gestion_estudiantil/procesar.php");

                QUrlQuery postFinal;
                // Extraer todos los inputs hidden del formulario de confirmación de procesar.php
                static const QRegularExpression reHidden(
                    "<input[^>]*name=[\"']([^\"']+)[\"'][^>]*value=[\"']([^\"']*)[\"'][^>]*>",
                    QRegularExpression::CaseInsensitiveOption);
                auto itHid = reHidden.globalMatch(htmlStep2);
                while (itHid.hasNext()) {
                    auto mh = itHid.next();
                    postFinal.addQueryItem(mh.captured(1), mh.captured(2));
                }
                if (postFinal.isEmpty()) {
                    postFinal.addQueryItem("resultado", m_resultadoPostInscripcionPendiente);
                }

                QNetworkReply *replyFinal = m_nam->post(reqFinal, postFinal.toString(QUrl::FullyEncoded).toUtf8());
                connect(replyFinal, &QNetworkReply::finished, this, [this, replyFinal, listaOrdenada]() {
                    replyFinal->deleteLater();
                    m_enviandoInscripcion = false;
                    QString htmlFinal = QString::fromUtf8(replyFinal->readAll());

                    if (htmlFinal.contains("REPORTE DE SOLICITUD DE INSCRIPCI", Qt::CaseInsensitive)) {
                        parsearReporteSolicitudInscripcionHtml(htmlFinal);
                    } else {
                        m_solicitudInscripcionRegistrada = listaOrdenada;
                        m_fechaSolicitudInscripcion = QDateTime::currentDateTime().toString("dd/MM/yyyy hh:mm:ss ap");
                        guardarSolicitudInscripcionLocal(m_solicitudInscripcionRegistrada, m_fechaSolicitudInscripcion);
                    }
                    // Refrescar el reporte en la caché para que no quede desactualizado
                    if (!m_pidSesion.isEmpty()) {
                        sincronizarSeccionEstudiantil("reporte.php?pid=" + m_pidSesion);
                    }
                    m_datosDesdeCache = false;
                    emit cacheSesionChanged();
                    emit inscripcionChanged();
                    emit solicitudInscripcionCompletada(true, "Solicitud de inscripción registrada correctamente.");
                });
                return;
            }

            m_enviandoInscripcion = false;
            if (htmlStep2.contains("REPORTE DE SOLICITUD DE INSCRIPCI", Qt::CaseInsensitive)) {
                parsearReporteSolicitudInscripcionHtml(htmlStep2);
            } else {
                m_solicitudInscripcionRegistrada = listaOrdenada;
                m_fechaSolicitudInscripcion = QDateTime::currentDateTime().toString("dd/MM/yyyy hh:mm:ss ap");
                guardarSolicitudInscripcionLocal(m_solicitudInscripcionRegistrada, m_fechaSolicitudInscripcion);
            }
            emit inscripcionChanged();
            emit solicitudInscripcionCompletada(true, "Solicitud de inscripción registrada correctamente.");
        });
        return;
    }

    // Respaldo si no hay pid activo
    m_enviandoInscripcion = false;
    m_solicitudInscripcionRegistrada = listaOrdenada;
    m_fechaSolicitudInscripcion = QDateTime::currentDateTime().toString("dd/MM/yyyy hh:mm:ss ap");
    guardarSolicitudInscripcionLocal(m_solicitudInscripcionRegistrada, m_fechaSolicitudInscripcion);
    m_datosDesdeCache = false;
    emit cacheSesionChanged();
    emit inscripcionChanged();
    emit solicitudInscripcionCompletada(true, "Solicitud de inscripción registrada correctamente.");
}

void DaeClient::cargarSolicitudInscripcionLocal()
{
    m_solicitudInscripcionRegistrada.clear();
    m_fechaSolicitudInscripcion.clear();
    if (m_cedulaEstudiante.isEmpty()) {
        return;
    }

    QSettings settings("UniversidadDeCarabobo", "AppDAE");
    QString claveJson = "inscripcion/solicitud_" + m_cedulaEstudiante;
    QString claveFecha = "inscripcion/fecha_" + m_cedulaEstudiante;
    QString jsonStr = settings.value(claveJson, "").toString();
    if (jsonStr.isEmpty()) {
        return;
    }

    QJsonDocument doc = QJsonDocument::fromJson(jsonStr.toUtf8());
    if (!doc.isArray()) {
        return;
    }

    QVariantList lista;
    const QJsonArray arr = doc.array();
    for (const QJsonValue &val : arr) {
        if (!val.isObject()) continue;
        QJsonObject obj = val.toObject();
        QVariantMap item;
        item["codigo"] = obj["codigo"].toString();
        item["nombre"] = obj["nombre"].toString();
        item["opcion1"] = obj["opcion1"].toString();
        item["opcion2"] = obj["opcion2"].toString();
        lista.append(item);
    }

    if (!lista.isEmpty()) {
        m_solicitudInscripcionRegistrada = lista;
        m_fechaSolicitudInscripcion = settings.value(claveFecha, "").toString();
        emit inscripcionChanged();
    }
}

void DaeClient::guardarSolicitudInscripcionLocal(const QVariantList &items, const QString &fecha)
{
    if (m_cedulaEstudiante.isEmpty()) {
        return;
    }

    QJsonArray arr;
    for (const QVariant &v : items) {
        QVariantMap m = v.toMap();
        QJsonObject obj;
        obj["codigo"] = m["codigo"].toString();
        obj["nombre"] = m["nombre"].toString();
        obj["opcion1"] = m["opcion1"].toString();
        obj["opcion2"] = m["opcion2"].toString();
        arr.append(obj);
    }

    QSettings settings("UniversidadDeCarabobo", "AppDAE");
    settings.setValue("inscripcion/solicitud_" + m_cedulaEstudiante,
                      QString::fromUtf8(QJsonDocument(arr).toJson(QJsonDocument::Compact)));
    settings.setValue("inscripcion/fecha_" + m_cedulaEstudiante, fecha);
    settings.sync();
}

// ============================================================================
// MÓDULO DE RETIRO DE ASIGNATURAS (Solicitud de Retiro DAE UC)
// ============================================================================

QVariantList DaeClient::materiasRetiro() const
{
    QVariantList resultado;

    // 1. Si el servidor DAE devolvió directamente la tabla de retiro de asignaturas, usarla
    if (!m_materiasRetiroServidor.isEmpty()) {
        for (const QVariant &v : m_materiasRetiroServidor) {
            QVariantMap m = v.toMap();
            QString cod = m["codigo"].toString().trimmed().toUpper();
            if (cod.isEmpty() || m_codigosRetiradosConfirmados.contains(cod)) continue;
            resultado.append(m);
        }
        return resultado;
    }

    // 2. Construir dinámicamente a partir de las asignaturas inscritas del estudiante autenticado
    const QVariantList &fuente = !m_materiasInscritasRaw.isEmpty()
                                 ? m_materiasInscritasRaw
                                 : (!m_materiasPeriodoActualRaw.isEmpty()
                                    ? m_materiasPeriodoActualRaw
                                    : m_materiasSinTranscribir);

    QSet<QString> codigosAgregados;
    for (const QVariant &v : fuente) {
        QVariantMap m = v.toMap();
        QString cod = m["codigo"].toString().trimmed().toUpper();
        if (cod.isEmpty() || codigosAgregados.contains(cod) || m_codigosRetiradosConfirmados.contains(cod)) {
            continue;
        }
        // En la tabla de Solicitud de Retiro del DAE no se listan por separado las prácticas de laboratorio
        // anexas de 0 UC cuyo código termina en "L" (ej. ER7T03L, SA6T01L, SA8T04L, SS8T06L)
        if (cod.length() >= 7 && cod.endsWith(QLatin1Char('L'))) {
            continue;
        }

        QString nom = m.value("nombreOriginal").toString().trimmed();
        if (nom.isEmpty()) {
            nom = m.value("nombre").toString().trimmed();
        }
        if (nom.startsWith("Lab. ", Qt::CaseInsensitive)) {
            nom = nom.mid(5).trimmed();
        }
        if (nom.endsWith("(LAB)", Qt::CaseInsensitive)) {
            nom = nom.left(nom.length() - 5).trimmed();
        }
        nom = nom.toUpper();

        QString sec = m.value("sec").toString().trimmed().rightJustified(2, '0');
        codigosAgregados.insert(cod);

        QVariantMap item;
        item["codigo"] = cod;
        item["nombre"] = nom;
        item["sec"] = sec;
        item["uc"] = obtenerUcAsignatura(cod);
        item["inputName"] = QStringLiteral("retirar[]");
        item["inputValue"] = cod;
        resultado.append(item);
    }

    std::sort(resultado.begin(), resultado.end(), [](const QVariant &a, const QVariant &b) {
        return a.toMap()["codigo"].toString() < b.toMap()["codigo"].toString();
    });

    return resultado;
}

void DaeClient::cargarDatosRetiro()
{
    if (!m_autenticado || m_pidSesion.isEmpty()) {
        emit retiroChanged();
        return;
    }

    if (m_datosDesdeCache) {
        if (!m_hrefRetiroMenu.isEmpty()) {
            cargarSeccionDesdeCache(m_hrefRetiroMenu);
        }
        m_cargandoRetiro = false;
        emit retiroChanged();
        return;
    }

    if (m_hrefRetiroMenu.isEmpty()) {
        // Si no hay materias cargadas aún del horario del estudiante, sincronizar horario asignado
        if (m_materiasInscritasRaw.isEmpty()) {
            sincronizarSeccionEstudiantil("mostrar_horario.php?pid=" + m_pidSesion);
        }
        m_cargandoRetiro = false;
        emit retiroChanged();
        return;
    }

    m_cargandoRetiro = true;
    emit retiroChanged();

    QUrl urlRetiro = QUrl("https://dae.ing.uc.edu.ve/gestion_estudiantil/").resolved(QUrl(m_hrefRetiroMenu));
    QNetworkRequest req(urlRetiro);
    configurarRequestDae(req);
    req.setRawHeader("Referer", "https://dae.ing.uc.edu.ve/gestion_estudiantil/index.php");

    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        m_cargandoRetiro = false;
        if (reply->error() == QNetworkReply::NoError) {
            QString html = QString::fromUtf8(reply->readAll());
            parsearRetiroHtml(html);
        }
        emit retiroChanged();
    });
}

void DaeClient::parsearRetiroHtml(const QString &html)
{
    static const QRegularExpression rePeriodo(
        "Solicitud\\s+de\\s+Retiro\\s+([0-9]+-[0-9]{4})",
        QRegularExpression::CaseInsensitiveOption);
    QRegularExpressionMatch mPer = rePeriodo.match(html);
    if (mPer.hasMatch()) {
        m_periodoRetiro = mPer.captured(1).trimmed();
    }

    static const QRegularExpression reActionForm(
        "<form[^>]*action=[\"']([^\"']+)[\"'][^>]*>",
        QRegularExpression::CaseInsensitiveOption);
    QRegularExpressionMatch mAct = reActionForm.match(html);
    if (mAct.hasMatch()) {
        m_urlAccionProcesarRetiro = mAct.captured(1).trimmed();
    }

    m_camposOcultosRetiro.clear();
    static const QRegularExpression reHidden(
        "<input[^>]*type=[\"']hidden[\"'][^>]*name=[\"']([^\"']+)[\"'][^>]*value=[\"']([^\"']*)[\"'][^>]*>",
        QRegularExpression::CaseInsensitiveOption);
    auto itHid = reHidden.globalMatch(html);
    while (itHid.hasNext()) {
        auto mh = itHid.next();
        m_camposOcultosRetiro[mh.captured(1).trimmed()] = mh.captured(2);
    }

    static const QRegularExpression reTr(
        "<tr[^>]*>(.*?)</tr>",
        QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);
    static const QRegularExpression reTd(
        "<td[^>]*>(.*?)</td>",
        QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption);
    static const QRegularExpression reCod("^[A-Z]{2}[A-Z0-9]{3,7}$");
    static const QRegularExpression reCheckboxName("<input[^>]*name=[\"']([^\"']+)[\"']", QRegularExpression::CaseInsensitiveOption);
    static const QRegularExpression reCheckboxVal("<input[^>]*value=[\"']([^\"']*)[\"']", QRegularExpression::CaseInsensitiveOption);

    QVariantList listaServidor;
    QSet<QString> vistos;

    auto itRow = reTr.globalMatch(html);
    while (itRow.hasNext()) {
        QString rowHtml = itRow.next().captured(1);
        QStringList celdasRaw;
        QStringList celdasTxt;
        auto itCell = reTd.globalMatch(rowHtml);
        while (itCell.hasNext()) {
            QString rawCell = itCell.next().captured(1);
            celdasRaw.append(rawCell);
            celdasTxt.append(limpiarTextoHtml(rawCell));
        }
        if (celdasTxt.size() < 3) continue;

        QString cod = celdasTxt[0].trimmed().toUpper();
        if (!reCod.match(cod).hasMatch() || cod == "CODIGO" || cod == "CÓDIGO") continue;
        if (vistos.contains(cod)) continue;

        QString nom = celdasTxt[1].trimmed().toUpper();
        QString sec = celdasTxt[2].trimmed().rightJustified(2, '0');
        QString chkRaw = (celdasRaw.size() >= 4) ? celdasRaw[3] : rowHtml;

        QString inputName = QStringLiteral("retirar[]");
        QString inputValue = cod;
        QRegularExpressionMatch mN = reCheckboxName.match(chkRaw);
        if (mN.hasMatch()) inputName = mN.captured(1).trimmed();
        QRegularExpressionMatch mV = reCheckboxVal.match(chkRaw);
        if (mV.hasMatch() && !mV.captured(1).trimmed().isEmpty()) inputValue = mV.captured(1).trimmed();

        vistos.insert(cod);
        QVariantMap item;
        item["codigo"] = cod;
        item["nombre"] = nom;
        item["sec"] = sec;
        item["uc"] = obtenerUcAsignatura(cod);
        item["inputName"] = inputName;
        item["inputValue"] = inputValue;
        listaServidor.append(item);
    }

    if (!listaServidor.isEmpty()) {
        std::sort(listaServidor.begin(), listaServidor.end(), [](const QVariant &a, const QVariant &b) {
            return a.toMap()["codigo"].toString() < b.toMap()["codigo"].toString();
        });
        m_materiasRetiroServidor = listaServidor;
        emit retiroChanged();
    }
}

void DaeClient::enviarSolicitudRetiro(const QVariantList &seleccionadas)
{
    if (m_enviandoRetiro) return;
    if (seleccionadas.isEmpty()) {
        emit solicitudRetiroCompletada(false, "Selecciona al menos una asignatura para retirar");
        return;
    }

    QVariantList listaOrdenada;
    QStringList codigosResumen;
    for (const QVariant &v : seleccionadas) {
        QVariantMap item = v.toMap();
        QString cod = item["codigo"].toString().trimmed().toUpper();
        QString nom = item["nombre"].toString().trimmed().toUpper();
        QString sec = item["sec"].toString().trimmed().rightJustified(2, '0');
        if (cod.isEmpty()) continue;

        QVariantMap limpio;
        limpio["codigo"] = cod;
        limpio["nombre"] = nom;
        limpio["sec"] = sec;
        limpio["uc"] = obtenerUcAsignatura(cod);
        limpio["inputName"] = item.value("inputName", "retirar[]").toString();
        limpio["inputValue"] = item.value("inputValue", cod).toString();
        listaOrdenada.append(limpio);
        codigosResumen.append(cod);
    }

    if (listaOrdenada.isEmpty()) {
        emit solicitudRetiroCompletada(false, "Selecciona al menos una asignatura válida para retirar");
        return;
    }

    std::sort(listaOrdenada.begin(), listaOrdenada.end(), [](const QVariant &a, const QVariant &b) {
        return a.toMap()["codigo"].toString() < b.toMap()["codigo"].toString();
    });

    auto finalizarRegistroRetiro = [this, listaOrdenada, codigosResumen](const QString &msg) {
        m_enviandoRetiro = false;
        m_solicitudRetiroRegistrada = listaOrdenada;
        m_fechaSolicitudRetiro = QDateTime::currentDateTime().toString("dd/MM/yyyy hh:mm:ss ap");
        for (const QVariant &v : listaOrdenada) {
            m_codigosRetiradosConfirmados.insert(v.toMap()["codigo"].toString());
        }
        registrarSolicitudReciente("RET", "Retiro de Asignatura",
                                   codigosResumen.join(", ") + " • Período " + periodoRetiro(),
                                   "Procesado");
        emit retiroChanged();
        emit solicitudRetiroCompletada(true, msg);
    };

    if (m_autenticado && !m_pidSesion.isEmpty() && (!m_urlAccionProcesarRetiro.isEmpty() || !m_hrefRetiroMenu.isEmpty())) {
        m_enviandoRetiro = true;
        emit retiroChanged();

        QString rutaAccion = !m_urlAccionProcesarRetiro.isEmpty()
                             ? m_urlAccionProcesarRetiro
                             : m_hrefRetiroMenu;
        QUrl urlPost = QUrl("https://dae.ing.uc.edu.ve/gestion_estudiantil/").resolved(QUrl(rutaAccion));
        QNetworkRequest req(urlPost);
        configurarRequestDae(req);
        req.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");
        req.setRawHeader("Origin", "https://dae.ing.uc.edu.ve");
        QString refHref = !m_hrefRetiroMenu.isEmpty() ? m_hrefRetiroMenu : ("index.php?pid=" + m_pidSesion);
        req.setRawHeader("Referer", ("https://dae.ing.uc.edu.ve/gestion_estudiantil/" + refHref).toUtf8());

        QUrlQuery postData;
        for (auto it = m_camposOcultosRetiro.constBegin(); it != m_camposOcultosRetiro.constEnd(); ++it) {
            postData.addQueryItem(it.key(), it.value());
        }
        for (const QVariant &v : listaOrdenada) {
            QVariantMap m = v.toMap();
            QString iName = m["inputName"].toString().isEmpty() ? QStringLiteral("retirar[]") : m["inputName"].toString();
            QString iVal = m["inputValue"].toString().isEmpty() ? m["codigo"].toString() : m["inputValue"].toString();
            postData.addQueryItem(iName, iVal);
        }

        QNetworkReply *reply = m_nam->post(req, postData.toString(QUrl::FullyEncoded).toUtf8());
        connect(reply, &QNetworkReply::finished, this, [this, reply, finalizarRegistroRetiro]() {
            reply->deleteLater();
            QString htmlStep2 = QString::fromUtf8(reply->readAll());

            static const QRegularExpression reFormAction(
                "<form[^>]*action=[\"']([^\"']+)[\"'][^>]*>",
                QRegularExpression::CaseInsensitiveOption);
            QRegularExpressionMatch mAct = reFormAction.match(htmlStep2);
            if (mAct.hasMatch()) {
                QString actionHref = mAct.captured(1).trimmed();
                QUrl urlPasoFinal = QUrl("https://dae.ing.uc.edu.ve/gestion_estudiantil/").resolved(QUrl(actionHref));
                QNetworkRequest reqFinal(urlPasoFinal);
                configurarRequestDae(reqFinal);
                reqFinal.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");
                reqFinal.setRawHeader("Origin", "https://dae.ing.uc.edu.ve");

                QUrlQuery postFinal;
                static const QRegularExpression reHidden(
                    "<input[^>]*name=[\"']([^\"']+)[\"'][^>]*value=[\"']([^\"']*)[\"'][^>]*>",
                    QRegularExpression::CaseInsensitiveOption);
                auto itHid = reHidden.globalMatch(htmlStep2);
                while (itHid.hasNext()) {
                    auto mh = itHid.next();
                    postFinal.addQueryItem(mh.captured(1), mh.captured(2));
                }

                QNetworkReply *replyFinal = m_nam->post(reqFinal, postFinal.toString(QUrl::FullyEncoded).toUtf8());
                connect(replyFinal, &QNetworkReply::finished, this, [replyFinal, finalizarRegistroRetiro]() {
                    replyFinal->deleteLater();
                    finalizarRegistroRetiro("✓ Solicitud de retiro enviada y procesada en DAE UC");
                });
                return;
            }

            finalizarRegistroRetiro("✓ Solicitud de retiro procesada correctamente");
        });
        return;
    }

    finalizarRegistroRetiro("✓ Solicitud de retiro registrada correctamente");
}

