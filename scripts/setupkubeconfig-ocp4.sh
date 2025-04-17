#!/bin/bash -x
    echo "Capturing the System Information"
    if [ -d ${WORKSPACE}/deploy ];then
        cd ${WORKSPACE}/deploy
    else
        exit 1 
    fi
    # Capturing Terraform template
    if [ ! -z "${BASTION_IP}" ]; then
        ssh -q -i id_rsa -o StrictHostKeyChecking=no root@${BASTION_IP} exit
        rc=$?
        if [ $? -eq 0 ] ; then
            rm -rf ~/.kube
            mkdir ~/.kube
            scp -i id_rsa -o StrictHostKeyChecking=no root@${BASTION_IP}:"${KUBECONFIG_PATH:-/root/openstack-upi/auth/kubeconfig}" ~/.kube/config
            if [ ${POWERVS} == "false" ] ; then
                make terraform:output TERRAFORM_DIR=.${TARGET} TERRAFORM_OUTPUT_VAR=etc_hosts_entries >> /etc/hosts
            else
                make $TARGET:output TERRAFORM_OUTPUT_VAR=etc_hosts_entries >> /etc/hosts
            fi
        else
            echo 'Unable to access the cluster. You may delete the VMs manually'
        fi
    else
        echo 'Unable to access the cluster. You may delete the VMs manually'
    fi