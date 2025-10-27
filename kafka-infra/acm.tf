data "aws_route53_zone" "domain" {
  name = var.team_domain
}

locals {
  # FQDN the dashboard will use
  dashboard_host = "kafka-dashboard-${var.team}-${var.environment}.${var.team_domain}"

  # Optionally issue a wildcard for future apps in the same env
  wildcard_host = "*-${var.team}-${var.environment}.${var.team_domain}" # optional
}

resource "aws_acm_certificate" "dashboard" {
  domain_name       = local.dashboard_host
  validation_method = "DNS"
  # Optional SANs (uncomment if you want a wildcard too)
  # subject_alternative_names = [local.wildcard_host]

  lifecycle {
    create_before_destroy = true
  }
}

# Create the Route53 validation records ACM asks for
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.dashboard.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.domain.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

# Tell ACM to finish validation using those DNS records
resource "aws_acm_certificate_validation" "dashboard" {
  certificate_arn         = aws_acm_certificate.dashboard.arn
  validation_record_fqdns = [for r in aws_route53_record.acm_validation : r.fqdn]
}
