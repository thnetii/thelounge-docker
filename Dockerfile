# escape=`

ARG WINDOWSDOWNLOADTAG=1809-amd64
ARG BASEIMAGE=mcr.microsoft.com/windows/nanoserver:${WINDOWSDOWNLOADTAG}
ARG PYTHONVERSION=3.8.5
ARG NODEVERSION=12.18.3
ARG NPMVERSION
ARG YARNVERSION
ARG THELOUNGEVERSION

FROM mcr.microsoft.com/windows/servercore:${WINDOWSDOWNLOADTAG} AS build-thelounge

# Restore the default Windows shell for correct batch processing.
SHELL ["cmd", "/S", "/C"]
ADD https://aka.ms/vs/16/release/vs_buildtools.exe C:\Users\Public\Downlods\

RUN C:\Users\Public\Downlods\vs_buildtools.exe --quiet --wait --norestart --nocache `
    --installPath C:\Tools\VsBuildTools `
    --add Microsoft.VisualStudio.Workload.VCTools `
 || IF "%ERRORLEVEL%"=="3010" EXIT 0

# Use PowerShell from now on
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ARG PYTHONVERSION
ADD https://www.python.org/ftp/python/${PYTHONVERSION}/python-${PYTHONVERSION}-amd64.exe C:\Users\Public\Downloads\
RUN `
    $PythonInstallerFile = ('python-{0}-amd64.exe' -f $ENV:PYTHONVERSION); `
    $PythonInstallerPath = Join-Path -Resolve "C:\Users\Public\Downloads" $PythonInstallerFile; `
    $PythonInstallerName = [System.Io.Path]::GetFileNameWithoutExtension($PythonInstallerFile); `
    $PythonInstallerArgs = @('/quiet', 'InstallAllUsers=1',`
    ('TargetDir=C:\Tools\{0}' -f $PythonInstallerName), `
    'CompileAll=1', 'PrependPath=1', 'Include_tcltk=0', 'Include_test=0'`
    ); `
    Start-Process -NoNewWindow -Wait $PythonInstallerPath $PythonInstallerArgs; `
    Join-Path -Resolve "C:\Tools" $PythonInstallerName | Out-Null; `
    Remove-Item -Force -Verbose $PythonInstallerPath

ARG NODEVERSION
ADD https://nodejs.org/dist/v${NODEVERSION}/node-v${NODEVERSION}-x64.msi C:\Users\Public\Downloads\
RUN `
    $NodeMsiFileName = ('node-v{0}-x64.msi' -f $ENV:NODEVERSION); `
    $NodeMsiFilePath = Join-Path -Resolve "C:\Users\Public\Downloads" $NodeMsiFileName; `
    $NodeMsiBaseName = [System.Io.Path]::GetFileNameWithoutExtension($NodeMsiFileName); `
    $NodeMSiArgs = @(`
    '/i', $NodeMsiFilePath, `
    ('INSTALLDIR=C:\Tools\{0}' -f $NodeMsiBaseName), `
    '/quiet'); `
    Start-Process -NoNewWindow -Wait msiexec.exe $NodeMSiArgs; `
    Join-Path -Resolve "C:\Tools" $NodeMsiBaseName | Out-Null; `
    Remove-Item -Force -Verbose $NodeMsiFilePath

ARG NPMVERSION
RUN `
    if ($ENV:NPMVERSION) { `
        & npm install --global --no-cache ('npm@{0}' -f $ENV:NPMVERSION); `
    }
ARG YARNVERSION
RUN `
    if ($ENV:YARNVERSION) { `
        $YarnVersion = ('yarn@{0}' -f $ENV:YARNVERSION); `
    } else { `
        $YarnVersion = 'yarn'; `
    }; `
    & npm install --global --no-cache $YarnVersion;

ARG THELOUNGEVERSION
ADD package.json C:\TheLounge\
RUN `
    Push-Location 'C:\TheLounge'; `
    if ($ENV:THELOUNGEVERSION) { `
        $TheLoungeVersion = ('thelounge@{0}' -f $ENV:THELOUNGEVERSION); `
    } else { `
        $TheLoungeVersion = 'thelounge'; `
    }; `
    yarn --non-interactive --frozen-lockfile add $TheLoungeVersion; `
    yarn --non-interactive cache clean

FROM ${BASEIMAGE}
ARG NODEVERSION
COPY --from=build-thelounge C:\Tools\node-v${NODEVERSION}-x64\ C:\Tools\node-v${NODEVERSION}-x64\
COPY --from=build-thelounge C:\TheLounge\ C:\TheLounge\
ADD *.cmd C:\Users\Public\Downloads\HelperScripts\
RUN C:\Users\Public\Downloads\HelperScripts\node-pathsetup.cmd
RUN C:\Users\Public\Downloads\HelperScripts\thelounge-pathsetup.cmd
RUN cmd.exe /C "RD /S /Q C:\Users\Public\Downloads\HelperScripts"

ENV NODE_ENV production

ENV THELOUNGE_HOME "C:\ProgramData\thelounge"
VOLUME "${THELOUNGE_HOME}"
WORKDIR "${THELOUNGE_HOME}"

# Expose HTTP.
ENV PORT 9000
EXPOSE ${PORT}
# Expose additional port for Identd
EXPOSE 9001
