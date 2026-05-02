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
    matriz_b_mp:    .space 400    // Reserva 400 bytes para matriz B
    matriz_r_mp:    .space 400    // Reserva 400 bytes para matriz resultante R
    filas_b_mp:     .space 2      // Espacio para almacenar filas de B
    columnas_b_mp:  .space 2      // Espacio para almacenar columnas de B
    valor_b_mp:     .space 8      // Buffer para lectura de teclado
    itoa_buffer_mp: .space 16     // Buffer para conversion de números a texto

.section .text
.global matriz_multip

// --- Inicio del proceso de multiplicación cruz ---
matriz_multip:
    stp x29, x30, [sp, -16]!      // Guarda Frame Pointer y Link Register en el stack

    // --- VALIDAR MATRIZ A ---
    ldr x1, =filas                // Carga direccion de la variable filas de A
    ldrb w4, [x1]                 // Lee el byte de filas en w4
    cbz w4, error_vacia_mp        // Salta si w4 es nulo (sin matriz A)
    cmp w4, '0'                   // Compara con el caracter '0'
    b.eq error_vacia_mp           // Salta si es igual a '0'

    ldr x1, =columnas             // Carga direccion de columnas de A
    ldrb w5, [x1]                 // Lee el byte de columnas en w5
    sub w4, w4, '0'               // m = Filas de A 
    sub w5, w5, '0'               // n = Columnas de A

    // --- PEDIR DIMENSIONES DE B ---
    mov x8, 64                    // Syscall 64: write
    mov x0, 1                     // FD 1: stdout
    ldr x1, =msg_pedir_fb         // Mensaje: "Ingrese filas de B: "
    mov x2, 34                    // Longitud del mensaje
    svc 0                         // Llamada al sistema

    mov x8, 63                    // Syscall 63: read
    mov x0, 0                     // FD 0: stdin
    ldr x1, =filas_b_mp           // Buffer de destino
    mov x2, 2                     // Leer 2 bytes
    svc 0                         

    mov x8, 64                    // Syscall write
    mov x0, 1                     
    ldr x1, =msg_pedir_cb
    mov x2, 37                    
    svc 0                         

    mov x8, 63                    // Syscall read
    mov x0, 0                     
    ldr x1, =columnas_b_mp        
    mov x2, 2                     
    svc 0                         

    // -- Convertir dimensiones de B --
    ldr x1, =filas_b_mp           // Direccion de filas B
    ldrb w21, [x1]                // Carga el byte
    sub w21, w21, '0'             // n = Filas de B

    ldr x1, =columnas_b_mp        // Direccion de columnas B
    ldrb w22, [x1]                // Carga el byte
    sub w22, w22, '0'             // p = Columnas de B

    // --- VALIDAR REGLA DE MULTIPLICACION (Col A == Fil B) ---
    cmp w5, w21                   // Compara columnas de A con filas de B
    b.ne error_dim_mp             // Salta si n != n (imposible multiplicar)

    // --- INGRESAR VALORES DE MATRIZ B ---
    mov x8, 64                    // Syscall write
    mov x0, 1                     
    ldr x1, =msg_ingreso_b        // Mensaje de inicio de ingreso
    mov x2, 39                    
    svc 0                         

    mov w6, 0                     // i = 0 (Contador de filas de B)
loop_fb_mp:
    cmp w6, w21                   // i == filas B
    b.ge eval_multip              // Si termino, ir a la multiplicacion logica
    mov w7, 0                     // j = 0 Contador de columnas de B
