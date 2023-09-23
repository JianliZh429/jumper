#! /bin/bash

rm -rf target
echo "Build linux target..."
CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=x86_64-unknown-linux-gnu-gcc cargo build --release --target=x86_64-unknown-linux-gnu

echo "Build Mac target..."
cargo build --release --target=x86_64-apple-darwin

mkdir -p pkg

cp target/x86_64-unknown-linux-gnu/release/jumper pkg/jumper
cp install.sh pkg/install.sh
cp jumper.sh pkg/jumper.sh

cd pkg
chmod +x jumper
tar -zcvf ../target/jumper-x86_64-unknown-linux-gnu.tar.gz jumper install.sh jumper.sh
rm jumper
cd -

cp target/x86_64-apple-darwin/release/jumper pkg/jumper
cd pkg
chmod +x jumper
tar -zcvf ../target/jumper-x86_64-apple-darwin.tar.gz jumper install.sh jumper.sh
cd -

# mv jumper.tar.gz target/jumper.tar.gz
rm pkg/*
echo "Done..."