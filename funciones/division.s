// --- Mensajes a imprimir ---
.section .data
    msg_err_vacia:    .asciz "\nError: Primero debe ingresar la Matriz A en la opcion 1.\n"
    msg_pedir_fb:     .asciz "\nIngrese el numero de filas de B: "
    msg_pedir_cb:     .asciz "Ingrese el numero de columnas de B: "
    msg_err_dim:      .asciz "\nError: Dimensiones invalidas para A * B^-1.\n"
    msg_err_inv:      .asciz "\nError: Matriz B no es invertible (Determinante 0).\n"
    msg_ingreso_b:    .asciz "\nIngrese los valores para la Matriz B:\n"
    msg_celda_b:      .ascii "b[0][0] = "
    len_celda_b = . - msg_celda_b
    msg_header_res:   .asciz "\nResultado Division (A x B^-1)\nR = "
    abre_cor:         .asciz "[ "
    cierra_cor:       .asciz "]\n    "
    espacio:          .asciz " "
    newline:          .asciz "\n"

// --- Espacio de memoria ---
.section .bss
.align 3
    matriz_b_div:    .space 400    // Almacén para Matriz B original
    matriz_b_inv:    .space 400    // Almacén para Matriz B Inversa (Punto fijo)
    matriz_aug_div:  .space 800    // Espacio para Matriz Aumentada [B|I]
    matriz_r_div:    .space 400    // Matriz resultante R = A * B^-1
    filas_b_div:     .space 8      // Buffer para lectura de filas
    columnas_b_div:  .space 8      // Buffer para lectura de columnas
    valor_b_div:     .space 16     // Buffer para ATOI
    itoa_buffer_div: .space 32     // Buffer para ITOA decimal

.section .text
.global matriz_division

matriz_division:
    // --- PRESERVAR REGISTROS ---
    stp x29, x30, [sp, -64]!        // Guarda Frame Pointer y Link Register
    stp x19, x20, [sp, 16]          // Preserva dimensiones de A
    stp x21, x22, [sp, 32]          // Preserva dimensiones de B
    stp x25, x26, [sp, 48]          // Preserva registros auxiliares
    mov x29, sp                     // Actualiza el puntero de marco

    // --- VALIDAR MATRIZ A ---
    ldr x1, =filas                  // Carga dirección de filas de A
    ldrb w19, [x1]                  // Lee el byte de filas
    cbz w19, error_vacia_div        // Si es 0, la matriz no existe
    sub w19, w19, '0'               // Convierte ASCII a entero (m)
    ldr x1, =columnas               // Carga dirección de columnas de A
    ldrb w20, [x1]                  // Lee el byte de columnas
    sub w20, w20, '0'               // Convierte ASCII a entero (n)

    // --- PEDIR DIMENSIONES DE B ---
    mov x8, 64                      // Syscall write
    mov x0, 1                       // FD 1: stdout
    ldr x1, =msg_pedir_fb           // "Ingrese filas de B: "
    mov x2, 34                      // Longitud del mensaje
    svc 0                           // Ejecuta llamada

    mov x8, 63                      // Syscall read
    mov x0, 0                       // FD 0: stdin
    ldr x1, =filas_b_div            // Buffer de destino
    mov x2, 4                       // Lee hasta 4 bytes
    svc 0                           

    mov x8, 64                      // Syscall write
    mov x0, 1                       
    ldr x1, =msg_pedir_cb           // "Ingrese columnas de B: "
    mov x2, 37                      
    svc 0                           

    mov x8, 63                      // Syscall read
    mov x0, 0                       
    ldr x1, =columnas_b_div         
    mov x2, 4                       
    svc 0                           

    // Convertir dimensiones de B
    ldr x1, =filas_b_div            // Dirección de filas B
    ldrb w21, [x1]                  // Carga caracter
    sub w21, w21, '0'               // ASCII a entero (filas B)
    ldr x1, =columnas_b_div         // Dirección de columnas B
    ldrb w22, [x1]                  // Carga caracter
    sub w22, w22, '0'               // ASCII a entero (columnas B)

    // --- VALIDACION ALGEBRAICA (n_A == m_B) y (m_B == n_B) ---
    cmp w21, w22                    // Compara filas B vs columnas B (B debe ser cuadrada)
    b.ne error_dim_div              // Si no es cuadrada, error
    cmp w20, w21                    // Compara columnas A vs filas B
    b.ne error_dim_div              // Si no coinciden, imposible multiplicar

    // --- INGRESAR VALORES DE B ---
    mov x8, 64                      // Mensaje "Ingrese valores..."
    mov x0, 1                     
    ldr x1, =msg_ingreso_b        
    mov x2, 39                    
    svc 0                         

    mov w23, 0                      // i = 0 Contador de filas
