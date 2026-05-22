param(
    [Parameter(Mandatory = $true)]
    [string]$SshKeyPath,

    [string]$Repo = "AIGautam/Billing_Software_System",
    [string]$DatasourceUrl = "jdbc:mariadb://127.0.0.1:3306/billing_app",
    [string]$DatasourceUsername = "root",
    [string]$DatasourcePassword = "change-me",
    [string]$DdlAuto = "update",
    [string]$JwtSecretKey = "",
    [string]$RazorpayKeyId = "",
    [string]$RazorpayKeySecret = "",
    [string]$CorsAllowedOrigins = "http://52.62.111.84",
    [switch]$InstallGitHubCli
)

$ErrorActionPreference = "Stop"

function Get-GitHubCliCommand {
    $command = Get-Command gh -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $knownPath = "C:\Program Files\GitHub CLI\gh.exe"
    if (Test-Path -LiteralPath $knownPath) {
        return $knownPath
    }

    return $null
}

function ConvertFrom-SecureValue {
    param(
        [Parameter(Mandatory = $true)]
        [System.Security.SecureString]$SecureValue
    )

    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureValue)
    try {
        return [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    } finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

$gh = Get-GitHubCliCommand

if ($InstallGitHubCli -and -not $gh) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "winget is not available. Install GitHub CLI manually from https://cli.github.com/, run 'gh auth login', then rerun this script."
    }

    winget install --id GitHub.cli --source winget --accept-package-agreements --accept-source-agreements
    $gh = Get-GitHubCliCommand
}

if (-not $gh) {
    throw "GitHub CLI is not installed. Install it from https://cli.github.com/ or rerun this script with -InstallGitHubCli. Then run 'gh auth login'."
}

& $gh auth status *> $null
if ($LASTEXITCODE -ne 0) {
    throw "GitHub CLI is installed but not authenticated. Run 'gh auth login', then rerun this script."
}

if (-not (Test-Path -LiteralPath $SshKeyPath)) {
    throw "SSH private key file not found: $SshKeyPath"
}

if ([string]::IsNullOrWhiteSpace($JwtSecretKey)) {
    $bytes = New-Object byte[] 48
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $rng.GetBytes($bytes)
        $JwtSecretKey = [Convert]::ToBase64String($bytes)
    } finally {
        $rng.Dispose()
    }
}

if ([string]::IsNullOrWhiteSpace($RazorpayKeyId)) {
    $RazorpayKeyId = Read-Host "Enter Razorpay key id"
}

if ([string]::IsNullOrWhiteSpace($RazorpayKeySecret)) {
    $secureSecret = Read-Host "Enter Razorpay key secret" -AsSecureString
    $RazorpayKeySecret = ConvertFrom-SecureValue -SecureValue $secureSecret
}

function Set-GitHubSecret {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value
    )

    $Value | & $gh secret set $Name --repo $Repo --app actions
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to set GitHub secret: $Name"
    }
}

$privateKey = Get-Content -Raw -LiteralPath $SshKeyPath

Set-GitHubSecret -Name "EC2_SSH_PRIVATE_KEY" -Value $privateKey
Set-GitHubSecret -Name "SPRING_DATASOURCE_PASSWORD" -Value $DatasourcePassword
Set-GitHubSecret -Name "SPRING_JPA_HIBERNATE_DDL_AUTO" -Value $DdlAuto
Set-GitHubSecret -Name "JWT_SECRET_KEY" -Value $JwtSecretKey
Set-GitHubSecret -Name "RAZORPAY_KEY_ID" -Value $RazorpayKeyId
Set-GitHubSecret -Name "RAZORPAY_KEY_SECRET" -Value $RazorpayKeySecret
Set-GitHubSecret -Name "CORS_ALLOWED_ORIGINS" -Value $CorsAllowedOrigins

Write-Host "GitHub Actions secrets were updated for $Repo."
Write-Host "JWT_SECRET_KEY was generated automatically when not provided."
Write-Host "MySQL now runs inside the app container; only the datasource password is needed as a secret."
Write-Host "Uploads are stored locally on EC2; no S3 secrets were set."
