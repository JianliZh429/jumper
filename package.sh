#! /bin/bash
cargo run
mkdir -p pkg

cp target/debug/jumper pkg/jumper
cp install.sh pkg/install.sh
cp jumper.sh pkg/jumper.sh

cd pkg
tar -zcvf ../target/jumper.tar.gz jumper install.sh jumper.sh
cd ../

# mv jumper.tar.gz target/jumper.tar.gz
rm pkg/*
echo "Done..."