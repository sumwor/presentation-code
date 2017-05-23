#-- scenario file --#
# when mouse have to alternately lick either port (3x) to get water
# to motivate exploratory licking, can press spacebar to give free drop of water
# pure-tone sounds are also played when reward is delivered, so mouse gets used to cue
# modified from MJ phase1_Alternation 2/14/2017
# correct display window bug 2/16/2107
# modified from GS phase1_ALTERNATION_2-arm-bandit_GS.sce 5/8/2017
# 2 blocks: L70%R10% & L10%R70%

#-------HEADER PARAMETERS-------#
scenario = "2-arm-bandit_RL_task_HW";
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

#different start experiment trials for different blocks
#trial {
#   trial_type = fixed;
#   trial_duration = 1;
#	nothing {} startexptevent;
#   code=71;
#}startexptL70R10;

#trial {
#  trial_type = fixed;
#  trial_duration = 1;
#  nothing {} startexpeevent;
#  code = 17;
#}startexptL10R70;

trial {
	trial_type = fixed;
	trial_duration = 2900;
   nothing {} rewardleftcorrectevent;
   time=0;
	code=4;
}rewardleftcorrect;

trial {
  trial_type = fixed;
  trial_duration = 2900;
  nothing {} rewardleftincorrectevent;
  time = 0;
  code = 40;
}rewardleftincorrect;  #this trial represents lick left, get reward in R70% block

trial {
	trial_type = fixed;
	trial_duration = 2900;
   nothing {} rewardrightcorrectevent;
	time=0;
	code=8;
}rewardrightcorrect;

trial {
  trial_type = fixed;
  trial_duration = 2900;
  nothing {} rewardrightincorrectevent;
  time = 0;
  code = 80;
}rewardrightincorrect;

trial { #INTERVAL BETWEEN REWARD PULSES
   trial_type = fixed;
   trial_duration = 100; #to prevent conflicts on the output port
}interpulse;

trial {
	trial_type = correct_response;    # 0~3000ms no lick account, after that trial terminates once licking
	trial_duration = 3000;   # MJ set grace period to 4s to interrupt the rhythm (lll-rrr-lll-rrr)
	nothing {} leftincorrectnorewardevent;
   time=3000;
	code= 100;
	target_button = 2;
}leftincorrectnoreward;

trial {
  trial_duration=3000;
  nothing {} leftcorrectnorewardevent;
  time = 3000;
  code = 101;
  target_button = 2;
}leftcorrectnoreward;

trial {
	trial_type = correct_response;
	trial_duration = 3000;
	nothing {} rightcorrectnorewardevent;
   time=3000;
   code=111;
	target_button = 3;
}rightcorrectnoreward;

trial {
  trial_duration=3000;
  nothing {} rightincorrectnorewardevent;
  time = 3000;
  code = 110;
  target_button = 3;
}rightincorrectnoreward;

trial {
   trial_type = first_response;
   trial_duration = 2000;
	sound go;
   code=17;
}waitlickL70R10;

trial {
   trial_type = first_response;
   trial_duration = 2000;
	sound go;
   code=17;
}waitlickL10R70;


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
	trial_duration = 1000;
	nothing {} pauseevent;
	code=77;
} pause;

#trial {
#  trial_type = correct_response;
#  trial_duration = 500;
#  sound go;
#  code = 000;
#}gocue;

#trial {
#   trial_type = fixed;
#   trial_duration = 50; #6000 FOR RECORDING; 1000 FOR TRAINING#
#	nothing {} endexptevent;
#   code=7; #port_code=3.5;
#   response_active = true; # stimulus recorded but not used
#}endexpt;


trial {
   save_logfile {
		filename = "temp.log"; 	# use temp.log in default logfile directory
	};									#save logfile during mid-experiment
}quicksave;


#--------PCL---------------
begin_pcl;

#HEADER

term.print("Starting time:");
term.print(date_time());
logfile.add_event_entry(date_time());
string startTime = (date_time());

display_window.draw_text("Initializing...");

