# tf-aws-vpc
🚧 Terraform plan to bring up an AWS VPC with a public and private subnet in each availability zone 

## Dependencies
* Terraform 0.11.2+ - For installation instructions go [here](https://www.terraform.io/intro/getting-started/install.html). Or you can use a Docker image like this [one](https://hub.docker.com/r/hashicorp/terraform/).
* AWS account  - Free; if you don't have an account you can sign up at https://aws.amazon.com/. In this example we use T2.small instances.

## QuickStart
`git clone git@github.com:nickbatts/tf-aws-vpc && cd tf-aws-vpc`
* change key_name variable to name of your own key
* `terraform plan` - check to make sure there are no mistakes
* `terraform apply` - review and confirm resources to be created
* `terraform destroy` - terminate instances and clean-up resources

## Authors

* Nick Batts

## License

This project is licensed under the terms of the MIT license.