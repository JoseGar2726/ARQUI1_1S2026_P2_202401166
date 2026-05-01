// --- Mensajes a utilizar ---
.section .data
    msg_filas: .asciz "\nIngrese número de filas: "
    len_filas = . - msg_filas

    msg_columnas: .asciz "Ingrese número de columnas: "
    len_columnas = . - msg_columnas

    msg_celda: .ascii "a[0][0] = "
    len_celda = . - msg_celda

// --- Variables a utilizar ---
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
    // --- Mensaje de Filas ---
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_filas
    ldr x2, =len_filas
    svc 0

    // --- Ingreso de Filas ---
    mov x8, 63
    mov x0, 0
    ldr x1, =filas
    mov x2, 2
    svc 0

    // --- Mensaje Columnas ---
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_columnas
    ldr x2, =len_columnas
    svc 0

    // --- Ingreso de Columnas ---
    mov x8, 63
    mov x0, 0
    ldr x1, =columnas
    mov x2, 2
    svc 0

    // --- Preparar limites para los ciclos ---
    ldr x1, =filas
    ldrb w4, [x1]
    sub w4, w4, '0'     // Obtiene el valor de filas ingresado y luego lo convierte a entero -> w4

    ldr x1, =columnas
    ldrb w5, [x1]
    sub w5, w5, '0'     // Obtiene el valor de columnas ingresado y luego lo convierte a entero -> w5

    mov w6, 0           // Contador para filas

// Va recorriendo las filas
ciclo_filas:
    cmp w6, w4          // Compara si el contador es igual a filas para saber si ya ingreso todas las filas
    b.ge fin_ingreso    // En caso de que contador => filas -> ya se ingresaron todos los datos

    mov w7, 0           // Contador para las columas

// Va recorriendo columnas
ciclo_columnas:
    cmp w7, w5          // Compara si el contador es igual a columnas para saber si ya ingreso todas las columnas
    b.ge fin_columnas   // En caso de que contador => columnas -> ya se ingresaron todos los datos y avanza a la siguiene fila

    // --- Actualizar Texto -> A[i][j] ---
    ldr x1, =msg_celda
    add w8, w6, '0'
    strb w8, [x1, 2]

    add w9, w7, '0'
    strb w9, [x1, 5]

    // --- Imprimir A[i][j] = ---
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

    // --- Lectura y escritura de datos
    ldr x1, =valor_celda            // Obtener el valor de la celda
    mov w10, 0                      // Acumulador numerico final
    mov w11, 1                      // Signo, 1 = positivo, -1 = negativo

    // -- Verificar si el primer caracter es negativo --
    ldrb w12, [x1]                  // Obtener el primer byte de x1 que es el valor de la celda
    cmp w12, '-'                    // Ver si es el signo menos
    b.ne loop_atoi                  // Si no es negativo, ir directo a convertir
    
    mov w11, -1                     // Es negativo, guardamos el signo
    add x1, x1, 1                   // Avanzamos 1 byte para saltarnos el signo '-'

loop_atoi:
    ldrb w12, [x1], 1               // Leer caracter y avanzar puntero 1 byte
    
    cmp w12, '\n'                   // Si detecta 'Enter', terminar
    b.eq fin_atoi
    cbz w12, fin_atoi               // Si detecta final de cadena, terminar
    
    // -- Convertir a numero y acumular --
    sub w12, w12, '0'               // Convertir ASCII a numero real
    mov w13, 10
    mul w10, w10, w13               // Acumulador * 10
    add w10, w10, w12               // Sumar el nuevo digito
    
    b loop_atoi                     // Repetir para el siguiente caracter

fin_atoi:
    mul w10, w10, w11               // Multiplicar el acumulador por el signo (1 o -1)

    // -- Calcular indice Row-Major y guardar --
    mul w13, w6, w5                 // w13 = i * w5 (columnas)
    add w13, w13, w7                // w13 = w13 + j (columna actual)

    ldr x14, =matriz
    str w10, [x14, w13, uxtw #2]    // Guardar entero de 4 bytes en memoria

    add w7, w7, 1                   // Avanzar contador columnas
    b ciclo_columnas                // Regresa al ciclo de columnas

fin_columnas:
    add w6, w6, 1                   // Avanzar contador filas
    b ciclo_filas                   // Vuelve a evaluar el ciclo de filas

fin_ingreso:
    ret
