#!/bin/sh

# Memastikan rust sudah terinstal, atau instal jika belum ada
rustc --version || curl https://sh.rustup.rs -sSf | sh

NEXUS_HOME=$HOME/.nexus
GREEN='\033[1;32m'
ORANGE='\033[1;33m'
NC='\033[0m' # No Color

# Membuat direktori .nexus jika belum ada
mkdir -p $NEXUS_HOME

# Otomatis pilih 'y' untuk menyetujui syarat Nexus Beta (tanpa /dev/tty)
echo "y" | while [ -z "$NONINTERACTIVE" ] && [ ! -f "$NEXUS_HOME/prover-id" ]; do
    # Melewati input interaktif untuk syarat Nexus Beta
    echo "Skipping agreement to Nexus Beta Terms of Use"
    break
done

# Cek keberadaan git
git --version 2>&1 >/dev/null
GIT_IS_AVAILABLE=$?
if [ $GIT_IS_AVAILABLE != 0 ]; then
  echo "Unable to find git. Please install it and try again."
  exit 1;
fi

# Memastikan file prover-id ada atau menulis yang baru jika tidak ada
if [ ! -f "$NEXUS_HOME/prover-id" ]; then
    echo "No prover-id file found. Creating new prover-id..."

    # Menetapkan Prover ID secara otomatis
    PROVER_ID="N6fnuD9vv0OIday4X8njm8QL0nD2"
    echo "Automatically using Prover ID: $PROVER_ID"
    
    # Menyimpan Prover ID ke file prover-id
    echo "$PROVER_ID" > $NEXUS_HOME/prover-id
    echo "Prover ID saved to $NEXUS_HOME/prover-id."
else
    # Membaca Prover ID dari file jika sudah ada
    PROVER_ID=$(cat $NEXUS_HOME/prover-id)
    echo "Prover ID found: $PROVER_ID"
fi

# Mengatur path repositori
REPO_PATH=$NEXUS_HOME/network-api
if [ -d "$REPO_PATH" ]; then
  echo "$REPO_PATH exists. Updating."
  (cd $REPO_PATH && git stash save && git fetch --tags)
else
  mkdir -p $NEXUS_HOME
  (cd $NEXUS_HOME && git clone https://github.com/nexus-xyz/network-api)
fi

# Mengambil dan menggunakan tag terbaru dari repositori
(cd $REPO_PATH && git -c advice.detachedHead=false checkout $(git rev-list --tags --max-count=1))

# Menjalankan aplikasi
(cd $REPO_PATH/clients/cli && cargo run --release --bin prover -- beta.orchestrator.nexus.xyz)
