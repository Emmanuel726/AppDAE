#ifndef DAECLIENT_H
#define DAECLIENT_H

#include <QObject>
#include <QString>
#include <QSet>
#include <QVariantList>
#include <QVariantMap>
#include <QNetworkAccessManager>
#include <QNetworkCookieJar>
#include <QNetworkCookie>
#include <QNetworkReply>

// QNetworkCookieJar deja allCookies()/setAllCookies() como protegidos. Esta
// subclase los expone para poder guardar y restaurar la sesión en la caché.
class DaeCookieJar : public QNetworkCookieJar
{
public:
    explicit DaeCookieJar(QObject *parent = nullptr) : QNetworkCookieJar(parent) {}
    QList<QNetworkCookie> cookies() const { return allCookies(); }
    void setCookies(const QList<QNetworkCookie> &lista) { setAllCookies(lista); }
};

class DaeClient : public QObject
{
    Q_OBJECT

    // Estado de Autenticación y Sesión
    Q_PROPERTY(bool cargandoLogin READ cargandoLogin NOTIFY cargandoLoginChanged)
    Q_PROPERTY(bool autenticado READ autenticado NOTIFY autenticadoChanged)
    Q_PROPERTY(QString mensajeError READ mensajeError NOTIFY mensajeErrorChanged)
    // Caché local de la sesión: evita repetir todas las consultas al DAE
    Q_PROPERTY(bool datosDesdeCache READ datosDesdeCache NOTIFY cacheSesionChanged)
    Q_PROPERTY(QString actualizadoHace READ actualizadoHace NOTIFY cacheSesionChanged)
    Q_PROPERTY(bool sincronizandoServidor READ sincronizandoServidor NOTIFY cacheSesionChanged)

    // Datos del Estudiante Autenticado
    Q_PROPERTY(QString cedulaEstudiante READ cedulaEstudiante NOTIFY datosEstudianteChanged)
    Q_PROPERTY(QString cedulaFormateada READ cedulaFormateada NOTIFY datosEstudianteChanged)
    Q_PROPERTY(QString nombreEstudiante READ nombreEstudiante NOTIFY datosEstudianteChanged)
    Q_PROPERTY(QString primerNombre READ primerNombre NOTIFY datosEstudianteChanged)
    Q_PROPERTY(QString segundoNombre READ segundoNombre NOTIFY datosEstudianteChanged)
    Q_PROPERTY(QString primerApellido READ primerApellido NOTIFY datosEstudianteChanged)
    Q_PROPERTY(QString segundoApellido READ segundoApellido NOTIFY datosEstudianteChanged)
    Q_PROPERTY(QString inicialesEstudiante READ inicialesEstudiante NOTIFY datosEstudianteChanged)
    Q_PROPERTY(QString escuelaEstudiante READ escuelaEstudiante NOTIFY datosEstudianteChanged)
    Q_PROPERTY(QString escuelaCorta READ escuelaCorta NOTIFY datosEstudianteChanged)
    Q_PROPERTY(int escuelaIndexEstudiante READ escuelaIndexEstudiante NOTIFY datosEstudianteChanged)
    Q_PROPERTY(QString codigoEscuelaActual READ codigoEscuelaActual NOTIFY datosEstudianteChanged)
    Q_PROPERTY(QVariantList escuelasDestinoDisponibles READ escuelasDestinoDisponibles NOTIFY datosEstudianteChanged)
    Q_PROPERTY(QString fechaLimiteCambioEscuela READ fechaLimiteCambioEscuela NOTIFY datosEstudianteChanged)
    Q_PROPERTY(bool enviandoCambioEscuela READ enviandoCambioEscuela NOTIFY cambioEscuelaChanged)
    Q_PROPERTY(QString correoEstudiante READ correoEstudiante NOTIFY datosEstudianteChanged)
    Q_PROPERTY(QString correoAlternativo READ correoAlternativo NOTIFY datosEstudianteChanged)
    Q_PROPERTY(QString telefonoFijo READ telefonoFijo NOTIFY datosEstudianteChanged)
    Q_PROPERTY(QString telefonoEstudiante READ telefonoEstudiante NOTIFY datosEstudianteChanged)
    Q_PROPERTY(QString fechaNacimiento READ fechaNacimiento NOTIFY datosEstudianteChanged)
    Q_PROPERTY(QString sexoEstudiante READ sexoEstudiante NOTIFY datosEstudianteChanged)
    Q_PROPERTY(QString dirEstado READ dirEstado NOTIFY datosEstudianteChanged)
    Q_PROPERTY(QString dirMunicipio READ dirMunicipio NOTIFY datosEstudianteChanged)
    Q_PROPERTY(QString dirParroquia READ dirParroquia NOTIFY datosEstudianteChanged)
    Q_PROPERTY(QString dirDetalle READ dirDetalle NOTIFY datosEstudianteChanged)
    Q_PROPERTY(QString opsuEstadoCivil READ opsuEstadoCivil NOTIFY datosEstudianteChanged)
    Q_PROPERTY(QString opsuEtnia READ opsuEtnia NOTIFY datosEstudianteChanged)
    Q_PROPERTY(QString opsuDiscapacidad READ opsuDiscapacidad NOTIFY datosEstudianteChanged)
    Q_PROPERTY(QString opsuManoAgil READ opsuManoAgil NOTIFY datosEstudianteChanged)
    Q_PROPERTY(QString periodoActual READ periodoActual NOTIFY datosEstudianteChanged)
    Q_PROPERTY(QVariantList enlacesMenuInterno READ enlacesMenuInterno NOTIFY enlacesMenuInternoChanged)

