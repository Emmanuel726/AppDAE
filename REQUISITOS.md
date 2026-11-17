# Requisitos para Compilar AppDAE

Este documento detalla las herramientas, SDKs y dependencias necesarias para compilar **AppDAE** desde el código fuente para **Android (arm64-v8a)** o **Escritorio (Linux/Windows)**.

## 1. Herramientas Requeridas

- **Qt:** `6.8` o superior (probado con **Qt 6.10.2**) con los siguientes módulos:
  - `Qt Quick` (`Qt6::Quick`)
  - `Qt Quick Controls 2` (`Qt6::QuickControls2`)
  - `Qt Network` (`Qt6::Network`)
  - Kits instalados: `Android for arm64-v8a` (y opcionalmente `Desktop` para pruebas locales).
- **CMake:** `3.16` o superior.
- **Ninja** (recomendado) o `Make`.
- **Compilador C++:** compatible con **C++17** o superior.

## 2. Requisitos Adicionales para Android

- **JDK:** Java **17** o **21** (recomendado **JDK 21**).
- **Android SDK:**
  - `Platform`: **Android 15 / 16 (API 35–37)**
  - `Build-Tools`: **36.0.0** o superior
  - `Min SDK`: **28** (Android 9.0)
- **Android NDK:** **27.x** o **28.x** (probado con `28.2.13676358`).
- **OpenSSL para Android (`android_openssl`):**
  - Indispensable para las conexiones HTTPS hacia `dae.ing.uc.edu.ve`.
  - Puedes descargarlo desde el repositorio `KDAB/android_openssl` o desde **Qt Maintenance Tool** (`Qt -> Additional Libraries -> OpenSSL 3.x Toolkit`).
  - Colócalo en `~/Android/android_openssl` o pasa su ruta mediante la variable `ANDROID_OPENSSL_DIR`.

## 3. Cómo Compilar el APK

1. Exporta las variables de entorno según tu instalación:
   ```bash
   export JAVA_HOME=/ruta/a/tu/jdk-21
   export ANDROID_SDK_ROOT=$HOME/Android/Sdk
   export ANDROID_NDK_ROOT=$HOME/Android/Sdk/ndk/28.2.13676358
   export ANDROID_OPENSSL_DIR=$HOME/Android/android_openssl
   ```

2. Configura el proyecto con `qt-cmake`:
   ```bash
   /ruta/a/Qt/6.10.2/android_arm64_v8a/bin/qt-cmake \
     -S . \
     -B build/Android-Debug \
     -G Ninja \
     -DANDROID_OPENSSL_DIR="$ANDROID_OPENSSL_DIR"
   ```

3. Compila y empaqueta el APK:
   ```bash
   cmake --build build/Android-Debug --target apk -j4
   ```

4. El APK generado quedará en:
   ```
   build/Android-Debug/android-build/build/outputs/apk/debug/android-build-debug.apk
   ```
