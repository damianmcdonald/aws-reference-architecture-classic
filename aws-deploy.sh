#!/bin/bash

##############################################################
#                                                            #
# This sample creates the following resources:               #
#                                                            #
# * AWS::AutoScaling::AutoScalingGroup                       #
# * AWS::AutoScaling::LaunchConfiguration                    #      
# * AWS::AutoScaling::ScalingPolicy                          #
# * AWS::CloudTrail::Trail                                   #   
# * AWS::CloudWatch::Alarm                                   #
# * AWS::Config::ConfigRule                                  #
# * AWS::Config::ConfigurationRecorder                       #
# * AWS::Config::DeliveryChannel                             #
# * AWS::EC2::EIP                                            #
# * AWS::EC2::Instance                                       #
# * AWS::EC2::InternetGateway                                #
# * AWS::EC2::NatGateway                                     # 
# * AWS::EC2::NetworkAcl                                     #
# * AWS::EC2::NetworkAclEntry                                #   
# * AWS::EC2::Route                                          #
# * AWS::EC2::RouteTable                                     #   
# * AWS::EC2::SecurityGroup                                  #
# * AWS::EC2::Subnet                                         #
# * AWS::EC2::SubnetNetworkAclAssociation                    # 
# * AWS::EC2::SubnetRouteTableAssociation                    #
# * AWS::EC2::VPC                                            #
# * AWS::EC2::VPCGatewayAttachment                           #
# * AWS::ElasticLoadBalancingV2::Listener                    #
# * AWS::ElasticLoadBalancingV2::LoadBalancer                #    
# * AWS::ElasticLoadBalancingV2::TargetGroup                 #
# * AWS::IAM::InstanceProfile                                #
# * AWS::IAM::Role                                           # 
# * AWS::Logs::LogGroup                                      #
# * AWS::RDS::DBInstance                                     # 
# * AWS::RDS::DBSubnetGroup                                  #
# * AWS::S3::Bucket                                          # 
# * AWS::S3::BucketPolicy                                    #
# * AWS::SNS::Topic                                          #  
# * AWS::SNS::TopicPolicy                                    # 
#                                                            #
##############################################################

# Colors
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT_GRAY='\033[0;37m'
DARK_GRAY='\033[1;30m'
LIGHT_RED='\033[1;31m'
LIGHT_GREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHT_BLUE='\033[1;34m'
LIGHT_PURPLE='\033[1;35m'
LIGHT_CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Global variable declarations
PROJECT_DIR=$PWD
AWS_PROFILE=<!-- ADD_YOUR_AWS_CLI_PROFILE_HERE -->
AWS_REGION=$(aws configure get region --output text --profile ${AWS_PROFILE})
IAM_CAPABILITIES=CAPABILITY_IAM
STACK_NAME=aws-reference-classic
CFN_STACK_TEMPLATE=stack-template.yml
UNDEPLOY_FILE=aws-undeploy.sh

###########################################################
#                                                         #
#  Validate the CloudFormation templates                  #
#                                                         #
###########################################################

echo -e "[${LIGHT_BLUE}INFO${NC}] Validating CloudFormation template ${YELLOW}$CFN_STACK_TEMPLATE${NC}.";
cat ${CFN_STACK_TEMPLATE} | xargs -0 aws cloudformation validate-template --profile ${AWS_PROFILE} --template-body

# assign the exit code to a variable
CFN_STACK_TEMPLATE_VALIDAION_CODE="$?"

# check the exit code, 255 means the CloudFormation template was not valid
if [ $CFN_STACK_TEMPLATE_VALIDAION_CODE != "0" ]; then
    echo -e "[${RED}FATAL${NC}] CloudFormation template ${YELLOW}$CFN_STACK_TEMPLATE${NC} failed validation with non zero exit code ${YELLOW}$CFN_STACK_TEMPLATE_VALIDAION_CODE${NC}. Exiting.";
    exit 999;
fi

echo -e "[${GREEN}SUCCESS${NC}] CloudFormation template ${YELLOW}$CFN_STACK_TEMPLATE${NC} is valid.";

###########################################################
#                                                         #
#  Execute the CloudFormation templates                   #
#                                                         #
###########################################################

echo -e "[${LIGHT_BLUE}INFO${NC}] Exectuing the CloudFormation template ${YELLOW}$CFN_STACK_TEMPLATE${NC}.";
aws cloudformation create-stack \
	--template-body file://${CFN_STACK_TEMPLATE} \
	--stack-name ${STACK_NAME} \
	--capabilities ${IAM_CAPABILITIES} \
	--profile ${AWS_PROFILE}

echo -e "[${LIGHT_BLUE}INFO${NC}] Waiting for the CloudFormation template ${YELLOW}$CFN_STACK_TEMPLATE${NC} to complete.";
aws cloudformation wait stack-create-complete --stack-name ${STACK_NAME} --profile ${AWS_PROFILE}

###########################################################
#                                                         #
# Undeployment file creation                              #
#                                                         #
###########################################################

# delete any previous instance of undeploy.sh
if [ -f "$UNDEPLOY_FILE" ]; then
    rm $UNDEPLOY_FILE
fi

cat > $UNDEPLOY_FILE <<EOF
#!/bin/bash

# Colors
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT_GRAY='\033[0;37m'
DARK_GRAY='\033[1;30m'
LIGHT_RED='\033[1;31m'
LIGHT_GREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHT_BLUE='\033[1;34m'
LIGHT_PURPLE='\033[1;35m'
LIGHT_CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

echo -e "[${LIGHT_BLUE}INFO${NC}] Terminating cloudformation stack ${YELLOW}${STACK_NAME}${NC} ....";
aws cloudformation delete-stack --stack-name ${STACK_NAME} --profile ${AWS_PROFILE}

echo -e "[${LIGHT_BLUE}INFO${NC}] Waiting for the deletion of cloudformation stack ${YELLOW}${STACK_NAME}${NC} ....";
aws cloudformation wait stack-delete-complete --stack-name ${STACK_NAME} --profile ${AWS_PROFILE}

aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --profile ${AWS_PROFILE}
EOF

chmod +x $UNDEPLOY_FILE