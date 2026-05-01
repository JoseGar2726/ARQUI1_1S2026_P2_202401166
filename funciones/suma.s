// --- Mensajes a imprimir ---
.section .data
    msg_err_vacia:    .asciz "\nError: Primero debe ingresar la Matriz A en la opcion 1.\n"
    msg_ingreso_b:    .asciz "\nIngrese los valores para la Matriz B a sumar:\n"
    
    msg_celda_b:      .ascii "b[0][0] = "
    len_celda_b = . - msg_celda_b

    msg_header_r:     .asciz "\nMatriz Resultante (A + B):\nR = "
    
    abre_cor:         .asciz "[ "
    cierra_cor:       .asciz "]\n    "
    espacio:          .asciz " "
    newline:          .asciz "\n"

// --- Espacio de memoria ---
.section .bss
    matriz_r:  .space 400    // Espacio para 100 enteros (10x10)
    valor_b:   .space 8      // Buffer de entrada para el teclado

.section .text
.global matriz_suma

// --- Inicio proceso ---
matriz_suma:
    stp x29, x30, [sp, -16]!      // Preservar registros de enlace y marco

    // --- 1. VALIDAR DATOS DE MATRIZ A ---
    ldr x1, =filas
    ldrb w4, [x1]
    cbz w4, error_vacia           // Salta si no hay datos en filas
    cmp w4, '0'
    b.eq error_vacia

    ldr x1, =columnas
    ldrb w5, [x1]

    sub w4, w4, '0'               // Convertir filas a entero
    sub w5, w5, '0'               // Convertir columnas a entero

    // --- NOTIFICAR INGRESO DE MATRIZ B ---
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_ingreso_b
    mov x2, 47
    svc 0

    mov w6, 0                     // i = 0

// --- CICLO DE CAPTURA Y SUMA ---
loop_filas_suma:
    cmp w6, w4
    b.ge fin_ingreso_suma

    mov w7, 0                     // j = 0

loop_columnas_suma:
    cmp w7, w5
    b.ge sig_fila_suma

    // -- Actualizar indices en la etiqueta de texto --
    ldr x1, =msg_celda_b
    add w8, w6, '0'
    strb w8, [x1, 2]              // Reemplaza i en "b[i][j]"
    add w9, w7, '0'
    strb w9, [x1, 5]              // Reemplaza j en "b[i][j]"

    mov x8, 64
    mov x0, 1
    ldr x1, =msg_celda_b
    ldr x2, =len_celda_b
    svc 0

    // -- Leer valor del teclado --
    mov x8, 63
    mov x0, 0
    ldr x1, =valor_b
    mov x2, 8
    svc 0

    // --- ALGORITMO ATOI ---
    ldr x1, =valor_b
    mov w10, 0                    // Acumulador numerico
    mov w11, 1                    // Control de signo

    ldrb w12, [x1]
    cmp w12, '-'
    b.ne loop_atoi
    mov w11, -1                   // Guardar signo negativo
    add x1, x1, 1                 // Saltar el guion

loop_atoi:
    ldrb w12, [x1], 1
    cmp w12, '\n'
    b.eq fin_atoi
    cbz w12, fin_atoi
    sub w12, w12, '0'             // Convertir ASCII a digito
    mov w14, 10
    mul w10, w10, w14             // Desplazamiento decimal
    add w10, w10, w12             // Sumar al acumulado
    b loop_atoi

fin_atoi:
    mul w10, w10, w11             // Ajustar signo final

    // --- OPERACION ARITMETICA Y ALMACENAMIENTO ---
    mul w13, w6, w5
    add w13, w13, w7              // Calculo de indice Row-Major

    ldr x14, =matriz
    ldr w15, [x14, w13, uxtw #2]  // Cargar elemento de A

    add w15, w15, w10             // Suma: R[i][j] = A[i][j] + B[i][j]

    ldr x14, =matriz_r
    str w15, [x14, w13, uxtw #2]  // Guardar en matriz resultante

    add w7, w7, 1
    b loop_columnas_suma

sig_fila_suma:
    add w6, w6, 1
    b loop_filas_suma

fin_ingreso_suma:

    // --- IMPRESION DE LA MATRIZ RESULTANTE ---
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_header_r
    mov x2, 33
    svc 0

    mov w6, 0                     // i = 0

loop_print_f:
    cmp w6, w4
    b.ge fin_suma

    mov x8, 64
    mov x0, 1
    ldr x1, =abre_cor
    mov x2, 2
    svc 0

    mov w7, 0                     // j = 0

loop_print_c:
    cmp w7, w5
    b.ge sig_print_fila

    mul w13, w6, w5
    add w13, w13, w7
    ldr x14, =matriz_r
    ldr w15, [x14, w13, uxtw #2]  // Valor a convertir

    // --- ALGORITMO ITOA  ---
    sub sp, sp, 16                // Reservar buffer en stack
    mov x9, sp
    mov w10, 0

    cmp w15, 0
    b.ge no_negativo

    // Gestión del signo negativo para salida
    mov w11, '-'
    strb w11, [sp, 15]
    mov x8, 64
    mov x0, 1
    add x1, sp, 15
    mov x2, 1
    svc 0
    neg w15, w15                  // Valor absoluto

no_negativo:
    mov w11, 10
loop_dividir:
    udiv w12, w15, w11            // w12 = cociente
    msub w13, w12, w11, w15       // w13 = residuo (digito)
    add w13, w13, '0'             // ASCII
    strb w13, [x9], 1             // Guardar en buffer
    add w10, w10, 1
    mov w15, w12
    cbnz w15, loop_dividir

loop_imprimir_digitos:
    cbz w10, fin_itoa
    sub x9, x9, 1                 // Retroceder al digito
    mov x8, 64
    mov x0, 1
    mov x1, x9
    mov x2, 1
    svc 0
    sub w10, w10, 1
    b loop_imprimir_digitos

fin_itoa:
    add sp, sp, 16                // Liberar stack

    mov x8, 64
    mov x0, 1
    ldr x1, =espacio
    mov x2, 1
    svc 0

    add w7, w7, 1
    b loop_print_c

sig_print_fila:
    mov x8, 64
    mov x0, 1
    ldr x1, =cierra_cor
    mov x2, 7
    svc 0

    add w6, w6, 1
    b loop_print_f


// --- MANEJO DE ERRORES Y SALIDA ---
error_vacia:
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_err_vacia
    mov x2, 58
    svc 0
    b salir_rutina

fin_suma:
    mov x8, 64
    mov x0, 1
    ldr x1, =newline
    mov x2, 1
    svc 0

salir_rutina:
    ldp x29, x30, [sp], 16        // Restaurar registros y stack
    ret                           // Regreso al menú principal
