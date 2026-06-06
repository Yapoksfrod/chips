// ============================================================================
// tb_chip_top.v  —  Testbench para chip_top unificado (SUM/SUB/MPY/DIV)
//
// Prueba las 4 operaciones usando valores bfloat16:
//   1.0  = 0x3F80
//   2.0  = 0x4000
//   3.0  = 0x4040
//   4.0  = 0x4080
//   0.5  = 0x3F00
//
// Protocolo SPI simulado:
//   - Modo 0 (CPOL=0, CPHA=0), LSB primero, tramas de 16 bits
//   - SS activo en bajo
// ============================================================================

`timescale 1ns / 1ps

module tb_chip_top;

    // =========================================================================
    // Señales del DUT
    // =========================================================================
    reg  clk;
    reg  rst;
    reg  sclk;
    reg  ss;
    reg  mosi;
    wire miso;

    // =========================================================================
    // Instancia del DUT
    // =========================================================================
    chip_top dut (
        .clk  (clk),
        .rst  (rst),
        .sclk (sclk),
        .ss   (ss),
        .mosi (mosi),
        .miso (miso)
    );

    // =========================================================================
    // Generación de reloj principal (50 MHz → periodo 20 ns)
    // =========================================================================
    initial clk = 0;
    always #10 clk = ~clk;

    // SCLK SPI a ~5 MHz (periodo 200 ns, mucho más lento que clk)
    initial sclk = 0;

    // =========================================================================
    // Registro para capturar respuesta MISO
    // =========================================================================
    reg [15:0] miso_capture;

    // =========================================================================
    // Tarea: enviar/recibir una trama SPI de 16 bits (LSB primero)
    // =========================================================================
    task spi_transfer;
        input  [15:0] data_in;
        output [15:0] data_out;
        integer i;
        begin
            data_out = 16'd0;
            for (i = 0; i < 16; i = i + 1) begin
                // Datos en MOSI se colocan antes del flanco de subida
                mosi = data_in[i];          // LSB primero
                #80;                        // setup time
                sclk = 1;                   // Flanco de subida  → DUT captura MOSI
                #20;
                data_out = {miso, data_out[15:1]};  // Capturar MISO (LSB primero)
                sclk = 0;                   // Flanco de bajada → DUT actualiza MISO
                #100;
            end
        end
    endtask

    // =========================================================================
    // Tarea: ejecutar una operación completa (cmd + N operandos)
    // =========================================================================
    task run_operation;
        input [15:0] cmd;
        input [15:0] op1;
        input [15:0] op2;
        input [15:0] op3;
        input integer n_ops;
        input [63:0] test_name;
        reg [15:0] rx;
    begin
        $display("\n--- %s ---", test_name);
        ss = 0; #50;

        // Trama 0: Comando
        spi_transfer(cmd, rx);
        $display("  CMD=0x%04X  MISO(ACC_inicial)=0x%04X", cmd, rx);

        // Operando 1
        if (n_ops >= 1) begin
            spi_transfer(op1, rx);
            $display("  OP1=0x%04X  MISO(ACC)=0x%04X", op1, rx);
        end

        // Operando 2
        if (n_ops >= 2) begin
            spi_transfer(op2, rx);
            $display("  OP2=0x%04X  MISO(ACC)=0x%04X", op2, rx);
        end

        // Operando 3 (dummy para leer el último ACC)
        if (n_ops >= 3) begin
            spi_transfer(op3, rx);
            $display("  OP3=0x%04X  MISO(ACC_final)=0x%04X", op3, rx);
        end

        ss = 1; #200;
    end
    endtask

    // =========================================================================
    // Estímulos
    // =========================================================================
    initial begin
        $dumpfile("tb_chip_top.vcd");
        $dumpvars(0, tb_chip_top);

        // Inicialización
        rst  = 1;
        ss   = 1;
        sclk = 0;
        mosi = 0;
        #100;
        rst  = 0;
        #100;

        // -----------------------------------------------------------------------
        // TEST 1: SUM — ACC = 0 + 1.0 + 2.0 → esperado 3.0 = 0x4040
        // Comando: op=0000 (SUM), init=0000 (ACC=0) → 0x0000
        // -----------------------------------------------------------------------
        run_operation(
            16'h0000,   // CMD: SUM, ACC=0
            16'h3F80,   // OP1: 1.0
            16'h4000,   // OP2: 2.0
            16'h0000,   // OP3: dummy para leer resultado
            3, "SUM: 0+1+2 (esperado 0x4040 = 3.0)"
        );

        // -----------------------------------------------------------------------
        // TEST 2: SUB — ACC = 0 - 1.0 - 2.0 → esperado -3.0 = 0xC040
        // Comando: op=1000 (SUB), init=0000 (ACC=0) → 0x0080
        // -----------------------------------------------------------------------
        run_operation(
            16'h0080,   // CMD: SUB, ACC=0
            16'h3F80,   // OP1: 1.0
            16'h4000,   // OP2: 2.0
            16'h0000,   // OP3: dummy
            3, "SUB: 0-1-2 (esperado 0xC040 = -3.0)"
        );

        // -----------------------------------------------------------------------
        // TEST 3: MPY — ACC = 1 * 2.0 * 3.0 → esperado 6.0 = 0x40C0
        // Comando: op=0001 (MPY), init=0001 (ACC=1) → 0x0011
        // -----------------------------------------------------------------------
        run_operation(
            16'h0011,   // CMD: MPY, ACC=1.0
            16'h4000,   // OP1: 2.0
            16'h4040,   // OP2: 3.0
            16'h0000,   // OP3: dummy
            3, "MPY: 1*2*3 (esperado 0x40C0 = 6.0)"
        );

        // -----------------------------------------------------------------------
        // TEST 4: DIV — ACC = 1 / 2.0 → esperado 0.5 = 0x3F00
        // Comando: op=0010 (DIV), init=0001 (ACC=1) → 0x0021
        // -----------------------------------------------------------------------
        run_operation(
            16'h0021,   // CMD: DIV, ACC=1.0
            16'h4000,   // OP1: 2.0
            16'h0000,   // OP2: dummy
            16'h0000,   // OP3: no usado
            3, "DIV: 1/2 (esperado 0x3F00 = 0.5)"
        );

        // -----------------------------------------------------------------------
        // TEST 5: SUM con ACC sin cambio (001X) → ACC mantiene valor previo
        // Comando: op=0000 (SUM), init=0010 (sin cambio) → 0x0002
        // -----------------------------------------------------------------------
        run_operation(
            16'h0002,   // CMD: SUM, ACC sin cambio
            16'h3F80,   // OP1: 1.0
            16'h0000,   // OP2: dummy
            16'h0000,   // OP3: no usado
            2, "SUM con ACC sin cambio (init=001X)"
        );

        #50000;
        $display("\n=== Simulacion completada ===");
        $finish;
    end

endmodule
