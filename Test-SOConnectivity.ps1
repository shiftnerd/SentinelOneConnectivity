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
            [string[]]  $purl,
            [Parameter(
                Mandatory = $false,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true,
                Position = 1
                )]
            [string[]]  $sitetoken
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
            $MGMT = & $SentinelCTL config server.mgmtServer
            $SITE = & $SentinelCTL config server.site
            if (!$MGMT) {
                Write-Error -Message "mgmtServer came back null or empty."
                if(!$sitetoken) {
                $sitetoken = Read-Host -Prompt 'Please enter site token so that we can attempt to re-connect.'
                }
                & $SentinelCTL bind {$purl | $sitetoken}
            }
            if (!$SITE) {
                Write-Error -Message "Site came back null or empty."
                if(!$sitetoken) {
                    $sitetoken = Read-Host -Prompt 'Please enter site token so that we can attempt to re-connect.'
                    }
                    & $SentinelCTL bind {$purl | $sitetoken}
            }
        }
     
        END {
            $ConnectionEvents = Get-WinEvent -LogName 'SentinelOne/Operational' | Where-Object {$_.Id -eq 5}
            if(!$ConnectionEvents) {
                Write-Host "No connection issue events found"
        }else{
            Write-Error -Message "Connection issue event logs found"
            Write-Error -Message "Event logs found: $ConnectionEvents" -ErrorActionStop
        }
    }
}
