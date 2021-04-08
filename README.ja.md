![](https://img.shields.io/static/v1?label=terraform&message=0.14.9&color=blue) ![](https://img.shields.io/static/v1?label=aws-provider&message=3.35.0&color=blue) [![fmt](https://github.com/reireias/rails-on-ecs-terraform/workflows/fmt/badge.svg)](https://github.com/reireias/rails-on-ecs-terraform/actions) [![tfsec](https://github.com/reireias/rails-on-ecs-terraform/workflows/tfsec/badge.svg)](https://github.com/reireias/rails-on-ecs-terraform/actions) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# rails-on-ecs-terraform
Rails on AWS ECS を構築する Terraform の実装です。

**シンプル** かつ **セキュア** なアーキテクチャに仕上げています。

Rails リポジトリ: [reireias/rails-on-ecs](https://github.com/reireias/rails-on-ecs)

## 構成

### 全体概要
![rails-on-ecs-01](https://user-images.githubusercontent.com/24800246/114057770-d7225080-98cd-11eb-8f93-507f6080ccd3.png)

CloudFront, ALB, ECS, Auroraを利用したシンプルなアーキテクチャです。

CloudFrontにはWAFを設定しXSSやSQLi等の攻撃をブロックします。

CloudFront, ALBのドメインはRoute53で管理しています。

いずれもMulti-AZレベルの可用性をもつように設計しているため、任意のAZで障害が発生してもサービスは継続できる構成です。

### ネットワーク
![rails-on-ecs-02](https://user-images.githubusercontent.com/24800246/114059568-7562e600-98cf-11eb-9b85-b5e288dc0b93.png)

VPC内のSubnetは上記のように用途ごとに細かく分けています。

### Security Group
![rails-on-ecs-03](https://user-images.githubusercontent.com/24800246/114063905-0fc52880-98d4-11eb-9159-d9239eb9724e.png)

Security Groupも用途ごとに分けた設計になっています。

Security Group間のインバウンドルールのソースに別Security Groupを指定することで、最低限の通信しか許可していません。

また、VPC Endpointを設定することでインターネットを経由せずにS3やECRと通信できるように設定しています。

### CDパイプライン
![rails-on-ecs-04](https://user-images.githubusercontent.com/24800246/114064398-91b55180-98d4-11eb-995e-33c424d51688.png)

CDパイプラインは上記のようにECRへのイメージプッシュをトリガーに、CodePipelineで実行されます。

ECRへのプッシュをトリガーにすることで、Railsアプリケーション開発者とインフラエンジニアの自然な責任境界を実現できます。

イメージビルドはGitHub Actions側で行います。

`rails db:migrate` をCodeBuildで実行します。

デプロイはCodeDeployを採用しており、全トラフィックを一括で新バージョンに切り替えることで、デプロイ時にassets参照が404エラーにならないように配慮しています。

## Tips

### セキュリティ対策
Well-Architected FrameworkやSecurity Hubによるベストプラクティスなどに従い、下記のセキュリティ対策を実施しています。

- CloudFrontを前段に配置することによるDDoS対策
- WAFのマネージドルールによるXSSやSQLi等の攻撃のブロック
- RDSの暗号化設定
- SSMパラメータストアを利用した秘匿情報の管理
- ECRによる脆弱性スキャン
- [tfsec](https://tfsec.dev/)によるTerraformコード静的解析によるセキュリティ指摘

### ロギング
以下のログ設定を行っています。

可能な限りログは取得するべきです。(このリポジトリではWAFのログは取得していませんが)

- [CloudFront](cloudfront.tf)
- [ALB](alb.tf)
- [VPC Flow Log](vpc.tf)
- [S3 Access Log](s3_codepipeline.tf)

### 証明書とDNSレコード
このリポジトリでは、[route53.tf](route53.tf) の実装のようにRoute53で取得したドメインを利用しています。

もし、ドメインを別の方法で取得している場合でも、Route53から設定できるように移譲するのが良いでしょう。

Route53でドメインを設定できると、[acm.tf](acm.tf) のようにACMの検証などもスムーズに実装できます。

ACM証明書とその検証DNSレコードの実装:
```terraform
resource "aws_acm_certificate" "main" {
  domain_name               = local.domain
  subject_alternative_names = ["*.${local.domain}"]
  validation_method         = "DNS"
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.acm : record.fqdn]
}
```

### カスタムヘッダーによるALBへのリクエストをCloudFront限定にする
CloudFrontで以下のカスタムヘッダーを設定します。

```terraform
resource "aws_cloudfront_distribution" "main" {

  origin {
    custom_header {
      name  = "x-pre-shared-key"
      value = data.aws_kms_secrets.secrets.plaintext["cloudfront_shared_key"]
    }
    # ...
  }
  # ...
}
```

ALBのリスナールールで、上記ヘッダーが付与されたリクエストのみ、ECSへ流すように設定します。

```terraform
resource "aws_lb_listener_rule" "app_from_cloudfront" {
  listener_arn = aws_lb_listener.app.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app["blue"].arn
  }

  condition {
    http_header {
      http_header_name = "x-pre-shared-key"
      values           = [data.aws_kms_secrets.secrets.plaintext["cloudfront_shared_key"]]
    }
  }

  # NOTE: Ignore target group switch
  lifecycle {
    ignore_changes = [action]
  }
}
```

このように設定することで、CloudFrontを経由せずに直接ALBへリクエストする経路を塞ぐことができます。

### CodeDeployによりローリングアップデートを回避する
複数台のサーバーにRailsをローリングアップデートでデプロイすると、一部のjsやcss等のassets系ファイルの参照が404エラーになる瞬間が発生します。

これは、新サーバーからhtmlを取得し、その中のjsを旧サーバーへ取得しにいくと発生します。

この問題を回避する方法は様々ありますが、ここではシンプルにCodeDeployを利用しローリングアップデートを実施しないことで回避しています。

`deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"` を指定することで、全リクエストを同時に新バージョンへ切り替えることができます。

### 初期構築時のダミー用ECSタスク定義
プロダクトの構築初期段階など、まだRailsアプリが用意できていない場合に最低限ヘルスチェックにだけ合格する軽量イメージとそれを利用したECSタスク定義が欲しくなります。

[medpeer/health_check](https://hub.docker.com/r/medpeer/health_check) イメージを使うことで指定したパスのヘルスチェックに合格するだけのECSタスク定義が作成できます。

```terraform
resource "aws_ecs_task_definition" "app" {
  # ...

  # NOTE: Dummy containers for initial.
  container_definitions = <<CONTAINERS
[
  {
    "name": "web",
    "image": "medpeer/health_check:latest",
    "portMappings": [
      {
        "hostPort": 3000,
        "containerPort": 3000
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.app.name}",
        "awslogs-region": "${local.region}",
        "awslogs-stream-prefix": "web"
      }
    },
    "environment": [
      {
        "name": "NGINX_PORT",
        "value": "3000"
      },
      {
        "name": "HEALTH_CHECK_PATH",
        "value": "/health_checks"
      }
    ]
  }
]
CONTAINERS
}
```

### Availability Zoneの繰り返しにはfor_eachを使う
将来、AZが追加されるケースを考慮して、Subnet等AZの数だけ作成するリソースは `for_each` を利用します。

例えばpublic subnetは以下のように作成します。
```terraform
resource "aws_subnet" "public" {
  for_each = local.availability_zones

  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(local.vpc_cidr, 8, local.az_conf[each.key].index)

  tags = {
    Name = "${local.name}-public-${local.az_conf[each.key].short_name}"
  }
}
```

ここでは、以下のように `az_conf` という変数を定義しています。

```terraform
locals {
  az_conf = {
    "ap-northeast-1a" = {
      index      = 1
      short_name = "1a"
    }
    "ap-northeast-1c" = {
      index      = 2
      short_name = "1c"
    }
    "ap-northeast-1d" = {
      index      = 3
      short_name = "1d"
    }
  }
}
```

[cidrsubnet関数](https://www.terraform.io/docs/language/functions/cidrsubnet.html) を利用することで、一定ルールでのCIDRの管理を楽に実現できます。

Subnetのidのリストが欲しい場合は以下のコードで生成できます。

```terraform
values(aws_subnet.public)[*].id
```

### KMSを利用した秘匿情報管理
秘匿情報はKMSで暗号化し、このリポジトリに含めることでシンプルに管理できます。

`aws_kms_secrets` を利用することで、複合はTerraformがplan時apply時に行います。

利用方法は以下のとおりです。

- KMSを使い秘匿情報を暗号化する。.
  ```console
  $ aws kms encrypt --key alias/terraform --plaintext "secret_value" --output text --query CiphertextBlob
  ```

- `aws_kms_secrets` データリソースを作成する。
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

- SSMパラメータストアやDBのパスワード等、復号した値を利用したい部分に以下のコードを記述する。
  ```terraform
  data.aws_kms_secrets.secrets.plaintext["foo"] # set decrypted value
  ```
