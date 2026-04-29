# Universal9830: plano de upstream do kernel 4.19.325 para 5.10

Este repositório está em **Linux 4.19.325** (vide `Makefile`).

Fazer "upstream" direto para 5.10 em um único commit normalmente não é seguro para dispositivos Android com muitos drivers vendor (SoC, modem, câmera, display, energia). O fluxo recomendado é faseado.

## Estratégia recomendada

1. **Base limpa de referência**
   - Subir uma árvore limpa de Linux 5.10 LTS (ou Android Common Kernel 5.10, dependendo do alvo).
   - Definir baseline de build: `ARCH=arm64`, toolchain, e defconfig inicial.

2. **Migração de configuração (`defconfig`)**
   - Rodar `make olddefconfig` contra 5.10 e registrar símbolos removidos/renomeados.
   - Resolver conflitos de opções que deixaram de existir no 5.10.

3. **Port de drivers vendor por subsistema**
   - clocks/reset/pinctrl
   - PMIC/regulator/power
   - armazenamento (UFS/eMMC)
   - rede/modem
   - display/GPU
   - câmera/media
   - áudio

4. **Device Tree**
   - Revalidar bindings YAML (muitos `compatible` e propriedades mudaram entre 4.19 e 5.10).
   - Corrigir warnings de `dtbs_check`.

5. **API churn (quebras comuns 4.19 -> 5.10)**
   - mudanças em `procfs`, `file_operations`, `timer`, `mm`, `dma-buf`, `iommu`, `irq`.
   - refatorações em subsistemas Android (binder/ion -> dma-buf heaps, dependendo da base).

6. **Validação contínua**
   - boot smoke test
   - SELinux permissivo/enforcing
   - câmera, áudio, modem, Wi‑Fi/BT, sensores
   - suspensão/retomada
   - stress I/O e memória

## Entregáveis por fase

- Fase A: kernel 5.10 compila + boot básico
- Fase B: storage + adb estáveis
- Fase C: conectividade e multimídia
- Fase D: performance/térmica/bateria
- Fase E: hardening + release

## Observação importante

Alterar apenas `VERSION/PATCHLEVEL` no `Makefile` **não** realiza o upstream real; isso apenas muda a string de versão e quebra build/ABI.

