// --- Mensajes a imprimir ---
.section .data
    msg_err_vacia:    .asciz "\nError: Primero debe ingresar una matriz en la opcion 1.\n"
    msg_err_cua:      .asciz "\nError: La matriz debe ser CUADRADA para calcular su determinante.\n"
    
    msg_resultado:    .asciz "\nEl determinante de la matriz es: "
    
    espacio:          .asciz " "
    newline:          .asciz "\n"

// --- Espacio de memoria ---
.section .bss
.align 3                        // Alineacion de seguridad ARM64 (8 bytes)
    matriz_copia_det: .space 400// Espacio para copia de matriz 10x10
    itoa_buffer_det:  .space 16 // Buffer estatico para conversion de texto

.section .text
.global matriz_determinante

// --- Inicio proceso ---
matriz_determinante:
    stp x29, x30, [sp, -16]!    // Guardar marco y registro de retorno

    // --- VALIDAR EXISTENCIA DE LA MATRIZ ---
    ldr x1, =filas              // Direccion de filas guardadas
    ldrb w4, [x1]               // Cargar caracter de filas
    cbz w4, error_vacia_det     // Validar si es nulo (sin matriz)
    cmp w4, '0'                 // Comparar con caracter '0'
    b.eq error_vacia_det        // Salto si no hay dimensiones validas

    ldr x1, =columnas           // Direccion de columnas guardadas
    ldrb w5, [x1]               // Cargar caracter de columnas

    // --- VALIDAR SI ES MATRIZ CUADRADA ---
    cmp w4, w5                  // Comparar filas vs columnas
    b.ne error_cuadrada_det     // Salto si no son iguales

    // Convertir dimensiones de ASCII a entero
    sub w4, w4, '0'             // w4 = n (dimension filas)
    sub w5, w5, '0'             // w5 = n (dimension columnas)

    // --- COPIAR MATRIZ A MEMORIA TEMPORAL ---
    mul w18, w4, w5             // w18 = total de elementos (n * n)
    mov w19, 0                  // w19 = contador de elementos copiados

