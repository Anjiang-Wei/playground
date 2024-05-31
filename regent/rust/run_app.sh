mpirun /scratch2/anjiang/playground/regent/build/blinks -lg:prof 1 -lg:prof_logfile prof_blinks_%.log -lg:spy -logfile spy_blinks_%.log
# -lg:prof 1 -lg:prof_logfile prof_circuit_%.gz -lg:spy -logfile spy_circuit_%.log
LD_LIBRARY_PATH=/scratch2/anjiang/perfanalysis/legions/language/circuit.run1 mpirun --bind-to none /scratch2/anjiang/perfanalysis/legions/language/circuit.run1/circuit -npp 1000 -wpp 1000 -l 10 -p 40 -pps 10 -prune 30 -ll:gpu 4 -ll:cpu 1 -ll:util 1 -ll:csize 150000 -ll:fsize 15000 -ll:zsize 2048 -lg:prof 1 -lg:prof_logfile prof_circuit_%.gz -lg:spy -logfile spy_circuit_%.log
LD_LIBRARY_PATH=/scratch2/anjiang/perfanalysis/legions/language/stencil.run1 mpirun --bind-to none /scratch2/anjiang/perfanalysis/legions/language/stencil.run1/stencil -nx 30000 -ny 30000 -ntx 2 -nty 2 -tsteps 5 -tprune 30 -ll:gpu 4 -ll:util 1 -ll:csize 150000 -ll:fsize 15000 -ll:zsize 2048 -lg:prof 1 -lg:prof_logfile prof_stencil_%.gz -lg:spy -logfile spy_stencil_%.log
LD_LIBRARY_PATH=/scratch2/anjiang/perfanalysis/legions/language/pennant.run1 mpirun --bind-to none /scratch2/anjiang/perfanalysis/legions/language/pennant.run1/pennant /scratch2/anjiang/perfanalysis/legions/language/pennant.run1/pennant.tests/sedovbig4x30/sedovbig.pnt -npieces 4 -numpcx 1 -numpcy 4 -seq_init 0 -par_init 1 -prune 30 -ll:gpu 4 -ll:util 2 -ll:csize 150000 -ll:fsize 15000 -ll:zsize 2048 -dm:replicate 1 -dm:same_address_space -dm:memoize -lg:no_fence_elision -lg:parallel_replay 2 -lg:prof 1 -lg:prof_logfile prof_pennant_%.gz -lg:spy -logfile spy_pennant_%.log


# circuit2: 1 num_superpieces
mkdir circuit2 && cd circuit2
LD_LIBRARY_PATH=/scratch2/anjiang/perfanalysis/legions/language/circuit.run1 mpirun --bind-to none /scratch2/anjiang/perfanalysis/legions/language/circuit.run1/circuit -npp 1000 -wpp 1000 -l 10 -p 40 -pps 40 -prune 30 -ll:gpu 4 -ll:cpu 1 -ll:util 1 -ll:csize 150000 -ll:fsize 15000 -ll:zsize 2048 -lg:prof 1 -lg:prof_logfile prof_circuit2_%.gz -lg:spy -logfile spy_circuit2_%.log

# circuit3: 2 num_superpieces
mkdir circuit3 && cd circuit3
LD_LIBRARY_PATH=/scratch2/anjiang/perfanalysis/legions/language/circuit.run1 mpirun --bind-to none /scratch2/anjiang/perfanalysis/legions/language/circuit.run1/circuit -npp 1000 -wpp 1000 -l 10 -p 40 -pps 20 -prune 30 -ll:gpu 4 -ll:cpu 1 -ll:util 1 -ll:csize 150000 -ll:fsize 15000 -ll:zsize 2048 -lg:prof 1 -lg:prof_logfile prof_circuit3_%.gz -lg:spy -logfile spy_circuit3_%.log

# circuit4: configurable index launch -sp1 4 -sp2 1 -sp3 1
LD_LIBRARY_PATH=/scratch2/anjiang/perfanalysis/legions/language/circuit.run2 mpirun --bind-to none /scratch2/anjiang/perfanalysis/legions/language/circuit.run2/circuit -npp 1000 -wpp 1000 -l 10 -p 40 -sp1 4 -sp2 1 -sp3 1 -prune 30 -ll:gpu 4 -ll:cpu 1 -ll:util 1 -ll:csize 150000 -ll:fsize 15000 -ll:zsize 2048 -lg:prof 1 -lg:prof_logfile prof_circuit4_%.gz -lg:spy -logfile spy_circuit4_%.log

# circuit5: -sp1 1 -sp2 1 -sp3 1
LD_LIBRARY_PATH=/scratch2/anjiang/perfanalysis/legions/language/circuit.run2 mpirun --bind-to none /scratch2/anjiang/perfanalysis/legions/language/circuit.run2/circuit -npp 1000 -wpp 1000 -l 10 -p 40 -sp1 1 -sp2 1 -sp3 1 -prune 30 -ll:gpu 4 -ll:cpu 1 -ll:util 1 -ll:csize 150000 -ll:fsize 15000 -ll:zsize 2048 -lg:prof 1 -lg:prof_logfile prof_circuit5_%.gz -lg:spy -logfile spy_circuit5_%.log

# circuit6: -sp1 2 -sp2 1 -sp3 1
LD_LIBRARY_PATH=/scratch2/anjiang/perfanalysis/legions/language/circuit.run2 mpirun --bind-to none /scratch2/anjiang/perfanalysis/legions/language/circuit.run2/circuit -npp 1000 -wpp 1000 -l 10 -p 40 -sp1 2 -sp2 1 -sp3 1 -prune 30 -ll:gpu 4 -ll:cpu 1 -ll:util 1 -ll:csize 150000 -ll:fsize 15000 -ll:zsize 2048 -lg:prof 1 -lg:prof_logfile prof_circuit6_%.gz -lg:spy -logfile spy_circuit6_%.log

# circuit7: -sp1 2 -sp2 2 -sp3 2
LD_LIBRARY_PATH=/scratch2/anjiang/perfanalysis/legions/language/circuit.run2 mpirun --bind-to none /scratch2/anjiang/perfanalysis/legions/language/circuit.run2/circuit -npp 1000 -wpp 1000 -l 10 -p 40 -sp1 2 -sp2 2 -sp3 2 -prune 30 -ll:gpu 4 -ll:cpu 1 -ll:util 1 -ll:csize 150000 -ll:fsize 15000 -ll:zsize 2048 -lg:prof 1 -lg:prof_logfile prof_circuit7_%.gz -lg:spy -logfile spy_circuit7_%.log

# circuit8: -sp1 4 -sp2 4 -sp3 4
LD_LIBRARY_PATH=/scratch2/anjiang/perfanalysis/legions/language/circuit.run2 mpirun --bind-to none /scratch2/anjiang/perfanalysis/legions/language/circuit.run2/circuit -npp 1000 -wpp 1000 -l 10 -p 40 -sp1 4 -sp2 4 -sp3 4 -prune 30 -ll:gpu 4 -ll:cpu 1 -ll:util 1 -ll:csize 150000 -ll:fsize 15000 -ll:zsize 2048 -lg:prof 1 -lg:prof_logfile prof_circuit8_%.gz -lg:spy -logfile spy_circuit8_%.log