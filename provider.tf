provider "aws" {
  region = "ap-northeast-1"
}

provider "aws" {
  alias  = "useast1"
  region = "us-east-1"
}
