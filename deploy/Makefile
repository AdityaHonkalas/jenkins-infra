###############################################################################
# Licensed Materials - Property of IBM Copyright IBM Corporation 2017. All Rights Reserved.
# U.S. Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP
# Schedule Contract with IBM Corp.
#
# Contributors:
#  IBM Corporation - initial API and implementation
###############################################################################
SHELL := /bin/bash
TOP := $(BUILD_DIR)
DATE ?= $(shell date +%Y%m%d)
# GITHUB_USER containing '@' char must be escaped with '%40'
GITHUB_USER := $(shell echo $(GITHUB_USER) | sed 's/@/%40/g')
GITHUB_TOKEN ?=

export SELF ?= make
export GIT ?= git
ARTIFACTORY_USER ?=
ARTIFACTORY_TOKEN ?=

TAG ?= latest-$(DATE)-$(TRAVIS_BUILD_NUMBER)

ifeq ($(TARGET),.)
$(error TARGET is not set - this is used to further define TERRAFORM_DIR and TERRAFORM_VARS_FILE)
endif

TERRAFORM_DIR ?=.$(TARGET)
TERRAFORM_VARS_FILE ?= .$(TARGET).tfvars

##---------- SSH specific parameters ---------
SSH := $(shell which ssh)
SSH_KEYGEN := $(shell which ssh-keygen)
SSH_KEY_FILE ?= id_rsa

## -------- PowerVC Specifc parameters --------

AUTH_URL ?=
OS_TENANT_NAME ?= ibm-default
AVAILABILITY_ZONE ?=
OS_IMAGE ?=
NUM_OF_MASTERS ?= 1
NUM_OF_WORKERS ?= 0
OS_NETWORK ?= icp_network4

MASTER_TEMPLATE ?=
MANAGER_TEMPLATE ?=
WORKER_TEMPLATE ?=
include ./makefiles/Makefile.*

# ---------------------------------
## ----- default, init, keys -----
# ---------------------------------

.PHONY: default
default:: init;

.PHONY: init\:
init::
ifndef GITHUB_USER
	$(info GITHUB_USER not defined)
	exit -1
endif
	$(info Using GITHUB_USER=$(GITHUB_USER))
ifndef GITHUB_TOKEN
	$(info GITHUB_TOKEN not defined)
	exit -1
endif

.PHONY: keys\:
## Generate ssh key pair
keys:
	@$(SSH_KEYGEN) -t rsa -b 2048 -f $(SSH_KEY_FILE) -P ""

.PHONY: keys\:clean
## Delete ssh key pair
keys\:clean:
	@$(shell rm -f id_rsa id_rsa.pub)

# ---------------------------------
## ----- openshift4-powervc -----
# ---------------------------------

