$csvPath = "C:\Users\xxxxxxx\Downloads\xxxxxxxxx.csv"
$outputPath = "C:\Users\xxxxxx\Downloads\FailedUsers.csv"

$failedUsers = @()

Import-Csv $csvPath | ForEach-Object {
    $name  = $_.name
    $email = $_.email

    if (-not [string]::IsNullOrWhiteSpace($email)) {
        try {
            Add-DistributionGroupMember -Identity "group@xxxxxxx.com" -Member $email -ErrorAction Stop
            Write-Host "SUCCESS: Added $name ($email)"
        }
        catch {
            Write-Warning "FAILED: $name ($email)"

            $failedUsers += [PSCustomObject]@{
                Name  = $name
                Email = $email
                Error = $_.Exception.Message
            }
        }
    }
}

if ($failedUsers.Count -gt 0) {
    $failedUsers | Export-Csv -Path $outputPath -NoTypeInformation
    Write-Host "Failed users exported to $outputPath"
}
else {
    Write-Host "No failures detected."
}