# Sample script to install Python and pip under Windows
# Authors: Olivier Grisel, Jonathan Helmus and Kyle Kastner
# License: CC0 1.0 Universal: http://creativecommons.org/publicdomain/zero/1.0/

$MINICONDA_URL = "http://repo.continuum.io/miniconda/"
$BASE_URL = "https://www.python.org/ftp/python/"
$GET_PIP_URL = "https://bootstrap.pypa.io/get-pip.py"
$GET_PIP_PATH = "C:\get-pip.py"


function DownloadPython ($python_version, $platform_suffix) {
    $webclient = New-Object System.Net.WebClient
    $filename = "python-" + $python_version + $platform_suffix + ".msi"
    $url = $BASE_URL + $python_version + "/" + $filename

    $basedir = $pwd.Path + "\"
    $filepath = $basedir + $filename
    if (Test-Path $filename) {
        Write-Host "Reusing" $filepath
        return $filepath
    }

    # Download and retry up to 3 times in case of network transient errors.
    Write-Host "Downloading" $filename "from" $url
    $retry_attempts = 2
    for($i=0; $i -lt $retry_attempts; $i++){
        try {
            $webclient.DownloadFile($url, $filepath)
            break
        }
        Catch [Exception]{
            Start-Sleep 1
        }
   }
   if (Test-Path $filepath) {
       Write-Host "File saved at" $filepath
   } else {
       # Retry once to get the error message if any at the last try
       $webclient.DownloadFile($url, $filepath)
   }
   return $filepath
}


function InstallPython ($python_version, $architecture, $python_home) {
    Write-Host "Installing Python" $python_version "for" $architecture "bit architecture to" $python_home
    if (Test-Path $python_home) {
        Write-Host $python_home "already exists, skipping."
        return $false
    }
    if ($architecture -eq "32") {
        $platform_suffix = ""
    } else {
        $platform_suffix = ".amd64"
    }
    $msipath = DownloadPython $python_version $platform_suffix
    Write-Host "Installing" $msipath "to" $python_home
    $install_log = $python_home + ".log"
    $install_args = "/qn /log $install_log /i $msipath TARGETDIR=$python_home"
    $uninstall_args = "/qn /x $msipath"
    RunCommand "msiexec.exe" $install_args
    if (-not(Test-Path $python_home)) {
        Write-Host "Python seems to be installed else-where, reinstalling."
        RunCommand "msiexec.exe" $uninstall_args
        RunCommand "msiexec.exe" $install_args
    }
    if (Test-Path $python_home) {
        Write-Host "Python $python_version ($architecture) installation complete"
    } else {
        Write-Host "Failed to install Python in $python_home"
        Get-Content -Path $install_log
        Exit 1
    }
}

function RunCommand ($command, $command_args) {
    Write-Host $command $command_args
    Start-Process -FilePath $command -ArgumentList $command_args -Wait -Passthru
}


function InstallPip ($python_home) {
    $pip_path = $python_home + "\Scripts\pip.exe"
    $python_path = $python_home + "\python.exe"
    if (-not(Test-Path $pip_path)) {
        Write-Host "Installing pip..."
        $webclient = New-Object System.Net.WebClient
        $webclient.DownloadFile($GET_PIP_URL, $GET_PIP_PATH)
        Write-Host "Executing:" $python_path $GET_PIP_PATH
        Start-Process -FilePath "$python_path" -ArgumentList "$GET_PIP_PATH" -Wait -Passthru
    } else {
        Write-Host "pip already installed."
    }
}


