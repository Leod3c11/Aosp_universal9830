# Universal9830: upstream 4.19.325 -> 5.10 (plano + execução inicial)

Este repositório está em **Linux 4.19.325** (`Makefile`).

## O que já foi colocado em prática

Foi adicionado um bootstrap executável para iniciar a migração de configuração e gerar artefatos objetivos:

```bash
tools/upstream/start_5_10_upstream.sh
```

O script:
- baixa/atualiza uma referência `linux-5.10.y` oficial;
- normaliza o `universal9830_defconfig` da árvore atual (4.19);
- roda `olddefconfig` em 5.10 usando essa configuração;
- gera delta de config (`diffconfig`) e lista de símbolos removidos/desabilitados.

## Como rodar

```bash
# do root do repo
OUT_DIR=$PWD/out/upstream-5.10 \
BASE_DEFCONFIG=universal9830_defconfig \
ARCH=arm64 \
./tools/upstream/start_5_10_upstream.sh
```

Artefatos esperados em `out/upstream-5.10/`:
- `universal9830_defconfig.4.19.normalized.config`
- `universal9830_defconfig.5.10.olddefconfig.config`
- `universal9830_defconfig.diffconfig.txt`
- `symbols.removed-or-disabled.txt`

## Estratégia recomendada (continuação)

1. **Base limpa de referência**
   - Linux 5.10 LTS ou Android Common Kernel 5.10, conforme alvo do device.

2. **Migração de configuração (`defconfig`)**
   - Revisar `*.diffconfig.txt` e classificar símbolos por subsistema.

3. **Port de drivers vendor por bloco**
   - clock/reset/pinctrl
   - PMIC/regulator/power
   - storage (UFS/eMMC)
   - modem/rede
   - display/GPU
   - câmera/media
   - áudio

4. **Device Tree e bindings**
   - executar `dtbs_check` no 5.10 e corrigir bindings incompatíveis.

5. **Validação contínua**
   - boot, adb, SELinux, câmera, áudio, modem, Wi‑Fi/BT, sensores, suspend/resume.

## Observação

Trocar apenas `VERSION/PATCHLEVEL` no `Makefile` não faz upstream real; isso só altera string de versão e costuma quebrar ABI/build.
