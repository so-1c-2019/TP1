#!/bin/bash

#*********************************************************#
# Script      :	ejercicio3.sh
# TP          :	1
# N° Ejercicio:	3
# Nº Entrega  :	1
# Integrantes :
# - Nicolas, Martin         DNI: 39375821
# - Medrano, Jonatan        DNI: 33557962
# - Moreno, Emiliano        DNI: 33905487
# - Sendras, Bruno          DNI: 32090370
#*********************************************************#

# ---------- funciones ----------#

# Muestra la ayuda del script segun $1
function showHelp() {
    if [[ "$1" != "-h" ]]; then
        return;
    fi

    echo "************ AYUDA DE BINGO **************";
    echo "-----------------------------------------------";
    echo "Descripcion:";
    echo "-----------------------------------------------";
    echo "Este script permite simular el sorteo de bolillas";
    echo "de forma automatica. El proceso probador finalizará";
    echo "al finalizar el proceso especificado con <pid>.";
    echo "Puede finalizarse con Ctrl+C";
    showUsage;
    echo;
    exit 0;
}

function showUsage() {
    echo;
    echo "-----------------------------------------------";
    echo "USO:";
    echo "-----------------------------------------------";
    echo "Ejecutar el script:";
    echo "$USER$ $0 <pid>";
    echo ;
    echo "Parametros";
    echo "<pid>: PID del proceso ejercicio3 (BINGO).";
    echo;
    echo "NOTA: El script probador enviará señales SIGUSR1";
    echo "al proceso cuyo identificador sea <pid> cada 1 seg";
    echo ;
    echo "Ver ayuda del script:";
    echo "$USER$ $0 -h";
    echo;
}

showHelp "$1";

for i in {1..100}; do
    kill -s SIGUSR1 $1 2>/dev/null
    # si ya murio, corto
    if [ $? -ne 0 ]; then
        exit 0;
    fi
    sleep 1;
done