.PHONY: deploy-openshift4-powervc\:
## Create power build on powervc tenant
deploy-openshift4-powervc: %deploy-openshift4-powervc:
	@$(shell sed -e "s|__OS_AUTH_URL__|$(OS_AUTH_URL)|g" -e "s|__OS_TENANT_NAME__|$(OS_TENANT_NAME)|g" \
        -e "s|__AVAILABILITY_ZONE__|$(AVAILABILITY_ZONE)|g" -e "s|__INSTANCE_NAME__|$(INSTANCE_NAME)|g" -e "s|__NETWORK_TYPE__|$(NETWORK_TYPE)|g" \
        -e "s|__OS_IMAGE__|$(OS_IMAGE)|g" -e "s|__OS_NETWORK__|$(OS_NETWORK)|g" -e "s|__FIPS_COMPLIANT__|$(FIPS_COMPLIANT)|g" \
		-e "s|__NUM_OF_WORKERS__|$(NUM_OF_WORKERS)|g" -e "s|__WORKER_TEMPLATE__|$(WORKER_TEMPLATE)|g"  \
		-e "s|__NUM_OF_MASTERS__|$(NUM_OF_MASTERS)|g" -e "s|__MASTER_TEMPLATE__|$(MASTER_TEMPLATE)|g" \
		-e "s|__SCG_ID__|$(SCG_ID)|g" -e "s|__VOLUME_STORAGE_TEMPLATE__|$(VOLUME_STORAGE_TEMPLATE)|g" \
		-e "s|__SETUP_SQUID_PROXY__|$(SETUP_SQUID_PROXY)|g" -e "s|__PROXY_ADDRESS__|$(PROXY_ADDRESS)|g" \
		-e "s|__BOOTSTRAP_TEMPLATE__|$(BOOTSTRAP_TEMPLATE)|g" -e "s|__BASTION_TEMPLATE__|$(BASTION_TEMPLATE)|g" \
		-e "s|__REDHAT_RELEASE__|$(REDHAT_RELEASE)|g" -e "s|__ENABLE_E2E_TEST__|$(ENABLE_E2E_TEST)|g" \
        -e "s|__REDHAT_USERNAME__|$(REDHAT_USERNAME)|g" -e "s|__REDHAT_PASSWORD__|$(REDHAT_PASSWORD)|g"  \
        -e "s|__OS_USERNAME__|$(OS_USERNAME)|g" -e "s|__OS_PASSWORD__|$(OS_PASSWORD)|g" -e "s|__KDUMP_ENABLE__|$(KDUMP_ENABLE)|g" \
        -e "s|__ARTIFACTORY_USER__|$(ARTIFACTORY_USER)|g" -e "s|__ARTIFACTORY_TOKEN__|$(ARTIFACTORY_TOKEN)|g" \
		-e "s|__BASTION_IMAGE_ID__|$(BASTION_IMAGE_ID)|g" -e "s|__RHCOS_IMAGE_ID__|$(RHCOS_IMAGE_ID)|g" \
		-e "s|__RHEL_USERNAME__|$(RHEL_USERNAME)|g" -e "s|__OPENSHIFT_INSTALL_TARBALL__|$(OPENSHIFT_INSTALL_TARBALL)|g" \
		-e "s|__OPENSHIFT_IMAGE__|$(OPENSHIFT_IMAGE)|g" -e "s|__PULL_SECRET_FILE__|$(PULL_SECRET_FILE)|g" \
		-e "s|__OPENSHIFT_CLIENT_TARBALL__|$(OPENSHIFT_CLIENT_TARBALL)|g" -e "s|__OPENSHIFT_UPGRADE_IMAGE__|$(OPENSHIFT_UPGRADE_IMAGE)|g" \
		-e "s|__CLUSTER_DOMAIN__|$(CLUSTER_DOMAIN)|g" -e "s|__CLUSTER_ID__|$(CLUSTER_ID)|g" -e "s|__STORAGE_TYPE__|$(STORAGE_TYPE)|g" \
		-e "s|__E2E_GIT__|$(E2E_GIT)|g" -e "s|__E2E_BRANCH__|$(E2E_BRANCH)|g"  -e "s|__E2E_EXCLUDE_LIST__|$(E2E_EXCLUDE_LIST)|g"\
		-e "s|__CS_INSTALL__|$(CS_INSTALL)|g" -e "s|__ENABLE_E2E_UPGRADE__|$(ENABLE_E2E_UPGRADE)|g" -e "s|__PRE_KERNEL_OPTIONS__|$(PRE_KERNEL_OPTIONS)|g" \
		-e "s|__GITHUB_USER__|$(GITHUB_USER)|g" -e "s|__GITHUB_TOKEN__|$(GITHUB_TOKEN)|g"  -e "s|__CONNECTION_TIME_OUT__|$(CONNECTION_TIME_OUT)|g"\
		-e "s|__MOUNT_ETCD_RAMDISK__|$(MOUNT_ETCD_RAMDISK)|g" -e "s|__SCALE_NUM_OF_DEPLOYMENTS__|$(SCALE_NUM_OF_DEPLOYMENTS)|g"\
		-e "s|__ENABLE_SCALE_TEST__|$(ENABLE_SCALE_TEST)|g" -e "s|__GOLANG_TARBALL__|$(GOLANG_TARBALL)|g"\
        -e "s|__UPGRADE_VERSION__|$(UPGRADE_VERSION)|g" -e "s|__UPGRADE_PAUSE_TIME__|$(UPGRADE_PAUSE_TIME)|g"\
        -e "s|__UPGRADE_CHANNEL__|$(UPGRADE_CHANNEL)|g" -e "s|__UPGRADE_IMAGE__|$(UPGRADE_IMAGE)|g" -e "s|__QE_ONLY_DISABLE_IMAGE_POLICY__|$(QE_ONLY_DISABLE_IMAGE_POLICY)|g" \
        -e "s|__UPGRADE_DELAY_TIME__|$(UPGRADE_DELAY_TIME)|g" -e "s|__CHRONY_CONFIG__|$(CHRONY_CONFIG)|g"\
        -e "s|__INSTALL_PLAYBOOK_REPO__|$(INSTALL_PLAYBOOK_REPO)|g" -e "s|__INSTALL_PLAYBOOK_TAG__|$(INSTALL_PLAYBOOK_TAG)|g"\
        -e "s|__HELPERNODE_REPO__|$(HELPERNODE_REPO)|g" -e "s|__HELPERNODE_TAG__|$(HELPERNODE_TAG)|g"\
        -e "s|__DATA_VOLUME_COUNT__|$(DATA_VOLUME_COUNT)|g" -e "s|__DATA_VOLUME_SIZE__|$(DATA_VOLUME_SIZE)|g" \
        -e "s|__DNS_FORWARDERS__|$(DNS_FORWARDERS)|g" -e "s|__CHRONY_SERVERS__|$(CHRONY_SERVERS)|g" \
        -e "s|__REPO__|$(DEPLOY_REPO)|g" -e "s|__CNI_NETWORK_PROVIDER__|$(CNI_NETWORK_PROVIDER)|g" \
		-e "s|__OCP_RELEASE__|$(OCP_RELEASE)|g" -e "s|__OCP_VERSION__|$(OCP_VERSION)|g" -e "s|__AI_TOKEN__|$(AI_TOKEN)|g" -e "s|__AI_INSTALL_TYPE__|$(AI_INSTALL_TYPE)|g" templates/$(TERRAFORM_VARS_FILE).template > $(TERRAFORM_VARS_FILE))
	@$(SELF) -s deploy:openshift4:powervc OPENSHIFT_POWERVC_DEPLOY_DIR=$(TERRAFORM_DIR) OPENSHIFT_POWERVC_TERRAFORM_VARS_FILE=$(TERRAFORM_VARS_FILE)

