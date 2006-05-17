package Bio::DB::SeqFeature::NormalizedFeature;

# $Id

=head1 NAME

Bio::DB::SeqFeature::NormalizedFeature -- Normalized feature for use with Bio::DB::SeqFeature::Store

=head1 SYNOPSIS

 use Bio::DB::SeqFeature::Store;
 # Open the sequence database
 my $db      = Bio::DB::SeqFeature::Store->new( -adaptor => 'DBI::mysql',
                                                -dsn     => 'dbi:mysql:test');
 my ($feature)   = $db->get_features_by_name('ZK909');
 my @subfeatures = $feature->get_SeqFeatures();
 my @exons_only  = $feature->get_SeqFeatures('exon');

 # create a new object
 $db->seqfeature_class('Bio::DB::SeqFeature::NormalizedFeature');
 my $new = $db->new_feature(-primary_tag=>'gene',
                            -seq_id     => 'chr3',
                            -start      => 10000,
                            -end        => 11000);

 # add a new exon
 $feature->add_SeqFeature($db->new_feature(-primary_tag=>'exon',
                                           -seq_id     => 'chr3',
                                           -start      => 5000,
                                           -end        => 5551));

=head1 DESCRIPTION

The Bio::DB::SeqFeature::NormalizedFeature object is an alternative
representation of SeqFeatures for use with Bio::DB::SeqFeature::Store
database system. It is identical to Bio::DB::SeqFeature, except that
instead of storing feature/subfeature relationships in a database
table, the information is stored in the object itself. This actually
makes the objects somewhat inconvenient to work with from SQL, but
does speed up access somewhat.

To use this class, pass the name of the class to the
Bio::DB::SeqFeature::Store object's seqfeature_class() method. After
this, $db->new_feature() will create objects of type
Bio::DB::SeqFeature::NormalizedFeature. If you are using the GFF3
loader, pass Bio::DB::SeqFeature::Store::GFF3Loader->new() the
-seqfeature_class argument:

  use Bio::DB::SeqFeature::Store::GFF3Loader;

  my $store  = connect_to_db_somehow();
  my $loader = Bio::DB::SeqFeature::Store::GFF3Loader->new(
                -store=>$db,
                -seqfeature_class => 'Bio::DB::SeqFeature::NormalizedFeature'
               );
=cut




use strict;
use Carp 'croak';
use base 'Bio::Graphics::FeatureBase';
use base 'Bio::DB::SeqFeature::NormalizedFeatureI';
use overload '""' => \&as_string;

use vars '$AUTOLOAD';

my $USE_OVERLOADED_NAMES     = 1;

# some of this is my fault and some of it is changing bioperl API
*get_all_SeqFeatures = *sub_SeqFeature = *merged_segments = \&segments;

##### CLASS METHODS ####

=head2 new

 Title   : new
 Usage   : $feature = Bio::DB::SeqFeature::NormalizedFeature->new(@args)
 Function: create a new feature
 Returns : the new seqfeature
 Args    : see below
 Status  : public

This method creates and, if possible stores into a database, a new
Bio::DB::SeqFeature::NormalizedFeature object using the specialized
Bio::DB::SeqFeature class.

The arguments are the same to Bio::SeqFeature::Generic->new() and
Bio::Graphics::Feature->new(). The most important difference is the
B<-store> option, which if present creates the object in a
Bio::DB::SeqFeature::Store database, and he B<-index> option, which
controls whether the feature will be indexed for retrieval (default is
true). Ordinarily, you would only want to turn indexing on when
creating top level features, and off only when storing
subfeatures. The default is on.

Arguments are as follows:

  -seq_id       the reference sequence
  -start        the start position of the feature
  -end          the stop position of the feature
  -display_name the feature name (returned by seqname)
  -primary_tag  the feature type (returned by primary_tag)
  -source       the source tag
  -score        the feature score (for GFF compatibility)
  -desc         a description of the feature
  -segments     a list of subfeatures (see Bio::Graphics::Feature)
  -subtype      the type to use when creating subfeatures
  -strand       the strand of the feature (one of -1, 0 or +1)
  -phase        the phase of the feature (0..2)
  -url          a URL to link to when rendered with Bio::Graphics
  -attributes   a hashref of tag value attributes, in which the key is the tag
                  and the value is an array reference of values
  -store        a previously-opened Bio::DB::SeqFeature::Store object
  -index        index this feature if true

