#!/bin/bash

# Setup the console repo for running the OCP console UI e2e tests
CONSOLE_REPO="https://github.com/openshift/console"
HOSTDIR=/host
CONSOLEDIR=/root/console

# if /host is not exists, create the /host directory
if [ ! -d $HOSTDIR ]; 
then
  mkdir $HOSTDIR
fi

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

# create console tar gzip
tar -czf console-built.tgz $CONSOLEDIR
cp console-built.tgz $HOSTDIR 

# Extract the input parameters for console e2e test run
echo "Step-2: Setting the input params for running the console UI e2e tests"
echo ""
APIURL=$(oc whoami --show-server)
echo "Cluster server URL: ${APIURL}"
echo ""
# Extract the password
scp -i ${WORKSPACE}/deploy/id_rsa -o StrictHostKeyChecking=no root@${BASTION_IP}:/root/openstack-upi/auth/kubeadmin-password ~/.kube
KUBEADPASSWD=$(cat ~/.kube/kubeadmin-password)
echo "Kubeadmin password: ${KUBEADPASSWD}"
echo ""

# Copy the kubeconfig to the $HOSTDIR/ path
scp -i ${WORKSPACE}/deploy/id_rsa -o StrictHostKeyChecking=no root@${BASTION_IP}:/root/openstack-upi/auth/kubeconfig $HOSTDIR 

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
sed -i 's/htpasswd_username: ""/htpasswd_username: '${HTPASS_USER}'/g' all.yaml
sed -i 's/htpasswd_password: ""/htpasswd_password: '${HTPASS_PASSWD}'/g' all.yaml
sed -i 's/htpasswd_user_role: ""/htpasswd_user_role: "self-provisioner"/g' all.yaml
sed -i "s/localhost/${BASTION_IP}/g" inventory
ansible-playbook  -i inventory -e @all.yaml playbooks/main.yml
echo ""
if [ $? -ne 0 ]; then
  echo "Error during creating a htpasswd_identity_provider user, Exiting ..........."
  exit $?
fi

# create a input.json file
echo "input.json params file: "

cat > $HOSTDIR/input.json <<EOF
{
  "apiurl": "${APIURL}",
  "password": "${KUBEADPASSWD}",
  "idp": "${IDP_NAME}",
  "idp_user": "${HTPASS_USER}",
  "idp_password": "${HTPASS_PASSWD}",
  "driver": "${DRIVER}",
  "suite": "${SUITE2RUN}",
  "browser": "electron",
  "jtimeout": 180000,
  "retries": "${RETRIES}"
}
EOF

cat $HOSTDIR/input.json
echo ""

# Add cluster host entry to /etc/hosts file
OCP_ROUTES=$(oc get routes -A --no-headers | awk '{ print $2 }')
CLUSTER_HOST_ENTRY=${BASTION_IP}" "${OCP_ROUTES}

# Append the cluster host entry to /etc/hosts file
echo "Step-3: Adding cluster host entry to /etc/hosts file ..."
echo $CLUSTER_HOST_ENTRY | tee -a /etc/hosts

# Trigger the console-e2e.sh from the ${WORKSPACE}/scripts/ path
echo "Step-4: Trigger the /console-e2e.sh to run console UI e2e tests:"
source ${WORKSPACE}/scripts/console-e2e/console-e2e.sh

