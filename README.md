test on Ubuntu 24.04/22.04

## compilers, math libraries

default:

- [x] gcc
- [x] gfortran
- [x] aocc 5.1.0
- [x] intel fortran essentials 2025.3.1.26
  - [x] intel ifx
  - [x] intel mkl
  - [x] intel mpi

optional: see in the end of file `install.sh`

- [x] intel one mkl
- [x] intel cpp essentials
- [x] intel oneapi hpc toolkit
- [x] intel dpcpp compiler
- [x] intel fortran compiler

[Using MKL efficiently on AMD CPU may look here](https://documentation.sigma2.no/jobs/mkl.html#forcing-mkl-to-use-best-performing-routines)

## slurm queue

- [x] only on local machine

change the cpu config in `slurm.conf` as yours

```
NodeName=localhost CPUs=4 Sockets=1 CoresPerSocket=4 ThreadsPerCore=1 State=UNKNOWN
```

here only set to a single socket 4 core cpu

## other tools

- [x] lmod
- [x] parallel
- [x] cmake
- [x] automake
- [x] autoconf

## install

```
sudo bash install.sh
```

## test

check if the queue is up

```
sinfo
```
printing like:

```
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
test*       up   infinite      1   idle localhost
```

submit jobs to the queue

```
cat >1.sb<<EOF
#! /bin/bash
sleep 10s
hostname
EOF

sbatch -c 1 -a 1-4 1.sb
squeue
```

printing like:

```
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
               1_1      test     1.sb     root  R       0:04      1 localhost
               1_2      test     1.sb     root  R       0:04      1 localhost
               1_3      test     1.sb     root  R       0:04      1 localhost
               1_4      test     1.sb     root  R       0:04      1 localhost
```

check intel fortran compiler
```
$(find /opt/intel/ -name "ifx" | head -n 1 ) --version
```
printing like:
```
ifx (IFX) 2025.3.2 20260112
Copyright (C) 1985-2026 Intel Corporation. All rights reserved.
```


## customize

modify install.sh
