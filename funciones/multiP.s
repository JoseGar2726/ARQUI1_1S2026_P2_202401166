// --- Mensajes a imprimir ---
.section .data
    msg_err_vacia:    .asciz "\nError: Primero debe ingresar la Matriz A en la opcion 1.\n"
    msg_pedir_fb:     .asciz "\nIngrese el numero de filas de B: "
    msg_pedir_cb:     .asciz "Ingrese el numero de columnas de B: "
    
    msg_err_dim:      .asciz "\nError: Columnas de A no coinciden con Filas de B. Imposible multiplicar.\n"
    msg_ingreso_b:    .asciz "\nIngrese los valores para la Matriz B:\n"
    
    msg_celda_b:      .ascii "b[0][0] = "
    len_celda_b = . - msg_celda_b

    msg_header_res:   .asciz "\nMatriz Resultante (A x B):\nR = "
    
    abre_cor:         .asciz "[ "
    cierra_cor:       .asciz "]\n    "
    espacio:          .asciz " "
    newline:          .asciz "\n"

// --- Espacio de memoria ---
.section .bss
.align 3
    matriz_b_mp:    .space 400    
    matriz_r_mp:    .space 400    
    filas_b_mp:     .space 2
    columnas_b_mp:  .space 2
    valor_b_mp:     .space 8      
    itoa_buffer_mp: .space 16     

.section .text
.global matriz_multip

// --- Inicio del proceso de multiplicacion cruz ---
matriz_multip:
    stp x29, x30, [sp, -16]!      // Preservar registros de enlace y marco

    // --- VALIDAR MATRIZ A ---
    ldr x1, =filas
    ldrb w4, [x1]
    cbz w4, error_vacia_mp        // Validar si A existe
    cmp w4, '0'
    b.eq error_vacia_mp

    ldr x1, =columnas
    ldrb w5, [x1]
    sub w4, w4, '0'               // w4 = m (filas A)
    sub w5, w5, '0'               // w5 = n (columnas A)

    // --- PEDIR DIMENSIONES DE B ---
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_pedir_fb
    mov x2, 34
    svc 0

    mov x8, 63
    mov x0, 0
    ldr x1, =filas_b_mp
    mov x2, 2
    svc 0

    mov x8, 64
    mov x0, 1
    ldr x1, =msg_pedir_cb
    mov x2, 37
    svc 0

    mov x8, 63
    mov x0, 0
    ldr x1, =columnas_b_mp
    mov x2, 2
    svc 0

    // -- Convertir dimensiones de B --
    ldr x1, =filas_b_mp
    ldrb w21, [x1]
    sub w21, w21, '0'             // w21 = n (filas B)

    ldr x1, =columnas_b_mp
    ldrb w22, [x1]
    sub w22, w22, '0'             // w22 = p (columnas B)

    // --- VALIDAR REGLA DE MULTIPLICACION (Col A == Fil B) ---
    cmp w5, w21
    b.ne error_dim_mp

    // --- INGRESAR VALORES DE MATRIZ B ---
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_ingreso_b
    mov x2, 39
    svc 0

    mov w6, 0                     // i = 0
loop_fb_mp:
    cmp w6, w21
    b.ge eval_multip
    mov w7, 0                     // j = 0
loop_cb_mp:
    cmp w7, w22
    b.ge sig_fb_mp

    // -- Actualizar etiqueta de celda --
    ldr x1, =msg_celda_b
    add w8, w6, '0'
    strb w8, [x1, 2]              
    add w9, w7, '0'
    strb w9, [x1, 5]              

    mov x8, 64
    mov x0, 1
    ldr x1, =msg_celda_b
    ldr x2, =len_celda_b
    svc 0

    mov x8, 63
    mov x0, 0
    ldr x1, =valor_b_mp
    mov x2, 8
    svc 0

    // --- ALGORITMO ATOI ---
    ldr x1, =valor_b_mp
    mov w10, 0                  
    mov w11, 1                  
    ldrb w12, [x1]
    cmp w12, '-'
    b.ne loop_atoi_mp
    mov w11, -1                 // Detectar negativo
    add x1, x1, 1
loop_atoi_mp:
    ldrb w12, [x1], 1
    cmp w12, '\n'
    b.eq fin_atoi_mp
    cbz w12, fin_atoi_mp
    sub w12, w12, '0'
    mov w9, 10
    mul w10, w10, w9
    add w10, w10, w12           // Acumular digito
    b loop_atoi_mp
