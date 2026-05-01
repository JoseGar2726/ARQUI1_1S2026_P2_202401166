// --- Mensajes a imprimir ---
.section .data
    msg_err_vacia:    .asciz "\nError: Primero debe ingresar la Matriz A en la opcion 1.\n"
    msg_ingreso_b:    .asciz "\nIngrese los valores para la Matriz B a restar:\n"
    
    // Plantilla para pedir celda
    msg_celda_b:      .ascii "b[0][0] = "
    len_celda_b = . - msg_celda_b

    msg_header_r:     .asciz "\nMatriz Resultante (A - B):\nR = "
    
    abre_cor:         .asciz "[ "
    cierra_cor:       .asciz "]\n    "
    espacio:          .asciz " "
    newline:          .asciz "\n"

// --- Espacio de memoria ---
.section .bss
    matriz_r_resta:  .space 400    // Espacio para 100 enteros (10x10) de 4 bytes
    valor_b_resta:   .space 8      // Buffer para lectura de teclado

.section .text
.global matriz_resta

// --- Inicio del proceso de resta ---
matriz_resta:
    stp x29, x30, [sp, -16]!      // Guardar registros de enlace y marco

    // --- 1. VALIDACION DE MATRIZ EXISTENTE ---
    ldr x1, =filas                
    ldrb w4, [x1]                 // Leer cantidad de filas
    cbz w4, error_vacia_res       // Error si no hay filas ingresadas
    cmp w4, '0'                   
    b.eq error_vacia_res          

    ldr x1, =columnas             
    ldrb w5, [x1]                 // Leer cantidad de columnas

    sub w4, w4, '0'               // Convertir filas a entero
    sub w5, w5, '0'               // Convertir columnas a entero

    // --- NOTIFICAR INGRESO DE MATRIZ B ---
    mov x8, 64                    // Syscall write
    mov x0, 1                     
    ldr x1, =msg_ingreso_b        
    mov x2, 48                    
    svc 0                         

    mov w6, 0                     // w6 = i (contador de filas)

// --- CICLO PARA PEDIR MATRIZ B Y RESTAR ---
loop_filas_resta:
    cmp w6, w4                    
    b.ge fin_ingreso_resta         

    mov w7, 0                     // w7 = j (contador de columnas)

loop_columnas_resta:
    cmp w7, w5                    
    b.ge sig_fila_resta           

    // --- ACTUALIZAR PLANTILLA DINAMICA 'b[i][j] = ' ---
    ldr x1, =msg_celda_b          
    add w8, w6, '0'               // Fila actual a ASCII
    strb w8, [x1, 2]              // Actualizar caracter de fila
    add w9, w7, '0'               // Columna actual a ASCII
    strb w9, [x1, 5]              // Actualizar caracter de columna

    mov x8, 64                    
    mov x0, 1                     
    ldr x1, =msg_celda_b          
    ldr x2, =len_celda_b          
    svc 0                         

    mov x8, 63                    // Syscall read
    mov x0, 0                     
    ldr x1, =valor_b_resta        
    mov x2, 8                     
    svc 0                         

    // --- ALGORITMO ATOI  ---
    ldr x1, =valor_b_resta        
    mov w10, 0                    // Acumulador numerico
    mov w11, 1                    // Registro de signo

    ldrb w12, [x1]                
    cmp w12, '-'                  // Verificar si es negativo
    b.ne loop_atoi_res            
    mov w11, -1                   
    add x1, x1, 1                 

loop_atoi_res:
    ldrb w12, [x1], 1             // Cargar caracter y avanzar
    cmp w12, '\n'                 
    b.eq fin_atoi_res             
    cbz w12, fin_atoi_res         
    sub w12, w12, '0'             // ASCII a digito
    mov w14, 10                   
    mul w10, w10, w14             // Desplazar posicion decimal
    add w10, w10, w12             // Sumar digito actual
    b loop_atoi_res               

