# fast-file

FastFile is a PowerShell module for rapid write-only file access.  This module performs much faster than out-file for large data sets written across multiple pipelines.

## Quick Start
    > import-module FastFile
    > $path = ./tmp.txt
    > open-fastFile $path
    > 0..999 | %{ls /} | out-fastFile $path
    > close-fastFile $path

or

    > import-module FastFile
    > $path = ./tmp.txt
    > use-fastFile $path {
        0..999 | %{ls /} 
      }

## Exported Functions


### open-FastFile
    
    SYNOPSIS
        Opens a FastFile for writing.
    
    
    SYNTAX
        open-FastFile [-FilePath] <String> [-Append] [-NoClobber] [<CommonParameters>]
    
    
    DESCRIPTION
        Opens a FastFile for writing.
    
        A "FastFile" is a write-only file stream that can be written to multiple
        times from different pipelines once the initial stream has been acquired.
        This is a much faster way of persisting large quantities of data to file
        than the built-in out-file cmdlet.
    
        A FastFile must be explicitly closed using the close-FastFile cmdlet before
        the data file can be modified by another process.  You can open a FastFile explicitly
        using the open-FastFile cmdlet, or implicitly by sending data to the 
        out-FastFile cmdlet.
    
### close-FastFile
    
    SYNOPSIS
        Closes a FastFile.  
    
    SYNTAX
        close-FastFile [-FilePath] <String> [<CommonParameters>]
    
    
    DESCRIPTION
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
    

### out-FastFile
    
    SYNOPSIS
        Writes data to a FastFile.
    
    
    SYNTAX
        out-FastFile [-FilePath] <String> [-InputObject <PSObject>] [<CommonParameters>]
    
    
    DESCRIPTION
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
    
