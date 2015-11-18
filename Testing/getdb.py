import sys
import re
import os
from os.path import basename
from numpy import mean
import shutil
import commands
import subprocess

PRECISION = 100
IMPLEMENTACIONES = [["c", "O0"], ["c", "O3"],["asm1", "O3"], ["asm2", "O3"]]
outpdir = os.path.expanduser('~') + "/outputdata/"
#outpdir = "./outputdata/"


def main():
  if not os.path.exists(outpdir):
    os.makedirs(outpdir)
  # processblur("normal")
  # processblur("black")
  # processblur("white")

  # processmerge("white", "0.5")
  # processmerge("black", "0.5")

  # for x in xrange(0, 11, 1):
  #   processmerge("normal", str(x/10.0))

  #HSL Cambiando H
  # processhsl("black", "0", "1", "0.1")
  # processhsl("white", "0", "1", "0.1")
  # processhsl("black", "360", "1", "0.1")
  # processhsl("white", "360", "1", "0.1")
  # for x in xrange(0, 361, 60):
  #   processhsl("normal", str(x), "1", "0.1")
  processblur("rectangularW")
  processblur("rectangularH")



def trimmean(arr, percent):
    n = len(arr)
    k = int(round(n*(float(percent)/100)/2))
    return mean(arr[k+1:n-k])

def processblur(folder):
    ou = open(outpdir + "blur-"+ folder + ".csv", "w")
    listfile = getfiles("./testimgs/"+ folder + "/")
    total = len(listfile)*len(IMPLEMENTACIONES) 
    done = 0
    #Para cada implementacion
    for impl in IMPLEMENTACIONES:
      #Para cada imagen de prueba
      for filen in listfile:
        done = done + 1
        size = int(filen[5:9])
        time = []
        #Corro p veces y me quedo con el minimo tiempo de ejecucion
        for x in range(0,PRECISION+1):
          ticks = int(subprocess.check_output(["./runtest"+impl[1], impl[0], "blur", "./testimgs/"+ folder + "/"+filen, "n", str(0)]))
          if (ticks != 0):
              time.append(ticks)
        ou.write(impl[0] + impl[1] + ', ' + str(size) + ', ' + str(int(trimmean(sorted(time), 0.25))) + "\n")
        os.system("clear")
        print("Blur[" + impl[0] + impl[1] + "]: TESTSET=" + folder + " IMG=" + filen + " image:" +  str(done) + "of" + str(total) + "  | Process " + str(float(done*100)/float(total)) + "%")
    ou.close()

def processmerge(folder, val):
    ou = open(outpdir + "merge-"+ folder + "-" + val.replace('.', '_') + ".csv", "w")
    listfile = getfiles("./testimgs/"+ folder + "/")
    total = len(listfile)*len(IMPLEMENTACIONES) 
    done = 0
    #Para cada implementacion
    for impl in IMPLEMENTACIONES:
      #Para cada imagen de prueba
      for filen in listfile:
        done = done + 1
        filen2 = filen[0:4] + "m" + filen[5:14]
        size = int(filen[5:9])
        time = []
        #Corro p veces y me quedo con el minimo tiempo de ejecucion
        for x in range(0,PRECISION+1):
          #print(["./runtest"+impl[1], impl[0], "blur", "./testimgs/"+ folder + "/"+filen, "n", str(0)])
          ticks = int(subprocess.check_output(["./runtest"+impl[1], impl[0], "merge", "./testimgs/"+ folder + "/"+filen, "./testimgs/"+ folder + "/"+filen2, "n", val, str(0)]))
          if (ticks != 0):
            time.append(ticks)
        ou.write(impl[0] + impl[1] + ', ' + str(size) + ', ' + str(int(trimmean(sorted(time), 0.25))) + "\n")
        os.system("clear")
        print("Merge[" + impl[0] + impl[1] + "]Val=" + val + ": TESTSET=" + folder + " IMG=" + filen + " image:" +  str(done) + "of" + str(total) + "  | Process " + str(float(done*100)/float(total)) + "%")
    ou.close()

def processhsl(folder, h, s, l):
    ou = open(outpdir + "hsl-"+ folder + "-" + h.replace('.', '_') + "-" + s.replace('.', '_') + "-" + l.replace('.', '_') + ".csv", "w")
    listfile = getfiles("./testimgs/"+ folder + "/")
    total = len(listfile)*len(IMPLEMENTACIONES)
    done = 0
    #Para cada implementacion
    for impl in IMPLEMENTACIONES:
      #Para cada imagen de prueba
      for filen in listfile:
        done = done + 1
        size = int(filen[5:9])
        time = []
        #Corro p veces y me quedo con el minimo tiempo de ejecucion
        for x in range(0,PRECISION+1):
          ticks = int(subprocess.check_output(["./runtest"+impl[1], impl[0], "hsl", "./testimgs/"+ folder + "/"+filen, "n", h, s, l, str(0)]))
          if (ticks != 0):
              time.append(ticks)
        ou.write(impl[0] + impl[1] + ', ' + str(size) + ', ' + str(int(trimmean(sorted(time), 0.25))) + "\n")
        os.system("clear")
        print("Hsl[" + impl[0] + impl[1] + "]H=" + h + "S=" + s + "L=" + l + ": TESTSET=" + folder + " IMG=" + filen + " image:" +  str(done) + "of" + str(total) + "  | Process " + str(float(done*100)/float(total)) + "%")
    ou.close()

def getfiles(dir):
  res = []
  for filen in os.listdir(dir):
    match = re.search(r'test-\w+\.bmp', filen)
    if match:
      res.append(filen)

  return sorted(res)  

if __name__ == '__main__':
  main()