    // Métricas Académicas del Estudiante Autenticado
    Q_PROPERTY(QString promedioPonderadoEntero READ promedioPonderadoEntero NOTIFY expedienteChanged)
    Q_PROPERTY(QString promedioPonderadoDecimal READ promedioPonderadoDecimal NOTIFY expedienteChanged)
    Q_PROPERTY(QString promedioAritmeticoEntero READ promedioAritmeticoEntero NOTIFY expedienteChanged)
    Q_PROPERTY(QString promedioAritmeticoDecimal READ promedioAritmeticoDecimal NOTIFY expedienteChanged)
    Q_PROPERTY(int ucInscritas READ ucInscritas NOTIFY horarioAsignadoChanged)
    Q_PROPERTY(int ucAprobadasCarrera READ ucAprobadasCarrera NOTIFY expedienteChanged)
    Q_PROPERTY(int ucAcumuladas READ ucAcumuladas NOTIFY expedienteChanged)

    // Preferencias Persistentes de Apariencia, Tema del Sistema y Biometría (QSettings)
    Q_PROPERTY(int temaSeleccionado READ temaSeleccionado WRITE setTemaSeleccionado NOTIFY aparienciaChanged)
    Q_PROPERTY(bool sistemaEsClaro READ sistemaEsClaro NOTIFY aparienciaChanged)
    Q_PROPERTY(int paletaAuroraIndex READ paletaAuroraIndex WRITE setPaletaAuroraIndex NOTIFY aparienciaChanged)
    Q_PROPERTY(bool animacionAuroraActiva READ animacionAuroraActiva WRITE setAnimacionAuroraActiva NOTIFY aparienciaChanged)
    Q_PROPERTY(QString urlFotoPerfil READ urlFotoPerfil WRITE setUrlFotoPerfil NOTIFY aparienciaChanged)
    Q_PROPERTY(bool biometriaActiva READ biometriaActiva WRITE setBiometriaActiva NOTIFY biometriaChanged)
    Q_PROPERTY(bool tieneCredencialesBiometricas READ tieneCredencialesBiometricas NOTIFY biometriaChanged)
    Q_PROPERTY(QString cedulaBiometrica READ cedulaBiometrica NOTIFY biometriaChanged)
    Q_PROPERTY(QString cedulaBiometricaFormateada READ cedulaBiometricaFormateada NOTIFY biometriaChanged)
    Q_PROPERTY(bool autenticandoBiometria READ autenticandoBiometria NOTIFY biometriaChanged)
    Q_PROPERTY(bool descargoAceptado READ descargoAceptado NOTIFY aparienciaChanged)

    // Oferta de Horarios en Vivo (https://dae.ing.uc.edu.ve/horarios/)
    Q_PROPERTY(bool cargandoHorarios READ cargandoHorarios NOTIFY cargandoHorariosChanged)
    Q_PROPERTY(QString fechaActualizacionHorarios READ fechaActualizacionHorarios NOTIFY horariosOfertaChanged)
    Q_PROPERTY(QString periodoOfertaHorarios READ periodoOfertaHorarios NOTIFY horariosOfertaChanged)
    Q_PROPERTY(QVariantList horariosPensum2025 READ horariosPensum2025 NOTIFY horariosOfertaChanged)
    Q_PROPERTY(QVariantList horariosPensum1997 READ horariosPensum1997 NOTIFY horariosOfertaChanged)
    Q_PROPERTY(int totalSeccionesOferta READ totalSeccionesOferta NOTIFY horariosOfertaChanged)

    // Pensum de Estudios en Vivo (https://dae.ing.uc.edu.ve/pensa/)
    Q_PROPERTY(bool cargandoPensum READ cargandoPensum NOTIFY cargandoPensumChanged)
    Q_PROPERTY(QVariantList semestresPensum READ semestresPensum NOTIFY pensumChanged)
    Q_PROPERTY(QVariantList preguntasFaqPensum READ preguntasFaqPensum NOTIFY faqPensumChanged)

    // Calendarios Oficiales en PDF (https://dae.ing.uc.edu.ve/portal/)
    Q_PROPERTY(bool descargandoPdf READ descargandoPdf NOTIFY descargandoPdfChanged)
    Q_PROPERTY(QVariantList calendariosOficiales READ calendariosOficiales NOTIFY calendariosChanged)

