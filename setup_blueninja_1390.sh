#! /bin/bash

apt-get -y install git
apt-get -y install OpenOCD

git clone https://bitbucket.org/cerevo/blueninja_bsp.git

echo "Download and copy OSHIBA.TZ10xx_DFP.*.pack files into blueninja_bsp/install_files/"
echo ". Please Enter key. restart."
read Wait


export BASE=$HOME/Cerevo/CDP-TZ01B/
export GIT_BSP_BASE=blueninja_bsp
export BSP_INST_FILES_DIR=install_files/

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
if [ ! -e ARM.CMSIS.3.20.4.pack ]; then
	wget https://sadevicepacksprodus.blob.core.windows.net/pack/ARM.CMSIS.3.20.4.pack
fi
unzip -qd ${BASE}sdk/ARM.CMSIS ARM.CMSIS.3.20.4.pack

if [ ! -e gcc-arm-none-eabi-4_9-2015q1-20150306-linux.tar.bz2 ]; then
	wget https://launchpad.net/gcc-arm-embedded/4.9/4.9-2015-q1-update/+download/gcc-arm-none-eabi-4_9-2015q1-20150306-linux.tar.bz2
fi
tar -jxf gcc-arm-none-eabi-4_9-2015q1-20150306-linux.tar.bz2 -C ${BASE}tools --strip=1

# Add Packs
for file in `\find . -name 'TOSHIBA.TZ10xx_DFP.*.pack'`; do
        echo $file
        ver_num=`echo $file | cut -c 50-55`

	if [ ! -e "${BASE}sdk/TOSHIBA.TZ10xx_DFP.${ver_num}" ]; then
		mkdir "${BASE}sdk/TOSHIBA.TZ10xx_DFP.${ver_num}"
	fi
	unzip -qd ${BASE}sdk/TOSHIBA.TZ10xx_DFP.${ver_num} ${file}
done

# Add Patchs
for file in `\find . -name 'TOSHIBA.TZ10xx_DFP.*.patch'`; do
	sed -i -e "s/\\\\/\//g" $file
	file_name=`sed -n 2p ${file} | cut -d' ' -f2 | cut -f1`
	fromdos ${BASE}sdk/${file_name}
	patch -p0 -d ${BASE}sdk < $file
done

cp ${GIT_BSP_BASE}/${BSP_INST_FILES_DIR}tz10xx.specs ${BASE}tools/arm-none-eabi/lib
${BASE}tools/bin/arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -mthumb-interwork -march=armv7e-m -mfloat-abi=soft -std=c99 -g -O0 -c tz10xx-crt0.c -o ${BASE}tools/arm-none-eabi/lib/tz10xx-crt0.o

echo "Finish"
exit
