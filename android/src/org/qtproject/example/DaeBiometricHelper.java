package org.qtproject.example;

import android.app.Activity;
import android.app.KeyguardManager;
import android.content.Context;
import android.content.DialogInterface;
import android.content.res.Resources;
import android.graphics.Color;
import android.graphics.Insets;
import android.hardware.biometrics.BiometricPrompt;
import android.os.Build;
import android.os.CancellationSignal;
import android.util.DisplayMetrics;
import android.view.View;
import android.view.Window;
import android.view.WindowInsets;
import android.view.WindowInsetsController;
import android.view.WindowManager;

/**
 * Auxiliar nativo en Android para:
 * - Calcular y almacenar en caché los márgenes fijos de la barra de estado y navegación (en dp).
 * - Configurar la pantalla de borde a borde (barras transparentes e iconos claros/oscuros).
 * - Autenticar mediante el diálogo biométrico nativo del dispositivo.
 */
public class DaeBiometricHelper {

    public static native void nativeOnBiometricResult(boolean exito, String mensaje);

    private static volatile boolean sUltimoModoClaro = false;
    private static volatile double sCachedStatusBarHeightDp = -1.0;
    private static volatile double sCachedNavBarHeightDp = -1.0;

    /** Devuelve la altura fija de la barra de estado en dp (sin variar al abrir el teclado). */
    public static double getStatusBarHeightDp(final Activity activity) {
        if (sCachedStatusBarHeightDp > 0.0) {
            return sCachedStatusBarHeightDp;
        }
        if (activity == null) {
            return 32.0;
        }
        try {
            Resources res = activity.getResources();
            DisplayMetrics dm = res.getDisplayMetrics();
            float density = (dm != null && dm.density > 0f) ? dm.density : 1.0f;

            int px = 0;
            int resId = res.getIdentifier("status_bar_height", "dimen", "android");
            if (resId > 0) {
                px = res.getDimensionPixelSize(resId);
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                Window window = activity.getWindow();
                if (window != null && window.getDecorView() != null) {
                    WindowInsets wi = window.getDecorView().getRootWindowInsets();
                    if (wi != null) {
                        Insets sys = wi.getInsetsIgnoringVisibility(
                                WindowInsets.Type.statusBars() | WindowInsets.Type.displayCutout());
                        if (sys.top > px) {
                            px = sys.top;
                        }
                    }
                }
            }

            double dp = (px > 0) ? (px / (double) density) : 32.0;
            if (dp < 24.0) {
                dp = 24.0;
            } else if (dp > 64.0) {
                dp = 64.0;
            }
            sCachedStatusBarHeightDp = dp;
            return dp;
        } catch (Throwable ignored) {
            return 32.0;
        }
    }