loop_cb_mp:
    cmp w7, w22                   // j == columnas B
    b.ge sig_fb_mp                // Si termino columnas, siguiente fila

    // -- Actualizar etiqueta de celda b[i][j] --
    ldr x1, =msg_celda_b          // Carga plantilla "b[0][0] = "
    add w8, w6, '0'               // Convierte indice i a ASCII
    strb w8, [x1, 2]              // Reemplaza el caracter en pos 2
    add w9, w7, '0'               // Convierte indice j a ASCII
    strb w9, [x1, 5]              // Reemplaza el caracter en pos 5

    mov x8, 64                    // Syscall write
    mov x0, 1                     
    ldr x1, =msg_celda_b          // Imprime "b[i][j] = "
    ldr x2, =len_celda_b          
    svc 0                         

    mov x8, 63                    // Syscall read
    mov x0, 0                     
    ldr x1, =valor_b_mp           // Lee valor numerico como texto
    mov x2, 8                     
    svc 0                         

    // --- ALGORITMO ATOI ---
    ldr x1, =valor_b_mp           // Puntero al inicio del buffer leído
    mov w10, 0                    // Acumulador numérico = 0
    mov w11, 1                    // Multiplicador de signo = 1 
    ldrb w12, [x1]                // Carga primer carácter
    cmp w12, '-'                  // Es negativo
    b.ne loop_atoi_mp             
    mov w11, -1                   // Cambia signo a -1
    add x1, x1, 1                 // Avanza puntero para saltar el '-'
loop_atoi_mp:
    ldrb w12, [x1], 1             // Carga byte y post-incrementa puntero
    cmp w12, '\n'                 // Es fin de linea
    b.eq fin_atoi_mp              
    cbz w12, fin_atoi_mp          // Es fin de cadena
    sub w12, w12, '0'             // Convierte ASCII a digito
    mov w9, 10                    // Base 10
    mul w10, w10, w9              // acumulado = acumulado * 10
    add w10, w10, w12             // acumulado = acumulado + digito
    b loop_atoi_mp                
