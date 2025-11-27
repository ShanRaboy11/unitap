#!/usr/bin/env bash


channel_name=$1

# Ensure correct PATH to bundled binaries
export PATH="${ROOTDIR}/../bin:${PWD}/../bin:$PATH"

# Paths to orderer TLS certs (posix)
ORDERER_ADMIN_TLS_SIGN_CERT_POSIX="${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt"
ORDERER_ADMIN_TLS_PRIVATE_KEY_POSIX="${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key"

# Default FABRIC_CFG_PATH to repo config if not set
: ${FABRIC_CFG_PATH:="${PWD}/../config/"}

# If running under Git Bash / MSYS, convert paths to Windows form for Windows-native osnadmin.exe
if uname | grep -i mingw > /dev/null 2>&1; then
	if command -v cygpath > /dev/null 2>&1; then
		FABRIC_CFG_PATH_WIN=$(cygpath -w "$FABRIC_CFG_PATH")
		# Derive a sensible ORDERER_CA_WIN from the repository layout instead of
		# calling cygpath on an empty or unset ORDERER_CA variable.
		ORDERER_CA_WIN=$(cygpath -w "${PWD}/organizations/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem")
		ORDERER_ADMIN_TLS_SIGN_CERT=$(cygpath -w "$ORDERER_ADMIN_TLS_SIGN_CERT_POSIX")
		ORDERER_ADMIN_TLS_PRIVATE_KEY=$(cygpath -w "$ORDERER_ADMIN_TLS_PRIVATE_KEY_POSIX")
	else
		PWD_WIN=$(pwd -W)
		FABRIC_CFG_PATH_WIN="${PWD_WIN}\\..\\config\\"
		ORDERER_CA_WIN="${PWD_WIN}\\organizations\\ordererOrganizations\\example.com\\tlsca\\tlsca.example.com-cert.pem"
		ORDERER_ADMIN_TLS_SIGN_CERT="${PWD_WIN}\\organizations\\ordererOrganizations\\example.com\\orderers\\orderer.example.com\\tls\\server.crt"
		ORDERER_ADMIN_TLS_PRIVATE_KEY="${PWD_WIN}\\organizations\\ordererOrganizations\\example.com\\orderers\\orderer.example.com\\tls\\server.key"
	fi
	export FABRIC_CFG_PATH="${FABRIC_CFG_PATH_WIN}"
	# If ORDERER_CA is set, convert it; otherwise use the derived path.
	if [ -n "$ORDERER_CA" ]; then
		if command -v cygpath > /dev/null 2>&1; then
			ORDERER_CA=$(cygpath -w "$ORDERER_CA")
		fi
	else
		ORDERER_CA="$ORDERER_CA_WIN"
	fi
else
	# Use POSIX paths
	ORDERER_ADMIN_TLS_SIGN_CERT="$ORDERER_ADMIN_TLS_SIGN_CERT_POSIX"
	ORDERER_ADMIN_TLS_PRIVATE_KEY="$ORDERER_ADMIN_TLS_PRIVATE_KEY_POSIX"
fi

# Join the orderer to the channel via osnadmin
osnadmin channel join --channelID "${channel_name}" --config-block ./channel-artifacts/${channel_name}.block -o localhost:7053 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY" >> log.txt 2>&1