    // Datos Académicos del Estudiante (RAP, Expediente, Transcritas, Horario Asignado, Inscripción)
    Q_PROPERTY(QVariantList materiasRap READ materiasRap NOTIFY rapChanged)
    Q_PROPERTY(QVariantList expedienteSemestres READ expedienteSemestres NOTIFY expedienteChanged)
    Q_PROPERTY(QVariantList curvaProgresoExpediente READ curvaProgresoExpediente NOTIFY expedienteChanged)
    Q_PROPERTY(QVariantList notasTranscritas READ notasTranscritas NOTIFY transcritasChanged)
    Q_PROPERTY(QVariantList materiasSinTranscribir READ materiasSinTranscribir NOTIFY transcritasChanged)
    Q_PROPERTY(QVariantList diasHorarioAsignado READ diasHorarioAsignado NOTIFY horarioAsignadoChanged)
    Q_PROPERTY(QVariantList mallaHorarioAsignado READ mallaHorarioAsignado NOTIFY horarioAsignadoChanged)
    Q_PROPERTY(QVariantList clasesPorDiaDashboard READ clasesPorDiaDashboard NOTIFY horarioAsignadoChanged)
    Q_PROPERTY(QVariantList materiasSinBloqueHorario READ materiasSinBloqueHorario NOTIFY horarioAsignadoChanged)
    Q_PROPERTY(int totalBloquesHorario READ totalBloquesHorario NOTIFY horarioAsignadoChanged)
    Q_PROPERTY(int totalMateriasHorario READ totalMateriasHorario NOTIFY horarioAsignadoChanged)

    // Solicitud de Inscripción en Vivo (inscribir.php / procesar.php / reporte.php)
    Q_PROPERTY(QVariantList materiasInscripcion READ materiasInscripcion NOTIFY inscripcionChanged)
    Q_PROPERTY(QVariantList solicitudInscripcionRegistrada READ solicitudInscripcionRegistrada NOTIFY inscripcionChanged)
    Q_PROPERTY(QString fechaSolicitudInscripcion READ fechaSolicitudInscripcion NOTIFY inscripcionChanged)
    Q_PROPERTY(QString periodoInscripcion READ periodoInscripcion NOTIFY inscripcionChanged)

    // Solicitudes recientes que el estudiante ha hecho en la app (máximo 3)
    Q_PROPERTY(QVariantList solicitudesRecientes READ solicitudesRecientes NOTIFY solicitudesRecientesChanged)

    // Estado real del teclado en pantalla (Android/IME) y márgenes fijos del sistema (dp)
    Q_PROPERTY(bool tecladoVisible READ tecladoVisible NOTIFY tecladoVisibleChanged)
    Q_PROPERTY(double tecladoAltura READ tecladoAltura NOTIFY tecladoVisibleChanged)
    Q_PROPERTY(double insetSuperior READ insetSuperior CONSTANT)
    Q_PROPERTY(double insetInferior READ insetInferior CONSTANT)

    // Recordatorios: tareas y examenes programados por el estudiante
    Q_PROPERTY(QVariantList recordatorios READ recordatorios NOTIFY recordatoriosChanged)
    Q_PROPERTY(int recordatoriosPendientes READ recordatoriosPendientes NOTIFY recordatoriosChanged)
    Q_PROPERTY(bool permisoNotificacionesActivo READ permisoNotificacionesActivo WRITE setPermisoNotificacionesActivo NOTIFY recordatoriosChanged)
    // Materias que cursa el estudiante, para elegirlas al crear un recordatorio
    Q_PROPERTY(QVariantList materiasParaRecordatorio READ materiasParaRecordatorio NOTIFY materiasRecordatorioChanged)
    Q_PROPERTY(QString fechaLimiteInscripcion READ fechaLimiteInscripcion NOTIFY inscripcionChanged)
    Q_PROPERTY(bool inscripcionDisponible READ inscripcionDisponible NOTIFY inscripcionChanged)
    Q_PROPERTY(bool reporteInscripcionDisponible READ reporteInscripcionDisponible NOTIFY inscripcionChanged)
    Q_PROPERTY(bool cargandoInscripcion READ cargandoInscripcion NOTIFY inscripcionChanged)
    Q_PROPERTY(bool enviandoInscripcion READ enviandoInscripcion NOTIFY inscripcionChanged)

    // Solicitud de Retiro de Asignaturas (retirar.php / horario asignado del estudiante)
    Q_PROPERTY(QVariantList materiasRetiro READ materiasRetiro NOTIFY retiroChanged)
    Q_PROPERTY(QVariantList solicitudRetiroRegistrada READ solicitudRetiroRegistrada NOTIFY retiroChanged)
    Q_PROPERTY(QString fechaSolicitudRetiro READ fechaSolicitudRetiro NOTIFY retiroChanged)
    Q_PROPERTY(QString periodoRetiro READ periodoRetiro NOTIFY retiroChanged)
    Q_PROPERTY(QString fechaLimiteRetiro READ fechaLimiteRetiro NOTIFY retiroChanged)
    Q_PROPERTY(bool retiroDisponible READ retiroDisponible NOTIFY retiroChanged)
    Q_PROPERTY(bool cargandoRetiro READ cargandoRetiro NOTIFY retiroChanged)
    Q_PROPERTY(bool enviandoRetiro READ enviandoRetiro NOTIFY retiroChanged)

public:
    explicit DaeClient(QObject *parent = nullptr);

