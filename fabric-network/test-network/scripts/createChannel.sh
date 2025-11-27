#!/usr/bin/env bash

# imports  
. scripts/envVar.sh

CHANNEL_NAME="$1"
DELAY="$2"
MAX_RETRY="$3"
VERBOSE="$4"
BFT="$5"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
: ${VERBOSE:="false"}
: ${BFT:=0}

: ${CONTAINER_CLI:="docker"}
if command -v ${CONTAINER_CLI}-compose > /dev/null 2>&1; then
    : ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI}-compose"}
else
    : ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI} compose"}
fi
infoln "Using ${CONTAINER_CLI} and ${CONTAINER_CLI_COMPOSE}"

if [ ! -d "channel-artifacts" ]; then
	mkdir channel-artifacts
fi

createChannelGenesisBlock() {
  setGlobals 1
	# Prefer configtxgen on PATH, but fall back to the bundled ../bin/configtxgen
	CONFIGTXGEN_BIN="$(which configtxgen 2>/dev/null || true)"
	if [ -z "$CONFIGTXGEN_BIN" ]; then
		CONFIGTXGEN_BIN="${TEST_NETWORK_HOME}/../bin/configtxgen"
	fi
	# On Windows the binary may have a .exe extension; try that if needed
	if [ ! -x "$CONFIGTXGEN_BIN" ]; then
		if [ -x "${CONFIGTXGEN_BIN}.exe" ]; then
			CONFIGTXGEN_BIN="${CONFIGTXGEN_BIN}.exe"
		elif [ -x "${TEST_NETWORK_HOME}/../bin/configtxgen.exe" ]; then
			CONFIGTXGEN_BIN="${TEST_NETWORK_HOME}/../bin/configtxgen.exe"
		fi
	fi
	if [ ! -x "$CONFIGTXGEN_BIN" ]; then
		fatalln "configtxgen tool not found at '$CONFIGTXGEN_BIN'. Ensure binaries are extracted into ../bin or configtxgen is on your PATH."
	fi
	local bft_true=$1

	# If running under Git Bash / MSYS (MINGW), convert FABRIC_CFG_PATH
	# to a Windows-style path so the Windows-native configtxgen.exe can read
	# the config file correctly.
	if uname | grep -i mingw > /dev/null 2>&1; then
		if command -v cygpath > /dev/null 2>&1; then
			FABRIC_CFG_PATH_WIN=$(cygpath -w "$FABRIC_CFG_PATH")
			export FABRIC_CFG_PATH="$FABRIC_CFG_PATH_WIN"
		else
			PWD_WIN=$(pwd -W)
			export FABRIC_CFG_PATH="${PWD_WIN}\\configtx"
		fi
	fi

	# Debug: show resolved FABRIC_CFG_PATH and working directory
	echo "DEBUG: PWD='$(pwd -W 2>/dev/null || pwd)'"
	echo "DEBUG: FABRIC_CFG_PATH='$FABRIC_CFG_PATH'"
	echo "DEBUG: Listing ./configtx (posix)"; ls -la ./configtx || true
	echo "DEBUG: Attempting to list FABRIC_CFG_PATH as posix"; ls -la "$FABRIC_CFG_PATH" 2>/dev/null || true

	set -x

	# Determine which FABRIC_CFG_PATH to pass to configtxgen. If running under
	# MINGW, prefer a Windows-style path so the Windows-native binary can open
	# the config file. Otherwise use the existing FABRIC_CFG_PATH.
	CFG_PATH_FOR_EXEC="$FABRIC_CFG_PATH"
	if uname | grep -i mingw > /dev/null 2>&1; then
	  if command -v cygpath > /dev/null 2>&1; then
	    CFG_PATH_FOR_EXEC=$(cygpath -w "$FABRIC_CFG_PATH")
	  else
	    PWD_WIN=$(pwd -W)
	    CFG_PATH_FOR_EXEC="${PWD_WIN}\\configtx"
	  fi
	fi

	# Run the resolved configtxgen binary with an appropriate FABRIC_CFG_PATH
	echo "DEBUG: Using configtxgen binary: $CONFIGTXGEN_BIN"
	if [ $bft_true -eq 1 ]; then
		FABRIC_CFG_PATH="$CFG_PATH_FOR_EXEC" "$CONFIGTXGEN_BIN" -profile ChannelUsingBFT -outputBlock ./channel-artifacts/${CHANNEL_NAME}.block -channelID $CHANNEL_NAME
	else
		FABRIC_CFG_PATH="$CFG_PATH_FOR_EXEC" "$CONFIGTXGEN_BIN" -profile ChannelUsingRaft -outputBlock ./channel-artifacts/${CHANNEL_NAME}.block -channelID $CHANNEL_NAME
	fi
	res=$?
	{ set +x; } 2>/dev/null
  verifyResult $res "Failed to generate channel configuration transaction..."
}

