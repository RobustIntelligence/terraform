variable "customer_name" {
  description = "The unique name of the customer."
  type        = string
}

variable "namespace" {
  description = "The namespace the rime helm chart is deployed into."
  type        = string
}

variable "cloudfront_certificate_arn" {
  description = "The ARN of the ACM certificate to use for the CloudFront distribution."
  type        = string
}

variable "hostname_alias" {
  description = "The hostname alias for the CloudFront distribution."
  type        = string
}

variable "dependency_link" {
  description = "Dependency link to the helm release."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the CloudFront distribution."
  type        = map(string)
  default = {
    Environment = "production"
  }
}
