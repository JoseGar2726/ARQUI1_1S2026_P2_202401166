AS = aarch64-linux-gnu-as
LD = aarch64-linux-gnu-ld
QEMU = qemu-aarch64
LIBS = -L /usr/aarch64-linux-gnu/lib
TARGET = inicio

SRCS = inicio.s funciones/ingreso.s funciones/visualizar.s funciones/identidad.s funciones/transpuesta.s funciones/gauss.s funciones/gaussjordan.s funciones/inversa.s funciones/suma.s funciones/resta.s funciones/determinante.s funciones/multiP.s funciones/multiP1.s funciones/multiC.s funciones/division.s

OBJS = $(SRCS:.s=.o)

all: $(TARGET)

# REGLA DE COMPILACION
$(TARGET): $(OBJS)
	$(LD) $(LIBS) $(OBJS) -o $(TARGET)

%.o: %.s
	$(AS) $< -o $@

# REGLA DE EJECUCION
run: $(TARGET)
	$(QEMU) -L /usr/aarch64-linux-gnu/ ./$(TARGET)

# REGLA DE LIMPIEZA
clean:
	rm -f $(TARGET) $(OBJS)