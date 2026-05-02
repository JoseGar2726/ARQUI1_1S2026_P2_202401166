# Manual Técnico: Motor de Álgebra Lineal en Ensamblador ARM64

## 1. Introducción
Este documento detalla la arquitectura, lógica de programación y procedimientos matemáticos implementados en el motor de álgebra lineal desarrollado para procesadores con arquitectura **ARM64 (AArch64)**. El sistema permite realizar operaciones complejas sobre matrices utilizando optimizaciones de bajo nivel, registros de 64 bits para alta precisión y manejo directo de memoria.

---

## 2. Arquitectura de Datos
El sistema organiza las matrices en memoria utilizando el esquema **Row-Major Order** (Orden de Fila Mayor).

### 2.1 Lógica de Direccionamiento
Para localizar un elemento $A[i][j]$ en un espacio de memoria lineal, se utiliza la siguiente fórmula de desplazamiento:
$$Índice = (i \times \text{columnas\_totales}) + j$$

**Parámetros:**
*   **i**: Índice de la fila (0 a $m-1$).
*   **j**: Índice de la columna (0 a $n-1$).
*   **Tamaño de celda**: Cada elemento ocupa **4 bytes** (32 bits). El desplazamiento real se calcula mediante el direccionamiento de registro base más índice con escalado: `[base, índice, LSL #2]`.

---

## 3. Procedimientos de Entrada y Salida (E/S)

### 3.1 Algoritmo ATOI (ASCII to Integer)
Convierte cadenas de caracteres capturadas por teclado (Syscall `read`) en valores numéricos procesables.
*   **Detección de Signo**: Verifica la existencia del carácter `-` (ASCII 45) para manejar números negativos.
*   **Conversión e Iteración**: Resta el valor base `0x30` ('0' en ASCII) a cada byte capturado y acumula el resultado multiplicando el valor previo por 10.
*   **Gestión de Registros**: Se utilizan registros de 32 bits para el cálculo y se aplica el signo mediante una multiplicación final por -1 si corresponde.
![alt text](image-2.png)

### 3.2 Algoritmo ITOA Decimal (Integer to ASCII)
Transforma resultados escalados en cadenas de texto legibles con formato decimal.
*   **Extracción**: Divide el número por 10 de forma sucesiva para obtener los residuos que representan cada dígito.
*   **Punto Decimal**: Al procesar el segundo dígito extraído (de derecha a izquierda), el algoritmo inserta manualmente el carácter `.` (ASCII 46) en el buffer.
*   **Manejo de Pila**: Debido a que los dígitos se extraen del menos al más significativo, se almacenan en el *stack* para invertirlos y mostrarlos en el orden correcto.
![alt text](image-1.png)

---

### 4. Lógica de los Procedimientos Desarrollados

#### 4.1 Ingreso de Matrices
El sistema permite la captura dinámica de datos numéricos desde la entrada estándar.
*   **Proceso**: Se solicita al usuario el número de filas y columnas, seguido de los valores para cada celda.
*   **Almacenamiento**: Los valores son procesados mediante el algoritmo ATOI y almacenados en buffers de memoria lineal utilizando el esquema *Row-Major Order*.

#### 4.2 Operaciones Elementales (Suma y Resta)
Operaciones de complejidad $O(n^2)$ que recorren las matrices elemento a elemento.
*   **Lógica**: Utiliza un doble bucle anidado que sincroniza los punteros de la Matriz A, Matriz B y la Matriz Resultante para operar celda por celda.
![alt text](image-5.png)

#### 4.3 Matriz Identidad y Transpuesta
Procedimientos fundamentales para la reestructuración y generación de matrices base.
*   **Matriz Identidad**: Genera una matriz cuadrada donde los elementos de la diagonal principal son cargados con el valor 1 y los restantes con 0, mediante la validación del índice de fila igual al de columna ($i == j$).
![alt text](image-3.png)
*   **Matriz Transpuesta**: Reorganiza los elementos de una matriz original intercambiando filas por columnas ($A[i][j] \rightarrow A[j][i]$), lo cual requiere una reasignación de punteros basada en las nuevas dimensiones.
![alt text](image-4.png)

#### 4.4 Operaciones de Multiplicación

El sistema implementa dos variantes de multiplicación para cubrir distintas necesidades del álgebra lineal, optimizadas para la arquitectura ARM64.

##### 4.4.1 Producto de Matrices (Multiplicación Cruz)
Implementa el algoritmo de producto punto con una complejidad de $O(n^3)$.
*   **Lógica de Triple Ciclo**:
    1.  **Ciclo i**: Itera sobre las filas de la Matriz A.
    2.  **Ciclo j**: Itera sobre las columnas de la Matriz B.
    3.  **Ciclo k**: Recorre el índice común (columnas de A / filas de B) para realizar la sumatoria.
