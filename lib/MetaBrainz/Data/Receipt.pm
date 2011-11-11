package MetaBrainz::Data::Receipt;
use Moose;
use namespace::autoclean;

use DateTime::Format::Strptime;
use File::Temp qw( tempfile );
use MIME::Lite;

sub mail_donation_receipt {
    my ($self, $donation) = @_;
    my (undef, $file_name) = tempfile();
    $self->_create_receipt($file_name, $donation);

    my $text = "Dear " . $donation->first_name . " " . $donation->last_name . ":\n\n";
    $text .= "Thank you very much for your donation to the MetaBrainz Foundation!\n\n";
    $text .= "Your donation will allow the MetaBrainz Foundation to continue operating and ";
    $text .= "improving the MusicBrainz project (http://musicbrainz.org). MusicBrainz depends ";
    $text .= "on donations from the community and therefore deeply appreciates your support.\n\n";
    $text .= "The MetaBrainz Foundation is a United States 501(c)(3) tax-exempt public charity. This ";
    $text .= "allows US taxpayers to deduct this donation from their taxes under section 170 of the ";
    $text .= "Internal Revenue Service code.\n\n";
    $text .= "Please save a printed copy of the attached PDF receipt for your records.\n\n";

    my $msg = MIME::Lite->new(
        Sender  =>'Donation Manager <donations@metabrainz.org>',
        From    =>'Donation Manager <donations@metabrainz.org>',
        To      =>($donation->first_name." ".$donation->last_name." <" . $donation->email.">"),
        Subject =>'Receipt for your donation to the MetaBrainz Foundation',
        Type    =>'multipart/mixed'
    );

    $msg->attach(
        Type     => 'TEXT',
        Data     => $text
    );
    $msg->attach(
        Type        => 'application/pdf',
        Path        => $file_name,
        Filename    => 'metabrainz_donation.pdf',
        Disposition => 'attachment'
    );

    $msg->send;
    unlink($file_name);
}

sub _create_receipt
{
    my ($self, $file, $donation) = @_;

    my $pdf = PDF::API2->new(-file => $file);
    my $date_formatter = DateTime::Format::Strptime->new( pattern => '%Y/%m/%d' );

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
    $text->println($donation->first_name . " " . $donation->last_name);
    if ($donation->street)
    {
        $text->println($donation->street);
        $text->println($donation->city .", ". $donation->state." ".$donation->postcode);
    }
    $text->println($donation->email);
    $text->lf;
    $text->lf;

    $text->println("Dear " . $donation->first_name . " " . $donation->last_name . ":");
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
    $text->println(" " . $date_formatter->format_datetime($donation->date));

    $saved = $text->{y};
    $text->move_to(297, $text->{y});
    $text->rprintln("Donation amount: ");
    $text->move_to(297, $saved);
    $text->println(' $ ' . sprintf("%.2f", ($donation->amount + $donation->fee)) . " USD");

    if ($donation->editor) {
        $saved = $text->{y};
        $text->move_to(297, $text->{y});
        $text->rprintln("Donation editor: ");
        $text->move_to(297, $saved);
        $text->println(" " . $donation->editor);
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
