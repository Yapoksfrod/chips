# chip_top — Procesador Aritmético bfloat16 con Interfaz SPI

**Tecnología:** SkyWater sky130A · **Herramienta:** OpenLane 2 · **Reloj:** 50 MHz

---

## 1. Propósito del módulo

`chip_top` es un chip aritmético que implementa operaciones de suma, resta, multiplicación y división acumulada sobre números en formato **bfloat16** (Brain Floating Point de 16 bits: 1 bit de signo, 8 de exponente, 7 de mantisa). El chip expone una **interfaz SPI** (Modo 0, CPOL=0, CPHA=0) de 16 bits por trama, con transmisión LSB primero.

El propósito principal es demostrar la integración de unidades aritméticas de punto flotante en un flujo de diseño digital completo (RTL → síntesis → Place & Route → layout GDS) sobre PDK de código abierto sky130A.

---

## 2. Diagrama de bloques y diagrama de estados

### Diagrama de bloques

```
                         ┌─────────────────────────────────────────────────────┐
         clk ───────────►│                     chip_top                        │
         rst ───────────►│                                                     │
                         │   ┌──────────────┐    ┌────────────────────────┐   │
  sclk ─────────────────►│   │  CDC (2-FF)  │    │  Registro de entrada   │   │
  ss ───────────────────►│   │  sclk_s0/s1  │    │  shift_in  [15:0]      │   │
  mosi ──────────────────►│   │  ss_s0/s1    │    │  bit_count [4:0]       │   │
                         │   │  mosi_s0/s1  │    └──────────┬─────────────┘   │
  miso ◄─────────────────│   └──────┬───────┘               │                 │
                         │          │ sclk_rise/fall         │                 │
                         │          ▼                        ▼                 │
                         │   ┌──────────────────────────────────────────┐     │
                         │   │               FSM Principal               │     │
                         │   │  IDLE → RX_CMD → DECODE → RX_OPERAND     │     │
                         │   │          → EXECUTE → WAIT_DONE           │     │
                         │   └──┬──────────┬──────────┬─────────────────┘     │
                         │      │          │          │                        │
                         │      ▼          ▼          ▼                        │
                         │  ┌────────┐ ┌──────┐ ┌─────────┐                  │
                         │  │fp16_   │ │fpmul │ │frac_div │                  │
                         │  │sum_sub │ │(MPY) │ │  (DIV)  │                  │
                         │  │(SUM/   │ │      │ │  N=8    │                  │
                         │  │ SUB)   │ │      │ │         │                  │
                         │  └───┬────┘ └──┬───┘ └────┬────┘                  │
                         │      └─────────┴──────────┘                        │
                         │                    │                                │
                         │             ┌──────▼──────┐                        │
                         │             │  acc_reg    │ ◄── shift_out → MISO   │
                         │             │  [15:0]     │                        │
                         │             └─────────────┘                        │
                         └─────────────────────────────────────────────────────┘
```

### Diagrama de estados de la FSM

```
                    rst / ss=1
                        │
                        ▼
                   ┌─────────┐
              ┌───►│  IDLE   │◄─────────────────────────────┐
              │    └────┬────┘                               │ opcode inválido
              │         │ ss=0                               │
              │         ▼                                    │
              │    ┌─────────┐  sclk_fall × 16              │
              │    │ RX_CMD  ├──────────────────────────────►│
              │    └────┬────┘                               │
              │         │ bit_count == 15                    │
              │         ▼                                    │
              │    ┌─────────┐                               │
              │    │ DECODE  ├───────────────────────────────┘
              │    └────┬────┘  decodifica opcode + init ACC
              │         │ opcode válido
              │         ▼
  siguiente   │    ┌────────────┐  sclk_fall × 16
  operando    │    │ RX_OPERAND ├──────────────────────────┐
       ◄──────┤    └────────────┘                          │ bit_count == 15
              │                                            ▼
              │    ┌──────────┐                    ┌──────────────┐
              │    │  WAIT    │◄───────────────────│   EXECUTE    │
              │    │  DONE    │  lanza operación   └──────────────┘
              │    └────┬─────┘
              │         │ done → acc_reg ← resultado
              └─────────┘        shift_out ← resultado
```

---

## 3. Cobertura de la especificación

### Implementado y verificado

