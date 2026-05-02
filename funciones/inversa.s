// Mensajes a imprimir
.section .data
    msg_err_vacia:    .asciz "\nError: Primero debe ingresar una matriz en la opcion 1.\n"
    msg_err_cua:      .asciz "\nError: La matriz debe ser CUADRADA para tener inversa.\n"
    msg_header_inv:   .asciz "\nMatriz Inversa:\nA^-1 = "
    
    abre_cor:         .asciz "[ "
    cierra_cor:       .asciz "]\n       "
    espacio:          .asciz " "
    newline:          .asciz "\n"

// --- Matriz aumentada: espacio para max 10x20 ---
.section .bss
    matriz_aumentada: .space 800                // Reserva 800 bytes (10x20 elementos de 4 bytes)

.section .text
.global matriz_inversa

// --- Inicio proceso ---
matriz_inversa:
    stp x29, x30, [sp, -16]!                    // Guarda Frame Pointer y Link Register en el stack

    // --- Validar existencia y dimensiones de la matriz ---
    ldr x1, =filas                              // Carga direccion de la variable filas
    ldrb w4, [x1]                               // Lee el byte de filas en w4
    cbz w4, error_vacia                         // Salta si w4 es 0 (null)
    cmp w4, '0'                                 // Compara con el carácter '0'
    b.eq error_vacia                            // Salta si es igual a '0'

    ldr x1, =columnas                           // Carga direccion de columnas
    ldrb w5, [x1]                               // Lee el byte de columnas en w5

    cmp w4, w5                                  // Compara filas vs columnas (deben ser iguales)
    b.ne error_cuadrada                         // Si no son iguales, no es cuadrada

    // --- Configurar dimensiones de la matriz aumentada [A|I] ---
    sub w4, w4, '0'                             // Convierte ASCII de filas a entero (n)
    mov w5, w4                                  // Copia n a w5
    lsl w5, w5, 1                               // w5 = n * 2 (columnas totales de la aumentada)

    // --- Impresión del encabezado ---
    mov x8, 64                                  // Syscall 64: write
    mov x0, 1                                   // FD 1: stdout
    ldr x1, =msg_header_inv                     // Dirección del mensaje de encabezado
    mov x2, 24                                  // Longitud del mensaje
    svc 0                                       // Llamada al sistema

    // --- CONSTRUIR MATRIZ AUMENTADA [ A | I ] ---
    mov w21, 0                                  // i = 0 (Contador de filas)
loop_aug_i:
    cmp w21, w4                                 // i == n
    b.ge fin_aug                                // Si terminó filas, salir del bucle

    mov w22, 0                                  // j = 0 (Contador de columnas)
