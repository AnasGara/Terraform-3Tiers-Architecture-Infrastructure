resource "aws_waf_web_acl" "main" {
  name        = "web-acl"
  metric_name = "webACL"
  default_action {
    type = "ALLOW"
  }
}

resource "aws_waf_rule" "sql_injection" {
  name        = "sql-injection"
  metric_name = "SQLInjection"

  predicates {
    data_id = aws_waf_sql_injection_match_set.main.id
    negated = false
    type    = "SQLInjectionMatch"
  }
}

resource "aws_waf_sql_injection_match_set" "main" {
  name = "sql-injection-set"

  sql_injection_match_tuples {
    field_to_match {
      type = "BODY"
    }
    text_transformation = "URL_DECODE"
  }
}

resource "aws_waf_web_acl_association" "main" {
  resource_arn = aws_lb.alb.arn
  web_acl_id   = aws_waf_web_acl.main.id
}
