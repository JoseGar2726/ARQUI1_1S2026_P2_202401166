.section .data
    header:      .asciz "\nmatriz guardada:\nA = "
    abre_cor:    .asciz "[ "
    cierra_cor:  .asciz "]\n    " // Espacio para alinear filas debajo de 'A = '
    espacio:     .asciz " "
    newline:     .asciz "\n"

.section .text
.global imprimir_matriz

imprimir_matriz:
    // Guardar registros de enlace
    stp x29, x30, [sp, -16]!

    // Verificar si hay datos
    ldr x1, =filas
    ldrb w4, [x1]
    sub w4, w4, '0'         
    cbz w4, fin_visualizar  

    ldr x1, =columnas
    ldrb w5, [x1]
    sub w5, w5, '0'         

    // 1. Imprimir encabezado
    mov x8, 64
    mov x0, 1
    ldr x1, =header
    mov x2, 22
    svc 0

    mov w6, 0               // i = 0 

loop_filas:
    cmp w6, w4
    b.ge fin_matriz

    // 2. Imprimir "[ "
    mov x8, 64
    mov x0, 1
    ldr x1, =abre_cor
    mov x2, 2
    svc 0

    mov w7, 0               // j = 0 

loop_columnas:
    cmp w7, w5
    b.ge sig_fila

    // 3. Calcular dirección en memoria
    mul w13, w6, w5         
    add w13, w13, w7        
    ldr x14, =matriz
    ldr w15, [x14, w13, uxtw #2] 

    // ------------------------------------------------
    // 4. ALGORITMO ITOA (Soporta >9 y negativos)
    // ------------------------------------------------
    sub sp, sp, 16          // Reservar 16 bytes en la pila
    mov x9, sp              // Puntero temporal
    mov w10, 0              // Contador de digitos

    // -- Verificar si es negativo --
    cmp w15, 0
    b.ge no_negativo

    mov w11, '-'
    strb w11, [sp, 15]
    
    mov x8, 64
    mov x0, 1
    add x1, sp, 15          
    mov x2, 1
    svc 0                   // Imprime '-'

    neg w15, w15            // Vuelve el numero positivo

no_negativo:
    mov w11, 10
loop_dividir:
    udiv w12, w15, w11      
    msub w13, w12, w11, w15 
    
    add w13, w13, '0'       
    strb w13, [x9], 1       
    add w10, w10, 1         
    
    mov w15, w12            
    cbnz w15, loop_dividir  

loop_imprimir_digitos:
    cbz w10, fin_itoa

    sub x9, x9, 1           
    mov x8, 64
    mov x0, 1
    mov x1, x9              
    mov x2, 1               
    svc 0                   // Imprime digito

    sub w10, w10, 1
    b loop_imprimir_digitos

fin_itoa:
    add sp, sp, 16          // Restaurar la pila

    // Imprimir el espacio separador
    mov x8, 64
    mov x0, 1
    ldr x1, =espacio
    mov x2, 1               
    svc 0
    // ------------------------------------------------

    add w7, w7, 1
    b loop_columnas

sig_fila:
    // 5. Imprimir "]\n"
    mov x8, 64
    mov x0, 1
    ldr x1, =cierra_cor
    mov x2, 6               
    svc 0

    add w6, w6, 1
    b loop_filas

fin_matriz:
    mov x8, 64
    mov x0, 1
    ldr x1, =newline
    mov x2, 1
    svc 0

fin_visualizar:
    ldp x29, x30, [sp], 16
    ret
