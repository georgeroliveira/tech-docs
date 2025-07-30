#Requires -Version 5.1

<#
===========================================================
 Autor:      George Rodrigues de Oliveira
 GitHub:     https://github.com/georgeroliveira
 Licença:    MIT
 Versão:     1.1 - CORRIGIDO
 Data:       2025-07-30
 Descrição:  Conexão ao Cloud SQL com autenticação humana
===========================================================
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ProjetoGCP = "meu-projeto-gcp",

    [Parameter(Mandatory = $false)]
    [string]$InstanciaGCP = "meu-projeto-gcp:regiao:cluster-bd-dev",

    [Parameter(Mandatory = $false)]
    [ValidatePattern('^v\d+\.\d+\.\d+$')]
    [string]$ProxyVersion = "v2.16.0",

    [Parameter(Mandatory = $false)]
    [string]$ProxyDir = (Join-Path $env:USERPROFILE "Documents"),

    [Parameter(Mandatory = $false)]
    [switch]$SkipGCloudInstall
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

try { Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force } catch {}

$Config = @{
    ProxyFileName = "cloud-sql-proxy.exe"
    ProxyTempName = "cloud-sql-proxy.x64.exe"
    ProxyBaseUrl = "https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy"
    GCloudInstallerUrl = "https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe"
    MaxRetries = 3
    RetryDelaySeconds = 5
}

$Paths = @{
    ProxyFinal = Join-Path $ProxyDir $Config.ProxyFileName
    ProxyTemp = Join-Path $ProxyDir $Config.ProxyTempName
    ProxyUrl = "$($Config.ProxyBaseUrl)/$ProxyVersion/$($Config.ProxyTempName)"
    GCloudInstaller = Join-Path $env:TEMP "GoogleCloudSDKInstaller.exe"
}

function Write-ColoredMessage {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $false)][ValidateSet("Info", "Success", "Warning", "Error")][string]$Type = "Info"
    )
    $colorMap = @{ Info = "Cyan"; Success = "Green"; Warning = "Yellow"; Error = "Red" }
    $prefix = "[$($Type.ToUpper())]"
    Write-Host "$prefix $Message" -ForegroundColor $colorMap[$Type]
}

function Test-CommandExists {
    param([Parameter(Mandatory = $true)][string]$CommandName)
    try { $null = Get-Command $CommandName -ErrorAction Stop; return $true }
    catch { return $false }
}

function Invoke-WithRetry {
    param(
        [Parameter(Mandatory = $true)][scriptblock]$ScriptBlock,
        [Parameter(Mandatory = $false)][string]$ActionDescription = "Operação",
        [Parameter(Mandatory = $false)][int]$MaxRetries = $Config.MaxRetries,
        [Parameter(Mandatory = $false)][int]$DelaySeconds = $Config.RetryDelaySeconds
    )
    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            Write-ColoredMessage "Tentativa $i de $MaxRetries - $ActionDescription" -Type Info
            & $ScriptBlock
            return
        } catch {
            Write-ColoredMessage "Tentativa $i falhou - $($_.Exception.Message)" -Type Warning
            if ($i -eq $MaxRetries) {
                Write-ColoredMessage "Todas as tentativas falharam para - $ActionDescription" -Type Error
                throw $_
            }
            Write-ColoredMessage "Aguardando $DelaySeconds segundos antes da próxima tentativa..." -Type Info
            Start-Sleep -Seconds $DelaySeconds
        }
    }
}

function Install-GCloudSDK {
    if (Test-CommandExists "gcloud") {
        Write-ColoredMessage "Google Cloud SDK já está instalado" -Type Success
        return
    }
    if ($SkipGCloudInstall) {
        Write-ColoredMessage "Instalação do gcloud foi pulada conforme solicitado" -Type Warning
        throw "Google Cloud SDK não encontrado e instalação foi pulada"
    }
    
    Write-ColoredMessage "Google Cloud SDK não encontrado. Iniciando instalação..." -Type Info
    
    Invoke-WithRetry -ActionDescription "Instalação do Google Cloud SDK" -ScriptBlock {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $Config.GCloudInstallerUrl -OutFile $Paths.GCloudInstaller -UseBasicParsing -ErrorAction Stop
        $process = Start-Process -FilePath $Paths.GCloudInstaller -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            throw "Instalador falhou com código de saída - $($process.ExitCode)"
        }
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
        
        # Cleanup
        if (Test-Path $Paths.GCloudInstaller) {
            try { Remove-Item $Paths.GCloudInstaller -Force -ErrorAction SilentlyContinue } catch {}
        }
    }
}