fin_atoi_mp:
    mul w10, w10, w11           

    // -- Almacenar en Matriz B --
    mul w13, w6, w22
    add w13, w13, w7
    ldr x14, =matriz_b_mp
    str w10, [x14, w13, uxtw #2]

    add w7, w7, 1
    b loop_cb_mp
sig_fb_mp:
    add w6, w6, 1
    b loop_fb_mp

// --- OPERACION DE MULTIPLICACION (Fila A x Columna B) ---
eval_multip:
    mov w6, 0                   // i (Filas de A)
loop_multi_i:
    cmp w6, w4
    b.ge print_result_mp
    
    mov w7, 0                   // j (Columnas de B)
loop_multi_j:
    cmp w7, w22
    b.ge sig_multi_i
    
    mov w25, 0                  // Acumulador de producto punto
    mov w8, 0                   // k (Indice comun)
loop_multi_k:
    cmp w8, w5
    b.ge guardar_celda_c
    
    // -- Leer A[i][k] --
    mul w13, w6, w5
    add w13, w13, w8
    ldr x9, =matriz             
    ldr w10, [x9, w13, uxtw #2]
    
    // -- Leer B[k][j] --
    mul w11, w8, w22
    add w11, w11, w7
    ldr x9, =matriz_b_mp
    ldr w12, [x9, w11, uxtw #2]
    
    mul w10, w10, w12           // A[i][k] * B[k][j]
    add w25, w25, w10           // Acumular resultado
    
    add w8, w8, 1
    b loop_multi_k

guardar_celda_c:
    // -- Guardar en R[i][j] --
    mul w13, w6, w22
    add w13, w13, w7
    ldr x9, =matriz_r_mp
    str w25, [x9, w13, uxtw #2]
    
    add w7, w7, 1
    b loop_multi_j

sig_multi_i:
    add w6, w6, 1
    b loop_multi_i

// --- IMPRESION DE MATRIZ RESULTANTE ---
print_result_mp:
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_header_res
    mov x2, 33
    svc 0

    mov w6, 0                   // i = 0
loop_print_f_mp:
    cmp w6, w4
    b.ge fin_rutina_mp

    mov x8, 64
    mov x0, 1
    ldr x1, =abre_cor
    mov x2, 2
    svc 0

    mov w7, 0                   // j = 0
loop_print_c_mp:
    cmp w7, w22
    b.ge sig_print_fila_mp

    mul w13, w6, w22
    add w13, w13, w7
    ldr x9, =matriz_r_mp
    ldr w15, [x9, w13, uxtw #2] 

    bl itoa_imprimir_mp

    mov x8, 64
    mov x0, 1
    ldr x1, =espacio
    mov x2, 1
    svc 0

    add w7, w7, 1
    b loop_print_c_mp

sig_print_fila_mp:
    mov x8, 64
    mov x0, 1
    ldr x1, =cierra_cor
    mov x2, 7
    svc 0

    add w6, w6, 1
    b loop_print_f_mp

// --- MANEJO DE ERRORES Y SALIDA ---
error_vacia_mp:
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_err_vacia
    mov x2, 58
    svc 0
    b salir_rutina_mp

error_dim_mp:
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_err_dim
    mov x2, 77
    svc 0
    b salir_rutina_mp

fin_rutina_mp:
    mov x8, 64
    mov x0, 1
    ldr x1, =newline
    mov x2, 1
    svc 0

salir_rutina_mp:
    ldp x29, x30, [sp], 16      // Restaurar stack
    ret

// --- SUBRUTINA ITOA ---
itoa_imprimir_mp:
    stp x29, x30, [sp, -16]!
    ldr x9, =itoa_buffer_mp
    mov w10, 0
    cmp w15, 0
    b.ge itoa_no_neg_mp
    
    // Imprimir signo negativo manual
    mov w11, '-'
    strb w11, [x9]
    mov x8, 64
    mov x0, 1
    mov x1, x9
    mov x2, 1
    svc 0
    neg w15, w15                // Valor absoluto

itoa_no_neg_mp:
    mov w11, 10
    ldr x9, =itoa_buffer_mp
itoa_div_mp:
    udiv w12, w15, w11
    msub w13, w12, w11, w15
    add w13, w13, '0'           // ASCII
    strb w13, [x9], 1           // Guardar digito
    add w10, w10, 1
    mov w15, w12
    cbnz w15, itoa_div_mp
itoa_print_mp:
    cbz w10, itoa_fin_mp
    sub x9, x9, 1               // Retroceder puntero
    mov x8, 64
    mov x0, 1
    mov x1, x9
    mov x2, 1
    svc 0
    sub w10, w10, 1
    b itoa_print_mp
itoa_fin_mp:
    ldp x29, x30, [sp], 16      // Restaurar registros
    ret
