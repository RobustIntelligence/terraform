variable "secondary_domains" {
  description = "Domains to create/validate acm for."
  type        = list(string)
}

variable "primary_domain" {
  description = "Domain corresponding to primary namespace. Urls will be shorter as they will not include the namespace i.e app.latest.rime.dev vs app.{namespace}-latest.rime.dev"
  type        = string
}

variable "acm_domain" {
  description = "Domain corresponding to acm cert. Must have wildcard access for subdomains."
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources. Tags added to launch configuration or templates override these values for ASG Tags only."
  type        = map(string)
  default     = {}
}
