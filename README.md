# posh-cargo

Provides tab autocompletion of '[cargo](https://github.com/rust-lang/cargo)' command on *PowerShell* prompt

## Installation

### Prerequisites

1. PowerShell 4.1.0 or higher. Check your PowerShell version by executing `$PSVersionTable.PSVersion`.

1. Script execution policy must be set to either `RemoteSigned` or `Unrestricted`.
   Check the script execution policy setting by executing `Get-ExecutionPolicy`.
   If the policy is not set to one of the two required values, run PowerShell as Administrator and execute `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Confirm`.

1. Cargo must be installed and available via the PATH environment variable.
   Check that `cargo` is accessible from PowerShell by executing `cargo --version` from PowerShell.
   If `cargo` is not recognized as the name of a command verify that you have Rust installed.
   If not, install Rust from [https://www.rust-lang.org](https://www.rust-lang.org).
   If you have Rust installed, make sure the path to cargo.exe is in your PATH environment variable.

### Installing via PowerShellGet

If you are on PowerShell version 5 or higher, execute the command below to install from the [PowerShell Gallery](https://www.powershellgallery.com/):

```powershell
PowerShellGet\Install-Module posh-cargo -Scope CurrentUser -AllowClobber
```

You may be asked if you trust packages coming from the PowerShell Gallery. Answer yes to allow installation of this module to proceed.

If you are on PowerShell version 3 or 4, you will need to install the [Package Management Preview for PowerShell 3 & 4](https://www.microsoft.com/en-us/download/details.aspx?id=51451) in order to run the command above.

Note: If you get an error message from Install-Module about NuGet being required to interact with NuGet-based repositories, execute the following commands to bootstrap the NuGet provider:

```powershell
Install-PackageProvider NuGet -Force
Import-PackageProvider NuGet -Force
```

Then retry the Install-Module command above.

After you have successfully installed the posh-cargo module from the PowerShell Gallery, you will be able to update to a newer version by executing the command:

```powershell
Update-Module posh-cargo
```

### Usage

Open (or create) your profile script with the command notepad $profile.CurrentUserAllHosts. In the profile script, add the following line:

```powershell
Import-Module posh-cargo
```

Save the profile script, then close PowerShell and open a new PowerShell session.
Type `cargo me` and then press <kbd>tab</kbd>. If posh-cargo has been imported, that command should tab complete to `cargo metadata`.
