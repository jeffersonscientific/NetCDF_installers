#! /bin/bash
#
###############################################################################
# compiler script for netcdf-c and netcdf-fortran, with mpi support
#
# for more inormation on compiling netcdf:
# https://www.unidata.ucar.edu/software/netcdf/docs/building_netcdf_fortran.html
#
# The best way (probably) to install NetCDF is to install the OpenHPC software and modules
#  stack. The main challenge with NetCDF is that it is unforgiving and difficult to compile,
#  and it has multiple dependencies that all need to be compiled together, using the same exact
#  compiler -- both compiler make (aka, intel, gcc, etc.), compiler versionm, MPI, etc.
#  OHPC includes working "stacks" of these componetns, so to use NetCDF, one would preface
#  a scritp with:
#  # load "environment" with most recent/default intel compilers and openmpi3
#  module load intel openmpi3
#  # now netcdf:
#  module load netcdf netcdf-fortran
#
#  If OpenHPC is not installed, it will likely ber necessary to compile not only NetCDF but
#  its dependencies as well. This will include:
#  (HDF5, zlib, curl) -> netcdf-c -> netcdf-fortran
#
#  The following script worked on Stanford Earth's Mazama HPC. The variable party of the script includes:
#  - module loads
#  - Setting up sorce and destination paths
#
# after that, this script will (attempt to):
# - download components (except HDF5, which I don't think currently has a simple URL from which to download)
# - unpack components
# - install components
#
##############################################################################
#
# Load software:
#  module configuration will vary for different HPC (and other) systems:
#
# intel compilers:
# compiler, output path, etc. different for each compiler, because the Fortran
#  compiler is very very picky.
#
#
# load modules in parent/batch script:
# Stanford Earth Mazama:
#module load intel/19.1.0.166
#module load openmpi3
#
# TODO this should be commented out and the modules set in the batch script,
#  assuming we can retain the modules.
# SRCC Sherlock:
module purge
module load icc/2019
module load ifort/2019
module load impi/2019
#module load openmpi/3.1.2
##
## maybe load curl this way?:
## module load system curl/7.54.0
#
echo "*****************************"
echo "module list: "
module list
#
# Should we set these in the batch script? Probablym, since we
CC=icc
FC=ifort
CXX=icpc
#
# MPI compilers:
MPICC=mpiicc
MPIFC=mpiifort
MPICXX=mpiicpc
# TODO: probably most of these variable defs belong in the batch script...
#
ROOT_DIR=`pwd`
echo "root dir: ${ROOT_DIR}"
export HDF5_PARAPREFIX="${SCRATCH}/h5para"
#
# Set this value; if you are ok with the subsequent directory structure, you can leave the rest alone. eventually
#  we'll want smarter version management.
#TARGET_PATH_ROOT=$HOME/.local/intel/19.1.0.166
TARGET_PATH_ROOT=${SCRATCH}/.local/intel/19.1.0.166
#
# set up program version variables/names:
NETCDF_C=netcdf-c-4.7.3
NETCDF_F=netcdf-fortran-4.5.2
NETCDF_CXX=netcdf-cxx4-4.3.1
ZLIB=zlib-1.2.11
HDF5=hdf5-1.10.6
CURL=curl-7.68.0
#
# now file paths:
# These are your install target paths. We're using an OHPC-like structure.
#
# NOTE: it might make sense to separate the C, Fortran, and maybe C++ components.
NCC_DIR=${TARGET_PATH_ROOT}/netcdfc/4.7.3
NCCXX_DIR=${TARGET_PATH_ROOT}/netcdfcxx/4.3.1
NCF_DIR=${TARGET_PATH_ROOT}/netcdff/4.5.2
#
ZDIR=${TARGET_PATH_ROOT}/zlib/1.2.11
H5DIR=${TARGET_PATH_ROOT}/hdf5/1.10.6
CURLDIR=${TARGET_PATH_ROOT}/curl/7.68.0
#
# TODO: might be a good idea to better understand the roles of LD_LIBRARY_PATH and LIBRARY_PATH, or
#  at least how they are used in these installation scripts.
export LD_LIBRARY_PATH=$H5DIR/lib:$ZDIR/LIB:$CURLDIR/lib:$NCC_DIR/lib:$LD_LIBRARY_PATH
export LIBRARY_PATH=$LD_LIBRARY_PATH:LIBRARY_PATH
#export LIBRARY_PATH=$LD_LIBRARY_PATH
export PATH=$H5DIR/bin:$NCC_DIR/bin:$PATH
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
echo "**"
#
# consolidate by component:
###########################################
# CURL:
#
# curl get:
if [ -f "${CURL}.tar.gz" ]; then
    echo "curl ${CURL} exists"
