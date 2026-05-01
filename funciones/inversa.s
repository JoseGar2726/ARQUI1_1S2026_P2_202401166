// Mensajes a imprimir
.section .data
    msg_err_vacia:    .asciz "\nError: Primero debe ingresar una matriz en la opcion 1.\n"
    msg_err_cua:      .asciz "\nError: La matriz debe ser CUADRADA para tener inversa.\n"
    msg_header_inv:   .asciz "\nMatriz Inversa:\nA^-1 = "
    
    abre_cor:         .asciz "[ "
    cierra_cor:       .asciz "]\n       "
    espacio:          .asciz " "
    newline:          .asciz "\n"

// --- Matriz aumentada: espacio para max 10x20  ---
.section .bss
    matriz_aumentada: .space 800

.section .text
.global matriz_inversa

// --- Inicio proceso ---
matriz_inversa:
    stp x29, x30, [sp, -16]! 

    // --- Validar existencia y dimensiones de la matriz ---
    ldr x1, =filas          
    ldrb w4, [x1]           
    cbz w4, error_vacia     
    cmp w4, '0'             
    b.eq error_vacia        

    ldr x1, =columnas       
    ldrb w5, [x1]           

    cmp w4, w5
    b.ne error_cuadrada

    // --- Configurar dimensiones de la matriz aumentada [A|I] ---
    sub w4, w4, '0'         // n (original)
    mov w5, w4              
    lsl w5, w5, 1           // 2n (columnas totales)

    // --- Impresión del encabezado ---
    mov x8, 64              
    mov x0, 1               
    ldr x1, =msg_header_inv  
    mov x2, 24              
    svc 0                   

    // --- CONSTRUIR MATRIZ AUMENTADA [ A | I ] ---
    mov w21, 0              // i = 0
loop_aug_i:
    cmp w21, w4
    b.ge fin_aug

    mov w22, 0              // j = 0
