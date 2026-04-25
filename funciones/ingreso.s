.section .data
    msg_filas: .asciz "\nIngrese número de filas: "
    len_filas = . - msg_filas

    msg_columnas: .asciz "Ingrese número de columnas: "
    len_columnas = . - msg_columnas

    msg_celda: .ascii "a[0][0] = "
    len_celda = . - msg_celda

.section .bss
    .global filas
    .global columnas
    .global matriz
    matriz: .space 400
    filas: .space 2
    columnas: .space 2
    valor_celda: .space 8

.section .text
.global ingreso_datos

ingreso_datos:
    // --- Pedir Filas ---
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_filas
    ldr x2, =len_filas
    svc 0

    mov x8, 63
    mov x0, 0
    ldr x1, =filas
    mov x2, 2
    svc 0

    // --- Pedir Columnas ---
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_columnas
    ldr x2, =len_columnas
    svc 0

    mov x8, 63
    mov x0, 0
    ldr x1, =columnas
    mov x2, 2
    svc 0

    // --- Preparar límites para los ciclos ---
    ldr x1, =filas
    ldrb w4, [x1]
    sub w4, w4, '0'     // w4 = Límite de filas (entero)

    ldr x1, =columnas
    ldrb w5, [x1]
    sub w5, w5, '0'     // w5 = Límite de columnas (entero)

    mov w6, 0           // w6 = i (fila actual)

ciclo_filas:
    cmp w6, w4
    b.ge fin_ingreso

    mov w7, 0           // w7 = j (columna actual)

ciclo_columnas:
    cmp w7, w5
    b.ge fin_columnas

    // --- Actualizar plantilla de texto ---
    ldr x1, =msg_celda
    add w8, w6, '0'
    strb w8, [x1, 2]

    add w9, w7, '0'
    strb w9, [x1, 5]

    // --- Imprimir a[i][j] = ---
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_celda
    ldr x2, =len_celda
    svc 0

    // --- Leer valor ingresado ---
    mov x8, 63
    mov x0, 0
    ldr x1, =valor_celda
    mov x2, 8
    svc 0

    // ------------------------------------------------
    // GUARDAR EN MEMORIA (Lógica agregada)
    // ------------------------------------------------
    ldr x1, =valor_celda
    ldrb w10, [x1]      // Cargar el primer carácter ingresado
    sub w10, w10, '0'   // Convertir de ASCII a número entero

    // Calcular índice: (i * total_columnas) + j
    mul w13, w6, w5     // w13 = i * w5
    add w13, w13, w7    // w13 = w13 + j

    // Guardar el número en el buffer 'matriz'
    ldr x14, =matriz
    // Se usa 'uxtw #2' para multiplicar el índice por 4 (cada entero ocupa 4 bytes)
    str w10, [x14, w13, uxtw #2] 
    // ------------------------------------------------

    add w7, w7, 1
    b ciclo_columnas

fin_columnas:
    add w6, w6, 1
    b ciclo_filas       // Vuelve a evaluar el ciclo de filas

fin_ingreso:
    ret
