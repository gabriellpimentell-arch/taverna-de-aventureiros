// Partes do atualizador que dependem do sistema operacional.
// No Windows usa a WinINet (já vem com o sistema); nas outras plataformas,
// por enquanto, não baixa nada.
#pragma once

#include <filesystem>
#include <string>

namespace atualizador {

// Caminho completo do executável que está rodando.
std::filesystem::path caminhoExecutavel();

// Baixa uma URL inteira para a memória. Devolve false se falhar.
bool baixar(const std::string& url, std::string& saida, int limiteMs);

// Coloca o executável novo no lugar do atual e abre o novo.
// Devolve true se o novo foi aberto (aí o atual deve fechar).
bool trocarExecutavelEReiniciar(const std::filesystem::path& atual, const std::filesystem::path& novo);

// Apaga a cópia antiga deixada pela última atualização.
void limparVersaoAntiga(const std::filesystem::path& atual);

}  // namespace atualizador