loop_in_b_i:
    cmp w23, w21                    // i == filas B
    b.ge calcular_b_inv             // Si termino, ir a inversion
    mov w24, 0                      // j = 0 Contador de columnas
loop_in_b_j:
    cmp w24, w22                    // j == columnas B
    b.ge sig_in_b_i                 // Siguiente fila

    // Actualizar etiqueta b[i][j] dinamicamente
    ldr x1, =msg_celda_b            // Plantilla "b[0][0] = "
    add w8, w23, '0'                // Fila i a ASCII
    strb w8, [x1, 2]                // Sobrescribe pos 2
    add w9, w24, '0'                // Columna j a ASCII
    strb w9, [x1, 5]                // Sobrescribe pos 5

    mov x8, 64                      // Imprime etiqueta b[i][j]
    mov x0, 1                     
    ldr x1, =msg_celda_b          
    mov x2, len_celda_b           
    svc 0                         

    mov x8, 63                      // Lee valor numerico
    mov x0, 0                     
    ldr x1, =valor_b_div          
    mov x2, 8                     
    svc 0                         

    // ATOI
    ldr x1, =valor_b_div            // Direccion del buffer
    mov w10, 0                      // Acumulador
    mov w11, 1                      // Signo
    ldrb w12, [x1]                  // Lee primer byte
    cmp w12, '-'                    // Es negativo
    b.ne atoi_b_start             
    mov w11, -1                     // Cambia signo a -1
    add x1, x1, 1                   // Salta el '-'
atoi_b_start:
    ldrb w12, [x1], 1               // Carga byte y avanza
    cmp w12, '\n'                   // Fin de linea
    b.eq atoi_b_done              
    cbz w12, atoi_b_done            // Fin de cadena
    sub w12, w12, '0'               // Convierte a dígito
    mov w9, 10                      // Base 10
    mul w10, w10, w9                // acum = acum * 10
    add w10, w10, w12               // acum = acum + dígito
    b atoi_b_start                
