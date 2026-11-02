"""Embute os scripts e as fontes no final do executável.

Uso: python tools/empacotar.py <exe compilado> <exe final> <versão>

O motor (src/main.cpp, função lerPacote) lê esse pacote quando abre.
Formato: "TAVPAK01", quantidade (u32) e, para cada arquivo, tamanho do nome
(u32), nome, tamanho dos dados (u32), dados. No fim: tamanho do pacote (u64)
e "TAVPAKFT".
"""

import struct
import sys
from pathlib import Path


def main() -> None:
    exe, saida, versao = sys.argv[1], sys.argv[2], sys.argv[3]
    raiz = Path(__file__).resolve().parent.parent

    arquivos = []
    for pasta in ("scripts", "assets"):
        for p in sorted((raiz / pasta).rglob("*")):
            if p.is_file():
                arquivos.append((p.relative_to(raiz).as_posix(), p.read_bytes()))
    arquivos.append(("versao.txt", versao.encode()))

    pacote = bytearray(b"TAVPAK01")
    pacote += struct.pack("<I", len(arquivos))
    for nome, dados in arquivos:
        n = nome.encode("utf-8")
        pacote += struct.pack("<I", len(n)) + n
        pacote += struct.pack("<I", len(dados)) + dados

    final = Path(exe).read_bytes() + bytes(pacote) + struct.pack("<Q", len(pacote)) + b"TAVPAKFT"
    Path(saida).write_bytes(final)
    print(f"{len(arquivos)} arquivos embutidos ({len(pacote) // 1024} KB), versão {versao}")


if __name__ == "__main__":
    main()
