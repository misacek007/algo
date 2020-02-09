#!/bin/bash -x

export gcp_service_account_file=$HOME/.gcp/pihole-267016.json.crypt

cat > entrypoint.sh << EOF
#!/bin/bash -x

trap exit ERR

[ -n "\$CONTAINER_GIT_DIR" ]
[ -s "\${GCP_SERVICE_ACCOUNT_FILE}" ]

yum -y install epel-release
yum -y install openssl openssh-clients python36-virtualenv git

python3 -m virtualenv --python="\$(command -v python3)" \${CONTAINER_GIT_DIR}/.env
source \${CONTAINER_GIT_DIR}/.env/bin/activate
python3 -m pip install -U pip virtualenv
python3 -m pip install -r \${CONTAINER_GIT_DIR}/requirements.txt

COMMAND=(
	ansible-playbook \${CONTAINER_GIT_DIR}/main.yml
	-e dns_adblocking=true
	-e do_token=token
	-e gce_credentials_file=\${GCP_SERVICE_ACCOUNT_FILE}
	-e ondemand_cellular=false
	-e ondemand_wifi=false
	-e provider=gce
	-e region=us-west1
	-e server_name=algo
	-e ssh_tunneling=true
	-e store_pki=true
	-vv
)
\${COMMAND[*]}
EOF

export LOCAL_GIT_DIR=${LOCAL_GIT_DIR:-"$(pwd)"}
export CONTAINER_GIT_DIR=/algo
export GCP_SERVICE_ACCOUNT_FILE=${GCP_SERVICE_ACCOUNT_FILE:-"${LOCAL_GIT_DIR}/auth.json"}

[ -d .env ] && rm -rf .env

DOCKER_COMMAND=(
	docker run
	-ti
	--rm
	--name algo-provision
	-v $(pwd):${CONTAINER_GIT_DIR}
	-v ${GCP_SERVICE_ACCOUNT_FILE}:/tmp/gcp.yml
	--entrypoint=${CONTAINER_GIT_DIR}/entrypoint.sh
	--env CONTAINER_GIT_DIR=${CONTAINER_GIT_DIR}
	--env GCP_SERVICE_ACCOUNT_FILE=/tmp/gcp.yml
 	centos:7
)
${DOCKER_COMMAND[*]}


