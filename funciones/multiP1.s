// --- Mensajes a imprimir ---
.section .data
    msg_err_vacia:    .asciz "\nError: Primero debe ingresar la Matriz A en la opcion 1.\n"
    msg_pedir_fb:     .asciz "\nIngrese el numero de filas de B: "
    msg_pedir_cb:     .asciz "Ingrese el numero de columnas de B: "
    
    msg_err_dim:      .asciz "\nError: Las dimensiones de B deben ser iguales a las de A.\n"
    msg_ingreso_b:    .asciz "\nIngrese los valores para la Matriz B:\n"
    
    msg_celda_b:      .ascii "b[0][0] = "
    len_celda_b = . - msg_celda_b

    msg_header_res:   .asciz "\nResultado Multiplicacion Punto:\nR = "
    
    abre_cor:         .asciz "[ "
    cierra_cor:       .asciz "]\n    "
    espacio:          .asciz " "
    newline:          .asciz "\n"

// --- Espacio de memoria ---
.section .bss
.align 3
    matriz_b_p1:    .space 400    // Espacio para matriz B
    matriz_r_p1:    .space 400    // Espacio para matriz resultante
    filas_b_p1:     .space 2      // Almacen para dimensión de filas B
    columnas_b_p1:  .space 2      // Almacen para dimensión de columnas B
    valor_b_p1:     .space 8      // Buffer para lectura de teclado
    itoa_buffer_p1: .space 16     // Buffer para conversión de números a texto

.section .text
.global matriz_multip1

// --- Inicio del proceso de multiplicacion punto ---
matriz_multip1:
    stp x29, x30, [sp, -16]!      // Preservar registros de enlace y marco en el stack

    // --- 1. VALIDAR MATRIZ A ---
    ldr x1, =filas                // Carga direccion de la variable de filas de A
    ldrb w4, [x1]                 // Lee el byte indicando la cantidad de filas
    cbz w4, error_vacia_p1        // Salta si no se ha ingresado ninguna matriz
    cmp w4, '0'                   // Compara con el carácter '0'
    b.eq error_vacia_p1           // Error si la dimensión es cero

    ldr x1, =columnas             // Carga direccion de columnas de A
    ldrb w5, [x1]                 // Lee el byte de cantidad de columnas de A
    sub w4, w4, '0'               // Convierte filas A de ASCII a entero
    sub w5, w5, '0'               // Convierte columnas A de ASCII a entero

    // --- 2. PEDIR DIMENSIONES DE B ---
    mov x8, 64                    // Syscall 64: write
    mov x0, 1                     // FD 1: stdout
    ldr x1, =msg_pedir_fb         // Mensaje: "Ingrese filas de B: "
    mov x2, 34                    // Longitud del mensaje
    svc 0                         

    mov x8, 63                    // Syscall 63: read
    mov x0, 0                     // FD 0: stdin
    ldr x1, =filas_b_p1           // Buffer de destino
    mov x2, 2                     // Leer 2 bytes
    svc 0                         

    mov x8, 64                    // Escribir peticion columnas B
    mov x0, 1                     
    ldr x1, =msg_pedir_cb         
    mov x2, 37                    
    svc 0                         

    mov x8, 63                    // Leer columnas B del teclado
    mov x0, 0                     
    ldr x1, =columnas_b_p1        
    mov x2, 2                     
    svc 0                         

    // -- Convertir dimensiones ingresadas --
    ldr x1, =filas_b_p1           // Direccion de filas B leídas
    ldrb w21, [x1]                // Carga el byte
    sub w21, w21, '0'             // w21 = n Filas de B en entero

    ldr x1, =columnas_b_p1        // Direccion de columnas B leidas
    ldrb w22, [x1]                // Carga el byte
    sub w22, w22, '0'             // w22 = p Columnas de B en entero

    // --- VALIDAR DIMENSIONES IDENTICAS ---
    cmp w4, w21                   // Compara filas A vs B
    b.ne error_dim_p1             // Salta si no coinciden
    cmp w5, w22                   // Compara columnas A vs B
    b.ne error_dim_p1             // Salta si no coinciden

    // --- INGRESAR VALORES DE MATRIZ B ---
    mov x8, 64                    // Escribir aviso de ingreso
    mov x0, 1                     
    ldr x1, =msg_ingreso_b        
    mov x2, 39                    
    svc 0                         

    mov w6, 0                     // w6 = i Contador de filas, inicia en 0