| Instrucción | Código | Estado |
|---|---|---|
| SUM — sumatoria acumulada | `0000` | ✅ Implementado y verificado |
| SUB — resta acumulada | `1000` | ✅ Implementado y verificado |
| MPY — multiplicación acumulada | `0001` | ✅ Implementado y verificado |
| DIV — división acumulada | `0010` | ✅ Implementado y verificado |
| Inicialización ACC = 0.0 | `init=0000` | ✅ Funciona correctamente |
| Inicialización ACC = 1.0 | `init=0001` | ✅ Funciona correctamente |
| Interfaz SPI Modo 0, LSB primero | — | ✅ Con sincronizadores CDC doble FF |
| Retorno de ACC en MISO por trama | — | ✅ Implementado |

### Pendiente / no implementado

| Instrucción | Código | Observación |
|---|---|---|
| MAC — Multiplicación-Acumulación | `0011` | ❌ No implementado |
| MAS — Multiplicación-Sustracción | `1011` | ❌ No implementado |
| Inicialización `001X` sin cambio de ACC | `0010`/`0011` | ⚠️ El valor del acumulador no se preserva correctamente entre sesiones SPI |
| Manejo de NaN, Inf, subnormales | — | ❌ No implementado |

---

## 4. Vista RTL del diseño

Vista RTL generada con Yosys sobre el módulo `chip_top` completo:

![Vista RTL](vista_rtl.jpeg)

```bash
yosys -p "
  read_verilog src/chip_top.v src/fp16_sum_sub.v src/fpmul.v
               src/rounder.v src/myreg.v src/fractional_divider.v;
  hierarchy -check -top chip_top;
  proc; opt; flatten;
  show -format dot -prefix rtl_view chip_top
"
dot -Tpng rtl_view.dot -o rtl_view.png
```

---

## 5. Simulación comportamental

Simulación realizada con **Icarus Verilog** sobre `tb/tb_chip_top.v`. Vista general de todas las operaciones:

![Trama completa — todas las operaciones](trama_completa.jpeg)

En `acc_reg` se observa la secuencia completa: SUM → SUB → MPY → DIV → caso excepcional.

### Protocolo SPI

```
Trama 0:  CMD  (opcode + init ACC)  →  MISO retorna ACC previo
Trama 1:  OP1  (operando bfloat16)  →  MISO retorna ACC inicializado
Trama N:  OPn  (operando bfloat16)  →  MISO retorna resultado anterior
```

### Caso 1 — SUM: `0 + 1.0 + 2.0 = 3.0`

Comando `0x0001` (SUM, init ACC=0). `acc_reg`: `0x0000` → `0x3F80` (1.0) → `0x4040` (3.0) ✅

![SUM: 0 + 1.0 + 2.0 = 3.0](suma%200%20(0000)%201%20(3F80)%20+%202%20(4000)%20=%203%20(4040).jpeg)

### Caso 2 — SUB: `0 − 1.0 − 2.0 = −3.0`

Comando `0x0080` (SUB, init ACC=0). `acc_reg`: `0x0000` → `0xBF80` (−1.0) → `0xC040` (−3.0) ✅

![SUB: 0 - 1.0 - 2.0 = -3.0](resta%200%20-%201%20-%202%20=%20-3%20(C040).jpeg)

### Caso 3 — MPY: `1.0 × 2.0 × 3.0 = 6.0`

Comando `0x0011` (MPY, init ACC=1). `acc_reg`: `0x3F80` → `0x4000` (2.0) → `0x40C0` (6.0) ✅

![MPY: 1.0 x 2.0 x 3.0 = 6.0](multiplicacion%20123%20=%206%20(40C0).jpeg)

### Caso 4 — DIV: `1.0 / 2.0 = 0.5`

Comando `0x0021` (DIV, init ACC=1). `acc_reg`: `0x3F80` → `0x3F00` (0.5) ✅

> **Nota:** el módulo `fractional_divider` original tenía un bug en el ancho del contador (`$clog2(N)-1` bits en lugar de `$clog2(N)` bits), lo que impedía que la señal `done` se activara con N=8. Corregido cambiando `reg [$clog2(N)-1:0] counter` por `reg [$clog2(N):0] counter`.

![DIV: 1.0 / 2.0 = 0.5](division%2012%20=%200.5%20(3F00).jpeg)

