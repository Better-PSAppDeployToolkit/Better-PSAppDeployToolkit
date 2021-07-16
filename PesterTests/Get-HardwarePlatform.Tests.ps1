Describe "Get-HardwarePlatform" {

    BeforeEach{
        function Write-FunctionInfo {}
        function Write-Log {}
    }

    It "returns correct machine indicator (<ExpectedResult>)" -TestCases @(
        @{
            TestName = "Hypver-V"
            Win32_BIOSVersion = "VRTUAL"
            ExpectedResult = "Virtual:Hyper-V"
        },
        
        @{
            TestName = "Virtual PC"
            Win32_BIOSVersion = "A M I"
            ExpectedResult = "Virtual:Virtual PC"
        },
        
        @{
            TestName = "Xen"
            Win32_BIOSVersion = "deez Xen Nuts"
            ExpectedResult = "Virtual:Xen"
        },
        
        @{
            TestName = "VMWare"
            Win32_BIOSSerialNumber = "deez VMWare Nuts"
            ExpectedResult = "Virtual:VMWare"
        },
        
        @{
            TestName = "Hyper-V"
            Win32_ComputerSystemManufacturer = "deez Microsoft Nuts"
            Win32_ComputerSystemModel = "NotCurfaceWithAnS"
            ExpectedResult = "Virtual:Hyper-V"
        },
        
        @{
            TestName = "VMWare"
            Win32_ComputerSystemManufacturer = "deez VMWare Nuts"
            ExpectedResult = "Virtual:VMWare"
        },
        
        @{
            TestName = "Virtual"
            Win32_ComputerSystemModel = "deez Virtual Nuts"
            ExpectedResult = "Virtual"
        },
        
        @{
            TestName = "Physical"
            ExpectedResult = "Physical"
        }
    ) {
        Mock Get-WmiObject {
            Switch($Class){
                "Win32_BIOS" {
                    return [PSCustomObject]@{
                        Version         = $Win32_BIOSVersion
                        SerialNumber    = $Win32_BIOSSerialNumber
                    }
                }
                "Win32_ComputerSystem" {
                    return [PSCustomObject]@{
                        Model           = $Win32_ComputerSystemModel
                        Manufacturer    = $Win32_ComputerSystemManufacturer
                    }
                }
            }
        }
            
        Get-HardwarePlatform | Should -Be $ExpectedResult
    }
}