loop_copiar_det:
    cmp w19, w18                // ¿Ya se copio toda la matriz?
    b.ge fin_copiar_det         

    ldr x14, =matriz            // Base de la matriz original
    ldr w20, [x14, w19, uxtw #2]// Cargar elemento (desplazamiento * 4)

    ldr x15, =matriz_copia_det  // Base de la matriz de trabajo
    str w20, [x15, w19, uxtw #2]// Almacenar en la copia temporal

    add w19, w19, 1             // Incrementar contador de copia
    b loop_copiar_det           

// --- ALGORITMO DE BAREISS ---
fin_copiar_det:
    mov w21, 0                  // w21 = k (Indice de Fila Pivote actual)
    mov w29, 1                  // w29 = Pivote Anterior (Inicializado en 1)

loop_pivote_k_det:
    add w8, w21, 1              // w8 = k + 1 (Siguiente fila)
    cmp w8, w4                  // Procesamos todos los pivotes necesarios
    b.ge imprimir_determinante  // Fin de eliminacion, imprimir resultado final

    // -- Cargar PIVOTE ACTUAL: A[k][k] --
    mul w13, w21, w5            // Indice fila pivote: k * n
    add w13, w13, w21           // + k (diagonal)
    ldr x15, =matriz_copia_det  // Base matriz trabajo
    ldr w16, [x15, w13, uxtw #2]// w16 = Valor de A[k][k]

    // Si pivote es 0, Bareiss falla sin intercambios. Resultado: 0
    cbz w16, det_es_cero   

    mov w22, w8                 // w22 = i (Iterador de Fila Objetivo)

loop_filas_i_det:
    cmp w22, w4                 // Terminamos con todas las filas i
    b.ge sig_pivote_k_det       

    ldr x15, =matriz_copia_det  // Recargar base por seguridad

    // -- Cargar OBJETIVO: A[i][k] (Elemento a hacer 0) --
    mul w13, w22, w5            // i * n
    add w13, w13, w21           // + k
    ldr w17, [x15, w13, uxtw #2]// w17 = Valor objetivo bajo el pivote

    mov w23, 0                  // w23 = j (Iterador de columnas)

loop_columnas_j_det:
    cmp w23, w5                 // Procesamos todas las columnas j
    b.ge sig_fila_i_det         

    ldr x15, =matriz_copia_det

    // Leer A[i][j] (Elemento a actualizar)
    mul w13, w22, w5            
    add w13, w13, w23           
    ldr w24, [x15, w13, uxtw #2]// w24 = valor actual A[i][j]

    // Leer A[k][j] (Elemento de la fila pivote)
    mul w14, w21, w5            
    add w14, w14, w23           
    ldr w25, [x15, w14, uxtw #2]// w25 = valor actual A[k][j]

    // --- A[i,j] = (A[k,k]*A[i,j] - A[i,k]*A[k,j]) / A[k-1,k-1] ---
    mul w26, w16, w24           // Producto 1: Pivote Actual * A[i][j]
    mul w27, w17, w25           // Producto 2: Objetivo * Fila Pivote
    sub w28, w26, w27           // Resta de productos para eliminacion
    
    // Division exacta por el pivote anterior (Garantizado por Bareiss)
    sdiv w28, w28, w29          // w28 = Nuevo valor de la celda

    str w28, [x15, w13, uxtw #2]// Actualizar memoria con nuevo valor

    add w23, w23, 1             // j++
    b loop_columnas_j_det       

sig_fila_i_det:
    add w22, w22, 1             // i++ (Siguiente fila objetivo)
    b loop_filas_i_det

sig_pivote_k_det:
    // El pivote usado ahora pasa a ser el Pivote Anterior (w29)
    mov w29, w16                // Actualizar Pivote Anterior para formula
    add w21, w21, 1             // k++ (Siguiente elemento diagonal)
    b loop_pivote_k_det


// --- IMPRESION DEL RESULTADO ---
det_es_cero:
    mov w15, 0                  // Cargar 0 directamente como resultado
    b print_final

imprimir_determinante:
    // el determinante final queda en la posicion A[n-1][n-1]
    sub w6, w4, 1               // w6 = n - 1 (Indice final)
    
    mul w13, w6, w5             // (n-1) * n
    add w13, w13, w6            // + (n-1)
    
    ldr x15, =matriz_copia_det
    ldr w15, [x15, w13, uxtw #2]// Cargar Determinante Final en w15

print_final:
    // Imprimir etiqueta "El determinante es: "
    mov x8, 64                  // Syscall write
    mov x0, 1                   // stdout
    ldr x1, =msg_resultado      // Puntero al mensaje
    mov x2, 35                  // Longitud del mensaje
    svc 0                       

    // Llamar a ITOA para convertir numero en w15 a texto
    bl itoa_imprimir_det        
    
    mov x8, 64                  // Salto de linea
    mov x0, 1
    ldr x1, =newline
    mov x2, 1
    svc 0
    
    b salir_rutina_det


// --- SUBRUTINA ITOA ---
itoa_imprimir_det:
    stp x29, x30, [sp, -16]!    // Guardar entorno de subrutina
    
    ldr x9, =itoa_buffer_det    // Puntero al buffer de conversion
    mov w10, 0                  // Contador de digitos extraidos
    
    cmp w15, 0                  // Es un determinante negativo
    b.ge itoa_no_neg_det
    
    // Imprimir signo menos de forma manual
    mov w11, '-'
    strb w11, [x9]              // Guardar signo en buffer
    mov x8, 64                  
    mov x0, 1
    mov x1, x9                  // Direccion del '-'
    mov x2, 1                   // Imprimir 1 byte
    svc 0
    neg w15, w15                // Valor absoluto para procesar digitos
    
itoa_no_neg_det:
    mov w11, 10                 // Base decimal
    ldr x9, =itoa_buffer_det    
itoa_div_det:
    udiv w12, w15, w11          // Obtener cociente
    msub w13, w12, w11, w15     // Obtener residuo (digito)
    add w13, w13, '0'           // Convertir a ASCII
    strb w13, [x9], 1           // Almacenar digito y avanzar puntero
    add w10, w10, 1             // Incrementar contador
    mov w15, w12                // Continuar con el cociente
    cbnz w15, itoa_div_det      // Repetir hasta vaciar el numero

itoa_print_det:
    cbz w10, itoa_fin_det       // Se imprimieron todos los digitos
    sub x9, x9, 1               // Retroceder puntero al digito anterior
    mov x8, 64                  // Escribir digito individual
    mov x0, 1
    mov x1, x9                  
    mov x2, 1                   
    svc 0
    sub w10, w10, 1             // Decrementar cuenta
    b itoa_print_det

itoa_fin_det:
    ldp x29, x30, [sp], 16      // Restaurar entorno
    ret

// --- MANEJO DE ERRORES ---
error_vacia_det:
    mov x8, 64                  // matriz no definida
    mov x0, 1
    ldr x1, =msg_err_vacia      
    mov x2, 56                  
    svc 0                       
    b salir_rutina_det          

error_cuadrada_det:
    mov x8, 64                  // no es cuadrada
    mov x0, 1
    ldr x1, =msg_err_cua
    mov x2, 73                  
    svc 0
    b salir_rutina_det

salir_rutina_det:
    ldp x29, x30, [sp], 16      // restaurar registros y salir
    ret
