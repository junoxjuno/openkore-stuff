# NOTE: This is scuffed, cuz the character may not move after moving to pneuma.
# I haven't tested or used it enough to discover what the issue was

package mslSlave;

# plugin load mslSlave
# plugin unload mslSlave

use strict;
use Plugins;
use Globals ;
use Utils;
use Commands;
use Misc;
use Log qw(message debug);
use Data::Dumper;
use Task::Wait;
use Time::HiRes qw(time usleep);

my $prefix = "msl_";

my $moveToPortalWaitDuration = 10;
my $portalWaitOpenDuration = 3;

my $openX = 0;
my $openY = 0;

Plugins::register("movepneuma", "Move to Pneuma", \&on_unload, \&on_reload);
my $hooks = Plugins::addHooks(
	['is_casting', \&casting_hook],
);

sub on_unload {
	# This plugin is about to be unloaded; remove hooks
	Plugins::delHooks($hooks);
	message "[mslSlave] Unload done.\n", 'success';
}

sub on_reload {
	&on_unload;
}

sub casting_hook {
	my $hookName = shift;
	my $args = shift;

	my $openX;
	my $openY;

	# pneuma casted, move to it
	if ($args->{skillID} eq 25) {

		message "Move into pneuma at $args->{x} $args->{y}\n";

		$openX = $args->{x};
		$openY = $args->{y};

		main::ai_route(
			$field->baseName,
			$openX,
			$openY,
			noSitAuto => 1,
			attackOnRoute => 0
		);
	}
}

1;
