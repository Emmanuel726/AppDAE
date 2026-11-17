package org.qtproject.example;

import android.app.Activity;
import android.app.AlarmManager;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.os.Build;
import android.util.Log;

/**
 * Notificaciones locales de los recordatorios (tareas y exámenes) de la app.
 *
 * - programarAviso(): agenda el aviso con AlarmManager para la fecha elegida.
 * - mostrarAvisoAhora(): publica la notificación en el momento.
 * - cancelarAviso(): cancela el aviso agendado.
 */
public class DaeReminderHelper {

    private static final String TAG = "DaeReminderHelper";
    private static final String CANAL_ID = "dae_recordatorios_v2";
    private static final String CANAL_NOMBRE = "Tareas y exámenes";
    private static final int NOTIFICACION_BASE = 7300;

    /** Crea el canal de notificaciones (obligatorio en Android 8+). */
    public static void crearCanal(Context ctx) {
        if (ctx == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return;
        }
        try {
            NotificationManager nm = (NotificationManager) ctx.getSystemService(Context.NOTIFICATION_SERVICE);
            if (nm == null) {
                return;
            }
            NotificationChannel canal = new NotificationChannel(CANAL_ID, CANAL_NOMBRE, NotificationManager.IMPORTANCE_HIGH);
            canal.setDescription("Avisos de tus tareas y exámenes programados");
            canal.enableLights(true);
            canal.setLightColor(Color.parseColor("#127A5C"));
            canal.enableVibration(true);
            nm.createNotificationChannel(canal);
        } catch (Throwable t) {
            Log.e(TAG, "Error creando canal de notificaciones", t);
        }
    }

