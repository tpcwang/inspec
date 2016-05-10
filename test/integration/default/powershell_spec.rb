# encoding: utf-8
if os.windows?
  script = <<-EOH
    Write-Output 'hello'
  EOH

  # Write-Output comes with a newline
  describe powershell(script) do
    its('stdout') { should eq "hello\r\n" }
    its('stderr') { should eq '' }
  end

  # remove whitespace \r\n from stdout
  describe powershell(script) do
    its('strip') { should eq "hello" }
  end

  # legacy test with `script` resource
  describe script(script) do
    its('stdout') { should eq "hello\r\n" }
    its('stderr') { should eq '' }
  end

  # -NoNewLine only works in powershell 5
  # @see https://blogs.technet.microsoft.com/heyscriptingguy/2015/08/07/the-powershell-5-nonewline-parameter/
  describe powershell("'hello' | Write-Host -NoNewLine") do
    its('stdout') { should eq 'hello' }
    its('stderr') { should eq '' }
  end

  # test stderr
  describe powershell("Write-Error \"error\"") do
    its('stdout') { should eq '' }
    # this is an xml error for now, if the script is run via WinRM
    # @see https://github.com/WinRb/WinRM/issues/106
    # its('stderr') { should eq 'error' }
  end
end
