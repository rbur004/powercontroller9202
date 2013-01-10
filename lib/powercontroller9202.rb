require "net/http"
require 'uri'
require 'digest/md5' 
require 'scanf' 

#Extention to the Array class to extend Array in a cleaner manner.
class PowerController9202Array < Array
  #Add the seed value to the enumerated array values
  def inject_with_index(seed=nil)
    if seed == nil
      seed = self[0]
      start = 1
    else 
      start = 0
    end
    self[start..-1].each_with_index do |a,i|
      seed = yield(seed,a,i)
    end
    return seed
  end
end

#Aviosys Inc. 9202 IP Power Controller
#PowerController provides a ruby API to the web interface
#

class PowerController9202
  VERSION = '1.0.2'
    
  attr_accessor :host #Hostname or IP address of the power controller
  attr_accessor :user #username to login as (admin)
  attr_accessor :portmap #Defoults to 4 relay version, can be set to 8 relay version, or manually set through this accessor.
  attr_reader :status #The relay state. Set this with #set_status if you manually change portmap.
  attr_writer :password
  
  PORTMAP4 = [0,0,2,5,7] #The 4 relay version of the 9202 (my two are like this)
  PORTMAP8 = [0,0,1,2,3,4,5,6,7,8] #The 8 relay version of the 9212
  RELAY_ON = 1
  RELAY_OFF = 0
  
  #PowerController.new saves the hostname, username and password and returns the instantiated class
  # on_is_off means the relays conduct power in their off state.
  #   My default is to use the relay off state as power on
  #   and the relay on state as the power being off (just a wiring decision) 
  #   This means that a powercontroller failure will leave the devices on,
  #   which is what I want.
  # portmap maps the relay number to the web interface's numbering (position on the board)
  #   I have only have 4 relays installed and they are on Port 0, 2, 5 and 7
  #   Numbering for SetIO & GetIO use 1,2,3 and 4 as relay numbers, 
  #   but the web uses the actual relay position on the board.
  #   PORTMAP maps 1..4 to the actual ports for the web interfaces commands, 
  #   so Array index 0 is unused
  
  def initialize(host, user, password, on_is_off=true, portmap=4 )
    @host = host
    @user = user
    @password = password
    @power_on = on_is_off ? RELAY_OFF : RELAY_ON
    @power_off = on_is_off ? RELAY_ON : RELAY_OFF
    @portmap = portmap == 4 ? PORTMAP4 : PORTMAP8
    set_status
  end
  
  #Fetches the relay states and return as an array of 1's and 0's
  #1 means the relay is powered (though you might be using the relay off state as power on)
  #0 means the relay is unpowered (though you might be using the relay off state as power on)
  def set_status
    Net::HTTP.start(@host) do |http|
    	response = http.get("/GetP6?")
    	if response.code.to_i == 200
    	  #print response.body
    	  @status = PowerController9202Array.new(response.body.scanf("<html>P61=%d,P62=%d,P63=%d,P64=%d</html>"))
    	else
    	  #print "Connection failed with error #{response.code}\n"
    	  raise "Connection failed with error #{response.code}\n"
      end
    end
  end
    

  #'on' is short hand for tmp_change_state(outlet, @power_on)
  #Using SetIO. Note that changes are lost after power cycle.
  def on(outlet)
    tmp_change_state(outlet, @power_on)
  end
  
  #'on' is short hand for tmp_change_state(outlet, @power_off)
  #Using SetIO. Note that changes are lost after power cycle.
  def off(outlet)
    tmp_change_state(outlet, @power_off)
  end
  
  #Ensure_on will fetch each relays state, and turn the relay on, if it is off.
  #Using SetIO. Note that changes are lost after power cycle.
  def ensure_on
    outlet = []
    @status.each_with_index do |o,i|
      if o == @power_off 
        outlet << i + 1
      end
    end
    if outlet.length > 0 #We have relays to alter the state of
      on(outlet)
    end
  end

  #toggle turns a relay off, then back on again, so the device is power cycled.
  #If the outlet argument is an array, all relays specified in the array are power cycled.
  #The time the relay is off is defined by the argument sleep_time (defoult of 5 seconds)
  def toggle(outlet, sleep_time=5)
    off(outlet)
    sleep sleep_time
    on(outlet)
  end
  
  #Toggle_all power cycles all the relays.
  #The time the relay is off is defined by the argument sleep_time (defoult of 5 seconds)
  def toggle_all(sleep_time=5)
    outlet = []
    @portmap[1..-1].each_with_index { |x,i| outlet << i+1 }
    toggle(outlet, sleep_time)
  end
  
    
  #Reset_all uses the web form reset of each relays to the OFF state
  #This persists after a device reboot, where the earlier calls do not.
  def reset_all
    login
    res = Net::HTTP.new(@host, 80).start do |http|

        post = Net::HTTP::Post.new('/tgi/ioControl.tgi')
        #setting post body this way, as set_form_data randomised the order and device expects fixed order.
        post.body = "PinNo=P6_0&P60=Off&P60_TIMER=0&P60_TIMER_CNTL=Off&" +
                    "PinNo=P6_1&P61=Off&P61_TIMER=0&P61_TIMER_CNTL=Off&" +
                    "PinNo=P6_2&P62=Off&P62_TIMER=0&P62_TIMER_CNTL=Off&" +
                    "PinNo=P6_3&P63=Off&P63_TIMER=0&P63_TIMER_CNTL=Off&" +
                    "PinNo=P6_4&P64=Off&P64_TIMER=0&P64_TIMER_CNTL=Off&" +
                    "PinNo=P6_5&P65=Off&P65_TIMER=0&P65_TIMER_CNTL=Off&" +
                    "PinNo=P6_6&P66=Off&P66_TIMER=0&P66_TIMER_CNTL=Off&" +
                    "PinNo=P6_7&P67=Off&P67_TIMER=0&P67_TIMER_CNTL=Off&" +
                    "Reset=Reset"        
        headers = {
          'User-Agent' => 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9) Gecko/2008051206 Firefox/3.0',
          'Content-Type' => 'application/x-www-form-urlencoded',
          'Referer' => "http://#{@host}/ioControl_2e.htm",
          'Cookie' => @cookie
        }
          
        response = http.post('/tgi/ioControl.tgi', post.body, headers)
        if(response.code.to_i == 200)
          @status.collect! { |v| 0 }
        end
        #puts response.code
    end
  end
  
  #timer_toggle_all calls the web form to turn off the relays for the time period
  #The earlier toggle uses the SetIO call, with an, OFF, sleep, then ON call.
  def timer_toggle_all(sleep_time=5) 
    login
    p6 = ["On","On","On","On","On","On","On","On"]
    p6_time = ["0", "0", "0", "0","0","0","0","0"]
    p6_timer = ["On","On","On","On","On","On","On","On"]
    @portmap[1..-1].each do |pm|
      p6[pm] = @power_on == "Off"
      p6_time[pm] = "#{sleep_time}"
    end

    res = Net::HTTP.new(@host, 80).start do |http|

        post = Net::HTTP::Post.new('/tgi/ioControl.tgi')
        post.body = "PinNo=P6_0&P60=#{p6[0]}&P60_TIMER=#{p6_time[0]}&P60_TIMER_CNTL=#{p6_timer[0]}" +
                    "&PinNo=P6_1&P61=#{p6[1]}&P61_TIMER=#{p6_time[1]}&P61_TIMER_CNTL=#{p6_timer[1]}" +
                    "&PinNo=P6_2&P62=#{p6[2]}&P62_TIMER=#{p6_time[2]}&P62_TIMER_CNTL=#{p6_timer[2]}" +
                    "&PinNo=P6_3&P63=#{p6[3]}&P63_TIMER=#{p6_time[3]}&P63_TIMER_CNTL=#{p6_timer[3]}" +
                    "&PinNo=P6_4&P64=#{p6[4]}&P64_TIMER=#{p6_time[4]}&P64_TIMER_CNTL=#{p6_timer[4]}" +
                    "&PinNo=P6_5&P65=#{p6[5]}&P65_TIMER=#{p6_time[5]}&P65_TIMER_CNTL=#{p6_timer[5]}" +
                    "&PinNo=P6_6&P66=#{p6[6]}&P66_TIMER=#{p6_time[6]}&P66_TIMER_CNTL=#{p6_timer[6]}" +
                    "&PinNo=P6_7&P67=#{p6[7]}&P67_TIMER=#{p6_time[7]}&P67_TIMER_CNTL=#{p6_timer[7]}" +
                    "&Apply=Apply"
       # print post.body
        
        headers = {
          'User-Agent' => 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9) Gecko/2008051206 Firefox/3.0',
          'Content-Type' => 'application/x-www-form-urlencoded',
          'Referer' => "http://#{@host}/ioControl_2e.htm",
          'Cookie' => @cookie
        }
          
        response = http.post('/tgi/ioControl.tgi', post.body, headers)
        #puts response.code
    end
  end
  

  #Timer_toggle uses the web interface's power cycling feature.
  #
  #I only have 4 relays installed and they are on Port 0, 2, 5 and 7
  #Numbering for SetIO & GetIO use 1,2,3 and 4 as relay numbers
  def timer_toggle(outlet, sleep_time=5) #
    login
    
    p6 = ["On","On","On","On","On","On","On","On"]
    p6_time = ["0", "0", "0", "0","0","0","0","0"]
    p6_timer = ["On","On","On","On","On","On","On","On"]
    p6[@portmap[outlet]] = "Off"
    p6_time[@portmap[outlet]] = "#{sleep_time}"
    
    res = Net::HTTP.new(@host, 80).start do |http|

        post = Net::HTTP::Post.new('/tgi/ioControl.tgi')
        post.body = "PinNo=P6_0&P60=#{p6[0]}&P60_TIMER=#{p6_time[0]}&P60_TIMER_CNTL=#{p6_timer[0]}" +
                    "&PinNo=P6_1&P61=#{p6[1]}&P61_TIMER=#{p6_time[1]}&P61_TIMER_CNTL=#{p6_timer[1]}" +
                    "&PinNo=P6_2&P62=#{p6[2]}&P62_TIMER=#{p6_time[2]}&P62_TIMER_CNTL=#{p6_timer[2]}" +
                    "&PinNo=P6_3&P63=#{p6[3]}&P63_TIMER=#{p6_time[3]}&P63_TIMER_CNTL=#{p6_timer[3]}" +
                    "&PinNo=P6_4&P64=#{p6[4]}&P64_TIMER=#{p6_time[4]}&P64_TIMER_CNTL=#{p6_timer[4]}" +
                    "&PinNo=P6_5&P65=#{p6[5]}&P65_TIMER=#{p6_time[5]}&P65_TIMER_CNTL=#{p6_timer[5]}" +
                    "&PinNo=P6_6&P66=#{p6[6]}&P66_TIMER=#{p6_time[6]}&P66_TIMER_CNTL=#{p6_timer[6]}" +
                    "&PinNo=P6_7&P67=#{p6[7]}&P67_TIMER=#{p6_time[7]}&P67_TIMER_CNTL=#{p6_timer[7]}" +
                    "&Apply=Apply"
  
        #a = post.body.split(/&PinNo/)
        #a.each {|x| print "#{x}\n&PinNo" }
        
        headers = {
          'User-Agent' => 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9) Gecko/2008051206 Firefox/3.0',
          'Content-Type' => 'application/x-www-form-urlencoded',
          'Referer' => "http://#{@host}/ioControl_2e.htm",
          'Cookie' => @cookie
        }
          
        response = http.post('/tgi/ioControl.tgi', post.body, headers)
        #puts response.code
    end
  end
    
  #'on2' is short hand for change_state(outlet, PowerController::ON)
  #Uses the web interface, so unlike 'on', this persists after a device reboot
  def on2(outlet) #Uses the web interfaces, not SetIO
    change_state(outlet, @power_on == 1 ? "On" : "Off")
  end
  
  #'off2' is short hand for change_state(outlet, PowerController::ON)
  #Uses the web interface, so unlike 'off', this persists after a device reboot
  def off2(outlet) #Uses the web interfaces, not SetIO
    change_state(outlet, @power_off == 0 ? "Off" : "On")
  end
 
  #Return a status string, with named ports specified in the port_names array.
  def to_s(port_names = [nil,nil,nil,nil ])
    @status.inject_with_index("") { |s,x,i| s + "Port #{i+1}=#{x==0 ? 'On' : 'Off'} #{if port_names[i] then port_names[i] end}\n" } 
  end
  
  private
  #change_state uses the web interface to turn relays On or Off
  #This persists after a device reboot, where the earlier calls do not.
  #
  #More Useful is tmp_change_state, as this doesn't get saved on the device.
  #
  def change_state(outlet,state)
    login
    
    p6 = set_p6
    p6_time = ["0", "0", "0", "0","0","0","0","0"]
    p6_timer = ["On","On","On","On","On","On","On","On"]
    if outlet.class == Array
      outlet.each { |o| p6[@portmap[o]] = state }
    else
      p6[@portmap[outlet]] = state
    end
    
    res = Net::HTTP.new(@host, 80).start do |http|

        post = Net::HTTP::Post.new('/tgi/ioControl.tgi')
        post.body = "PinNo=P6_0&P60=#{p6[0]}&P60_TIMER=#{p6_time[0]}&P60_TIMER_CNTL=#{p6_timer[0]}" +
                    "&PinNo=P6_1&P61=#{p6[1]}&P61_TIMER=#{p6_time[1]}&P61_TIMER_CNTL=#{p6_timer[1]}" +
                    "&PinNo=P6_2&P62=#{p6[2]}&P62_TIMER=#{p6_time[2]}&P62_TIMER_CNTL=#{p6_timer[2]}" +
                    "&PinNo=P6_3&P63=#{p6[3]}&P63_TIMER=#{p6_time[3]}&P63_TIMER_CNTL=#{p6_timer[3]}" +
                    "&PinNo=P6_4&P64=#{p6[4]}&P64_TIMER=#{p6_time[4]}&P64_TIMER_CNTL=#{p6_timer[4]}" +
                    "&PinNo=P6_5&P65=#{p6[5]}&P65_TIMER=#{p6_time[5]}&P65_TIMER_CNTL=#{p6_timer[5]}" +
                    "&PinNo=P6_6&P66=#{p6[6]}&P66_TIMER=#{p6_time[6]}&P66_TIMER_CNTL=#{p6_timer[6]}" +
                    "&PinNo=P6_7&P67=#{p6[7]}&P67_TIMER=#{p6_time[7]}&P67_TIMER_CNTL=#{p6_timer[7]}" +
                    "&Apply=Apply"
  
        #a = post.body.split(/&PinNo/)
        #a.each {|x| print "#{x}\n&PinNo" }
        
        headers = {
          'User-Agent' => 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9) Gecko/2008051206 Firefox/3.0',
          'Content-Type' => 'application/x-www-form-urlencoded',
          'Referer' => "http://#{@host}/ioControl_2e.htm",
          'Cookie' => @cookie
        }
          
        response = http.post('/tgi/ioControl.tgi', post.body, headers)
        
        #puts response.code
        if(response.code.to_i == 200)
          if outlet.class == Array
            outlet.each { |o| @status[o-1] = (state == "On" ? 0 : 1) }
          else
            @status[outlet-1] = (state == "On" ? 0 : 1)
          end
        end
    end
  end

  #chonge_state1 takes arguments 
  #  outlet, being the relay to change the state of power to the relay
  #Uses SetIO. Note: changes are lost after power cycle of the 9202.
  def tmp_change_state(outlet, state) 
    if outlet.class == Array
      get_str = "/SetIO?"
      outlet.each_with_index do |o,i|
        get_str += "+" if i > 0 
        get_str += "P6#{o}=#{state}" 
      end
    else
      get_str = "/SetIO?P6#{outlet}=#{state}"
    end

    Net::HTTP.start(@host) do |http|
      request = Net::HTTP::Get.new(get_str)
      request.basic_auth @user, @password
    	response = http.request(request)
    	if response.code.to_i == 200
    	  #print response.body
        if outlet.class == Array
          outlet.each { |o| @status[o-1] = state }
        else
          @status[outlet-1] = state
        end
          
    	else
    	  #print "Connection failed with error #{response.code}\n"
    	  raise "Connection failed with error #{response.code}\n"
      end
    end
  end

  #Authenticates to the IP Powercontroller's web server
  #Credentials were passed in to PowerController.new()
  def login #web interface needs a special login
    res = Net::HTTP.new(@host, 80).start do |http|   
      response = http.get("/")
      if response.code.to_i == 200
        challenge = response.body.scan(/NAME=\"Challenge\" VALUE=\n\"(.*)\">/)
      else
      	#print "Connection failed with error #{response.code}\n"
    	raise "Connection failed with error #{response.code}\n"
      	return
      end

      #authorize
      post = Net::HTTP::Post.new('/tgi/login.tgi')
      post.set_form_data( {"Submitbtn" => "OK", "Username" => "admin", "Password" => "", 
                          "Challenge" => "", "Response" => Digest::MD5.hexdigest("admin" + @password + challenge.to_s)} )

      response = http.request(post)
      if response == nil
        raise "Failed: no response"
      elsif response.code.to_i == 200 
        if (response_text = response.response['set-cookie']) != nil
          @cookie = response_text.split(';')[0]
        else
          raise "Failed"
        end
      else
        raise "Failed: #{response.code}"
      end
      #puts @cookie 
    end    
  end

  # Sets up the p6 array with the devices active ports. Mine has only 4 of 8 available.
  def set_p6
    p6 = ["On","On","On","On","On","On","On","On"]
    @status.each_with_index { |x,i| p6[@portmap[i+1]] = x == 1 ? "Off" : "On" }
    return p6
  end
end