#SETUP PARAMETER WINDOW
parameter_window.remove_all();
int left_correct_rewardIndex = parameter_window.add_parameter("LCR");
int left_correct_no_rewardIndex = parameter_window.add_parameter("LCN");
int left_incorrect_rewardIndex = parameter_window.add_parameter("LIR");
int left_incorrect_no_rewardIndex = parameter_window.add_parameter("LIN");

int right_correct_rewardIndex = parameter_window.add_parameter("RCR");
int right_correct_no_rewardIndex = parameter_window.add_parameter("RCN");
int right_incorrect_rewardIndex = parameter_window.add_parameter("RIR");
int right_incorrect_no_rewardIndex = parameter_window.add_parameter("RIN");

int consecmissIndex = parameter_window.add_parameter("Consec Miss");
int nTrials_hit_totalIndex = parameter_window.add_parameter("Hit");
int trialnumIndex = parameter_window.add_parameter("Trial num");
int hit_rateIndex=parameter_window.add_parameter("hit_rate");
int geo_Index=parameter_window.add_parameter("Geo_sample");
int leftreward_rate=parameter_window.add_parameter("Left Reward Rate");
int rightreward_rate=parameter_window.add_parameter("Right Reward Rate");
# int expIndex=parameter_window.add_parameter("ITI(ms)");
#CONFIGURE OUTPUT PORT
output_port port = output_port_manager.get_port(1);




#INITIALIZE VARIABLES
int block = int(ceil(random()*double(2))); #randomize the start block
#for now, two blocks presented: Left70% & Right10%; Left10% & Right70%



int button = 0; #temporary for debug
int nTrials_hit = 0; #trials passed in current block
int nTrials_hit_total = 0;
preset int max_consecMiss = 20;                                                                                 ; #triggers end session, for mice, set to 20
int consecMiss = 0;

int left_correct_reward=0;
int left_correct_no_reward=0;
int left_miss=0;
int left_incorrect_reward=0;
int left_incorrect_no_reward=0;
int right_correct_reward=0;
int right_correct_no_reward=0;
int right_miss=0;
int right_incorrect_reward=0;
int right_incorrect_no_reward=0;
int num_trials=0;

#array<int> hit_count[0];

#array<int> leftCorrReward[0]; #1: correct+reward; 0: correct+noreward
#array<int> rightIncorrReward[0];
#array<int> leftIncorrReward[0];
#array<int> rightCorrReward[0];

preset int waterAmount_left = 18;    #   14~3.3uL 2/14/2017
preset int waterAmount_right = 16;

double reward_threshold = double(0); #threshold for reward, will change later in the code
double i_geo=double(0) ;  # block switch index
int block_length=0;
double  ii=double(1);  # sample from geometric distribution
double m=double(0);

string side;

#for generating exponetial distribution (random time interval following the reward period)
double minimum_go=0.0;
double mu=0.2; #rate parameter for exponential distribution
double truncate_go=1.0;
double expval=0.0;

#for generating exponetial distribution (white noise block)
double minimum_wn=2.0;
#double mu=0.2; #rate parameter for exponential distribution
double truncate_wn=3.0;
#double expval=0.0;


#-------------TRIAL STRUCTURE------------------------------

loop
	int i = 1
until
	consecMiss >= max_consecMiss
begin

	port.set_pulse_width(500);  #send pulse to ScanImage for synchronization later
	port.send_code(32);