    bool cargandoLogin() const { return m_cargandoLogin; }
    bool autenticado() const { return m_autenticado; }
    QString mensajeError() const { return m_mensajeError; }
    bool datosDesdeCache() const { return m_datosDesdeCache; }
    QString actualizadoHace() const;
    bool sincronizandoServidor() const { return m_sincronizandoServidor; }

    QString cedulaEstudiante() const { return m_cedulaEstudiante; }
    QString cedulaFormateada() const;
    QString nombreEstudiante() const { return m_nombreEstudiante; }
    QString primerNombre() const { return m_primerNombre; }
    QString segundoNombre() const { return m_segundoNombre; }
    QString primerApellido() const { return m_primerApellido; }
    QString segundoApellido() const { return m_segundoApellido; }
    QString inicialesEstudiante() const { return m_inicialesEstudiante; }
    QString escuelaEstudiante() const { return m_escuelaEstudiante; }
    QString escuelaCorta() const;
    int escuelaIndexEstudiante() const;
    QString codigoEscuelaActual() const;
    QVariantList escuelasDestinoDisponibles() const;
    QString fechaLimiteCambioEscuela() const { return m_fechaLimiteCambioEscuela; }
    bool enviandoCambioEscuela() const { return m_enviandoCambioEscuela; }
    QString correoEstudiante() const { return m_correoEstudiante; }
    QString correoAlternativo() const { return m_correoAlternativo; }
    QString telefonoFijo() const { return m_telefonoFijo; }
    QString telefonoEstudiante() const { return m_telefonoEstudiante; }
    QString fechaNacimiento() const { return m_fechaNacimiento; }
    QString sexoEstudiante() const { return m_sexoEstudiante; }
    QString dirEstado() const { return m_dirEstado; }
    QString dirMunicipio() const { return m_dirMunicipio; }
    QString dirParroquia() const { return m_dirParroquia; }
    QString dirDetalle() const { return m_dirDetalle; }
    QString opsuEstadoCivil() const { return m_opsuEstadoCivil; }
    QString opsuEtnia() const { return m_opsuEtnia; }
    QString opsuDiscapacidad() const { return m_opsuDiscapacidad; }
    QString opsuManoAgil() const { return m_opsuManoAgil; }
    QString periodoActual() const { return m_periodoActual; }
    QVariantList enlacesMenuInterno() const { return m_enlacesMenuInterno; }

    QString promedioPonderadoEntero() const { return m_promedioPonderadoEntero; }
    QString promedioPonderadoDecimal() const { return m_promedioPonderadoDecimal; }
    QString promedioAritmeticoEntero() const { return m_promedioAritmeticoEntero; }
    QString promedioAritmeticoDecimal() const { return m_promedioAritmeticoDecimal; }
    int ucInscritas() const { return m_ucInscritas; }
    int ucAprobadasCarrera() const { return m_ucAprobadasCarrera; }
    int ucAcumuladas() const { return m_ucAprobadasCarrera; }

    int temaSeleccionado() const { return m_temaSeleccionado; }
    void setTemaSeleccionado(int valor);
    bool sistemaEsClaro() const;
    int paletaAuroraIndex() const { return m_paletaAuroraIndex; }
    void setPaletaAuroraIndex(int valor);
    bool animacionAuroraActiva() const { return m_animacionAuroraActiva; }
    void setAnimacionAuroraActiva(bool valor);
    QString urlFotoPerfil() const { return m_urlFotoPerfil; }
    void setUrlFotoPerfil(const QString &valor);
    bool biometriaActiva() const { return m_biometriaActiva; }
    void setBiometriaActiva(bool valor);
    bool tieneCredencialesBiometricas() const { return m_biometriaActiva && !m_cedulaBiometrica.isEmpty() && !m_claveBiometrica.isEmpty(); }
    QString cedulaBiometrica() const { return m_cedulaBiometrica; }
    QString cedulaBiometricaFormateada() const;
    bool autenticandoBiometria() const { return m_autenticandoBiometria; }
    bool descargoAceptado() const { return m_descargoAceptado; }
    int obtenerUcAsignatura(const QString &codigo) const;

