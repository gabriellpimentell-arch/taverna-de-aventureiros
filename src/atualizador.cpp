#include "atualizador.h"

namespace fs = std::filesystem;

#if defined(_WIN32)

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <wininet.h>

namespace atualizador {

fs::path caminhoExecutavel() {
    wchar_t buf[MAX_PATH * 4];
    DWORD n = GetModuleFileNameW(nullptr, buf, (DWORD)(sizeof(buf) / sizeof(buf[0])));
    if (n == 0) return {};
    return fs::path(std::wstring(buf, n));
}

bool baixar(const std::string& url, std::string& saida, int limiteMs) {
    saida.clear();
    HINTERNET net = InternetOpenA("TavernaDeAventureiros", INTERNET_OPEN_TYPE_PRECONFIG, nullptr, nullptr, 0);
    if (!net) return false;
    DWORD limite = (DWORD)limiteMs;
    InternetSetOptionA(net, INTERNET_OPTION_CONNECT_TIMEOUT, &limite, sizeof(limite));
    InternetSetOptionA(net, INTERNET_OPTION_RECEIVE_TIMEOUT, &limite, sizeof(limite));
    InternetSetOptionA(net, INTERNET_OPTION_SEND_TIMEOUT, &limite, sizeof(limite));

    DWORD flags = INTERNET_FLAG_RELOAD | INTERNET_FLAG_NO_CACHE_WRITE | INTERNET_FLAG_PRAGMA_NOCACHE |
                  INTERNET_FLAG_NO_UI | INTERNET_FLAG_NO_COOKIES;
    HINTERNET req = InternetOpenUrlA(net, url.c_str(), nullptr, 0, flags, 0);
    bool ok = false;
    if (req) {
        DWORD status = 0, tam = sizeof(status);
        if (HttpQueryInfoA(req, HTTP_QUERY_STATUS_CODE | HTTP_QUERY_FLAG_NUMBER, &status, &tam, nullptr) &&
            status == 200) {
            char buf[16384];
            DWORD lido = 0;
            ok = true;
            for (;;) {
                if (!InternetReadFile(req, buf, sizeof(buf), &lido)) {
                    ok = false;
                    break;
                }
                if (lido == 0) break;
                saida.append(buf, lido);
            }
        }
        InternetCloseHandle(req);
    }
    InternetCloseHandle(net);
    return ok;
}

bool trocarExecutavelEReiniciar(const fs::path& atual, const fs::path& novo) {
    std::wstring a = atual.wstring();
    std::wstring velho = a + L".velho";
    std::wstring n = novo.wstring();

    // O Windows deixa renomear um .exe que está rodando, mas não apagar.
    if (!MoveFileExW(a.c_str(), velho.c_str(), MOVEFILE_REPLACE_EXISTING)) return false;
    if (!MoveFileExW(n.c_str(), a.c_str(), MOVEFILE_REPLACE_EXISTING)) {
        MoveFileExW(velho.c_str(), a.c_str(), 0);  // desfaz
        return false;
    }

    STARTUPINFOW si{};
    si.cb = sizeof(si);
    PROCESS_INFORMATION pi{};
    std::wstring linha = L"\"" + a + L"\"";
    std::wstring pasta = atual.parent_path().wstring();
    if (!CreateProcessW(a.c_str(), linha.data(), nullptr, nullptr, FALSE, 0, nullptr, pasta.c_str(), &si, &pi)) {
        return false;  // o .exe novo já está no lugar: vale na próxima vez que abrir
    }
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    return true;
}

void limparVersaoAntiga(const fs::path& atual) {
    std::wstring velho = atual.wstring() + L".velho";
    // o processo antigo pode ainda estar fechando: tenta por um instante
    for (int i = 0; i < 10; i++) {
        if (DeleteFileW(velho.c_str()) || GetLastError() == ERROR_FILE_NOT_FOUND) return;
        Sleep(100);
    }
}

}  // namespace atualizador

#elif defined(__ANDROID__)

#include "android_sistema.h"

namespace atualizador {

fs::path caminhoExecutavel() { return {}; }
bool baixar(const std::string& url, std::string& saida, int limiteMs) { return android_sistema::baixar(url, saida, limiteMs); }
bool trocarExecutavelEReiniciar(const fs::path&, const fs::path&) { return false; }
void limparVersaoAntiga(const fs::path&) {}

}  // namespace atualizador

#else  // outras plataformas

namespace atualizador {

fs::path caminhoExecutavel() {
    std::error_code ec;
    fs::path p = fs::read_symlink("/proc/self/exe", ec);
    return ec ? fs::path() : p;
}

bool baixar(const std::string&, std::string& saida, int) {
    saida.clear();
    return false;
}

bool trocarExecutavelEReiniciar(const fs::path&, const fs::path&) { return false; }

void limparVersaoAntiga(const fs::path&) {}

}  // namespace atualizador

#endif
