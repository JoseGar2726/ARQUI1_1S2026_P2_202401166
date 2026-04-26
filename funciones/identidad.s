// Mensajes a imprimir
.section .data
    msg_err_vacia:    .asciz "\nError: Primero debe ingresar una matriz en la opcion 1.\n"
    msg_err_cuadrada: .asciz "\nError: La matriz ingresada NO es cuadrada.\n"
    msg_header_id:    .asciz "\nMatriz Identidad:\nI = "
    
    abre_cor:         .asciz "[ "
    cierra_cor:       .asciz "]\n    "
    str_uno:          .asciz "1 "
    str_cero:         .asciz "0 "
    newline:          .asciz "\n"

.section .text
.global matriz_identidad

// --- Inicio proceso ---
matriz_identidad:
    // --- Manejo de link register y stack pointer ---
    stp x29, x30, [sp, -16]! // Guarda x29 y x30 restando 16 bytes al stack pointer

    // --- Validar si ya se ingresó una matriz ---
    // -- Lectura del valor de filas --
    ldr x1, =filas          // Carga el valor de las filas guardado en la memoria global
    ldrb w4, [x1]           // Lee el valor de las filas y lo guarda en w4
    cbz w4, error_vacia     // Si el valor es nulo no hay matriz
    cmp w4, '0'             // Compara el valor con el caracter '0'
    b.eq error_vacia        // Si el valor es '0' tampoco hay matriz válida

    // --- Lectura del valor de columnas ---
    ldr x1, =columnas       // Carga el valor de las columnas guardado en la memoria global
    ldrb w5, [x1]           // Lee el valor de las columnas y lo guarda en w5

    // --- Validar si es Cuadrada ---
    cmp w4, w5              // Comparar si filas = columnas
    b.ne error_cuadrada     // Si filas != columnas, mostrar error

    // --- Preparar impresion de matriz ddentidad ---
    // -- Convertir a numero columnas y filas --
    sub w4, w4, '0'         // Restar el valor '0' para obtener el entero

    // Imprimir encabezado
    mov x8, 64              // Syscall 64 -> write
    mov x0, 1               // File descriptor 1 -> stdout
    ldr x1, =msg_header_id  // Carga la dirección del mensaje -> encabezado
    mov x2, 23              // Longitud de la cadena
    svc 0                   // Ejecuta la llamada al sistema

    // --- Inicializar contador para numero de filas ---
    mov w6, 0               // w6 = 0

// --- Ciclo externo para recorrer filas ---
loop_filas_id:
    cmp w6, w4              // Compara contador con limite de filas
    b.ge fin_identidad      // Si el contador > limite termino de imprimir filas -> final ejecucion

    // --- Inicio de fila ---
    mov x8, 64              // Syscall 64 -> write
    mov x0, 1               // File descriptor 1 -> stdout
    ldr x1, =abre_cor       // Carga la dirección del mensaje -> '['
    mov x2, 2               // Longitud de la cadena
    svc 0                   // Ejecuta la llamada al sistema
    
    // --- Inicializar contador para numero de columnas ---
    mov w7, 0              // w7 = 0

// --- Ciclo interno para recorrer columnas ---
loop_columnas_id:
    cmp w7, w4              // Compara contador con limite de columnas
    b.ge sig_fila_id        // Si el contador > limite termino de imprimir columnas -> siguiente fila

    cmp w6, w7              // Compara contador de fila con contador de columna
    b.eq imprimir_uno       // si contador de fila = contador de columna -> imprimir '1'

// --- Funcion para imprimir '0' ---
imprimir_cero:
    ldr x1, =str_cero       // Carga la dirección del mensaje -> '0'
    b ejecutar_print        // Ir a la funcion que imprime mensaje

// --- Funcion para imprimir '1' ---
imprimir_uno:
    ldr x1, =str_uno        // Carga la dirección del mensaje -> '1'

// --- Funcion para imprimir '1' o '0' ---
ejecutar_print:
    mov x8, 64              // Syscall 64 -> write
    mov x0, 1               // File descriptor 1 -> stdout
    mov x2, 2               // Longitud de la cadena
    svc 0                   // Ejecuta la llamada al sistema

    add w7, w7, 1           // Suma 1 al contador de columnas
    b loop_columnas_id      // Regresa al loop de las columnas

// --- Funcion para imprimir la siguiente fila ---
sig_fila_id:
    // --- Fin de fila ---
    mov x8, 64              // Syscall 64 -> write
    mov x0, 1               // File descriptor 1 -> stdout
    ldr x1, =cierra_cor     // Carga la dirección del mensaje -> ']'
    mov x2, 6               // Longitud de la cadena
    svc 0                   // Ejecuta la llamada al sistema

    add w6, w6, 1           // Suma 1 al contador de columnas
    b loop_filas_id         // Regresa al loop de las filas

// --- Manejo de errores y salida ---
// -- No se ha ingresado matriz --
error_vacia:
    mov x8, 64              // Syscall 64 -> write
    mov x0, 1               // File descriptor 1 -> stdout
    ldr x1, =msg_err_vacia  // Carga la dirección del mensaje -> Mensajde de que esta vacia
    mov x2, 56              // Longitud de la cadena
    svc 0                   // Ejecuta la llamada al sistema
    b salir_rutina          // Ir a la salida

// -- La matriz no es cuadrada --
error_cuadrada:
    mov x8, 64              // Syscall 64 -> write
    mov x0, 1               // File descriptor 1 -> stdout
    ldr x1, =msg_err_cuadrada  // Carga la dirección del mensaje -> Mensajde de que no es matriz cuadrada
    mov x2, 44              // Longitud de la cadena
    svc 0                   // Ejecuta la llamada al sistema
    b salir_rutina          // Ir a la salida

// -- Fin de ejecucion --
fin_identidad:
    mov x8, 64              // Syscall 64 (write)
    mov x0, 1               // File descriptor 1 -> stdout
    ldr x1, =newline        // Carga la dirección del mensaje -> Salto de linea
    mov x2, 1               // Longitud de la cadena
    svc 0                   // Ir a la salida

// -- Fin de ejecucion --
salir_rutina:
    // -- Recuperamos los registros de la pila y restauramos el Stack Pointer --
    ldp x29, x30, [sp], 16  // Carga x29 y x30 sumando 16 bytes al sp
    ret                     // Regresa a inicio.s