loop_aug_j:
    cmp w22, w5                                 // j == 2n
    b.ge sig_aug_i                              // Si terminó columnas, siguiente fila

    mul w13, w21, w5                            // Indice lineal: i * (2n)
    add w13, w13, w22                           // Indice lineal final: (i * 2n) + j

    // Determinar si insertar valor de A o de la Identidad
    cmp w22, w4                                 // j < n
    b.ge es_identidad                           // Si j >= n, estamos en la seccion de identidad

    // Mitad Izquierda: Cargar de matriz original
    mul w14, w21, w4                            // Indice original: i * n
    add w14, w14, w22                           // Indice original: (i * n) + j
    ldr x15, =matriz                            // Base de la matriz original
    ldr w16, [x15, w14, uxtw #2]                // Cargar A[i][j] (w14 << 2 para offset de 4 bytes)
    b guardar_aug                               // Saltar a guardar

es_identidad:
    // Mitad Derecha: Generar diagonal de 1
    sub w14, w22, w4                            // j_relativo = j - n
    cmp w14, w21                                // j_relativo == i
    mov w16, 0                                  // Inicializar valor en 0
    b.ne guardar_aug                            // Si no es diagonal, mantener 0
    mov w16, 1                                  // Si es diagonal, poner 1

guardar_aug:
    ldr x15, =matriz_aumentada                   // Base de la matriz aumentada
    str w16, [x15, w13, uxtw #2]                // Guardar valor en matriz_aumentada[i][j]

    add w22, w22, 1                             // j++
    b loop_aug_j                                // Repetir bucle columnas

sig_aug_i:
    add w21, w21, 1                             // i++
    b loop_aug_i                                // Repetir bucle filas

fin_aug:

    // --- APLICAR GAUSS-JORDAN ---
    mov w21, 0                                  // k = 0

loop_pivote_k:
    cmp w21, w4                                 // k == n
    b.ge fin_gj_inv                             // Si procesó todos los pivotes, terminar

    // Cargar Pivote A[k][k]
    mul w13, w21, w5                            // k * 2n
    add w13, w13, w21                           // (k * 2n) + k
    ldr x15, =matriz_aumentada                  // Base de matriz aumentada
    ldr w16, [x15, w13, uxtw #2]                // w16 = Pivote A[k][k]

    cbz w16, sig_pivote_k                       // Si el pivote es 0, evitar division

    mov w22, 0                                  // i = 0 (Fila objetivo a eliminar)

loop_filas_i:
    cmp w22, w4                                 // i == n
    b.ge sig_pivote_k                           // Si terminó filas, siguiente pivote

    cmp w22, w21                                // Es la fila del pivote (i == k)
    b.eq sig_fila_i                             // Si es la fila del pivote, no operamos en ella

    // Cargar factor de eliminación A[i][k]
    mul w13, w22, w5                            // i * 2n
    add w13, w13, w21                           // (i * 2n) + k
    ldr w17, [x15, w13, uxtw #2]                // w17 = Objetivo A[i][k]

    mov w23, 0                                  // j = 0 Recorrer columnas para la operación de fila

loop_columnas_j:
    cmp w23, w5                                 // j == 2n
    b.ge sig_fila_i                             // Si termino columnas, siguiente fila i

    // Operación de fila: A[i][j] = (Pivote * A[i][j]) - (Objetivo * A[k][j])
    mul w13, w22, w5                            // i * 2n
    add w13, w13, w23                           // (i * 2n) + j
    ldr w24, [x15, w13, uxtw #2]                // w24 = A[i][j]

    mul w14, w21, w5                            // k * 2n
    add w14, w14, w23                           // (k * 2n) + j
    ldr w25, [x15, w14, uxtw #2]                // w25 = A[k][j]

    mul w26, w16, w24                           // w26 = Pivote * A[i][j]
    mul w27, w17, w25                           // w27 = Objetivo * A[k][j]
    sub w28, w26, w27                           // w28 = Resultado de la resta

    str w28, [x15, w13, uxtw #2]                // Guardar nuevo valor en A[i][j]

    add w23, w23, 1                             // j++
    b loop_columnas_j                           // Bucle columnas j

sig_fila_i:
    add w22, w22, 1                             // i++
    b loop_filas_i                              // Bucle filas i

sig_pivote_k:
    add w21, w21, 1                             // k++
    b loop_pivote_k                             // Bucle pivote k

fin_gj_inv:

    // --- IMPRESION DE LA INVERSA ---
    mov w6, 0                                   // i = 0 contador de filas

loop_print_f:
    cmp w6, w4                                  // Termino filas
    b.ge fin_inversa                            

    // Imprimir inicio de fila "[ "
    mov x8, 64                                  // Syscall write
    mov x0, 1                                   // stdout
    ldr x1, =abre_cor                           // "[ "
    mov x2, 2                                   
    svc 0                                       

    // Obtener divisor de la fila (Pivote final A[i][i] para normalizar a 1)
    mul w13, w6, w5                             // i * 2n
    add w13, w13, w6                            // (i * 2n) + i
    ldr x14, =matriz_aumentada                  // Base aumentada
    ldr w16, [x14, w13, uxtw #2]                // w16 = Divisor (Pivote)

    mov w7, w4                                  // j = n

loop_print_c:
    cmp w7, w5                                  // j == 2n
    b.ge sig_print_fila                         

    mul w13, w6, w5                             // i * 2n
    add w13, w13, w7                            // (i * 2n) + j
    ldr w15, [x14, w13, uxtw #2]                // w15 = Dividendo (Elemento de la inversa)

    // Escalar valor por 100 para obtener 2 decimales mediante division entera
    mov w18, 100                                // Multiplicador
    mul w15, w15, w18                           // Dividendo * 100
    
    cbnz w16, hacer_div                         // Si el divisor no es 0, dividir
    mov w15, 0                                  // Si es 0, resultado es 0 por seguridad
    b saltar_div
hacer_div:
    sdiv w15, w15, w16                          // w15 = (A[i][j]*100) / Pivote
saltar_div:

    // --- Subrutina ITOA  ---
    sub sp, sp, 32                              // Reservar espacio en stack para el buffer
    mov x9, sp                                  // x9 apunta al inicio del buffer
    mov w10, 0                                  // Contador de dígitos

    // Gestión del signo negativo
    cmp w15, 0                                  // El numero es negativo
    b.ge no_negativo                            

    mov w11, '-'                                // Caracter '-'
    strb w11, [sp, 31]                          // Guardar al final del buffer
    mov x8, 64                                  // Syscall write
    mov x0, 1                                   // stdout
    add x1, sp, 31                              // Dirección del '-'
    mov x2, 1                                   
    svc 0                                       // Imprimir el signo '-'
    neg w15, w15                                // Convertir w15 a positivo
    
no_negativo:
    mov w11, 10                                 // Divisor base 10
loop_dividir:
    // Insertar el punto visual al llegar a la posicion de centésimas
    cmp w10, 2                                  // Ya procesamos 2 dígitos
    b.ne seguir_div
    mov w18, '.'                                // Caracter punto
    strb w18, [x9], 1                           // Guardar y avanzar puntero
    add w10, w10, 1                             // Incrementar contador

seguir_div:
    udiv w12, w15, w11                          // w12 = cociente
    msub w13, w12, w11, w15                     // w13 = residuo
    add w13, w13, '0'                           // Convertir a ASCII
    strb w13, [x9], 1                           // Guardar dígito y avanzar puntero
    add w10, w10, 1                             // Contador++
    mov w15, w12                                // Actualizar numero con el cociente
    
    // Condición de parada (mínimo 3 ciclos para asegurar el "0.00")
    cbnz w15, loop_dividir                      
    cmp w10, 3                                  
    b.lt loop_dividir                           

loop_imprimir_digitos:
    cbz w10, fin_itoa                           // Si no hay mas digitos, salir
    sub x9, x9, 1                               // Retroceder puntero al ultimo digito guardado
    mov x8, 64                                  // Syscall write
    mov x0, 1                                   // FD 1
    mov x1, x9                                  // Dirección del digito
    mov x2, 1                                   
    svc 0                                       // Imprimir caracter
    sub w10, w10, 1                             // Contador--
    b loop_imprimir_digitos                     

fin_itoa:
    add sp, sp, 32                              // Liberar espacio del buffer en stack
    mov x8, 64                                  // Syscall write
    mov x0, 1                                   
    ldr x1, =espacio                            // Imprimir espacio entre elementos
    mov x2, 1                                   
    svc 0                                       

    add w7, w7, 1                               // j++
    b loop_print_c                              // Repetir bucle columnas j

sig_print_fila:
    mov x8, 64                                  // Syscall write
    mov x0, 1                                   
    ldr x1, =cierra_cor                         // Imprimir "]\n"
    mov x2, 8                                   
    svc 0                                       

    add w6, w6, 1                               // i++
    b loop_print_f                              // Repetir bucle filas i

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
    ldp x29, x30, [sp], 16                      // Restaurar x29 y x30 del stack
    ret                                         // Retornar al llamador
