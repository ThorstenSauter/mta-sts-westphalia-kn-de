module "mta_sts_westphalia_kn_de" {
  source                    = "github.com/ThorstenSauter/mta-sts-cloudflare-azure-static-web-app?ref=3.0.0"
  domain                    = "westphalia-kn.de"
  azure_location            = var.location
  azure_resource_group_name = "rg-mta-sts-westphalia-kn-de-prod-001"
  azure_static_web_app_name = "stapp-mta-sts-westphalia-kn-de-prod-01"
  azure_tags                = var.tags
  mta_sts_mode              = "enforce"
  mx_hosts = [
    "westphaliakn-de02e.d-v1.mx.microsoft"
  ]
  rua = [
    "mailto:tls-report@westphalia-kn.de"
  ]
}