.PHONY: deploy-openshift4-powervc\:redeploy
## Re deploy on powervc tenant
deploy-openshift4-powervc\:redeploy:
	@$(SELF) -s deploy:openshift4:powervc:redeploy OPENSHIFT_POWERVC_DEPLOY_DIR=$(TERRAFORM_DIR) OPENSHIFT_POWERVC_TERRAFORM_VARS_FILE=$(TERRAFORM_VARS_FILE)

.PHONY: deploy-openshift4-powervc\:output
## Re deploy on powervc tenant
deploy-openshift4-powervc\:output:
	@$(SELF) -s deploy:openshift4:powervc:output OPENSHIFT_POWERVC_DEPLOY_DIR=$(TERRAFORM_DIR) TERRAFORM_OUTPUT_VAR=$(TERRAFORM_OUTPUT_VAR)

.PHONY: deploy-openshift4-powervc\:clean
## Clean up power-openstack build artifacts
deploy-openshift4-powervc\:clean:
	@$(SELF) -s deploy:openshift4:powervc:clean OPENSHIFT_POWERVC_DEPLOY_DIR=$(TERRAFORM_DIR) OPENSHIFT_POWERVC_TERRAFORM_VARS_FILE=$(TERRAFORM_VARS_FILE)


# ---------------------------------
## ----- openshift4-powervs-script -----
# ---------------------------------