*   **Acumulación de Precisión**: Se utilizan registros de **64 bits** (`x25`) para el acumulador de la sumatoria. Esto evita errores de desbordamiento (*overflow*) producidos por la multiplicación de elementos grandes antes de almacenar el resultado final en una celda de 32 bits.
*   **Fórmula**: $R[i][j] = \sum (A[i][k] \times B[k][j])$.
![alt text](image-8.png)

##### 4.4.2 Multiplicación Punto
A diferencia de la multiplicación cruz, esta operación tiene una complejidad de $O(n^2)$ y se realiza elemento a elemento.
*   **Restricción**: Ambas matrices (A y B) deben tener dimensiones idénticas ($m \times n$).
*   **Lógica**: Se utiliza un doble bucle anidado (filas y columnas) para sincronizar los punteros de memoria.
*   **Operación**: Se accede a la dirección de memoria de $A[i][j]$ y $B[i][j]$ simultáneamente, se multiplican sus contenidos y el producto se almacena directamente en la posición correspondiente de la matriz resultante $R$.
*   **Fórmula**: $R[i][j] = A[i][j] \times B[i][j]$.
![alt text](image-9.png)


#### 4.5 Métodos de Resolución (Gauss y Gauss-Jordan)
Algoritmos de reducción de filas aplicados a sistemas de ecuaciones y análisis matricial.
*   **Método de Gauss**: Transforma una matriz en una forma escalonada (triangular superior) mediante la eliminación de elementos debajo de la diagonal principal utilizando un factor de eliminación.
*   **Método de Gauss-Jordan**: Extiende el proceso de Gauss para anular también los elementos por encima de la diagonal principal y normalizar los pivotes a 1, resultando en una matriz identidad en el lado izquierdo.
![alt text](image-6.png)

#### 4.6 Determinante
Calcula la magnitud escalar de una matriz cuadrada.
*   **Lógica**: Implementado mediante la reducción de la matriz a su forma triangular superior (Gauss) y realizando el producto de los elementos de la diagonal principal.
![alt text](image-10.png)

#### 4.7 Matriz Inversa y División
Operaciones avanzadas basadas en la reducción total de la matriz.
*   **Inversa**: Se obtiene aplicando Gauss-Jordan sobre una matriz aumentada $[A | I]$ hasta que el lado izquierdo se convierte en la identidad.
*   **División de Matrices ($A \times B^{-1}$)**: Resuelve la operación multiplicando la Matriz A por la inversa de la Matriz B calculada previamente.
*   **Escalamiento**: Se aplica un factor de escala de **100** para manejar la precisión decimal mediante aritmética de punto fijo.
![alt text](image-11.png)

---

## 5. Aritmética de Punto Fijo
Para representar decimales sin depender de la FPU (Floating Point Unit), el motor implementa **Aritmética de Punto Fijo**:
*   **Escalamiento**: En la normalización de la inversa, se realiza la operación $(Valor \times 100) / Pivote$.
*   **Preservación de Precisión**: Se utiliza la instrucción `smull` (Signed Multiply Long) para manejar productos de 64 bits, asegurando que la precisión se mantenga tras la división.
*   **Visualización**: El procedimiento **ITOA** interpreta los últimos dos dígitos como la parte decimal (centésimas).

---

## 6. Manejo de Errores y Seguridad
El software implementa validaciones críticas para garantizar la estabilidad del sistema:
1.  **Validación de Existencia**: Comprueba si la Matriz A ha sido inicializada antes de permitir cualquier operación derivada.
2.  **Compatibilidad Dimensional**: 
    *   Suma/Resta: Requiere dimensiones idénticas ($m_A=m_B, n_A=n_B$).
    *   Multiplicación/División: Requiere que las columnas de A coincidan con las filas de B ($n_A = m_B$).
3.  **Matriz Singular**: Durante Gauss-Jordan, si un pivote resulta ser `0`, el programa detecta que la matriz no es invertible y aborta la operación de forma segura.
4.  **Preservación de Contexto**: Uso estricto de las instrucciones `stp` (Store Pair) y `ldp` (Load Pair) para salvar los registros `x19-x28` (Callee-saved). Esto previene errores de segmentación (`Segmentation Fault`) al retornar al menú principal del programa.

## 7. Diagrama de Flujo: Proceso de División de Matrices

A continuación se describe el flujo lógico implementado en el motor para la operación de división matricial:
![alt text](<Matriz Fase Flow-2026-05-02-024912.png>)


![alt text](image.png)


## 8. Explicación del Makefile (Automatización de Compilación)

El **Makefile** es una herramienta esencial en el desarrollo de este proyecto bajo la arquitectura **ARM64**, ya que gestiona de forma automática la compilación y el enlace de los múltiples módulos que componen el sistema. Su función principal es asegurar que solo se procesen los archivos que han sufrido cambios, optimizando el flujo de trabajo del desarrollador.

