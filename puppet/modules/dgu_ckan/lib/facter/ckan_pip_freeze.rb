
ckan_virtualenv = "/home/co/ckan"

Facter.add("ckan_virtualenv") do
  setcode do
    ckan_virtualenv
  end
end
Facter.add("ckan_pip_freeze") do
  setcode do
    # Concatenated list of packages
    packagelist = Facter::Util::Resolution.exec(ckan_virtualenv+"/bin/pip freeze")
    packagelist = (packagelist or "NOTREADY")
    packagelist = packagelist.gsub(/\r/," ")
    packagelist = packagelist.gsub(/\n/," ")
    packagelist
  end
end
