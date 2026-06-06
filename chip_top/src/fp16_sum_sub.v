// ============================================================================
// fp16_sum_sub.v
// Módulo de Suma/Resta Acumulada en formato bfloat16
//
// Operaciones:
//   operation = 0  →  SUM: ACC = ACC + operand
//   operation = 1  →  SUB: ACC = ACC - operand
//
// Formato bfloat16:
//   [15]    : Signo (S)
//   [14:7]  : Exponente (8 bits, sesgo = 127)
//   [6:0]   : Mantisa fraccionaria (7 bits, bit implícito = 1)
//
// Pipeline de 3 ciclos activos desde start hasta done:
//   Ciclo 1 [ST_ALIGN]    : Alinear mantisas por diferencia de exponentes
//   Ciclo 2 [ST_COMPUTE]  : Sumar/restar magnitudes con signo efectivo
//   Ciclo 3 [ST_NORMALIZE]: Normalizar y construir resultado bfloat16
//
// Tecnología: SkyWater sky130A (OpenLane)
// ============================================================================

`timescale 1ns / 1ps

module fp16_sum_sub (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,       // Pulso de 1 ciclo para iniciar
    input  wire        operation,   // 0 = SUM, 1 = SUB
    input  wire [15:0] operand_a,   // Acumulador (bfloat16)
    input  wire [15:0] operand_b,   // Operando entrante (bfloat16)
    output reg  [15:0] result,      // Resultado (bfloat16)
    output reg         done,        // Pulso de 1 ciclo: result es válido
    output reg         overflow,    // 1 si resultado → ±Inf
    output reg         underflow    // 1 si resultado → 0 por cancelación
);

    // =========================================================================
    // Estados FSM
    // =========================================================================
    localparam ST_IDLE      = 2'd0;
    localparam ST_ALIGN     = 2'd1;
    localparam ST_COMPUTE   = 2'd2;
    localparam ST_NORMALIZE = 2'd3;

    reg [1:0] state;

    // =========================================================================
    // Extracción de campos del operando de entrada (combinacional)
    // =========================================================================
    wire        sa      = operand_a[15];
    wire [7:0]  ea      = operand_a[14:7];
    wire        sb_raw  = operand_b[15];
    wire [7:0]  eb      = operand_b[14:7];

    // Signo efectivo de B: SUB invierte el signo → A - B = A + (-B)
    wire sb_eff = sb_raw ^ operation;

    // Mantisas completas 8 bits {1, frac[6:0]} — cero si exponente = 0
    wire [7:0] ma_full = (ea == 8'd0) ? 8'd0 : {1'b1, operand_a[6:0]};
    wire [7:0] mb_full = (eb == 8'd0) ? 8'd0 : {1'b1, operand_b[6:0]};

    // =========================================================================
    // Registros de pipeline entre etapas
    // =========================================================================
    // Etapa ALIGN → COMPUTE
    reg [7:0] al_exp;
    reg [7:0] al_ma;
    reg [7:0] al_mb;
    reg       al_sa;
    reg       al_sb_eff;
    reg       al_b_larger;

    // Etapa COMPUTE → NORMALIZE
    reg [8:0] cm_mant;      // 9 bits: posible carry en [8]
    reg       cm_sign;
    reg [7:0] cm_exp;

    // =========================================================================
    // FSM + Datapath
    // =========================================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state      <= ST_IDLE;
            result     <= 16'd0;
            done       <= 1'b0;
            overflow   <= 1'b0;
            underflow  <= 1'b0;
            al_exp     <= 8'd0;
            al_ma      <= 8'd0;
            al_mb      <= 8'd0;
            al_sa      <= 1'b0;
            al_sb_eff  <= 1'b0;
            al_b_larger<= 1'b0;
            cm_mant    <= 9'd0;
            cm_sign    <= 1'b0;
            cm_exp     <= 8'd0;
        end else begin

            // Pulsos de un solo ciclo
            done      <= 1'b0;
            overflow  <= 1'b0;
            underflow <= 1'b0;

            case (state)

                // -------------------------------------------------------------
                ST_IDLE: begin
                    if (start)
                        state <= ST_ALIGN;
                end

                // -------------------------------------------------------------
                // Ciclo 1: Alinear mantisas
                // El operando con menor exponente se desplaza a la derecha
                // tantos bits como diferencia de exponentes haya.
                // -------------------------------------------------------------
                ST_ALIGN: begin
                    al_sa     <= sa;
                    al_sb_eff <= sb_eff;

                    if (ea >= eb) begin
                        al_exp      <= ea;
                        al_b_larger <= 1'b0;
                        al_ma       <= ma_full;
                        al_mb       <= ((ea - eb) >= 8'd8) ? 8'd0
                                                           : mb_full >> (ea - eb);
                    end else begin
                        al_exp      <= eb;
                        al_b_larger <= 1'b1;
                        al_mb       <= mb_full;
                        al_ma       <= ((eb - ea) >= 8'd8) ? 8'd0
                                                           : ma_full >> (eb - ea);
                    end
                    state <= ST_COMPUTE;
                end

                // -------------------------------------------------------------
                // Ciclo 2: Suma o resta de magnitudes alineadas
                // Si los signos efectivos son iguales → sumar
                // Si son distintos → restar (mayor − menor, siempre ≥ 0)
                // -------------------------------------------------------------
                ST_COMPUTE: begin
                    cm_exp <= al_exp;

                    if (al_sa == al_sb_eff) begin
                        // Mismos signos: suma de magnitudes
                        cm_sign <= al_sa;
                        cm_mant <= {1'b0, al_ma} + {1'b0, al_mb};
                    end else begin
                        // Signos distintos: restar (mayor − menor)
                        if (!al_b_larger) begin
                            cm_sign <= al_sa;
                            cm_mant <= {1'b0, al_ma} - {1'b0, al_mb};
                        end else begin
                            cm_sign <= al_sb_eff;
                            cm_mant <= {1'b0, al_mb} - {1'b0, al_ma};
                        end
                    end
                    state <= ST_NORMALIZE;
                end

                // -------------------------------------------------------------
                // Ciclo 3: Normalizar resultado
                //   cm_mant[8] = 1  → carry (overflow de mantisa): >>1, exp+1
                //   cm_mant[7] = 1  → ya normalizado: fracción = cm_mant[6:0]
                //   cm_mant[7] = 0  → subnormal: <<1 hasta 7 veces, exp−N
                //   cm_mant = 0     → resultado exactamente cero
                // -------------------------------------------------------------
                ST_NORMALIZE: begin
                    begin : norm
                        reg [8:0] m;
                        reg [7:0] e;
                        reg       of_f, uf_f;

                        m    = cm_mant;
                        e    = cm_exp;
                        of_f = 1'b0;
                        uf_f = 1'b0;

                        if (m == 9'd0) begin
                            uf_f = 1'b1;

                        end else begin
                            // Normalizar hacia arriba si hay carry en bit [8]
                            if (m[8]) begin
                                m = m >> 1;
                                if (e >= 8'hFE) begin
                                    of_f = 1'b1;
                                    e    = 8'hFF;
                                end else
                                    e = e + 8'd1;
                            end

                            // Normalizar hacia abajo: llevar bit implícito a [7]
                            // Máximo 7 iteraciones para bfloat16
                            if (!of_f) begin
                                if (!m[7]) begin m = m<<1; if(e>0) e=e-1; else uf_f=1; end
                                if (!m[7]) begin m = m<<1; if(e>0) e=e-1; else uf_f=1; end
                                if (!m[7]) begin m = m<<1; if(e>0) e=e-1; else uf_f=1; end
                                if (!m[7]) begin m = m<<1; if(e>0) e=e-1; else uf_f=1; end
                                if (!m[7]) begin m = m<<1; if(e>0) e=e-1; else uf_f=1; end
                                if (!m[7]) begin m = m<<1; if(e>0) e=e-1; else uf_f=1; end
                                if (!m[7]) begin m = m<<1; if(e>0) e=e-1; else uf_f=1; end
                                if (!m[7]) uf_f = 1;
                            end
                        end

                        // Construir resultado bfloat16
                        // Bit implícito m[7] se descarta; fracción = m[6:0]
                        if (uf_f || e == 8'd0) begin
                            result    <= 16'h0000;
                            underflow <= 1'b1;
                        end else if (of_f || e == 8'hFF) begin
                            result   <= {cm_sign, 8'hFF, 7'd0};  // ±Inf
                            overflow <= 1'b1;
                        end else begin
                            result <= {cm_sign, e, m[6:0]};
                        end
                    end

                    done  <= 1'b1;
                    state <= ST_IDLE;
                end

                default: state <= ST_IDLE;

            endcase
        end
    end

endmodule
