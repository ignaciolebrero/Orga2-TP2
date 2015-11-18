#!/bin/bash

# Este script ejecuta su implementacion y chequea memoria

source param.sh

img0=${IMAGENES[0]}
img0=${img0%%.*}
img1=${IMAGENES[1]}
img1=${img1%%.*}

VALGRINDFLAGS="--leak-check=no --error-exitcode=1 -q"

#$1 : Programa Ejecutable
#$2 : Filtro e Implementacion Ejecutar
#$3 : Archivos de Entrada
#$4 : Archivo de Salida (sin path)
#$5 : Parametros del filtro
function run_test {
    valgrind $VALGRINDFLAGS $1 $2 $3 $ALUMNOSDIR/$4 $5
    if [ $? -ne 0 ]; then
      echo -e "$ROJO NO: $4 $DEFAULT"
      ret=0; return;
    fi
    echo -e "$VERDE OK: $4 $DEFAULT"
    ret=0; return;
}

for imp in c asm1 asm2; do

  # BLUR
  for s in ${SIZESMEM[*]}; do
    run_test "$TP2ALU" "$imp blur" "$TESTINDIR/$img1.$s.bmp" "$imp.$img1.$s.blur.MEM.bmp" ""
    if [ $ret -ne 0 ]; then exit -1; fi
  done

  # MERGE
  for s in ${SIZESMEM[*]}; do
    v=0.555
    run_test "$TP2ALU" "$imp merge" "$TESTINDIR/$img1.$s.bmp $TESTINDIR/$img1.$s.bmp" "$imp.$img1.$s.merge$v.MEM.bmp" "$v"
    if [ $ret -ne 0 ]; then exit -1; fi
  done

  # HSL
  for s in ${SIZESMEM[*]}; do
  hh=111; ss=0.111 ll=0.111;
    run_test "$TP2ALU" "$imp hsl" "$TESTINDIR/$img1.$s.bmp" "$imp.$img1.$s.hsl$hh-$ss-$ll.MEM.bmp" "$hh $ss $ll"
    if [ $ret -ne 0 ]; then exit -1; fi
  done

done

echo ""
# echo -e "$VERDE Felicitaciones los test de MEMORIA finalizaron correctamente $DEFAULT"