loop_fb_p1:
    cmp w6, w21                   // ¿i == filas B?
    b.ge calcular_p1              // Si termino, ir a la multiplicacion
    mov w7, 0                     // w7 = j Contador de columnas, inicia en 0
loop_cb_p1:
    cmp w7, w22                   // j == columnas B
    b.ge sig_fb_p1                // Si termino columnas, siguiente fila

    // -- Actualizar etiquetas dinamicas b[i][j] --
    ldr x1, =msg_celda_b          // Carga plantilla "b[0][0] = "
    add w8, w6, '0'               // Convierte indice i a ASCII
    strb w8, [x1, 2]              // Actualiza el caracter en pos 2 (fila)
    add w9, w7, '0'               // Convierte indice j a ASCII
    strb w9, [x1, 5]              // Actualiza el caracter en pos 5 (columna)

    mov x8, 64                    // Escribir b[i][j] =
    mov x0, 1                     
    ldr x1, =msg_celda_b          
    ldr x2, =len_celda_b          
    svc 0                         

    mov x8, 63                    // Leer numero ingresado
    mov x0, 0                     
    ldr x1, =valor_b_p1           
    mov x2, 8                     
    svc 0                         

    // --- ALGORITMO ATOI ---
    ldr x1, =valor_b_p1           // Puntero al inicio del buffer leído
    mov w10, 0                    // Acumulador numérico para el valor
    mov w11, 1                    // Multiplicador de signo
    ldrb w12, [x1]                // Carga primer caracter
    cmp w12, '-'                  // Es negativo
    b.ne atoi_p1                  
    mov w11, -1                   // Guardar signo negativo
    add x1, x1, 1                 // Avanzar puntero tras el '-'
atoi_p1:
    ldrb w12, [x1], 1             // Carga byte y post-incrementa puntero
    cmp w12, '\n'                 // Fin de linea
    b.eq atoi_fin_p1              
    cbz w12, atoi_fin_p1          // Fin de cadena
    sub w12, w12, '0'             // ASCII a digito
    mov w9, 10                    // Base 10
    mul w10, w10, w9              // acumulado = acumulado * 10
    add w10, w10, w12             // acumulado = acumulado + digito
    b atoi_p1                     
