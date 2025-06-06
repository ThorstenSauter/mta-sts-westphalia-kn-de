output "deployment_token" {
  description = "The deployment token used to deploy code from CI pipelines."
  value       = module.mta_sts.deployment_token
  sensitive   = true
}
