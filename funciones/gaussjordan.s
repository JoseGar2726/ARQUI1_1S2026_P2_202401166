// Mensajes a imprimir
.section .data
    msg_err_vacia:    .asciz "\nError: Primero debe ingresar una matriz en la opcion 1.\n"
    msg_header_id:    .asciz "\nMetodo de Gauss-jordan:\nA = "
    
    abre_cor:         .asciz "[ "
    cierra_cor:       .asciz "]\n      "
    espacio:          .asciz "  "
    newline:          .asciz "\n"

    msg_paso_ini:     .asciz "\n--- Paso "
    msg_paso_fin:     .asciz " ---\n"
    msg_paso_diag:    .asciz "\n--- Paso Final (Diagonal a 1) ---\n"

    msg_pivote:       .asciz "Pivote: "
    msg_fila:         .asciz "\nHaciendo 0 la fila: "

// --- Espacio de memoria ---
.section .bss
.align 3                        
    matriz_copia: .space 400
    itoa_buffer:  .space 16     

.section .text
.global matriz_gaussjordan

// --- Inicio proceso ---
matriz_gaussjordan:
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
    mov x2, 29              // Longitud de la cadena
    svc 0                   // Ejecuta la llamada al sistema

    // --- Valor entero de columnas y filas ---
    sub w4, w4, '0'         // Numero filas en entero 
    sub w5, w5, '0'         // Numero columnas en entero 

    // --- Realizar copia de seguridad de la matriz original ---
    mul w18, w4, w5         // Calcular total de elementos
    mov w19, 0              // Contador para el ciclo de copia

