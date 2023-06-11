# =======================
# Example (put in config.txt):
#	route_randomWalk 1
#	teleport_searchMVP 1
#   teleport_searchMVP_monsters Garm
#	teleport_search_minSp 10
#
# Put in timeouts.txt:
#	ai_teleport_search 5

package telesearchMVP;

use strict;
use Plugins;
use Globals;
use Log qw(message error);
use Utils qw(timeOut calcPosition);
# use Misc qw(sendMessage);
use Misc;



Plugins::register('telesearchmvp', 'search for mvp and report if found.', \&unload, \&unload);

my $hooks = Plugins::addHooks(
	['AI_pre',\&search, undef],
	['map_loaded', \&MapLoaded, undef],
	['packet/sendMapLoaded', \&MapLoaded, undef],
);

my ($maploaded,$allow_tele);
my $cHook = Log::addHook(\&cHook);

# Set $maploaded to 1, this incase we reload the plugin for whatever reason...
if ($net && $net->getState() == Network::IN_GAME) {
	$maploaded = 1;
}

sub unload {
	Plugins::delHooks($hooks);
	undef $maploaded;
	undef $allow_tele;
	message "telesearchmvp plugin unloading or reloading\n", 'success';
}

sub cHook {
   my $type = shift;
    my $domain = shift;
   my $level = shift;
   my $currentVerbosity = shift;
   my $message = shift;

	if ($message =~ /telesearch on/) {
		message "Commanded to do telesearchMVP. Setting conf now.";
		# sendMessage($messageSender, "g", "turning ON telesearch...");
		if (!$char->statusActive('CUST_TELESEARCH')) {
			$char->setStatus('CUST_TELESEARCH', 1);
		}
	} elsif ($message =~ /telesearch on/) {
		message "Commanded to stop telesearchMVP. Setting conf now.";
		# sendMessage($messageSender, "g", "turning OFF telesearch...");
		if ($char->statusActive('CUST_TELESEARCH')) {
			$char->setStatus('CUST_TELESEARCH', 0);
		}
	}

}

sub MapLoaded {
	$maploaded = 1;
}

sub checkIdle {
	# if ($char->statusActive('CUST_TELESEARCH')) {
	if ($char && $char->statusActive('CUST_TELESEARCH')) {
		return 1;
	} else {
		return 0;
	}
}

sub search {
	if ($config{"teleport_searchMVP"} && $char && $char->statusActive('CUST_TELESEARCH')) {
		if ($maploaded && !$allow_tele) {
			$timeout{'ai_teleport_search'}{'time'} = time;
			$allow_tele = 1;

			if ($char->statusActive('CUST_TELESEARCH')) {
				foreach (@monstersID) {
					next unless defined $_;
					if (Utils::existsInList($config{"teleport_searchMVP_monsters"}, $monsters{$_}->{name})) {
						message "------------ woow {$monsters{$_}->{name}} exists in list\n";
						my $mypos = calcPosition($char);
						$char->setStatus('CUST_TELESEARCH', 0);
						$allow_tele = 0;

						sendMessage($messageSender, "g", "found monster [$monsters{$_}->{name}]. im at $mypos->{x} $mypos->{y} \n");
						message "found monster [$monsters{$_}->{name}]. im at $mypos->{x} $mypos->{y} \n"
					}
					# message "list: {$monList}";
				}
			}
		# Check if we're allowed to teleport, if map is loaded, timeout has passed and we're just looking for targets.
		} elsif ($maploaded && $allow_tele && timeOut($timeout{'ai_teleport_search'}) && checkIdle()) {
			message ("Attemping to tele-searchMVP.\n","info");
			$allow_tele = 0;
			$maploaded = 0;


			# Attempt to teleport, give error and unload plugin if we cant.
			if (!Misc::useTeleport(1)) {
				error ("Unable to tele-search cause we can't teleport!\n");
				return;
			}

		# We're doing something else besides looking for monsters, reset the timeout.
		} elsif (!checkIdle()) {
			$timeout{'ai_teleport_search'}{'time'} = time;
		}

		# Oops! timeouts.txt is missing a crucial value, lets use the default value ;)
		} elsif (!$timeout{'ai_teleport_search'}{'timeout'}) {
			error ("timeouts.txt missing setting! Using default timeout of 5 seconds.\n");
			$timeout{'ai_teleport_search'}{'timeout'} = 5;
			return;
		}
}

1;
