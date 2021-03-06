import-module pester;
import-module ./FastFile.psm1;

Describe "FastFile" {  
    
    It "can be used explicitly" {
        
        $filepath = [io.path]::GetTempFileName();
        
        open-FastFile $filepath
        ls / | out-fastfile $filepath;
        close-FastFile $filepath
        
        (test-path $filepath) -and ((gc $filepath) -match '\d+')
    }
    
    It "can be used implicitly" {
        
        $filepath = [io.path]::GetTempFileName();
        
        ls / | out-fastfile $filepath;
        (test-path $filepath) -and ((gc $filepath) -match '\d+')
    }
    
    It "can be used in a block" {
        
        $filepath = [io.path]::GetTempFileName();
        
        use-FastFile $filepath {
            ls /
        }
        
        (test-path $filepath) -and ((gc $filepath) -match '\d+')
    }
    
    It "is faster than out-file for incrementally writing large files" {
        $filepath = [io.path]::GetTempFileName();
        $fastfile = measure-command {
            0..999 | %{ [guid]::newGuid().ToString() | out-fastfile $filepath }
        }
        
        $filepath = [io.path]::GetTempFileName();
        $outfile = measure-command {
            0..999 | %{ [guid]::newGuid().ToString() | out-file $filepath -append }
        }
    
        write-verbose "Out-FastFile time: $($fastfile.totalMilliseconds)";
        write-verbose "Out-File time:     $($outfile.totalMilliseconds)";
        
        $fastfile.totalMilliseconds -lt $outfile.totalMilliseconds;
    }    
    
}

remove-module pester;
remove-module FastFile;