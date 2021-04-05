![](https://img.shields.io/static/v1?label=terraform&message=0.14.9&color=blue) ![](https://img.shields.io/static/v1?label=aws-provider&message=3.35.0&color=blue) [![fmt](https://github.com/reireias/rails-on-ecs-terraform/workflows/fmt/badge.svg)](https://github.com/reireias/rails-on-ecs-terraform/actions) [![tfsec](https://github.com/reireias/rails-on-ecs-terraform/workflows/tfsec/badge.svg)](https://github.com/reireias/rails-on-ecs-terraform/actions) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# rails-on-ecs-terraform
Terraform Code for Rails on AWS ECS.

Rails Repository: [reireias/rails-on-ecs](https://github.com/reireias/rails-on-ecs)

## Secrets with KMS
- Encrypt with KMS key.
  ```console
  $ aws kms encrypt --key alias/terraform --plaintext "secret_value" --output text --query CiphertextBlob
  ```

- Create `aws_kms_secrets` data resource.
  ```terraform
  locals {
    secrets = {
      foo = "encrypted_value"
    }
  }

  # NOTE: register all secrets
  data "aws_kms_secrets" "secrets" {
    dynamic "secret" {
      for_each = local.secrets

      content {
        name    = secret.key
        payload = secret.value
      }
    }
  }
  ```

- Use decrypted value
  ```terraform
  data.aws_kms_secrets.secrets.plaintext["foo"] # set decrypted value
  ```
