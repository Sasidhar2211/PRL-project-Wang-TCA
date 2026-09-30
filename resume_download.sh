#!/bin/bash
# Script to resume downloading datasets (skipping already downloaded and broken EuroSAT)

DATA_DIR="data"

echo "Downloading FGVC Aircraft..."
cd $DATA_DIR/fgvc/data
wget https://www.robots.ox.ac.uk/~vgg/data/fgvc-aircraft/archives/fgvc-aircraft-2013b.tar.gz
tar -xzf fgvc-aircraft-2013b.tar.gz --strip-components=1
rm fgvc-aircraft-2013b.tar.gz
cd ../../..

echo "Downloading Food-101..."
cd $DATA_DIR/food-101
wget http://data.vision.ee.ethz.ch/cvl/food-101.tar.gz
tar -xzf food-101.tar.gz --strip-components=1
rm food-101.tar.gz
cd ../..

echo "Downloading Oxford Flowers..."
cd $DATA_DIR/oxford_flowers
wget https://www.robots.ox.ac.uk/~vgg/data/flowers/102/102segments.tgz
tar -xzf 102segments.tgz
rm 102segments.tgz
cd ../..

echo "Downloading Oxford Pets..."
cd $DATA_DIR/oxford_pets
wget https://www.robots.ox.ac.uk/~vgg/data/pets/data/images.tar.gz
wget https://www.robots.ox.ac.uk/~vgg/data/pets/data/annotations.tar.gz
tar -xzf images.tar.gz
tar -xzf annotations.tar.gz
rm images.tar.gz annotations.tar.gz
cd ../..

echo "Downloading SUN397..."
cd $DATA_DIR/sun397
wget http://vision.princeton.edu/projects/2010/SUN/SUN397.tar.gz
tar -xzf SUN397.tar.gz
rm SUN397.tar.gz
cd ../..

echo "Downloading UCF101..."
cd $DATA_DIR/ucf101
wget --no-check-certificate https://www.crcv.ucf.edu/data/UCF101/UCF101.rar
unrar x UCF101.rar
rm UCF101.rar
cd ../..

echo "Downloads complete!"
