$csvPath    = "importFile.csv"
$outputPath = "C:\FailedUsers.csv"

$groupName = "(INSERT GROUP NAMe)"

$failedUsers = @()
$successCount = 0
$skippedCount = 0

# Cache group members once
$groupMembers = Get-ADGroupMember $groupName | Select-Object -ExpandProperty DistinguishedName

Import-Csv $csvPath | ForEach-Object {

    $email = $_.email.Trim().ToLower()

    if (-not [string]::IsNullOrWhiteSpace($email)) {
        try {
            # Find user in AD
            $user = Get-ADUser -Filter "mail -eq '$email'" -Properties mail

            if (-not $user) {
                throw "User not found in Active Directory"
            }

            # Already in group → skip silently (no failure)
            if ($groupMembers -contains $user.DistinguishedName) {
                Write-Host "SKIPPED (Already in group): $email" -ForegroundColor Yellow
                $skippedCount++
                return
            }

            # Add to group
            Add-ADGroupMember -Identity $groupName -Members $user -ErrorAction Stop

            Write-Host "SUCCESS: Added $email" -ForegroundColor Green
            $successCount++
        }
        catch {
            Write-Warning "FAILED: $email"

            $failedUsers += [PSCustomObject]@{
                Email     = $email
                Error     = $_.Exception.Message
                Timestamp = Get-Date
            }
        }
    }
}

# Export failures
if ($failedUsers.Count -gt 0) {
    $failedUsers | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8
    Write-Host "Failed users exported to $outputPath" -ForegroundColor Red
}

Write-Host "Summary:"
Write-Host "  Added: $successCount" -ForegroundColor Green
Write-Host "  Skipped (already in group): $skippedCount" -ForegroundColor Yellow
Write-Host "  Failed: $($failedUsers.Count)" -ForegroundColor Red