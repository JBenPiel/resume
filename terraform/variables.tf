variable "prefix" {
  default = "jordan"
}

variable "project" {
  default = "resume"
}

variable "contact" {
  default = "jordan@piel.vip"
}

variable "container_insights" {
  description = "Toggle ECS Container Insights on the cluster"
  default     = "disabled"
}

variable "ecr_image_resume" {
  description = "ECR image for Resume"
  default     = "public.ecr.aws/e7k4f6o3/jordan-resume:latest"
}

variable "dns_zone_name" {
  description = "Domain name"
  default     = "piel.vip"
}

variable "subdomain" {
  description = "Subdomain per environment"
  type        = map(string)
  default = {
    prod  = "jordan."
    stage = "jordan-stage."
  }
}