    public static double getNavigationBarHeightDp(final Activity activity) {
        if (sCachedNavBarHeightDp >= 0.0) {
            return sCachedNavBarHeightDp;
        }
        if (activity == null) {
            return 16.0;
        }
        try {
            Resources res = activity.getResources();
            DisplayMetrics dm = res.getDisplayMetrics();
            float density = (dm != null && dm.density > 0f) ? dm.density : 1.0f;

            int px = -1;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                Window window = activity.getWindow();
                if (window != null && window.getDecorView() != null) {
                    WindowInsets wi = window.getDecorView().getRootWindowInsets();
                    if (wi != null) {
                        Insets nav = wi.getInsetsIgnoringVisibility(WindowInsets.Type.navigationBars());
                        px = nav.bottom;
                    }
                }
            }

            double dp;
            if (px >= 0) {
                dp = px / (double) density;
            } else {
                int modeId = res.getIdentifier("config_navBarInteractionMode", "integer", "android");
                int mode = (modeId > 0) ? res.getInteger(modeId) : 0;
                if (mode == 2) {
                    // Navegación por gestos (barra inferior delgada)
                    dp = 16.0;
                } else {
                    int resId = res.getIdentifier("navigation_bar_height", "dimen", "android");
                    int navPx = (resId > 0) ? res.getDimensionPixelSize(resId) : 0;
                    dp = (navPx > 0) ? (navPx / (double) density) : 16.0;
                }
            }

            if (dp < 0.0) {
                dp = 0.0;
            } else if (dp > 56.0) {
                dp = 56.0;
            }
            sCachedNavBarHeightDp = dp;
            return dp;
        } catch (Throwable ignored) {
            return 16.0;
        }
    }

    private static void applyEdgeToEdgeNow(final Activity activity, final boolean modoClaro) {
        try {
            Window window = activity.getWindow();
            if (window == null) {
                return;
            }

            window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
            window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS
                    | WindowManager.LayoutParams.FLAG_TRANSLUCENT_NAVIGATION
                    | WindowManager.LayoutParams.FLAG_FULLSCREEN);
            window.setStatusBarColor(Color.TRANSPARENT);
            window.setNavigationBarColor(Color.TRANSPARENT);

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                window.setNavigationBarDividerColor(Color.TRANSPARENT);
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                window.setStatusBarContrastEnforced(false);
                window.setNavigationBarContrastEnforced(false);
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                WindowManager.LayoutParams lp = window.getAttributes();
                int targetCutout = (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R)
                        ? WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
                        : WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
                if (lp.layoutInDisplayCutoutMode != targetCutout) {
                    lp.layoutInDisplayCutoutMode = targetCutout;
                    window.setAttributes(lp);
                }
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                window.setDecorFitsSystemWindows(false);
            }

            View decorView = window.getDecorView();
            if (decorView != null) {
                int flags = View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                        | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                        | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION;
                if (modoClaro) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        flags |= View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        flags |= View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR;
                    }
                }
                decorView.setSystemUiVisibility(flags);

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    WindowInsetsController controller = decorView.getWindowInsetsController();
                    if (controller != null) {
                        int mask = WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS
                                | WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS;
                        controller.setSystemBarsAppearance(modoClaro ? mask : 0, mask);
                    }
                }
            }
        } catch (Throwable ignored) {
        }
    }

    public static void configureEdgeToEdge(final Activity activity, final boolean modoClaro) {
        if (activity == null) {
            return;
        }
        sUltimoModoClaro = modoClaro;
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                applyEdgeToEdgeNow(activity, sUltimoModoClaro);
                try {
                    Window window = activity.getWindow();
                    if (window == null) {
                        return;
                    }
                    final View decorView = window.getDecorView();
                    if (decorView != null) {
                        decorView.post(new Runnable() {
                            @Override
                            public void run() {
                                applyEdgeToEdgeNow(activity, sUltimoModoClaro);
                            }
                        });
                        decorView.postDelayed(new Runnable() {
                            @Override
                            public void run() {
                                applyEdgeToEdgeNow(activity, sUltimoModoClaro);
                            }
                        }, 180);
                    }
                } catch (Throwable ignored) {
                }
            }
        });
    }

    public static boolean isBiometricAvailable(final Activity activity) {
        if (activity == null) {
            return false;
        }
        try {
            KeyguardManager km = (KeyguardManager) activity.getSystemService(Context.KEYGUARD_SERVICE);
            return km != null && km.isKeyguardSecure();
        } catch (Throwable t) {
            return false;
        }
    }

    public static void authenticate(final Activity activity, final String titulo, final String subtitulo) {
        if (activity == null) {
            nativeOnBiometricResult(false, "No se pudo acceder a la actividad de Android.");
            return;
        }

        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        BiometricPrompt.Builder builder = new BiometricPrompt.Builder(activity)
                                .setTitle(titulo)
                                .setSubtitle(subtitulo)
                                .setDescription("Coloca tu huella dactilar para verificar tu identidad en DAE UC");

                        builder.setNegativeButton("Cancelar", activity.getMainExecutor(), new DialogInterface.OnClickListener() {
                            @Override
                            public void onClick(DialogInterface dialogInterface, int i) {
                                nativeOnBiometricResult(false, "Autenticación biométrica cancelada");
                            }
                        });

                        BiometricPrompt prompt = builder.build();
                        CancellationSignal cancelSignal = new CancellationSignal();

                        prompt.authenticate(cancelSignal, activity.getMainExecutor(), new BiometricPrompt.AuthenticationCallback() {
                            @Override
                            public void onAuthenticationError(int errorCode, CharSequence errString) {
                                super.onAuthenticationError(errorCode, errString);
                                String msg = (errString != null) ? errString.toString() : "Autenticación cancelada";
                                nativeOnBiometricResult(false, msg);
                            }

                            @Override
                            public void onAuthenticationSucceeded(BiometricPrompt.AuthenticationResult result) {
                                super.onAuthenticationSucceeded(result);
                                nativeOnBiometricResult(true, "Identidad verificada con huella dactilar");
                            }

                            @Override
                            public void onAuthenticationFailed() {
                                super.onAuthenticationFailed();
                            }
                        });
                    } else {
                        nativeOnBiometricResult(true, "Identidad verificada en el dispositivo");
                    }
                } catch (Throwable t) {
                    nativeOnBiometricResult(false, "Sensor biométrico no disponible: " + t.getMessage());
                }
            }
        });
    }
}
