#!/usr/bin/perl 

print "begin;\n";
$header = <>;
while(defined($line = <>))
{
    @data = split ',', $line;
    @data = map { substr($_, 1, length($1) - 1) } @data;

    $data[8] = abs($data[8]);
    ($first, $last) = split ' ', $data[3];

    $date = "to_timestamp('$data[0] $data[1]', 'MM/DD/YYYY HH24:MI:SS')";
    $memo = $data[10];
    $memo =~ s/\'/\\\'/g;
    print qq|INSERT INTO donation (first_name, last_name, email, contact, 
                       anon, address_street, address_city, address_state, address_postcode, 
                       address_country, payment_date, paypal_trans_id, amount, fee, memo) values (
                       '$first', '$last', '$data[11]', 'n', 'n', '$data[35]', '$data[37]', '$data[38]',
                       '$data[39]', '$data[40]', $date, '$data[13]', $data[9], $data[8], '$memo');\n|;
}
print "commit;\n";
