#!/usr/bin/env bash

here=$(dirname "$0")
# shellcheck source=multinode-demo/common.sh
source "$here"/common.sh

set -e

rm -rf "$SOLANA_CONFIG_DIR"/bootstrap-validator
mkdir -p "$SOLANA_CONFIG_DIR"/bootstrap-validator

# Create genesis ledger
if [[ -r $FAUCET_KEYPAIR ]]; then
  cp -f "$FAUCET_KEYPAIR" "$SOLANA_CONFIG_DIR"/faucet.json
else
  $solana_keygen new --no-passphrase -fso "$SOLANA_CONFIG_DIR"/faucet.json
fi

if [[ -f $BOOTSTRAP_VALIDATOR_IDENTITY_KEYPAIR ]]; then
  cp -f "$BOOTSTRAP_VALIDATOR_IDENTITY_KEYPAIR" "$SOLANA_CONFIG_DIR"/bootstrap-validator/identity.json
else
  $solana_keygen new --no-passphrase -so "$SOLANA_CONFIG_DIR"/bootstrap-validator/identity.json
fi
if [[ -f $BOOTSTRAP_VALIDATOR_STAKE_KEYPAIR ]]; then
  cp -f "$BOOTSTRAP_VALIDATOR_STAKE_KEYPAIR" "$SOLANA_CONFIG_DIR"/bootstrap-validator/stake-account.json
else
  $solana_keygen new --no-passphrase -so "$SOLANA_CONFIG_DIR"/bootstrap-validator/stake-account.json
fi
if [[ -f $BOOTSTRAP_VALIDATOR_VOTE_KEYPAIR ]]; then
  cp -f "$BOOTSTRAP_VALIDATOR_VOTE_KEYPAIR" "$SOLANA_CONFIG_DIR"/bootstrap-validator/vote-account.json
else
  $solana_keygen new --no-passphrase -so "$SOLANA_CONFIG_DIR"/bootstrap-validator/vote-account.json
fi

args=(
  "$@"
  --max-genesis-archive-unpacked-size 1073741824
  --enable-warmup-epochs
  --bootstrap-validator "$SOLANA_CONFIG_DIR"/bootstrap-validator/identity.json
                        "$SOLANA_CONFIG_DIR"/bootstrap-validator/vote-account.json
                        "$SOLANA_CONFIG_DIR"/bootstrap-validator/stake-account.json
)

"$SOLANA_ROOT"/fetch-core-bpf.sh
if [[ -r core-bpf-genesis-args.sh ]]; then
  CORE_BPF_GENESIS_ARGS=$(cat "$SOLANA_ROOT"/core-bpf-genesis-args.sh)
  #shellcheck disable=SC2207
  #shellcheck disable=SC2206
  args+=($CORE_BPF_GENESIS_ARGS)
fi

"$SOLANA_ROOT"/fetch-spl.sh
if [[ -r spl-genesis-args.sh ]]; then
  SPL_GENESIS_ARGS=$(cat "$SOLANA_ROOT"/spl-genesis-args.sh)
  #shellcheck disable=SC2207
  #shellcheck disable=SC2206
  args+=($SPL_GENESIS_ARGS)
fi

default_arg --ledger "$SOLANA_CONFIG_DIR"/bootstrap-validator
default_arg --faucet-pubkey "$SOLANA_CONFIG_DIR"/faucet.json
default_arg --faucet-lamports 500000000000000000
default_arg --hashes-per-tick auto
default_arg --cluster-type development


# Print final args for debugging so the user can see what will be passed to solana-genesis
echo "[setup.sh] Final solana-genesis args (count=${#args[@]}):"
# Print as a single joined line
printf '%s ' "${args[@]}"
echo
# Also print each arg on its own line with index for clarity
for i in "${!args[@]}"; do
  printf '  [%s] %s\n' "$i" "${args[$i]}"
done

read -p "Press enter to continue"
$solana_genesis "${args[@]}"