### Caso excepcional — Inicialización `001X`

Se intentó retener ACC=0.5 y sumarle 1.0 (esperando 1.5 = `0x3FC0`). El chip produjo `0x7EBF` ≈ 1.27×10³⁸. El valor del acumulador no se preserva correctamente entre sesiones SPI consecutivas. **Este caso queda pendiente.**

![Caso excepcional: 0x7EBF](error%207EBF%20es%20valor%20estupidamente%20grande.jpeg)

---

## 6. Simulación funcional post-layout

La simulación post-layout se realizó con el netlist generado por OpenLane (`final/nl/chip_top.nl.v`) compilado contra las celdas sky130, verificando la operación SUM con resultado correcto `0x4040` = 3.0.

### Diagrama de temporización estilo hoja de datos — Operación SUM

```
SS   ‾‾‾‾‾|___________________________|‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

SCLK      |‾|_|‾|_ ... _|‾|_|         |‾|_|‾|_ ... _|‾|_|
           └──── Trama CMD (16b) ────┘  └── Trama OP1 (16b) ─

MOSI      [     CMD: 0x0001 (SUM)    ]  [   OP1: 0x3F80 (1.0)  ]

MISO      [   ACC_prev = 0x0000      ]  [   ACC = 0x3F80 (1.0)  ]
```

| Parámetro | Valor |
|---|---|
| `t_setup` MOSI → SCLK↑ | 80 ns |
| `t_hold` SCLK↑ → MOSI | 20 ns |
| `t_valid` SCLK↓ → MISO válido | < 1 ciclo SCLK |
| Periodo SCLK mínimo | 200 ns (5 MHz) |
| Trama completa (16 bits) | 3.2 µs a 5 MHz |

---

## 7. Caracterización de área y temporización

### Área (síntesis Yosys)

![Métricas de área — síntesis](metrica_area_1.jpeg)

![Métricas de área — resultado final](metrica_area_2.jpeg)

| Métrica | Valor |
|---|---|
| Área total del chip (die area) | 35,424 µm² |
| Área del core | 29,402 µm² |
| Área de instancias estándar | 19,758 µm² |
| Número de celdas estándar | 2,458 |
| Celdas secuenciales | 185 |

### Temporización (post-P&R, corner típico nom_tt_025C_1v80)

| Métrica | Valor |
|---|---|
| Periodo de reloj | 20.0 ns (50 MHz) |
| WNS setup | **0.0 ns** — timing cerrado ✅ |
| TNS setup | **0.0 ns** — sin violaciones ✅ |
| Frecuencia máxima | **50.0 MHz** |
| Potencia total | ~0.97 mW |

> En el corner lento (SS, 100°C, 1.6V) el WNS es −0.51 ns. Para producción se recomendaría reducir el reloj a ~45 MHz.

---

## 8. Layout final

Layout visualizado en KLayout con el GDS generado por OpenLane (paso `56-magic-streamout`):

![Layout final en KLayout — chip_top.gds](layout.jpeg)

El layout muestra la distribución de 2,458 celdas estándar sky130 con rutas en capas li1, met1 y met2, y anillos de alimentación VDD/GND.

```bash
klayout runs/RUN_*/results/final/chip_top.gds \
    -e -nn $PDK_ROOT/sky130A/libs.tech/klayout/sky130A.lyt
```

---

## Estructura del repositorio

```
chip_top/
├── src/
│   ├── chip_top.v
│   ├── fp16_sum_sub.v
│   ├── fpmul.v
│   ├── rounder.v
│   ├── myreg.v
│   └── fractional_divider.v   ← bug contador corregido
├── tb/
│   └── tb_chip_top.v
├── config.json
├── constraints.sdc
├── rtl_view.png
└── runs/
    └── RUN_2026-06-06_06-39-23/
        ├── 06-yosys-synthesis/reports/stat.rpt
        ├── 54-openroad-stapostpnr/
        └── final/gds/chip_top.gds
```

---

## Referencias

- [bfloat16-riscv — Módulos aritméticos fuente](https://github.com/jimarinh/bfloat16-riscv)
- [OpenLane 2 Documentation](https://openlane2.readthedocs.io)
- [SkyWater sky130A PDK](https://skywater-pdk.readthedocs.io)
