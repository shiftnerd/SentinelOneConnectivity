Function Test-SOConnectivity {
    <#
    .SYNOPSIS
        This script automates the steps outlined at: https://help.redcanary.com/hc/en-us/articles/5133477562007-SentinelOne-Agent-is-Offline-Windows- for troubleshooting SentinelOne connectivity issues

     
    .EXAMPLE
        Test-SOConnectivity -purl usea1-redbird.sentinelone.net
    #>
     
        [CmdletBinding()]
        param(
            [Parameter(
                Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true,
                Position = 0
                )]
            [string[]]  $purl
        )
     
        BEGIN {
            Resolve-DnsName -Name $purl
            Test-NetConnection -Port 443 -ComputerName $purl -InformationLevel Detailed
            $SentinelAgent = Get-Service SentinelAgent
            $SentinelStatic = Get-Service SentinelStaticEngine
            $SentinelFolder = Get-ChildItem "C:\Program Files\SentinelOne\Sentinel Agent*"
            $SentinelCTL = $SentinelFolder.FullName + "\sentinelctl.exe"
        }
     
        PROCESS {
            try {
                Resolve-DnsName $purl -Server -ErrorAction Stop
                }
                catch {
                  Write-Error -Message “DNS lookup for provided portal failed. It's always DNS.” -ErrorAction Stop
                }
            if (-not(Test-Path -Path $$SentinelCtl -PathType Leaf)) {
                Write-Error 'The sentinelctl.exe file does not exist, usually this means an uninstall failed or a corruption, SentinelSweeper is advised. Contact SentinelOne support.' -ErrorAction Stop
            }else { Write-output "SentinelCTL.exe check passed - continuing checks"}
            Write-outsput "The status of the SentinelAgent service is $SentinelAgent.Status"
            Write-outsput "The status of the SentinelStatic service is $SentinelStatic.Status"
            & $SentinelCTL config server.mgmtServer
            & $SentinelCTL config server.site
        }
     
        END {}
    }
