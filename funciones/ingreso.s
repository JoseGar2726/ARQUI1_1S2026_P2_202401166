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
    // GUARDAR EN MEMORIA (Algoritmo ATOI para multiples digitos y negativos)
    // ------------------------------------------------
    ldr x1, =valor_celda
    mov w10, 0          // Acumulador numerico final
    mov w11, 1          // Signo (1 = positivo, -1 = negativo)

    // -- Verificar si el primer caracter es negativo --
    ldrb w12, [x1]
    cmp w12, '-'
    b.ne loop_atoi      // Si no es negativo, ir directo a convertir
    
    mov w11, -1         // Es negativo, guardamos el signo
    add x1, x1, 1       // Avanzamos 1 byte para saltarnos el guion '-'

loop_atoi:
    ldrb w12, [x1], 1   // Leer caracter y avanzar puntero 1 byte
    
    cmp w12, '\n'       // Si detecta 'Enter', terminar
    b.eq fin_atoi
    cbz w12, fin_atoi   // Si detecta final de cadena (nulo), terminar
    
    // -- Convertir a numero y acumular --
    sub w12, w12, '0'   // Convertir ASCII a numero real
    mov w13, 10
    mul w10, w10, w13   // Acumulador * 10
    add w10, w10, w12   // Sumar el nuevo digito
    
    b loop_atoi         // Repetir para el siguiente caracter

fin_atoi:
    mul w10, w10, w11   // Multiplicar el acumulador por el signo (1 o -1)

    // -- Calcular índice Row-Major y guardar --
    mul w13, w6, w5     // w13 = i * w5 (columnas)
    add w13, w13, w7    // w13 = w13 + j (columna actual)

    ldr x14, =matriz
    str w10, [x14, w13, uxtw #2] // Guardar entero de 4 bytes en memoria

    add w7, w7, 1
    b ciclo_columnas

fin_columnas:
    add w6, w6, 1
    b ciclo_filas       // Vuelve a evaluar el ciclo de filas

fin_ingreso:
    ret
