#!/bin/sh
# Write Battle.net news. The build list comes from the images. BNETD_NEWS is the text under it.
set -eu

OUT_ETC="${OUT_ETC:-/out/etc}"
mkdir -p "$OUT_ETC/i18n"

for name in BNETD_IMAGE D2GS_IMAGE D1GS_IMAGE MYSQL_IMAGE PVPGN_VERSION WINE_VERSION D2GS_ENGINE D2GS_PATCH D1GS_VERSION; do
  if ! printenv "$name" >/dev/null 2>&1; then
    echo "missing $name" >&2
    exit 1
  fi
done

export NEWS_STAMP="$(date -u +%m/%d/%Y)"
export NEWS_PATH="$OUT_ETC/i18n/news.txt"

perl -e '
  use strict;
  use warnings;
  use IO::Socket::UNIX;

  sub unquote {
    my ($value) = @_;
    return "" unless defined $value;
    if ($value =~ /\A"(.*)"\z/s) { $value = $1; }
    return $value;
  }

  for my $key (qw(BNETD_IMAGE D2GS_IMAGE D1GS_IMAGE MYSQL_IMAGE PVPGN_VERSION WINE_VERSION D2GS_ENGINE D2GS_PATCH D1GS_VERSION BNETD_NEWS)) {
    $ENV{$key} = unquote($ENV{$key}) if exists $ENV{$key};
  }

  sub inspect {
    my ($image) = @_;
    my $sock = IO::Socket::UNIX->new(Peer => "/var/run/docker.sock", Type => SOCK_STREAM)
      or die "docker socket: $!\n";
    my $path = $image;
    $path =~ s/([^A-Za-z0-9._:\-])/sprintf("%%%02X", ord($1))/ge;
    print $sock "GET /images/$path/json HTTP/1.0\r\nHost: docker\r\n\r\n";
    local $/;
    my $raw = <$sock>;
    die "no answer for $image\n" unless defined $raw && length $raw;
    my ($head, $body) = split(/\r\n\r\n/, $raw, 2);
    my ($status) = defined $head ? $head =~ m{HTTP/\S+\s+(\d+)} : ();
    if (!defined $body || !defined $status || $status ne "200") {
      die "image $image: " . (split(/\r?\n/, $head // "no status"))[0] . "\n";
    }
    my ($created) = $body =~ /"Created"\s*:\s*"([^"]+)"/;
    my ($version) = $body =~ /"org.opencontainers.image.version"\s*:\s*"([^"]+)"/;
    $created = "unknown" unless defined $created;
    $created =~ s/^(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2}).*/$1 $2 UTC/;
    return ($created, defined $version ? $version : "");
  }

  my @lines;
  push @lines, "{$ENV{NEWS_STAMP}}";

  my ($bnetd_built) = inspect($ENV{BNETD_IMAGE});
  push @lines, "$ENV{BNETD_IMAGE}";
  push @lines, "built $bnetd_built";
  push @lines, "PvPGN $ENV{PVPGN_VERSION}";
  push @lines, "";

  my ($d2gs_built) = inspect($ENV{D2GS_IMAGE});
  push @lines, "$ENV{D2GS_IMAGE}";
  push @lines, "built $d2gs_built";
  push @lines, "D2GS $ENV{D2GS_ENGINE}, patch $ENV{D2GS_PATCH}, Wine $ENV{WINE_VERSION}";
  push @lines, "";

  my ($d1gs_built) = inspect($ENV{D1GS_IMAGE});
  push @lines, "$ENV{D1GS_IMAGE}";
  push @lines, "built $d1gs_built";
  push @lines, "$ENV{D1GS_VERSION}";
  push @lines, "";

  my ($mysql_built, $mysql_version) = inspect($ENV{MYSQL_IMAGE});
  push @lines, "$ENV{MYSQL_IMAGE}";
  push @lines, "built $mysql_built";
  push @lines, $mysql_version ne "" ? "MariaDB $mysql_version" : "MariaDB";

  my $text = $ENV{BNETD_NEWS} // "";
  $text =~ s/\\n/\n/g;
  $text =~ s/\s+\z//;
  if ($text ne "") {
    push @lines, "";
    push @lines, $text;
  }

  open my $out, ">", $ENV{NEWS_PATH} or die "open $ENV{NEWS_PATH}: $!\n";
  print $out join("\n", @lines), "\n";
  close $out or die "close $ENV{NEWS_PATH}: $!\n";
'
