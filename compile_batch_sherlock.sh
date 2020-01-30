#! /bin/bash
#
#SBATCH -n 1
#SBATCH -o netcdf_batch_netcdf.out
#SBATCH -e netcdf_batch_netcdf.err
##
#
#module purge
#
# Stanford Earth Mazama:
#module load intel/19.1.0.166
#module load openmpi3
#
## SRCC Sherlock:
#module load icc/2019
#module load ifort/2019
#module load impi/2019
##module load openmpi/3.1.2
##
## maybe load curl this way? might work, but it is not difficult to compile either.
## module load system curl/7.54.0
##
#export CC=icc
#export FC=ifort
#export CXX=icpc
##
## MPI compilers:
#export MPICC=mpiicc
#export MPIFC=mpiifort
#export MPICXX=mpiicpc

echo 'modules from batch script: '
module list
#
#cd /scratch/myoder96/Downloads/netcdf
cd $SCRATCH/Downloads/netcdf

srun ./netcdf_compile_general.sh
#srun bash netcdf_compile_general.sh

#srun $SCRATCH/Downloads/netcdf/test_script.sh
#srun ./test_script.sh
#
