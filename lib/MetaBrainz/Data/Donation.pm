package MetaBrainz::Data::Donation;
use Moose;
use namespace::autoclean;

use MetaBrainz::TextWrapper;
use MusicBrainz::Server::Data::Utils qw( query_to_list_limited );
use PDF::API2;

with 'MusicBrainz::Server::Data::Role::Sql',
     'MusicBrainz::Server::Data::Role::NewFromRow';

sub _entity_class { 'MetaBrainz::Entity::Donation' }

sub _column_mapping {
    return {
        first_name => 'first_name',
        last_name => 'last_name',
        email => 'email',
        editor => 'moderator',
        fee => 'fee',
        amount => 'amount',
        memo => 'memo',
        date => 'payment_date'
    }
}

sub get_all {
    my ($self, $limit, $offset) = @_;

    return query_to_list_limited(
        $self->sql, $offset, $limit,
        sub { $self->_new_from_row(@_) },
        'SELECT * FROM donation ORDER BY payment_date DESC OFFSET ?',
        $offset
    );
}

sub get_all_by_amount {
    my ($self, $limit, $offset) = @_;

    return query_to_list_limited(
        $self->sql, $offset, $limit,
        sub { shift },
        'SELECT *
         FROM (
             SELECT first_name, last_name, moderator AS editor, sum(amount) as amount,
               sum(fee) as fee
             FROM donation
             GROUP BY first_name, last_name, moderator
         ) s
         ORDER BY amount DESC
         OFFSET ?',
        $offset
    );
}

sub _create_receipt
{
    my ($self, $file, $data) = @_;

    my $pdf = PDF::API2->new(-file => $file);

    $pdf->info(
            'Author'       => "MetaBrainz Foundation Inc.",
            'CreationDate' => localtime,
            'Creator'      => "mb-receipt.pl",
            'Producer'     => "PDF::API2",
            'Title'        => "Donation Receipt",
            'Subject'      => "perl ?",
            'Keywords'     => "metabrainz musicbrainz donation receipt"
            );

    my $page = $pdf->page;
    #$page->mediabox(595,842); # A4 Size
    #$page->mediabox(612,792); # Letter size
    $page->mediabox(595,792); # Common size between Letter and A4

    my $txt = $page->text;                               ## Text Layer
    $txt->compressFlate;

    my $gfx = $page->gfx;
    $gfx->compressFlate;

    ## Create standard font references.
    my $HelveticaBold = $pdf->corefont('Helvetica-Bold');
    my $Helvetica = $pdf->corefont('Helvetica');

    my $text = MetaBrainz::TextWrapper->new(text => $txt);

    my @lt = localtime(time);

    #--------------------------------------------------------------------
    # Draw the header
    #--------------------------------------------------------------------
    $text->select_font($Helvetica, 14);
    $text->move_to(55, 700);
    $text->println("Donation Receipt");

    $text->select_font($HelveticaBold, 16);
    $text->move_to(550, 700);
    $text->rprintln("MetaBrainz Foundation Inc.");


    $text->select_font($Helvetica, 12);
    $text->rprintln("3565 South Higuera St., Suite B");
    $text->rprintln("San Luis Obispo, CA 93401");
    $text->lf;
    $text->rprintln('donations@metabrainz.org');
    $text->rprintln("http://metabrainz.org");
    $text->lf;

    $gfx->strokecolor('black');
    $gfx->linewidth(.7);

    $gfx->move(52, 695);
    $gfx->line(550,695);
    $gfx->stroke;

    #--------------------------------------------------------------------
    # Draw the donor name and address
    #--------------------------------------------------------------------

    $text->move_to(55, $text->{y});
    $text->println($data->{first_name} . " " . $data->{last_name});
    if ($data->{address_street})
    {
        $text->println($data->{address_street});
        $text->println($data->{address_city} .", ". $data->{address_state}." ".$data->{address_postcode});
    }
    $text->println($data->{email});
    $text->lf;
    $text->lf;

    $text->println("Dear " . $data->{first_name} . " " . $data->{last_name} . ":");
    $text->lf;

    $text->println('Thank you very much for your donation to the MetaBrainz Foundation!');
    $text->lf;

    $text->println('Your donation will allow the MetaBrainz Foundation to continue operating and');
    $text->println('improving the MusicBrainz project (http://musicbrainz.org). MusicBrainz depends');
    $text->println('on donations from the community and therefore deeply appreciates your support.');
    $text->lf;

    $text->println('The MetaBrainz Foundation is a United States 501(c)(3) tax-exempt public charity. This');
    $text->println('allows US taxpayers to deduct this donation from their taxes under section 170 of the');
    $text->println('Internal Revenue Service code.');
    $text->lf;

    $text->select_font($HelveticaBold, 12);
    $text->println('Please save a printed copy of this receipt for your records.');
    $text->lf;
    $text->lf;

    $text->select_font($HelveticaBold, 12);
    my $saved = $text->{y};
    $text->move_to(297, $text->{y});
    $text->rprintln("Donation date: ");
    $text->move_to(297, $saved);
    $text->println(" " . $data->{payment_date});

    $saved = $text->{y};
    $text->move_to(297, $text->{y});
    $text->rprintln("Donation amount: ");
    $text->move_to(297, $saved);
    $text->println(' $ ' . sprintf("%.2f", ($data->{amount} + $data->{fee})) . " USD");

    if ($data->{editor}) {
        $saved = $text->{y};
        $text->move_to(297, $text->{y});
        $text->rprintln("Donation editor: ");
        $text->move_to(297, $saved);
        $text->println(" " . $data->{editor});
    }

    $text->move_to(55, $text->{y});
    $text->select_font($HelveticaBold, 20);
    $text->move_to(297, $text->{y});
    $text->lf;
    $text->lf;
    $text->cprintln("Thank you for your support!");

    $pdf->finishobjects($page,$txt);
    $pdf->saveas;
    $pdf->end();
}

1;
