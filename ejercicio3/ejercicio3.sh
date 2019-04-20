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

# ---------- Variables globales ----------#

# control de finalizacion
terminated=0;

# bolillero
declare -a lotterySpinner;
declare -a playedBalls;
declare -a cards;

# cartones
cards=();
cardResults=();
cardNumbers=();

# ganadores
lineWinner="";
lineNumbers="";

# Maxima cantidad de bolillas
maxBalls=100;

# ---------- Manejo de señales ----------#
trap handleSigUsr1 SIGUSR1;
trap handleSigUsr2 SIGUSR2;
trap handleSigInt SIGINT;

handleSigUsr1() {
    play;
}

handleSigUsr2() {
    quit;
}

handleSigInt() {
    showInstructions;
}

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
    echo "Este script simula una partida de bingo."
    showUsage
    showInstructions;
    echo;
    exit 0;
}

# Termina el script con un mensaje y codigo de error.
function exitError() {
    echo -e "$1";
    exit 1;
}

# Obtiene un numero aleatoreo entre $1 y $2;
function getRandomNumber() {
    echo $(( $1 + $RANDOM % ($2 + 1) ));
}

function showUsage() {
    echo;
    echo "-----------------------------------------------";
    echo "USO:";
    echo "-----------------------------------------------";
    echo "Ejecutar el script:";
    echo "$USER$ ./ejercicio3.sh <path> <count>";
    echo ;
    echo "Parametros";
    echo "<path>: ruta del archivo que contiene la";
    echo "descripcion de los cartones participantes";
    echo;
    echo "<count>: cantidad maxima de bolillas usadas para";
    echo "el juego (de 1 a <count>). 100 si se omite";
    echo;
    echo "NOTA: Los cartones deben estar formados numeros";
    echo "dentro del rango definido por <count>";
    echo;
    echo "NOTA: El carton describirse como una linea de";
    echo "texto con el siguiente formato:";
    echo "<nro carton>\t<nro bolilla 1>\t...\t<nro bolilla 15>";
    echo ;
    echo "Ver ayuda del script:";
    echo "$USER$ ./ejercicio3.sh -h";
    echo;
    echo "Para sacar una bolilla, ejecute desde otra terminal:";
    echo "$USER$ kill -s SIGUSR1 <pid>";
    echo;
    echo "Para finalizar el juego, ejecute desde otra terminal:";
    echo "$USER$ kill -s SIGUSR2 <pid>";
    echo;
}

function showInstructions() {
    echo;
    echo "-----------------------------------------------";
    echo "INSTRUCCIONES:";
    echo "-----------------------------------------------";
    echo "Para sacar una bolilla: kill -s SIGUSR1 $$";
    echo "Para finalizar el juego: kill -s SIGUSR2 $$";
    echo "El script finalizara automaticamente al encontrar";
    echo "al ganador del juego (Primer carton con BINGO)";
    echo "-----------------------------------------------";
}

function showInitialMessage() {
    echo;
    echo "************ BIENVENIDO AL BINGO **************";
    showInstructions;
    echo;
}

# Muestro los cartones en juego
function showPlayingCards() {
    echo;
    echo "-----------------------------------------------";
    echo "CARTONES EN JUEGO";
    echo "-----------------------------------------------";
    echo -e "Carton\tNumeros";
    echo -e "------\t-------"
    for i in ${!cards[@]}; do
        card=$(echo ${cards[$i]} | sed 's/\t/ /g');
        echo -e "${cardNumbers[$i]}\t$card";
    done
    echo;
}

# Carga el contenido del archivo en los arrays
function loadCards() {
    # procedo a cargar los cartones
    oldIFS=$IFS;
    IFS=$'\r\n';
    set -f;

    i=0;
    for line in $(cat "$1"); do
        isValidCardFormat $line;
        if [ $? -eq 1 ]; then
            echo "Formato de carton invalido en la linea $i";
            echo "Dicho carton no se considerará en el juego";
            continue;
        fi

        # validateCardBalls $line;
        # if [ $? -eq 1 ]; then
        #     echo "Las bolillas del carton en la linea $i no estan en el rango de 0 a $maxBalls";
        #     echo "Dicho carton no se considerará en el juego";
        #     continue;
        # fi

        cardNumbers[$i]=$(echo $line | cut -f 1);
        cards[$i]=$(echo $line | cut -f 2-16);
        cardResults[$i]=${cards[$i]};
        i=$(( $i + 1 ));
    done;

    set +f;
    IFS=$oldIFS;

    # Chequeo si pude leer alguno
    validateCardsCount;
}

