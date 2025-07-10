## Build a Serverless Personal Portfolio Website

## Overview
![](https://github.com/kurokood/cloud_resume_challenge/blob/master/site-sc.png)
This portfolio site is inspired by the concepts of the Cloud Resume Challenge by Forrest Brazeal. It demonstrates a foundational understanding of serverless architecture through a practical, hands-on project. The system architecture is illustrated below.

In this project, I provisioned a personal static portfolio site hosted on Amazon S3, integrated with Amazon CloudFront for content delivery and a custom domain managed via Route 53. The site also features a visitor counter implemented using API Gateway, an AWS Lambda function, and Amazon DynamoDB for storing visit data.

NOTE: I provisioned the entire infrastructure using Infrastructure as Code (IaC) with Terraform.

You can use the information and instructions below to replicate this project and gain hands-on experience with core Terraform and AWS concepts.
Happy learning! ☁️

## The Architecture
![](https://github.com/kurokood/cloud_resume_challenge/blob/master/cloud-resume-challenge.png)

## Prerequisites
Ensure the following tools are installed before deploying this project:

## 1. Install Terraform
- Download Terraform from the official site: [Download Terraform](https://www.terraform.io/downloads)
- Follow the installation instructions specific to your operating system.
- Verify installation by running: `terraform -version`

## 2. Install VS Code
- Download and install VS Code from the official site: [Download VS Code](https://code.visualstudio.com/)
- Install Terraform extansion: Search for `Hashicorp Terraform` in the VS Code extensions section.

## 3. Configure AWS CLI
- Install AWS CLI from the official site: [](https://aws.amazon.com/cli/)
- Configure AWS credentials by running this command: `aws configure`
