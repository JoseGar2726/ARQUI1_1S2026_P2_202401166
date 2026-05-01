// --- Mensajes a imprimir ---
.section .data
    msg_err_vacia:    .asciz "\nError: Primero debe ingresar la Matriz A en la opcion 1.\n"
    msg_pedir_fb:     .asciz "\nIngrese el numero de filas de B: "
    msg_pedir_cb:     .asciz "Ingrese el numero de columnas de B: "
    
    msg_err_dim:      .asciz "\nError: Las dimensiones de B deben ser iguales a las de A.\n"
    msg_err_cero:     .asciz "\nError Matematico: Division por cero detectada.\n"
    msg_ingreso_b:    .asciz "\nIngrese los valores para la Matriz B:\n"
    
    msg_celda_b:      .ascii "b[0][0] = "
    len_celda_b = . - msg_celda_b

    msg_header_res:   .asciz "\nResultado Division\nR = "
    
    abre_cor:         .asciz "[ "
    cierra_cor:       .asciz "]\n    "
    espacio:          .asciz " "
    newline:          .asciz "\n"

// --- Espacio de memoria ---
.section .bss
.align 3
    matriz_b_div:    .space 400    // Espacio para matriz B
    matriz_r_div:    .space 400    // Espacio para resultados
    filas_b_div:     .space 2      
    columnas_b_div:  .space 2      
    valor_b_div:     .space 8      
    itoa_buffer_div: .space 32     // Buffer extendido para manejo de decimales

.section .text
.global matriz_division

// --- Inicio del proceso de division ---
matriz_division:
    stp x29, x30, [sp, -16]!      // Guardar marco y retorno

    // --- VALIDAR MATRIZ A ---
    ldr x1, =filas                
    ldrb w4, [x1]                 // Cargar caracter de filas A
    cbz w4, error_vacia_div       // Validar si existe matriz A
    cmp w4, '0'                   
    b.eq error_vacia_div          

    ldr x1, =columnas             
    ldrb w5, [x1]                 // Cargar caracter de columnas A
    sub w4, w4, '0'               // w4 = filas A entero
    sub w5, w5, '0'               // w5 = columnas A entero

    // --- PEDIR DIMENSIONES DE B ---
    mov x8, 64                    // peticion filas
    mov x0, 1                     
    ldr x1, =msg_pedir_fb         
    mov x2, 34                    
    svc 0                         

    mov x8, 63                    // leer filas
    mov x0, 0                     
    ldr x1, =filas_b_div          
    mov x2, 2                     
    svc 0                         

    mov x8, 64                    // peticion columnas
    mov x0, 1                     
    ldr x1, =msg_pedir_cb         
    mov x2, 37                    
    svc 0                         

    mov x8, 63                    // leer columnas
    mov x0, 0                     
    ldr x1, =columnas_b_div       
    mov x2, 2                     
    svc 0                         

    // -- Procesar dimensiones de B --
    ldr x1, =filas_b_div          
    ldrb w21, [x1]                
    sub w21, w21, '0'             // w21 = filas B
    ldr x1, =columnas_b_div       
    ldrb w22, [x1]                
    sub w22, w22, '0'             // w22 = columnas B

    // --- VALIDAR DIMENSIONES IDENTICAS ---
    cmp w4, w21                   // Filas A vs Filas B
    b.ne error_dim_div            
    cmp w5, w22                   // Columnas A vs Columnas B
    b.ne error_dim_div            

    // --- INGRESAR VALORES DE MATRIZ B ---
    mov x8, 64                    
    mov x0, 1                     
    ldr x1, =msg_ingreso_b        
    mov x2, 39                    
    svc 0                         

    mov w6, 0                     // i = 0
loop_fb_div:
    cmp w6, w21                   // Fin de filas de B
    b.ge calcular_div             
    mov w7, 0                     // j = 0
loop_cb_div:
    cmp w7, w22                   // Fin de columnas de B
    b.ge sig_fb_div               

    // -- Actualizar b[i][j] en pantalla --
    ldr x1, =msg_celda_b          
    add w8, w6, '0'               // Fila a ASCII
    strb w8, [x1, 2]              
    add w9, w7, '0'               // Columna a ASCII
    strb w9, [x1, 5]              

    mov x8, 64                    
    mov x0, 1                     
    ldr x1, =msg_celda_b          
    ldr x2, =len_celda_b          
    svc 0                         

    mov x8, 63                    // Captura valor teclado
    mov x0, 0                     
    ldr x1, =valor_b_div          
    mov x2, 8                     
    svc 0                         

    // --- ALGORITMO ATOI ---
    ldr x1, =valor_b_div          
    mov w10, 0                    // Limpiar acumulador
    mov w11, 1                    // Signo por defecto
    ldrb w12, [x1]                
    cmp w12, '-'                  
    b.ne atoi_div                 
    mov w11, -1                   
    add x1, x1, 1                 
atoi_div:
    ldrb w12, [x1], 1             
    cmp w12, '\n'                 
    b.eq atoi_fin_div             
    cbz w12, atoi_fin_div         
    sub w12, w12, '0'             
    mov w9, 10                    
    mul w10, w10, w9              
    add w10, w10, w12             // Acumular digito
    b atoi_div                    
