@rem
@rem Copyright 2015 the original author or authors.
@rem
@rem Licensed under the Apache License, Version 2.0 (the "License");
@rem you may not use this file except in compliance with the License.
@rem You may obtain a copy of the License at
@rem
@rem      https://www.apache.org/licenses/LICENSE-2.0
@rem
@rem Unless required by applicable law or agreed to in writing, software
@rem distributed under the License is distributed on an "AS IS" BASIS,
@rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
@rem See the License for the specific language governing permissions and
@rem limitations under the License.
@rem

@if "%DEBUG%" == "" @echo off
@rem ##########################################################################
@rem
@rem  TxConsumer startup script for Windows
@rem
@rem ##########################################################################

@rem Set local scope for the variables with windows NT shell
if "%OS%"=="Windows_NT" setlocal

set DIRNAME=%~dp0
if "%DIRNAME%" == "" set DIRNAME=.
set APP_BASE_NAME=%~n0
set APP_HOME=%DIRNAME%..

@rem Resolve any "." and ".." in APP_HOME to make it shorter.
for %%i in ("%APP_HOME%") do set APP_HOME=%%~fi

@rem Add default JVM options here. You can also use JAVA_OPTS and TX_CONSUMER_OPTS to pass JVM options to this script.
set DEFAULT_JVM_OPTS=

@rem Find java.exe
if defined JAVA_HOME goto findJavaFromJavaHome

set JAVA_EXE=java.exe
%JAVA_EXE% -version >NUL 2>&1
if "%ERRORLEVEL%" == "0" goto execute

echo.
echo ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.

goto fail

:findJavaFromJavaHome
set JAVA_HOME=%JAVA_HOME:"=%
set JAVA_EXE=%JAVA_HOME%/bin/java.exe

if exist "%JAVA_EXE%" goto execute

echo.
echo ERROR: JAVA_HOME is set to an invalid directory: %JAVA_HOME%
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.

goto fail

:execute
@rem Setup the command line

set CLASSPATH=%APP_HOME%\lib\okafka-23.4.0.0-txconsumer.jar;%APP_HOME%\lib\okafka-23.4.0.0.jar;%APP_HOME%\lib\oraclepki-23.4.0.24.05.jar;%APP_HOME%\lib\kafka-clients-3.7.1.jar;%APP_HOME%\lib\logback-classic-1.5.6.jar;%APP_HOME%\lib\ojdbc11-23.4.0.24.05.jar;%APP_HOME%\lib\aqapi-23.3.0.0.jar;%APP_HOME%\lib\jta-1.1.jar;%APP_HOME%\lib\javax.jms-api-2.0.jar;%APP_HOME%\lib\slf4j-api-2.0.13.jar;%APP_HOME%\lib\junit-4.12.jar;%APP_HOME%\lib\zstd-jni-1.5.6-3.jar;%APP_HOME%\lib\lz4-java-1.8.0.jar;%APP_HOME%\lib\snappy-java-1.1.10.5.jar;%APP_HOME%\lib\logback-core-1.5.6.jar;%APP_HOME%\lib\ojdbc8-23.3.0.23.09.jar;%APP_HOME%\lib\hamcrest-core-1.3.jar


@rem Execute TxConsumer
"%JAVA_EXE%" %DEFAULT_JVM_OPTS% %JAVA_OPTS% %TX_CONSUMER_OPTS%  -classpath "%CLASSPATH%"  %*

:end
@rem End local scope for the variables with windows NT shell
if "%ERRORLEVEL%"=="0" goto mainEnd

:fail
rem Set variable TX_CONSUMER_EXIT_CONSOLE if you need the _script_ return code instead of
rem the _cmd.exe /c_ return code!
if  not "" == "%TX_CONSUMER_EXIT_CONSOLE%" exit 1
exit /b 1

:mainEnd
if "%OS%"=="Windows_NT" endlocal

:omega
