#!/bin/bash
# Ajustes na raylib 5.5 para OpenGL ES 3 no celular. Uso: android/ajustar_raylib.sh <pasta raylib-src>
# Se uma versão nova da raylib mudar estas linhas, o build falha aqui em vez de gerar um APK quebrado.
set -e
SRC="$1/src"
trocar() {  # arquivo, expressão procurada, novo texto
  grep -q "$2" "$SRC/$1" || { echo "raylib: não encontrei '$2' em $1"; exit 1; }
  sed -i "s/$2/$3/g" "$SRC/$1"
}
# a raylib pede um contexto ES 2 mesmo compilada para ES 3
trocar platforms/rcore_android.c "EGL_CONTEXT_CLIENT_VERSION, 2" "EGL_CONTEXT_CLIENT_VERSION, 3"
# com 16 bits de profundidade, peças próximas piscam na cena
trocar platforms/rcore_android.c "EGL_DEPTH_SIZE, 16" "EGL_DEPTH_SIZE, 24"
# no ES 3 a função não tem o sufixo
trocar rlgl.h "glDrawBuffersEXT" "glDrawBuffers"
# textura de sombra: o ES 3 exige o formato com tamanho (GL_DEPTH_COMPONENT24)
trocar rlgl.h "^    RLGL.ExtSupported.texDepthWebGL = true;$" "    RLGL.ExtSupported.texDepthWebGL = false;"