# Valida aspectos del archivo a leer
function validateFile {
    # existe y es un archivo?
    if [ ! -f "$1" ]; then
        exitError "$1\nEs un directorio o el archivo no existe.";
    fi

    # tiene permisos de lectura?
    if [ ! -r  "$1" ]; then
        exitError "No tiene permisos de lectura para el  archvo:\n$1";
    fi

    # tiene contenido?
    if [ ! -s "$1" ]; then
        exitError "$1\nEs un archivo vacio";
    fi
}

# valida la cantidad de bolillas a utilizar
function validateAndSetCount() {
    if [ -z "$1" ]; then
        maxBalls=100;
    elif [[ ! "$1" =~ ^[0-9]{1,3}$ ]]; then
        exitError "La cantidad maxima de bolillas debe ser un numero de 1 a 100";
    elif [ "$1" -ge 1 ] && [ "$1" -le 100 ];  then
        maxBalls=$1;
    else
        exitError "La cantidad maxima de bolillas debe ser un numero de 1 a 100";
    fi
}

# valida el formato de una linea leida
function isValidCardFormat() {
    regexp="^[0-9]{4}([[:blank:]][0-9]{1,2}){15}";
    if [[ "$1" =~ $regexp ]]; then
        return 0;
    fi
    return 1;
}

# valida el formato de una linea leida
function validateCardBalls() {
    oldIFS=$IFS;
    IFS=$'\t';
    set -f;

    lineArray=($1);

    set +f;
    IFS=$oldIFS;

    for k in ${!lineArray[@]}; do
        if [ $k -gt 0 ]; then
            if [ ${lineArray[$k]} -lt 0 ] ||  [ ${lineArray[$k]} -ge $maxBalls ]; then
                return 1;
            fi
        fi
    done;

    return 0;
}

