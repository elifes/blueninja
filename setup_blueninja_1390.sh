#! /bin/bash

apt-get -y install git
apt-get -y install OpenOCD
apt-get -y install tofrodos

git clone https://github.com/elifes/blueninja.git

echo "Download and copy OSHIBA.TZ10xx_DFP.*.pack files into blueninja_bsp/install_files/"
echo ". Please Enter key. restart."
read Wait

echo "Please wait a moment."

export BASE=$HOME/Cerevo/CDP-TZ01B/
export GIT_BSP_BASE=blueninja_bsp
export BSP_INST_FILES_DIR=install_files/
export OPENOCD_INST_DIR=/usr/share/openocd

# Create DIRz
if [ ! -e ${BASE} ]; then
	mkdir -p ${BASE}
fi
if [ ! -e ${BASE}tools ]; then
	mkdir ${BASE}tools
fi
if [ ! -e ${BASE}sdk ]; then
	mkdir ${BASE}sdk
fi
if [ ! -e ${BASE}sdk/ARM.CMSIS ]; then
	mkdir ${BASE}sdk/ARM.CMSIS
fi
if [ ! -e "${BASE}sdk/TOSHIBA.TZ10xx_DFP" ]; then
	mkdir "${BASE}sdk/TOSHIBA.TZ10xx_DFP"
fi

# Download and unpack modules 
export CMSIS_FILE_NAME=ARM.CMSIS.3.20.4.pack
if [ ! -e ${CMSIS_FILE_NAME} ]; then
	wget https://sadevicepacksprodus.blob.core.windows.net/pack/${CMSIS_FILE_NAME}
fi
unzip -qd ${BASE}sdk/ ${CMSIS_FILE_NAME}

export GCC_FILE_NAME=gcc-arm-none-eabi-6_2-2016q4-20161216-linux.tar.bz2
if [ ! -e ${GCC_FILE_NAME} ]; then
	wget https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-rm/6-2016q4/${GCC_FILE_NAME}
fi
tar -jxf ${GCC_FILE_NAME} -C ${BASE}tools --strip=1

# Add Packs
for file in `\find . -name 'TOSHIBA.TZ10xx_DFP.*.pack'`; do
	ver_num=`basename $file | cut -c 20-25`

	if [ -e "${BASE}sdk/TOSHIBA.TZ10xx_DFP.${ver_num}" ]; then
		echo "Found ${BASE}sdk/TOSHIBA.TZ10xx_DFP.${ver_num}"
	else
		mkdir "${BASE}sdk/TOSHIBA.TZ10xx_DFP.${ver_num}"
	fi
	unzip -qd ${BASE}sdk/TOSHIBA.TZ10xx_DFP.${ver_num} ${file}
	if [ ${ver_num} = "1.31.1" ]; then
		unzip -qd ${BASE}sdk/TOSHIBA.TZ10xx_DFP ${file}
	fi
done

# Add Patchs
for file in `\find . -name 'TOSHIBA.TZ10xx_DFP.*.patch'`; do
	sed -i -e "s/\\\\/\//g" $file
	file_name=`sed -n 2p ${file} | cut -d' ' -f2 | cut -f1`
	fromdos ${BASE}sdk/${file_name}
	patch -p0 -d ${BASE}sdk < $file
done

# copy patch version file.
for file in `\find ./${GIT_BSP_BASE}/versions -name '*.patch'`; do
	#file_name=`basename $file .patch`
	cp -f $file ${BASE}sdk/
done

cp ${GIT_BSP_BASE}/${BSP_INST_FILES_DIR}tz10xx.specs ${BASE}tools/arm-none-eabi/lib

cd ${GIT_BSP_BASE}/${BSP_INST_FILES_DIR}
${BASE}tools/bin/arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -mthumb-interwork -march=armv7e-m -mfloat-abi=soft -std=c99 -g -O0 -c tz10xx-crt0.c -o ${BASE}tools/arm-none-eabi/lib/tz10xx-crt0.o

cp -f tz10xx.cfg ${OPENOCD_INST_DIR}/scripts/target/
cp -f tz10xx_reset.tcl ${OPENOCD_INST_DIR}/scripts/target/

cd ../
cp -rf _TZ1/* ${BASE}
cd ../
cp -rf MyScript/* ${BASE}

echo "Done."

exit