loop_aug_j:
    cmp w22, w5
    b.ge sig_aug_i

    mul w13, w21, w5
    add w13, w13, w22

    // Determinar si insertar valor de A o de la Identidad
    cmp w22, w4
    b.ge es_identidad

    // Mitad Izquierda: Cargar de matriz original
    mul w14, w21, w4        
    add w14, w14, w22
    ldr x15, =matriz
    ldr w16, [x15, w14, uxtw #2]
    b guardar_aug

es_identidad:
    // Mitad Derecha: Generar diagonal de 1
    sub w14, w22, w4        
    cmp w14, w21            
    mov w16, 0              
    b.ne guardar_aug
    mov w16, 1              

guardar_aug:
    ldr x15, =matriz_aumentada
    str w16, [x15, w13, uxtw #2]

    add w22, w22, 1
    b loop_aug_j

sig_aug_i:
    add w21, w21, 1
    b loop_aug_i

fin_aug:

    // --- APLICAR GAUSS-JORDAN ---
    mov w21, 0              // k = Pivote

loop_pivote_k:
    cmp w21, w4             
    b.ge fin_gj_inv   

    // Cargar Pivote A[k][k]
    mul w13, w21, w5        
    add w13, w13, w21       
    ldr x15, =matriz_aumentada
    ldr w16, [x15, w13, uxtw #2] 

    cbz w16, sig_pivote_k   

    mov w22, 0              // i = Fila objetivo

loop_filas_i:
    cmp w22, w4             
    b.ge sig_pivote_k       

    cmp w22, w21            
    b.eq sig_fila_i         

    // Cargar factor de eliminación A[i][k]
    mul w13, w22, w5        
    add w13, w13, w21       
    ldr w17, [x15, w13, uxtw #2] 

    mov w23, 0              // j = Columnas

loop_columnas_j:
    cmp w23, w5             
    b.ge sig_fila_i         

    // Operación de fila: A[i][j] = (Pivote * A[i][j]) - (Objetivo * A[k][j])
    mul w13, w22, w5        
    add w13, w13, w23       
    ldr w24, [x15, w13, uxtw #2]

    mul w14, w21, w5        
    add w14, w14, w23       
    ldr w25, [x15, w14, uxtw #2]

    mul w26, w16, w24       
    mul w27, w17, w25       
    sub w28, w26, w27       

    str w28, [x15, w13, uxtw #2]

    add w23, w23, 1         
    b loop_columnas_j       

sig_fila_i:
    add w22, w22, 1         
    b loop_filas_i

sig_pivote_k:
    add w21, w21, 1         
    b loop_pivote_k

fin_gj_inv:

    // --- IMPRESIÓN DE LA INVERSA ---
    mov w6, 0               // Fila i

loop_print_f:
    cmp w6, w4              
    b.ge fin_inversa            

    // Imprimir inicio de fila
    mov x8, 64                                      
    mov x0, 1                                       
    ldr x1, =abre_cor                               
    mov x2, 2                                       
    svc 0                                           

    // Obtener divisor de la fila (Pivote final A[i][i])
    mul w13, w6, w5
    add w13, w13, w6
    ldr x14, =matriz_aumentada
    ldr w16, [x14, w13, uxtw #2]  

    mov w7, w4              // j empieza en n (Lado derecho de la aumentada)

loop_print_c:
    cmp w7, w5                                      
    b.ge sig_print_fila             

    mul w13, w6, w5                                 
    add w13, w13, w7                                
    ldr w15, [x14, w13, uxtw #2]  

    // Escalar valor por 100 para obtener 2 decimales mediante división entera
    mov w18, 100
    mul w15, w15, w18       
    
    cbnz w16, hacer_div
    mov w15, 0              
    b saltar_div
hacer_div:
    sdiv w15, w15, w16      
saltar_div:

    // --- Subrutina ITOA ---
    sub sp, sp, 32          
    mov x9, sp                                      
    mov w10, 0              

    // Gestión del signo negativo
    cmp w15, 0                                      
    b.ge no_negativo                                

    mov w11, '-'                                    
    strb w11, [sp, 31]                              
    mov x8, 64
    mov x0, 1
    add x1, sp, 31                                  
    mov x2, 1
    svc 0
    neg w15, w15                                     
    
no_negativo:
    mov w11, 10                                     
loop_dividir:
    // Insertar el punto visual al llegar a la posición de centésimas
    cmp w10, 2
    b.ne seguir_div
    mov w18, '.'
    strb w18, [x9], 1
    add w10, w10, 1

seguir_div:
    udiv w12, w15, w11                               
    msub w13, w12, w11, w15                          
    add w13, w13, '0'                                
    strb w13, [x9], 1                                
    add w10, w10, 1                                  
    mov w15, w12                                     
    
    // 3 caracteres
    cbnz w15, loop_dividir
    cmp w10, 3
    b.lt loop_dividir

loop_imprimir_digitos:
    cbz w10, fin_itoa       
    sub x9, x9, 1           
    mov x8, 64
    mov x0, 1
    mov x1, x9                                      
    mov x2, 1                                       
    svc 0
    sub w10, w10, 1                                 
    b loop_imprimir_digitos 

fin_itoa:
    add sp, sp, 32                                  
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
    mov x2, 8
    svc 0

    add w6, w6, 1                                  
    b loop_print_f                                 

// --- Manejo de errores y salida ---
error_vacia:
    mov x8, 64                                      
    mov x0, 1                                       
    ldr x1, =msg_err_vacia                          
    mov x2, 55                                      
    svc 0                                           
    b salir_rutina                                  

error_cuadrada:
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_err_cua
    mov x2, 56
    svc 0
    b salir_rutina

fin_inversa:
    mov x8, 64                                      
    mov x0, 1                                       
    ldr x1, =newline                                
    mov x2, 1                                       
    svc 0                                           

salir_rutina:
    ldp x29, x30, [sp], 16                          
    ret
