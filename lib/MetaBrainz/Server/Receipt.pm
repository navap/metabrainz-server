#!/usr/bin/perl -w
# vi: set ts=4 sw=4 :
#____________________________________________________________________________
#
#   MusicBrainz -- the open internet music database
#
#   Copyright (C) 2000 Robert Kaye
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#   $Id$
#____________________________________________________________________________

package MetaBrainz::Server::TextWrapper;

use strict;
use PDF::API2;
use MIME::Lite;
use MetaBrainz::Server::MetaBrainz;
use MetaBrainz::Server::Donation;

sub newFromTxt
{
    my ($class, $txt) = @_;

    bless {
        txt => $txt,
          x => 0,
          y => 0,
    }, ref($class) || $class;
}

sub moveTo
{
    my ($self, $x, $y) = @_;

    $self->{x} = $x;
    $self->{y} = $y;
}

sub selectFont
{
    my ($self, $font, $size) = @_;

    #self->{font} = $font;
    $self->{size} = $size;
    $self->{txt}->font($font, $size);         
    $self->{lf} = int($size * 1.2);
}

sub println
{
    my ($self, $text) = @_;

    $self->{txt}->translate($self->{x},$self->{y});
    $self->{txt}->text($text); 
    $self->{y} -= $self->{lf};
}

sub rprintln
{
    my ($self, $text) = @_;

    $self->{txt}->translate($self->{x},$self->{y});
    $self->{txt}->text_right($text); 
    $self->{y} -= $self->{lf};
}

sub cprintln
{
    my ($self, $text) = @_;

    $self->{txt}->translate($self->{x},$self->{y});
    $self->{txt}->text_center($text); 
    $self->{y} -= $self->{lf};
}

sub lf
{
    my ($self, $text) = @_;

    $self->{y} -= $self->{lf};
}

package MetaBrainz::Server::Receipt;

sub new
{
    my ($class) = @_;
    bless { }, ref($class) || $class;
}

sub MailReceipt
{
    my ($self, $id) = @_;

    my $mb = new MetaBrainz::Server::MetaBrainz(1);
    $mb->Login();
    my $don = MetaBrainz::Server::Donation->new($mb->{DBH});
    $don = $don->newFromId($id);

    if ($don->{email})
    {
        my $file = "/tmp/receipt$$.pdf";

        $self->CreateReceipt($file, $don);
        $self->SendMail($file, $don);
        unlink($file);
    }
}

sub SendMail
{
    my ($self, $file, $data) = @_;

    my $text = "Dear " . $data->{first_name} . " " . $data->{last_name} . ":\n\n";
    $text .= "Thank you very much for your donation to the MetaBrainz Foundation!\n\n"; 
    $text .= "Your donation will allow the MetaBrainz Foundation to continue operating and ";
    $text .= "improving the MusicBrainz project (http://musicbrainz.org). MusicBrainz depends ";
    $text .= "on donations from the community and therefore deeply appreciates your support.\n\n";
    $text .= "The MetaBrainz Foundation is a United States 501(c)(3) tax-exempt public charity. This ";
    $text .= "allows US taxpayers to deduct this donation from their taxes under section 170 of the ";
    $text .= "Internal Revenue Service code.\n\n";
    $text .= "Please save a printed copy of the attached PDF receipt for your records.\n\n";

    # TODO: Fix the domain below
    my $msg = MIME::Lite->new(
                 Sender  =>'Donation Manager <donations@test.musicbrainz.org>',
                 From    =>'Donation Manager <donations@metabrainz.org>',
                 To      =>($data->{first_name}." ".$data->{last_name}." <" . $data->{email}.">"),
                 Subject =>'Receipt for your donation to the MetaBrainz Foundation',
                 Type    =>'multipart/mixed'
                 );

    $msg->attach(Type     =>'TEXT', 
                 Data     =>$text
                 );
    $msg->attach(Type     =>'application/pdf',
                 Path     =>$file,
                 Filename =>'metabrainz_donation.pdf',
                 Disposition => 'attachment'
                 );
    $msg->send;
}

sub CreateReceipt
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
    $txt->compress;

    my $gfx = $page->gfx;
    $gfx->compress;

    ## Create standard font references.
    my $HelveticaBold = $pdf->corefont('Helvetica-Bold');
    my $Helvetica = $pdf->corefont('Helvetica');

    my $text = MetaBrainz::Server::TextWrapper->newFromTxt($txt);

    my @lt = localtime(time);

    #--------------------------------------------------------------------
    # Draw the header
    #--------------------------------------------------------------------
    $text->selectFont($Helvetica, 14);         
    $text->moveTo(55, 700);
    $text->println("Donation Receipt"); 

    $text->selectFont($HelveticaBold, 16);         
    $text->moveTo(550, 700);
    $text->rprintln("MetaBrainz Foundation Inc."); 


    $text->selectFont($Helvetica, 12);         
    $text->rprintln("1435 Tanglewood Dr."); 
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

    $text->moveTo(55, $text->{y});
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

    $text->selectFont($HelveticaBold, 12);         
    $text->println('Please save a printed copy of this receipt for your records.');
    $text->lf;
    $text->lf;

    $text->selectFont($HelveticaBold, 12);         
    my $saved = $text->{y};
    $text->moveTo(297, $text->{y});
    $text->rprintln("Donation date: ");
    $text->moveTo(297, $saved);
    $text->println(" " . $data->{payment_date});

    $saved = $text->{y};
    $text->moveTo(297, $text->{y});
    $text->rprintln("Donation amount: ");
    $text->moveTo(297, $saved);
    $text->println(' $ ' . sprintf("%.2f", ($data->{amount} + $data->{fee})) . " USD");

    if ($data->{moderator}) 
    {
        $saved = $text->{y};
        $text->moveTo(297, $text->{y});
        $text->rprintln("Donation moderator: ");
        $text->moveTo(297, $saved);
        $text->println(" " . $data->{moderator});
    }

    $text->moveTo(55, $text->{y});
    $text->selectFont($HelveticaBold, 20);         
    $text->moveTo(297, $text->{y});
    $text->lf;
    $text->lf;
    $text->cprintln("Thank you for your support!");

    $pdf->finishobjects($page,$txt);
    $pdf->saveas;
    $pdf->end();
}

1;