Aliases:

  -id           an alias for -display_name
  -seqname      an alias for -display_name
  -display_id   an alias for -display_name
  -name         an alias for -display_name
  -stop         an alias for end
  -type         an alias for primary_tag

=cut

sub new {
  my $class = shift;
  my %args  = @_;
  my $db      = $args{-store} || $args{-factory};
  my $index = exists $args{-index} ? $args{-index} : 1;
  my $self  = $class->SUPER::new(@_);

  if ($db) {
    if ($index) {
      $db->store($self); # this will set the primary_id
    } else {
      $db->store_noindex($self); # this will set the primary_id
    }
    $self->object_store($db);
  }
  $self;
}

=head2 Bio::SeqFeatureI methods

The following Bio::SeqFeatureI methods are supported:

 seq_id(), start(), end(), strand(), get_SeqFeatures(),
 display_name(), primary_tag(), source_tag(), seq(),
 location(), primary_id(), overlaps(), contains(), equals(),
 intersection(), union(), has_tag(), remove_tag(),
 add_tag_value(), get_tag_values(), get_all_tags()

Some methods that do not make sense in the context of a genome
annotation database system, such as attach_seq(), are not supported.

Please see L<Bio::SeqFeatureI> for more details.

=cut

sub overloaded_names {
  my $class = shift;
  my $d     = $USE_OVERLOADED_NAMES;
  $USE_OVERLOADED_NAMES = shift if @_;
  $d;
}

### instance methods