function DownloadMiniconda ($python_version, $platform_suffix) {
    $webclient = New-Object System.Net.WebClient
    
    # The idea is to directly load the miniconda distribution which has the right
    # Python version, instead of downloading it later by creating a conda environment.
    # This is to save resources and reduce build time.
    
    # miniconda -> Python version
    # 2.2.8 to 3.5.2 -> 2.7.6  
    # 3.5.5          -> 2.7.7
    # 3.6.0 to 3.7.0 -> 2.7.8
    # 3.9.1 to 3.10.1-> 2.7.9
    # 3.16.0         -> 2.7.10
        
    # miniconda3 -> Python version
    # 2.2.8 to 3.0.0 -> 3.3.3
    # 3.0.4 to 3.0.5 -> 3.3.4
    # 3.3.0 to 3.4.2 -> 3.3.5
    # 3.5.5 to 3.7.0 -> 3.4.1
    # 3.7.3 to 3.9.1 -> 3.4.2
    # 3.10.1 to 3.16.0 -> 3.4.3
    # 3.18.3 -> 3.5.0
    
    $miniconda_versions=@{
     	"2.7.10"="3.16.0";
     	"3.3.4"="3.0.5";
    	"3.3.5"="3.4.2";
    	"3.4.3"="3.16.0";
    	"3.5.0"="3.18.3";
  		}
  		
  	#$miniconda_version = $miniconda_versions.$python_version
  	
  	# temporary test: always use latest version and then create a conda environment 
  	$miniconda_version = "3.18.3"
    
    $filename = "Miniconda3-" + $miniconda_version + "-Windows-" + $platform_suffix + ".exe"
    
    #if ($python_version.StartsWith("3")) {    	
    #    $filename = "Miniconda3-" + $miniconda_version + "-Windows-" + $platform_suffix + ".exe"
    #} else {
    #    $filename = "Miniconda-" + $miniconda_version + "-Windows-" + $platform_suffix + ".exe"
    #}
    $url = $MINICONDA_URL + $filename

    $basedir = $pwd.Path + "\"
    $filepath = $basedir + $filename
    if (Test-Path $filename) {
        Write-Host "Reusing" $filepath
        return $filepath
    }

    # Download and retry up to 3 times in case of network transient errors.
    Write-Host "Downloading" $filename "from" $url
    $retry_attempts = 2
    for($i=0; $i -lt $retry_attempts; $i++){
        try {
            $webclient.DownloadFile($url, $filepath)
            break
        }
        Catch [Exception]{
            Start-Sleep 1
        }
   }
   if (Test-Path $filepath) {
       Write-Host "File saved at" $filepath
   } else {
       # Retry once to get the error message if any at the last try
       $webclient.DownloadFile($url, $filepath)
   }
   return $filepath
}


function InstallMiniconda ($python_version, $architecture, $python_home) {
    Write-Host "Installing Python" $python_version "for" $architecture "bit architecture to" $python_home
    if (Test-Path $python_home) {
        Write-Host $python_home "already exists, skipping."
        return $false
    }
    if ($architecture -eq "32") {
        $platform_suffix = "x86"
    } else {
        $platform_suffix = "x86_64"
    }
    $filepath = DownloadMiniconda $python_version $platform_suffix
    Write-Host "Installing" $filepath "to" $python_home
    $install_log = $python_home + ".log"
    $args = "/S /D=$python_home"
    Write-Host $filepath $args
    Start-Process -FilePath $filepath -ArgumentList $args -Wait -Passthru
    if (Test-Path $python_home) {
        Write-Host "Python $python_version ($architecture) installation complete"
    } else {
        Write-Host "Failed to install Python in $python_home"
        Get-Content -Path $install_log
        Exit 1
    }
}


function InstallMinicondaPip ($python_home) {
    $pip_path = $python_home + "\Scripts\pip.exe"
    $conda_path = $python_home + "\Scripts\conda.exe"
    if (-not(Test-Path $pip_path)) {
        Write-Host "Installing pip..."
        $args = "install --yes pip"
        Write-Host $conda_path $args
        Start-Process -FilePath "$conda_path" -ArgumentList $args -Wait -Passthru
    } else {
        Write-Host "pip already installed."
    }
}

function main () {
    #InstallPython $env:PYTHON_VERSION $env:PYTHON_ARCH $env:PYTHON
    #InstallPip $env:PYTHON
    InstallMiniconda $env:PYTHON_VERSION $env:PYTHON_ARCH $env:PYTHON
    InstallMinicondaPip $env:PYTHON
}

main
