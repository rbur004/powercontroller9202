require '../lib/powercontroller9202.rb'

#Default to relay off state being a power on state
pc = PowerController9202.new("192.168.249.128", "admin", "xxxxx")

#change so relay off state is a power off state
#pc = PowerController9202.new("192.168.249.128", "admin", "xxxxxx", false)

#8 relays, not 4
#relay off state is a power on state
#pc = PowerController9202.new("192.168.249.128", "admin", "xxxxxx", true, 8)

#Manually set the portmap. Nb portmap[0] is unused.
#pc = PowerController9202.new("192.168.249.128", "admin", "xxxxxx")
#pc.portmap = [0,0,2,5,7,1,3,4,6] 
#pc.set_status #to update the status bitmap


puts pc.status.to_s #current relay states as array of 0's and 1's for relay off and on
puts pc.to_s(['server', 'modem', 'lights', 'tv']) #outputs relay status with names.
puts pc #Prints the relay status (Equivalent to puts pc.to_s )

######################### EXIT ########################
exit #currently testing against an installed controller , as the test version failed.

#Power on means the relay switch the power on, even if the relay power is off
#Relay on, means the relay is powered, but that might mean the power is then off.
pc.ensureon   #Turns all relays to the power on state (not saved)
pc.off([2,4])  #Turns relays 2 and 4 power off (not saved)
pc.on([2,4])   #Turns relays 2 and 4 power on (not saved)


pg.toggle_all     #Turns power off for 5 seconds through all relays (understands my off is on)
pg.toggle_all(10) #Turns power on for 10 seconds through all relays (understands my off is on)


pc.toggle(1)     #Turns power off for 5 seconds through relay 1(understands my off is on).
pc.toggle(1,10)  #Turns power off for 10 seconds through relay 1 (understands my off is on)

pc.toggle([1,4]) #Turns power off for 5 seconds through relay 1 & 4 (understands my off is on)
pc.toggle([2,3],10) #Turns power off for 10 seconds through relays 2 & 3 (understands my off is on).

#Via the web form, rather thon SetIO
pc.reset_all  #Sets relays to off state (Relays off, not necessarily power off)
           #For mine, that is an on state as I want the failure state to be on
           #The web interface shows them as off though.

#Via the web form, rather thon SetIO
pc.timer_toggle_all #Turns off the relays, then on again after 5 seconds
pc.timer_toggle_all(10) #Turns off the relays, then on again after 10 seconds

#Via the web form, rather thon SetIO
pc.on2(3)  #Turns relay 3 power on and it shows up that way in the web interface.
           #Hence will be set this way after the 9202 is power cycled.
pc.off2(2) #Turns relay 2 power off and it shows up that way in the web interface.
           #Hence will be set this way after the 9202 is power cycled.
