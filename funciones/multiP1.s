// --- Mensajes a imprimir ---
.section .data
    msg_err_vacia:    .asciz "\nError: Primero debe ingresar la Matriz A en la opcion 1.\n"
    msg_pedir_fb:     .asciz "\nIngrese el numero de filas de B: "
    msg_pedir_cb:     .asciz "Ingrese el numero de columnas de B: "
    
    msg_err_dim:      .asciz "\nError: Las dimensiones de B deben ser iguales a las de A.\n"
    msg_ingreso_b:    .asciz "\nIngrese los valores para la Matriz B:\n"
    
    msg_celda_b:      .ascii "b[0][0] = "
    len_celda_b = . - msg_celda_b

    msg_header_res:   .asciz "\nResultado Multiplicacion Punto:\nR = "
    
    abre_cor:         .asciz "[ "
    cierra_cor:       .asciz "]\n    "
    espacio:          .asciz " "
    newline:          .asciz "\n"

// --- Espacio de memoria ---
.section .bss
.align 3
    matriz_b_p1:    .space 400    
    matriz_r_p1:    .space 400    
    filas_b_p1:     .space 2
    columnas_b_p1:  .space 2
    valor_b_p1:     .space 8      
    itoa_buffer_p1: .space 16     

.section .text
.global matriz_multip1

// --- Inicio del proceso de multiplicacion punto ---
matriz_multip1:
    stp x29, x30, [sp, -16]!      // Preservar registros de enlace y marco

    // --- VALIDAR MATRIZ A ---
    ldr x1, =filas
    ldrb w4, [x1]
    cbz w4, error_vacia_p1        // Validar si A existe
    cmp w4, '0'
    b.eq error_vacia_p1

    ldr x1, =columnas
    ldrb w5, [x1]
    sub w4, w4, '0'               // w4 = filas A (entero)
    sub w5, w5, '0'               // w5 = columnas A (entero)

    // --- PEDIR DIMENSIONES DE B ---
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_pedir_fb
    mov x2, 34
    svc 0

    mov x8, 63
    mov x0, 0
    ldr x1, =filas_b_p1
    mov x2, 2
    svc 0

    mov x8, 64
    mov x0, 1
    ldr x1, =msg_pedir_cb
    mov x2, 37
    svc 0

    mov x8, 63
    mov x0, 0
    ldr x1, =columnas_b_p1
    mov x2, 2
    svc 0

    // -- Convertir dimensiones ingresadas --
    ldr x1, =filas_b_p1
    ldrb w21, [x1]
    sub w21, w21, '0'             // w21 = filas B
    ldr x1, =columnas_b_p1
    ldrb w22, [x1]
    sub w22, w22, '0'             // w22 = columnas B

    // --- VALIDAR DIMENSIONES IDENTICAS ---
    cmp w4, w21                   // Comparar filas A vs B
    b.ne error_dim_p1
    cmp w5, w22                   // Comparar columnas A vs B
    b.ne error_dim_p1

    // --- INGRESAR MATRIZ B ---
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_ingreso_b
    mov x2, 39
    svc 0

    mov w6, 0                     // i = 0
loop_fb_p1:
    cmp w6, w21
    b.ge calcular_p1
    mov w7, 0                     // j = 0
loop_cb_p1:
    cmp w7, w22
    b.ge sig_fb_p1

    // -- Actualizar etiquetas dinámicas --
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
    ldr x1, =valor_b_p1
    mov x2, 8
    svc 0

    // --- ALGORITMO ATOI ---
    ldr x1, =valor_b_p1
    mov w10, 0                    
    mov w11, 1                    
    ldrb w12, [x1]
    cmp w12, '-'
    b.ne atoi_p1
    mov w11, -1                   // Detectar signo negativo
    add x1, x1, 1
atoi_p1:
    ldrb w12, [x1], 1
    cmp w12, '\n'
    b.eq atoi_fin_p1
    cbz w12, atoi_fin_p1
    sub w12, w12, '0'
    mov w9, 10
    mul w10, w10, w9
    add w10, w10, w12             // Acumular digito
    b atoi_p1
