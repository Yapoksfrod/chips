// ============================================================================
// chip_top.v  —  Chip aritmético bfloat16 con interfaz SPI
//
// Operaciones soportadas (bits [7:4] del comando):
//   0000 (SUM) : ACC = ACC + operand
//   1000 (SUB) : ACC = ACC - operand
//   0001 (MPY) : ACC = ACC * operand
//   0010 (DIV) : ACC = ACC / operand
//
// Protocolo SPI (Modo 0, CPOL=0, CPHA=0, LSB primero, tramas de 16 bits):
//   1ª palabra MOSI → Comando de 16 bits:
//     bits [15:8] : reservado (X)
//     bits  [7:4] : código de operación
//     bits  [3:0] : inicialización del acumulador
//                     0000 → ACC = 0.0  (0x0000)
//                     0001 → ACC = 1.0  (0x3F80)
//                     001X → sin cambio
//   Palabras siguientes → operandos bfloat16 en flujo continuo
//   MISO → retorna el valor del ACC vigente durante cada trama
//
// Tecnología objetivo: SkyWater sky130A (OpenLane)
// ============================================================================

`timescale 1ns / 1ps

module chip_top (
    input  wire clk,    // Reloj global del chip (ej. 50 MHz)
    input  wire rst,    // Reset asincrónico activo en alto
    input  wire sclk,   // Reloj SPI generado por el Master
    input  wire ss,     // Chip Select (activo en bajo)
    input  wire mosi,   // Master-Out Slave-In
    output reg  miso    // Master-In Slave-Out
);

    // =========================================================================
    // Códigos de operación — bits [7:4] del comando
    // =========================================================================
    localparam OP_SUM = 4'b0000;
    localparam OP_SUB = 4'b1000;
    localparam OP_MPY = 4'b0001;
    localparam OP_DIV = 4'b0010;

    // =========================================================================
    // Estados de la FSM principal
    // =========================================================================
    localparam ST_IDLE       = 3'd0;
    localparam ST_RX_CMD     = 3'd1;
    localparam ST_DECODE     = 3'd2;
    localparam ST_RX_OPERAND = 3'd3;
    localparam ST_EXECUTE    = 3'd4;
    localparam ST_WAIT_DONE  = 3'd5;

    // =========================================================================
    // Registros internos
    // =========================================================================
    reg [2:0]  state;
    reg [15:0] acc_reg;       // Acumulador principal
    reg [15:0] cmd_reg;       // Comando recibido
    reg [15:0] operand_reg;   // Operando actual
    reg [15:0] shift_in;      // Registro de desplazamiento de entrada (MOSI)
    reg [15:0] shift_out;     // Registro de desplazamiento de salida  (MISO)
    reg [4:0]  bit_count;     // Contador de bits (0..15)
    reg [3:0]  op_reg;        // Operación almacenada — bits [7:4] del cmd

    // =========================================================================
    // Sincronizadores CDC (doble FF): dominio SPI → dominio clk
    // =========================================================================
    reg sclk_s0, sclk_s1;
    reg ss_s0,   ss_s1;
    reg mosi_s0, mosi_s1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sclk_s0 <= 1'b0; sclk_s1 <= 1'b0;
            ss_s0   <= 1'b1; ss_s1   <= 1'b1;
            mosi_s0 <= 1'b0; mosi_s1 <= 1'b0;
        end else begin
            sclk_s0 <= sclk;    sclk_s1 <= sclk_s0;
            ss_s0   <= ss;      ss_s1   <= ss_s0;
            mosi_s0 <= mosi;    mosi_s1 <= mosi_s0;
        end
    end

    // Detección de flancos del SCLK sincronizado
    wire sclk_rise = (sclk_s1 == 1'b0) && (sclk_s0 == 1'b1);
    wire sclk_fall = (sclk_s1 == 1'b1) && (sclk_s0 == 1'b0);

    // =========================================================================
    // Señales hacia/desde el módulo SUM/SUB (fp16_sum_sub)
    // =========================================================================
    reg        ss_start;
    wire       ss_done;
    wire [15:0] ss_result;

    fp16_sum_sub my_sum_sub (
        .clk       (clk),
        .rst       (rst),
        .start     (ss_start),
        .operation (op_reg[3]),     // 0 → SUM, 1 → SUB
        .operand_a (acc_reg),
        .operand_b (operand_reg),
        .result    (ss_result),
        .done      (ss_done),
        .overflow  (),
        .underflow ()
    );

    // =========================================================================
    // Señales hacia/desde el módulo MPY (fpmul)
    // =========================================================================
    reg        mpy_en;
    wire       mpy_ready;
    wire [15:0] mpy_result;

    fpmul my_mul (
        .x1    (acc_reg),
        .x2    (operand_reg),
        .y     (mpy_result),
        .clk   (clk),
        .rst   (rst),
        .en    (mpy_en),
        .ready (mpy_ready)
    );

    // =========================================================================
    // Señales hacia/desde el módulo DIV (fractional_divider)
    //
    // El divisor fraccional opera con mantisas de N=8 bits (1 implícito + 7
    // fraccionarios), separadas del número bfloat16 completo.
    // El resultado vuelve a ensamblarse con el exponente ajustado.
    // =========================================================================
    reg         div_start;
    wire        div_done;
    wire [7:0]  div_quotient;   // mantisa resultante (8 bits: bit impl. + 7 frac)

    // Mantisas con bit implícito (cero si exponente = 0)
    wire [7:0] div_dividend = (acc_reg[14:7]    == 8'd0) ? 8'd0 : {1'b1, acc_reg[6:0]};
    wire [7:0] div_divisor  = (operand_reg[14:7] == 8'd0) ? 8'd0 : {1'b1, operand_reg[6:0]};

    fractional_divider #(.N(8)) my_divider (
        .clk      (clk),
        .rst      (rst),
        .start    (div_start),
        .dividend (div_dividend),
        .divisor  (div_divisor),
        .quotient (div_quotient),
        .done     (div_done)
    );

    // Exponente del resultado de la división: exp_A - exp_B + 127 (sesgo)
    // Se limita a [1, 254] para evitar valores especiales (0 = subnormal, 255 = Inf/NaN)
    wire [8:0] div_exp_raw = {1'b0, acc_reg[14:7]} - {1'b0, operand_reg[14:7]} + 9'd127;
    wire [7:0] div_exp     = (div_exp_raw[8] || div_exp_raw == 9'd0) ? 8'd0 :
                             (div_exp_raw >= 9'hFF)                  ? 8'hFE :
                              div_exp_raw[7:0];
    // Signo del resultado de la división
    wire div_sign = acc_reg[15] ^ operand_reg[15];

    // =========================================================================
    // FSM principal (dominio clk)
    // =========================================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state       <= ST_IDLE;
            acc_reg     <= 16'h0000;
            cmd_reg     <= 16'h0000;
            operand_reg <= 16'h0000;
            shift_in    <= 16'h0000;
            shift_out   <= 16'h0000;
            bit_count   <= 5'd0;
            op_reg      <= 4'd0;
            ss_start    <= 1'b0;
            mpy_en      <= 1'b0;
            div_start   <= 1'b0;
            miso        <= 1'b0;
        end else begin

            // -----------------------------------------------------------------
            // Reset de la FSM cuando el Master desactiva SS
            // -----------------------------------------------------------------
            if (ss_s1) begin
                state     <= ST_IDLE;
                bit_count <= 5'd0;
                ss_start  <= 1'b0;
                mpy_en    <= 1'b0;
                div_start <= 1'b0;
                miso      <= 1'b0;
            end else begin

                // Pulsos de un solo ciclo (se limpian por defecto)
                ss_start  <= 1'b0;
                mpy_en    <= 1'b0;
                div_start <= 1'b0;

                case (state)

                    // ---------------------------------------------------------
                    ST_IDLE: begin
                        bit_count <= 5'd0;
                        shift_out <= acc_reg;   // Pre-cargar ACC para MISO
                        state     <= ST_RX_CMD;
                    end

                    // ---------------------------------------------------------
                    // Recepción del comando (16 bits, LSB primero)
                    // Flanco subida → capturar MOSI en shift_in
                    // Flanco bajada → volcar shift_out[0] en MISO
                    // ---------------------------------------------------------
                    ST_RX_CMD: begin
                        if (sclk_rise)
                            shift_in <= {mosi_s1, shift_in[15:1]};

                        if (sclk_fall) begin
                            miso      <= shift_out[0];
                            shift_out <= {1'b0, shift_out[15:1]};
                            bit_count <= bit_count + 5'd1;
                            if (bit_count == 5'd15)
                                state <= ST_DECODE;
                        end
                    end

                    // ---------------------------------------------------------
                    // Decodificación: inicializar ACC y almacenar operación
                    // ---------------------------------------------------------
                    ST_DECODE: begin
                        cmd_reg   <= shift_in;
                        op_reg    <= shift_in[7:4];
                        bit_count <= 5'd0;
                        shift_out <= acc_reg;

                        // Inicialización del acumulador según bits [3:0]
                        case (shift_in[3:0])
                            4'b0000: acc_reg <= 16'h0000;   // ACC = 0.0
                            4'b0001: acc_reg <= 16'h3F80;   // ACC = 1.0 (bfloat16)
                            default: acc_reg <= acc_reg;    // 001X → sin cambio
                        endcase

                        // Validar opcode; ignorar instrucciones no implementadas
                        if (shift_in[7:4] == OP_SUM ||
                            shift_in[7:4] == OP_SUB ||
                            shift_in[7:4] == OP_MPY ||
                            shift_in[7:4] == OP_DIV) begin
                            state <= ST_RX_OPERAND;
                        end else begin
                            state <= ST_IDLE;
                        end
                    end

                    // ---------------------------------------------------------
                    // Recepción de un operando bfloat16 (16 bits, LSB primero)
                    // MISO transmite el ACC de la iteración anterior
                    // ---------------------------------------------------------
                    ST_RX_OPERAND: begin
                        if (sclk_rise)
                            shift_in <= {mosi_s1, shift_in[15:1]};

                        if (sclk_fall) begin
                            miso      <= shift_out[0];
                            shift_out <= {1'b0, shift_out[15:1]};
                            bit_count <= bit_count + 5'd1;
                            if (bit_count == 5'd15) begin
                                operand_reg <= shift_in;
                                bit_count   <= 5'd0;
                                state       <= ST_EXECUTE;
                            end
                        end
                    end

                    // ---------------------------------------------------------
                    // Lanzar la operación aritmética correspondiente
                    // ---------------------------------------------------------
                    ST_EXECUTE: begin
                        case (op_reg)
                            OP_SUM,
                            OP_SUB: ss_start  <= 1'b1;
                            OP_MPY: mpy_en    <= 1'b1;
                            OP_DIV: div_start <= 1'b1;
                            default: ;
                        endcase
                        state <= ST_WAIT_DONE;
                    end

                    // ---------------------------------------------------------
                    // Esperar señal "done" del módulo activo;
                    // actualizar ACC y preparar shift_out para la siguiente trama
                    // ---------------------------------------------------------
                    ST_WAIT_DONE: begin
                        case (op_reg)

                            OP_SUM,
                            OP_SUB: begin
                                if (ss_done) begin
                                    acc_reg   <= ss_result;
                                    shift_out <= ss_result;
                                    state     <= ST_RX_OPERAND;
                                end
                            end

                            OP_MPY: begin
                                if (mpy_ready) begin
                                    acc_reg   <= mpy_result;
                                    shift_out <= mpy_result;
                                    state     <= ST_RX_OPERAND;
                                end
                            end

                            OP_DIV: begin
                                if (div_done) begin
                                    // Reensamblar bfloat16: signo + exponente ajustado + mantisa (sin bit implícito)
                                    acc_reg   <= {div_sign, div_exp, div_quotient[6:0]};
                                    shift_out <= {div_sign, div_exp, div_quotient[6:0]};
                                    state     <= ST_RX_OPERAND;
                                end
                            end

                            default: state <= ST_IDLE;
                        endcase
                    end

                    default: state <= ST_IDLE;

                endcase
            end
        end
    end

endmodule