.PHONY: deploy-openshift4-powervs-script\:
## Create power build on powervs tenant
deploy-openshift4-powervs-script: %deploy-openshift4-powervs-script:
	@$(shell sed -e "s|__IBMCLOUD_API_KEY__|$(IBMCLOUD_API_KEY)|g" -e "s|__IBMCLOUD_API_KEY__|$(IBMCLOUD_API_KEY)|g" \
        -e "s|__IBM_CLOUD_REGION__|$(IBM_CLOUD_REGION)|g" -e "s|__IBM_CLOUD_ZONE__|$(IBM_CLOUD_ZONE)|g" \
		-e "s|__BASTION_MEMORY__|$(BASTION_MEMORY)|g" -e "s|__BASTION_PROCESSORS__|$(BASTION_PROCESSORS)|g" \
		-e "s|__BOOTSTRAP_MEMORY__|$(BOOTSTRAP_MEMORY)|g" -e "s|__BOOTSTRAP_PROCESSORS__|$(BOOTSTRAP_PROCESSORS)|g" \
		-e "s|__MASTER_MEMORY__|$(MASTER_MEMORY)|g" -e "s|__MASTER_PROCESSORS__|$(MASTER_PROCESSORS)|g" -e "s|__NUM_OF_MASTERS__|$(NUM_OF_MASTERS)|g" \
		-e "s|__WORKER_MEMORY__|$(WORKER_MEMORY)|g" -e "s|__WORKER_PROCESSORS__|$(WORKER_PROCESSORS)|g" -e "s|__NUM_OF_WORKERS__|$(NUM_OF_WORKERS)|g" -e "s|__DATA_VOLUME_COUNT__|$(DATA_VOLUME_COUNT)|g" -e "s|__DATA_VOLUME_SIZE__|$(DATA_VOLUME_SIZE)|g" \
		-e "s|__BASTION_IMAGE_NAME__|$(BASTION_IMAGE_NAME)|g" -e "s|__RHCOS_IMAGE_NAME__|$(RHCOS_IMAGE_NAME)|g" -e "s|__SYSTEM_TYPE__|$(SYSTEM_TYPE)|g" \
		-e "s|__NETWORK_NAME__|$(NETWORK_NAME)|g" -e "s|__RHEL_USERNAME__|$(RHEL_USERNAME)|g" -e "s|__REDHAT_USERNAME__|$(REDHAT_USERNAME)|g" \
		-e "s|__REDHAT_PASSWORD__|$(REDHAT_PASSWORD)|g" -e "s|__OPENSHIFT_INSTALL_TARBALL__|$(OPENSHIFT_INSTALL_TARBALL)|g" \
		-e "s|__OPENSHIFT_CLIENT_TARBALL__|$(OPENSHIFT_CLIENT_TARBALL)|g" -e "s|__SETUP_SQUID_PROXY__|$(SETUP_SQUID_PROXY)|g" \
		-e "s|__OPENSHIFT_IMAGE__|$(OPENSHIFT_IMAGE)|g" -e "s|__CLUSTER_DOMAIN__|$(CLUSTER_DOMAIN)|g" -e "s|__INSTANCE_NAME__|$(INSTANCE_NAME)|g" \
		-e "s|__ENABLE_LOCAL_REGISTRY__|$(ENABLE_LOCAL_REGISTRY)|g" -e "s|__LOCAL_REGISTRY_IMAGE__|$(LOCAL_REGISTRY_IMAGE)|g" \
		-e "s|__OCP_RELEASE_TAG__|$(OCP_RELEASE_TAG)|g" -e "s|__HELPERNODE_REPO__|$(HELPERNODE_REPO)|g" -e "s|__PULL_SECRET_FILE__|$(PULL_SECRET_FILE)|g" \
		-e "s|__HELPERNODE_TAG__|$(HELPERNODE_TAG)|g" -e "s|__INSTALL_PLAYBOOK_REPO__|$(INSTALL_PLAYBOOK_REPO)|g" \
		-e "s|__INSTALL_PLAYBOOK_TAG__|$(INSTALL_PLAYBOOK_TAG)|g" -e "s|__UPGRADE_IMAGE__|$(UPGRADE_IMAGE)|g" \
		-e "s|__UPGRADE_PAUSE_TIME__|$(UPGRADE_PAUSE_TIME)|g" -e "s|__UPGRADE_DELAY_TIME__|$(UPGRADE_DELAY_TIME)|g" \
		-e "s|__STORAGE_TYPE__|$(STORAGE_TYPE)|g" -e "s|__FIPS_COMPLIANT__|$(FIPS_COMPLIANT)|g" -e "s|__QE_ONLY_DISABLE_IMAGE_POLICY__|$(QE_ONLY_DISABLE_IMAGE_POLICY)|g" -e "s|__PRE_KERNEL_OPTIONS__|$(PRE_KERNEL_OPTIONS)|g" \
        -e "s|__RHEL_SMT__|$(RHEL_SMT)|g" -e "s|__CNI_NETWORK_PROVIDER__|$(CNI_NETWORK_PROVIDER)|g" -e "s|__KDUMP_ENABLE__|$(KDUMP_ENABLE)|g"  \
        -e "s|__SERVICE_INSTANCE_ID__|$(SERVICE_INSTANCE_ID)|g" templates/$(TERRAFORM_VARS_FILE).template > $(TERRAFORM_VARS_FILE))

	@$(SELF) -s deploy:openshift4:powervs:script OPENSHIFT_POWERVS_SCRIPT_DEPLOY_DIR=$(TERRAFORM_DIR) OPENSHIFT_POWERVS_SCRIPT_TERRAFORM_VARS_FILE=$(TERRAFORM_VARS_FILE)

