#!/bin/bash

# =====================================================
#  BUILD COMPLETO SEM OUT/
#  Junta exynos9830_defconfig + ksu.config + r8s.config
# =====================================================

# Variáveis de compilação
export ARCH=arm64
export SUBARCH=arm64

export CC=clang
export LLVM=1
export LLVM_IAS=1

export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-

export LD=ld.lld
export AR=llvm-ar
export NM=llvm-nm
export OBJCOPY=llvm-objcopy
export OBJDUMP=llvm-objdump
export STRIP=llvm-strip

# Fragmentos do defconfig
CFG1="arch/arm64/configs/extreme.config"
CFG2="arch/arm64/configs/ksu.config"
CFG3="arch/arm64/configs/extreme_r8s_defconfig"

DEFCONFIG="arch/arm64/configs/r8s_defconfig"

JOBS=$(nproc --all)
KERNEL_DIR=$(pwd)
ANYKERNEL_DIR="$KERNEL_DIR/AnyKernel3"

echo "=========================================="
echo "  Limpando build antigo..."
echo "=========================================="
make mrproper

echo "=========================================="
echo "  Juntando configs para gerar defconfig..."
echo "=========================================="
rm -f .config
./scripts/kconfig/merge_config.sh $CFG1 $CFG2 $CFG3
cp .config $DEFCONFIG

echo "=========================================="
echo "  Compilando kernel..."
echo "=========================================="
make $DEFCONFIG
make -j$JOBS

if [ ! -f "arch/arm64/boot/Image" ]; then
    echo "ERRO: Image não encontrada! Compilação falhou."
    exit 1
fi

echo "=========================================="
echo "  Gerando dtb.img e dtbo.img"
echo "=========================================="
find arch/arm64/boot/dts/ -name "*.dtb" -exec cat {} + > dtb.img

if [ -f "arch/arm64/boot/dtbo.img" ]; then
    cp arch/arm64/boot/dtbo.img dtbo.img
fi

echo "=========================================="
echo "  Preparando AnyKernel3"
echo "=========================================="

cp arch/arm64/boot/Image $ANYKERNEL_DIR/
cp dtb.img $ANYKERNEL_DIR/
cp dtbo.img $ANYKERNEL_DIR/ 2>/dev/null

cd $ANYKERNEL_DIR
zip -r9 ExtremeR8s-Kernel.zip * -x .git README.md
cd $KERNEL_DIR

echo "=========================================="
echo " KERNEL COMPILADO!"
echo " ZIP disponível em:"
echo " $ANYKERNEL_DIR/ExtremeR8s-Kernel.zip"
echo "=========================================="