fin_atoi_mp:
    mul w10, w10, w11             // Resultado final = acumulado * signo

    // -- Almacenar en Matriz B --
    mul w13, w6, w22              // Indice: i * p (columnas de B)
    add w13, w13, w7              // Indice: (i * p) + j
    ldr x14, =matriz_b_mp         // Base de la matriz B
    str w10, [x14, w13, uxtw #2]  // Guarda valor (w13 << 2 para offset de 4 bytes)

    add w7, w7, 1                 // j++
    b loop_cb_mp                  
sig_fb_mp:
    add w6, w6, 1                 // i++
    b loop_fb_mp                  

// --- OPERACION DE MULTIPLICACION (Fila A x Columna B) ---
eval_multip:
    mov w6, 0                     // i = 0 (Filas de A)
loop_multi_i:
    cmp w6, w4                    // i == filas A
    b.ge print_result_mp          // Si termino todas las filas, ir a imprimir
    
    mov w7, 0                     // j = 0 (Columnas de B)
loop_multi_j:
    cmp w7, w22                   // j == columnas B
    b.ge sig_multi_i              // Si termino columnas, siguiente fila i
    
    mov w25, 0                    // w25 = 0 Acumulador para el producto punto
    mov w8, 0                     // k = 0 Indice comun: columnas A / filas B
loop_multi_k:
    cmp w8, w5                    // k == columnas A
    b.ge guardar_celda_c          // Si termino k, guardar el resultado en R[i][j]
    
    // -- Leer A[i][k] --
    mul w13, w6, w5               // i * columnas A
    add w13, w13, w8              // (i * n) + k
    ldr x9, =matriz               // Base de matriz A
    ldr w10, [x9, w13, uxtw #2]   // Carga A[i][k]
    
    // -- Leer B[k][j] --
    mul w11, w8, w22              // k * columnas B
    add w11, w11, w7              // (k * p) + j
    ldr x9, =matriz_b_mp          // Base de matriz B
    ldr w12, [x9, w11, uxtw #2]   // Carga B[k][j]
    
    mul w10, w10, w12             // w10 = A[i][k] * B[k][j]
    add w25, w25, w10             // w25 (acumulado) += w10
    
    add w8, w8, 1                 // k++
    b loop_multi_k                

guardar_celda_c:
    // -- Guardar en R[i][j] --
    mul w13, w6, w22              // Indice: i * p (columnas de B)
    add w13, w13, w7              // Indice: (i * p) + j
    ldr x9, =matriz_r_mp          // Base de matriz R (Resultante)
    str w25, [x9, w13, uxtw #2]   // Guarda el acumulado final en R[i][j]
    
    add w7, w7, 1                 // j++
    b loop_multi_j                

sig_multi_i:
    add w6, w6, 1                 // i++
    b loop_multi_i                

// --- IMPRESION DE MATRIZ RESULTANTE ---
print_result_mp:
    mov x8, 64                    // Syscall write
    mov x0, 1                     
    ldr x1, =msg_header_res       // Mensaje: "R = "
    mov x2, 33                    
    svc 0                         

    mov w6, 0                     // i = 0 (Filas para impresión)
loop_print_f_mp:
    cmp w6, w4                    // ¿i == filas A?
    b.ge fin_rutina_mp            

    mov x8, 64                    // Syscall write
    mov x0, 1                     
    ldr x1, =abre_cor             // Imprime "[ "
    mov x2, 2                     
    svc 0                         

    mov w7, 0                     // j = 0 Columnas para impresion
loop_print_c_mp:
    cmp w7, w22                   // j == columnas B
    b.ge sig_print_fila_mp        

    mul w13, w6, w22              // Indice: i * p
    add w13, w13, w7              // Indice: (i * p) + j
    ldr x9, =matriz_r_mp          // Base resultante
    ldr w15, [x9, w13, uxtw #2]   // w15 = R[i][j] Valor a imprimir

    bl itoa_imprimir_mp           // Llama a la subrutina ITOA

    mov x8, 64                    // Syscall write
    mov x0, 1                     
    ldr x1, =espacio              // Imprime espacio " "
    mov x2, 1                     
    svc 0                         

    add w7, w7, 1                 // j++
    b loop_print_c_mp             

sig_print_fila_mp:
    mov x8, 64                    // Syscall write
    mov x0, 1                     
    ldr x1, =cierra_cor           // Imprime "]\n"
    mov x2, 7                     
    svc 0                         

    add w6, w6, 1                 // i++
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
    ldp x29, x30, [sp], 16        // Restaura registros y stack
    ret                           

// --- SUBRUTINA ITOA ---
itoa_imprimir_mp:
    stp x29, x30, [sp, -16]!      // Guarda registros de subrutina
    ldr x9, =itoa_buffer_mp       // x9 = Puntero al buffer de texto
    mov w10, 0                    // Contador de dígitos = 0
    cmp w15, 0                    // Es el valor negativo
    b.ge itoa_no_neg_mp           
    
    // Imprimir signo negativo manual
    mov w11, '-'                  // Carga '-'
    strb w11, [x9]                // Guarda en buffer
    mov x8, 64                    // Syscall write
    mov x0, 1                     
    mov x1, x9                    // Dirección del '-'
    mov x2, 1                     
    svc 0                         
    neg w15, w15                  // Convierte w15 a positivo absoluto

itoa_no_neg_mp:
    mov w11, 10                   // Divisor = 10
    ldr x9, =itoa_buffer_mp       // Reinicia puntero al inicio
itoa_div_mp:
    udiv w12, w15, w11            // w12 = cociente
    msub w13, w12, w11, w15       // w13 = residuo
    add w13, w13, '0'             // Convierte a ASCII
    strb w13, [x9], 1             // Guarda digito y avanza
    add w10, w10, 1               // Contador++
    mov w15, w12                  // Actualiza número con cociente
    cbnz w15, itoa_div_mp         // Repetir mientras cociente != 0

itoa_print_mp:
    cbz w10, itoa_fin_mp          // Si no hay mas dígitos, salir
    sub x9, x9, 1                 // Retrocede puntero al digito guardado
    mov x8, 64                    // Syscall write
    mov x0, 1                     
    mov x1, x9                    // Dirección del caracter
    mov x2, 1                     
    svc 0                         
    sub w10, w10, 1               // Contador--
    b itoa_print_mp               

itoa_fin_mp:
    ldp x29, x30, [sp], 16        // Restaura registros
    ret