    bool cargandoHorarios() const { return m_cargandoHorarios; }
    QString fechaActualizacionHorarios() const { return m_fechaActualizacionHorarios; }
    // Período de la oferta de horarios: el más reciente entre el título de la página de horarios
    // (que DAE a veces no actualiza) y el período publicado en el menú estudiantil
    QString periodoOfertaHorarios() const {
        auto valor = [](const QString &p) -> int {
            QStringList partes = p.split('-');
            if (partes.size() != 2) return 0;
            return partes[1].toInt() * 10 + partes[0].toInt();
        };
        QString mejor = m_periodoPaginaHorarios;
        if (valor(m_periodoMenuReciente) > valor(mejor)) mejor = m_periodoMenuReciente;
        if (valor(m_periodoInscripcion) > valor(mejor)) mejor = m_periodoInscripcion;
        return mejor.isEmpty() ? m_periodoActual : mejor;
    }
    QVariantList horariosPensum2025() const { return m_horariosPensum2025; }
    QVariantList horariosPensum1997() const { return m_horariosPensum1997; }
    int totalSeccionesOferta() const { return m_seccionesOfertaPlana.size(); }

    bool cargandoPensum() const { return m_cargandoPensum; }
    QVariantList semestresPensum() const { return m_semestresPensum; }
    QVariantList preguntasFaqPensum() const { return m_preguntasFaqPensum; }

    bool descargandoPdf() const { return m_descargandoPdf; }
    QVariantList calendariosOficiales() const { return m_calendariosOficiales; }

    QVariantList materiasRap() const { return m_materiasRap; }
    QVariantList expedienteSemestres() const { return m_expedienteSemestres; }
    QVariantList curvaProgresoExpediente() const { return m_curvaProgresoExpediente; }
    QVariantList notasTranscritas() const { return m_notasTranscritas; }
    QVariantList materiasSinTranscribir() const { return m_materiasSinTranscribir; }
    QVariantList diasHorarioAsignado() const { return m_diasHorarioAsignado; }
    QVariantList mallaHorarioAsignado() const { return m_mallaHorarioAsignado; }
    QVariantList clasesPorDiaDashboard() const { return m_clasesPorDiaDashboard; }
    QVariantList materiasSinBloqueHorario() const { return m_materiasSinBloqueHorario; }
    int totalBloquesHorario() const { return m_totalBloquesHorario; }
    int totalMateriasHorario() const { return m_totalMateriasHorario; }

    QVariantList materiasInscripcion() const { return m_materiasInscripcion; }
    QVariantList solicitudInscripcionRegistrada() const { return m_solicitudInscripcionRegistrada; }
    QVariantList solicitudesRecientes() const { return m_solicitudesRecientes; }
    bool tecladoVisible() const;
    double tecladoAltura() const;
    double insetSuperior() const;
    double insetInferior() const;
    QVariantList recordatorios() const { return m_recordatorios; }
    int recordatoriosPendientes() const;
    QString fechaSolicitudInscripcion() const { return m_fechaSolicitudInscripcion; }
    QString periodoInscripcion() const { return m_periodoInscripcion; }
    QString fechaLimiteInscripcion() const { return m_fechaLimiteInscripcion; }
    bool inscripcionDisponible() const { return m_inscripcionDisponible; }
    bool reporteInscripcionDisponible() const { return m_reporteInscripcionDisponible; }
    bool cargandoInscripcion() const { return m_cargandoInscripcion; }
    bool enviandoInscripcion() const { return m_enviandoInscripcion; }

    QVariantList materiasRetiro() const;
    QVariantList solicitudRetiroRegistrada() const { return m_solicitudRetiroRegistrada; }
    QString fechaSolicitudRetiro() const { return m_fechaSolicitudRetiro; }
    QString periodoRetiro() const { return m_periodoRetiro.isEmpty() ? m_periodoActual : m_periodoRetiro; }
    QString fechaLimiteRetiro() const { return m_fechaLimiteRetiro; }
    bool retiroDisponible() const { return m_retiroDisponible; }
    bool cargandoRetiro() const { return m_cargandoRetiro; }
    bool enviandoRetiro() const { return m_enviandoRetiro; }

    // Acciones invocables desde QML
    Q_INVOKABLE void iniciarSesion(const QString &cedula, const QString &clave);
    // Fuerza una consulta real al DAE aunque exista una copia en caché
    Q_INVOKABLE void sincronizarConServidor();
    // Devuelve una ruta local nueva (y limpia las fotos recortadas anteriores) para guardar la foto de perfil ajustada
    Q_INVOKABLE QString prepararRutaFotoPerfil();
    Q_INVOKABLE void iniciarSesionConBiometria();
    Q_INVOKABLE void activarBiometria(bool activar);
    Q_INVOKABLE void confirmarEscanerBiometricoLocal(bool exito);
    Q_INVOKABLE void cerrarSesion();
    void procesarResultadoBiometrico(bool exito, const QString &mensaje);

    Q_INVOKABLE void cargarDatosInscripcion();
    Q_INVOKABLE void prepararPasoConfirmacionInscripcion(const QVariantList &seleccionadas);
    Q_INVOKABLE void registrarSolicitudInscripcion(const QVariantList &seleccionadas);

    Q_INVOKABLE void cargarDatosRetiro();
    Q_INVOKABLE void enviarSolicitudRetiro(const QVariantList &seleccionadas);

