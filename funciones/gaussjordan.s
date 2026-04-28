// Mensajes a imprimir
.section .data
    msg_err_vacia:    .asciz "\nError: Primero debe ingresar una matriz en la opcion 1.\n"
    msg_header_id:    .asciz "\nMetodo de Gauss-jordan:\nA = "
    
    abre_cor:         .asciz "[ "
    cierra_cor:       .asciz "]\n      "
    espacio:       .asciz "  "
    newline:          .asciz "\n"

    msg_paso_ini:     .asciz "\n--- Paso "
    msg_paso_fin:     .asciz " ---\n"
    msg_paso_diag:    .asciz "\n--- Paso Final (Diagonal a 1) ---\n"

// --- Espacio de memoria para trabajar sobre una copia de la matriz ---
.section .bss
    matriz_copia: .space 400
    paso_buffer:  .space 4

.section .text
.global matriz_gaussjordan

// --- Inicio proceso ---
matriz_gaussjordan:
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

    // --- Preparar impresion de matriz transpuesta ---
    // -- Imprimir encabezado --
    mov x8, 64              // Syscall 64 -> write
    mov x0, 1               // File descriptor 1 -> stdout
    ldr x1, =msg_header_id  // Carga la dirección del mensaje -> encabezado
    mov x2, 29              // Longitud de la cadena
    svc 0                   // Ejecuta la llamada al sistema

    // --- Valor entero de columnas y filas ---
    sub w4, w4, '0'         // Numero filas en entero 
    sub w5, w5, '0'         // Numero columnas en entero

    // --- Copiar la matriz ---
    mul w18, w4, w5         // Calcular el total de elementos
    mov w19, 0              // Contador para copiar elementos

