## Build a Serverless Personal Portfolio Website

## Project Description
![](https://github.com/kurokood/cloud_resume_challenge/blob/master/site-sc.png)

This portfolio site is inspired by the concepts of the Cloud Resume Challenge by Forrest Brazeal. It demonstrates a foundational understanding of serverless architecture through a practical, hands-on project. The system architecture is illustrated below.

In this project, I provisioned a personal static portfolio site hosted on Amazon S3, integrated with Amazon CloudFront for content delivery and a custom domain managed via Route 53. The site also features a visitor counter implemented using API Gateway, an AWS Lambda function, and Amazon DynamoDB for storing visit data.

NOTE: I provisioned the entire infrastructure using Infrastructure as Code (IaC) with Terraform.

You can use the information and instructions below to replicate this project and gain hands-on experience with core Terraform and AWS concepts.
Happy learning! ☁️

## Architectural Diagram

![](https://github.com/kurokood/cloud_resume_challenge/blob/master/cloud-resume-challenge.png)

## Components
| Feature               | Description                                                                 |
|------------------------|-----------------------------------------------------------------------------|
| Route 53       | Static resume site hosted on AWS S3 with CloudFront CDN                    |
| CloudFront          | Managed with Route 53 and secured with HTTPS                               |
| S3        | Implemented with API Gateway, Lambda (Python), and DynamoDB                |
| API Gateway | Entire AWS setup managed using Terraform                                   |
| Lambda Function        | Automated deployments via GitHub Actions                                   |
| DynamoDB Table       | Automated deployments via GitHub Actions                                   |

## Key Takeaways:
This project serves as a solid foundation for gaining hands-on experience with serverless computing and AWS services. Below is a detailed overview of the key takeaways:
- Built and deployed a serverless, cloud-native personal resume website.
- Gained hands-on experience with AWS core services like S3, CloudFront, Route 53, Lambda, API Gateway, DynamoDB, IAM, and more.
- Connected a frontend to a backend using API Gateway + Lambda + DynamoDB to track site visits in real time.
- Applied Infrastructure as Code (IaC) using Terraform to manage and provision AWS resources efficiently.
- Integrated CI/CD workflows with GitHub Actions to automate testing and deployments.
- Strengthened understanding of cloud architecture, automation, and scalability principles.
