BeforeDiscovery {
    $TestCases = @(
        @{
            TestName = "VRTUAL"
            Version = "VRTUAL"
            ExpectedResult = "Virtual:Hyper-V"
        }
        @{
            TestName = "A M I"
            Version = "A M I"
            ExpectedResult = "Virtual:Virtual PC"
        }
        @{
            TestName = "*Xen*"
            Version = "Deez Xen Nuts"
            ExpectedResult = "Virtual:Xen"
        }
        @{
            TestName = "*VMware*"
            SerialNumber = "Deez VMware Nuts"
            ExpectedResult = "Virtual:VMWare"
        }
        @{
            TestName = "*Microsoft* but not *Surface*"
            Manufacturer = "Big Microsoft Nuts"
            Model = "Not a Wurface btw"
            ExpectedResult = "Virtual:Hyper-V"
        }
        @{
            TestName = "*VMWare*"
            Manufacturer = "Deez VMWare Nuts"
            ExpectedResult = "Virtual:VMWare"
        }
        @{
            TestName = "*Virtual*"
            Model = "Deez Virtual Nuts"
            ExpectedResult = "Virtual"
        }
        @{
            TestName = "(Let's get) Physical"
            Model = "Model"
            ExpectedResult = "Physical"
        }
    )
}

Describe "Get-HardwarePlatform function tests" -ForEach $TestCases{
    BeforeAll{
        function Write-Log(){}
        function Write-FunctionInfo(){}
        function Resolve-Error(){}
    }
    
    BeforeEach{
        $TestCase = $_

        Mock Get-WmiObject {
            Switch($Class){
                "Win32_BIOS" {
                    return [PSCustomObject]@{
                        Version         = $Testcase.Version
                        SerialNumber    = $Testcase.SerialNumber
                    }
                }
                "Win32_ComputerSystem" {
                    return [PSCustomObject]@{
                        Model           = $Testcase.Model
                        Manufacturer    = $Testcase.Manufacturer
                    }
                }
            }
        }
    }

    It "Return should be a string" {
        (Get-HardwarePlatform).GetType().Name | Should -Be "String"
    }

    It "<TestCase.TestName> Should result in: <TestCase.ExpectedResult>" {
        Get-HardwarePlatform | Should -Be $TestCase.ExpectedResult
    }
}