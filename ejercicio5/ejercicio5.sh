#!/bin/bash

#*********************************************************#
# Script      :	ejercicio3.sh
# TP          :	1
# N° Ejercicio:	5
# Nº Entrega  :	1
# Integrantes :
# - XXXXX XXXX              DNI: ########
# - XXXXX XXXX              DNI: ########
# - Medrano, Jonatan XXXX   DNI: ########
# - Moreno, Emiliano        DNI: 33905487
# - Sendras, Bruno          DNI: 32090370
#*********************************************************#

# ---------- funciones ----------#

function exitSuccess() {
    exit 0;
}

# Termina el script con un mensaje y codigo de error.
function exitError() {
    echo;
    echo -e "ERROR: $1";
    echo "Ejecutar con la opcion -h para ver ayuda";
    echo;
    exit 1;
}

function IFSToLineBreakBegin() {
    oldIFS=$IFS;
    IFS=$'\r\n';
    set -f;
}

function IFSToLineBreakEnd() {
    set +f;
    IFS=$oldIFS;
}

# muestra la ayuda y finaliza el script
function showHelp() {
    operationMode=$(getOperationMode "$1");
    if [[ "$operationMode" = "HLP" ]]; then
        echo;
        echo "AYUDA:";
        echo "En construccion.";
        echo;
        exitSuccess;
    fi
}

function showFinishMessage() {
    echo;
    echo "Backup realzado con éxito!"
    echo -e "Archivo:\t$1";
    echo -e "Logs:\t\t$2";
    echo;
}
# imprime el modo de operación del script
function getOperationMode() {
    regex1='^-[tT]$';
    regex2='^-[xX]$';
    regex3='^-[hH]$';

    if [[ "$1" =~ $regex1 ]]; then
        echo "ALL"
    elif [[ "$1" =~ $regex2 ]]; then
        echo "EXT"
    elif [[ "$1" =~ $regex3 ]]; then
        echo "HLP"
    fi
}

# valida la cantidad de parametros en $1 contra el valor requerid en $2
function validateCount {
    if [ "$1" -lt $2 ]; then
        exitError "Parametros insuficientes.";
    fi

    if [ "$1" -gt $2 ]; then
        exitError "Demasiados parametros.";
    fi
}

# valida las opciones
function validateOptions() {
    regex='^-[tTxXhH]$';
    if ! [[ "$1" =~ $regex ]]; then
        exitError "Parametro invalido. Las <opciones> pueden ser solo -[xXtThH] y son mutuamente excluyentes";
    fi
}

# valida la extension
validateExtension() {
    regex='^\.[a-zA-Z0-9]+$';
    if ! [[ "$1" =~ $regex ]]; then
        exitError "Parametro invalido. La <extension> especificada debe coincidir con el patron ^\.[a-zA-Z0-9]+$";
    fi
}

# valida la ruta de entrada
function validatePath() {
    if [ -z "$1" ] ; then
        exitError "Parametro invalido. El <path> especificado no puede ser vacio";
    fi

    if [ ! -e "$1" ]; then
        exitError "Parametro invalido. El <path> especificado no existe";
    fi

    if [ ! -r "$1" ]; then
        exitError "Parametro invalido. El <path> especificado no posee permisos de lectura";
    fi
}

# valida los parametros. Finaliza el script si hay error.
function validateParameters() {

    # Valido las opciones
    validateOptions "$1";

    # modo de operación
    operationMode=$(getOperationMode "$1");

    # parametros recibidos <opciones>=X <extension> <path>
    if [[ $operationMode = 'EXT' ]]; then
        validateCount "$4" 3;
        validateExtension "$2";
        validatePath "$3";
    # parametros recibidos <opciones>=t <path>
    elif [[ $operationMode = 'ALL' ]]; then
        validateCount "$4" 2;
        validatePath "$2";
    # parametros recibidos <opciones>=h
    elif [[ $operationMode = 'HLP' ]]; then
        validateCount "$4" 1;
    fi
}