else
    echo "downloading curl..."
    wget https://curl.haxx.se/download/curl-7.68.0.tar.gz
fi
#
#####################
# curl unpack:
if [ -d "${CURL}" ]; then
    echo "curl (${CURL}) already unpacked"
else
    echo "unpacking curl..."
    tar xfv ${CURL}.tar.gz
fi
#
# curl install:
#####################
cd ${ROOT_DIR}/${CURL}
echo "switch to: " ${ROOT_DIR}/${CURL}
echo "switched to path: `pwd`"
echo "############"
echo "installing CURL to ${CURLDIR}"
#
CC=${MPICC} FC={MPIFC} CXX=${MPICXX} ./configure --prefix=${CURLDIR}
#
#make clean
make check
make install
#
####################################################################
# ZLIB:
# zlib get:
if [ -f "${ZLIB}.tar.gz" ]; then
    echo "zlib ( $ZLIB ) exists.";
 else
    echo "no zlib.";
    wget https://www.zlib.net/${ZLIB}.tar.gz;
fi
#
# zlib unpack:
if [ -d "${ZLIB}" ]; then
    echo "zlib already unpacked."
else
    echo "unpacking zlib"
    tar xfv ${ZLIB}.tar.gz
fi
###########################################
# zlib build:
#
cd ${ROOT_DIR}/${ZLIB}
echo "switch to: " ${ROOT_DIR}/${ZLIB}
echo "switched to path: `pwd`"
echo "############"
CC=${MPICC} FC={MPIFC} CXX=${MPICXX} ./configure --prefix=${ZDIR}
#
#make clean
make check
make install   # or sudo make install, if root permissions required
#
#####################################################################

# HDF5:
# hdf5 get:
## TODO: the HDF5 package, i think, needs to be downloade manually. i don't think we can easily script it.
##   maybe there is a github repo we can clone?
##wget https://www.hdfgroup.org/package/hdf5-1-10-6-tar/?wpdmdl=14133&refresh=5e177a53a0dab1578596947
#
# hdf5 unpack:
if [ -d "${HDF5}" ]; then
    echo "hdf5 already unpacked."
else
    echo "unpacking hdf5"
    if [ -f "${HDF5}.tar" ]; then
        tar xfv ${HDF5}.tar
    elif [ -f "${HDF5}.tar.gz" ]; then
        tar xfvz ${HDF5}.tar.gz
    fi
fi
#
###########################################
# hdf5 compile:
cd ${ROOT_DIR}/${HDF5}
echo "switch to: " ${ROOT_DIR}/${HDF5}
echo "switched to path: `pwd`"
echo "############"

# for serial IO:
# ./configure --with-zlib=${ZDIR} --prefix=${H5DIR} --enable-hl
# for parallel IO:
CC=${MPICC} FC={MPIFC} CXX=${MPICXX} ./configure --with-zlib=${ZDIR} --enable-parallel --enable-fortran --prefix=${H5DIR}
#
#make clean
#make check
make install   # or sudo make install, if root permissions required
#
#####################################################################
# NetCDF-C:
# get netcdf-c:
#if [ -f "netcdf-c-4.7.3.tar.gz" ]; then
if [ -f "${NETCDF_C}.tar.gz" ]; then
	echo "netcdf-c (${NETCDF_C}) exists"
else
	echo "downloading netcdf-c..."
	wget ftp://ftp.unidata.ucar.edu/pub/netcdf/${NETCDF_C}.tar.gz
	# https://www.unidata.ucar.edu/downloads/netcdf/ftp/netcdf-c-4.7.3.tar.gz
fi
#
# unpack netcdf-c
if [ -d "${NETCDF_C}" ]; then
    echo "netcdf-c (${NETCDF_F}) already unpacked."
else
    echo "unpacking netcdf-c"
    tar xfv ${NETCDF_C}.tar.gz
