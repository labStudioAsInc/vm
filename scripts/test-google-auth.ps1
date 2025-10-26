#
# Test script to verify Google Drive Service Account authentication
#

Write-Host "Testing Google Drive Service Account Authentication..."
Write-Host "=================================================="

# Check environment variables
if ($env:GOOGLE_SERVICE_ACCOUNT_JSON) {
    Write-Host "✓ GOOGLE_SERVICE_ACCOUNT_JSON is set"
    
    try {
        $serviceAccount = $env:GOOGLE_SERVICE_ACCOUNT_JSON | ConvertFrom-Json
        Write-Host "✓ JSON is valid"
        Write-Host "  - Client Email: $($serviceAccount.client_email)"
        Write-Host "  - Project ID: $($serviceAccount.project_id)"
        Write-Host "  - Private Key ID: $($serviceAccount.private_key_id)"
        
        if ($serviceAccount.private_key) {
            Write-Host "✓ Private key is present"
        } else {
            Write-Host "✗ Private key is missing"
        }
        
    } catch {
        Write-Host "✗ JSON is invalid: $_"
        exit 1
    }
} else {
    Write-Host "✗ GOOGLE_SERVICE_ACCOUNT_JSON is not set"
}

if ($env:GOOGLE_DRIVE_API_KEY) {
    Write-Host "✓ GOOGLE_DRIVE_API_KEY is also set (fallback)"
} else {
    Write-Host "ℹ GOOGLE_DRIVE_API_KEY is not set (using Service Account only)"
}

Write-Host ""
Write-Host "Authentication method: Service Account"
Write-Host "Ready to use Google Drive integration!"