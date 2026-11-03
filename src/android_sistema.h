// Funções do Android que a raylib não oferece: internet, área de transferência
// e mandar o jogo para o segundo plano. Tudo pelo Java do próprio sistema (JNI).
#pragma once
#if defined(__ANDROID__)

#include <android/asset_manager.h>
#include <android/native_activity.h>
#include <android_native_app_glue.h>
#include <jni.h>

#include <string>

extern "C" struct android_app* GetAndroidApp(void);

namespace android_sistema {

struct Jni {
    JNIEnv* env = nullptr;
    JavaVM* vm = nullptr;
    Jni() {
        vm = GetAndroidApp()->activity->vm;
        vm->AttachCurrentThread(&env, nullptr);
    }
    bool erro() {
        if (env->ExceptionCheck()) {
            env->ExceptionClear();
            return true;
        }
        return false;
    }
};

inline std::string pastaInterna() {
    const char* p = GetAndroidApp()->activity->internalDataPath;
    return p ? p : ".";
}

inline bool lerAsset(const char* nome, std::string& saida) {
    AAsset* a = AAssetManager_open(GetAndroidApp()->activity->assetManager, nome, AASSET_MODE_BUFFER);
    if (!a) return false;
    off_t n = AAsset_getLength(a);
    saida.resize((size_t)n);
    int lidos = AAsset_read(a, saida.data(), (size_t)n);
    AAsset_close(a);
    return lidos == n;
}

inline bool baixar(const std::string& url, std::string& saida, int limiteMs) {
    Jni j;
    JNIEnv* e = j.env;
    saida.clear();
    jclass cUrl = e->FindClass("java/net/URL");
    if (j.erro() || !cUrl) return false;
    jstring s = e->NewStringUTF(url.c_str());
    jobject oUrl = e->NewObject(cUrl, e->GetMethodID(cUrl, "<init>", "(Ljava/lang/String;)V"), s);
    if (j.erro() || !oUrl) return false;
    jobject con = e->CallObjectMethod(oUrl, e->GetMethodID(cUrl, "openConnection", "()Ljava/net/URLConnection;"));
    if (j.erro() || !con) return false;
    jclass cCon = e->FindClass("java/net/HttpURLConnection");
    e->CallVoidMethod(con, e->GetMethodID(cCon, "setConnectTimeout", "(I)V"), limiteMs);
    e->CallVoidMethod(con, e->GetMethodID(cCon, "setReadTimeout", "(I)V"), limiteMs);
    if (j.erro()) return false;
    jint codigo = e->CallIntMethod(con, e->GetMethodID(cCon, "getResponseCode", "()I"));
    if (j.erro() || codigo != 200) return false;
    jobject in = e->CallObjectMethod(con, e->GetMethodID(cCon, "getInputStream", "()Ljava/io/InputStream;"));
    if (j.erro() || !in) return false;
    jclass cIn = e->FindClass("java/io/InputStream");
    jmethodID mRead = e->GetMethodID(cIn, "read", "([B)I");
    jbyteArray buf = e->NewByteArray(65536);
    while (true) {
        jint n = e->CallIntMethod(in, mRead, buf);
        if (j.erro()) return false;
        if (n < 0) break;
        size_t antes = saida.size();
        saida.resize(antes + (size_t)n);
        e->GetByteArrayRegion(buf, 0, n, (jbyte*)saida.data() + antes);
    }
    e->DeleteLocalRef(buf);
    return true;
}

inline void copiar(const char* texto) {
    Jni j;
    JNIEnv* e = j.env;
    jobject atividade = GetAndroidApp()->activity->clazz;
    // o serviço da área de transferência exige uma fila de mensagens nesta linha de execução
    jclass cLooper = e->FindClass("android/os/Looper");
    if (!e->CallStaticObjectMethod(cLooper, e->GetStaticMethodID(cLooper, "myLooper", "()Landroid/os/Looper;")))
        e->CallStaticVoidMethod(cLooper, e->GetStaticMethodID(cLooper, "prepare", "()V"));
    j.erro();
    jclass cCtx = e->GetObjectClass(atividade);
    jobject servico = e->CallObjectMethod(atividade, e->GetMethodID(cCtx, "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;"), e->NewStringUTF("clipboard"));
    if (j.erro() || !servico) return;
    jclass cClip = e->FindClass("android/content/ClipData");
    jobject clip = e->CallStaticObjectMethod(cClip,
        e->GetStaticMethodID(cClip, "newPlainText", "(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Landroid/content/ClipData;"),
        e->NewStringUTF("Taverna"), e->NewStringUTF(texto));
    if (j.erro()) return;
    jclass cMan = e->GetObjectClass(servico);
    e->CallVoidMethod(servico, e->GetMethodID(cMan, "setPrimaryClip", "(Landroid/content/ClipData;)V"), clip);
    j.erro();
}

inline void minimizar() {
    Jni j;
    jobject atividade = GetAndroidApp()->activity->clazz;
    jclass c = j.env->GetObjectClass(atividade);
    j.env->CallBooleanMethod(atividade, j.env->GetMethodID(c, "moveTaskToBack", "(Z)Z"), JNI_TRUE);
    j.erro();
}

}  // namespace android_sistema
#endif