.PHONY: deploy-openshift4-powervs-script\:output
## Clean up power-openstack build artifacts
deploy-openshift4-powervs-script\:output:
	@$(SELF) -s deploy:openshift4:powervs:script:output OPENSHIFT_POWERVS_SCRIPT_DEPLOY_DIR=$(TERRAFORM_DIR) OPENSHIFT_POWERVS_SCRIPT_TERRAFORM_VARS_FILE=$(TERRAFORM_VARS_FILE) TERRAFORM_OUTPUT_VAR=$(TERRAFORM_OUTPUT_VAR)



.PHONY: deploy-openshift4-powervs-script\:clean
## Clean up power-openstack build artifacts
deploy-openshift4-powervs-script\:clean:
	@$(SELF) -s deploy:openshift4:powervs:script:clean OPENSHIFT_POWERVS_SCRIPT_DEPLOY_DIR=$(TERRAFORM_DIR) OPENSHIFT_POWERVS_SCRIPT_TERRAFORM_VARS_FILE=$(TERRAFORM_VARS_FILE)


# ---------------------------------
## ----- openshift4-powervs -----
# ---------------------------------

.PHONY: deploy-openshift4-powervs\:
## Create power build on powervs tenant
deploy-openshift4-powervs: %deploy-openshift4-powervs:
	@$(shell sed -e "s|__IBMCLOUD_API_KEY__|$(IBMCLOUD_API_KEY)|g" -e "s|__IBMCLOUD_API_KEY__|$(IBMCLOUD_API_KEY)|g" \
        -e "s|__IBM_CLOUD_REGION__|$(IBM_CLOUD_REGION)|g" -e "s|__IBM_CLOUD_ZONE__|$(IBM_CLOUD_ZONE)|g" \
		-e "s|__BASTION_MEMORY__|$(BASTION_MEMORY)|g" -e "s|__BASTION_PROCESSORS__|$(BASTION_PROCESSORS)|g" \
		-e "s|__BOOTSTRAP_MEMORY__|$(BOOTSTRAP_MEMORY)|g" -e "s|__BOOTSTRAP_PROCESSORS__|$(BOOTSTRAP_PROCESSORS)|g" \
		-e "s|__MASTER_MEMORY__|$(MASTER_MEMORY)|g" -e "s|__MASTER_PROCESSORS__|$(MASTER_PROCESSORS)|g" -e "s|__NUM_OF_MASTERS__|$(NUM_OF_MASTERS)|g" \
		-e "s|__WORKER_MEMORY__|$(WORKER_MEMORY)|g" -e "s|__WORKER_PROCESSORS__|$(WORKER_PROCESSORS)|g" -e "s|__NUM_OF_WORKERS__|$(NUM_OF_WORKERS)|g" \
		-e "s|__BASTION_IMAGE_NAME__|$(BASTION_IMAGE_NAME)|g" -e "s|__RHCOS_IMAGE_NAME__|$(RHCOS_IMAGE_NAME)|g" -e "s|__SYSTEM_TYPE__|$(SYSTEM_TYPE)|g" \
		-e "s|__NETWORK_NAME__|$(NETWORK_NAME)|g" -e "s|__RHEL_USERNAME__|$(RHEL_USERNAME)|g" -e "s|__REDHAT_USERNAME__|$(REDHAT_USERNAME)|g" \
		-e "s|__REDHAT_PASSWORD__|$(REDHAT_PASSWORD)|g" -e "s|__OPENSHIFT_INSTALL_TARBALL__|$(OPENSHIFT_INSTALL_TARBALL)|g" \
		-e "s|__OPENSHIFT_CLIENT_TARBALL__|$(OPENSHIFT_CLIENT_TARBALL)|g" -e "s|__SETUP_SQUID_PROXY__|$(SETUP_SQUID_PROXY)|g" \
		-e "s|__OPENSHIFT_IMAGE__|$(OPENSHIFT_IMAGE)|g" -e "s|__CLUSTER_DOMAIN__|$(CLUSTER_DOMAIN)|g" -e "s|__INSTANCE_NAME__|$(INSTANCE_NAME)|g" \
		-e "s|__ENABLE_LOCAL_REGISTRY__|$(ENABLE_LOCAL_REGISTRY)|g" -e "s|__LOCAL_REGISTRY_IMAGE__|$(LOCAL_REGISTRY_IMAGE)|g" \
		-e "s|__OCP_RELEASE_TAG__|$(OCP_RELEASE_TAG)|g" -e "s|__HELPERNODE_REPO__|$(HELPERNODE_REPO)|g" -e "s|__FIPS_COMPLIANT__|$(FIPS_COMPLIANT)|g" \
		-e "s|__HELPERNODE_TAG__|$(HELPERNODE_TAG)|g" -e "s|__INSTALL_PLAYBOOK_REPO__|$(INSTALL_PLAYBOOK_REPO)|g" -e "s|__QE_ONLY_DISABLE_IMAGE_POLICY__|$(QE_ONLY_DISABLE_IMAGE_POLICY)|g" \
		-e "s|__INSTALL_PLAYBOOK_TAG__|$(INSTALL_PLAYBOOK_TAG)|g" -e "s|__UPGRADE_IMAGE__|$(UPGRADE_IMAGE)|g"  -e "s|__PRE_KERNEL_OPTIONS__|$(PRE_KERNEL_OPTIONS)|g" \
		-e "s|__UPGRADE_PAUSE_TIME__|$(UPGRADE_PAUSE_TIME)|g" -e "s|__UPGRADE_DELAY_TIME__|$(UPGRADE_DELAY_TIME)|g" \
        -e "s|__RHEL_SMT__|$(RHEL_SMT)|g" -e "s|__PULL_SECRET_FILE__|$(PULL_SECRET_FILE)|g" -e "s|__CNI_NETWORK_PROVIDER__|$(CNI_NETWORK_PROVIDER)|g" \
        -e "s|__SERVICE_INSTANCE_ID__|$(SERVICE_INSTANCE_ID)|g" templates/$(TERRAFORM_VARS_FILE).template > $(TERRAFORM_VARS_FILE))

	@$(SELF) -s deploy:openshift4:powervs OPENSHIFT_POWERVS_DEPLOY_DIR=$(TERRAFORM_DIR) OPENSHIFT_POWERVS_TERRAFORM_VARS_FILE=$(TERRAFORM_VARS_FILE)

