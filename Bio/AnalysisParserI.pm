#---------------------------------------------------------------
# $Id$
#
# BioPerl module Bio::AnalysisParserI
#
# Cared for by Steve Chervitz <steve_chervitz@affymetrix.com>
#
# Derived from Bio::SeqAnalysisParserI by Jason Stajich, Hilmar Lapp.
#
# You may distribute this module under the same terms as perl itself
#---------------------------------------------------------------

=head1 NAME

Bio::AnalysisParserI - Generic analysis output parser interface

=head1 SYNOPSIS

    # get a AnalysisParserI somehow.
    # Eventually, there may be an Bio::Factory::AnalysisParserFactory.
    # For now a SearchIO object, an implementation of AnalysisParserI, can be created 
    # directly, as in the following:
    my $parser = Bio::SearchIO->new(
				    '-file'   => 'inputfile',
				    '-format' => 'blast'); 

    while( my $result = $parser->next_result() ) {
	print "Result:  ", $result->analysis_method, 
              ", Query:  ", $result->query_name, "\n";

          while( my $result = $parser->next_result() ) {
              print "Feature from ", $feature->start, " to ", $feature->end, "\n";
          }
    }

=head1 DESCRIPTION

AnalysisParserI is a interface for describing generic analysis
result parsers. This module makes no assumption about the nature of
analysis being parsed, only that zero or more result sets can be
obtained from the input source.

This module was derived from Bio::SeqAnalysisParserI, the differences being

=over 4

=item 1. next_feature() was replaced with next_result().

Instead of flattening a stream containing potentially multiple
analysis results into a single set of features, AnalysisParserI
segments the stream in terms of analysis result sets
(Bio::AnalysisResultI objects). Each AnalysisResultI can then be
queried for its features (if any) as well as other information
about the result

=item 2. AnalysisParserI is a pure interface.

It does not inherit from Bio::Root::RootI and does not provide a new()
method. Implementations are free to choose how to implement it.

=back

=head2 Rationale (copied from Bio::SeqAnalysisParserI)

The concept behind this interface is to have a generic interface in sequence
annotation pipelines (as used e.g. in high-throughput automated
sequence annotation). This interface enables plug-and-play for new analysis
methods and their corresponding parsers without the necessity for modifying
the core of the annotation pipeline. In this concept the annotation pipeline
has to rely on only a list of methods for which to process the results, and a
factory from which it can obtain the corresponding parser implementing this
interface.

=head2 TODO

Create Bio::Factory::AnalysisParserFactoryI and
Bio::Factory::AnalysisParserFactory for interface and an implementation.
Note that this factory could return Bio::SearchIO-derived objects.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this
and other Bioperl modules. Send your comments and suggestions preferably
 to one of the Bioperl mailing lists.
Your participation is much appreciated.

  bioperl-l@bioperl.org                - General discussion
  http://bio.perl.org/MailList.html    - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
 the bugs and their resolution.
 Bug reports can be submitted via email or the web:

  bioperl-bugs@bio.perl.org
  http://bio.perl.org/bioperl-bugs/

=head1 AUTHOR - Steve Chervitz, Jason Stajich, Hilmar Lapp

Email steve_chervitz@affymetrix.com

Authors of Bio::SeqAnalysisParserI on which this module is based:
Email jason@chg.mc.duke.edu 
Email hlapp@gmx.net

=head1 COPYRIGHT

Copyright (c) 2001 Steve Chervitz. All Rights Reserved.

=head1 DISCLAIMER

This software is provided "as is" without warranty of any kind.

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut

package Bio::AnalysisParserI;
use strict;
use vars qw(@ISA);

use Bio::Root::Interface;

@ISA = qw(Bio::Root::Interface);

=head2 next_result

 Title   : next_result
 Usage   : $result = $obj->next_result();
 Function: Returns the next result available from the input, or
           undef if there are no more results.
 Example :
 Returns : A Bio::Search::Result::ResultI implementing object, 
           or undef if there are no more results.
 Args    : none

=cut

sub next_result {
    my ($self);
    $self->throw_not_implemented;
}



=head2 result_factory

 Title   : result_factory
 Usage   : $res_fact = $obj->result_factory;     (get)
         : $obj->result_factory( $factory );      (set)
 Function: Sets/Gets a factory object to create result objects for this AnalysisParser.
 Returns : Bio::Factory::ResultFactoryI object 
 Args    : Bio::Factory::ResultFactoryI object (when setting)
 Comments: A AnalysisParserI implementation should provide a default result factory.
           obtainable by the  default_result_factory_class() method.
           
=cut

sub result_factory {
  my $self = shift;
  $self->throw_not_implemented;
}

=head2 default_result_factory_class

 Title   : default_result_factory_class
 Usage   : $res_factory = $obj->default_result_factory_class()->new( @args )
 Function: Returns the name of the default class to be used for creating
           Bio::AnalysisResultI objects.
 Example :
 Returns : A string containing the name of a class that implements 
           the Bio::Factory::ResultFactoryI interface.
 Args    : none

=cut

sub default_result_factory_class {
  my $self = shift;
# TODO: Uncomment this when Jason's SearchIO code conforms
#  $self->throw_not_implemented;
}

1;
__END__

NOTE: My ten-month old son Russell added the following line.
It doesn't look like it will compile so I'm putting it here:
mt6 j7qa