# valida la cantidad de cartones leidos
function validateCardsCount() {
    if [ ${#cards[@]} -eq 0 ]; then
        exitError "No se leyó ningun carton para procesar";
    fi
}

function generateLotterySpinner() {
    for((i=0; i < $maxBalls; i++ )); do
    # for i in {0..99}; do
        lotterySpinner[$i]=$i;
    done;
}

# Inicializa el juego
function startGame() {
    # Valido el archivo
    validateFile "$1";

    # Valido el maximo de bolillas
    validateAndSetCount "$2"

    # Muestro el inicio
    showInitialMessage;

    # Genero el bolillero
    generateLotterySpinner;

    # Leo los cartones
    loadCards "$1";
    # los muestro
    showPlayingCards;
}

# Finaliza el juego
function quit() {
    terminated=1;
}

# Saca una bolilla y controla los resultados.
function play() {
    # Cuento las bolillas que saqué
    count=${#playedBalls[*]}

    # Quedan bolillas en el bolillero?
    if [ $count -ge 100 ]; then
        echo -1;
        return 0;
    fi

    topLimit=$(( $maxBalls - 1 ));

    # Si, saco una.
    ball=$(getRandomNumber 0 $topLimit);
    while [ ${lotterySpinner[$ball]} -eq -1 ]; do
        # es repetida, vuelvo a intentar.
        ball=$(getRandomNumber 0 $topLimit);
    done;

    # la quito del bolillero
    lotterySpinner[$ball]=-1;

    # la separo en orden de aparicion
    playedBalls[$count]=$ball;

    # verifico los cartones
    checkAllCards;

    # informo la bolilla jugadas
    echo "Nueva bolilla: $ball";

    # Informo los resultados actuales
    checkAllCards $ball;
}

# Itera los cartones y verifica la bolilla
function checkAllCards() {
    for i in ${!cardResults[@]}; do
        # convierto a un array con card=(...)
        card=(${cardResults[$i]});

        for j in ${!card[@]}; do
            if [[ ${card[$j]} == $1 ]]; then
                # marco el casillero
                card[$j]=X;
                # actualizo el resultado
                cardResults[$i]=${card[@]};

                # verifico el resultado actual
                checkCard "${card[*]}" ${cardNumbers[$i]};
            fi
        done
    done
}

# Verifica la bolilla en un carton dado
function checkCard() {
    # $1: numeros
    # $2: numero de carton
    # linea: 1-5 || 6 - 10 || 6-15 == 'X X X X X X'
    # bingo: 1-15 == 'X X X X X X X X X X X X X X'
    bingo="$1";
    line1=$(echo $1 | cut -f 1-5 -d " ");
    line2=$(echo $1 | cut -f 6-10 -d " ");
    line3=$(echo $1 | cut -f 11-15 -d " ");

    regexp='^([X][[:blank:]]){14}[X]$';
    if [[ $bingo =~  $regexp ]]; then
        echo;
        echo "-----------------------------------------------";
        echo "CARTON: $2 => BINGO!";
        echo "-----------------------------------------------";
        showCardStatus $2 "$line1" "$line2" "$line3" 0;
        bingoWinner=$2;
        showSummary;
        exit 1;
    fi

    regexp='^([X][[:blank:]]){4}[X]$';
    if [[ $lineWinner = "" && $line1 =~  $regexp ]]; then
        echo;
        echo "-----------------------------------------------";
        echo "CARTON: $2 => LINEA (1)!";
        echo "-----------------------------------------------";
        showCardStatus $2 "$line1" "$line2" "$line3" 1
        echo "Se continua a bingo...";
        echo;
        lineWinner=$2;
    elif [[ $lineWinner = "" && $line2 =~  $regexp ]]; then
        echo;
        echo "-----------------------------------------------";
        echo "CARTON: $2 => LINEA (2)!";
        echo "-----------------------------------------------";
        showCardStatus $2 "$line1" "$line2" "$line3" 2
        echo "Se continua a bingo...";
        echo;
        lineWinner=$2;
    elif [[ $lineWinner = "" && $line3 =~  $regexp ]]; then
        echo;
        echo "-----------------------------------------------";
        echo "CARTON: $2 => LINEA (3)!";
        echo "-----------------------------------------------";
        showCardStatus $2 "$line1" "$line2" "$line3" 3
        echo "Se continua a bingo...";
        echo;
        lineWinner=$2;
    else
        showCardStatus $2 "$line1" "$line2" "$line3" 0
    fi
}

function showCardStatus() {
    echo;
    echo "--------------";
    echo Carton: $1;
    echo "--------------";
    if [ "$5" -eq 1 ]; then
        echo -e "$2 \t<---";
    else
        echo "$2";
    fi;

    if [ "$5" -eq 2 ]; then
        echo -e "$3 \t<---";
    else
        echo "$3";
    fi;

    if [ "$5" -eq 3 ]; then
        echo -e "$4 \t<---";
    else
        echo "$4";
    fi;

    echo "--------------";
    echo;
}

# Muestra las bolillas sorteadas y el carton ganador
function showSummary() {
    echo;
    echo "-----------------------------------------------";
    echo "RESUMEN DE LA PRTIDA"
    echo "-----------------------------------------------";
    echo "Cantidad de Bolillas Sorteadas: ${#playedBalls[@]}";
    echo "Secuencia: ${playedBalls[*]}";
    echo;
    echo "-----------------------------------------------";
    echo "CARTON GANADOR: $lineWinner => LINEA!";
    echo "-----------------------------------------------";
    echo;
    echo "-----------------------------------------------";
    echo "CARTON GANADOR: $bingoWinner => BINGO!";
    echo "-----------------------------------------------";
    echo;
    echo "GAME OVER!!"
    echo;
}

# ---------- Inicio del script ----------
showHelp "$1";
startGame "$1" "$2";

while [ $terminated -eq 0 ]; do
    sleep 1;
done;