fi
#
# compile netcdf-c
############################################
## NetCDF-C:
cd ${ROOT_DIR}/${NETCDF_C}
echo "switch to: " ${ROOT_DIR}/${NETCDF_C}
echo "switched to path: `pwd`"
echo "############"
#
echo "compiling netcdf-c; H5DIR=${H5DIR}"
#
# serial IO
##CPPFLAGS='-I${H5DIR}/include -I${ZDIR}/include' LDFLAGS='-L${H5DIR}/lib -L${ZDIR}/lib' ./configure --prefix=$NCC_DIR
# parallel IO:
# (maybe... in the documents' example, the ZLIB bits are excluded.
CPP_FLAGS="-I${H5DIR}/include -I${ZDIR}/include -I${CURLDIR}/include "
LDFLAGS="-L${H5DIR}/lib -L${ZDIR}/lib -L${CURLDIR}/lib"
#
LD_LIBRARY_PATH =${H5DIR}/lib:${ZDIR}/lib:${CURLDIR}/lib:$LD_LIBRARY_PATH
LIBRARY_PATH=$LD_LIBRARY_PATH
#
C_FLAGS="-fpic "
LIBS="-ldl -lhdf5 -lm"
echo "C_FLAGS: ${CPP_FLAGS}"
# NOTE: --disable-dap installs without curl support. do we need curl? is being a big pain to install...
# NOTE: The LIBS=-ldl option supposedly fixes a mysterious H5Fflush error;
#   you'll get an error that says "can't link to or find hdf5 libraries..." but i
#   still get the error.
CC=${MPICC} FC=${MPIFC} CXX={MPICXX} CFLAGS=${C_FLAGS} CPPFLAGS=${CPP_FLAGS} LDFLAGS=${LDFLAGS} LIBS=${LIBS} ./configure --disable-shared --enable-parallel-tests --prefix=${NCC_DIR} --disable-dap
# this should be a SPP compilation:
#CC=${MPICC} FC=${MPIFC} CXX={MPICXX} CPPFLAGS=${C_FLAGS} ./configure  --prefix=${NCC_DIR}
#
# parallel?:
#CC=${MPICC} FC=${MPIFC} CXX={MPICXX} CPPFLAGS=${C_FLAGS} ./configure --disable-shared --enable-parallel-tests  --prefix=${NCC_DIR}
make clean
make check
make install  # or sudo make install
#

###################################################################
# NetCDF-fortran:
# get NetCDF-fortran:
if [ -f "${NETCDF_F}.tar.gz" ]; then
	echo "netcdf-fortran exists"
else
	echo "downloading netcdf-fortran..."
	wget ftp://ftp.unidata.ucar.edu/pub/netcdf/${NETCDF_F}.tar.gz
	# https://www.unidata.ucar.edu/downloads/netcdf/ftp/netcdf-fortran-4.5.2.tar.gz
fi
#
# unpack netcdf-fortran:
if [ -d "${NETCDF_F}" ]; then
    echo "netcdf-fortran already unpacked."
else
    echo "unpacking netcdf-fortran"
    tar xfv ${NETCDF_F}.tar.gz
fi
#
# compile netcdf-fortran
# NetCDF-Fortran:
cd ${ROOT_DIR}/$NETCDF_F
echo "switch to: " ${ROOT_DIR}/$NETCDF_F
echo "actual path: `pwd`"
echo "############"
#
# getting a "can't run compiler" or something. found someplace that starting PATH with /usr/local/bin, etc. can help:
PATH=/usr/bin:/usr/local/bin:/usr/local/sbin:$PATH
#
## compilation worked after exporting this variable, but I think I had also not included it in the
#  ./configure prefixes, so it may not be necessary. Unfortunatly, it is difficult to test, since it is
#  necessary to start a new session (or painstakingly modify the variable), and then recompile. which takes hours.
#
#export LD_LIBRARY_PATH=${NCC_DIR}:${NCF_DIR}:$LD_LIBRARY_PATH
#export LIBRARY_PATH=${NCC_DIR}:${NCDF_DIR}:$LIBRARY_PATH
#export LIBRARY_PATH=$LD_LIBRARY_PATH
##
#CPPFLAGS=-I${NCC_DIR}/include LDFLAGS=-L${NCC_DIR}/lib \
./configure --prefix=${NCF_DIR}
echo "********"
#C_FLAGS=" -I${NCC_DIR}/include -I${NCF_DIR}/include -I${H5DIR}/include -I${ZDIR}/include "
# these two should be equivalen"t:
#C_FLAGS = "`nf-config --fflags`"
#C_FLAGS="`nc-config --cflags` -I${NCF_DIR}/include -I${ZDIR}/include -I${CURLDIR}"
#; nc-config --fflags`"
C_FLAGS = '-fpic '
CPP_FLAGS="-I${NCC_DIR}/include -I${H5DIR}/include -I${NCF_DIR}/include -I${ZDIR}/include -I${CURLDIR}/include "
FFLAGS="-fpic "
#
#LD_FLAGS="`nc-config --libs` -L${NCF_DIR}/lib -L${ZDIR}/lib -L${CURLDIR}/lib -L${H5DIR}/lib "
LD_FLAGS="`nc-config --libs` -L${ZDIR}/lib -L${CURLDIR}/lib -L${H5DIR}/lib "
#
#LIBS=" -lnetcdf -lm"
LIBS="-lnetcdf "
#LD_FLAGS="${LD_FLAGS} -L${ZDIR}/lib -L${CURLDIR}/lib"
#C_FLAGS = "${C_FLAGS} ${LD_FLAGS}"
echo "*** LD_FLAGS: " ${LD_FLAGS}
#
echo "*** C_FLAGS: " ${CPP_FLAGS}
echo "*** end C_FLAGS"
#
#LD_FLAGS=
CC=${MPICC} FC=${MPIFC} CXX=${MPICXX} CPPFLAGS=${CPP_FLAGS} FFLAGS=${FFLAGS} CFLAGS=${C_FLAGS} LDFLAGS=${LD_FLAGS} LIBS=${LIBS} ./configure --prefix=${NCF_DIR} --enable-parallel-tests
#--bindir=/usr/local/bin --bindir=/usr/bin
#
make clean
make check
make install
#
######################################################################
# NetCDF-C++:
# get NetCDF-C++:
# ... though we might not actually install this just yet
if [ -f "${NETCDF_CXX}.tar.gz" ]; then
	echo "netcdf-c++ ( ${NETCDF_CXX} ) exists"
