#!/usr/bin/env bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# import utils
# test network home var targets to test network folder
# the reason we use a var here is considering with org3 specific folder
# when invoking this for org3 as test-network/scripts/org3-scripts
# the value is changed from default as $PWD(test-network)
# to .. as relative path to make the import works
TEST_NETWORK_HOME=${TEST_NETWORK_HOME:-${PWD}}
. ${TEST_NETWORK_HOME}/scripts/envVar.sh

# fetchChannelConfig <org> <channel_id> <output_json>
# Writes the current channel config for a given channel to a JSON file
# NOTE: this requires jq and configtxlator for execution.
fetchChannelConfig() {
  ORG=$1
  CHANNEL=$2
  OUTPUT=$3

  setGlobals $ORG

  infoln "Fetching the most recent configuration block for the channel"
  set -x
  # Ensure paths passed to Windows-native binaries are Windows-style when running under MINGW
  if uname | grep -i mingw > /dev/null 2>&1; then
    if command -v cygpath > /dev/null 2>&1; then
      ORDERER_CA_WIN=$(cygpath -w "$ORDERER_CA")
      CONFIG_BLOCK_PB_WIN=$(cygpath -w "${TEST_NETWORK_HOME}/channel-artifacts/config_block.pb")
      CONFIG_BLOCK_JSON_WIN=$(cygpath -w "${TEST_NETWORK_HOME}/channel-artifacts/config_block.json")
      OUTPUT_WIN=$(cygpath -w "${OUTPUT}")
      # Ensure FABRIC_CFG_PATH is Windows-style so peer.exe resolves any relative paths correctly
      if [ -n "$FABRIC_CFG_PATH" ]; then
        FABRIC_CFG_PATH_WIN=$(cygpath -w "$FABRIC_CFG_PATH" 2>/dev/null || pwd -W)
        export FABRIC_CFG_PATH="$FABRIC_CFG_PATH_WIN"
      else
        # default to repo-level config in Windows format
        FABRIC_CFG_PATH_WIN=$(cygpath -w "${TEST_NETWORK_HOME}/../config" 2>/dev/null || echo "${PWD%/}/../config")
        export FABRIC_CFG_PATH="$FABRIC_CFG_PATH_WIN"
      fi
      peer channel fetch config "$CONFIG_BLOCK_PB_WIN" -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL --tls --cafile "$ORDERER_CA_WIN"
    else
      # cygpath not available — build Windows-style paths from POSIX using pwd -W
      PWD_WIN=$(pwd -W)
      POSIX_PREFIX="$TEST_NETWORK_HOME"
      WIN_PREFIX="$PWD_WIN"
      ORDERER_CA_WIN="${ORDERER_CA/#$POSIX_PREFIX/$WIN_PREFIX}"
      CONFIG_BLOCK_PB_WIN="${TEST_NETWORK_HOME}/channel-artifacts/config_block.pb"
      CONFIG_BLOCK_PB_WIN="${CONFIG_BLOCK_PB_WIN/#$POSIX_PREFIX/$WIN_PREFIX}"
      CONFIG_BLOCK_JSON_WIN="${TEST_NETWORK_HOME}/channel-artifacts/config_block.json"
      CONFIG_BLOCK_JSON_WIN="${CONFIG_BLOCK_JSON_WIN/#$POSIX_PREFIX/$WIN_PREFIX}"
      OUTPUT_WIN="${OUTPUT/#$POSIX_PREFIX/$WIN_PREFIX}"
      # Ensure FABRIC_CFG_PATH is Windows-style
      if [ -n "$FABRIC_CFG_PATH" ]; then
        FABRIC_CFG_PATH_WIN="${FABRIC_CFG_PATH/#$POSIX_PREFIX/$WIN_PREFIX}"
        export FABRIC_CFG_PATH="$FABRIC_CFG_PATH_WIN"
      else
        FABRIC_CFG_PATH_WIN="${TEST_NETWORK_HOME}/../config"
        FABRIC_CFG_PATH_WIN="${FABRIC_CFG_PATH_WIN/#$POSIX_PREFIX/$WIN_PREFIX}"
        export FABRIC_CFG_PATH="$FABRIC_CFG_PATH_WIN"
      fi
      peer channel fetch config "$CONFIG_BLOCK_PB_WIN" -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL --tls --cafile "$ORDERER_CA_WIN"
    fi
  else
    peer channel fetch config ${TEST_NETWORK_HOME}/channel-artifacts/config_block.pb -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL --tls --cafile "$ORDERER_CA"
  fi
  { set +x; } 2>/dev/null

  infoln "Decoding config block to JSON and isolating config to ${OUTPUT}"
  set -x
  if uname | grep -i mingw > /dev/null 2>&1; then
    if command -v cygpath > /dev/null 2>&1; then
      # Use Windows-style paths for configtxlator and jq if available
      configtxlator proto_decode --input "${CONFIG_BLOCK_PB_WIN}" --type common.Block --output "${CONFIG_BLOCK_JSON_WIN}"
      jq .data.data[0].payload.data.config "${CONFIG_BLOCK_JSON_WIN}" >"${OUTPUT_WIN}"
    else
      configtxlator proto_decode --input ${TEST_NETWORK_HOME}/channel-artifacts/config_block.pb --type common.Block --output ${TEST_NETWORK_HOME}/channel-artifacts/config_block.json
      jq .data.data[0].payload.data.config ${TEST_NETWORK_HOME}/channel-artifacts/config_block.json >"${OUTPUT}"
    fi
  else
    configtxlator proto_decode --input ${TEST_NETWORK_HOME}/channel-artifacts/config_block.pb --type common.Block --output ${TEST_NETWORK_HOME}/channel-artifacts/config_block.json
    jq .data.data[0].payload.data.config ${TEST_NETWORK_HOME}/channel-artifacts/config_block.json >"${OUTPUT}"
  fi
  res=$?
  { set +x; } 2>/dev/null
  verifyResult $res "Failed to parse channel configuration, make sure you have jq installed"
}

