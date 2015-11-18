import Image
import os
import sys

TESTSET = "rectangularW"
TESTIMG = "testcardc"

directory = "./testimgs/" + TESTSET
if not os.path.exists(directory):
    os.makedirs(directory)
# open an image file (.bmp,.jpg,.png,.gif) you have in the working folder
imageFile = "./testimgs/" + TESTIMG + ".bmp"
#imageFilem = "./testimgs/" + TESTIMG + "m.bmp"
im1 = Image.open(imageFile)
#im2 = Image.open(imageFilem)

# adjust width and height to your needs
for size in xrange(16, 425, 8):
    # use one of these filter options to resize the image
    im3 = im1.resize((size*8, size), Image.NEAREST)      # use nearest neighbour
    #im4 = im2.resize((size, size), Image.NEAREST)      # use nearest neighbour
    strsize = str(size)
    if len(strsize) == 2:
        strsize = "00" + strsize
    if len(strsize) == 3:
        strsize = "0" + strsize
    if len(strsize) == 1:
        strsize = "000" + strsize
    im3.save(directory + "/test-" + strsize + ".bmp")
    #im4.save(directory + "/testm" + strsize + ".bmp")

TESTSET = "rectangularH"
TESTIMG = "testcardc"

directory = "./testimgs/" + TESTSET
if not os.path.exists(directory):
    os.makedirs(directory)
# open an image file (.bmp,.jpg,.png,.gif) you have in the working folder
imageFile = "./testimgs/" + TESTIMG + ".bmp"
#imageFilem = "./testimgs/" + TESTIMG + "m.bmp"
im1 = Image.open(imageFile)
#im2 = Image.open(imageFilem)

# adjust width and height to your needs
for size in xrange(16, 425, 8):
    # use one of these filter options to resize the image
    im3 = im1.resize((size, size*8), Image.NEAREST)      # use nearest neighbour
    #im4 = im2.resize((size, size), Image.NEAREST)      # use nearest neighbour
    strsize = str(size)
    if len(strsize) == 2:
        strsize = "00" + strsize
    if len(strsize) == 3:
        strsize = "0" + strsize
    if len(strsize) == 1:
        strsize = "000" + strsize
    im3.save(directory + "/test-" + strsize + ".bmp")
    #im4.save(directory + "/testm" + strsize + ".bmp")