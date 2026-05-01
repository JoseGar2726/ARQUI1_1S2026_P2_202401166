// Mensajes a imprimir
.section .data
    msg_err_vacia:    .asciz "\nError: Primero debe ingresar una matriz en la opcion 1.\n"
    msg_header_id:    .asciz "\nMatriz Transpuesta:\nA^t = "
    
    abre_cor:         .asciz "[ "
    cierra_cor:       .asciz "]\n      "
    espacio:          .asciz " "
    newline:          .asciz "\n"

.section .text
.global matriz_transpuesta

// --- Inicio proceso ---
matriz_transpuesta:
    // --- Manejo de link register y stack pointer ---
    stp x29, x30, [sp, -16]! // Guarda x29 y x30 restando 16 bytes al stack pointer

    // --- Validar si ya se ingreso una matriz ---
    // -- Lectura del valor de filas --
    ldr x1, =filas          // Carga el valor de las filas guardado en la memoria global
    ldrb w4, [x1]           // Lee el valor de las filas y lo guarda en w4
    cbz w4, error_vacia     // Si el valor es nulo no hay matriz
    cmp w4, '0'             // Compara el valor con el caracter '0'
    b.eq error_vacia        // Si el valor es '0' tampoco hay matriz válida

    // --- Lectura del valor de columnas ---
    ldr x1, =columnas       // Carga el valor de las columnas guardado en la memoria global
    ldrb w5, [x1]           // Lee el valor de las columnas y lo guarda en w5

    // --- Preparar impresion de matriz transpuesta ---
    // -- Imprimir encabezado --
    mov x8, 64              // Syscall 64 -> write
    mov x0, 1               // File descriptor 1 -> stdout
    ldr x1, =msg_header_id  // Carga la dirección del mensaje -> encabezado
    mov x2, 27              // Longitud de la cadena
    svc 0                   // Ejecuta la llamada al sistema

    // --- Valor entero de columnas y filas ---
    sub w4, w4, '0'         // Numero filas en entero 
    sub w5, w5, '0'         // Numero columnas en entero

    mov w6, 0               // Contador para ciclo de columnas

// --- Ciclo externo recorrer columnas(Ahora las filas son columnas) ---
loop_columnas:
    cmp w6, w5              // Comparar contador columnas con numero de columas
    b.ge fin_transpuesta    // Si contador > colummas -> terminar de imprimir

    // --- Inicio de impresion de filas
    mov x8, 64              // Syscall 64 -> write
    mov x0, 1               // File descriptor 1 -> stdout
    ldr x1, =abre_cor       // Carga la dirección del mensaje -> [
    mov x2, 2               // Longitud de la cadena
    svc 0                   // Ejecuta la llamada al sistema

    mov w7, 0               // Contador para ciclo de filas

// --- Ciclo interno recorrer filas ---
loop_filas:
    cmp w7, w4             // Comparar contador filas con numero de de dilas
    b.ge sig_fila          // Si contador > filas -> pasar a imprimir la siguiente fila

    // --- Calcular Indice Row-Major: (fila_original * columnas_totales) + columna_original ---
    mul w13, w7, w5        // Multiplica la fila actual por el total de columnas originales
    add w13, w13, w6       // Le suma la columna actual para obtener la posición exacta

    ldr x14, =matriz       // Cargar la direccion del inicio de la matriz global
    ldr w15, [x14, w13, uxtw #2]     // Cargar el valor del inidice calculado

    sub sp, sp, 16          // Reservar 16 bytes en la pila
    mov x9, sp              // Puntero para escribir digitos
    mov w10, 0              // Contador de digitos

    cmp w15, 0              // Verificar si el numero a escribir es negativo
    b.ge no_neg_t           // Si el numero es >= 0 ir a no_neg_t

    mov w11, '-'            // Guardar el signo '-'
    strb w11, [sp, 15]      // Uso del byte 15 del buffer para imprimir

    // -- Imprime el signo '-' --
    mov x8, 64              // Syscall 64 -> write
    mov x0, 1               // File descriptor 1 -> stdout
    add x1, sp, 15          // Direccion del signo '-'
    mov x2, 1               // Imprimir 1 byte
    svc 0                   // Ejecuta llamada al sistema

    neg w15, w15            // Vuelve el numero positivo para dividirlo

no_neg_t:
    mov w11, 10             // Divisor base 10

loop_dividir_t:
    udiv w12, w15, w11      // Calculo del cociente
    msub w13, w12, w11, w15 // Calculo del residuo

    add w13, w13, '0'       // Convertir entero a ASCII
    strb w13, [x9], 1       // Guardar en el buffer y avanzar puntero
    add w10, w10, 1         // Incrementar contador de digitos

    mov w15, w12            // Actualizar el numero con el cociente
    cbnz w15, loop_dividir_t// Si no es 0 seguir dividiendo

loop_imprimir_digitos_t:
    cbz w10, fin_itoa_t     // Si contador es 0, terminamos

    sub x9, x9, 1           // Retroceder puntero al ultimo digito guardado
    mov x8, 64              // Syscall 64 -> write
    mov x0, 1               // File descriptor 1 -> stdout
    mov x1, x9              // Dirección del dígito
    mov x2, 1               // Imprimir 1 byte
    svc 0                   // Ejecuta llamada al sistema

    sub w10, w10, 1         // Decremento contador
    b loop_imprimir_digitos_t // Regresar a la impresion

fin_itoa_t:
    add sp, sp, 16          // Restaurar el stack

    // -- Imprimir un espacio separador --
    mov x8, 64              // Syscall 64 -> write
    mov x0, 1               // File descriptor 1 -> stdout
    ldr x1, =espacio        // Cargar el string espacio
    mov x2, 1               // Imprimir 1 byte
    svc 0                   // Ejecuta llamada al sistema

    add w7, w7, 1          // Incremento del contador de filas
    b loop_filas           // Regresar a la impresion de filas

// --- Imprimir la siguiente fila ---
sig_fila:
    // --- Fin de la fila ---
    mov x8, 64             // Syscall 64 -> write
    mov x0, 1              // File descriptor 1 -> stdout
    ldr x1, =cierra_cor    // Carga la dirección del mensaje -> ]
    mov x2, 8              // Longitud de la cadena
    svc 0                  // Ejecuta la llamada al sistema

    add w6, w6, 1          // Incremento del contador de columnas
    b loop_columnas        // Regresar para imprimir la siguiente columna

// --- Manejo de errores y salida ---
// -- No se ha ingresado matriz --
error_vacia:
    mov x8, 64              // Syscall 64 -> write
    mov x0, 1               // File descriptor 1 -> stdout
    ldr x1, =msg_err_vacia  // Carga la dirección del mensaje -> Mensaje de que esta vacia
    mov x2, 56              // Longitud de la cadena
    svc 0                   // Ejecuta la llamada al sistema
    b salir_rutina          // Ir a la salida

// --- Fin de la impresion de la matriz transpuesta ---
fin_transpuesta:
    mov x8, 64              // Syscall 64 -> write
    mov x0, 1               // File descriptor 1 -> stdout
    ldr x1, =newline        // Carga la dirección del mensaje -> Salto de linea
    mov x2, 1               // Longitud de la cadena
    svc 0                   // Ejecuta la llamada al sistema

// --- Fin de ejecucion ---
salir_rutina:
    // -- Recuperamos los registros de la pila y restauramos el Stack Pointer --
    ldp x29, x30, [sp], 16  // Carga x29 y x30 sumando 16 bytes al sp
    ret                     // Regresa a inicio.s
    