atoi_fin_div:
    mul w10, w10, w11             // Aplicar signo final

    // --- VALIDACION CRITICA: DIVISION POR CERO ---
    cbz w10, error_cero_div       // Si B[i][j] == 0, abortar

    // -- Guardar en memoria --
    mul w13, w6, w22              
    add w13, w13, w7              // Indice Row-Major
    ldr x9, =matriz_b_div         
    str w10, [x9, w13, uxtw #2]   // Guardar en matriz B (4 bytes offset)

    add w7, w7, 1                 // j++
    b loop_cb_div                 
sig_fb_div:
    add w6, w6, 1                 // i++
    b loop_fb_div                 

// --- DIVISION CON PUNTO FIJO (A * 100 / B) ---
calcular_div:
    mul w18, w4, w5               // Total de celdas
    mov w19, 0                    // Iterador de celdas
loop_op_div:
    cmp w19, w18                  
    b.ge print_div                

    ldr x9, =matriz               
    ldr w10, [x9, w19, uxtw #2]   // w10 = Dividendo (A)
    
    ldr x9, =matriz_b_div         
    ldr w11, [x9, w19, uxtw #2]   // w11 = Divisor (B)

    // Escalar por 100 para preservar 2 decimales
    mov w13, 100                  
    mul w10, w10, w13             // Dividendo * 100
    sdiv w12, w10, w11            // w12 = Resultado escalado
    
    ldr x9, =matriz_r_div         
    str w12, [x9, w19, uxtw #2]   // Almacenar en resultante

    add w19, w19, 1               // Celda++
    b loop_op_div                 

// --- IMPRESION DE MATRIZ RESULTANTE ---
print_div:
    mov x8, 64                    
    mov x0, 1                     
    ldr x1, =msg_header_res       
    mov x2, 25                    
    svc 0                         

    mov w6, 0                     // i = 0
loop_f_pr_div:
    cmp w6, w4                    
    b.ge fin_div                  

    mov x8, 64                    // Imprimir "[ "
    mov x0, 1                     
    ldr x1, =abre_cor             
    mov x2, 2                     
    svc 0                         

    mov w7, 0                     // j = 0
loop_c_pr_div:
    cmp w7, w5                    
    b.ge sig_f_pr_div             

    mul w13, w6, w5               
    add w13, w13, w7              
    ldr x9, =matriz_r_div         
    ldr w15, [x9, w13, uxtw #2]   // Cargar valor escalado para ITOA

    bl itoa_imprimir_div          // Llamar subrutina con punto decimal

    mov x8, 64                    
    mov x0, 1                     
    ldr x1, =espacio              
    mov x2, 1                     
    svc 0                         

    add w7, w7, 1                 // j++
    b loop_c_pr_div               

sig_f_pr_div:
    mov x8, 64                    // Imprimir "]\n"
    mov x0, 1                     
    ldr x1, =cierra_cor           
    mov x2, 7                     
    svc 0                         
    add w6, w6, 1                 // i++
    b loop_f_pr_div               

// --- MANEJO DE ERRORES Y SALIDA ---
error_vacia_div:
    mov x8, 64                    
    mov x0, 1                     
    ldr x1, =msg_err_vacia        
    mov x2, 58                    
    svc 0                         
    b salir_div                   

error_dim_div:
    mov x8, 64                    
    mov x0, 1                     
    ldr x1, =msg_err_dim          
    mov x2, 60                    
    svc 0                         
    b salir_div                   

error_cero_div:
    ldr x1, =msg_err_cero         
    mov x8, 64                    
    mov x0, 1                     
    mov x2, 43                    
    svc 0                         
    b salir_div                   

fin_div:
    mov x8, 64                    // Salto de linea estético
    mov x0, 1                     
    ldr x1, =newline              
    mov x2, 1                     
    svc 0                         

salir_div:
    ldp x29, x30, [sp], 16        // Restaurar marco y retorno
    ret                           

// --- SUBRUTINA ITOA CON PUNTO DECIMAL ---
itoa_imprimir_div:
    stp x29, x30, [sp, -16]!      
    ldr x9, =itoa_buffer_div      // Puntero de escritura en buffer
    mov w10, 0                    // Contador de digitos extraidos

    cmp w15, 0                    
    b.ge no_negativo_div          
    
    // Manejo de signo negativo
    mov w11, '-'                  
    strb w11, [x9]                
    mov x8, 64                    
    mov x0, 1                     
    mov x1, x9                    
    mov x2, 1                     
    svc 0                         
    neg w15, w15                  // Trabajar con valor absoluto

no_negativo_div:
    mov w11, 10                   // Divisor decimal
    ldr x9, =itoa_buffer_div      // Reiniciar puntero para digitos

loop_dividir_div:
    // Insertar punto visual en la centesima (tras extraer 2 digitos)
    cmp w10, 2                    
    b.ne seguir_div_op            
    mov w18, '.'                  
    strb w18, [x9], 1             // Guardar '.' en buffer
    add w10, w10, 1               

seguir_div_op:
    udiv w12, w15, w11            // w12 = cociente
    msub w13, w12, w11, w15       // w13 = residuo
    add w13, w13, '0'             // ASCII
    strb w13, [x9], 1             // Almacenar y avanzar puntero
    add w10, w10, 1               
    mov w15, w12                  
    
    // Forzar extraccion hasta unidad
    cbnz w15, loop_dividir_div    
    cmp w10, 3                    
    b.lt loop_dividir_div         

loop_print_digits_div:
    cbz w10, itoa_f_div           
    sub x9, x9, 1                 // Retroceder puntero al digito
    mov x8, 64                    // escribir digito
    mov x0, 1                     
    mov x1, x9                    
    mov x2, 1                     
    svc 0                         
    sub w10, w10, 1               
    b loop_print_digits_div       

itoa_f_div:
    ldp x29, x30, [sp], 16        
    ret
