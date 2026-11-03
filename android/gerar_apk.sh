#!/bin/bash
# Monta e assina o APK. Uso: android/gerar_apk.sh <libtaverna.so> <pacote.bin> <saida.apk>
# A chave em android/chave é só para testes: serve para instalar por cima sem perder o progresso.
set -e
SO="$1"; PACOTE="$2"; SAIDA="$3"
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
BT="$ANDROID_HOME/build-tools/$(ls "$ANDROID_HOME/build-tools" | sort -V | tail -1)"
JAR="$ANDROID_HOME/platforms/$(ls "$ANDROID_HOME/platforms" | sort -V | tail -1)/android.jar"
T="$(mktemp -d)"
mkdir -p "$T/assets" "$T/lib/arm64-v8a"
cp "$PACOTE" "$T/assets/pacote.bin"
cp "$SO" "$T/lib/arm64-v8a/libtaverna.so"
"$BT/aapt2" link --manifest "$RAIZ/android/AndroidManifest.xml" -I "$JAR" -A "$T/assets" -o "$T/base.apk"
(cd "$T" && zip -q -r base.apk lib)
"$BT/zipalign" -f -p 4 "$T/base.apk" "$T/alinhado.apk"
"$BT/apksigner" sign --ks "$RAIZ/android/chave/teste.jks" --ks-key-alias taverna --ks-pass pass:tavernateste --key-pass pass:tavernateste --out "$SAIDA" "$T/alinhado.apk"
"$BT/apksigner" verify "$SAIDA"
ls -la "$SAIDA"
