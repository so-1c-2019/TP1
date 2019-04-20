#!/bin/bash

cards=();
cardResults=();
cardNumbers=();

# Carga el contenido del archivo en los arrays
function loadCards() {
    path="$1";

    oldIFS=$IFS;
    IFS=$'\r\n';
    set -f;

    i=0;
    for line in $(cat $path); do
        isValidCardFormat $line;
        if [ $? -eq 1 ]; then
            echo "Formato de carton invalido en la linea $i";
            echo "Dicho carton no se considerará en el juego";
            continue;
        fi
        cardNumbers[$i]=$(echo $line | cut -f 1);
        cards[$i]=$(echo $line | cut -f 2-16);
        cardResults[$i]=${cards[$i]};
        i=$(( $i + 1 ));
    done;

    set +f;
    IFS=$oldIFS;
}

function exitError() {
    echo -e "$1";
    exit 1;
}

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

# ^[0-9]{4}(\t[0-9]{1,2}){15}([\n]{0,1})$
function isValidCardFormat() {
    regexp="^[0-9]{4}([[:blank:]][0-9]{1,2}){15}";
    if [[ "$1" =~ $regexp ]]; then
        return 0;
    fi

    return 1;
}

function validateCards() {
    if [ ${#cards[@]} -eq 0 ]; then
        exitError "No se leyó ningun carton para procesar";
    fi
}

function checkAllCards() {
    for i in ${!cardResults[@]}; do
        # convierto a un array con card=(...)
        card=(${cardResults[$i]});

        for j in ${!card[@]}; do
            if [ ${card[$j]} = $1 ]; then
                # marco el casillero
                card[$j]=X;
                # actualizo el resultado
                cardResults[$i]=${card[@]};
            fi
        done

        # verifico el resultado actual
        checkCard "${card[*]}" ${cardNumbers[$i]};
    done
}

lineWin=0;

function checkCard() {
    # $1: numeros
    # $2: numero de carton
    # linea: 1-5 || 6 - 10 || 6-15 == 'XXXXXX'
    # bingo: 1-15 == 'XXXXXXXXXXXXXX'
    bingo="$1";
    line1=$(echo $1 | cut -f 1-5 -d " ");
    line2=$(echo $1 | cut -f 6-10 -d " ");
    line3=$(echo $1 | cut -f 11-15 -d " ");

    regexp='^([X][[:blank:]]){14}[X]$';
    if [[ $bingo =~  $regexp ]]; then
        echo "GANADOR CARTON: $2 => BINGO!";
        echo "GAME OVER!!"
        exit 1;
    fi

    regexp='^([X][[:blank:]]){4}[X]$';
    if [[ $lin -eq 0 && $line1 =~  $regexp ]]; then
        echo "CARTON: $2 => LINEA (1)!";
        echo "Se continua a bingo...";
        lin=1;
    fi

    if [[ $lin -eq 0 && $line2 =~  $regexp ]]; then
        echo "CARTON: $2 => LINEA (2)!";
        echo "Se continua a bingo...";
        lin=1;
    fi

    if [[ $lin -eq 0 && $line3 =~  $regexp ]]; then
        echo "CARTON: $2 => LINEA (3)!";
        echo "Se continua a bingo...";
        lin=1;
    fi

    echo;
    echo "--------------";
    echo $line1;
    echo $line2;
    echo $line3;
    echo "--------------";
    echo;
}

echo "# -------- loadCards ------- #";
loadCards "./cartones.txt";
# validateCards;
# echo ${cards[@]};
# echo ${cardResults[@]};
# echo ${cardNumbers[@]};

# echo "# -------- validateFile ------- #"
# validateFile "./vacio";
# validateFile "./cartones.txt";
# validateFile "./cartwones.txt";
# validateFile "./";

checkAllCards 5;
checkAllCards 9;
checkAllCards 15;
checkAllCards 47;
checkAllCards 98;
checkAllCards 66;
checkAllCards 72;
checkAllCards 61;
checkAllCards 0;
checkAllCards 12;
checkAllCards 3;
checkAllCards 25;
checkAllCards 34;
checkAllCards 57;
checkAllCards 1;

for i in ${!cardResults[@]}; do
    # convierto a un array con card=(...)
    echo ${cardResults[$i]};
done