else
	echo "downloading netcdf-c++... ${NETCDF_CXX} ..."
	wget ftp://ftp.unidata.ucar.edu/pub/netcdf/${NETCDF_CXX}.tar.gz
	# https://www.unidata.ucar.edu/downloads/netcdf/ftp/netcdf-cxx4-4.3.1.tar.gz
fi
#
# unpack netcdf-c++
if [ -d "${NETCDF_CXX}" ]; then
    echo "netcdf-cxx already unpacked."
else
    echo "unpacking netcdf-cxx"
    tar xfv ${NETCDF_CXX}.tar.gz
fi
#
# TODO: compile netcdf-c++

cd ${ROOT_DIR}/$NETCDF_CXX
echo "switch to: " ${ROOT_DIR}/$NETCDF_CXX
echo "actual path: `pwd`"
echo "############"
#
## do we need to export to LD_LIBRARY_PATH if we include the linking path in
##  compilation? I guess so...

#export LD_LIBRARY_PATH=${NCC_DIR}:${NCF_DIR}:$LD_LIBRARY_PATH
#export LIBRARY_PATH=${NCC_DIR}:${NCDF_DIR}:$LIBRARY_PATH
#export LIBRARY_PATH=$LD_LIBRARY_PATH
##
#CPPFLAGS=-I${NCC_DIR}/include LDFLAGS=-L${NCC_DIR}/lib \
./configure --prefix=${NCF_DIR}
echo "********"
#
C_FLAGS = '-fpic '
CPP_FLAGS="-I${NCC_DIR}/include -I${NCF_DIR}/include -I${H5DIR}/include -I${ZDIR}/include -I${CURLDIR}/include "
FFLAGS="-fpic "
#
# nc/f-config might not be available...
LD_FLAGS="-L${NCC_DIR}/lib -L${NCF_DIR}/lib -L${ZDIR}/lib -L${CURLDIR}/lib -L${H5DIR}/lib "
#LD_FLAGS="`nc-config --libs` -L${NCF_DIR}/lib -L${ZDIR}/lib -L${CURLDIR}/lib -L${H5DIR}/lib "
#LD_FLAGS="`nc-config --libs` -L${ZDIR}/lib -L${CURLDIR}/lib -L${H5DIR}/lib "
#
#LIBS=" -lnetcdf -lm"
LIBS="-lnetcdf "
#
echo "*** LD_FLAGS: " ${LD_FLAGS}
echo "*** C_FLAGS: " ${CPP_FLAGS}
echo "*** end C_FLAGS"
#
#LD_FLAGS=
CC=${MPICC} FC=${MPIFC} CXX=${MPICXX} CPPFLAGS=${CPP_FLAGS} FFLAGS=${FFLAGS} CFLAGS=${C_FLAGS} LDFLAGS=${LD_FLAGS} LIBS=${LIBS} ./configure --prefix=${NCF_DIR} --enable-parallel-tests
#--bindir=/usr/local/bin --bindir=/usr/bin
#
make clean
make check
make install