.PHONY: deploy-openshift4-powervs\:redeploy
## Re deploy on powervs tenant
deploy-openshift4-powervs\:redeploy:
	@$(SELF) -s deploy:openshift4:powervs:redeploy OPENSHIFT_POWERVS_DEPLOY_DIR=$(TERRAFORM_DIR) OPENSHIFT_POWERVS_TERRAFORM_VARS_FILE=$(TERRAFORM_VARS_FILE)

.PHONY: deploy-openshift4-powervs\:output
## Clean up power-openstack build artifacts
deploy-openshift4-powervs\:output:
	@$(SELF) -s deploy:openshift4:powervs:output OPENSHIFT_POWERVS_DEPLOY_DIR=$(TERRAFORM_DIR) TERRAFORM_OUTPUT_VAR=$(TERRAFORM_OUTPUT_VAR)

.PHONY: deploy-openshift4-powervs\:clean
## Clean up power-openstack build artifacts
deploy-openshift4-powervs\:clean:
	@$(SELF) -s deploy:openshift4:powervs:clean OPENSHIFT_POWERVS_DEPLOY_DIR=$(TERRAFORM_DIR) OPENSHIFT_POWERVS_TERRAFORM_VARS_FILE=$(TERRAFORM_VARS_FILE)

# ---------------------------------
## ----- single-instance-openshift4-powervs -----
# ---------------------------------

