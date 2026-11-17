package org.qtproject.example;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

/**
 * Recibe la alarma de los recordatorios y publica la notificación.
 */
public class DaeReminderReceiver extends BroadcastReceiver {

    @Override
    public void onReceive(Context context, Intent intent) {
        if (context == null || intent == null) {
            return;
        }
        try {
            String id = intent.getStringExtra("id");
            String titulo = intent.getStringExtra("titulo");
            String texto = intent.getStringExtra("texto");
            DaeReminderHelper.mostrarAviso(context, id == null ? "0" : id,
                    titulo == null ? "Recordatorio" : titulo,
                    texto == null ? "" : texto);
        } catch (Throwable ignored) {
        }
    }
}