atoi_fin_p1:
    mul w10, w10, w11             // Aplicar signo final al valor B[i][j]

    // -- Guardar elemento en Matriz B --
    mul w13, w6, w22              // Índice row-major: i * columnas_B
    add w13, w13, w7              // + j
    ldr x9, =matriz_b_p1          // Base de la matriz B
    str w10, [x9, w13, uxtw #2]   // Guardar w13 << 2 para offset de 4 bytes

    add w7, w7, 1                 // j++
    b loop_cb_p1                  
sig_fb_p1:
    add w6, w6, 1                 // i++
    b loop_fb_p1                  

// --- CALCULO DE MULTIPLICACION PUNTO (A[i] * B[i]) ---
calcular_p1:
    mul w18, w4, w5               // w18 = Total de elementos (n * n)
    mov w19, 0                    // Contador global de elementos
loop_op_p1:
    cmp w19, w18                  // Se procesaron todas las celdas
    b.ge print_p1                 

    ldr x9, =matriz               // Base de matriz A
    ldr w10, [x9, w19, uxtw #2]   // Cargar A[i] elemento actual
    
    ldr x9, =matriz_b_p1          // Base de matriz B
    ldr w11, [x9, w19, uxtw #2]   // Cargar B[i] elemento actual

    mul w12, w10, w11             // Operación: Resultante = A[i] * B[i]
    
    ldr x9, =matriz_r_p1          // Base resultante
    str w12, [x9, w19, uxtw #2]   // Guardar resultado del producto punto

    add w19, w19, 1               // Siguiente elemento
    b loop_op_p1                  

// --- IMPRESION DE RESULTADOS ---
print_p1:
    mov x8, 64                    // Escribir encabezado "R = "
    mov x0, 1                     
    ldr x1, =msg_header_res       
    mov x2, 45                    
    svc 0                         

    mov w6, 0                     // i = 0 Contador filas para impresin
loop_f_pr:
    cmp w6, w4                    // Termino todas las filas
    b.ge fin_p1                   

    mov x8, 64                    // Imprimir "[ "
    mov x0, 1                     
    ldr x1, =abre_cor             
    mov x2, 2                     
    svc 0                         

    mov w7, 0                     // j = 0 Contador columnas para impresion
loop_c_pr:
    cmp w7, w5                    // Termino todas las columnas
    b.ge sig_f_pr                 

    mul w13, w6, w5               // Recalcular indice lineal
    add w13, w13, w7              
    ldr x9, =matriz_r_p1          // Base resultante
    ldr w15, [x9, w13, uxtw #2]   // Cargar valor para convertir con ITOA

    bl itoa_imprimir_p1           // Llamada a subrutina de conversion e impresion

    mov x8, 64                    // Imprimir espacio entre valores
    mov x0, 1                     
    ldr x1, =espacio              
    mov x2, 1                     
    svc 0                         

    add w7, w7, 1                 // j++
    b loop_c_pr                   

sig_f_pr:
    mov x8, 64                    // Imprimir "]\n"
    mov x0, 1                     
    ldr x1, =cierra_cor           
    mov x2, 7                     
    svc 0                         
    add w6, w6, 1                 // i++
    b loop_f_pr                   

// --- MANEJO DE ERRORES Y SALIDA ---
error_vacia_p1:
    mov x8, 64                    // Matriz A no existe
    mov x0, 1                     
    ldr x1, =msg_err_vacia        
    mov x2, 58                    
    svc 0                         
    b salir_p1                    

error_dim_p1:
    mov x8, 64                    // Dimensiones no coinciden
    mov x0, 1                     
    ldr x1, =msg_err_dim          
    mov x2, 60                    
    svc 0                         
    b salir_p1                    

fin_p1:
    mov x8, 64                    // Salto de linea final
    mov x0, 1                     
    ldr x1, =newline              
    mov x2, 1                     
    svc 0                         

salir_p1:
    ldp x29, x30, [sp], 16        // Restaurar registros y liberar stack
    ret                           

// --- SUBRUTINA ITOA ---
itoa_imprimir_p1:
    stp x29, x30, [sp, -16]!      // Guardar registros de subrutina
    
    ldr x9, =itoa_buffer_p1       // x9 = Puntero al buffer de texto
    mov w10, 0                    // Contador de digitos extraidos
    
    cmp w15, 0                    // El numero es negativo
    b.ge itoa_p_p1                
    
    // Imprimir signo negativo manual
    mov w11, '-'                  
    strb w11, [x9]                // Guardar en buffer
    mov x8, 64                    // Escribir el '-' de inmediato
    mov x0, 1                     
    mov x1, x9                    
    mov x2, 1                     
    svc 0                         
    neg w15, w15                  // Convertir a positivo absoluto para dividir

itoa_p_p1:
    mov w11, 10                   // Base decimal
    ldr x9, =itoa_buffer_p1       // Reiniciar puntero al inicio
itoa_div_p1:
    udiv w12, w15, w11            // w12 = cociente
    msub w13, w12, w11, w15       // w13 = residuo
    add w13, w13, '0'             // ASCII
    strb w13, [x9], 1             // Guardar caracter y avanzar
    add w10, w10, 1               // Contador de digitos++
    mov w15, w12                  // Actualizar con el cociente
    cbnz w15, itoa_div_p1         // Mientras el cociente sea != 0

itoa_pr_p1:
    cbz w10, itoa_f_p1            // Termino de imprimir digitos
    sub x9, x9, 1                 // Retroceder puntero al digito almacenado
    mov x8, 64                    // Syscall write
    mov x0, 1                     
    mov x1, x9                    // Caracter actual
    mov x2, 1                     
    svc 0                         
    sub w10, w10, 1               // Contador--
    b itoa_pr_p1                  

itoa_f_p1:
    ldp x29, x30, [sp], 16        // Restaurar registros y retornar
    ret
