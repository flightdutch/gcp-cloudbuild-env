# GCP: build project env by terraform

## 1. GCP: configure Workload Identity Federation (WIF)
      Cloud Shell: check/modify/run: ./script/SA-WIF.config.sh
      Copy Variables: GCP_PROJECT_ID, GCP_SERVICE_ACCOUNT, GCP_WORKLOAD_IDENTITY_PROVIDER

## 2. github: Create WIF-variables
      repo: log-analytics-IaC > Setting > Secret and Variables > Actions
      Create Variables: GCP_PROJECT_ID, GCP_SERVICE_ACCOUNT, GCP_WORKLOAD_IDENTITY_PROVIDER

## 3. github: Check connect github to GCP by WIF
      Manually run workflow: SA-WIF check (./github/workflow/sa-wif.check.yml)

## 4. GCP APIs: Enable
      Cloud Shell: check/modify/run: ./script/GCP-APIs.enable.sh

## 5. GCP: create tfstate-bucket
      Cloud Shell: check/modify/run: ./script/tfstate-bucket.create.sh

## 6. github: create project environment
      Manually run workflow: Terraform Deployment (./github/workflow/env-deploy.yml)