createChannel() {
	# Poll in case the raft leader is not set yet
	local rc=1
	local COUNTER=1
	local bft_true=$1
	infoln "Adding orderers"
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		set -x
    . scripts/orderer.sh ${CHANNEL_NAME}> /dev/null 2>&1
    if [ $bft_true -eq 1 ]; then
      . scripts/orderer2.sh ${CHANNEL_NAME}> /dev/null 2>&1
      . scripts/orderer3.sh ${CHANNEL_NAME}> /dev/null 2>&1
      . scripts/orderer4.sh ${CHANNEL_NAME}> /dev/null 2>&1
    fi
		res=$?
		{ set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "Channel creation failed"
}

# joinChannel ORG
joinChannel() {
  ORG=$1
	FABRIC_CFG_PATH=$PWD/../config/
	setGlobals $ORG
	# Ensure peer.exe sees Windows-style CORE_PEER_* paths when running under MINGW
	if uname | grep -i mingw > /dev/null 2>&1; then
		if command -v cygpath > /dev/null 2>&1; then
			CORE_PEER_MSPCONFIGPATH=$(cygpath -w "$CORE_PEER_MSPCONFIGPATH")
			CORE_PEER_TLS_ROOTCERT_FILE=$(cygpath -w "$CORE_PEER_TLS_ROOTCERT_FILE")
			export CORE_PEER_MSPCONFIGPATH CORE_PEER_TLS_ROOTCERT_FILE
		else
			PWD_WIN=$(pwd -W)
			# Replace POSIX prefix with Windows prefix when cygpath isn't available
			CORE_PEER_MSPCONFIGPATH="${CORE_PEER_MSPCONFIGPATH/$PWD/$PWD_WIN}"
			CORE_PEER_TLS_ROOTCERT_FILE="${CORE_PEER_TLS_ROOTCERT_FILE/$PWD/$PWD_WIN}"
			export CORE_PEER_MSPCONFIGPATH CORE_PEER_TLS_ROOTCERT_FILE
		fi
	fi
	# Ensure peer.exe sees a Windows-style FABRIC_CFG_PATH under MINGW
	if uname | grep -i mingw > /dev/null 2>&1; then
		if command -v cygpath > /dev/null 2>&1; then
			FABRIC_CFG_PATH_WIN=$(cygpath -w "$FABRIC_CFG_PATH")
			export FABRIC_CFG_PATH="$FABRIC_CFG_PATH_WIN"
		else
			PWD_WIN=$(pwd -W)
			export FABRIC_CFG_PATH="${PWD_WIN}\\..\\config\\"
		fi
	fi
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x
    peer channel join -b $BLOCKFILE >&log.txt
    res=$?
    { set +x; } 2>/dev/null
			# If the join failed, check whether the peer already has the ledger/channel.
			if [ $res -ne 0 ]; then
				if grep -Eiq "already exists|already joined|ledger \[.*\] already exists|already a member" log.txt; then
					infoln "Peer0.org${ORG} already has the channel ledger; treating join as success"
					res=0
				fi
			fi
			# As a fallback, ask the peer for its channel list — if the channel appears,
			# treat the join as successful (covers cases where the peer reports an
			# 'already exists' condition in a different format).
			if [ $res -ne 0 ]; then
				peer channel list >& chlist.txt 2>&1 || true
				if grep -Fq "$CHANNEL_NAME" chlist.txt; then
					infoln "Peer0.org${ORG} already joined channel '$CHANNEL_NAME' (found in channel list); treating join as success"
					res=0
				fi
			fi
			let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "After $MAX_RETRY attempts, peer0.org${ORG} has failed to join channel '$CHANNEL_NAME' "
}

setAnchorPeer() {
  ORG=$1
  . scripts/setAnchorPeer.sh $ORG $CHANNEL_NAME 
}

## Create channel genesis block
FABRIC_CFG_PATH=$PWD/../config/
BLOCKFILE="./channel-artifacts/${CHANNEL_NAME}.block"

infoln "Generating channel genesis block '${CHANNEL_NAME}.block'"
FABRIC_CFG_PATH=${PWD}/configtx
if [ $BFT -eq 1 ]; then
  FABRIC_CFG_PATH=${PWD}/bft-config
fi
createChannelGenesisBlock $BFT


## Create channel
infoln "Creating channel ${CHANNEL_NAME}"
createChannel $BFT
successln "Channel '$CHANNEL_NAME' created"

## Join all the peers to the channel
infoln "Joining org1 peer to the channel..."
joinChannel 1
infoln "Joining org2 peer to the channel..."
joinChannel 2

## Set the anchor peers for each org in the channel
infoln "Setting anchor peer for org1..."
setAnchorPeer 1
infoln "Setting anchor peer for org2..."
setAnchorPeer 2

successln "Channel '$CHANNEL_NAME' joined"
