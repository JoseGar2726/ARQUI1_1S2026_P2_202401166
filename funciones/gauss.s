// Mensajes a imprimir
.section .data
    msg_err_vacia:    .asciz "\nError: Primero debe ingresar una matriz en la opcion 1.\n"
    msg_header_id:    .asciz "\nMetodo de Gauss:\nA = "
    
    abre_cor:         .asciz "[ "
    cierra_cor:       .asciz "]\n      "
    espacio:          .asciz "  "
    newline:          .asciz "\n"

    msg_paso_ini:     .asciz "\n--- Paso "
    msg_paso_fin:     .asciz " ---\n"
    
    msg_pivote:       .asciz "Pivote: "
    msg_fila:         .asciz "\nHaciendo 0 la fila: "

// --- Espacio de memoria ---
.section .bss
.align 3                        
    matriz_copia: .space 400
    itoa_buffer:  .space 16     

.section .text
.global matriz_gauss

// --- Inicio proceso ---
matriz_gauss:
    // --- Manejo de link register y stack pointer ---
    stp x29, x30, [sp, -16]! // Guarda x29 y x30 restando 16 bytes al stack pointer

    // --- Validar si ya se ingreso una matriz ---
    // -- Lectura del valor de filas --
    ldr x1, =filas          // Carga el valor de las filas guardado en la memoria global
    ldrb w4, [x1]           // Lee el valor de las filas y lo guarda en w4
    cbz w4, error_vacia     // Si el valor es nulo no hay matriz
    cmp w4, '0'             // Compara el valor con el caracter '0'
    b.eq error_vacia        // Si el valor es '0' tampoco hay matriz válida

    // -- Lectura del valor de columnas --
    ldr x1, =columnas       // Carga el valor de las columnas guardado en la memoria global
    ldrb w5, [x1]           // Lee el valor de las columnas y lo guarda en w5

    // --- Preparar impresion de encabezado ---
    mov x8, 64              // Syscall 64 -> write
    mov x0, 1               // File descriptor 1 -> stdout
    ldr x1, =msg_header_id  // Carga la dirección del mensaje -> encabezado
    mov x2, 22              // Longitud de la cadena
    svc 0                   // Ejecuta la llamada al sistema

    // --- Valor entero de columnas y filas ---
    sub w4, w4, '0'         // Numero filas en entero 
    sub w5, w5, '0'         // Numero columnas en entero 

    // --- Realizar copia de seguridad de la matriz original ---
    mul w18, w4, w5         // Calcular total de elementos (filas * columnas)
    mov w19, 0              // Contador para el ciclo de copia

