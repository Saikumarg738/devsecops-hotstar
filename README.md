# DevSecOps With Docker Scout Hotstar Clone

#BLOG
https://mrcloudbook.com/devsecops-ci-cd-deploying-a-secure-hotstar-clone-even-if-youre-not-a-pro/

Deploying HOTSTAR using CI / CD DevSecOps
========================================


Step 1: Setting up AWS EC2 Instance
----------------------------------
Creating an EC2 instance t2.large with Ubuntu 24 AMI, t2.large, and 30 GB storage
Assigning an IAM role with Admin access

Step 2: Installation of Required Tools on the Instance
------------------------------------------------------

Docker
Jenkins
Java
SonarQube container
AWS CLI
Kubectl
Terraform

Step 3: Jenkins Job Configuration
-----------------------------------
Creating Jenkins jobs for:
========================
Job 1: Creating an EKS cluster
Job 2: Deploying the Hotstar clone application

Configuring the Jenkins job stages:
-----------------------------------
Sending files to SonarQube for static code analysis
Running npm install
Implementing OWASP for security checks
Installing and running Docker Scout for container security
Scanning files and Docker images with Docker Scout
Building and pushing Docker images
Deploying the application to the EKS cluster

==================================
Process
=================================

Script1 for Java,Jenkins,Docker

vi script1.sh

#!/bin/bash
sudo apt update -y
wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | tee /etc/apt/keyrings/adoptium.asc
echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list
sudo apt update -y
sudo apt install temurin-17-jdk -y
/usr/bin/java --version
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y
sudo apt-get install jenkins -y
sudo systemctl start jenkins

#install docker
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo usermod -aG docker ubuntu
newgrp docker

===========================================

http://ip:8080

Script 2 for Terraform,kubectl,Aws cli

vi script2.sh

#!/bin/bash
#install terraform
sudo apt install wget -y
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

#install Kubectl on Jenkins
sudo apt update
sudo apt install curl -y
curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

#install Aws cli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt-get install unzip -y
unzip awscliv2.zip
sudo ./aws/install

=======================================================

Now Run sonarqube container

sudo chmod 777 /var/run/docker.sock
systemctl daemon-reload
systemctl restart docker.service

docker run -d --name sonar -p 9000:9000 sonarqube:lts-community

http://ip:9000

username:admin, password: admin

Step 3: Jenkins Job Configuration
=================================

Job 1: EKS Provision
-----------------------

First change the bucketname in the backend.tf ( devsecops-hotstar/EKS_TERRAFORM/backend.tf )

Install terraform plugin

let’s find the path to our Terraform (we will use it in the tools section of Terraform)

In EC2 instance run the below command

which terraform 

Now --> Manage Jenkins –> Tools

Terraform --> Name: terraform, uncheck install automatically , install directory = /usr/bin/

Now create a new pipeline job for the Eks provision
------------------------------------------

New Item --> Pipeline --> EKSJOB 

This project is parameterized
Name: action
choices: 
 apply
 destroy

pipeline{
    agent any
    stages {
        stage('Checkout from Git'){
            steps{
                git branch: 'main', url: 'https://github.com/ReyazShaik/devsecops-hotstar.git'
            }
        }
        stage('Terraform version'){
             steps{
                 sh 'terraform --version'
             }
        }
        stage('Terraform init'){
             steps{
                 dir('EKS_TERRAFORM') {
                      sh 'terraform init'
                   }
             }
        }
        stage('Terraform validate'){
             steps{
                 dir('EKS_TERRAFORM') {
                      sh 'terraform validate'
                   }
             }
        }
        stage('Terraform plan'){
             steps{
                 dir('EKS_TERRAFORM') {
                      sh 'terraform plan'
                   }
             }
        }
        stage('Terraform apply/destroy'){
             steps{
                 dir('EKS_TERRAFORM') {
                      sh 'terraform ${action} --auto-approve'
                   }
             }
        }
    }
}


Create a another pipeline Hotstar job
---------------------------------------

Plugins installation & setup (Java, Sonar, Nodejs, owasp, Docker)
-----------------------------------------------------------------

Go to Jenkins dashboard

Manage Jenkins –> Plugins –> Available Plugins

Search for the Below Plugins

Eclipse Temurin installer

Sonarqube Scanner

NodeJs

Owasp Dependency-Check

Docker

Docker Commons

Docker Pipeline

Docker API

Docker-build-step

Goto Manage Jenkins → Tools → 

JDK installations --> Add JDK --> Name: jdk17, remove install oracle and add Install from adoptium.net and select jdk 17.0.12+7 (install automatically)

SonarQube Scanner installations --> Add SonarQube Scanner --> Name=sonar-scanner, install automatically --> version: sonarscanner 6.1 latest

NodeJS installations --> Add NodeJS --> install automatically --> install from nodejs.org -> version nodejs 16.2.0

Dependency-Check installations --> Name = DP-Check --> install automatically --> Add installer --> select GitHub --> latest

Docker installations --> Name = docker --> install automatically --> Add installer --> select docker.com --> latest



Configure Sonar Server in Manage Jenkins
==========================================

Go to your Sonarqube Server. http://ip:9000

Click on Administration → Security → Users → Click on Tokens and Update Token → Give it a name hotstar → and click on Generate Token

squ_bec30b9d455c90b0c0c289d6f17fca11d55832a4

Goto Jenkins Dashboard → Manage Jenkins → Credentials → Add Secret Text.
Kind = Secret Text
Scope = Global
Secret = Paste the sonar key you copied
ID = sonar-token
Desc = sonar-token

Adding sonar server details in Jenkins
---------------------------------

