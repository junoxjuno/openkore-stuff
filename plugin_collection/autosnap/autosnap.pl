package autosnap;

use strict;
use Globals;
use Log qw(message);
use Utils;
use Network::Send;
use Misc;
use AI;

Plugins::register('autosnap', 'Auto snap after asura.', \&unload);

my $hooks = Plugins::addHooks(
   ['is_casting', \&casting_hook],
   ['parseMsg/pre', \&packet_hook],
);

sub unload {
   Plugins::delHooks($hooks);
}

my $flag = 0;


sub packet_hook {
   my $hookName = shift;
   my $args = shift;
   my $switch = $args->{switch};
   my $msg = $args->{msg};

   if ($switch eq "01D0") {
	  if ($char->statusActive('CUST_ASURAD') && $char->{spirits} > 0) {
		my $pos = getEmptyPos($char, 6);
		$messageSender->sendSkillUseLoc(264, 1, $pos->{x}, $pos->{y});
		$char->setStatus('CUST_ASURAD', 0);
	  }
   }
}

# Casting Skill Hook
sub casting_hook {
	my $hookName = shift;
	my $args = shift;

	# it's our asura! ok lets snap
	if ($args->{sourceID} eq $accountID && $args->{skillID} eq 271) {
		message "Using asura. set asura status\n";
		$char->setStatus('CUST_ASURAD', 1);
	}
}

sub getEmptyPos {
   my $obj = shift;
   my $maxDist = shift;
   my $minDist = 5;

   # load info about everyone's location
   my %pos;
   for (my $i = 0; $i < @playersID; $i++) {
      next if (!$playersID[$i]);
      my $player = $players{$playersID[$i]};
      $pos{$player->{pos_to}{x}}{$player->{pos_to}{y}} = 1;
   }

   # crazy algorithm i made for spiral scanning the area around you
   # i wont bother to document it since im lazy and it already confuses me

   my @vectors = (-1, 0, 1, 0);

   my $vecx = int abs rand 4;
   my $vecy = $vectors[$vecx] ? 2 * int(abs(rand(2))) + 1 : 2 * int(abs(rand(2)));

   my ($posx, $posy);

   for (my $i = 1; $i <= $maxDist; $i++) {
      for (my $j = 0; $j < 4; $j++) {
         $posx = $obj->{pos_to}{x} + ( $vectors[$vecx] * $i * -1) || ( ($i*2) /2 );
         $posy = $obj->{pos_to}{y} + ( $vectors[$vecy] * $i * -1) || ( ($i*2) /-2 );
         for (my $k = 0; $k < ($i*2); $k++) {
            if ($field->isWalkable($posx, $posy) && !$pos{$posx}{$posy}) {
               my $pos = {x=>$posx + $minDist, y=>$posy + $minDist};
               return $pos if ($field->canMove($pos, $obj->{pos_to}));
            }

            $posx += $vectors[$vecx];
            $posy += $vectors[$vecy];
         }
         $vecx = ($vecx+1)%4;
         $vecy = ($vecy+1)%4;
      }
   }
   return undef;
}

1;