# sample from truncated geometric distribution, update only after switch of high reward port
	if i_geo==double(0) && block_length==0 then
		double shift_threshold = 1.000-0.0909; # success probability = 1/(mean+1),  0.0909
		m=ceil(double(950)*random());
		ii=double(0); #reset ii
		double cp=pow(shift_threshold,ii)*(double(1)-shift_threshold)*double(1000);# cummulative probablity
			loop until m<cp
			begin
			ii=ii+double(1);
			cp=cp+pow(shift_threshold,ii)*(double(1)-shift_threshold)*double(1000);
			end;
	end;

	#show the current block
	#display_window.erase();
	#if block == 1 then
	#	display_window.draw_text("Current Block: Left 70%");   # display high reward side
	#elseif block == 2 then
	#	display_window.draw_text("Current Trial Block: Right 70%");
	#end;
	#RESPONSE WINDOW AND REWARD DETERMINATION

	if block==1 then
	#in block L70R10
		waitlickL70R10.present();
		if response_manager.response_count()>0 then   # lick, not miss
			double n=random();  #generate the random number to determine whether there is reward
			if (response_manager.last_response()==2) then
				side = "left";
				reward_threshold = 0.7;
					if n <= reward_threshold then
						port.set_pulse_width(waterAmount_left);
						port.send_code(4);		#give water reward
						interpulse.present();
						port.send_code(4);		#second pulse
						rewardleftcorrect.present();
						#hit_count.add(1);
						#leftCorrReward.add(1);
						left_correct_reward = left_correct_reward+1;
						parameter_window.set_parameter(left_correct_rewardIndex,string(left_correct_reward)); #LCR: left correct reward
					else
						leftcorrectnoreward.present();
						#hit_count.add(1);
						#leftCorrReward.add(0);
						left_correct_no_reward = left_correct_no_reward+1;
						parameter_window.set_parameter(left_correct_no_rewardIndex,string(left_correct_no_reward)); #LCN: left correct no reward
					end; #end reward/no reward if
			nTrials_hit = nTrials_hit+1; # nTrials on high-reward side
			nTrials_hit_total = nTrials_hit_total+1;
			parameter_window.set_parameter(nTrials_hit_totalIndex,string(nTrials_hit_total));
			elseif (response_manager.last_response()==3) then
				side = "right";
				reward_threshold = 0.1;
				if n <= reward_threshold then
					port.set_pulse_width(waterAmount_right);
					port.send_code(8);		#give water reward
					interpulse.present();
					port.send_code(8);		#second pulse
					rewardrightcorrect.present();
					#hit_count.add(0);
					#rightIncorrReward.add(1);
					right_incorrect_reward = right_incorrect_reward + 1;
					parameter_window.set_parameter(right_incorrect_rewardIndex,string(right_incorrect_reward)); #RIR: right incorrect reward
				else
					rightincorrectnoreward.present();
					#hit_count.add(0);
					#rightIncorrReward.add(0);
					right_incorrect_no_reward = right_incorrect_no_reward +1;
					parameter_window.set_parameter(right_incorrect_no_rewardIndex,string(right_incorrect_no_reward)); #RIN: right incorrect no reward
				end; #end reward/no reward if
			end; #end lick left/right if
			consecMiss = 0;
			parameter_window.set_parameter(consecmissIndex,string(consecMiss));

		else # miss else
		pause.present();
		consecMiss = consecMiss+1;
		parameter_window.set_parameter(consecmissIndex,string(consecMiss));
		end; #end lick/no lick if

	elseif block==2 then
	#in block L10R70
		waitlickL10R70.present();
		if response_manager.response_count()>0 then   # lick, not miss
			double n=random();  #generate the random number to determine whether there is reward
			if (response_manager.last_response()==3) then
				side = "right";
				reward_threshold = 0.7;
				if n <= reward_threshold then
					port.set_pulse_width(waterAmount_left);
					port.send_code(8);		#give water reward
					interpulse.present();
					port.send_code(8);		#second pulse
					rewardrightcorrect.present();
					#hit_count.add(1);
					#rightCorrReward.add(1);
					right_correct_reward = right_correct_reward + 1;
					parameter_window.set_parameter(right_correct_rewardIndex,string(right_correct_reward)); #RCR: right correct reward
				else
					leftincorrectnoreward.present();
					#hit_count.add(1);
					#rightCorrReward.add(0);
					right_correct_no_reward = right_correct_no_reward + 1;
					parameter_window.set_parameter(right_correct_no_rewardIndex,string(right_correct_no_reward)); #RCN: right correct no reward
				end; #end reward/no reward if
				nTrials_hit = nTrials_hit+1; # nTrials on high-reward side
				nTrials_hit_total = nTrials_hit_total+1;
				parameter_window.set_parameter(nTrials_hit_totalIndex,string(nTrials_hit_total));
			elseif (response_manager.last_response()==2) then
				side = "left";
				reward_threshold = 0.1;
				if n <= reward_threshold then
					port.set_pulse_width(waterAmount_right);
					port.send_code(4);		#give water reward
					interpulse.present();
					port.send_code(4);		#second pulse
					rewardrightcorrect.present();
					#hit_count.add(0);
					#leftIncorrReward.add(1);
					left_incorrect_reward = left_incorrect_reward + 1;
					parameter_window.set_parameter(left_incorrect_rewardIndex,string(left_incorrect_reward)); #LIR: left incorrect reward
				else
					rightcorrectnoreward.present();
					#hit_count.add(0);
					#leftIncorrReward.add(0);
					left_incorrect_no_reward = left_incorrect_no_reward + 1;
					parameter_window.set_parameter(left_incorrect_no_rewardIndex,string(left_incorrect_no_reward)); #LIN: left incorrectno reward
				end; #end reward/no reward trial
			end; #end lick left/right if
			consecMiss = 0;
			parameter_window.set_parameter(consecmissIndex,string(consecMiss));

		else #miss else
			pause.present();
			consecMiss = consecMiss+1;
			parameter_window.set_parameter(consecmissIndex,string(consecMiss));

		end; #end lick/miss trial
	end; #end block1/2 if

	#random block following the reward period
	loop
		expval=minimum_go-1.0/mu*log(random())
	until
		expval<truncate_go
	begin
		expval=minimum_go-1.0/mu*log(random())
	end;

   randomblock.set_duration(int(1000.0*expval));

	randomblock.present();

	# no lick period

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



	block_length=block_length+1;   # update trials within current block

	#PROBABILITY BLOCK SWITCH

	if nTrials_hit>=10 then
		if i_geo==ii then
			block_length=0; # reset  trial number within current block
			# switch block
			if block==1 then block = 2
			else block = 1
			end;
			nTrials_hit = 0; # reset count
			i_geo=double(0); # reset i_geo
		else i_geo=i_geo+double(1);
		end;
	end;
	parameter_window.set_parameter(geo_Index,"ii="+string(ii)+" i_geo="+string(i_geo)+"m"+string(m)); # display i_geo


	if (i%5) == 0 then		#every 5 trials, save a temp logfile
		quicksave.present();
	end;
	num_trials = i;
	#TEMP LOGSTATS OUTPUT FOR TASK
	output_file ofile = new output_file;
	ofile.open("C:\\Users\\KWANLAB\\Desktop\\Presentation\\hONGLI\\logfile\\logstats_temp.txt");
	ofile.print("\n\nStarting time: "+startTime);
	ofile.print("\nSubject: "+logfile.subject());
	ofile.print("\n\t Rig 2 ");
	ofile.print("\n\tTotal trial number");
	ofile.print("\n\t" + string(num_trials));
	ofile.print("\n\tHigh reward hit (total)");
	ofile.print("\n\t" + string(nTrials_hit_total));
	ofile.print("\n\tHigh reward accuracy percentage (%)");
	ofile.print("\n\t" + string(nTrials_hit_total*100/num_trials)+"%");
	#ofile.print("\n\tleftReward rate (%)");
	#ofile.print("\n\t"+string(100*(left_correct_reward+left_incorrect_reward)/(left_correct_reward+left_incorrect_reward+left_correct_no_reward+left_incorrect_no_reward))+"%");
   #ofile.print("\n\trightReward rate (%)");
   #ofile.print("\n\t"+string(100*(right_correct_reward+right_incorrect_reward)/(right_correct_reward+right_incorrect_reward+right_correct_no_reward+right_incorrect_no_reward))+"%");
   ofile.print("\n\tConsecutive Miss");
	ofile.print("\n\t" + string(consecMiss));

	ofile.print("\n\tRight reward");
	ofile.print("\n\t" + string(right_correct_reward + right_incorrect_reward));
	ofile.print("\n\tRight no reward");
	ofile.print("\n\t" + string(right_correct_no_reward + right_incorrect_no_reward));
	ofile.print("\n\tRight total");
	ofile.print("\n\t" + string(right_correct_reward + right_incorrect_reward + right_correct_no_reward + right_incorrect_no_reward));

	ofile.print("\n\tLeft reward");
	ofile.print("\n\t" + string(left_correct_reward+left_incorrect_reward));
	ofile.print("\n\tLeft no reward");
	ofile.print("\n\t" + string(left_correct_no_reward+left_incorrect_no_reward));
	ofile.print("\n\tLeft total");
	ofile.print("\n\t" + string(left_correct_reward+left_incorrect_reward + left_correct_no_reward+left_incorrect_no_reward));
	ofile.print("\n\tLeft water per trial");
	ofile.print("\n\t" + string(waterAmount_left));
	ofile.print("\n\tRight water per trial");
	ofile.print("\n\t" + string(waterAmount_right));
	ofile.print("\nEnding time:");
	ofile.print(date_time());
	ofile.close();

	i = i+1;
	parameter_window.set_parameter(trialnumIndex,string(i) + " ("+string(nTrials_hit)+" hit/block)");


	parameter_window.set_parameter(hit_rateIndex,string(nTrials_hit_total*100/num_trials)+"%");
	if left_correct_reward+left_correct_no_reward+left_incorrect_reward+left_incorrect_no_reward>0 then
	parameter_window.set_parameter(leftreward_rate,string(100*(left_correct_reward+left_incorrect_reward)/(left_correct_reward+left_incorrect_reward+left_correct_no_reward+left_incorrect_no_reward))+"%");
	end;
	if right_correct_reward+right_correct_no_reward+right_incorrect_reward+right_incorrect_no_reward>0 then
	parameter_window.set_parameter(rightreward_rate,string(100*(right_correct_reward+right_incorrect_reward)/(right_correct_reward+right_incorrect_reward+right_correct_no_reward+right_incorrect_no_reward))+"%");
	end;

