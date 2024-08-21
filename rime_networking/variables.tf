variable "domain" {
  description = "Domain to create a cert for. This can also be a wildcard cert. Must be a child of the registered domain."
  type        = string
}

variable "subject_alternative_names" {
  description = "(Optional) Set of domains that should be SANs in the issued certificate."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to add to all resources. Tags added to launch configuration or templates override these values for ASG Tags only."
  type        = map(string)
  default     = {}
}

variable "cross_account" {
  description = "Boolean to enable/disable cross account ACM certificate creation"
  type        = bool
  default     = true
}

variable "rime_deployment" {
  description = "Boolean to enable/disable RIME ACM certificate creation"
  type        = bool
  default     = false
}

variable "fw_deployment" {
  description = "Boolean to enable/disable FW ACM certificate creation"
  type        = bool
  default     = false
}

variable "subdomain_enabled" {
  description = "Boolean to enable/disable subdomain creation. If enabled, the subdomain will be <subdomain>.<domain>, otherwise <domain> will be used."
  type        = bool
  default     = true
}

variable "cloudflare_waf_enabled" {
  description = "Boolean to enable/disable Cloudflare WAF certificate creation"
  type        = bool
  default     = true
}
