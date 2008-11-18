# Ercoupe nasal program
# relased under the GPL

# Called from ercoupe-set.xml.
# Ercoupes have mechanically coordinated ailerons and rudder. No rudder pedals.

#####################################

var cockpit_mute=nil;
var fuel_system=nil;

var my_last_time = 0.0;

props.globals.getNode("/sim/time/fast_timer",1).setDoubleValue(0.0);


var fast_timer= func {
	var time = props.globals.getNode("/sim/time/fast_timer",1).getValue() + props.globals.getNode("sim/time/delta-sec",1).getValue();
	props.globals.getNode("/sim/time/fast_timer",1).setDoubleValue(time);
	settimer( fast_timer, 0);
}

setlistener("/sim/signals/electrical-initialized", func {
	FDM = 1;
	cockpit_mute = Volume.new(0);
	fuel_system = Fuel.new(0);

	fast_timer();
	settimer(update_ercoupe,1);
#	gui.menuEnable("fuel-and-payload", "/sim/flight-model" == "jsb");
	print("Ercoupe Started ... OK");
});

# Cockpit sound volume
var Volume = {
	new : func (n) {
		var m = { parents : [Volume] };

		m.volumeN = props.globals.getNode("sim/sound/cockpit-volume", 1);
		m.muteN = props.globals.getNode("sim/sound/cockpit-mute", 1);
		m.viewN = props.globals.getNode("sim/current-view/internal", 1);
		m.windowN = props.globals.getNode("surface-positions/speedbrake-pos-norm", 1);
		m.self = n;
		return m;
	},
	update : func {
		var volume=0;
		if (me.viewN.getBoolValue()) {
			volume=1 - me.windowN.getValue();
		}
		me.volumeN.setDoubleValue(1 - volume);
		me.muteN.setDoubleValue(volume);
	},
};

# Fuel Transfer
var Fuel = {
	new : func (n) {
		var m = { parents : [Fuel] };
		
		m.headerN = props.globals.getNode("consumables/fuel/tank[0]/level-gal_us", 1);
		m.headerCap = props.globals.getNode("consumables/fuel/tank[0]/capacity-gal_us").getValue();
		m.winglN =  props.globals.getNode("consumables/fuel/tank[1]/level-gal_us", 1);
		m.wingrN =  props.globals.getNode("consumables/fuel/tank[2]/level-gal_us", 1);
		m.fuelpumpN = props.globals.getNode("systems/electrical/outputs/fuel-pump", 1);
#		needs switch for header - > engine

		return m;
	},
	update : func (dt) {
		var level = me.headerN.getValue();
		var delta = me.headerCap - level;
		var available = me.winglN.getValue();
		var transfer = 0;
		var max_transfer = 0.12*dt; # in gallons per second, roughly 7 gpm
		if(me.fuelpumpN.getValue() > 11.0){# if power to fuel pump
			if (available > (delta)) {
				transfer = delta;
			} else {
				transfer = available;
			}
			if (transfer > max_transfer) {
				transfer=max_transfer;
			}
			me.headerN.setDoubleValue(level + transfer);
			me.winglN.setDoubleValue(available - transfer);
		}
		var left  = me.winglN.getValue();
		var right = me.wingrN.getValue();
		delta = (right - left)/2;
		left += delta;
		right -= delta;
		me.winglN.setDoubleValue(left);
		me.wingrN.setDoubleValue(right);
	},
};

var update_ercoupe = func {
	var time = getprop("/sim/time/fast_timer");
	var dt = time - my_last_time;
#print ("dT = "~dt~" ,time = "~time~" ,last = "~my_last_time);
	my_last_time = time;

	cockpit_mute.update();
	fuel_system.update(dt);
	
	settimer(update_ercoupe,1);
}

