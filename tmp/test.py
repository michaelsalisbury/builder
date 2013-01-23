#!/usr/bin/python

import dbus
import sys
# import itertools

session_bus = dbus.SessionBus()
system_bus = dbus.SystemBus()

proxy = system_bus.get_object('org.freedesktop.NetworkManager','/org/freedesktop/NetworkManager')

interface = dbus.Interface(proxy,dbus_interface='org.freedesktop.NetworkManager')

for path in interface.GetDevices():
	print "--------------------------------------------------"
	print path
	print "--------------------------------------------------"
	device_obj = system_bus.get_object('org.freedesktop.NetworkManager', path)
	device_int = dbus.Interface(device_obj,dbus_interface='org.freedesktop.DBus.Properties')
	print "\n","### org.freedesktop.NetworkManager.Device ###"
	prop_dev = device_int.GetAll('org.freedesktop.NetworkManager.Device')
	for prop in prop_dev:
		print prop, "\t", prop_dev[prop]
	print "\n","### org.freedesktop.NetworkManager.Device.Wired ###"
	prop_dev = device_int.GetAll('org.freedesktop.NetworkManager.Device.Wired')
	for prop in prop_dev:
		print prop, "\t", prop_dev[prop]
	print "\n","### org.freedesktop.NetworkManager.Device.Wired ###"

print
print "--------------------------------------------------"
obj_path = interface.GetDeviceByIpIface("eth2")
obj      = system_bus.get_object('org.freedesktop.NetworkManager', obj_path)
obj_int  = dbus.Interface(obj,dbus_interface='org.freedesktop.NetworkManager.Device')
#print obj_int.Disconnect()
obj_prop = dbus.Interface(obj,dbus_interface='org.freedesktop.DBus.Properties')
obj_conn = obj_prop.GetAll('org.freedesktop.NetworkManager.Device')['ActiveConnection']
#print interface.DeactivateConnection(obj_conn)

print obj_path
#print interface.ActivateConnection("/",obj_path,"/")
print interface.AddAndActivateConnection("",interface.GetDeviceByIpIface("eth0"),"/")





print "--------------------------------------------------"
sys.exit("hello world")





perms = interface.GetPermissions()



for perm in perms:
	print perm

print interface.state()
print proxy.state()

print "------------------------------------"
print interface.AddAndActivateConnection("",proxy.GetDeviceByIpIface("eth0"),"/")
#print interface.AddAndActivateConnection("",proxy.GetDeviceByIpIface("eth1"),"/")
print interface.GetDeviceByIpIface("eth0")



print "------------------------------------"

new_obj  = system_bus.get_object('org.freedesktop.NetworkManager','/org/freedesktop/NetworkManager')
new_int  = dbus.Interface(new_obj,dbus_interface='org.freedesktop.DBus.Properties')
new_prop = new_int.GetAll('org.freedesktop.NetworkManager')

for prop in new_prop:
	print new_prop[prop], "\t", prop


print "------------------------------------"

obj2 = system_bus.get_object('org.freedesktop.NetworkManager','/org/freedesktop/NetworkManager/Devices/0')
int2 = dbus.Interface(obj2,dbus_interface='org.freedesktop.DBus.Properties')
all2 = int2.GetAll('org.freedesktop.NetworkManager.Device')


for prop in all2:
	print all2[prop], "\t", prop