    /** Agenda el aviso del recordatorio para la fecha indicada (milisegundos epoch). */
    public static void programarAviso(final Activity activity, final String id, final String titulo,
                                    final String texto, final String etiqueta, final long cuando) {
        if (activity == null) {
            return;
        }
        try {
            final Context ctx = activity.getApplicationContext();
            crearCanal(ctx);

            long ahora = System.currentTimeMillis();
            long momentoDisparo = cuando;
            // Si el usuario programa para el minuto actual (p. ej. son las 08:33:20 PM y puso 08:33 PM),
            // el inicio del minuto (08:33:00 PM) quedó hace unos segundos; lo disparamos en 1.5 s.
            if (momentoDisparo <= ahora) {
                if (ahora - momentoDisparo <= 90000L) {
                    momentoDisparo = ahora + 1500L;
                } else {
                    // Fecha ya pasada hace más de minuto y medio: no programar en el pasado
                    return;
                }
            }

            Intent intent = new Intent(ctx, DaeReminderReceiver.class);
            intent.setAction("org.qtproject.example.RECORDATORIO");
            intent.setPackage(ctx.getPackageName());
            intent.putExtra("id", id);
            intent.putExtra("titulo", titulo);
            intent.putExtra("texto", texto);
            intent.putExtra("canal", CANAL_ID);

            // Cada aviso tiene su propia clave, para que el AlarmManager
            // los agende por separado y se puedan cancelar uno a uno.
            final int claveAviso = NOTIFICACION_BASE + id.hashCode() + (etiqueta == null ? 0 : etiqueta.hashCode());

            PendingIntent pi = PendingIntent.getBroadcast(ctx, claveAviso,
                    intent, PendingIntent.FLAG_UPDATE_CURRENT | flagsInmutables());

            AlarmManager am = (AlarmManager) ctx.getSystemService(Context.ALARM_SERVICE);
            if (am == null) {
                return;
            }
            try {
                // setAlarmClock garantiza disparo puntual exacto incluso con pantalla apagada (Doze)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    Intent showIntent = ctx.getPackageManager().getLaunchIntentForPackage(ctx.getPackageName());
                    if (showIntent == null) {
                        showIntent = new Intent(ctx, activity.getClass());
                    }
                    showIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
                    PendingIntent showPi = PendingIntent.getActivity(ctx, claveAviso,
                            showIntent, PendingIntent.FLAG_UPDATE_CURRENT | flagsInmutables());
                    AlarmManager.AlarmClockInfo info = new AlarmManager.AlarmClockInfo(momentoDisparo, showPi);
                    am.setAlarmClock(info, pi);
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, momentoDisparo, pi);
                } else {
                    am.setExact(AlarmManager.RTC_WAKEUP, momentoDisparo, pi);
                }
            } catch (SecurityException se) {
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, momentoDisparo, pi);
                    } else {
                        am.set(AlarmManager.RTC_WAKEUP, momentoDisparo, pi);
                    }
                } catch (SecurityException se2) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, momentoDisparo, pi);
                    } else {
                        am.set(AlarmManager.RTC_WAKEUP, momentoDisparo, pi);
                    }
                }
            }
        } catch (Throwable t) {
            Log.e(TAG, "Error programando aviso", t);
        }
    }

    /** Cancela el aviso agendado de un recordatorio. */
    public static void cancelarAviso(final Activity activity, final String id) {
        cancelarAviso(activity, id, "");
    }

    /** Cancela un aviso concreto del recordatorio (etiqueta = indice o sufijo). */
    public static void cancelarAviso(final Activity activity, final String id, final String etiqueta) {
        if (activity == null) {
            return;
        }
        try {
            final Context ctx = activity.getApplicationContext();
            Intent intent = new Intent(ctx, DaeReminderReceiver.class);
            intent.setAction("org.qtproject.example.RECORDATORIO");
            intent.setPackage(ctx.getPackageName());
            intent.putExtra("id", id);
            final int claveAviso = NOTIFICACION_BASE + id.hashCode()
                    + (etiqueta == null ? 0 : etiqueta.hashCode());

            PendingIntent pi = PendingIntent.getBroadcast(ctx, claveAviso,
                    intent, PendingIntent.FLAG_NO_CREATE | flagsInmutables());
            if (pi != null) {
                AlarmManager am = (AlarmManager) ctx.getSystemService(Context.ALARM_SERVICE);
                if (am != null) {
                    am.cancel(pi);
                }
                pi.cancel();
            }
        } catch (Throwable t) {
            Log.e(TAG, "Error cancelando aviso", t);
        }
    }

    /** Publica la notificacion en el instante. */
    public static void mostrarAvisoAhora(final Activity activity, final String id,
                                        final String titulo, final String texto) {
        if (activity == null) {
            return;
        }
        try {
            mostrarAviso(activity.getApplicationContext(), id, titulo, texto);
        } catch (Throwable t) {
            Log.e(TAG, "Error en mostrarAvisoAhora", t);
        }
    }

    public static void mostrarAviso(final Context ctx, final String id, final String titulo, final String texto) {
        try {
            crearCanal(ctx);
            NotificationManager nm = (NotificationManager) ctx.getSystemService(Context.NOTIFICATION_SERVICE);
            if (nm == null) {
                return;
            }

            Intent abrir = ctx.getPackageManager().getLaunchIntentForPackage(ctx.getPackageName());
            if (abrir == null) {
                abrir = new Intent();
                abrir.setPackage(ctx.getPackageName());
            }
            abrir.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
            PendingIntent abrirPi = PendingIntent.getActivity(ctx, (NOTIFICACION_BASE + (id == null ? 0 : id.hashCode())),
                    abrir, PendingIntent.FLAG_UPDATE_CURRENT | flagsInmutables());

            Notification.Builder b;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                b = new Notification.Builder(ctx, CANAL_ID);
            } else {
                b = new Notification.Builder(ctx);
                b.setDefaults(Notification.DEFAULT_ALL);
            }
            String tituloFinal = (titulo == null || titulo.isEmpty()) ? "Recordatorio DAE" : titulo;
            String textoFinal = (texto == null || texto.isEmpty()) ? "Tienes un recordatorio pendiente" : texto;
            b.setContentTitle(tituloFinal);
            b.setContentText(textoFinal);
            b.setStyle(new Notification.BigTextStyle().bigText(textoFinal));
            // El icono de la propia app (la clase R pertenece a otro paquete)
            int iconoApp = 0;
            try {
                iconoApp = ctx.getApplicationInfo().icon;
            } catch (Throwable ignored) {
            }
            b.setSmallIcon(iconoApp != 0 ? iconoApp : android.R.drawable.ic_dialog_info);
            b.setAutoCancel(true);
            b.setContentIntent(abrirPi);
            b.setColor(Color.parseColor("#127A5C"));
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                b.setPriority(Notification.PRIORITY_HIGH);
                b.setCategory(Notification.CATEGORY_REMINDER);
                b.setVisibility(Notification.VISIBILITY_PUBLIC);
            }

            int notifId = NOTIFICACION_BASE + Math.abs((id == null ? "0" : id).hashCode() % 100000);
            nm.notify(notifId, b.build());
        } catch (Throwable t) {
            Log.e(TAG, "Error publicando notificacion", t);
        }
    }

    private static volatile boolean sYaSolicitadoEnSesion = false;

    /** Indica si ya se concedio el permiso de notificaciones (Android 13+ y ajustes del sistema). */
    public static boolean tienePermisoNotificaciones(final Activity activity) {
        if (activity == null) {
            return false;
        }
        try {
            NotificationManager nm = (NotificationManager) activity.getSystemService(Context.NOTIFICATION_SERVICE);
            if (nm != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                if (!nm.areNotificationsEnabled()) {
                    return false;
                }
            }
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                return true;
            }
            return ContextCompatPermiso(activity);
        } catch (Throwable ignored) {
            return false;
        }
    }

    /** Pide el permiso de notificaciones (Android 13+) o abre los ajustes si fue bloqueado. */
    public static void pedirPermisoNotificaciones(final Activity activity) {
        if (activity == null) {
            return;
        }
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                try {
                    crearCanal(activity.getApplicationContext());
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        if (!ContextCompatPermiso(activity)) {
                            boolean mostrarRazon = activity.shouldShowRequestPermissionRationale("android.permission.POST_NOTIFICATIONS");
                            if (!sYaSolicitadoEnSesion || mostrarRazon) {
                                sYaSolicitadoEnSesion = true;
                                activity.requestPermissions(new String[]{"android.permission.POST_NOTIFICATIONS"}, 7301);
                                return;
                            } else {
                                abrirAjustesNotificaciones(activity);
                                return;
                            }
                        }
                    }
                    NotificationManager nm = (NotificationManager) activity.getSystemService(Context.NOTIFICATION_SERVICE);
                    if (nm != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && !nm.areNotificationsEnabled()) {
                        abrirAjustesNotificaciones(activity);
                    }
                } catch (Throwable t) {
                    Log.e(TAG, "Error pidiendo permiso de notificaciones", t);
                }
            }
        });
    }

    public static void abrirAjustesNotificaciones(final Activity activity) {
        if (activity == null) {
            return;
        }
        try {
            Intent intent = new Intent();
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                intent.setAction("android.settings.APP_NOTIFICATION_SETTINGS");
                intent.putExtra("android.provider.extra.APP_PACKAGE", activity.getPackageName());
            } else {
                intent.setAction("android.settings.APPLICATION_DETAILS_SETTINGS");
                intent.setData(android.net.Uri.fromParts("package", activity.getPackageName(), null));
            }
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            activity.startActivity(intent);
        } catch (Throwable t) {
            Log.e(TAG, "Error abriendo ajustes de notificaciones", t);
        }
    }

    private static boolean ContextCompatPermiso(final Activity activity) {
        try {
            return activity.checkSelfPermission("android.permission.POST_NOTIFICATIONS")
                    == android.content.pm.PackageManager.PERMISSION_GRANTED;
        } catch (Throwable t) {
            return true;
        }
    }

    private static int flagsInmutables() {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.M ? PendingIntent.FLAG_IMMUTABLE : 0;
    }
}