function Install-CloudSQLProxy {
    if (Test-Path $Paths.ProxyFinal) {
        try {
            $versionOutput = & $Paths.ProxyFinal --version 2>&1
            Write-ColoredMessage "Cloud SQL Proxy já existe e está funcional - $($Paths.ProxyFinal)" -Type Success
            Write-ColoredMessage "Versão instalada - $versionOutput" -Type Info
            return
        } catch {
            Write-ColoredMessage "Proxy existe mas não é executável. Fazendo re-download..." -Type Warning
            try { Remove-Item $Paths.ProxyFinal -Force -ErrorAction SilentlyContinue } catch {}
        }
    }
    
    Write-ColoredMessage "Instalando Cloud SQL Proxy versão $ProxyVersion..." -Type Info
    
    Invoke-WithRetry -ActionDescription "Download do Cloud SQL Proxy" -ScriptBlock {
        if (-not (Test-Path $ProxyDir)) {
            New-Item -Path $ProxyDir -ItemType Directory -Force | Out-Null
        }
        
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "PowerShell CloudSQL Script")
        
        try {
            $webClient.DownloadFile($Paths.ProxyUrl, $Paths.ProxyTemp)
        } finally { 
            $webClient.Dispose() 
        }
        
        if (-not (Test-Path $Paths.ProxyTemp)) { 
            throw "Falha no download do proxy" 
        }
        
        $fileInfo = Get-Item $Paths.ProxyTemp
        if ($fileInfo.Length -eq 0) { 
            throw "Arquivo baixado está vazio" 
        }
        
        Move-Item -Path $Paths.ProxyTemp -Destination $Paths.ProxyFinal -Force
        
        $versionOutput = & $Paths.ProxyFinal --version 2>&1
        Write-ColoredMessage "Cloud SQL Proxy instalado com sucesso - $($Paths.ProxyFinal)" -Type Success
        Write-ColoredMessage "Versão - $versionOutput" -Type Info
        
        # Cleanup em caso de erro
        if ($LASTEXITCODE -ne 0) {
            @($Paths.ProxyTemp, $Paths.ProxyFinal) | ForEach-Object {
                if (Test-Path $_) { 
                    try { Remove-Item $_ -Force -ErrorAction SilentlyContinue } catch {} 
                }
            }
            throw "Proxy não está funcionando corretamente"
        }
    }
}

function Ensure-HumanAuth {
    $activeUser = & gcloud auth list --filter="status:ACTIVE" --format="value(account)" 2>$null
    
    if (-not $activeUser -or $activeUser -match "compute@developer\.gserviceaccount\.com") {
        Write-ColoredMessage "Login necessário! Será aberto o navegador para autenticação Google." -Type Warning
        Write-ColoredMessage "Use uma conta humana do GCP com permissões adequadas." -Type Info
        
        Invoke-WithRetry -ActionDescription "Autenticação Google Cloud" -ScriptBlock {
            & gcloud auth login
            
            $newActiveUser = & gcloud auth list --filter="status:ACTIVE" --format="value(account)" 2>$null
            if (-not $newActiveUser -or $newActiveUser -match "compute@developer\.gserviceaccount\.com") {
                throw "Falha na autenticação ou conta inválida"
            }
            
            Write-ColoredMessage "Autenticado como: $newActiveUser" -Type Success
        }
    } else {
        Write-ColoredMessage "Já autenticado como: $activeUser" -Type Success
    }
    
    # Configurar projeto
    Write-ColoredMessage "Configurando projeto: $ProjetoGCP" -Type Info
    & gcloud config set project $ProjetoGCP | Out-Null
}

function Test-PortAvailable {
    param([int]$Port)
    
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $Port)
        $listener.Start()
        $listener.Stop()
        return $true
    } catch {
        return $false
    }
}

function Get-NextAvailablePort {
    param([int]$StartPort = 5432)
    
    $currentPort = $StartPort
    $maxAttempts = 100
    $attempts = 0
    
    while ($attempts -lt $maxAttempts) {
        if (Test-PortAvailable -Port $currentPort) {
            return $currentPort
        }
        
        Write-ColoredMessage "Porta $currentPort ocupada, tentando próxima..." -Type Warning
        $currentPort++
        $attempts++
    }
    
    throw "Não foi possível encontrar uma porta disponível após $maxAttempts tentativas"
}

function Start-CloudSQLProxy {
    Write-ColoredMessage "Procurando porta disponível..." -Type Info
    
    try {
        $porta = Get-NextAvailablePort -StartPort 5432
        Write-ColoredMessage "Porta disponível encontrada: $porta" -Type Success
    } catch {
        Write-ColoredMessage "Erro ao encontrar porta disponível: $($_.Exception.Message)" -Type Error
        throw
    }
    
    Write-ColoredMessage "Iniciando Cloud SQL Proxy na porta $porta..." -Type Info
    Write-ColoredMessage "Conectando à instância: $InstanciaGCP" -Type Info
    
    Write-Host ""
    Write-Host "=== CONEXÃO ESTABELECIDA ===" -ForegroundColor Green
    Write-Host "Host:     127.0.0.1" -ForegroundColor White
    Write-Host "Porta:    $porta" -ForegroundColor White
    Write-Host "Banco:    <seu_banco>" -ForegroundColor White
    Write-Host "Usuário:  <seu_usuario>" -ForegroundColor White
    Write-Host "Senha:    <sua_senha>" -ForegroundColor White
    Write-Host ""
    Write-Host "Comando psql: psql -h 127.0.0.1 -p $porta -U usuario -d banco" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Pressione Ctrl+C para interromper" -ForegroundColor Red
    Write-Host "=================================" -ForegroundColor Green
    Write-Host ""
    
    # Loop de reconexão
    while ($true) {
        try {
            & $Paths.ProxyFinal $InstanciaGCP --gcloud-auth --port $porta --address 127.0.0.1
        } catch {
            Write-ColoredMessage "Conexão perdida. Reconectando em 5 segundos..." -Type Warning
            Start-Sleep -Seconds 5
        }
    }
}

# Execução principal
try {
    Write-ColoredMessage "Verificando pré-requisitos..." -Type Info
    
    Install-GCloudSDK
    Install-CloudSQLProxy
    
    Write-ColoredMessage "Pré-requisitos verificados com sucesso" -Type Success
    
    Ensure-HumanAuth
    Start-CloudSQLProxy
    
} catch {
    Write-ColoredMessage "Erro fatal - $($_.Exception.Message)" -Type Error
    exit 1
}