atoi_fin_p1:
    mul w10, w10, w11   

    // -- Guardar elemento en Matriz B --
    mul w13, w6, w22
    add w13, w13, w7
    ldr x9, =matriz_b_p1
    str w10, [x9, w13, uxtw #2]

    add w7, w7, 1
    b loop_cb_p1
sig_fb_p1:
    add w6, w6, 1
    b loop_fb_p1

// --- CALCULO DE MULTIPLICACION PUNTO (A[i] * B[i]) ---
calcular_p1:
    mul w18, w4, w5               // Total de elementos
    mov w19, 0                    
loop_op_p1:
    cmp w19, w18
    b.ge print_p1

    ldr x9, =matriz
    ldr w10, [x9, w19, uxtw #2]   // Cargar elemento de A
    
    ldr x9, =matriz_b_p1
    ldr w11, [x9, w19, uxtw #2]   // Cargar elemento de B

    mul w12, w10, w11             // Multiplicacion: A * B
    
    ldr x9, =matriz_r_p1
    str w12, [x9, w19, uxtw #2]   // Guardar en Resultante

    add w19, w19, 1
    b loop_op_p1

// --- IMPRESION DE RESULTADOS ---
print_p1:
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_header_res
    mov x2, 45
    svc 0

    mov w6, 0                     // i = 0
loop_f_pr:
    cmp w6, w4
    b.ge fin_p1

    mov x8, 64
    mov x0, 1
    ldr x1, =abre_cor
    mov x2, 2
    svc 0

    mov w7, 0                     // j = 0
loop_c_pr:
    cmp w7, w5
    b.ge sig_f_pr

    mul w13, w6, w5
    add w13, w13, w7
    ldr x9, =matriz_r_p1
    ldr w15, [x9, w13, uxtw #2]   // Valor a convertir

    bl itoa_imprimir_p1

    mov x8, 64
    mov x0, 1
    ldr x1, =espacio
    mov x2, 1
    svc 0

    add w7, w7, 1
    b loop_c_pr

sig_f_pr:
    mov x8, 64
    mov x0, 1
    ldr x1, =cierra_cor
    mov x2, 7
    svc 0
    add w6, w6, 1
    b loop_f_pr

// --- MANEJO DE ERRORES Y SALIDA ---
error_vacia_p1:
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_err_vacia
    mov x2, 58
    svc 0
    b salir_p1

error_dim_p1:
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_err_dim
    mov x2, 60
    svc 0
    b salir_p1

fin_p1:
    mov x8, 64
    mov x0, 1
    ldr x1, =newline
    mov x2, 1
    svc 0

salir_p1:
    ldp x29, x30, [sp], 16        // Restaurar stack y registros
    ret

// --- SUBRUTINA ITOA ---
itoa_imprimir_p1:
    stp x29, x30, [sp, -16]!
    
    ldr x9, =itoa_buffer_p1
    mov w10, 0                    
    
    cmp w15, 0
    b.ge itoa_p_p1
    
    // Imprimir signo negativo manual
    mov w11, '-'
    strb w11, [x9]
    mov x8, 64
    mov x0, 1
    mov x1, x9
    mov x2, 1
    svc 0
    neg w15, w15

itoa_p_p1:
    mov w11, 10
    ldr x9, =itoa_buffer_p1       
itoa_div_p1:
    udiv w12, w15, w11
    msub w13, w12, w11, w15
    add w13, w13, '0'             // ASCII
    strb w13, [x9], 1             // Guardar digito
    add w10, w10, 1
    mov w15, w12
    cbnz w15, itoa_div_p1

itoa_pr_p1:
    cbz w10, itoa_f_p1
    sub x9, x9, 1                 // Retroceder puntero
    mov x8, 64
    mov x0, 1
    mov x1, x9                    
    mov x2, 1                     
    svc 0
    sub w10, w10, 1
    b itoa_pr_p1

itoa_f_p1:
    ldp x29, x30, [sp], 16        // Restaurar registros
    ret