.PHONY: deploy-openshift4-powervs-single-instance\:
## Create power build on powervs tenant
deploy-openshift4-powervs-single-instance: %deploy-openshift4-powervs-single-instance:
	@$(shell sed -e "s|__IBMCLOUD_API_KEY__|$(IBMCLOUD_API_KEY)|g" -e "s|__IBMCLOUD_API_KEY__|$(IBMCLOUD_API_KEY)|g" \
        -e "s|__IBM_CLOUD_REGION__|$(IBM_CLOUD_REGION)|g" -e "s|__IBM_CLOUD_ZONE__|$(IBM_CLOUD_ZONE)|g" \
		-e "s|__BASTION_MEMORY__|$(BASTION_MEMORY)|g" -e "s|__BASTION_PROCESSORS__|$(BASTION_PROCESSORS)|g" \
		-e "s|__BASTION_IMAGE_NAME__|$(BASTION_IMAGE_NAME)|g" -e "s|__VM_ID_PREFIX__|$(VM_ID_PREFIX)|g" -e "s|__SYSTEM_TYPE__|$(SYSTEM_TYPE)|g" \
		-e "s|__NETWORK_NAME__|$(NETWORK_NAME)|g" -e "s|__RHEL_USERNAME__|$(RHEL_USERNAME)|g" -e "s|__REDHAT_USERNAME__|$(REDHAT_USERNAME)|g" \
		-e "s|__REDHAT_PASSWORD__|$(REDHAT_PASSWORD)|g" -e "s|__RHEL_SMT__|$(RHEL_SMT)|g" -e "s|__BASTION_HEALTH_STATUS__|$(BASTION_HEALTH_STATUS)|g" \
        -e "s|__SERVICE_INSTANCE_ID__|$(SERVICE_INSTANCE_ID)|g" templates/$(TERRAFORM_VARS_FILE).template > $(TERRAFORM_VARS_FILE))
	@$(SELF) -s deploy:openshift4:powervs:single:instance OPENSHIFT_POWERVS_SINGLE_INSTANCE_DEPLOY_DIR=$(TERRAFORM_DIR) OPENSHIFT_POWERVS_SINGLE_INSTANCE_TERRAFORM_VARS_FILE=$(TERRAFORM_VARS_FILE)

.PHONY: deploy-openshift4-powervs-single-instance\:redeploy
## Re deploy on powervs tenant
deploy-openshift4-powervs-single-instance\:redeploy:
	@$(SELF) -s deploy:openshift4:powervs:single:instance:redeploy OPENSHIFT_POWERVS_SINGLE_INSTANCE_DEPLOY_DIR=$(TERRAFORM_DIR) OPENSHIFT_POWERVS_SINGLE_INSTANCE_TERRAFORM_VARS_FILE=$(TERRAFORM_VARS_FILE)

.PHONY: deploy-openshift4-powervs-single-instance\:output
## output up power-openstack build artifacts
deploy-openshift4-powervs-single-instance\:output:
	@$(SELF) -s deploy:openshift4:powervs:single:instance:output OPENSHIFT_POWERVS_SINGLE_INSTANCE_DEPLOY_DIR=$(TERRAFORM_DIR) TERRAFORM_OUTPUT_VAR=$(TERRAFORM_OUTPUT_VAR)

.PHONY: deploy-openshift4-powervs-single-instance\:clean
## Clean up power-openstack build artifacts
deploy-openshift4-powervs-single-instance\:clean:
	@$(SELF) -s deploy:openshift4:powervs:single:instance:clean OPENSHIFT_POWERVS_SINGLE_INSTANCE_DEPLOY_DIR=$(TERRAFORM_DIR) OPENSHIFT_POWERVS_SINGLE_INSTANCE_TERRAFORM_VARS_FILE=$(TERRAFORM_VARS_FILE)

# -----------------------------------------------
## ----- setup-dependencies, show-env -----
# -----------------------------------------------

.PHONY: setup-dependencies
setup-dependencies:
	@mkdir -p `pwd`/tmp