atoi_b_done:
    mul w10, w10, w11               // Aplica signo final

    mul w13, w23, w22               // Indice Row-Major: i * columnas
    add w13, w13, w24               // Indice final: (i * col) + j
    ldr x14, =matriz_b_div          // Base de B
    str w10, [x14, w13, uxtw #2]    // Guarda en matriz_b_div[i][j]

    add w24, w24, 1                 // j++
    b loop_in_b_j                 
sig_in_b_i:
    add w23, w23, 1                 // i++
    b loop_in_b_i                 

// --- CALCULAR INVERSA DE B (GAUSS-JORDAN) ---
calcular_b_inv:
    // A. Construir Aumentada [B | I]
    mov w23, 0                      // i = 0
loop_build_aug:
    cmp w23, w21                    // i == n
    b.ge resolver_gauss             // Ir a fase de reducción
    mov w24, 0                      // j = 0
loop_build_aug_j:
    mov w8, w21                     // Carga n
    lsl w8, w8, 1                   // w8 = 2n columnas totales aumentada
    cmp w24, w8                     // j == 2n
    b.ge next_aug_i                 

    mul w13, w23, w8                // i * 2n
    add w13, w13, w24               // Indice lineal aumentada

    cmp w24, w21                    // Estamos en la mitad izquierda (B)
    b.ge poner_identidad_div        

    // Lado B: Copiar valores originales de B
    mul w14, w23, w21               // i * n
    add w14, w14, w24               // Indice lineal B
    ldr x9, =matriz_b_div           // Base B
    ldr w10, [x9, w14, uxtw #2]     // Carga B[i][j]
    b guardar_aug_div             

poner_identidad_div:
    sub w14, w24, w21               // j relativo = j - n
    cmp w14, w23                    // j_relativo == i Diagonal
    mov w10, 0                      // Valor por defecto
    b.ne guardar_aug_div          
    mov w10, 1                      // Diagonal = 1

guardar_aug_div:
    ldr x9, =matriz_aug_div         // Base aumentada
    str w10, [x9, w13, uxtw #2]     // Guarda en [B|I]
    add w24, w24, 1                 // j++
    b loop_build_aug_j            
next_aug_i:
    add w23, w23, 1                 // i++
    b loop_build_aug              

resolver_gauss:
    mov w23, 0                      // k = pivote actual

loop_k_gj:
    cmp w23, w21                    // k == n Verifica si termino todas las columnas de pivote
    b.ge extraer_inv_final          // Si termino, procede a extraer la matriz inversa
    mov w8, w21                     // Carga n en w8
    lsl w8, w8, 1                   // w8 = 2n total de columnas en la matriz aumentada
    mul w13, w23, w8                // Índice: k * 2n (fila del pivote)
    add w13, w13, w23               // Índice: (k * 2n) + k (posición diagonal)
    ldr x15, =matriz_aug_div        // Carga base de la matriz aumentada
    ldr w16, [x15, w13, uxtw #2]    // w16 = valor del pivote actual A[k][k]
    cbz w16, error_inv_singular     // Si el pivote es 0, la matriz no es invertible
    mov w22, 0                      // i = 0 (fila objetivo para eliminación)
loop_i_gj:
    cmp w22, w21                    // i == n Verifica si se procesaron todas las filas
    b.ge proximo_k                  // Siguiente columna de pivote
    cmp w22, w23                    // Es la fila del pivote actual (i == k)
    b.eq saltar_fila_pivote_div     // Si es la fila del pivote, no se opera sobre si misma
    mul w13, w22, w8                // indice: i * 2n
    add w13, w13, w23               // Indice: (i * 2n) + k (elemento a anular)
    ldr w17, [x15, w13, uxtw #2]    // w17 = Factor de eliminación A[i][k]
    mov w24, 0                      // j = 0 recorrido de columnas para la fila i
loop_j_gj:
    cmp w24, w8                     // j == 2n Verifica si termino la fila
    b.ge saltar_fila_pivote_div     // Siguiente fila i
    mul w13, w22, w8                // i * 2n
    add w13, w13, w24               // Índice: (i * 2n) + j
    ldr w11, [x15, w13, uxtw #2]    // w11 = Valor actual A[i][j]
    mul w14, w23, w8                // k * 2n
    add w14, w14, w24               // Índice: (k * 2n) + j
    ldr w12, [x15, w14, uxtw #2]    // w12 = Valor en fila pivote A[k][j]
    mul w11, w11, w16               // A[i][j] = A[i][j] * pivote
    mul w12, w12, w17               // Valor temporal = A[k][j] * factor
    sub w11, w11, w12               // A[i][j] = (A[i][j]*pivote) - (A[k][j]*factor)
    str w11, [x15, w13, uxtw #2]    // Guarda el nuevo valor en la matriz aumentada
    add w24, w24, 1                 // j++
    b loop_j_gj                     // Repetir para siguiente columna j
saltar_fila_pivote_div:
    add w22, w22, 1                 // i++
    b loop_i_gj                     // Repetir para siguiente fila i
proximo_k:
    add w23, w23, 1                 // k++ Siguiente columna de pivote
    b loop_k_gj                     // Repetir proceso de Gauss-Jordan
extraer_inv_final:
    mov w23, 0                      // i = 0 reinicio para extraccion
loop_ex_i:
    cmp w23, w21                    // i == n Verifica si se extrajeron todas las filas
    b.ge loop_mult_inicia           // Proceder a la multiplicacion A * B_inv
    mov w8, w21                     // w8 = n
    lsl w8, w8, 1                   // w8 = 2n
    mul w13, w23, w8                // Indice: i * 2n
    add w13, w13, w23               // Indice: (i * 2n) + i (elemento diagonal)
    ldr x15, =matriz_aug_div        // Base aumentada
    ldr w16, [x15, w13, uxtw #2]    // w16 = Divisor pivote final de la fila i
    mov w24, w21                    // j = n inicio de la parte derecha/inversa
loop_ex_j:
    cmp w24, w8                     // j == 2n
    b.ge next_ex_i_div              // Siguiente fila i
    mul w13, w23, w8                // i * 2n
    add w13, w13, w24               // Indice: (i * 2n) + j
    ldr w10, [x15, w13, uxtw #2]    // Carga valor de la matriz inversa cruda
    mov w11, 100                    // Factor de escala para punto fijo
    mul w10, w10, w11               // Escalar valor: valor * 100
    sdiv w10, w10, w16              // Normalizar: (valor * 100) / pivote
    sub w14, w24, w21               // Indice j relativo: j - n
    mul w13, w23, w21               // i * n
    add w13, w13, w14               // Indice final en matriz inversa
    ldr x9, =matriz_b_inv           // Carga direccion destino
    str w10, [x9, w13, uxtw #2]     // Almacena el valor normalizado en matriz_b_inv
    add w24, w24, 1                 // j++
    b loop_ex_j                     // Siguiente columna j
next_ex_i_div:
    add w23, w23, 1                 // i++
    b loop_ex_i                     // Siguiente fila i
loop_mult_inicia:
    mov w23, 0                      // i = 0 (ilas de A
loop_mult_i_div:
    cmp w23, w19                    // i == filas de A
    b.ge imprimir_div_res           // Si termino, ir a imprimir
    mov w24, 0                      // j = 0 columnas de B_inv
loop_mult_j_div:
    cmp w24, w21                    // j == n columnas de B_inv
    b.ge sig_mult_i_div             // Siguiente fila de A
    mov x25, 0                      // x25 = 0 Acumulador de producto punto de 64 bits
    mov w26, 0                      // k = 0 indice comun
loop_mult_k_div:
    cmp w26, w20                    // k == columnas de A
    b.ge guardar_mult_r_div         // Si termino k, guardar celda resultante
    mul w13, w23, w20               // i * n_A
    add w13, w13, w26               // (i * n_A) + k
    ldr x9, =matriz                 // Base matriz A
    ldr w10, [x9, w13, uxtw #2]     // w10 = A[i][k]
    mul w11, w26, w21               // k * n_B
    add w11, w11, w24               // (k * n_B) + j
    ldr x9, =matriz_b_inv           // Base matriz B inversa
    ldr w12, [x9, w11, uxtw #2]     // w12 = B_inv[k][j]
    mul w10, w10, w12               // Producto temporal
    add x25, x25, x10               // Acumula en 64 bits para evitar desbordamiento
    add w26, w26, 1                 // k++
    b loop_mult_k_div               // Siguiente k
guardar_mult_r_div:
    mul w13, w23, w21               // i * n_B
    add w13, w13, w24               // (i * n_B) + j
    ldr x9, =matriz_r_div           // Base matriz resultante
    str w25, [x9, w13, uxtw #2]     // Guarda resultado final de la celda
    add w24, w24, 1                 // j++
    b loop_mult_j_div               // Siguiente columna j
sig_mult_i_div:
    add w23, w23, 1                 // i++
    b loop_mult_i_div               // Siguiente fila i
error_inv_singular:
    ldr x1, =msg_err_inv            // Mensaje: Matriz no invertible
    mov x8, 64                      // write
    mov x0, 1                       // stdout
    mov x2, 53                      // longitud
    svc 0                           
    b salir_division                
imprimir_div_res:
    mov x8, 64                      // write
    mov x0, 1                       
    ldr x1, =msg_header_res         // Encabezado del resultado
    mov x2, 37                      
    svc 0                           
    mov w23, 0                      // i = 0 recorrido de filas
loop_p_f:
    cmp w23, w19                    // Termino filas de A
    b.ge fin_division               
    mov x8, 64                      // Imprime "[ "
    mov x0, 1                       
    ldr x1, =abre_cor               
    mov x2, 2                       
    svc 0                           
    mov w24, 0                      // j = 0 recorrido de columnas
loop_p_c:
    cmp w24, w22                    // Termino columnas de B
    b.ge sig_p_f                    
    mul w13, w23, w22               // i * n_B
    add w13, w13, w24               // (i * n_B) + j
    ldr x9, =matriz_r_div           // Base resultante
    ldr w15, [x9, w13, uxtw #2]     // Carga valor para ITOA
    bl itoa_imprimir_div            // Convierte e imprime con punto decimal
    mov x8, 64                      // Imprime espacio
    mov x0, 1                       
    ldr x1, =espacio                
    mov x2, 1                       
    svc 0                           
    add w24, w24, 1                 // j++
    b loop_p_c                      
sig_p_f:
    mov x8, 64                      // Imprime "]\n"
    mov x0, 1                       
    ldr x1, =cierra_cor             
    mov x2, 7                       
    svc 0                           
    add w23, w23, 1                 // i++
    b loop_p_f                      
error_vacia_div:
    ldr x1, =msg_err_vacia          // Error: Matriz A no existe
    b print_err_div                 
error_dim_div:
    ldr x1, =msg_err_dim            // Error: Dimensiones no compatibles
print_err_div:
    mov x8, 64                      // write
    mov x0, 1                       
    mov x2, 60                      
    svc 0                           
    b salir_division                
fin_division:
    mov x8, 64                      // Imprime salto de línea final
    mov x0, 1                       
    ldr x1, =newline                
    mov x2, 1                       
    svc 0                           
salir_division:
    ldp x25, x26, [sp, 48]          // Restaurar registros preservados
    ldp x21, x22, [sp, 32]          
    ldp x19, x20, [sp, 16]          
    ldp x29, x30, [sp], 64          // Restaurar FP y LR y limpiar stack
    ret                             
itoa_imprimir_div:
    stp x29, x30, [sp, -32]!        // Guardar estado de la subrutina
    ldr x9, =itoa_buffer_div        // Buffer para conversión
    mov w10, 0                      // Contador de dígitos
    cmp w15, 0                      // Es negativo
    b.ge itoa_pos                   
    mov w11, '-'                    // Imprimir signo negativo
    strb w11, [x9]                  
    mov x8, 64                      
    mov x0, 1                       
    mov x1, x9                      
    mov x2, 1                       
    svc 0                           
    neg w15, w15                    // Trabajar con valor absoluto
itoa_pos:
    mov w11, 10                     // Divisor base 10
    ldr x9, =itoa_buffer_div        
itoa_loop:
    cmp w10, 2                      // Insertar punto decimal en posicion 2
    b.ne itoa_digit                 
    mov w18, '.'                    
    strb w18, [x9], 1               
    add w10, w10, 1                 
itoa_digit:
    udiv w12, w15, w11              // Division para extraer digitos
    msub w13, w12, w11, w15         
    add w13, w13, '0'               // Convertir a ASCII
    strb w13, [x9], 1               
    add w10, w10, 1                 
    mov w15, w12                    
    cbnz w15, itoa_loop             // Repetir hasta procesar todo el numero
    cmp w10, 3                      // Asegurar al menos 3 caracteres
    b.lt itoa_loop                  
itoa_rev:
    cbz w10, itoa_done              // Imprimir digitos en orden correcto
    sub x9, x9, 1                   
    mov x8, 64                      
    mov x0, 1                       
    mov x1, x9                      
    mov x2, 1                       
    svc 0                           
    sub w10, w10, 1                 
    b itoa_rev                      
itoa_done:
    ldp x29, x30, [sp], 32          // Restaurar y retornar
    ret