sub AUTOLOAD {
  my($pack,$func_name) = $AUTOLOAD=~/(.+)::([^:]+)$/;
  my $sub = $AUTOLOAD;
  my $self = $_[0];

  # ignore DESTROY calls
  return if $func_name eq 'DESTROY';

  # fetch subfeatures if func_name has an initial cap
  return $self->get_SeqFeatures($func_name) if $func_name =~ /^[A-Z]/;

  # error message of last resort
  $self->throw(qq(Can't locate object method "$func_name" via package "$pack"));
}#'


sub object_store {
  my $self = shift;
  my $d = $self->{store};
  $self->{store} = shift if @_;
  $d;
}

sub add_SeqFeature {
  my $self = shift;
  $self->_add_segment(1,@_);
}

sub add_segment {
  my $self = shift;
  $self->_add_segment(0,@_);
}

# This adds subfeatures. It has the property of converting the
# provided features into an object like itself and storing them
# into the database. If the feature already has a primary id and
# an object_store() method, then it is not stored into the database,
# but its primary id is reused.
sub _add_segment {
  my $self       = shift;
  my $normalized = shift;
  my $store      = $self->store;

  my @segments   = $self->_create_subfeatures($normalized,@_);

  my $min_start = $self->start ||  999_999_999_999;
  my $max_stop  = $self->end   || -999_999_999_999;

  for my $seg (@segments) {
    $min_start     = $seg->start if $seg->start < $min_start;
    $max_stop      = $seg->end   if $seg->end   > $max_stop;
    my $id_or_seg  = $normalized ? $seg->primary_id : $seg;
    defined $id_or_seg or croak "No primary ID when there should be";
    push @{$self->{segments}},$id_or_seg;
  }

  # adjust our boundaries, etc.
  $self->start($min_start) if $min_start < $self->start;
  $self->end($max_stop)    if $max_stop  > $self->end;
  $self->{ref}           ||= $segments[0]->seq_id;
  $self->{strand}        ||= $segments[0]->strand;

  $self->update if $self->primary_id; # write us back to disk
}

sub _create_subfeatures {
  my $self = shift;
  my $normalized = shift;

  my $type = $self->{subtype} || $self->{type};
  my $ref   = $self->seq_id;
  my $name  = $self->name;
  my $class = $self->class;
  my $store = $self->object_store
    or $self->throw("Feature must be associated with a Bio::DB::SeqFeature::Store database before attempting to add subfeatures");

  my $index_subfeatures_policy = $store->index_subfeatures;

  my @segments;

  for my $seg (@_) {

    if (UNIVERSAL::isa($seg,ref $self)) {

      if (!$normalized) {  # make sure the object has no lazy behavior
	$seg->primary_id(undef);
	$seg->object_store(undef);
      }
      push @segments,$seg;
    }

    elsif (ref($seg) eq 'ARRAY') {
      my ($start,$stop) = @{$seg};
      next unless defined $start && defined $stop;  # fixes an obscure bug somewhere above us
      my $strand = $self->{strand};

      if ($start > $stop) {
	($start,$stop) = ($stop,$start);
	$strand = -1;
      }
      push @segments,$self->new(-start  => $start,
				-stop   => $stop,
				-strand => $strand,
				-ref    => $ref,
				-type   => $type,
			        -name   => $name,
			        -class  => $class,
			       );
    }


    elsif (UNIVERSAL::isa($seg,'Bio::SeqFeatureI')) {
      my $score = $seg->score if $seg->can('score');
      my $f = $self->new(-start  => $seg->start,
			 -end    => $seg->end,
			 -strand => $seg->strand,
			 -seq_id => $seg->seq_id,
			 -name   => $seg->display_name,
			 -primary_tag => $seg->primary_tag,
			 -source_tag  => $seg->source,
			 -score       => $score,
			);
      for my $tag ($seg->get_all_tags) {
	my @values = $seg->get_tag_values($tag);
	$f->{attributes}{$tag} = \@values;
      }
      push @segments,$f;
    }

    else {
      croak "$seg is neither a Bio::SeqFeatureI object nor an arrayref";
    }
  }

  return unless @segments;

  if ($normalized && $store) {  # parent/child data is going to be stored in the database

    my @need_loading = grep {!defined $_->primary_id || $_->object_store ne $store} @segments;
    if (@need_loading) {
      my $result;
      if ($index_subfeatures_policy) {
	$result = $store->store(@need_loading);
      } else {
	$result = $store->store_noindex(@need_loading);
      }
      $result or croak "Couldn't store one or more subseqfeatures";
    }
  }

  return @segments;
}

sub update {
  my $self = shift;
  my $store = $self->object_store or return;
  $store->store($self);
}

# segments can be either normalized IDs or ordinary feature objects
sub get_SeqFeatures {
  my $self = shift;
  my @types        = @_;

  my $s     = $self->{segments} or return;
  my $store = $self->object_store;
  my (@ordinary,@ids);
  for (@$s) {
    if (ref ($_)) {
      push @ordinary,$_;
    } else {
      push @ids,$_;
    }
  }
  my @r = grep {$_->type_match(@types)} (@ordinary,$store->fetch_many(\@ids));
  return @r;
}

sub load_id {
  return shift->attributes('load_id');
}

sub primary_id {
  my $self = shift;
  my $d    = $self->{primary_id};
  $self->{primary_id} = shift if @_;
  $d;
}

sub target {
  my $self    = shift;
  my @targets = $self->attributes('Target');
  my @result;
  for my $t (@targets) {
    my ($seqid,$start,$end,$strand) = split /\s+/,$t;
    $strand ||= +1;
    push @result,Bio::DB::SeqFeature::Segment->new($self->object_store,
						   $seqid,
						   $start,
						   $end,
						   $strand);
  }
  return wantarray ? @result : $result[0];
}

sub as_string {
  my $self = shift;
  return overload::StrVal($self) unless $self->overloaded_names;
  my $name  = $self->display_name || $self->load_id || "id=".$self->primary_id;
  my $method = $self->primary_tag;
  my $source= $self->source_tag;
  my $type  = $source ? "$method:$source" : $method;
  return "$type($name)";
}

# completely case insensitive
sub type_match {
  my $self = shift;
  my @types = @_;
  my $method = lc $self->primary_tag;
  my $source = lc $self->source_tag;
  for my $t (@types) {
    my ($m,$s) = map {lc $_} split /:/,$t;
    return 1 if $method eq $m && (!defined $s || $source eq $s);
  }
  return;
}

sub segments { shift->get_SeqFeatures(@_) }

sub segment  {
  my $self = shift;
  return Bio::DB::SeqFeature::Segment->new($self);
}

1;