Now, go to Dashboard → Manage Jenkins → System --> SonarQube servers
Name = sonar-server
Server URL = http://35.154.52.225:9000
Server authentication token = sonar-token that you created in credentials

In the Sonarqube Dashboard add a quality gate
------------------------------------------

Administration–> Configuration–>Webhooks --> create 
Name = Jenkins
URL = http://35.154.52.225:8080/sonarqube-webhook/
Secret = empty

Add Docker credentials to the Jenkins to log in and push the image
----------------------------------------------------------------

Manage Jenkins –> Credentials –> global –> add credential

Kind = Username and password
Username= trainerreyaz
password = ****
ID = docker
Desc = docker

Lets create a pipeline to create docker image and containers using real application hotstar
==========================================================================================

Before that install docker scout for security scan.

Docker Scout is a security analysis tool that helps you scan, assess, and remediate vulnerabilities in Docker images. It integrates with Docker Hub and local images to provide insights into software dependencies and security risks.

Use Docker Scout 🐳 if you are a Docker user looking for a fast, easy way to scan images.
Use Trivy 🔍 if you need comprehensive security scanning beyond just Docker images, including containers, Kubernetes, file systems, and Infrastructure as Code.


docker login -u trainerreyaz

curl -sSfL https://raw.githubusercontent.com/docker/scout-cli/main/install.sh | sh -s -- -b /usr/local/bin


 curl -fsSL https://raw.githubusercontent.com/docker/scout-cli/main/install.sh -o install-scout.sh
 sh install-scout.sh

https://docs.docker.com/scout/install/


Create a HOTSTAR Pipeline
-------------------------

pipeline{
    agent any
    tools{
        jdk 'jdk23'
        nodejs 'node23'
    }
    environment {
        SCANNER_HOME=tool 'sonar-scanner'
    }
    stages {
        stage('Checkout from Git'){
            steps{
                git branch: 'main', url: 'https://github.com/ReyazShaik/devsecops-hotstar.git'
            }
        }
        stage("Sonarqube Analysis "){
            steps{
                withSonarQubeEnv('sonar-server') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=hotstar \
                    -Dsonar.projectKey=hotstar'''
                }
            }
        }
        stage("Quality Gate"){
           steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token'
                }
            }
        }
        stage('Install Dependencies') {
            steps {
                sh "npm install"
            }
        }
        stage('OWASP FS SCAN') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
        stage("Docker Build & Push"){
            steps{
                script{
                   withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){
                       sh "docker build -t hotstar ."
                       sh "docker tag hotstar trainerreyaz/hotstar:latest "
                       sh "docker push trainerreyaz/hotstar:latest"
                    }
                }
            }
        }
        stage('Docker Scout Image') {
            steps {
                script{
                   withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){
                       sh 'docker-scout quickview trainerreyaz/hotstar:latest'
                       sh 'docker-scout cves trainerreyaz/hotstar:latest'
                       sh 'docker-scout recommendations trainerreyaz/hotstar:latest'
                   }
                }
            }
        }
        stage("deploy_docker"){
            steps{
                sh "docker run -d --name hotstar -p 3000:3000 trainerreyaz/hotstar:latest"
            }
        }
    }
}



aws eks update-kubeconfig --name EKS_CLUSTER --region ap-south-1

cat .kube/config

save that as secret.txt in local machine

kubectl get nodes

Install Kubernetes Plugin
----------------------

Kubernetes Credentials
Kubernetes Client API
Kubernetes
Kubernetes CLI

goto manage Jenkins –> manage credentials –> Click on Jenkins global –> add credentials

Kind= SEcret File
choose = secret.txt
ID: k8s
desc : k8s


Go to HOTSTAR Pipeline And add the code

pipeline{
    agent any
    tools{
        jdk 'jdk23'
        nodejs 'node23'
    }
    environment {
        SCANNER_HOME=tool 'sonar-scanner'
    }
    stages {
        stage('Checkout from Git'){
            steps{
                git branch: 'main', url: 'https://github.com/ReyazShaik/devsecops-hotstar.git'
            }
        }
        stage("Sonarqube Analysis "){
            steps{
                withSonarQubeEnv('sonar-server') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=hotstar \
                    -Dsonar.projectKey=hotstar'''
                }
            }
        }
        stage("Quality Gate"){
           steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token'
                }
            }
        }
        stage('Install Dependencies') {
            steps {
                sh "npm install"
            }
        }
        stage("Docker Build & Push"){
            steps{
                script{
                   withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){
                       sh "docker build -t hotstar ."
                       sh "docker tag hotstar trainerreyaz/hotstar:latest "
                       sh "docker push trainerreyaz/hotstar:latest"
                    }
                }
            }
        }
        stage('Docker Scout Image') {
            steps {
                script{
                   withDockerRegistry(credentialsId: 'docker', toolName: 'docker'){
                       sh 'docker-scout quickview trainerreyaz/hotstar:latest'
                       sh 'docker-scout cves trainerreyaz/hotstar:latest'
                       sh 'docker-scout recommendations trainerreyaz/hotstar:latest'
                   }
                }
            }
        }
        stage("deploy_docker"){
            steps{
                sh "docker run -d --name hotstar -p 3000:3000 trainerreyaz/hotstar:latest"
            }
        }
        stage('Deploying to kubernetes'){
            steps{
                script{
                    dir('K8S') {
                        withKubeConfig(caCertificate: '', clusterName: '', contextName: '', credentialsId: 'k8s', namespace: '', restrictKubeConfigAccess: false, serverUrl: '') {
                                sh 'kubectl apply -f deployment.yml'
                                sh 'kubectl apply -f service.yml'
                        }   
                    }
                }
            }
        }
    }
}


Once pipeline is successful

 kubectl get all

kubectl get svc -o wide