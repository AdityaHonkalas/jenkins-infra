#!/bin/bash

# Setup the console repo for running the OCP console UI e2e tests
CONSOLE_REPO="https://github.com/openshift/console"
HOSTDIR=/host
CONSOLEDIR=/root/console

# Build the console test code
echo "Step-1: Setting up the console repository"
echo ""
# switch to the root path
cd /root
git clone $CONSOLE_REPO
cd $CONSOLEDIR
git checkout "release-${OCP_RELEASE}"
echo "Building the console code ............"
./build.sh
if [ $? -ne 0 ]; then
    echo "Error while building the console code. Exiting .........."
    exit $?
fi

# create a console tar
tar -czf console-built.tgz $CONSOLEDIR
cp console-built.tgz $HOSTDIR 

# Extract the input parameters for console e2e test run
echo "Step-2: Setting the input params for running the console UI e2e tests"
echo ""
APIURL=$(oc whoami --show-server)
echo "Cluster server URL: ${APIURL}"
echo ""
# Extract the password
scp -i id_rsa -o StrictHostKeyChecking=no  root@${BASTION_IP}:/root/openstack-upi/auth/kubeadmin-password ~/.kube
KUBEADPASSWD=$(cat ~/.kube/kubeadmin-password)
echo "Kubeadmin password: ${KUBEADPASSWD}"
echo ""

# Create a htpasswd user for console multiuser-auth test
IDP_NAME="htpasswd_identity_provider"
HTPASS_USER="user01"
HTPASS_PASSWD="keypass123"
ansible-galaxy collection install community.general #[temp fix]The Ansible playbook fails when a role requires the `make` module or when running all playbooks using `playbooks/main.yaml`
echo "Setting up htpasswd"
git clone https://github.com/ocp-power-automation/ocp4-playbooks-extras
cd ocp4-playbooks-extras
cp examples/inventory inventory
sed -i "s|localhost|${BASTION_IP}|g" inventory
sed -i 's/ansible_connection=local/ansible_connection=ssh/g' inventory
sed -i "s|ssh|ssh ansible_ssh_private_key_file=${WORKSPACE}/deploy/id_rsa|g" inventory
cp examples/all.yaml .
sed -i 's/htpasswd_identity_provider: false/htpasswd_identity_provider: true/g' all.yaml
sed -i 's/htpasswd_username: ""/htpasswd_username: "${HTPASS_USER}"/g' all.yaml
sed -i 's/htpasswd_password: ""/htpasswd_password: "${HTPASS_PASSWD}"/g' all.yaml
sed -i 's/htpasswd_user_role: ""/htpasswd_user_role: "self-provisioner"/g' all.yaml
ansible-playbook  -i inventory -e @all.yaml playbooks/main.yml
echo ""
if [ $? -ne 0 ]; then
  echo "Error during creatign a htpasswd_identity_provider user, Exiting ..........."
  exit $?
fi

# create a input.json file
echo "input.json params file: "

# if /host is not exists, create the /host directory
if [ ! -d $HOSTDIR ]; 
then
  mkdir $HOSTDIR
fi

cat > $HOSTDIR/input.json <<EOF
{
  "apiurl": "${APIURL}",
  "password": "${KUBEADPASSWD}",
  "idp": "${IDP_NAME}",
  "idp_user": "${HTPASS_USER}",
  "idp_password": "${HTPASS_PASSWD}",
  "driver": "${CYPRESS}",
  "suite": "${SUITE2RUN}",
  "browser": "chrome",
  "jtimeout": 180000,
  "retries": "${RETRIES}"
}
EOF

cat $HOSTDIR/input.json
echo ""


# Trigger the console-e2e.sh from the / path
source /console-e2e.sh

# Copy the test output logs and artifacts to the ${WORKSPACE}/deploy
if [ $? -eq 0 ]; then
  echo ""
  echo "Copying the test output results ......"
  
  # Copying the tests artifcts from ${HOSTDIR}
  cp -rf ${HOSTDIR}/* ${WORKSPACE}/deploy
  cp ${HOSTDIR}/input.json ${WORKSPACE}/deploy

fi