loop_copiar:
    cmp w19, w18            // Comparar contador con total de elementos
    b.ge fin_copiar         // Si se copiaron todos, pasar a la siguiente fase

    ldr x14, =matriz        // Cargar direccion de la matriz original
    ldr w20, [x14, w19, uxtw #2] // Leer valor actual de la matriz original

    ldr x15, =matriz_copia  // Cargar direccion de la matriz de copia
    str w20, [x15, w19, uxtw #2] // Guardar valor en la copia

    add w19, w19, 1         // Incrementar contador
    b loop_copiar           // Repetir ciclo de copia

// --- Algoritmo de Gauss ---
fin_copiar:
    mov w21, 0              // w21 = k (Indice de fila pivote)
    mov w20, 1              // w20 = Contador global para mostrar los pasos

loop_pivote_k:
    add w8, w21, 1          // Calcular k + 1 para comparar
    cmp w8, w4              // Hemos llegado a la ultima fila
    b.ge fin_gauss_total    // Si k >= filas, el proceso ha terminado

    // -- Obtener Pivote A[k][k] --
    mul w13, w21, w5        // fila * total_columnas
    add w13, w13, w21       // + columna_pivote
    ldr x15, =matriz_copia  // Cargar base de la matriz de trabajo
    ldr w16, [x15, w13, uxtw #2] // Cargar valor del Pivote

    cbz w16, sig_pivote_k   // Si el pivote es 0, saltar a la siguiente fila

    mov w22, w8             // w22 = i (Indice de fila objetivo, empieza en k+1)

loop_filas_i:
    cmp w22, w4             // Hemos procesado todas las filas debajo del pivote
    b.ge sig_pivote_k       // Si i >= filas, pasar al siguiente pivote k

    ldr x15, =matriz_copia  // Recargar direccion base de la matriz

    // -- Obtener Valor Objetivo A[i][k] --
    mul w13, w22, w5        // fila_i * total_columnas
    add w13, w13, w21       // + columna_k
    ldr w17, [x15, w13, uxtw #2] // Cargar valor a eliminar (Objetivo)

    mov w23, 0              // w23 = j (Contador de columnas para la operacion de fila)

loop_columnas_j:
    cmp w23, w5             // Se han procesado todas las columnas de la fila
    b.ge sig_fila_i         // Si j >= columnas, pasar a imprimir el paso

    ldr x15, =matriz_copia  // Recargar direccion base de la matriz

    // -- Obtener A[i][j] --
    mul w13, w22, w5        
    add w13, w13, w23       
    ldr w24, [x15, w13, uxtw #2] // Cargar elemento de la fila objetivo

    // -- Obtener A[k][j] --
    mul w14, w21, w5        
    add w14, w14, w23       
    ldr w25, [x15, w14, uxtw #2] // Cargar elemento de la fila pivote

    // -- Operacion Gauss: A[i][j] = (Pivote * A[i][j]) - (Objetivo * A[k][j]) --
    mul w26, w16, w24       // Pivote * A[i][j]
    mul w27, w17, w25       // Objetivo * A[k][j]
    sub w28, w26, w27       // Resta de productos

    str w28, [x15, w13, uxtw #2] // Guardar resultado en la matriz de copia

    add w23, w23, 1         // j++
    b loop_columnas_j       // Siguiente columna

// --- Impresion detallada de los pasos ---
sig_fila_i:
    // -- Imprimir encabezado de paso --
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_paso_ini
    mov x2, 10
    svc 0
    mov w15, w20            // Pasar contador de pasos a ITOA
    bl itoa_imprimir
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_paso_fin
    mov x2, 5
    svc 0

    // -- Imprimir valor del pivote usado --
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_pivote
    mov x2, 8
    svc 0
    mov w15, w16            // Pasar valor del pivote a ITOA
    bl itoa_imprimir

    // -- Imprimir cual fila se esta modificando --
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_fila
    mov x2, 20
    svc 0
    mov w15, w22            // Pasar indice de fila a ITOA
    bl itoa_imprimir
    
    // -- Salto de linea antes de mostrar la matriz --
    mov x8, 64
    mov x0, 1
    ldr x1, =newline
    mov x2, 1
    svc 0

    bl imprimir_copia       // Llamar a rutina para mostrar estado actual de la matriz
    
    mov x8, 64
    mov x0, 1
    ldr x1, =newline
    mov x2, 1
    svc 0

    add w20, w20, 1         // Incrementar contador de pasos
    add w22, w22, 1         // i++ (Siguiente fila objetivo)
    b loop_filas_i          // Repetir para la siguiente fila

sig_pivote_k:
    add w21, w21, 1         // k++ (Siguiente elemento de la diagonal)
    b loop_pivote_k         // Repetir ciclo principal

fin_gauss_total:
    b fin_gauss             // Ir a finalizacion

// --- Funcion para imprimir la matriz de trabajo ---
imprimir_copia:
    stp x29, x30, [sp, -16]! // Preservar registros de enlace

    mov w6, 0               // Contador de filas para impresion

loop_print_f:
    cmp w6, w4              // Comparar con total de filas
    b.ge fin_print_copia    // Si termino filas, salir

    // -- Imprimir apertura de corchete --
    mov x8, 64
    mov x0, 1
    ldr x1, =abre_cor
    mov x2, 2
    svc 0

    mov w7, 0               // Contador de columnas para impresion

loop_print_c:
    cmp w7, w5              // Comparar con total de columnas
    b.ge sig_print_fila     // Si termino columnas, pasar a cerrar corchete

    // -- Cargar valor de la celda --
    mul w13, w6, w5         
    add w13, w13, w7        
    ldr x14, =matriz_copia  
    ldr w15, [x14, w13, uxtw #2] 

    bl itoa_imprimir        // Convertir valor a texto y mostrar

    // -- Imprimir espacio entre numeros --
    mov x8, 64
    mov x0, 1
    ldr x1, =espacio
    mov x2, 2
    svc 0

    add w7, w7, 1           // j++
    b loop_print_c          

sig_print_fila:
    // -- Imprimir cierre de corchete --
    mov x8, 64
    mov x0, 1
    ldr x1, =cierra_cor
    mov x2, 8
    svc 0

    add w6, w6, 1           // i++
    b loop_print_f          

fin_print_copia:
    ldp x29, x30, [sp], 16  // Restaurar registros
    ret                     // Regresar de la funcion

// --- SUBRUTINA ITOA ---
itoa_imprimir:
    stp x29, x30, [sp, -16]!
    
    ldr x9, =itoa_buffer    // Cargar puntero de buffer temporal
    mov w10, 0              // Contador de digitos
    
    // -- Gestion de numeros negativos --
    cmp w15, 0              // Comparar numero con 0
    b.ge itoa_no_neg        // Si es positivo, saltar signo
    
    mov w11, '-'            // Cargar signo menos
    strb w11, [x9]          // Guardar en buffer
    mov x8, 64              // Imprimir signo inmediatamente
    mov x0, 1
    mov x1, x9              
    mov x2, 1
    svc 0
    neg w15, w15            // Volver numero positivo para procesar digitos
    
itoa_no_neg:
    mov w11, 10             // Base decimal
    ldr x9, =itoa_buffer    
itoa_div:
    udiv w12, w15, w11      // w12 = cociente
    msub w13, w12, w11, w15 // w13 = residuo (digito)
    add w13, w13, '0'       // Convertir a ASCII
    strb w13, [x9], 1       // Guardar y avanzar
    add w10, w10, 1         // Incrementar contador
    mov w15, w12            // Continuar con el cociente
    cbnz w15, itoa_div      // Mientras el cociente no sea 0
itoa_print:
    cbz w10, itoa_fin       // Si no quedan digitos, salir
    sub x9, x9, 1           // Retroceder puntero al digito
    mov x8, 64              // Imprimir digito individual
    mov x0, 1
    mov x1, x9              
    mov x2, 1
    svc 0
    sub w10, w10, 1         // Decrementar contador
    b itoa_print
itoa_fin:
    ldp x29, x30, [sp], 16  // Restaurar enlace
    ret

// --- Manejo de errores y salida ---
error_vacia:
    mov x8, 64              // Imprimir mensaje de error si no hay datos
    mov x0, 1
    ldr x1, =msg_err_vacia  
    mov x2, 56              
    svc 0                   
    b salir_rutina          

fin_gauss:
    mov x8, 64              // Imprimir salto de linea final
    mov x0, 1
    ldr x1, =newline        
    mov x2, 1               
    svc 0                   

salir_rutina:
    ldp x29, x30, [sp], 16  // Recuperar registros y restaurar pila
    ret                     // Regresar al menu principal