end; #end trial loop

#----------------------record ITI---------------------
output_file ofile = new output_file;    # let the trial end without using 'quit'
string asd = date_time("mmddhhnn");

	ofile.open("C:\\Users\\KWANLAB\\Desktop\\Presentation\\logfiles\\logstats_wanyu_accuracy"+asd+".txt");
	#ofile.open_append("logstats_ITI.txt");
	ofile.print("\n\t Rig 2 ");
	ofile.print("\n\tTotal trial number");
	ofile.print("\n\t" + string(num_trials));
	ofile.print("\n\tHigh reward hit (total)");
	ofile.print("\n\t" + string(nTrials_hit_total));
	ofile.print("\n\tHigh reward accuracy percentage (%)");
	ofile.print("\n\t" + string(nTrials_hit_total*100/num_trials)+"%");
	ofile.print("\n\tleftReward rate (%)");
	ofile.print("\n\t"+string(100*(left_correct_reward+left_incorrect_reward)/(left_correct_reward+left_incorrect_reward+left_correct_no_reward+left_incorrect_no_reward))+"%");
   ofile.print("\n\trightReward rate (%)");
   ofile.print("\n\t"+string(100*(right_correct_reward+right_incorrect_reward)/(right_correct_reward+right_incorrect_reward+right_correct_no_reward+right_incorrect_no_reward))+"%");
   ofile.print("\n\tConsecutive Miss");
	ofile.print("\n\t" + string(consecMiss));

	ofile.print("\n\tRight reward");
	ofile.print("\n\t" + string(right_correct_reward + right_incorrect_reward));
	ofile.print("\n\tRight no reward");
	ofile.print("\n\t" + string(right_correct_no_reward + right_incorrect_no_reward));
	ofile.print("\n\tRight total");
	ofile.print("\n\t" + string(right_correct_reward + right_incorrect_reward + right_correct_no_reward + right_incorrect_no_reward));

	ofile.print("\n\tLeft reward");
	ofile.print("\n\t" + string(left_correct_reward+left_incorrect_reward));
	ofile.print("\n\tLeft no reward");
	ofile.print("\n\t" + string(left_correct_no_reward+left_incorrect_no_reward));
	ofile.print("\n\tLeft total");
	ofile.print("\n\t" + string(left_correct_reward+left_incorrect_reward + left_correct_no_reward+left_incorrect_no_reward));
	ofile.print("\n\tLeft water per trial");
	ofile.print("\n\t" + string(waterAmount_left));
	ofile.print("\n\tRight water per trial");
	ofile.print("\n\t" + string(waterAmount_right));
	ofile.print("\nEnding time:");
	ofile.print(date_time());
	ofile.close();

display_window.draw_text("Training has ended.");
term.print("\nEnding time:");
term.print(date_time());