    Q_INVOKABLE void cargarOfertaHorarios();
    Q_INVOKABLE QVariantList filtrarHorariosOferta(int pensumIdx, int estadoIdx, const QString &busqueda, int limite) const;
    Q_INVOKABLE int contarHorariosOferta(int pensumIdx, int estadoIdx, const QString &busqueda) const;
    Q_INVOKABLE QString obtenerProfesorSeccion(const QString &codigo, const QString &seccion, const QString &fallback = QString()) const;
    Q_INVOKABLE QVariantMap consultarSalonesDisponibles(int diaIdx, int horaIdx, int categoriaFiltro, const QString &busqueda) const;

    Q_INVOKABLE void cargarPensum(int modoVista, int escuelaIdx);
    Q_INVOKABLE void cargarFaqPensum();
    Q_INVOKABLE void cargarCalendarios();
    Q_INVOKABLE void descargarCalendarioPdf(const QString &urlPdf, const QString &nombreArchivo);
    Q_INVOKABLE void descargarConstanciaEstudiantil(int tipoConstancia);
    Q_INVOKABLE void descargarHorarioPdf();
    Q_INVOKABLE void descargarCarnetPdf(const QString &rutaFotoPerfil = QString());
    Q_INVOKABLE QVariantList matrizQrCarnet() const;
    Q_INVOKABLE void enviarSolicitudCambioEscuela(const QString &codigoEscuelaDestino);
    Q_INVOKABLE QStringList obtenerEstados() const;
    Q_INVOKABLE QStringList obtenerMunicipiosPorEstado(const QString &nombreEstado) const;
    Q_INVOKABLE QStringList obtenerParroquiasPorMunicipio(const QString &nombreEstado, const QString &nombreMunicipio) const;
    Q_INVOKABLE void guardarDatosPersonales(const QString &correoPrincipal,
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
                                            const QString &opsuManoAgil);
    Q_INVOKABLE void sincronizarSeccionEstudiantil(const QString &hrefRelativo);
    // Registra la acción que el estudiante acaba de hacer (constancia, inscripción,
    //  carnet, RAP, horario o calendario) para las "Solicitudes Recientes"
    Q_INVOKABLE void registrarSolicitudReciente(const QString &tipo, const QString &titulo,
                                                 const QString &detalle, const QString &estado);

    // --- Recordatorios (tareas y examenes) ---
    Q_INVOKABLE void guardarRecordatorio(const QVariantMap &datos);
    Q_INVOKABLE void eliminarRecordatorio(const QString &id);
    Q_INVOKABLE void alternarRecordatorioHecho(const QString &id);
    Q_INVOKABLE QStringList materiasSugeridasRecordatorio() const;
    QVariantList materiasParaRecordatorio() const;
    // Programa (o cancela) la notificacion local de un recordatorio
    Q_INVOKABLE void programarAvisoRecordatorio(const QString &id, const QString &titulo,
                                              const QString &texto, qint64 cuandoMillis);
    Q_INVOKABLE void cancelarAvisoRecordatorio(const QString &id);
    // Varios avisos por recordatorio: cada uno con su etiqueta
    Q_INVOKABLE void programarAvisosRecordatorio(const QString &id, const QString &titulo,
                                                 const QString &texto, const QVariantList &avisos);
    Q_INVOKABLE void cancelarAvisosRecordatorio(const QString &id, const QVariantList &avisos);
    Q_INVOKABLE void avisarAhoraRecordatorio(const QString &id, const QString &titulo, const QString &texto);
    // Pide el permiso de notificaciones (Android 13+), una sola vez
    Q_INVOKABLE void solicitarPermisoNotificaciones();
    bool permisoNotificacionesActivo() const;
    void setPermisoNotificacionesActivo(bool activar);
    Q_INVOKABLE void activarPermisoNotificaciones(bool activar);
    // Aplica el esquema de color de la app para que los iconos de la barra de
    // estado de Android (hora, wifi, batería) sean legibles sobre el fondo
    Q_INVOKABLE void aplicarEsquemaColorSistema(bool modoClaro);
    Q_INVOKABLE void aceptarDescargoResponsabilidad();

signals:
    void cargandoLoginChanged();
    void autenticadoChanged();
    void mensajeErrorChanged();
    void loginExitoso();
    void loginFallido(const QString &razon);
    void cacheSesionChanged();
    void sincronizacionCompletada();
    void sincronizacionFallida(const QString &mensaje);

    void datosEstudianteChanged();
    void enlacesMenuInternoChanged();

    void cargandoHorariosChanged();
    void horariosOfertaChanged();

    void cargandoPensumChanged();
    void pensumChanged();
    void faqPensumChanged();

    void descargandoPdfChanged();
    void calendariosChanged();
    void pdfDescargado(const QString &rutaLocal, const QString &nombreArchivo);
    void errorDescargaPdf(const QString &mensaje);

