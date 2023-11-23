SHELL:=/bin/bash
CC=gcc
MODELFILE=get_chip_id.c
MODELTARGET=get_chip_id
C_EXTENSION=.c
OBJ_EXTENSION=.o
CFLAGS=-c -Wall -Werror -fpic
LDFLAGS=-shared
LIB=libjetspi.so
LIBS=-lpthread -lrt
FILENAME="installationCompleted.txt"

all: check_sudoers start_spidev step1 step2 step3

check_sudoers:
	@if grep -qF "$(username) ALL=(ALL) NOPASSWD: /sbin/setcap" /etc/sudoers; then \
		echo "Sudoers rule for $(username) already exists"; \
	else \
		echo "$(username) ALL=(ALL) NOPASSWD: /sbin/setcap" | sudo tee -a /etc/sudoers; \
	fi

start_spidev:
	modprobe spidev
	@if grep -qF "spidev" /etc/modules-load.d/modules.conf ; then \
		echo "Spidev for $(username) already exists"; \
	else \
		echo "spidev" | sudo tee -a /etc/modules-load.d/modules.conf; \
	fi

step1:
	$(CC) -Wall -Werror -o $(MODELTARGET) $(MODELFILE)
	./$(MODELTARGET)

step2:
	$(eval MODEL := $(shell cat ./hardware))

step3:
	$(CC) $(CFLAGS) $(MODEL)$(C_EXTENSION)
	$(CC) $(LDFLAGS) -o $(LIB) $(MODEL)$(OBJ_EXTENSION) $(LIBS)

step4:
	install -m 0755 $(LIB) /usr/lib
	install -m 0644 jetgpio.h /usr/include
	ldconfig
	ldconfig -p | grep libjetspi.so
	@if [ $(MODEL) == orin ]; then\
		cp ./scripts/pwm_enabler.sh /etc/systemd/system;\
		cp ./scripts/pwm_enable.service /etc/systemd/system;\
		chmod +x /etc/systemd/system/pwm_enabler.sh;\
		chown root /etc/systemd/system/pwm_enabler.sh;\
		systemctl enable pwm_enable.service;\
		systemctl start pwm_enable.service;\
	fi
	
	echo "Installation completed" > "$(FILENAME)"

step5:
	$(eval MODEL := $(shell systemctl is-enabled pwm_enable.service 2>/dev/null))

step6:
	rm -f /usr/lib/$(LIB)
	rm -f /usr/include/jetgpio.h
	ldconfig
	@if [ "$(MODEL)" == "enabled" ]; then\
		systemctl disable pwm_enable.service;\
		rm -f /etc/systemd/system/pwm_enabler.sh;\
		rm -f /etc/systemd/system/pwm_enable.service;\
	fi

nano:
	$(CC) $(CFLAGS) nano.c
	$(CC) $(LDFLAGS) -o $(LIB) nano.o $(LIBS)
	@echo nano >  ./hardware

orin:
	$(CC) $(CFLAGS) orin.c
	$(CC) $(LDFLAGS) -o $(LIB) orin.o $(LIBS)
	@echo orin >  ./hardware

clean:
	rm -f *.o $(LIB) get_chip_id hardware

install: step2 step4

uninstall: step5 step6
