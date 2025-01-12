module "armor_security_policy" {
  source  = "GoogleCloudPlatform/cloud-armor/google"
  version = "~> 4.0"

  project_id                           = var.project_id
  name                                 = "kheops-global-security-policy"
  description                          = "Global Security Policy for Kheops"
  default_rule_action                  = "allow"
  type                                 = "CLOUD_ARMOR"
  layer_7_ddos_defense_enable          = true
  layer_7_ddos_defense_rule_visibility = "STANDARD"

  # Adaptable
  adaptive_protection_auto_deploy = {
    enable   = true
    priority = 100000
    action   = "throttle"

    rate_limit_options = {
      exceed_action                        = "deny(502)"
      rate_limit_http_request_count        = 500
      rate_limit_http_request_interval_sec = 120
      enforce_on_key                       = "IP"
    }
  }

  # Pre-configured WAF Rules

  pre_configured_rules = {

    "sqli_sensitivity_level_4" = {
      action          = "deny(502)"
      priority        = 1
      target_rule_set = "sqli-v33-stable"

      sensitivity_level = 4
      description       = "sqli-v33-stable Sensitivity Level 4 and 2 preconfigured_waf_config_exclusions"
    }

    "xss-stable_level_2_with_exclude" = {
      action                  = "deny(502)"
      priority                = 2
      description             = "XSS Sensitivity Level 2 with excluded rules"
      preview                 = true
      target_rule_set         = "xss-v33-stable"
      sensitivity_level       = 2
      exclude_target_rule_ids = ["owasp-crs-v030301-id941380-xss", "owasp-crs-v030301-id941280-xss"]
    }

    "php-stable_level_0_with_include" = {
      action                  = "deny(502)"
      priority                = 3
      description             = "PHP Sensitivity Level 0 with included rules"
      target_rule_set         = "php-v33-stable"
      include_target_rule_ids = ["owasp-crs-v030301-id933190-php", "owasp-crs-v030301-id933111-php"]
    }

  }

  # Threat Intelligence Rules
  /*
  threat_intelligence_rules = {

    deny_malicious_ips = {
      action      = "deny(502)"
      priority    = 200
      description = "Deny IP addresses known to attack web applications"
      preview     = false
      feed        = "iplist-known-malicious-ips"
      #exclude_ip  = "['47.100.100.100', '47.189.12.139']"
    }

    deny_tor_exit_ips = {
      action      = "deny(502)"
      priority    = 400
      description = "Deny Tor exit nodes IP addresses"
      preview     = false
      feed        = "iplist-tor-exit-nodes"
    }
  }
*/
}