    void rapChanged();
    void expedienteChanged();
    void transcritasChanged();
    void horarioAsignadoChanged();
    // Se emite cuando cambian las materias que puede elegir el estudiante
    // para un recordatorio (horario, materias inscritas o RAP).
    void materiasRecordatorioChanged();
    void inscripcionChanged();
    void solicitudesRecientesChanged();
    void tecladoVisibleChanged();
    void recordatoriosChanged();
    void solicitudInscripcionCompletada(bool exito, const QString &mensaje);
    void retiroChanged();
    void solicitudRetiroCompletada(bool exito, const QString &mensaje);
    void cambioEscuelaChanged();
    void solicitudCambioEscuelaCompletada(bool exito, const QString &mensaje);
    void datosPersonalesGuardados(bool exito, const QString &mensaje);
    void aparienciaChanged();
    void biometriaChanged();
    void biometriaNotificacion(bool exito, const QString &mensaje);
    void mostrarEscanerBiometricoLocal(const QString &titulo, const QString &subtitulo);

private:
    void limpiarDatosEstudianteSesion();
    void iniciarSesionInterno(const QString &cedula, const QString &clave,
                              bool permitirCache, bool emitirLogin);
    bool restaurarSesionDesdeCache(const QString &cedula, const QString &clave,
                                   bool emitirLogin);
    void guardarSesionEnCache(const QString &menuHtml);
    bool cargarSeccionDesdeCache(const QString &hrefRelativo);
    void limpiarCacheSesion(const QString &cedula) const;
    void guardarCredencialesBiometricas(const QString &cedula, const QString &clave);
    void solicitarAutenticacionBiometricaDispositivo(const QString &titulo, const QString &subtitulo);

    QNetworkAccessManager *m_nam;
    DaeCookieJar *m_cookieJar;

    bool m_cargandoLogin = false;
    bool m_autenticado = false;
    QString m_mensajeError;

    QString m_cedulaEstudiante;
    QString m_nombreEstudiante = "ESTUDIANTE DAE UC";
    QString m_primerNombre;
    QString m_segundoNombre;
    QString m_primerApellido;
    QString m_segundoApellido;
    QString m_inicialesEstudiante = "UC";
    QString m_escuelaEstudiante = "FACULTAD DE INGENIERÍA";
    QString m_correoEstudiante;
    QString m_correoAlternativo;
    QString m_telefonoFijo;
    QString m_telefonoEstudiante;
    QString m_fechaNacimiento;
    QString m_sexoEstudiante;
    QString m_dirEstado = "CARABOBO";
    QString m_dirMunicipio = "VALENCIA";
    QString m_dirParroquia;
    QString m_dirDetalle;
    QString m_idEstado = "7";
    QString m_idMunicipio = "91";
    QString m_idParroquia = "316";
    // Tablas de Estado -> Municipios (id, nombre) y Municipio -> Parroquias (id, nombre)
    QMap<QString, QList<QPair<QString, QString>>> m_municipiosPorEstado;
    QMap<QString, QList<QPair<QString, QString>>> m_parroquiasPorMunicipio;
    QString m_opsuEstadoCivil = "SOLTERO";
    QString m_opsuEtnia = "NINGUNA";
    QString m_opsuDiscapacidad = "NINGUNA";
    QString m_opsuManoAgil = "DERECHA";
    QString m_periodoActual = "2-2026";
    QString m_pidSesion = "";
    QString m_fechaLimiteCambioEscuela = "HASTA EL MIE 28/10/2026";
    bool m_enviandoCambioEscuela = false;
    QVariantList m_enlacesMenuInterno;

    QString m_promedioPonderadoEntero = "--";
    QString m_promedioPonderadoDecimal = "";
    QString m_promedioAritmeticoEntero = "--";
    QString m_promedioAritmeticoDecimal = "";
    int m_ucInscritas = 0;
    int m_ucAprobadasCarrera = 0;

    int m_temaSeleccionado = 3; // 3 = Sistema Operativo (por defecto), 0 = Oscuro, 1 = Claro, 2 = OLED
    int m_paletaAuroraIndex = 0;
    bool m_animacionAuroraActiva = true;
    QString m_urlFotoPerfil = "";
    bool m_biometriaActiva = false;
    bool m_autenticandoBiometria = false;
    QString m_accionBiometricaPendiente = ""; // "login" o "activar"
    QString m_cedulaBiometrica = "";
    QString m_claveBiometrica = "";
    QString m_ultimaClaveSesion = "";
    // Estado de la caché local de la sesión
    bool m_datosDesdeCache = false;
    bool m_sincronizandoServidor = false;
    bool m_restaurandoDesdeCache = false;
    qint64 m_cacheTimestamp = 0;

    bool m_cargandoHorarios = false;
    QString m_fechaActualizacionHorarios = "Sincronizado con dae.ing.uc.edu.ve";
    QString m_periodoPaginaHorarios;
    QString m_periodoMenuReciente;
    QVariantList m_horariosPensum2025;
    QVariantList m_horariosPensum1997;
    QVariantList m_seccionesOfertaPlana;

