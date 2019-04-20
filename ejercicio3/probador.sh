#!/bin/bash

#*********************************************************#
# Script      :	ejercicio3.sh
# TP          :	1
# N° Ejercicio:	3
# Nº Entrega  :	1
# Integrantes :
# - XXXXX XXXX              DNI: ########
# - XXXXX XXXX              DNI: ########
# - Medrano, Jonatan XXXX   DNI: ########
# - Moreno, Emiliano        DNI: 33905487
# - Sendras, Bruno          DNI: 32090370
#*********************************************************#

for i in {1..100}; do
    kill -s SIGUSR1 $1 2>/dev/null
    # si ya murio, corto
    if [ $? -ne 0 ]; then
        exit 0;
    fi
    sleep 1;
done
