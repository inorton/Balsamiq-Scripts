#!/usr/bin/perl

# depends on
# bmml.py from "http://vi.to/bmml/"
# vncserver
# balsamiq mockups
# perl


my $balsamiq = "/opt/Balsamiq Mockups/bin/Balsamiq Mockups";
my $bmmlpy_dir   = "/opt/bmmlpy";
my $mako_template = "$bmmlpy/jq.mako.txt";

my $found_bmmlpy = ( -d $bmmlpy_dir );

my $target = $ARGV[0];

unless ( $target ){ 
  $target = "--help"; 
}

if ( $target eq "--help" ){
  die "Usage: $0 /full/path/containing/bmml";
}

print "Target Directory is $target\n";
if ( $found_bmmlpy ){
  print "Using bmml.py in $bmmlpy_dir\n";
} else {
  print "bmml.py not found, only exporting pngs\n";
}

unless ( -d $target ){ die "$! $target"; }

render( $target );

sub run
{
  my $rv = tryrun(@_);
  if ( $rv != 0 ) { die "command " . join(" ",@_) . " returned $rv."; }
}

sub tryrun
{
  return system(@_)/256;
}


sub render
{
  my $target = shift;
  print "Render $target\n";
  opendir(my $dir, "$target") or die "cant open $target $!";

  run("mkdir","-p","$target/bmml_export");

  if ( $found_bmmlpy ){
    open(my $html, '>',"$target/bmml_export/index.html") or die "$!";
    my $date = scalar(localtime());
    print $html qq|<html>
      <head><title>navigation for exported balsamiq mockups - $target</title><head>
      <body><h3>$target</h3>
      $date<br/>
      <hr size="1"/>
      |;

  }

  my @names = readdir($dir);
  tryrun("vncserver","-kill",":31");
  run("vncserver",":31","-fp","/usr/share/fonts/X11/misc/");
  $ENV{DISPLAY} = ":31";
  sleep 2;
  print "vncserver started\n";
  foreach my $name (sort @names){
    print "dirent $name\n";
    next if ($name eq ".");
    next if ($name eq "..");
    next if (-d $name);
    if ($name =~ /\.bmml$/){
      print "exporting $name\n";
      my $nn = $name;
      $nn =~ s/\.bmml$//;
      tryrun($balsamiq,"export","$target/$name","$target/bmml_export/$nn.png");

      if ( $found_bmmlpy ){
        print $html qq|<a href="$nn.html" target="exported">$nn</a><br/>|;
      }
    }

  }
       
  tryrun("vncserver","-kill",":31");
  if ( $found_bmmlpy ){
    print $html "</body></html>";
    close($html);
  }
  close($dir);

  if ( $found_bmmlpy ){
    # now render html
    tryrun("/usr/bin/python $bmmlpy_dir/bmml.py $mako_template $target/*.bmml");
    tryrun("cp","index.html.template","$target/index.html");
    trytun("cp $bmmlpy_dir/*.js $target/bmml_export/");
  }
}


