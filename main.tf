provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source        = "github.com/ericdahl/tf-vpc"
  admin_ip_cidr = "${var.admin_cidr}"
}


resource "aws_launch_configuration" "default" {
  image_id      = "ami-14c5486b"
  instance_type = "t2.medium"
  key_name      = "ec2-temp-2017-04-21"
  spot_price    = "0.046400"

  iam_instance_profile = "${aws_iam_instance_profile.ssm.name}"

  security_groups = [
    "${module.vpc.sg_allow_egress}",
    "${module.vpc.sg_allow_22}",
    "${module.vpc.sg_allow_vpc}",
  ]
}

resource "aws_autoscaling_group" "default" {
  launch_configuration = "${aws_launch_configuration.default.name}"
  max_size = 8
  min_size = 8

  availability_zones = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c",
  ]

  vpc_zone_identifier = [
    "${module.vpc.subnet_public1}",
    "${module.vpc.subnet_public2}",
    "${module.vpc.subnet_public3}",
  ]

  tag {
    key = "Name"
    propagate_at_launch = true
    value = "hello-ssm"
  }
}


resource "aws_ssm_document" "ifconfig" {
  name          = "ifconfig"
  document_type = "Command"

  content = <<DOC
  {
    "schemaVersion": "1.2",
    "description": "Check ip configuration of a Linux instance.",
    "parameters": {

    },
    "runtimeConfig": {
      "aws:runShellScript": {
        "properties": [
          {
            "id": "0.aws:runShellScript",
            "runCommand": ["ifconfig"]
          }
        ]
      }
    }
  }
DOC
}

resource "aws_ssm_document" "process_count" {
  name          = "process_count"
  document_type = "Command"
  document_format="YAML"

  content = <<DOC
---
schemaVersion: '2.2'
description: Sample document
mainSteps:
- action: aws:runShellScript
  name: runShellScript
  inputs:
    runCommand:
    - ps auxww | wc -l
DOC
}

resource "aws_ssm_document" "uptime" {
  name          = "uptime"
  document_type = "Command"
  document_format="YAML"

  content = <<DOC
---
schemaVersion: '2.2'
description: Sample document
mainSteps:
- action: aws:runShellScript
  name: runShellScript
  inputs:
    runCommand:
    - uptime
DOC
}