fin_atoi_res:
    mul w10, w10, w11             // Aplicar signo a B[i][j]

    // --- CALCULO DE INDICE Y OPERACION DE RESTA ---
    mul w13, w6, w5               // i * columnas_totales
    add w13, w13, w7              // + j (Indice Row-Major)

    ldr x14, =matriz              
    ldr w15, [x14, w13, uxtw #2]  // Cargar A[i][j]

    sub w15, w15, w10             // R[i][j] = A[i][j] - B[i][j]

    ldr x14, =matriz_r_resta      
    str w15, [x14, w13, uxtw #2]  // Guardar resultado en matriz R

    add w7, w7, 1                 // Siguiente columna
    b loop_columnas_resta         

sig_fila_resta:
    add w6, w6, 1                 // Siguiente fila
    b loop_filas_resta            

fin_ingreso_resta:

    // --- IMPRESION DE MATRIZ RESULTANTE ---
    mov x8, 64                    
    mov x0, 1                     
    ldr x1, =msg_header_r         
    mov x2, 33                    
    svc 0                         

    mov w6, 0                     // Reiniciar i = 0

loop_print_f_res:
    cmp w6, w4                    
    b.ge fin_resta                

    mov x8, 64                    // Imprimir "[ "
    mov x0, 1                     
    ldr x1, =abre_cor             
    mov x2, 2                     
    svc 0                         

    mov w7, 0                     // Reiniciar j = 0

loop_print_c_res:
    cmp w7, w5                    
    b.ge sig_print_fila_res       

    mul w13, w6, w5               
    add w13, w13, w7              
    ldr x14, =matriz_r_resta      
    ldr w15, [x14, w13, uxtw #2]  // Valor a convertir

    // --- ALGORITMO ITOA ---
    sub sp, sp, 16                // Reservar espacio en stack
    mov x9, sp                    
    mov w10, 0                    // Contador de digitos

    cmp w15, 0                    
    b.ge no_negativo_res          

    // Manejo de signo negativo para impresion
    mov w11, '-'                  
    strb w11, [sp, 15]            
    mov x8, 64                    
    mov x0, 1                     
    add x1, sp, 15                
    mov x2, 1                     
    svc 0                         
    neg w15, w15                  // Valor absoluto

no_negativo_res:
    mov w11, 10                   
loop_dividir_res:
    udiv w12, w15, w11            // w12 = cociente
    msub w13, w12, w11, w15       // w13 = residuo (digito)
    add w13, w13, '0'             // Digito a ASCII
    strb w13, [x9], 1             // Guardar digito en buffer
    add w10, w10, 1               
    mov w15, w12                  
    cbnz w15, loop_dividir_res    

loop_imprimir_digitos_res:
    cbz w10, fin_itoa_res         
    sub x9, x9, 1                 // Retroceder al digito
    mov x8, 64                    
    mov x0, 1                     
    mov x1, x9                    
    mov x2, 1                     
    svc 0                         
    sub w10, w10, 1               
    b loop_imprimir_digitos_res   

fin_itoa_res:
    add sp, sp, 16                // Liberar stack

    mov x8, 64                    // Imprimir espacio separador
    mov x0, 1                     
    ldr x1, =espacio              
    mov x2, 1                     
    svc 0                         

    add w7, w7, 1                 
    b loop_print_c_res            

sig_print_fila_res:
    mov x8, 64                    // Imprimir "]\n"
    mov x0, 1                     
    ldr x1, =cierra_cor           
    mov x2, 7                     
    svc 0                         

    add w6, w6, 1                 
    b loop_print_f_res            


// --- MANEJO DE ERRORES Y SALIDA ---
error_vacia_res:
    mov x8, 64                    
    mov x0, 1                     
    ldr x1, =msg_err_vacia        
    mov x2, 58                    
    svc 0                         
    b salir_rutina_res            

fin_resta:
    mov x8, 64                    // Salto de linea final
    mov x0, 1                     
    ldr x1, =newline              
    mov x2, 1                     
    svc 0                         

salir_rutina_res:
    ldp x29, x30, [sp], 16        // Restaurar registros y stack
    ret
