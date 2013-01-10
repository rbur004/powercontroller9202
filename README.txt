= powercontroller9202

* http://rbur004.github.com/powercontroller9202/
* Source https://github.com/rbur004/powercontroller9202
* Gem https://rubygems.org/gems/powercontroller9202

== DESCRIPTION:

A Ruby GEDCOM to communicate with an Aviosys Inc. 9202 IP Power Controller (and associated products (eg 9212)).
  
== FEATURES/PROBLEMS:

* see the status of the relays
* turns relays on and off without altering the saved state on power up
* turns relays on and off, and alters the saved state for next power up
* Toggles any or all relays

== SYNOPSIS:

	require 'powercontroller9202'
	
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



== REQUIREMENTS:

* require 'rubygems'
* require 'powercontroller9202'

== INSTALL:

* sudo gem install powercontroller9202

== LICENSE:

Distributed under the Ruby License.

Copyright (c) 2009

1. You may make and give away verbatim copies of the source form of the
   software without restriction, provided that you duplicate all of the
   original copyright notices and associated disclaimers.

2. You may modify your copy of the software in any way, provided that
   you do at least ONE of the following:

     a) place your modifications in the Public Domain or otherwise
        make them Freely Available, such as by posting said
  modifications to Usenet or an equivalent medium, or by allowing
  the author to include your modifications in the software.

     b) use the modified software only within your corporation or
        organization.

     c) rename any non-standard executables so the names do not conflict
  with standard executables, which must also be provided.

     d) make other distribution arrangements with the author.

3. You may distribute the software in object code or executable
   form, provided that you do at least ONE of the following:

     a) distribute the executables and library files of the software,
  together with instructions (in the manual page or equivalent)
  on where to get the original distribution.

     b) accompany the distribution with the machine-readable source of
  the software.

     c) give non-standard executables non-standard names, with
        instructions on where to get the original software distribution.

     d) make other distribution arrangements with the author.

4. You may modify and include the part of the software into any other
   software (possibly commercial).  But some files in the distribution
   may not have been written by the author, so that they are not under this terms.

5. The scripts and library files supplied as input to or produced as 
   output from the software do not automatically fall under the
   copyright of the software, but belong to whomever generated them, 
   and may be sold commercially, and may be aggregated with this
   software.

6. THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
   WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
   PURPOSE.
