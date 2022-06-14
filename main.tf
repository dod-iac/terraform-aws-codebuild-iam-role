/**
 * ## Usage
 *
 * Creates an IAM role for use as a CodeBuild service role.
 *
 * ```hcl
 * module "codebuild_iam_role" {
 *   source = "dod-iac/codebuild-iam-role/aws"
 *
 *   name       = format("app-%s-codebuild-iam-role-%s", var.application, var.environment)
 *   subnet_ids = ["*"]
 *   vpc_ids    = ["*"]
 *   tags       = {
 *     Application = var.application
 *     Environment = var.environment
 *     Automation  = "Terraform"
 *   }
 * }
 * ```
 *
 *
 * ## Terraform Version
 *
 * Terraform 0.13. Pin module version to ~> 1.0.0 . Submit pull-requests to main branch.
 *
 * Terraform 0.11 and 0.12 are not supported.
 *
 * ## License
 *
 * This project constitutes a work of the United States Government and is not subject to domestic copyright protection under 17 USC § 105.  However, because the project utilizes code licensed from contributors and other third parties, it therefore is licensed under the MIT License.  See LICENSE file for more information.
 */

data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_vpc" "main" {
  for_each = contains(var.vpc_ids, "*") ? [] : toset(var.vpc_ids)
  id       = each.value
}

data "aws_subnet" "main" {
  for_each = contains(var.subnet_ids, "*") ? [] : toset(var.subnet_ids)
  id       = each.value
}

#
# IAM
#

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "codebuild.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "main" {
  name               = var.name
  assume_role_policy = length(var.assume_role_policy) > 0 ? var.assume_role_policy : data.aws_iam_policy_document.assume_role_policy.json
  tags               = var.tags
}

data "aws_iam_policy_document" "main" {
  statement {
    sid = "AllowDescribeVPC"
    actions = [
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
  # AWS API does not allow condition keys to limit CreateNetworkInterface action
  statement {
    sid = "AllowCreateNetworkInterface"
    actions = [
      "ec2:CreateNetworkInterface"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    sid = "AllowCreateNetworkInterfacePermission"
    actions = [
      "ec2:CreateNetworkInterfacePermission"
    ]
    effect = "Allow"
    resources = [format(
      "arn:%s:ec2:%s:%s:network-interface/*",
      data.aws_partition.current.partition,
      data.aws_region.current.name,
      data.aws_caller_identity.current.account_id
    )]
    condition {
      test     = "StringEquals"
      variable = "ec2:AuthorizedService"
      values   = ["codebuild.amazonaws.com"]
    }
    dynamic "condition" {
      for_each = contains(var.vpc_ids, "*") ? [] : [1]
      content {
        test     = "StringEquals"
        variable = "ec2:Vpc"
        values   = [for v in data.aws_vpc.main : v.arn]
      }
    }
    dynamic "condition" {
      for_each = contains(var.subnet_ids, "*") ? [] : [1]
      content {
        test     = "StringEquals"
        variable = "ec2:Subnet"
        values   = [for s in data.aws_subnet.main : s.arn]
      }
    }
  }
  statement {
    sid = "AllowCloudwatch"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "main" {
  name        = length(var.policy_name) > 0 ? var.policy_name : format("%s-policy", var.name)
  description = length(var.policy_description) > 0 ? var.policy_description : format("The policy for %s.", var.name)
  policy      = data.aws_iam_policy_document.main.json
}

resource "aws_iam_role_policy_attachment" "main" {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.main.arn
}