    // Mapas rápidos ("CODIGO|SECCION" -> Profesor / Bloques / Estado) extraídos de /horarios/
    QMap<QString, QString> m_mapaProfesorHorario;
    QMap<QString, QStringList> m_mapaBloquesHorario;
    QMap<QString, QString> m_mapaNombreMateriaHorario;
    QMap<QString, QString> m_mapaEstadoHorario;

    bool m_cargandoPensum = false;
    QVariantList m_semestresPensum;
    QVariantList m_preguntasFaqPensum;

    bool m_descargandoPdf = false;
    QVariantList m_calendariosOficiales;

    QVariantList m_materiasRap;
    // Materias del periodo (semestre) actual, tal como aparecen en las
    // transcritas. Se usan para el desplegable de materias del recordatorio.
    QVariantList m_materiasPeriodoActualRaw;
    QVariantList m_expedienteSemestres;
    QVariantList m_curvaProgresoExpediente;
    QVariantList m_notasTranscritas;
    QVariantList m_materiasSinTranscribir;

    // Datos estructurados del Horario Asignado del estudiante
    QSet<QString> m_clavesBloquesDelEstudiante;
    QVariantList m_materiasInscritasRaw;
    QVariantList m_diasHorarioAsignado;
    QVariantList m_mallaHorarioAsignado;
    QVariantList m_clasesPorDiaDashboard;
    QVariantList m_materiasSinBloqueHorario;
    int m_totalBloquesHorario = 0;
    int m_totalMateriasHorario = 0;

    // Estado y datos de la Solicitud de Inscripción (Paso 1, Paso 2 y Reporte Paso 3)
    bool m_cargandoInscripcion = false;
    bool m_enviandoInscripcion = false;
    bool m_inscripcionDisponible = true;
    bool m_reporteInscripcionDisponible = true;
    QVariantList m_materiasInscripcionServidor;
    QVariantList m_materiasInscripcion;
    QVariantList m_solicitudInscripcionRegistrada;
    QVariantList m_solicitudesRecientes;
    QVariantList m_recordatorios;

    void guardarRecordatoriosEnDisco();

    // Estado del teclado (vigila que se emita siempre la señal)
    bool m_tecladoUltimoEstado = false;
    bool m_permisoNotificacionesSolicitado = false;
    bool m_notificacionesHabilitadasUsuario = true;
    bool m_ultimoEstadoPermisoNotif = false;
    bool m_esperandoRespuestaPermisoNotif = false;
    bool m_sistemaEsClaroReal = false;
    bool m_esquemaPersonalizado = false;
    bool m_descargoAceptado = false;
    QString m_fechaSolicitudInscripcion;
    QString m_periodoInscripcion = "2-2026";
    QString m_fechaLimiteInscripcion;
    QString m_resultadoPostInscripcionPendiente;
    QString m_urlAccionProcesarInscripcion;
    QString m_urlAccionConfirmarInscripcion;
    QMap<QString, QString> m_camposOcultosConfirmarInscripcion;

    // Estado y datos de la Solicitud de Retiro de Asignatura
    bool m_cargandoRetiro = false;
    bool m_enviandoRetiro = false;
    bool m_retiroDisponible = true;
    QString m_periodoRetiro;
    QString m_fechaLimiteRetiro;
    QString m_hrefRetiroMenu;
    QString m_urlAccionProcesarRetiro;
    QMap<QString, QString> m_camposOcultosRetiro;
    QVariantList m_materiasRetiroServidor;
    QVariantList m_solicitudRetiroRegistrada;
    QString m_fechaSolicitudRetiro;
    QSet<QString> m_codigosRetiradosConfirmados;

    // Helpers internos de scraping y limpieza de HTML
    static QString limpiarTextoHtml(QString html);
    void parsearMenuEstudiantil(const QString &html);
    void parsearPaginaInternaEstudiantil(const QString &href, const QString &html);
    void parsearHorarioAsignadoHtml(const QString &html);
    void parsearRapHtml(const QString &html);
    void parsearExpedienteHtml(const QString &html);
    void parsearReporteNotasTranscritasHtml(const QString &html);
    void parsearActualizarDatosHtml(const QString &html);
    void parsearInscripcionHtml(const QString &html);
    void parsearReporteSolicitudInscripcionHtml(const QString &html);
    void parsearRetiroHtml(const QString &html);
    void reconstruirOfertaInscripcionDesdeRap();
    void cargarSolicitudInscripcionLocal();
    void guardarSolicitudInscripcionLocal(const QVariantList &items, const QString &fecha);
    void reconstruirEstructurasHorarioAsignado();
    void parsearHtmlHorarios(const QString &html);
    QVariantList parsearBloquePensumHorarios(const QString &bloqueHtml, const QString &tagPensum, QVariantList &acumuladorPlano);
    void parsearHtmlPensum(const QString &html);
    void parsearHtmlFaqPensum(const QString &html);
    void parsearHtmlPortalCalendarios(const QString &html);
};

#endif // DAECLIENT_H