// --- Funcion para copiar elementos ---
loop_copiar:
    cmp w19, w18            // Verificar si ya se copiaron todos los elementos
    b.ge fin_copiar         // Si contador > elementos dejar de copiar elementos

    ldr x14, =matriz        // Cargar la direccion del inicio de la matriz global
    ldr w20, [x14, w19, uxtw #2] // Acceso al indice de la matriz original

    ldr x15, =matriz_copia  // Cargar la direccion del inicio de la matriz copia
    str w20, [x15, w19, uxtw #2] // Acceso al indice de la matriz copia

    add w19, w19, 1         // Autoincremento para el contador
    b loop_copiar           // Regresar para seguir copiando la matriz

// --- Empezar a aplicar gaussjordan ------------------------
fin_copiar:
    mov w21, 0              // Fila Pivote actual Empieza en 0.

loop_pivote_k:
    // El limite para el pivote 'k' es la penultima fila. 
    // Si k+1 >= total de filas, significa que ya terminamos todo el metodo.
    cmp w21, w4                  // Compara pivote actual (k) con total de filas (w4)
    b.ge fin_gaussjordan_total   // Si k >= filas, terminamos los barridos

    // --- Cargar el PIVOTE PRINCIPAL: A[k][k] ---
    // Indice = (k * columnas) + k
    mul w13, w21, w5        
    add w13, w13, w21       
    ldr x15, =matriz_copia
    ldr w16, [x15, w13, uxtw #2] // w16 = Valor de A[k][k]

    // Si el pivote es 0, idealmente hay que intercambiar filas. 
    // Por ahora, para que el programa no colapse, simplemente saltamos esta iteracion.
    cbz w16, sig_pivote_k   

    mov w22, 0               // Filas a modificar comienza desde 0 para modificar tanto arriba como abajo

loop_filas_i:
    cmp w22, w4             // Comparar i con total de filas
    b.ge sig_pivote_k       // Si ya limpiamos todas las filas debajo del pivote, pasamos al siguiente pivote

    cmp w22, w21            // Compara fila actual con fila pivote
    b.eq sig_fila_i         // Si fila actual = fila pivote saltar

    // --- Cargar el OBJETIVO a eliminar: A[i][k] ---
    // Indice = (i * columnas) + k
    mul w13, w22, w5        
    add w13, w13, w21       
    ldr w17, [x15, w13, uxtw #2] // w17 = Valor de A[i][k]

    mov w23, 0              // w23 = j (Contador de columnas). Empieza en 0.

// --- Ciclo interno para aplicar formula en toda la fila ---
loop_columnas_j:
    cmp w23, w5             // Comparar j con total de columnas
    b.ge sig_fila_i         // Si ya actualizamos toda la fila, pasamos a la siguiente fila objetivo

    // --- Leer A[i][j] (Elemento de la Fila a modificar) ---
    mul w13, w22, w5        // i * columnas
    add w13, w13, w23       // + j
    ldr w24, [x15, w13, uxtw #2]

    // --- Leer A[k][j] (Elemento de la Fila pivote) ---
    mul w14, w21, w5        // k * columnas
    add w14, w14, w23       // + j
    ldr w25, [x15, w14, uxtw #2]

    // --- Aplicacion de la formula cruzada ---
    // Fila_Objetivo = (Pivote * A[i][j]) - (Objetivo * A[k][j])
    mul w26, w16, w24       // w26 = Pivote * A[i][j]
    mul w27, w17, w25       // w27 = Objetivo * A[k][j]
    sub w28, w26, w27       // w28 = Resultado Final

    // --- Guardar el valor nuevo en la copia ---
    str w28, [x15, w13, uxtw #2]

    add w23, w23, 1         // j++
    b loop_columnas_j       // Repetir el proceso para las siguientes columnas

// --- Controles de avance de los ciclos ---
sig_fila_i:
    add w22, w22, 1         // Avanzar a la siguiente fila debajo del pivote
    b loop_filas_i

sig_pivote_k:
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_paso_ini
    mov x2, 10
    svc 0

    add w9, w21, 1

    mov w10, 0              
resta_diez_paso:
    cmp w9, 10
    b.lt fin_resta_paso
    sub w9, w9, 10
    add w10, w10, 1
    b resta_diez_paso

fin_resta_paso:
    ldr x1, =paso_buffer
    mov w11, 0              
    
    cbz w10, paso_unidades  
    add w10, w10, '0'       
    strb w10, [x1, w11, uxtw]
    add w11, w11, 1         
    
paso_unidades:
    add w9, w9, '0'         
    strb w9, [x1, w11, uxtw]
    add w11, w11, 1         
    
    mov x8, 64
    mov x0, 1
    ldr x1, =paso_buffer
    mov x2, x11             
    svc 0

    mov x8, 64
    mov x0, 1
    ldr x1, =msg_paso_fin
    mov x2, 5
    svc 0
    // ---------------------------------------------------------

    // Imprimir el estado de la matriz en este paso
    bl imprimir_copia       
    
    mov x8, 64
    mov x0, 1
    ldr x1, =newline
    mov x2, 1
    svc 0

    add w21, w21, 1         
    b loop_pivote_k

// --- Dividir diagonal dentro de si misma para hacer todos 1's ---
fin_gaussjordan_total:
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_paso_diag
    mov x2, 36
    svc 0
    // ---------------------------------------------------------

    mov w6, 0               // Contador de filas

loop_diag_f:
    cmp w6, w4
    b.ge fin_de_verdad

    // Leer el pivote final de esta fila: A[i][i]
    mul w13, w6, w5
    add w13, w13, w6
    ldr x15, =matriz_copia
    ldr w16, [x15, w13, uxtw #2] 

    cbz w16, sig_diag       

    mov w7, 0               

loop_diag_c:
    cmp w7, w5
    b.ge sig_diag

    // Leer el elemento actual: A[i][j]
    mul w13, w6, w5
    add w13, w13, w7
    ldr w17, [x15, w13, uxtw #2]

    // Dividir A[i][j] entre el Pivote A[i][i]
    sdiv w18, w17, w16      

    // Guardar el resultado simplificado
    str w18, [x15, w13, uxtw #2]

    add w7, w7, 1
    b loop_diag_c

sig_diag:
    add w6, w6, 1
    b loop_diag_f

fin_de_verdad:
    // Imprimir la matriz final perfecta
    bl imprimir_copia       
    b fin_gaussjordan       

// --- Funcion para imprimir el paso a paso ---
imprimir_copia:
    stp x29, x30, [sp, -16]!        

    mov w6, 0                       

loop_print_f:
    cmp w6, w4                      
    b.ge fin_print_copia            

    mov x8, 64                      
    mov x0, 1                       
    ldr x1, =abre_cor               
    mov x2, 2                       
    svc 0                           

    mov w7, 0                       

loop_print_c:
    cmp w7, w5                      
    b.ge sig_print_fila             

    mul w13, w6, w5                 
    add w13, w13, w7                
    ldr x14, =matriz_copia          
    ldr w15, [x14, w13, uxtw #2]    

    sub sp, sp, 16
    mov x9, sp                      
    mov w10, 0                      

    cmp w15, 0                      
    b.ge no_negativo                

    mov w11, '-'                    
    strb w11, [sp, 15]              

    mov x8, 64
    mov x0, 1
    add x1, sp, 15          
    mov x2, 1
    svc 0

    neg w15, w15                     
    
no_negativo:
    mov w11, 10                      

loop_dividir:
    udiv w12, w15, w11               
    msub w13, w12, w11, w15          

    add w13, w13, '0'                
    strb w13, [x9], 1                
    add w10, w10, 1                  

    mov w15, w12                     
    cbnz w15, loop_dividir           

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
    add sp, sp, 16          

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

fin_print_copia:
    ldp x29, x30, [sp], 16  
    ret                      

// --- Manejo de errores y salida ---
error_vacia:
    mov x8, 64              
    mov x0, 1               
    ldr x1, =msg_err_vacia  
    mov x2, 56              
    svc 0                   
    b salir_rutina          

// --- Fin de la impresion del proceso ---
fin_gaussjordan:            
    mov x8, 64              
    mov x0, 1               
    ldr x1, =newline        
    mov x2, 1               
    svc 0                   

salir_rutina:
    ldp x29, x30, [sp], 16  
    ret