# imprime el nombre del archivo
function getFileName() {
    ext="$1";
    # variable2=${variable1//substring/replacement}
    ext=${ext//\./""};

    if [ -z "$ext" ]; then
        echo "$(date -j "+%Y-%m-%d-%H:%M:%S")-ALL";
    else
        echo "$(date -j "+%Y-%m-%d-%H:%M:%S")-ONLY-[$ext]";
    fi
}

# comprime los archivos de la ruta especificada en $1
function compressAll() {
    fileName=$(getFileName);
    outputZipFileName="$fileName.zip";
    outputLogFile="$fileName.log";

    # -r: recursivo
    zip -r "$outputZipFileName" "$1" 1>/dev/null 2>&1;
    if [ $? -gt 0 ]; then
        exitError "Hubo un error generando el archivo $outputZipFileName";
    fi

    # si no hubo error logueo
    renderOutput "$1" "" "$outputZipFileName" > "$outputLogFile";

    # terminó todo bien!
    showFinishMessage "$outputZipFileName" "$outputLogFile";
}

# comprime solo archivos de la ruta especificada en $1
# que coincidan con la extencion especificada en $2
function compressByExt() {
    fileName=$(getFileName "$2");
    outputZipFileName="$fileName.zip";
    outputLogFile="$fileName.log";

    # -r: recursivo
    zip -r "$outputZipFileName" "$1" -i "*$2" 1>/dev/null 2>&1;
    if [ $? -gt 0 ]; then
        exitError "Hubo un error generando el archivo $outputZipFileName";
    fi

    # si no hubo error logueo
    renderOutput "$1" "$2" "$outputZipFileName" > "$outputLogFile";

    # terminó todo bien!
    showFinishMessage "$outputZipFileName" "$outputLogFile";
}

# Loguea los resultados a un archivo
function renderOutput() {
    # $1: <path> de entrada
    # $2: <extensión>
    # $3: Nombre del archivo de salida

    IFSToLineBreakBegin;

    echo "Nombre de archivo de backup:";
    echo "----------------------------";
    echo "$3";
    echo
    echo "Contenido:";
    echo "----------------------------";

    # terminan con punto . seguido de cualquier cosa.
    regex="([.].*)$";

    # variables para ciclar la salida de zip
    # -rsf: Muestra los archivos afectados y termina
    result=$(zip -rsf "DUMMY" "$1" -i "*$2");
    lines=(${result[@]});
    count=0;

    # filtramos las lineas que corresponden a paths de archivos
    for line in ${lines[@]}; do
        if [[ $line =~ $regex ]]; then
            echo $line;
            count=$(( $count+1 ));
        fi
    done

    # Escribimos las stats.
    echo;
    echo "Información:"
    echo "----------------------------";
    echo "Archivos resguardados: $count";
    echo "Generado por el usuario: $USER";
    echo "Fecha y hora de creación: ${3:0:10} ${3:11:8}";

    IFSToLineBreakEnd;
}

function makeBackup() {
    operationMode=$(getOperationMode "$1")
    if [[ "$operationMode" = "EXT" ]]; then
        compressByExt "$3" "$2";
    elif [[ "$operationMode" = "ALL" ]]; then
        compressAll "$2";
    fi
}

function deleteOldBackups() {
    IFSToLineBreakBegin;

    # Borrado por tipo de backup
    operationMode=$(getOperationMode "$1");
    if [[ "$operationMode" = "EXT" ]]; then
        regex=".*[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}-ONLY-.*\.zip$";
    elif [[ "$operationMode" = "ALL" ]]; then
        regex=".*[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}-ALL\.zip$";
    fi
    result=$(find . -regex $regex | sort -r);

    archives=(${result[@]});
    for i in ${!archives[@]}; do
        if [ $i -ge 5 ]; then
            echo;
            echo "Borrando backups antiguos...";
            rm -f ${archives[$i]};
            rm -f ${archives[$i]//".zip"/".log"};

            if [ $? -eq 0 ]; then
                echo "${archives[$i]} [Borrado]";
                echo "${archives[$i]//".zip"/".log"}";
            else
                echo -e "No se pudo borrar el archivo\n${archives[$i]}";
            fi
            echo;
        fi
    done

    IFSToLineBreakEnd;
}

# ---------- Inicio del script ---------- #
validateParameters "$1" "$2" "$3" "$#";
showHelp "$1";
makeBackup "$1" "$2" "$3";
deleteOldBackups $1;

