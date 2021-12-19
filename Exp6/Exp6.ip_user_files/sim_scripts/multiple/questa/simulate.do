onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib multiple_opt

do {wave.do}

view wave
view structure
view signals

do {multiple.udo}

run -all

quit -force
