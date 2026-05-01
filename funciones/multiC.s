// --- Mensajes a imprimir ---
.section .data
    msg_err_vacia:    .asciz "\nError: Primero debe ingresar la Matriz A en la opcion 1.\n"
    msg_err_dim_crz:  .asciz "\nError: El Producto Cruz requiere vectores de dimension 3.\n"
    
    msg_pedir_fb:     .asciz "\nIngrese el numero de filas de B: "
    msg_pedir_cb:     .asciz "Ingrese el numero de columnas de B: "
    msg_ingreso_b:    .asciz "\nIngrese los valores para el Vector B:\n"
    
    msg_celda_b:      .ascii "b[0][0] = "
    len_celda_b = . - msg_celda_b

    msg_header_crz:   .asciz "\n--- Resultado Producto Cruz ---\n"
    
    abre_cor:         .asciz "[ "
    cierra_cor:       .asciz " ]\n"
    espacio:          .asciz " "
    newline:          .asciz "\n"

// --- Espacio de memoria ---
.section .bss
.align 3
    vector_b_mc:   .space 64     // Espacio para vector B
    filas_b_mc:    .space 2
    columnas_b_mc: .space 2
    valor_b_mc:    .space 8      
    itoa_buffer_mc:.space 16     

.section .text
.global matriz_cruz

matriz_cruz:
    stp x29, x30, [sp, -16]!

    // --- 1. Validar Matriz A (Debe ser dimension 3) ---
    ldr x1, =filas
    ldrb w4, [x1]
    cbz w4, error_vacia_mc
    cmp w4, '0'
    b.eq error_vacia_mc

    ldr x1, =columnas
    ldrb w5, [x1]
    sub w4, w4, '0'         // filas A
    sub w5, w5, '0'         // columnas A

    mul w10, w4, w5         // Total elementos A
    cmp w10, 3
    b.ne error_dim_mc

    // --- 2. Pedir Dimensiones de B ---
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_pedir_fb
    mov x2, 34
    svc 0

    mov x8, 63
    mov x0, 0
    ldr x1, =filas_b_mc
    mov x2, 2
    svc 0

    mov x8, 64
    mov x0, 1
    ldr x1, =msg_pedir_cb
    mov x2, 37
    svc 0

    mov x8, 63
    mov x0, 0
    ldr x1, =columnas_b_mc
    mov x2, 2
    svc 0

    ldr x1, =filas_b_mc
    ldrb w21, [x1]
    sub w21, w21, '0'       // filas B
    ldr x1, =columnas_b_mc
    ldrb w22, [x1]
    sub w22, w22, '0'       // columnas B

    // --- 3. Validar Dimension B (Debe ser 3) ---
    mul w10, w21, w22
    cmp w10, 3
    b.ne error_dim_mc

    // --- 4. Ingresar Vector B ---
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_ingreso_b
    mov x2, 39
    svc 0

    mov w6, 0               // i
loop_ingreso_b_mc:
    cmp w6, 3
    b.ge calcular_cruz

    ldr x1, =msg_celda_b
    add w8, w6, '0'
    strb w8, [x1, 2]        // Solo mostramos b[i] simplificado

    mov x8, 64
    mov x0, 1
    ldr x1, =msg_celda_b
    ldr x2, =len_celda_b
    svc 0

    mov x8, 63
    mov x0, 0
    ldr x1, =valor_b_mc
    mov x2, 8
    svc 0

    // ATOI
    ldr x1, =valor_b_mc
    mov w10, 0          
    mov w11, 1          
    ldrb w12, [x1]
    cmp w12, '-'
    b.ne atoi_mc
    mov w11, -1
    add x1, x1, 1
atoi_mc:
    ldrb w12, [x1], 1
    cmp w12, '\n'
    b.eq atoi_fin_mc
    cbz w12, atoi_fin_mc
    sub w12, w12, '0'
    mov w9, 10
    mul w10, w10, w9
    add w10, w10, w12
    b atoi_mc
atoi_fin_mc:
    mul w10, w10, w11
    
    ldr x9, =vector_b_mc
    str w10, [x9, w6, uxtw #2]
    add w6, w6, 1
    b loop_ingreso_b_mc

calcular_cruz:
    // --- 5. Proceso Matematico ---
    // A = [a0, a1, a2], B = [b0, b1, b2]
    ldr x9, =matriz
    ldr w10, [x9, #0]       // a0
    ldr w11, [x9, #4]       // a1
    ldr w12, [x9, #8]       // a2

    ldr x9, =vector_b_mc
    ldr w13, [x9, #0]       // b0
    ldr w14, [x9, #4]       // b1
    ldr w15, [x9, #8]       // b2

    // R0 = a1*b2 - a2*b1
    mul w20, w11, w15
    mul w21, w12, w14
    sub w24, w20, w21       // R0 en w24

    // R1 = a2*b0 - a0*b2
    mul w20, w12, w13
    mul w21, w10, w15
    sub w25, w20, w21       // R1 en w25

    // R2 = a0*b1 - a1*b0
    mul w20, w10, w14
    mul w21, w11, w13
    sub w26, w20, w21       // R2 en w26

    // --- 6. Imprimir Resultado ---
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_header_crz
    mov x2, 33
    svc 0

    mov x8, 64
    mov x0, 1
    ldr x1, =abre_cor
    mov x2, 2
    svc 0

    mov w15, w24
    bl itoa_imprimir_mc
    mov w15, w25
    bl itoa_imprimir_mc
    mov w15, w26
    bl itoa_imprimir_mc

    mov x8, 64
    mov x0, 1
    ldr x1, =cierra_cor
    mov x2, 3
    svc 0
    b salir_mc

error_vacia_mc:
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_err_vacia
    mov x2, 58
    svc 0
    b salir_mc

error_dim_mc:
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_err_dim_crz
    mov x2, 60
    svc 0

salir_mc:
    ldp x29, x30, [sp], 16
    ret

// --- Subrutina ITOA ---
itoa_imprimir_mc:
    stp x29, x30, [sp, -16]!
    ldr x9, =itoa_buffer_mc
    mov w10, 0
    cmp w15, 0
    b.ge itoa_pos_mc
    mov w11, '-'
    strb w11, [x9]
    mov x8, 64
    mov x0, 1
    mov x1, x9
    mov x2, 1
    svc 0
    neg w15, w15
itoa_pos_mc:
    mov w11, 10
    ldr x9, =itoa_buffer_mc
itoa_div_mc:
    udiv w12, w15, w11
    msub w13, w12, w11, w15
    add w13, w13, '0'
    strb w13, [x9], 1
    add w10, w10, 1
    mov w15, w12
    cbnz w15, itoa_div_mc
itoa_print_mc:
    cbz w10, itoa_fin_mc
    sub x9, x9, 1
    mov x8, 64
    mov x0, 1
    mov x1, x9
    mov x2, 1
    svc 0
    sub w10, w10, 1
    b itoa_print_mc
itoa_fin_mc:
    mov x8, 64
    mov x0, 1
    ldr x1, =espacio
    mov x2, 1
    svc 0
    ldp x29, x30, [sp], 16
    ret
