.section .data
    header:      .asciz "\nmatriz guardada:\nA = "
    abre_cor:    .asciz "[ "
    cierra_cor:  .asciz "]\n    " // Espacio para alinear filas debajo de 'A = '
    espacio:     .asciz "  "
    newline:     .asciz "\n"

.section .text
.global imprimir_matriz

imprimir_matriz:
    // Guardar registros de enlace
    stp x29, x30, [sp, -16]!

    // Verificar si hay datos (si filas es '0', no imprimimos nada)
    ldr x1, =filas
    ldrb w4, [x1]
    sub w4, w4, '0'         // w4 = total filas
    cbz w4, fin_visualizar  // Si es 0, salir

    ldr x1, =columnas
    ldrb w5, [x1]
    sub w5, w5, '0'         // w5 = total columnas

    // 1. Imprimir encabezado "matriz guardada: A = "
    mov x8, 64
    mov x0, 1
    ldr x1, =header
    mov x2, 22
    svc 0

    mov w6, 0               // i = 0 (contador filas)

loop_filas:
    cmp w6, w4
    b.ge fin_matriz

    // 2. Imprimir "[ " al inicio de cada fila
    mov x8, 64
    mov x0, 1
    ldr x1, =abre_cor
    mov x2, 2
    svc 0

    mov w7, 0               // j = 0 (contador columnas)

loop_columnas:
    cmp w7, w5
    b.ge sig_fila

    // 3. Calcular dirección en memoria (Row-Major)
    mul w13, w6, w5         // i * total_cols
    add w13, w13, w7        // + j
    ldr x14, =matriz
    ldr w15, [x14, w13, uxtw #2] // Cargar entero de 4 bytes

    // 4. Convertir a ASCII y mostrar
    add w15, w15, '0'
    // Usamos el espacio en memoria de 'espacio' para poner el número
    ldr x1, =espacio
    strb w15, [x1]
    
    mov x8, 64
    mov x0, 1
    mov x2, 2               // Imprime el número + un espacio
    svc 0

    add w7, w7, 1
    b loop_columnas

sig_fila:
    // 5. Imprimir "]\n" al terminar la fila
    mov x8, 64
    mov x0, 1
    ldr x1, =cierra_cor
    mov x2, 6               // Imprime "]\n" y espacios de alineación
    svc 0

    add w6, w6, 1
    b loop_filas

fin_matriz:
    // Salto de línea extra antes del menú
    mov x8, 64
    mov x0, 1
    ldr x1, =newline
    mov x2, 1
    svc 0

fin_visualizar:
    ldp x29, x30, [sp], 16
    ret
