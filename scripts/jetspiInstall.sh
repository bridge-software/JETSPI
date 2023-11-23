#!/bin/bash

FILENAME="installationCompleted.txt"

if [ -e "$FILENAME" ]; then
    echo "The installation is completed."
else

    USER=$(whoami)

    if pkexec grep -qF "$USER ALL=(ALL) NOPASSWD: /usr/bin/make" /etc/sudoers; then
        echo "Sudoers usr/bin/make rule for $USER already exists"
    else
        echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/make" | pkexec tee -a /etc/sudoers
    fi

    sudo make username=$USER
    sudo make install username=$USER

fi


