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

use strict;

package MetaBrainz::Server::Donation;

use Carp qw( croak );
use base qw( MetaBrainz::Server::TableBase );
use MetaBrainz::Server::Sql;
use MetaBrainz::Server::Cache;

################################################################################
# Bare Constructor
################################################################################

use Data::Dumper;
sub new
{
    my ($class, $dbh) = @_;

    my $self = $class->SUPER::new($dbh);

    $self;
}

################################################################################
# Properties
################################################################################

sub GetTable        { $_[0]{_table} }

# Get/SetId implemented by TableBase
sub GetFirstName        { $_[0]{first_name} }
sub SetFirstName        { $_[0]{first_name} = $_[1] }
sub GetLastName         { $_[0]{last_name} }
sub SetLastName         { $_[0]{last_name} = $_[1] }
sub GetEMail            { $_[0]{email} }
sub SetEMail            { $_[0]{email} = $_[1] }
sub GetModeratorName    { $_[0]{moderator} }
sub SetModeratorName    { $_[0]{moderator} = $_[1] }
sub GetOkToContact      { $_[0]{contact} }
sub SetOkToContact      { $_[0]{contact} = $_[1] }
sub GetIsAnon           { $_[0]{anon} }
sub SetIsAnon           { $_[0]{anon} = $_[1] }
sub GetAddressStreet    { $_[0]{address_street} }
sub SetAddressStreet    { $_[0]{address_street} = $_[1] }
sub GetAddressCity      { $_[0]{address_city} }
sub SetAddressCity      { $_[0]{address_city} = $_[1] }
sub GetAddressState     { $_[0]{address_state} }
sub SetAddressState     { $_[0]{address_state} = $_[1] }
sub SetAddressPostcode  { $_[0]{address_postcode} = $_[1] }
sub GetAddressPostcode  { $_[0]{address_postcode} }
sub SetAddressCountry   { $_[0]{address_country} = $_[1] }
sub GetAddressCountry   { $_[0]{address_country} }
sub SetPaymentDate      { $_[0]{payment_date} = $_[1] }
sub GetPaymentDate      { $_[0]{payment_date} }
sub SetPayPalTransId    { $_[0]{paypal_trans_id} = $_[1] }
sub GetPayPalTransId    { $_[0]{paypal_trans_id} }
sub SetAmount           { $_[0]{amount} = $_[1] }
sub GetAmount           { $_[0]{amount} }
sub SetFee              { $_[0]{fee} = $_[1] }
sub GetFee              { $_[0]{fee} }
sub SetMemo             { $_[0]{memo} = $_[1] }
sub GetMemo             { $_[0]{memo} }

sub _GetDonationStatsKey { "meb_donation_stats" };

################################################################################
# Data Retrieval
################################################################################

sub _new_from_row
{
    my $this = shift;
    my $self = $this->SUPER::_new_from_row(@_)
        or return;

    while (my ($k, $v) = each %$this)
    {
        $self->{$k} = $v
            if substr($k, 0, 1) eq "_";
    }
    $self->{DBH} = $this->{DBH};

    bless $self, ref($this) || $this;
}

sub newFromId
{
    my ($self, $id) = @_;
    my $sql = MetaBrainz::Server::Sql->new($self->{DBH});

    $sql->AutoCommit();
    $sql->Do("SET TIME ZONE LOCAL");
    my $row = $sql->SelectSingleRowHash(
        "SELECT first_name, last_name, email, moderator, contact, anon, address_street,
                address_city, address_state, address_postcode, address_country, memo,
                paypal_trans_id, amount, fee, to_char(payment_date, 'YYYY-MM-DD HH24:MI TZ') as payment_date
           FROM donation 
          WHERE id = ?",
        $id,
    );
    $self->_new_from_row($row);
}

sub newFromPayPalTransId
{
    my ($self, $id) = @_;
    my $sql = MetaBrainz::Server::Sql->new($self->{DBH});

    $sql->AutoCommit();
    $sql->Do("SET TIME ZONE LOCAL");
    my $row = $sql->SelectSingleRowHash(
        "SELECT first_name, last_name, email, moderator, contact, anon, address_street,
                address_city, address_state, address_postcode, address_country, 
                paypal_trans_id, amount, fee, to_char(payment_date, 'YYYY-MM-DD HH24:MI TZ') as payment_date
           FROM donation 
          WHERE paypal_trans_id = ?",
        $id,
    );
    $self->_new_from_row($row);
}

