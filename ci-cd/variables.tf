variable "profile" {}
variable "region" {}
variable "ProjectName" {}
variable "ClusterName" {}                
variable "AppEnvPrefix" {}
variable "RFRedmineImage" {}
variable "AppType" {}
variable "RailsEnv" {}
variable "AppName" {}
variable "DesiredCount" {}
variable "VpcId" {}
variable "RFRedmineContainerCpu" {
    type = number
    default = "0"
}
variable "RFRedmineContainerMemory" {
    type = number
    default = "0"
}
variable "RFRedmineAlbHostHeader" {}
variable "RFRedmineRollingMaxPercent" {}
variable "RFRedmineRollingMinHealthyPercent" {}
variable "RFRedmineHealthCheckPath" {}
variable "AlbListenerArn80"          {}
variable "AlbListenerArn443"             {}
variable "RFRedmineAlbListenerPriority" {}
variable "AwsRegion" {}
variable "SecretId" {}