#-- scenario file --#
# when mouse have to alternately lick either port (3x) to get water
# to motivate exploratory licking, can press spacebar to give free drop of water
# pure-tone sounds are also played when reward is delivered, so mouse gets used to cue
# modified from MJ phase1_Alternation 2/14/2017
# correct display window bug 2/16/2107
# modified from GS phase1_ALTERNATION_2-arm-bandit_GS.sce 5/8/2017
# R-WN-R-WN-R-WN-L-WN-L-WN-L-WN

#-------HEADER PARAMETERS-------#
scenario = "phase1_ALTERNATION_2-arm-bandit_HW";
active_buttons = 3;							#how many response buttons in scenario
button_codes = 1,2,3;
target_button_codes = 1,2,3;
response_logging = log_all;				#log all trials
response_matching = simple_matching;	#response time match to stimuli
default_all_responses = true;
begin;

#-------SOUND STIMULI-------#
sound {
	wavefile { filename ="tone_5000Hz_0.2Dur.wav"; preload = true; };
} go;

sound {
	wavefile { filename ="white_noise_3s.wav"; preload=true; };
} whitenoise;



#-------SDL EVENTS ('TRIALS')-------#
#trial {
#   trial_type = fixed;
#   trial_duration = 1;
#	nothing {} startexptevent;
#   code=5;
#}startexpt;

trial {
	trial_type = fixed;
	trial_duration = 2900;
   nothing {} rewardleftevent;
   time=0;
	code=4;
}rewardleft;

trial {
	trial_type = fixed;
	trial_duration = 2900;
   nothing {} rewardrightevent;
	time=0;
	code=8;
}rewardright;

trial { #INTERVAL BETWEEN REWARD PULSES
   trial_type = fixed;
   trial_duration = 100; #to prevent conflicts on the output port
}interpulse;

#trial {
#	trial_type = correct_response;    # 0~3000ms no lick acount, after that trial terminates once licking
#	trial_duration = 2000;   # MJ set grace period to 4s to interupt the rythm (lll-rrr-lll-rrr)
#	nothing {} leftcorrectevent;
#  time=3000;
#	code=00;
#	target_button = 2;
#}leftcorrect;

#trial {
#	trial_type = correct_response;
#	trial_duration = 3100;
#	nothing {} rightcorrectevent;
#  time=3000;
#   code=11;
#	target_button = 3;
#}rightcorrect ;

trial {
   trial_type = first_response;
   trial_duration = 2000;
	sound go;
   code=10;
}waitlick;

trial {
   trial_type = fixed;
   nothing {} randomblockevent;
   code=22;
}randomblock;

trial {
  trial_type = fixed;
  sound whitenoise;
  code=19;
}nolick;

trial {
	trial_type = fixed;
	trial_duration = 2000;
	nothing {} pauseevent;
	code=7;
} pause;

trial {
  trial_type = correct_response;
  trial_duration = 500;
  sound go;
  code = 000;
}gocue;

#trial {
#   trial_type = fixed;
#   trial_duration = 3000; #6000 FOR RECORDING; 1000 FOR TRAINING
#	nothing {} endexptevent;
#   code=7; #port_code=3.5;
#   response_active = true; # stimulus recorded but not used
#}endexpt;


trial {
   save_logfile {
		filename = "temp.log"; 	# use temp.log in default logfile directory
	};									#save logfile during mid-experiment
}quicksave;

#-------PCL-------#

begin_pcl;

#for generating exponential distribution （go block)
double minimum_go=0.0;
double mu=0.2; #rate parameter for exponential distribution
double truncate_go=1.0;
double expval=0.0;

#for generating exponetial distribution (white noise block)
double minimum_wn=2.0;
#double mu=0.2; #rate parameter for exponential distribution
double truncate_wn=3.0;
#double expval=0.0;

#SETUP TERMINAL WINDOW
term.print("Starting time:");
term.print(date_time());
logfile.add_event_entry(date_time());
display_window.draw_text("Initializing...");

#SETUP PARAMETER WINDOW
parameter_window.remove_all();
int leftmanualfeedIndex = parameter_window.add_parameter("Left Manualfeed");
int rightmanualfeedIndex = parameter_window.add_parameter("Right Manualfeed");
int leftlickIndex = parameter_window.add_parameter("Left Lick");
int rightlickIndex = parameter_window.add_parameter("Right Lick");
#int missIndex = parameter_window.add_parameter("ConsecMiss");


#CONFIGURE OUTPUT PORT
output_port port = output_port_manager.get_port(1);

#INITIALIZE VARIABLES
int num_trials = 1000;
preset int waterAmount_left = 14;	# #msec to open water valve
preset int waterAmount_right = 14;

#preset int max_consecMiss = 20;                                                                                 ; #triggers end session, for mice, set to 20
#int consecMiss = 0;

preset int num_rewards=1000; # user enters initial value in dialog before scenario
int leftmanualfeed=0;
int rightmanualfeed=0;
int leftlick=0;
int rightlick=0;

int currdir=0;	#0 = should lick left, 1 = should lick right
int currrep=0;	#every 3 rewards, he has to switch port

int lastRespTime=clock.time();