### 1. Definición de Variables (Herramientas y Rutas)
En la sección inicial se definen las herramientas de la cadena de herramientas (*toolchain*) necesarias para la compilación cruzada:

*   **AS (Assembler)**: Define el ensamblador `aarch64-linux-gnu-as` encargado de transformar el código fuente `.s` en archivos objeto `.o`.
*   **LD (Linker)**: Utiliza `aarch64-linux-gnu-ld` para combinar todos los archivos objeto y las librerías del sistema en un único binario ejecutable.
*   **QEMU**: Especifica el emulador `qemu-aarch64`, fundamental para ejecutar y probar el código ARM64 en entornos con arquitecturas diferentes (como x86).
*   **LIBS**: Indica las rutas de las librerías de sistema necesarias para el entorno de ejecución de 64 bits.

### 2. Gestión de Módulos (SRCS y OBJS)
El archivo contiene la lista exhaustiva de los módulos que integran el motor de álgebra lineal. Esto incluye el núcleo del programa (`inicio.s`) y todas las rutinas especializadas alojadas en la carpeta `funciones/`, tales como `division.s`, `gaussjordan.s`, `inversa.s` y `determinante.s`, entre otras.

*   **SRCS**: Almacena la ruta de todos los archivos fuente originales.
*   **OBJS**: Utiliza una función de sustitución para generar automáticamente la lista de archivos objeto correspondientes, facilitando el mantenimiento del código.

### 3. Reglas de Construcción y Control
El Makefile opera bajo reglas específicas que dictan el comportamiento de la compilación:

1.  **Regla Principal (`all` y `$(TARGET)`)**: Coordina el proceso completo. Verifica que los archivos objeto estén actualizados y realiza el enlace final para generar el ejecutable llamado `inicio`.
2.  **Regla de Patrón (`%.o: %.s`)**: Define el método de transformación individual. Instruye al ensamblador para que procese cada archivo fuente y genere su respectivo archivo objeto.
3.  **Regla de Ejecución (`run`)**: Automatiza la prueba del programa utilizando **QEMU**, configurando correctamente las rutas de las librerías dinámicas de AArch64.
4.  **Regla de Limpieza (`clean`)**: Permite restablecer el entorno de trabajo eliminando los archivos objeto y el ejecutable generado, asegurando que la siguiente compilación sea totalmente limpia.

### 4. Flujo Lógico de Operación
El proceso sigue una jerarquía técnica estricta:
*   **Entrada**: Múltiples archivos de código fuente distribuidos por funciones.
*   **Proceso**: Ensamblado modular $\rightarrow$ Enlace de librerías y objetos $\rightarrow$ Generación de binario.
*   **Resultado**: Un ejecutable robusto, optimizado para la arquitectura ARM64 y listo para su distribución o prueba.


## 8. Uso
Se realiza el ciclo del uso del makefile, primero el comando make clean, luego make y finalmente make run para iniciar la ejecucion
![alt text](image-12.png)

### Menu principal
![alt text](image-13.png)
Ingresaremos 1 para ingresar la matriz A que es con la que trabajaremos para las demas funciones, luego de ingresar cada opcion nos regresa a este menu, y la Matriz A se seguira mostrando en caso de que este ingresada

### 1. Ingreso de datos
![alt text](image-14.png)
Nos pide las filas y las columnas y posteriormente los valores para cada respectiva posicion i,j finalmente se mostrara la matriz guardada esto nos permitira ejecutar todas las demas funciones

### 2. Matriz Identidad
Nos muestra la matriz identidad correspondiente a la matriz en caso de que sea cuadrada
![alt text](image-15.png)

### 3. Matriz Tranpuesta
Muestra la matriz transpuesta de la matriz ingresada o sea cambia filas por columnas y columnas por filas
![alt text](image-16.png)

### 4. Metodo de Gauss
Muestra la matriz ingresada de una forma triangular superior y los respectivos pasos para llegar a esta
![alt text](image-17.png)

### 5. Metodo de Gauss-Jordan
Muestra la matriz ingresada unicamente la diagonal con valores de 1 y el proceso para llegar a esto, haciendo triangular tanto inferior como superior y finalmente dividiendo las filas por si mismas para hacerlas 1
![alt text](image-18.png)

### 6. Matriz Inversa
Muestra la matriz inversa de la matriz ingresada
![alt text](image-19.png)

### 7. Funcionalidades Aritmeticas
Abre un nuevo submenu el cual nos permite elegir entre las 5 operaciones basicas de matrices, para esto nos pedira ingresar una matriz B la cual sera operada con la matriz que ingresamos inicialmente
![alt text](image-20.png)


### 8. Determinante
Muestra el determinante de la matriz ingresada
![alt text](image-21.png)


### 9. Salir
Detiene la ejecucion del programa


## 9. Video Explicativo
https://drive.google.com/drive/folders/1cYI_r0g_IhA3s9FRkvULqzlFPA2TyAYU?usp=sharing