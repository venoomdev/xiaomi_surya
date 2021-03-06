#!/bin/bash
#
# Compile script for QuicksilveR kernel
# Copyright (C) 2020-2021 Adithya R.

export TZ=Asia/Jakarta
START=$(date +"%s")
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz
DTBO=$(pwd)/out/arch/arm64/boot/dtbo.img
TANGGAL=${VERSION}-$(date +"%d%m%H%M")
SECONDS=0 # builtin bash timer
#CLANG_VERSION=$(clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
KERNEL_DIR=$(pwd)
BRANCH=$(git rev-parse --abbrev-ref HEAD)
ZIPNAME="venoom-surya-$(date '+%Y%m%d-%H%M').zip"
TC_DIR="/root/kernel/c"
GCC_64_DIR="/root/kernel/gcc/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64"
GCC_32_DIR="/root/kernel/gcc/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64"
export KBUILD_BUILD_HOST="Venoom"
export KBUILD_BUILD_USER="WartegCI"
AK3_DIR="/root/kernel/AnyKernel3"
export chat_id="-1001614291509"
export TOKEN="2090929759:AAGkk4KBry_oAWjZiGacVfZp2GkPdeUkXIs"
DEFCONFIG="surya_defconfig"
export PATH="$TC_DIR/bin:$PATH"
export CCACHE_DIR="/root/.cache/ccache"
export CA="ccache gcc"
export CXX="ccache g++"
export PATH="/usr/lib/ccache:$PATH"
export KBUILD_COMPILER_STRING="/root/kernel/c/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"


if [[ $1 = "-r" || $1 = "--regen" ]]; then
	make O=out ARCH=arm64 $DEFCONFIG savedefconfig
	cp out/defconfig arch/arm64/configs/$DEFCONFIG
	echo -e "\nSuccessfully regenerated defconfig at $DEFCONFIG"
	exit
fi

curl -s -X POST https://api.telegram.org/bot${TOKEN}/sendMessage -d text="Buckle up bois ${BRANCH} build has started" -d chat_id=${chat_id} -d parse_mode=HTML

mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG

echo -e "\nStarting compilation...\n"
# make -j$(nproc --all) O=out ARCH=arm64 CC=clang LD=ld.lld AS=llvm-as AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=$GCC_64_DIR/bin/aarch64-linux-android- CROSS_COMPILE_ARM32=$GCC_32_DIR/bin/arm-linux-androideabi- CLANG_TRIPLE=aarch64-linux-gnu- Image.gz dtbo.img
make -j$(nproc --all) O=out ARCH=arm64 CC=clang LD=ld.lld AS=llvm-as AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- CLANG_TRIPLE=aarch64-linux-gnu- Image.gz dtbo.img
kernel="out/arch/arm64/boot/Image.gz"
dtb="out/arch/arm64/boot/dts/qcom/sdmmagpie.dtb"
dtbo="out/arch/arm64/boot/dtbo.img"

# Post to CI channel
curl -s -X POST https://api.telegram.org/bot${TOKEN}/sendMessage -d text="Branch: <code>$(git rev-parse --abbrev-ref HEAD)</code>
Compiler Used : <code>${CLANG_VERSION} </code>
Latest Commit: <code>$(git log --pretty=format:'%h : %s' -1)</code>
<i>Build compiled successfully in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds</i>" -d chat_id=${chat_id} -d parse_mode=HTML
#curl -s -X POST https://api.telegram.org/bot${TOKEN}/sendMessage -d text="Flash now else bun" -d chat_id=${chat_id} -d parse_mode=HTML


if [ -f "$kernel" ] && [ -f "$dtb" ] && [ -f "$dtbo" ]; then
	echo -e "\nKernel compiled succesfully! Zipping up...\n"
	if [ -d "$AK3_DIR" ]; then
		cp -r $AK3_DIR AnyKernel3
	elif ! git clone -q https://github.com/venoom/AnyKernel3 -b surya; then
		echo -e "\nAnyKernel3 repo not found locally and couldn't clone from GitHub! Aborting..."
		exit 1
	fi
	cp $kernel $dtbo AnyKernel3
	cp $dtb AnyKernel3/dtb
	rm -rf out/arch/arm64/boot
	cd AnyKernel3
	git checkout surya &> /dev/null
	zip -r9 "../$ZIPNAME" * -x .git README.md *placeholder
	cd ..
	rm -rf AnyKernel3
	echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
	echo "Zip: $ZIPNAME"
	 curl -F chat_id="${chat_id}"  \
             -F caption="sha1sum: $(sha1sum $ZIPNAME | awk '{ print $1 }')" \
             -F document=@"$ZIPNAME" \
             https://api.telegram.org/bot${TOKEN}/sendDocument
else
       curl -F chat_id="${chat_id}"  \
                    -F caption="sha1sum: $(sha1sum $ZIPNAME | awk '{ print $1 }')" \
                    -F document=@"$ZIPNAME" \
                    https://api.telegram.org/bot${TOKEN}/sendDocument
	fi

    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendSticker" \
        -d sticker="CAACAgUAAxkBAAJi017AAw5j25_B3m8IP-iy98ffcGHZAAJAAgACeV4XIusNfRHZD3hnGQQ" \
        -d chat_id="$chat_id"
else
	echo -e "\nCompilation failed!"
	exit 1
fi