loop_copiar:
    cmp w19, w18            // Comparar contador con total de elementos
    b.ge fin_copiar         // Si se copiaron todos, pasar a la siguiente fase

    ldr x14, =matriz        // Cargar direccion de la matriz original
    ldr w20, [x14, w19, uxtw #2] // Leer valor actual

    ldr x15, =matriz_copia  // Cargar direccion de la matriz de trabajo
    str w20, [x15, w19, uxtw #2] // Guardar valor en la copia

    add w19, w19, 1         // Incrementar contador
    b loop_copiar           // Repetir ciclo de copia

// --- Algoritmo de Gauss-Jordan ----------------------
fin_copiar:
    mov w21, 0              // w21 = k (Indice de fila pivote actual)
    mov w20, 1              // w20 = Contador global de pasos narrativos

loop_pivote_k:
    cmp w21, w4             // ¿Hemos recorrido todas las filas como pivotes?
    b.ge fin_gaussjordan_total // Si k >= filas, el proceso de eliminacion termina

    // -- Cargar Pivote A[k][k] --
    mul w13, w21, w5        
    add w13, w13, w21       
    ldr x15, =matriz_copia
    ldr w16, [x15, w13, uxtw #2] // w16 = Valor del Pivote actual

    cbz w16, sig_pivote_k   // Si el pivote es 0, saltar para evitar division por cero

    mov w22, 0              // w22 = i (Fila a modificar, siempre empieza desde 0)

loop_filas_i:
    cmp w22, w4             // ¿Se han procesado todas las filas i para este pivote?
    b.ge sig_pivote_k       // Si i >= filas, pasar al siguiente pivote k

    cmp w22, w21            // ¿La fila actual es la misma que la del pivote?
    b.eq sig_fila_salto     // Si i == k, saltar la operacion (no se elimina a si misma)

    ldr x15, =matriz_copia  // Recargar base de la matriz de trabajo

    // -- Cargar Valor Objetivo A[i][k] --
    mul w13, w22, w5        
    add w13, w13, w21       
    ldr w17, [x15, w13, uxtw #2] // w17 = Valor a convertir en 0

    mov w23, 0              // w23 = j (Contador de columnas para operacion de fila)

loop_columnas_j:
    cmp w23, w5             // ¿Se han procesado todas las columnas de la fila?
    b.ge sig_fila_i         // Si j >= columnas, pasar a imprimir el paso realizado

    ldr x15, =matriz_copia  // Recargar base de la matriz de trabajo

    // -- Obtener A[i][j] --
    mul w13, w22, w5        
    add w13, w13, w23       
    ldr w24, [x15, w13, uxtw #2] // Elemento de la fila que estamos modificando

    // -- Obtener A[k][j] --
    mul w14, w21, w5        
    add w14, w14, w23       
    ldr w25, [x15, w14, uxtw #2] // Elemento de la fila pivote actual

    // -- Operacion Gauss-Jordan: A[i][j] = (Pivote * A[i][j]) - (Objetivo * A[k][j]) --
    mul w26, w16, w24       
    mul w27, w17, w25       
    sub w28, w26, w27       

    str w28, [x15, w13, uxtw #2] // Guardar resultado en la matriz de trabajo

    add w23, w23, 1         // j++
    b loop_columnas_j       

// --- Impresión Narrativa del Paso ---
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
    mov w15, w16            // Pasar pivote a ITOA
    bl itoa_imprimir

    // -- Imprimir fila modificada --
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_fila
    mov x2, 20
    svc 0
    mov w15, w22            // Pasar indice de fila a ITOA
    bl itoa_imprimir
    
    mov x8, 64
    mov x0, 1
    ldr x1, =newline
    mov x2, 1
    svc 0

    bl imprimir_copia       // Mostrar estado actual de la matriz de trabajo
    
    mov x8, 64
    mov x0, 1
    ldr x1, =newline
    mov x2, 1
    svc 0

    add w20, w20, 1         // Incrementar contador de pasos globales

sig_fila_salto:
    add w22, w22, 1         // i++ (Siguiente fila)
    b loop_filas_i

sig_pivote_k:
    add w21, w21, 1         // k++ (Siguiente pivote en la diagonal)
    b loop_pivote_k

// --- Normalización: Convertir la diagonal a 1 ---
fin_gaussjordan_total:
    // -- Mensaje de inicio de normalizacion --
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_paso_diag
    mov x2, 36
    svc 0

    mov w6, 0               // w6 = i (Fila para normalizar)

loop_diag_f:
    cmp w6, w4              // ¿Terminamos con todas las filas?
    b.ge fin_de_verdad      // Si i >= filas, terminar proceso total

    // -- Localizar Pivote final A[i][i] --
    mul w13, w6, w5
    add w13, w13, w6
    ldr x15, =matriz_copia
    ldr w16, [x15, w13, uxtw #2] // Cargar valor final del pivote

    cbz w16, sig_diag       // Si es 0 no se puede dividir (evitar crash)

    mov w7, 0               // w7 = j (Recorrer columnas para dividir)

loop_diag_c:
    cmp w7, w5              // ¿Terminamos columnas de la fila?
    b.ge sig_diag

    mul w13, w6, w5
    add w13, w13, w7
    ldr w17, [x15, w13, uxtw #2] // Cargar valor actual

    sdiv w18, w17, w16      // Fila_i = Fila_i / Pivote_i
    str w18, [x15, w13, uxtw #2] // Guardar valor normalizado

    add w7, w7, 1           // j++
    b loop_diag_c

sig_diag:
    add w6, w6, 1           // i++
    b loop_diag_f

fin_de_verdad:
    bl imprimir_copia       // Imprimir resultado final (Matriz escalonada reducida)
    b fin_gaussjordan       

// --- Funcion para imprimir la matriz ---
imprimir_copia:
    stp x29, x30, [sp, -16]! 

    mov w6, 0               // i = 0

loop_print_f:
    cmp w6, w4              
    b.ge fin_print_copia    

    mov x8, 64              
    mov x0, 1               
    ldr x1, =abre_cor       
    mov x2, 2               
    svc 0                   

    mov w7, 0               // j = 0

loop_print_c:
    cmp w7, w5              
    b.ge sig_print_fila     

    mul w13, w6, w5         
    add w13, w13, w7        
    ldr x14, =matriz_copia  
    ldr w15, [x14, w13, uxtw #2] 

    bl itoa_imprimir        // Convertir valor a texto y mostrar

    mov x8, 64
    mov x0, 1
    ldr x1, =espacio
    mov x2, 2
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

fin_print_copia:
    ldp x29, x30, [sp], 16  
    ret                     

// --- SUBRUTINA ITOA ---
itoa_imprimir:
    // -- Preservar registros de enlace y marco --
    stp x29, x30, [sp, -16]! // Guarda x29 y x30 en la pila y reserva espacio

    // -- Preparar el buffer y contadores --
    ldr x9, =itoa_buffer    // Carga la direccion del buffer donde se guardaran los digitos
    mov w10, 0              // Inicializa el contador de digitos en 0

    // -- Gestion de números negativos --
    cmp w15, 0              // Compara el numero a imprimir (w15) con 0
    b.ge itoa_no_neg        // Si el numero es positivo (>= 0), salta al proceso normal

    // - Imprimir signo negativo -
    mov w11, '-'            // Carga el carácter '-' en w11
    strb w11, [x9]          // Guarda temporalmente el signo en el buffer
    mov x8, 64              // Syscall 64 -> write
    mov x0, 1               // File descriptor 1 -> stdout
    mov x1, x9              // Direccion del buffer (donde está el '-')
    mov x2, 1               // Imprimir solo 1 byte
    svc 0                   // Ejecuta la llamada al sistema para mostrar el '-'
    neg w15, w15            // Convierte el numero negativo en positivo para procesar sus digitos

itoa_no_neg:
    // -- Proceso de extraccion de digitos --
    mov w11, 10             // Establece el divisor base 10
    ldr x9, =itoa_buffer    // Reinicia el puntero del buffer para los digitos numericos

itoa_div:
    // - Descomponer el numero -
    udiv w12, w15, w11      // w12 = cociente
    msub w13, w12, w11, w15 // w13 = residuo -> Este es el digito actual
    
    // - Guardar digito convertido -
    add w13, w13, '0'       // Convierte el valor numerico a su codigo ASCII
    strb w13, [x9], 1       // Guarda el caracter en el buffer y avanza el puntero 1 byte
    add w10, w10, 1         // Incrementa el contador de digitos encontrados
    
    mov w15, w12            // Actualiza el numero con el cociente para la siguiente vuelta
    cbnz w15, itoa_div      // Si el numero restante no es cero, sigue extrayendo digitos

itoa_print:
    // -- Impresion de los digitos en orden correcto --
    // Se imprimen de atras hacia adelante porque se extrajeron al reves
    cbz w10, itoa_fin       // Si el contador de digitos llega a 0, termina la rutina

    sub x9, x9, 1           // Retrocede el puntero para apuntar al ultimo digito guardado
    mov x8, 64              // Syscall 64 -> write
    mov x0, 1               // File descriptor 1 -> stdout
    mov x1, x9              // Direccion del digito actual en el buffer
    mov x2, 1               // Imprimir 1 byte
    svc 0                   // Ejecuta la llamada al sistema para mostrar el caracter
    
    sub w10, w10, 1         // Decrementa el contador de digitos pendientes
    b itoa_print            // Repite hasta que se impriman todos los digitos

itoa_fin:
    // -- Restaurar registros y retornar --
    ldp x29, x30, [sp], 16  // Recupera x29 y x30 de la pila y limpia el espacio
    ret                     // Regresa a la función que llamó a la subrutina

// --- Manejo de errores y salida ---
error_vacia:
    mov x8, 64              
    mov x0, 1               
    ldr x1, =msg_err_vacia  
    mov x2, 56              
    svc 0                   
    b salir_rutina          

fin_gaussjordan:            
    mov x8, 64              
    mov x0, 1               
    ldr x1, =newline        
    mov x2, 1               
    svc 0                   

salir_rutina:
    ldp x29, x30, [sp], 16  
    ret
