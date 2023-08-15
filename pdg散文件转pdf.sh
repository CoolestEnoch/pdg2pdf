#!/bin/bash


echo "请确保安装了 unzip, ffmpeg, imagemagick 和 pdftk 然后再运行本脚本!"
echo "食用方法:"
echo "  1. 直接法: 将本脚本和pdg散文件放在同级目录然后运行本脚本。输出的pdf文件名为merged.pdf"
echo "  2. 懒人法: 在命令行里运行 bash ./pdg散文件转pdf.sh 电子书.zip 然后输出的文件就是和zip文件同名的pdf"
echo "按任意键继续..."
read -n 1 -s -r -p ""
echo "Continuing..."

withArgs=false
zip_filename=""


# 判断命令行参数是否为空
if [ -z "$1" ]; then
    echo "Running script without zip extraction"
else
    # 提取zip文件名（不包括路径和扩展名）
    zip_filename=$(basename "$1" .zip)

    # 解压zip文件到与zip同名文件夹
    unzip -j -d "$zip_filename" "$1"
    cd "$zip_filename"

    echo "Unzipped and changed directory to: $(pwd)"
    withArgs=true
fi


# 开始处理转换

mkdir jpgs && mkdir pdfs && for file in $(ls);do ffmpeg -i $file jpgs/${file%.*}.jpg;done

# for i in {1..10}; do start=$((($i - 1) * 100 + 1)); end=$(($i * 100)); convert $(seq -f "%06g.jpg" $start $end) ./output_$i.pdf; done

# 正反面封面
convert jpgs/cov001.jpg pdfs/cover_front.pdf
convert jpgs/cov002.jpg pdfs/cover_end.pdf

# 非铜版纸的封面
convert jpgs/bok001.jpg pdfs/bok.pdf

# ISBN信息页
convert $(ls -v jpgs/leg*.jpg) pdfs/leg.pdf

# 前言
convert $(ls -v jpgs/fow*.jpg) pdfs/fow.pdf

# 目录
convert $(ls -v jpgs/\!*.jpg) pdfs/contents.pdf

# 正文部分
for i in {1..10}; do
    start=$((($i - 1) * 100 + 1))
    end=$(($i * 100))
    convert $(seq -f "jpgs/%06g.jpg" $start $end) ./pdfs/texts_$i.pdf
done

# 合并正文
pdftk pdfs/texts_*.pdf cat output pdfs/text.pdf

# 合并所有缓存文件
pdftk pdfs/cover_front.pdf pdfs/bok.pdf pdfs/leg.pdf pdfs/fow.pdf pdfs/contents.pdf pdfs/text.pdf pdfs/cover_end.pdf cat output merged.pdf


if [ "$withArgs" = true ]; then
    mv merged.pdf ../"$zip_filename".pdf
    cd ..
    rm -rf "$zip_filename"
else
    echo "Variable is false, performing action B."

fi

# 删除缓存
rm -rf jpgs pdfs