#SUBROUTINES
sub #DELIVER REWARD AND UPDATE LASTRESPTIME, LICK COUNT, REPS, AND PARAMETER WINDOW
rewardDelivery(string side)
begin
	int code; int pulse_dur; trial reward;
	if side=="left" then
		code = 4; pulse_dur = waterAmount_left;
		reward = rewardleft;
		leftlick = leftlick + 1;
		parameter_window.set_parameter(leftlickIndex,string(leftlick));
		currrep=currrep+1;
	elseif side=="right" then
		code = 8; pulse_dur = waterAmount_right;
		reward = rewardright;
		rightlick = rightlick + 1;
		parameter_window.set_parameter(rightlickIndex,string(rightlick));
		currrep=currrep+1;
	end;
	lastRespTime=clock.time();
	port.set_pulse_width(pulse_dur);
	port.send_code(code);		#give water reward to right
	interpulse.present();
	port.send_code(code);	#second pulse
	reward.present();


end;

sub #DELIVER REWARD AND UPDATE LASTRESPTIME, LICK COUNT, REPS, AND PARAMETER WINDOW
manualrewardDelivery(string side)
begin
	int code; int pulse_dur; trial reward;
	if side=="left" then
		code = 4; pulse_dur = waterAmount_left;
		reward = rewardleft;
		leftmanualfeed = leftmanualfeed + 1;
		parameter_window.set_parameter(leftmanualfeedIndex,string(leftmanualfeed));
		currrep=currrep+1;
	elseif side=="right" then
		code = 8; pulse_dur = waterAmount_right;
		reward = rewardright;
		rightmanualfeed = rightmanualfeed + 1;
		parameter_window.set_parameter(rightmanualfeedIndex,string(rightmanualfeed));
		currrep=currrep+1;
	end;
	lastRespTime=clock.time();
	port.set_pulse_width(pulse_dur);
	port.send_code(code);		#give water reward to right
	interpulse.present();
	port.send_code(code);	#second pulse
	reward.present();
end;


display_window.draw_text("Water reward with alternate left/right port...");

loop
	int i = 1
until
	i > num_trials || leftlick+rightlick>=num_rewards
begin

#startexpt.present();

#TRIAL ONE, CUE LEFT LICK WITH UPSWEEP
if i==1 then
	port.set_pulse_width(500);  #send pulse to ScanImage for synchronization later
	port.send_code(32);
	waitlick.present();
	currdir = 0;
	if (response_manager.hits()>0) then	#if licking left
		rewardDelivery("left")
	end;
end;

# IF CONSEC HITS ON SAME SIDE > 2, SWITCH TARGET SIDE
if (currrep > 2) then
	port.set_pulse_width(500);  #send pulse to ScanImage for synchronization later
	port.send_code(32);
	if (currdir==0) then #if active port==LEFT
		currdir=1;	#switch to RIGHT
		currrep=0;
		#gocue.present();
		if (response_manager.hits()>0) then	#if licking right
			rewardDelivery("right")
		end;
	else
		currdir=0;	#need to alternate to left
		currrep=0;
		#gocue.present();
		if (response_manager.hits()>0) then	#if licking left
			rewardDelivery("left")
		end;
	end;
end;

#WAIT FOR CORRECT RESPONSE

loop
  expval=minimum_go-1.0/mu*log(random())
until
  expval<truncate_go
begin
  expval=minimum_go-1.0/mu*log(random())
end;

randomblock.set_duration(int(1000.0*expval));

waitlick.present();

if (currdir==0) then
	if response_manager.response_count(2)>0 then			#if licking left
		rewardDelivery("left")
	elseif response_manager.response_count(1)>0 then	#if spacebar
		manualrewardDelivery("left")
	elseif response_manager.response_count(3)>0 then    # if licking right
		pause.present()
	end;
else
	if response_manager.response_count(3)>0 then	#if licking right
		rewardDelivery("right")
	elseif response_manager.response_count(1)>0 then	#if spacebar
		manualrewardDelivery("right")
	elseif response_manager.response_count(3)>0 then    # if licking right
		pause.present()
	end;
end;

#CUE ACTIVE PORT IF NO RESPONSES IN LAST WAITLICK EVENT
#if clock.time()-lastRespTime > 20000 then  #arbitrarily shorter than trial{waitlick}.
#	port.set_pulse_width(500);  #send pulse to ScanImage for synchronization later
#	port.send_code(32);
#	if (currdir==0) then
#		go.present();
#		if (response_manager.hits()>0) then	#if left lick
#			rewardDelivery("left")
#		end;
#	else
#		go.present();
#		if (response_manager.hits()>0) then	#if right lick
#			rewardDelivery("right")
#		end;
#	end;
#end;

randomblock.present();
int nLicks=1; #initialize the lick count
   loop until nLicks == 0
	begin
     int numLicks=0;
     loop
	      expval=minimum_wn-1.0/mu*log(random())
     until
	      expval<truncate_wn
     begin
	      expval=minimum_wn-1.0/mu*log(random())
     end;
     nolick.set_duration(int(1000.0*expval));
     nolick.present();
     nLicks=response_manager.response_count();
   end;

#endexpt.present();

i=i+1;

if (i%5) == 0 then		#every 5 trials, save a temp logfile
	quicksave.present();
end;

end; #end loop


display_window.draw_text("Phase 1 training has ended.");
term.print("Ending time:");
term.print(date_time());
