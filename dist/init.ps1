

function Search-Dodo {
    param(
        $filter
    )
    $hosts = Get-DodoHosts -scriptname host-status -scriptversion "1.0" | Select lastCheckTimestamp -ExpandProperty additionnalData | select -Property * -ExcludeProperty logs
    $hosts = $hosts | % {
        $h = $_
        $ips = $h.ipaddresses -split ','
        $ips | % {
            $tmp = $h.PSObject.Copy()
            Add-Member -InputObject $tmp  -MemberType NoteProperty -Name ipaddress -Value $_
            $tmp
        }
    }
    return $hosts | ? { $_.computername -like "*$filter*" -or $_.username -like "*$filter*" }
}

Function Get-DodoHosts {
    [cmdletbinding()]
    Param (
        $scriptname,
        $scriptversion
    )

    Try {
        $url = "$DODO_BASE_URL/$scriptname/$scriptversion"
        $request = [System.Net.HttpWebRequest]::Create($url)
        $request.Method = "GET"
        #$request.ContentType = "application/json"
        $state = Invoke-RestMethod -Method Get -Uri $url
        if ($state.status -ne 'success'){ 
            throw "Error reaching url $url $(ConvertTo-JSON $state)"
            return @()
        }
        $clients = $($state.data)
        $res = $clients  | % {
            $clientObj = $_
            $properties = $clientObj.additionnalData | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name
            foreach ($property in $properties){
                $value = ($clientObj.additionnalData | Select -ExpandProperty $property)
                Add-Member -InputObject $clientObj -MemberType NoteProperty -Name $property -Value $value
            }
            $clientObj.ipaddresses = $clientObj.ipaddresses -split ','

            
            $clientObj
        }

        return $res
    }
    Catch {
        write-warning $Error[0]
        return @()
    }
}