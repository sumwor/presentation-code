#-- scenario file --#
# when I press spacebar, give it water
# when mouse licks either port, give it water
# count water given by manualfeed or induced by licks
# modified from phase0, 500 ms go cue, 3-4s free water, 2-3s no water with white noise

scenario = "phase0_bothports";

active_buttons = 3;	#how many response buttons in scenario
button_codes = 1,2,3;
#target_button_codes = 1,2,3;
# write_codes = true;	#using analog output port to sync with electrophys
response_logging = log_all;	#log all trials
response_matching = simple_matching;	#response time match to stimuli

begin;

#-------SOUND STIMULI-------#
sound {
	wavefile { filename ="tone_5000Hz_0.2Dur.wav"; preload = true; };
} go;

sound {
	wavefile { filename ="white_noise_3s.wav"; preload=true; };
} whitenoise;


#--------trial---------#
trial {
   save_logfile {
		filename = "temp.log"; 	# use temp.log in default logfile directory
	};									#save logfile during mid-experiment
}quicksave;

trial {
	trial_type = fixed;
	trial_duration = 2900;	#at least 500ms between water
	nothing {} waterrewardexptevent;
	code=3;
	response_active = true; #still record the licks
}waterreward;

trial {
   trial_type = fixed;
   trial_duration = 100;
	nothing {} interpulseevent;
}interpulse;

trial {
   trial_type = first_response;
   trial_duration = 2000;
	sound go;
   code=0;
}waitlick;

trial {
   trial_type = fixed;
	trial_duration = 500;
   nothing {} randomblockevent;
   code=22;
}randomblock;

trial {
  trial_type = fixed;
  trial_duration = 2500;
  sound whitenoise;
  code=19;
}nolick;

begin_pcl;

#for generating exponential distribution （go block)
double minimum_go=0.0;
double mu=0.2; #rate parameter for exponential distribution
double truncate_go=1.0;
double expval=0.0;

#for generating exponetial distribution (white noise block)
double minimum_wn=2.0;
double mu_wn=0.2; #rate parameter for exponential distribution
double truncate_wn=3.0;
double expval_wn=0.0;

term.print("Starting time:");
term.print(date_time());
logfile.add_event_entry(date_time());

display_window.draw_text("Initializing...");

int num_trials = 400;  # user enters initial value in dialog before scenario
preset int waterAmount_left = 14;
preset int waterAmount_right = 12;

preset int max_consecMiss = 20;                                                                                 ; #triggers end session, for mice, set to 20
int consecMiss = 0;
	# #msec to open water valve
int manualfeed=0;
int leftlick=0;
int rightlick=0;

parameter_window.remove_all();
int manualfeedIndex = parameter_window.add_parameter("Manual feed");
int leftlickIndex = parameter_window.add_parameter("Left Lick");
int rightlickIndex = parameter_window.add_parameter("Right Lick");
int missIndex = parameter_window.add_parameter("ConsecMiss");
int trialIndex = parameter_window.add_parameter("trial_num");
#int nolickIndex = parameter_window.add_parameter("noLick");
# set up parallel port for water reward
output_port port = output_port_manager.get_port(1);

display_window.draw_text("Water reward with left lick or right lick or Spacebar...");

loop
	int i = 1
until
	i > num_trials
begin
	int noLick=0;
	int random = 0;
	waitlick.present();

	if response_manager.response_count()>0 then
		if (response_manager.last_response() == 1) then	#if spacebar
			port.set_pulse_width(waterAmount_left);
			port.send_code(4);		#give water reward to left
			interpulse.present();
			port.send_code(4);	#second pulse
			port.set_pulse_width(waterAmount_right);
			port.send_code(8);		#give water reward to right
			interpulse.present();
			port.send_code(8);	#second pulse
			waterreward.present();
			manualfeed = manualfeed + 1;
			parameter_window.set_parameter(manualfeedIndex, string(manualfeed));
			consecMiss=0;
		elseif (response_manager.last_response() == 2) then	#if licking left
			port.set_pulse_width(waterAmount_left);
			port.set_pulse_width(waterAmount_left);
			port.send_code(4);		#give water reward to left
			interpulse.present();
			port.send_code(4);	#second pulse
			waterreward.present();
			leftlick = leftlick + 1;
			parameter_window.set_parameter(leftlickIndex,string(leftlick));
			consecMiss=0;
			parameter_window.set_parameter(missIndex,string(consecMiss));
		elseif (response_manager.last_response() == 3) then	#if licking right
			port.set_pulse_width(waterAmount_right);
			port.send_code(8);		#give water reward to right
			interpulse.present();
			port.send_code(8);	#second pulse
			waterreward.present();
			rightlick = rightlick + 1;
			parameter_window.set_parameter(rightlickIndex,string(rightlick));
			consecMiss=0;
			parameter_window.set_parameter(missIndex,string(consecMiss));
		end;
		
	else
		consecMiss=consecMiss+1;
		parameter_window.set_parameter(missIndex,string(consecMiss));
	end;
	
	loop
		expval=minimum_go-1.0/mu*log(random())
	until
		expval<truncate_go
	begin
		expval=minimum_go-1.0/mu*log(random());
		random = random +1;
		#parameter_window.set_parameter(randomIndex, string(random));
	end;
	
	randomblock.set_duration(int(1000.0*expval));
	randomblock.present();
	
	#logfile.add_event_entry("nolickloop_begin");
   loop
	   expval_wn=minimum_wn-1.0/mu_wn*log(random())
   until
	   expval_wn<truncate_wn
   begin
	   expval_wn=minimum_wn-1.0/mu_wn*log(random());
		noLick = noLick + 1;
		#parameter_window.set_parameter(nolickIndex, string(noLick));
   end;
	#logfile.add_event_entry("nolick_begin");
   nolick.set_duration(int(1000.0*expval_wn));
   nolick.present();
	i=i+1;
	parameter_window.set_parameter(trialIndex,string(i));

	if (i%5) == 0 then		#every 5 trials, save a temp logfile
		quicksave.present();
	end;

end;


display_window.draw_text("Free water session has ended.");
term.print("Ending time:");
term.print(date_time());