sub Insert
{
    my ($self, %data) = @_;

    my $sql = MetaBrainz::Server::Sql->new($self->{DBH});
    eval
    {
        if (!($data{payment_date}))
        {
            $data{payment_date} = $sql->SelectSingleValue("SELECT now()");
        }
        $sql->AutoCommit();
        $sql->Do("SET TIME ZONE LOCAL");
        $sql->AutoCommit();
        $sql->Do(
            "INSERT INTO donation (first_name, last_name, email, moderator, contact, anon, address_street,
                         address_city, address_state, address_postcode, address_country, 
                         paypal_trans_id, amount, fee, memo, payment_date) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", 
            $data{first_name}, $data{last_name}, $data{email}, $data{moderator},
            $data{contact}, $data{anon}, $data{address_street}, $data{address_city},
            $data{address_state}, $data{address_postcode}, $data{address_country},
            $data{paypal_trans_id}, $data{amount}, $data{fee}, $data{memo}, $data{payment_date} 
        );
    };
    if (my $err = $@)
    {
        return $err;
    }
    $self->SetId($sql->GetLastInsertId('donation'));
    MusicBrainz::Server::Cache->delete($self->_GetDonationStatsKey);

    return "";
}

sub GetDonations
{
    my ($self, $offset, $num) = @_;

    my $sql = MetaBrainz::Server::Sql->new($self->{DBH});
    $sql->AutoCommit();
    $sql->Do("SET TIME ZONE LOCAL");
    return ($sql->SelectSingleValue("SELECT count(*) FROM donation"),
            $sql->SelectListOfHashes("SELECT id, first_name, last_name, amount, moderator, anon, fee, memo,
                                             to_char(payment_date, 'YYYY-MM-DD HH24:MI TZ') as payment_date
                                        FROM donation 
                                    ORDER BY payment_date DESC 
                                      OFFSET ? 
                                       LIMIT ?", 
            $offset, $num));
}

sub GetHighestDonations
{
    my ($self, $offset, $num) = @_;

    my $sql = MetaBrainz::Server::Sql->new($self->{DBH});
    $sql->AutoCommit();
    $sql->Do("SET TIME ZONE LOCAL");
    return ($sql->SelectSingleValue("SELECT count(*) FROM donation"),
            $sql->SelectListOfHashes("SELECT id, first_name, last_name, amount, moderator, anon, fee, memo,
                                             to_char(payment_date, 'YYYY-MM-DD HH24:MI TZ') as payment_date
                                        FROM donation 
                                    ORDER BY amount DESC 
                                      OFFSET ? 
                                       LIMIT ?", 
            $offset, $num));
}

sub GetDonationStats
{
    my ($self) = @_;

    my $values = MusicBrainz::Server::Cache->get($self->_GetDonationStatsKey);
    return split ',', $values if $values;

    my $sql = MetaBrainz::Server::Sql->new($self->{DBH});
    my $cur_year = $sql->SelectSingleValue("SELECT EXTRACT(YEAR FROM NOW())");
    my $cur_month = $sql->SelectSingleValue("SELECT EXTRACT(MONTH FROM NOW())");
    my $mtd = $sql->SelectSingleValue("SELECT SUM(amount) FROM donation 
                                        WHERE ? = EXTRACT(MONTH FROM payment_date) and 
                                              ? = EXTRACT(YEAR FROM payment_date)", $cur_month, $cur_year);
    my $ytd = $sql->SelectSingleValue("SELECT SUM(amount) FROM donation 
                                        WHERE ? = EXTRACT(YEAR FROM payment_date)", $cur_year);

    # now go back one month:
    $cur_month--;
    if ($cur_month == 0)
    {
        $cur_month = 1;
        $cur_year--;
    }
    my $pmtd = $sql->SelectSingleValue("SELECT SUM(amount) FROM donation 
                                        WHERE ? = EXTRACT(MONTH FROM payment_date) and 
                                              ? = EXTRACT(YEAR FROM payment_date)", $cur_month, $cur_year);

    $values = MusicBrainz::Server::Cache->set($self->_GetDonationStatsKey, "$mtd,$ytd,$pmtd");

    return ($mtd, $ytd, $pmtd);
}

sub Delete
{
    my $self = shift;

    my $sql = MetaBrainz::Server::Sql->new($self->{DBH});
    $sql->Do(
        "DELETE FROM donation WHERE id = ?",
        $self->GetId,
    );
}

1;
# eof Donation.pm