# createConfigUpdate <channel_id> <original_config.json> <modified_config.json> <output.pb>
# Takes an original and modified config, and produces the config update tx
# which transitions between the two
# NOTE: this requires jq and configtxlator for execution.
createConfigUpdate() {
  CHANNEL=$1
  ORIGINAL=$2
  MODIFIED=$3
  OUTPUT=$4

  set -x
  configtxlator proto_encode --input "${ORIGINAL}" --type common.Config --output ${TEST_NETWORK_HOME}/channel-artifacts/original_config.pb
  configtxlator proto_encode --input "${MODIFIED}" --type common.Config --output ${TEST_NETWORK_HOME}/channel-artifacts/modified_config.pb
  configtxlator compute_update --channel_id "${CHANNEL}" --original ${TEST_NETWORK_HOME}/channel-artifacts/original_config.pb --updated ${TEST_NETWORK_HOME}/channel-artifacts/modified_config.pb --output ${TEST_NETWORK_HOME}/channel-artifacts/config_update.pb
  compute_rc=$?
  if [ $compute_rc -ne 0 ]; then
    infoln "No differences detected between original and updated config for channel ${CHANNEL}; skipping config update creation"
    { set +x; } 2>/dev/null
    return 0
  fi
  configtxlator proto_decode --input ${TEST_NETWORK_HOME}/channel-artifacts/config_update.pb --type common.ConfigUpdate --output ${TEST_NETWORK_HOME}/channel-artifacts/config_update.json
  echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL'", "type":2}},"data":{"config_update":'$(cat ${TEST_NETWORK_HOME}/channel-artifacts/config_update.json)'}}}' | jq . > ${TEST_NETWORK_HOME}/channel-artifacts/config_update_in_envelope.json
  configtxlator proto_encode --input ${TEST_NETWORK_HOME}/channel-artifacts/config_update_in_envelope.json --type common.Envelope --output "${OUTPUT}"
  { set +x; } 2>/dev/null
}

# signConfigtxAsPeerOrg <org> <configtx.pb>
# Set the peerOrg admin of an org and sign the config update
signConfigtxAsPeerOrg() {
  ORG=$1
  CONFIGTXFILE=$2
  setGlobals $ORG
  set -x
  peer channel signconfigtx -f "${CONFIGTXFILE}"
  { set +x; } 2>/dev/null
}
