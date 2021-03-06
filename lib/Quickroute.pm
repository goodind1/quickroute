package Quickroute;

use Quickroute::Auth;

use strict;
use HTML::Mason;
use Exporter qw!import!;
our @EXPORT = qw!route noroute template!;

my %routes;

my $interp = HTML::Mason::Interp->new(comp_root => "$ENV{PWD}/templates");

my %mime = (
  plain => 'text/plain',
  html => 'text/html',
  css  => 'text/css',
  js   => 'text/javascript',
  json => 'application/json',
  xml  => 'text/xml',
);

sub new { 
  my ($class, $env) = @_;
  my %routes_copy = %routes;
  return bless { 
    env => $env,
    routes => \%routes_copy,
    ### defaults, you can change these in routes
    status => 200,
    headers => { 'Content-type' => 'text/html' },
    ###
  } => $class;
}

sub is_auth { Quickroute::Auth::is_auth(shift) }
sub authen  { Quickroute::Auth::authen(shift)  }
sub logout  { Quickroute::Auth::logout(shift)  }

sub env { shift->{env} }
sub routes { shift->{routes} }

sub go {
  my $self = shift;
  my $routes = $self->routes;
  my $path = $self->env->{PATH_INFO};
  my $path = $path ? $path : '/';
  my $method = $self->env->{REQUEST_METHOD};
  $path =~ s/\/\z// unless $path eq '/';
  my $action = $routes->{$path}->{$method} // $routes->{error};
  delete $routes->{$path}->{$method} if $action == $routes->{error};
  my $content = $action->();
  return [ $self->{status}, [ %{$self->{headers}} ], [ $content ] ] # psgi response
}

sub set_header { 
  my $self = shift;
  my %pair = @_;
  $self->{headers}->{$_} = $pair{$_} for keys %pair;
}

sub status { 
  my ($self, $code) = @_;
  $self->{status} = $code;
}

sub type   { 
  my ($self, $type) = @_;
  $self->{headers}->{'Content-type'} = $mime{$type};
}

### Exports ###

sub noroute { $routes{error} = shift }

sub route {
  my ($path, $method, $action) = @_;
  $routes{$path}->{uc $method} = $action;
}


sub template {
  my ($component, @args) = @_;
  my $buf;
  $interp->out_method(\$buf);
  $interp->exec("/" . $component, @args);
  $buf;
}

1;
