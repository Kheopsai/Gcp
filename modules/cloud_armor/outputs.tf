output "security_policy" {
  value       = module.armor_security_policy.policy.self_link
  description = "Cloud Armor security policy created"
}

output "policy_name" {
  value       = module.armor_security_policy.policy.name
  description = "Security Policy name"
}
