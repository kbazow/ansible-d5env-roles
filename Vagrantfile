# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
VAGRANTFILE_API_VERSION = '2'.freeze

# Addresses a potential problem eventually running `vagrant ssh` and an error
# occurs indicating keys not being permitted or usable.
ENV['VAGRANT_PREFER_SYSTEM_BIN'] = '0'

# Vagrant script is very likely to work for older versions; the known hard
# limit at this time is >= 1.8
Vagrant.require_version '>= 2.2.16'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = 'vagrant-autonomy-dev-18-04'
  config.vm.hostname = 'autonomy-18-04-lab'
  config.vm.base_mac = '0800275B91D9'

  # For VPN.
  config.vm.network 'private_network', type: 'dhcp'
  # config.vm.network 'public_network', bridge: 'Cisco AnyConnect Secure Mobility Client Virtual Miniport Adapter for Windows x64'
  # config.vm.network 'public_network', bridge: 'Realtek USB GbE Family Controller'

  # Override the default configuration for the synced_folder, using a dmode/fmode
  # to allow regular to read from the /vagrant share.
  config.vm.synced_folder '.', '/vagrant', mount_options: ['dmode=755,fmode=655']

  # Create generated RTI types on VM Linux using RTI installed on Windows Host
  #
  # Generating RTI types for both Java and C++ is an operation best performed on Linux. Reason:
  # RTI ships platform-specific installers that only have native libs for a related platform, i.e.,
  # DLLs in the Windows installer; *.so's for the Linux installer. By sharing the Windows directory
  # containing the DLLs, the build on Linux will have access to the both the DLLs and *.so's to
  # bundle into Java jar.
  # So, when tasked to build/deploy updated 'schema' or 'umaa' jars, you need to:
  # * install RTI on both Windows & Linux 
  # * an RTI license is required on the Linux VM; it can be used in Windows for other RTI uses.
  # * set the RTI_WINDOWS_DLLS environment var to where the RTI installer has placed them. The
  #   current file path pattern is: ...rti_connext_dds-<version>/lib/x64Win64VS<vs-version>
  # * set need_update_to_idl to true to mount the shared folder

  # To create generated RTI types on Linux: Reference SMB mount for Windows DLLs
  need_update_to_idl = false
  has_rti_installed = need_update_to_idl && ENV.has_key?('RTI_WINDOWS_DLLS')
  if need_update_to_idl && has_rti_installed
    config.vm.synced_folder ENV['RTI_WINDOWS_DLLS'], '/rti_dlls',
                            mount_options: %w[dmode=544 fmode=444 uid=1001 gid=1001]
  end

  config.vm.synced_folder "#{ENV['HOME']}/vm_share", '/vm_share',
                          create: true,
                          mount_options: %w[dmode=744 fmode=644 uid=1001 gid=1001]


  config.vm.provider 'virtualbox' do |vb|
    vb.name = 'autonomy-18-04-lab'
    # Set to vb.gui = true to debug
    vb.gui = true

    # Memory in Meg
    vb.memory = 16384

    # Use all 8 CPU's until you can't.  The VM will be scheduling processes
    # with the host. If the host becomes unresponsive during Autonomy operations,
    # start subtracting off CPU's here until a tolerable balance is reached.
    vb.cpus = 8

    # The :id special parameter is replaced with the ID of the virtual
    # machine being created, so when a VBoxManage command requires an ID,
    # you can pass this special parameter.
    # For all available 'modifyvm' options, see
    # https://www.virtualbox.org/manual/ch08.html#vboxmanage-modifyvm
    # vb.customize ["modifyvm", :id, "--vtxux", "off"]
    vb.customize ["modifyvm", :id, "--hwvirtex", "off"]
    vb.customize ['modifyvm', :id, '--accelerate3d', 'on']
    vb.customize ['modifyvm', :id, '--accelerate2dvideo', 'on']

    # Multiple customize directives can be used. They will be executed in the
    # order given.
    vb.customize ["modifyvm", :id, "--macaddress1", "0800275B91D9"]
    vb.customize ["modifyvm", :id, "--nestedpaging", "on"]
    vb.customize ["modifyvm", :id, "--hwvirtex", "on"]
    vb.customize ["modifyvm", :id, "--nicpromisc1", "allow-all"]
    vb.customize ["modifyvm", :id, "--nictype1", "82540EM"]
    vb.customize ["modifyvm", :id, "--nic1", "nat"]

    vb.customize ["modifyvm", :id, "--macaddress2", "080027F36EF5"]
    vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
    vb.customize ["modifyvm", :id, "--nictype2", "82540EM"]
    # # "hostonly" may be an option where there is too much competition for
    # # making vehicle choices.
    vb.customize ["modifyvm", :id, "--nic2", "bridged"]

    # vb.customize ["modifyvm", :id, "--macaddress3", "080027F36EF5"]
    # vb.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
    # vb.customize ["modifyvm", :id, "--nictype3", "82540EM"]
    # "hostonly" may be an option where there is too much competition for
    # making vehicle choices.
    # vb.customize ["modifyvm", :id, "--nic3", "bridged"]

    # GPU support
    # vb.linked_clone = true

    # By default, updates to guest additions are checked on every 'vagrant up'.
    # To expedite 'vagrant up', manually manage guest addition updates by
    # uncommenting:
    # vb.check_guest_additions = false
  end

  config.vm.provision 'file', source: '~/.ssh/secrets_pwd.txt',
                              destination: '/tmp/secrets_pwd.txt'

  config.vm.provision 'shell' do |s|
    s.inline = "echo VM IP: $(ip -family inet a | egrep '(192|10|172)\\.' | awk '{print $2}')"
  end

  config.vm.provision 'ansible_local' do |ansible|
    # ansible.verbose = 'vvv'
    ansible.compatibility_mode = "2.0"
    ansible.config_file = 'ansible.cfg'
    ansible.playbook = 'site.yml'
    ansible.vault_password_file = '/tmp/secrets_pwd.txt'

    ansible.galaxy_role_file = 'roles/requirements.yml'
    ansible.galaxy_roles_path = './roles'
    ansible.galaxy_command = "ansible-galaxy install -r %{role_file}"

    has_tags_arg = ENV.has_key?('ANSIBLE_ARGS') && ENV.fetch('ANSIBLE_ARGS').downcase.include?('tags')
    ansible.skip_tags = ['debug','enable_guest'] unless has_tags_arg

    # Enable the guest account for someone to login remote over using bridged
    # network. Replace 'meeseeks' with something only you and your guest share.
    # PS> $env:ANSIBLE_ARGS='--tags "debug"'; vagrant up --provision; $env:ANSIBLE_ARGS=""
    # PS> $env:ANSIBLE_ARGS='--tags "enable_guest" --extra-vars "guest_password=meeseeks"'; vagrant up --provision; $env:ANSIBLE_ARGS=""
    # To check what will run given a set of tags:
    # PS> $env:ANSIBLE_ARGS='--tags "new" --list-tasks'; vagrant up --provision; $env:ANSIBLE_ARGS=""
    ansible.raw_arguments = Shellwords.shellsplit(ENV['ANSIBLE_ARGS']) if ENV['ANSIBLE_ARGS']
  end

  config.vm.provision 'shell' do |s|
    s.inline = 'rm /tmp/secrets_pwd.txt'
  end

end
