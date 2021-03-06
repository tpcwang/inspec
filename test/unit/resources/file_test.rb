# encoding: utf-8
# author: Christoph Hartmann
# author: Dominik Richter

require 'helper'
require 'inspec/resource'

def shared_file_permission_tests(method_under_test)
  it 'returns false if the file does not exist' do
    resource.stubs(:exist?).returns(false)
    resource.send(method_under_test, nil, nil).must_equal(false)
  end

  it 'returns the value of #file_permission_granted?' do
    resource.stubs(:exist?).returns(true)
    resource.stubs(:file_permission_granted?).returns('test_result')
    resource.send(method_under_test, nil, nil).must_equal('test_result')
  end
end

describe Inspec::Resources::FileResource do
  let(:resource) { load_resource('file', '/fakepath/fakefile') }

  describe '#readable?' do
    shared_file_permission_tests(:readable?)
  end

  describe '#writable?' do
    shared_file_permission_tests(:writable?)
  end

  describe '#executable?' do
    shared_file_permission_tests(:executable?)
  end

  describe '#basename' do
    it 'returns the basename' do
      resource.stubs(:basename).returns('fakefile')
      resource.basename.must_equal('fakefile')
    end
  end

  describe '#to_s' do
    it 'returns a properly formatted string' do
      resource.to_s.must_equal('File /fakepath/fakefile')
    end
  end

  describe '#file_permission_granted?' do
    describe 'when not on a unix OS' do
      it 'raises an exception' do
        MockLoader.mock_os(resource, :windows)
        proc { resource.send(:file_permission_granted?, 'flag', nil, nil) }.must_raise(RuntimeError)
      end
    end

    describe 'when on a unix OS' do
      before do
        MockLoader.mock_os(resource, :centos7)
      end

      describe 'when no user is provided' do
        it 'checks file permission by mask' do
          resource.expects(:check_file_permission_by_mask).with('usergroup', 'flag')
          resource.send(:file_permission_granted?, 'flag', 'usergroup', nil)
        end
      end

      describe 'when a user is provided' do
        it 'checks file permission by user' do
          resource.expects(:check_file_permission_by_user).with('user', 'flag')
          resource.send(:file_permission_granted?, 'flag', nil, 'user')
        end
      end
    end
  end

  describe '#check_file_permission_by_mask' do
    describe 'when no mask is returned' do
      let(:file) { stub(unix_mode_mask: nil) }

      it 'raises an exception' do
        file = stub(unix_mode_mask: nil)
        resource.stubs(:file).returns(file)
        proc { resource.send(:check_file_permission_by_mask, 'usergroup', 'flag') }.must_raise(RuntimeError)
      end
    end

    describe 'when a mask is returned' do
      describe 'when the bitwise AND returns a non-zero' do
        let(:file) { stub(unix_mode_mask: 292, mode: 420) }
        it 'returns true' do
          resource.stubs(:file).returns(file)
          resource.send(:check_file_permission_by_mask, 'usergroup', 'flag').must_equal(true)
        end
      end

      describe 'when the bitwise AND returns zero' do
        let(:file) { stub(unix_mode_mask: 73, mode: 420) }
        it 'returns false' do
          resource.stubs(:file).returns(file)
          resource.send(:check_file_permission_by_mask, 'usergroup', 'flag').must_equal(false)
        end
      end
    end
  end

  describe 'check_file_permission_by_user' do
    describe 'when on linux' do
      before do
        MockLoader.mock_os(resource, :centos7)
      end

      it 'executes a properly formatted command' do
        MockLoader.mock_command(resource,
          'su -s /bin/sh -c "test -flag /fakepath/fakefile" user',
          exit_status: 0)
        resource.send(:check_file_permission_by_user, 'user', 'flag')
      end

      it 'returns true when the cmd exits 0' do
        MockLoader.mock_command(resource, 'su -s /bin/sh -c "test -flag /fakepath/fakefile" user', exit_status: 0)
        resource.send(:check_file_permission_by_user, 'user', 'flag').must_equal(true)
      end

      it 'returns true when the cmd exits non-zero' do
        MockLoader.mock_command(resource, 'su -s /bin/sh -c "test -flag /fakepath/fakefile" user', exit_status: 1)
        resource.send(:check_file_permission_by_user, 'user', 'flag').must_equal(false)
      end
    end

    describe 'when on freebsd' do
      before do
        MockLoader.mock_os(resource, :freebsd10)
      end

      it 'executes a properly formatted command' do
        MockLoader.mock_command(resource, 'sudo -u user test -flag /fakepath/fakefile', exit_status: 0)
        resource.send(:check_file_permission_by_user, 'user', 'flag')
      end

      it 'returns true when the cmd exits 0' do
        MockLoader.mock_command(resource, 'sudo -u user test -flag /fakepath/fakefile', exit_status: 0)
        resource.send(:check_file_permission_by_user, 'user', 'flag').must_equal(true)
      end

      it 'returns true when the cmd exits non-zero' do
        MockLoader.mock_command(resource, 'sudo -u user test -flag /fakepath/fakefile', exit_status: 1)
        resource.send(:check_file_permission_by_user, 'user', 'flag').must_equal(false)
      end
    end

    describe 'when on hpux' do
      before do
        MockLoader.mock_os(resource, :hpux)
      end

      it 'executes a properly formatted command' do
        MockLoader.mock_command(resource, "su user -c \"test -flag /fakepath/fakefile\"", exit_status: 0)
        resource.send(:check_file_permission_by_user, 'user', 'flag')
      end

      it 'returns true when the cmd exits 0' do
        MockLoader.mock_command(resource, "su user -c \"test -flag /fakepath/fakefile\"", exit_status: 0)
        resource.send(:check_file_permission_by_user, 'user', 'flag').must_equal(true)
      end

      it 'returns false when the cmd exits non-zero' do
        MockLoader.mock_command(resource, "su user -c \"test -flag /fakepath/fakefile\"", exit_status: 1)
        resource.send(:check_file_permission_by_user, 'user', 'flag').must_equal(false)
      end
    end

    describe 'when not on linux or freebsd' do
      before do
        MockLoader.mock_os(resource, :undefined)
      end

      it 'returns an error string' do
        resource.send(:check_file_permission_by_user, 'user', 'flag').must_equal('The `file` resource does not support `by_user` on your OS.')
      end
    end
  end

  describe '#usergroup_for' do
    it 'returns "other" if "others" is provided' do
      resource.send(:usergroup_for, 'others', nil).must_equal('other')
    end

    it 'returns "all" if no usergroup or user is specified' do
      resource.send(:usergroup_for, nil, nil).must_equal('all')
    end

    it 'returns nil if the usergroup is nil and a user is specified' do
      resource.send(:usergroup_for, nil, 'user').must_equal(nil)
    end

    it 'returns the passed-in usergroup if usergroup is not nil and user is nil' do
      resource.send(:usergroup_for, 'mygroup', nil).must_equal('mygroup')
    end
  end
end
