CC = "C:/Program Files/SDCC/bin/sdcc.exe"

BUILD_DIR = ./build

CFLAGS = -mmcs51

SRCS = main.c lcd.c scr_script.c m.c i2c.c screens.c uart.c logo_data.c charge_screen.c

OBJ_FILES = $(SRCS:%.c=%.rel)

$(BUILD_DIR)/%.rel: %.c common.h scr_script.h
	$(CC) -c -o $@ $(CFLAGS) $<

bin.hex: $(addprefix $(BUILD_DIR)/, $(OBJ_FILES))
	$(CC) $(CFLAGS) $(addprefix $(BUILD_DIR)/, $(OBJ_FILES)) -o bin.hex --xram-size 2048 --iram-size 256
	@grep -E "EXTERNAL RAM|ROM/EPROM/FLASH|Name             Start    End      Size     Max" bin.mem


flash: bin.hex
	@cmd /c flash.bat

