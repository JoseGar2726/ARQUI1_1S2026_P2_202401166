// --- Mensajes del Menu Principal ---
.section .data
msg_menu: 
    .ascii "\n--- MOTOR DE ALGEBRA LINEAL ---\n"
    .ascii "    1. Ingreso de datos (Filas y Columnas)\n"
    .ascii "    2. Funcionalidad Matriz Identidad\n"
    .ascii "    3. Funcionalidad Matriz Transpuesta\n"
    .ascii "    4. Metodo de Gauss\n"
    .ascii "    5. Metodo de Gauss-Jordan\n"
    .ascii "    6. Funcionalidad Matriz Inversa\n"
    .ascii "    7. Funcionalidades Aritmeticas\n"
    .ascii "    8. Funcionalidad Determinante\n"
    .ascii "    9. Salir\n\n"
    .asciz "    Seleccione una opción: "
len_menu = . - msg_menu
// --- Mensajes Submenu Aritmetio ---
msg_submenu:
    .ascii "\n--- FUNCIONALIDADES ARITMETICAS ---\n"
    .ascii "    1. Suma\n"
    .ascii "    2. Resta\n"
    .ascii "    3. Multiplicacion Punto\n"
    .ascii "    4. Multiplicacion Cruz\n"
    .ascii "    5. Division\n"
    .ascii "    6. Regresar\n\n"
    .asciz "    Seleccione una opción: "
len_submenu = . - msg_submenu

msg_salida: .asciz "\nSaliendo del programa\n"
len_salida = . - msg_salida
opcion: .space 2                     // Reserva espacio para la opcion que introducira el usuario

.section .text
.global _start

_start:
    bl imprimir_matriz                   // Salto al codigo que imprime la matriz

    // Impresion del mensaje del menu
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_menu
    ldr x2, =len_menu
    svc 0

    // Lectura de datos -> opcion a ingresar
    mov x8, 63
    mov x0, 0 
    ldr x1, =opcion
    mov x2, 2
    svc 0

    ldr x1, =opcion                        // Carga la opcion que ingreso el usuario en x1 
    ldrb w2, [x1]                          // Carga el contenido de x1 en w2
    
    // --- Manejo de opciones ---
    // Compara el registro w2 donde se encuentra la opcion ingresada por el usuario
    // Con la respectiva opcion en caso de que sea igual a la respectiva opcion
    // Se dirige a la opcion deseada
    // Finalmente se llama a _start para que el menu se reinicie hasta elegir la opcion salir

    cmp w2, '1'
    b.eq llamar_ingreso

    cmp w2, '2'
    b.eq llamar_identidad

    cmp w2, '3'
    b.eq llamar_transpuesta

    cmp w2, '4'
    b.eq llamar_gauss

    cmp w2, '5'
    b.eq llamar_gaussjordan

    cmp w2, '6'
    b.eq llamar_inversa

    cmp w2, '7'
    b.eq menu_aritmeticas

    cmp w2, '8'
    b.eq llamar_determinante

    cmp w2, '9'
    b.eq exit

    b _start            

// --- Distintas funciones ---
// Van al archivo donde se encuentra su respectiva funcion y luego van al inicio

llamar_ingreso:
    bl ingreso_datos
    b _start

llamar_identidad:
    bl matriz_identidad  
    b _start

llamar_transpuesta:
    bl matriz_transpuesta
    b _start

llamar_gauss:
    bl matriz_gauss
    b _start

llamar_gaussjordan:  
    bl matriz_gaussjordan
    b _start

llamar_inversa:      
    bl matriz_inversa
    b _start

llamar_determinante: 
    bl matriz_determinante
    b _start

// --- Submenu ---
menu_aritmeticas:

    // --- Mensaje del submenu ---
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_submenu
    ldr x2, =len_submenu
    svc 0

    // --- Opcion del submenu ---
    mov x8, 63
    mov x0, 0 
    ldr x1, =opcion
    mov x2, 2
    svc 0

    // --- Leer Opcion ---
    ldr x1, =opcion
    ldrb w2, [x1]

    // --- Ir a funcion respecto a opcion, regresa a submenu en bucle y la opcion regresar, regresa al menu principal ---
    cmp w2, '1'
    b.eq llamar_suma

    cmp w2, '2'
    b.eq llamar_resta

    cmp w2, '3'
    b.eq llamar_multiPunto

    cmp w2, '4'
    b.eq llamar_multiCruz

    cmp w2, '5'
    b.eq llamar_division

    cmp w2, '6'
    b.eq _start

    b menu_aritmeticas

// --- Llamadas a distintas funciones aritmeticas ---
llamar_suma:
    bl matriz_suma       
    b menu_aritmeticas

llamar_resta:        
    bl matriz_resta      
    b menu_aritmeticas

llamar_multiPunto:   
    bl matriz_multip1    
    b menu_aritmeticas

llamar_multiCruz:    
    bl matriz_multip     
    b menu_aritmeticas

llamar_division:     
    bl matriz_division 
    b menu_aritmeticas

// --- Salida ---
exit:
    // --- Mensaje de salida ---
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_salida
    ldr x2, =len_salida
    svc 0

    // --- Syscall de salida ---
    mov x8, 93
    mov x0, 0
    svc 0
