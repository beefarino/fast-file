# Copyright (c) 2011 Code Owls LLC, All Rights Reserved.
# 
# Permission is hereby granted, free of charge, to any person obtaining a 
# copy of this software and associated documentation files (the "Software"), 
# to deal in the Software without restriction, including without limitation 
# the rights to use, copy, modify, merge, publish, distribute, sublicense, 
# and/or sell copies of the Software, and to permit persons to whom the 
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included 
# in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
# DEALINGS IN THE SOFTWARE. 
#
# authors:
#	jim christopher <jimchristopher@gmail.com>
#
# notes:
#
# 11.19.2011: first pass, using audrey and scott as testers
# 11.21.2011: * out-fastfile: added explicit conversion of inputdata to
#               string using out-string cmdlet; this should result in the
#               output being formatted a-la the console

$writers = @{};

# see http://poshcode.org/2734
function _Get-Path 
{
    [CmdletBinding(DefaultParameterSetName="DriveQualified")]
    Param(
       [Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
       [Alias("PSPath")]
       [String]      
       $Path,
       [Parameter()]
       [Switch]$ResolvedPath,
       [Parameter(ParameterSetName="ProviderQualified")]
       [Switch]$ProviderQualified
       
    )
       $Drive = $Provider = $null
       $PSPath = $PSCmdlet.SessionState.Path
       
       if($ResolvedPath -and $ProviderQualified) {
          $ProviderPaths = $PSPath.GetResolvedProviderPathFromPSPath($Path, [ref]$Provider)
       } else {
          $ProviderPaths = @($PSPath.GetUnresolvedProviderPathFromPSPath($Path, [ref]$Provider, [ref]$Drive))
          if($ResolvedPath) {
             $ProviderPaths = $PSPath.GetResolvedProviderPathFromProviderPath($ProviderPaths[0], $Provider)
          }
       }
       
       foreach($p in $ProviderPaths) {
          if($ProviderQualified -or ($Drive -eq $null)) {
             if(!$PSPath.IsProviderQualified($p)) {
                $p = $Provider.Name + '::' + $p
             }
          } else {
             if($PSPath.IsProviderQualified($p)) {
                $p = $p -replace [regex]::Escape( ($Provider.Name + "::") )
             }
             $p = $p.Replace($Drive.Root, $Drive.Name + ":\")
          }
          $p
       }
    }

function open-FastFile
{
<#
.SYNOPSIS 
Opens a FastFile for writing.

.DESCRIPTION
Opens a FastFile for writing.

A "FastFile" is a write-only file stream that can be written to multiple
times from different pipelines once the initial stream has been acquired.
This is a much faster way of persisting large quantities of data to file
than the built-in out-file cmdlet.

A FastFile must be explicitly closed using the close-FastFile cmdlet before
the data file can be modified by another process.  You can open a FastFile explicitly
using the open-FastFile cmdlet, or implicitly by sending data to the 
out-FastFile cmdlet.

.INPUTS
None.

.OUTPUTS
None.

.EXAMPLE
C:\PS> open-fastfile ./tmp.txt

Opens the file at c:\tmp.txt for fast write access.

.LINK
out-file

.LINK
close-FastFile

.LINK
out-FastFile

.LINK
use-FastFile
#>
    [CmdletBinding()]
    param(
        [parameter( Mandatory=$true, ValueFromPipeline=$true, Position=1 )]
        [string]
        # the file path to open for fast writes
        $FilePath,
        
        [parameter()]
        [switch]
        # when specified, the file is opened for appending.  by default existing files are overwritten unless this option is specified.
        $Append,
        
        [parameter()]
        [switch]
        # when specified, existing files are not overwritten.  has no meaning when the -append switch is applied.
        $NoClobber
    );
    begin
    {
        write-debug "begin open-fastfile [$filepath]";
    }
    
    process
    {
        $fullPath = _get-path $filepath 
        
        if( $writers.ContainsKey( $fullpath ) )
        {
            write-debug "returning existing writer for $filepath";
            return $writers[ $fullpath ];
        }
        
        $fileInfo = new-object system.io.fileinfo -arg $fullpath;
        write-debug "file info: [$fileInfo]";
        $writer = $null;
        
        if( $fileinfo.exists )
        {
            write-debug "$filepath exists - processing noclobber and append parameters";
            if( $noclobber -and -not $append )
            {
                throw "The specified file [$FilePath] exists.  Using the -NoClobber parameter prevents overwriting an existing file";
            }
            if( $append )
            {
                write-debug "creating appending stream writer for $filePath";
                $writer = $fileInfo.AppendText();
            }
        }
        
        if( -not $writer )
        {
            write-debug "creating create stream writer for $filePath";
            $writer = $fileInfo.CreateText();
        }
        
        write-debug "writer: $writer"
        $writers[ $fullPath ] = $writer;
    }
    
    end
    {
        write-debug "end open-fastfile [$filepath]";
    }
}

function close-FastFile
{
<#
.SYNOPSIS 
Closes a FastFile.

.DESCRIPTION
Closes a FastFile.  Any pending data writes to the file are flushed and
the file is closed.

A "FastFile" is a write-only file stream that can be written to multiple
times from different pipelines once the initial stream has been acquired.
This is a much faster way of persisting large quantities of data to file
than the built-in out-file cmdlet.

A FastFile must be explicitly closed using the close-FastFile cmdlet before
the data file can be modified by another process.  You can open a FastFile explicitly
using the open-FastFile cmdlet, or implicitly by sending data to the 
out-FastFile cmdlet.

.INPUTS
None.

.OUTPUTS
None.

.EXAMPLE
C:\PS> close-fastfile ./tmp.txt

Closes the previously opened file at c:\tmp.txt.

.LINK
out-file

.LINK
open-FastFile

.LINK
out-FastFile

.LINK
use-FastFile
#>
    [CmdletBinding()]
    param(
        [parameter( Mandatory=$true, ValueFromPipeline=$true, Position=1 )]
        [string]
        # the path of the FastFile stream to close
        $FilePath
    );        
    
    begin
    {
        write-debug "begin close-fastfile [$filepath]";
    }
    process
    {
        $fullPath = _get-path $filepath 
        if( -not $writers.ContainsKey( $fullPath ) )
        {
            write-warning "attempt to close fast file writer for untracked path [$FilePath]";
            return;
        }
        
        $writer = $writers[ $fullPath ];
        $writers.Remove( $fullPath );
        
        $writer.Flush();
        $writer.Close();
        $writer.Dispose();
        $writer = $null;
    }
    
    end
    {
        write-debug "end close-fastfile [$filepath]";
    }
    
}

function out-FastFile
{
<#
.SYNOPSIS 
Writes data to a FastFile.

.DESCRIPTION
Writes data to a FastFile.

A "FastFile" is a write-only file stream that can be written to multiple
times from different pipelines once the initial stream has been acquired.
This is a much faster way of persisting large quantities of data to file
than the built-in out-file cmdlet.

A FastFile must be explicitly closed using the close-FastFile cmdlet before
the data file can be modified by another process.  You can open a FastFile explicitly
using the open-FastFile cmdlet, or implicitly by sending data to the 
out-FastFile cmdlet.

If the file specified by the mandatory FilePath parameter is not already 
opened from a previous call to open-FastFile, this cmdlet will invoke 
open-FastFile on the file path with the -append switch enabled.

.INPUTS
PSObject.  This cmdlet accepts pipeline input to be written to the file.

.OUTPUTS
None.

.EXAMPLE
C:\PS> ls | out-fastfile ./tmp.txt

Writes the current directory listing to the file at c:\tmp.txt.

.LINK
out-file

.LINK
close-FastFile

.LINK
open-FastFile

.LINK
use-FastFile
#>
    [CmdletBinding()]
    param(
        [parameter( Mandatory=$true, Position=1 )]
        [string]
        # the path of the FastFile to which to write the data.  if the file is not already opened by a call to open-FastFile, the file will be opened for appending.
        $FilePath,
        
        [parameter( Mandatory=$false, ValueFromPipeline=$true )]
        [psobject]
        # the data to write to the file
        $InputObject
    );        
    
    begin
    {    
        
        write-debug "begin out-fastfile [$filepath]";
        write-debug "current writer keys [$($writers.keys)]";
        write-debug "current writer keys [$($writers.ContainsKey( $filepath ))]";
    
        if( !( $writers.ContainsKey( $filepath ) ) )
        {            
            open-fastfile $filepath -append;
        }
        
        $writer = $writers[ ($filepath | _get-path ) ];
    }
    process
    {
        write-debug "process out-fastfile [$filepath]";
        $writer.WriteLine( ( $InputObject | out-string ) );
    }
    end
    {
        write-debug "end out-fastfile [$filepath]";
        $writer.Flush();
        
    }
}


function use-FastFile
{

    [CmdletBinding()]
    param(
        [parameter( Mandatory=$true, Position=1 )]
        [string]
        $FilePath,
        
        [parameter( Mandatory=$true, Position=2 )]
        [scriptblock]
        $Script
    );        
    
    begin
    {
        open-fastfile $filepath -append;
        
    }
    process
    {
        &$script | out-fastfile $filepath;
    }
    end
    {
        close-FastFile $filepath;
    }
}

export-ModuleMember -function *FastFile;