resource "aws_backup_vault" "main" {
  name = "main-vault"
}

resource "aws_backup_plan" "main" {
  name = "main-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 12 * * ? *)" # Daily at 12 UTC
    lifecycle {
      delete_after = 30 # Keep backups for 30 days
    }
  }
}

resource "aws_backup_selection" "main" {
  iam_role_arn     = aws_iam_role.backup_role.arn
  name             = "daily-backup-selection"
  plan_id          = aws_backup_plan.main.id
  resources        = [aws_instance.frontend[0].arn, aws_instance.backend[0].arn, aws_instance.admin.arn]
}

resource "aws_iam_role" "backup_role" {
  name = "backup-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Principal" : {
        "Service" : "backup.amazonaws.com"
      },
      "Action" : "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}
