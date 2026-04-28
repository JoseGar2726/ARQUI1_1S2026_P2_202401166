.section .data
    msg_menu: 
        .ascii "\n--- MOTOR DE ALGEBRA LINEAL ---\n"
        .ascii "    1. Ingreso de datos (Filas y Columnas)\n"
        .ascii "    2. Funcionalidad Matriz Identidad\n"
        .ascii "    3. Funcionalidad Matriz Transpuesta\n"
        .ascii "    4. Metodo de Gauss\n"
        .ascii "    5. Metodo de Gauss-Jordan\n"
        .ascii "    6. Salir\n\n"
        .asciz "    Seleccione una opción: "
    len_menu = . - msg_menu
    
    msg_salida: .asciz "\nSaliendo del programa\n"
    len_salida = . - msg_salida

    opcion: .space 2

.section .text
.global _start

_start:
    bl imprimir_matriz

    mov x8, 64
    mov x0, 1
    ldr x1, =msg_menu
    ldr x2, =len_menu
    svc 0

    mov x8, 63
    mov x0, 0 
    ldr x1, =opcion
    mov x2, 2
    svc 0

    ldr x1, =opcion
    ldrb w2, [x1]
    
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
    b.eq exit

    b _start           

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

exit:
    mov x8, 64
    mov x0, 1
    ldr x1, =msg_salida
    ldr x2, =len_salida
    svc 0

    mov x8, 93
    mov x0, 0
    svc 0
