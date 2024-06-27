
resource "aws_iam_user" "admin_user" {
  name = "admin-user"
}

resource "aws_iam_access_key" "admin_key" {
  user = aws_iam_user.admin_user.name
}

resource "aws_iam_user_policy" "admin_policy" {
  name   = "admin-policy"
  user   = aws_iam_user.admin_user.name
  policy = file("admin_policy.json") # Create this JSON policy file with appropriate permissions
}
