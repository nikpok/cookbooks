﻿<#
.SYNOPSIS

Delete all stacks in a region!

.EXAMPLE


#>
param(
[String]$region="ap-southeast-2"
)
$nextToken = $null
do {
  [Amazon.CloudFormation.Model.StackSummary[]]$stack = Get-CFNStackSummary -Region $region -StackStatusFilter @("CREATE_FAILED", "CREATE_IN_PROGRESS", "UPDATE_IN_PROGRESS", "CREATE_COMPLETE"  ) -NextToken $nextToken
  foreach ( $stackName in $stack.StackName )
  {
    Write-Output "Stack Name = $stackName"
    Remove-CFNStack -Region $region -StackName $StackName -Force
  }
  

  $nextToken = $AWSHistory.LastServiceResponse.NextToken
} while ($nextToken -ne $null)