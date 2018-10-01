del gelb.bin gelb.o
rgbasm -o gelb.o gelb.asm
python -m rgbbin gelb.o
ren WRAM.bin gelb.bin

del yellow.bin yellow.o
rgbasm -o yellow.o yellow.asm
python -m rgbbin yellow.o
ren WRAM.bin yellow.bin

pause