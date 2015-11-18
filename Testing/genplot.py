import os
from pylab import *
#TODO Pasar datos a otro directorio asi no se reprocesa
datadir = "./outputdata/"
plotdir = "./plots/"
if not os.path.exists(plotdir+ "all/"):
    os.makedirs(plotdir + "all/")
if not os.path.exists(plotdir + "noCO0/"):
    os.makedirs(plotdir + "noCO0/")
if not os.path.exists(plotdir + "noASM1/"):
    os.makedirs(plotdir + "noASM1/")
if not os.path.exists(plotdir + "noASM2/"):
    os.makedirs(plotdir + "noASM2/")
for filen in os.listdir(datadir):
	cO0time = []
	cO0size = []
	cO3time = []
	cO3size = []
	asm1time = []
	asm1size = []
	asm2time = []
	asm2size = []
	data = open(datadir + filen, "rU")
	for line in data:
		sample = line.split(", ", 2)
		if len(sample) == 3:
			if sample[0] == "cO0":
				cO0size.append(int(sample[1]))
				cO0time.append(int(sample[2][:-2]))
			if sample[0] == "cO3":
				cO3size.append(int(sample[1]))
				cO3time.append(int(sample[2][:-2]))
			if sample[0][:4] == "asm1":
				asm1size.append(int(sample[1]))
				asm1time.append(int(sample[2][:-2]))
			if sample[0][:4] == "asm2":
				asm2size.append(int(sample[1]))
				asm2time.append(int(sample[2][:-2]))
	getdataname = filen.split(".", 1)
	filename = getdataname[0].replace("_", "")
	titlee = getdataname[0].replace("_", ".").replace("-", " ")

	plot(cO3size, cO3time, color='red', lw=2, label='CO3')
	plot(asm1size, asm1time, color='green', lw=2, label='ASM1')
	plot(asm2size, asm2time, color='blue', lw=2, label='ASM2')
	plot(cO0size, cO0time, color='orange', lw=2, label='CO0')
	legend(loc='upper left')
	xlabel('Ancho de imagen (pixels)')
	ylabel('Ciclos')
	title(titlee)
	grid(True)
	savefig(plotdir + "all/" + filename + "--all"+ ".png")
	clf()

	plot(cO3size, cO3time, color='red', lw=2, label='CO3')
	plot(asm1size, asm1time, color='green', lw=2, label='ASM1')
	plot(cO0size, cO0time, color='orange', lw=2, label='CO0')
	legend(loc='upper left')
	xlabel('Ancho de imagen (pixels)')
	ylabel('Ciclos')
	title(getdataname[0])
	grid(True)
	savefig(plotdir + "noASM2/" + filename + "--noASM2"+ ".png")
	clf()

	plot(cO3size, cO3time, color='red', lw=2, label='CO3')
	plot(asm1size, asm1time, color='green', lw=2, label='ASM1')
	plot(asm2size, asm2time, color='blue', lw=2, label='ASM2')
	legend(loc='upper left')
	xlabel('Ancho de imagen (pixels)')
	ylabel('Ciclos')
	title(titlee)
	grid(True)
	savefig(plotdir + "noCO0/" + filename + "--noCO0" + ".png")
	clf()

	plot(cO3size, cO3time, color='red', lw=2, label='CO3')
	plot(asm2size, asm2time, color='blue', lw=2, label='ASM2')
	plot(cO0size, cO0time, color='orange', lw=2, label='CO0')
	legend(loc='upper left')
	xlabel('Ancho de imagen (pixels)')
	ylabel('Ciclos')
	title(titlee)
	grid(True)
	savefig(plotdir + "noASM1/" + filename + "--noASM1" + ".png")
	clf()
