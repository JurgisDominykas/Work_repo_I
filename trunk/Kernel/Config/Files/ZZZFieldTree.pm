# OTRS config changes (settings of other packages or base settings) which cannot be overriden by user
# VERSION:1.1
package Kernel::Config::Files::ZZZFieldTree;
use utf8;

sub Load {
    my ($File, $Self) = @_;
    
    # Add FieldTree Dynamic Field to views
    $Self->{'Ticket::Frontend::CustomerTicketZoom'}->{'DynamicField'}->{'ProblemTypeID'} = '1';
    $Self->{'Ticket::Frontend::AgentTicketZoom'}->{'DynamicField'}->{'ProblemTypeID'} = '1';
    $Self->{'Ticket::Frontend::CustomerTicketMessage'}->{'DynamicField'}->{'ProblemTypeID'} = '2';
    $Self->{'Ticket::Frontend::AgentTicketPhone'}->{'DynamicField'}->{'ProblemTypeID'} = '1';
    $Self->{'Ticket::Frontend::AgentTicketEmail'}->{'DynamicField'}->{'ProblemTypeID'} = '1';
    
    # Add js and css files to common lists
    my $ArrayContains = [
        {
            'Array' => $Self->{'Loader::Customer::CommonJS'}->{'000-Framework'},
            'Contains' => 'FieldTree.js',
        },
        {
            'Array' => $Self->{'Loader::Agent::CommonJS'}->{'000-Framework'},
            'Contains' => 'FieldTree.js',
        },
        {
            'Array' => $Self->{'Loader::Agent::CommonCSS'}->{'000-Framework'},
            'Contains' => 'FieldTree.css',
        }
    ];
    for my $ArrContItem ( @$ArrayContains ) {
        next if grep( /^$ArrContItem->{Contains}$/, @{$ArrContItem->{Array}} );
        push @{$ArrContItem->{Array}}, $ArrContItem->{Contains};
    }
}
1;
