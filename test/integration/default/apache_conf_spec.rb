# encoding: utf-8

if os.linux?

  # direct access to params of apache conf
  describe apache_conf do
    its('LogLevel') { should cmp 'warn' }
    its('MaxKeepAliveRequests') { should cmp '100' }
  end

  # only read one param
  describe apache_conf.params('LogLevel') do
    it { should include 'warn' }
  end
end
