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
. ${TEST_NETWORK_HOME}/scripts/configUpdate.sh


# NOTE: This requires jq and configtxlator for execution.
createAnchorPeerUpdate() {
  infoln "Fetching channel config for channel $CHANNEL_NAME"
  fetchChannelConfig $ORG $CHANNEL_NAME ${TEST_NETWORK_HOME}/channel-artifacts/${CORE_PEER_LOCALMSPID}config.json

  infoln "Generating anchor peer update transaction for Org${ORG} on channel $CHANNEL_NAME"

  if [ $ORG -eq 1 ]; then
    HOST="peer0.org1.example.com"
    PORT=7051
  elif [ $ORG -eq 2 ]; then
    HOST="peer0.org2.example.com"
    PORT=9051
  elif [ $ORG -eq 3 ]; then
    HOST="peer0.org3.example.com"
    PORT=11051
  else
    errorln "Org${ORG} unknown"
  fi

  set -x
  # Modify the configuration to append the anchor peer 
  jq '.channel_group.groups.Application.groups.'${CORE_PEER_LOCALMSPID}'.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "'$HOST'","port": '$PORT'}]},"version": "0"}}' ${TEST_NETWORK_HOME}/channel-artifacts/${CORE_PEER_LOCALMSPID}config.json > ${TEST_NETWORK_HOME}/channel-artifacts/${CORE_PEER_LOCALMSPID}modified_config.json
  res=$?
  { set +x; } 2>/dev/null
  verifyResult $res "Channel configuration update for anchor peer failed, make sure you have jq installed"
  

  # Compute a config update, based on the differences between 
  # {orgmsp}config.json and {orgmsp}modified_config.json, write
  # it as a transaction to {orgmsp}anchors.tx
  createConfigUpdate ${CHANNEL_NAME} ${TEST_NETWORK_HOME}/channel-artifacts/${CORE_PEER_LOCALMSPID}config.json ${TEST_NETWORK_HOME}/channel-artifacts/${CORE_PEER_LOCALMSPID}modified_config.json ${TEST_NETWORK_HOME}/channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx
}

updateAnchorPeer() {
  peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL_NAME -f ${TEST_NETWORK_HOME}/channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile "$ORDERER_CA" >&log.txt
  res=$?
  cat log.txt
  verifyResult $res "Anchor peer update failed"
  successln "Anchor peer set for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME'"
}

ORG=$1
CHANNEL_NAME=$2

setGlobals $ORG

# If running under Git Bash / MSYS, ensure ORDERER_CA is a Windows-style absolute path
if uname | grep -i mingw > /dev/null 2>&1; then
  if command -v cygpath > /dev/null 2>&1; then
    ORDERER_CA=$(cygpath -w "$ORDERER_CA")
    export ORDERER_CA
  else
    PWD_WIN=$(pwd -W)
    # derive windows path for orderer ca as a fallback
    ORDERER_CA="${PWD_WIN}\\organizations\\ordererOrganizations\\example.com\\tlsca\\tlsca.example.com-cert.pem"
    export ORDERER_CA
  fi
fi

# Remove any stale config update artifacts to avoid applying an old/invalid update
rm -f "${TEST_NETWORK_HOME}/channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx" \
  "${TEST_NETWORK_HOME}/channel-artifacts/config_update.pb" \
  "${TEST_NETWORK_HOME}/channel-artifacts/config_update.json" \
  "${TEST_NETWORK_HOME}/channel-artifacts/config_update_in_envelope.json" \
  "${TEST_NETWORK_HOME}/channel-artifacts/original_config.pb" \
  "${TEST_NETWORK_HOME}/channel-artifacts/modified_config.pb" || true

createAnchorPeerUpdate 
# Only attempt to apply the anchor peer update if a transaction file was created
if [ -f "${TEST_NETWORK_HOME}/channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx" ] && [ -s "${TEST_NETWORK_HOME}/channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx" ]; then
  updateAnchorPeer
else
  infoln "No channel config changes detected for ${CORE_PEER_LOCALMSPID}; skipping anchor peer update"
fi
