# --
# Kernel/System/FieldTree.pm - all general catalog functions
# Copyright (C) 2001-2009 OTRS AG, http://otrs.org/
# --
# $Id: FieldTree.pm,v 0.01 2009/05/18 09:40:47 mh Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::FieldTree;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::CheckItem',
    'Kernel::System::DB',
    'Kernel::System::HTMLUtils',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::Cache',
    'Kernel::System::Log',
	'Kernel::System::Queue',
);

#use Kernel::System::ObjectManager;

use vars qw($VERSION);
$VERSION = qw($Revision: 0.01 $) [1];

=head1 NAME

Kernel::System::FieldTree - field tree lib

=head1 SYNOPSIS

Field tree component

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::Config;
    use Kernel::System::DB;
    use Kernel::System::FieldTree;
    use Kernel::System::Log;
    use Kernel::System::Main;

    my $ConfigObject = Kernel::Config->new();
    my $Log = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
    );
    my $MainObject = Kernel::System::Main->new(
        ConfigObject => $ConfigObject,
        Log    => $Log,
    );
    my $DBObject = Kernel::System::DB->new(
        ConfigObject => $ConfigObject,
        Log    => $Log,
        MainObject   => $MainObject,
    );
    my $FieldTreeObject = Kernel::System::FieldTree->new(
        ConfigObject => $ConfigObject,
        Log    => $Log,
        DBObject     => $DBObject,
        MainObject   => $MainObject,
    );



=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # ParamObject available TIK tikriems requestams!!!
    $Self->{CacheType} = 'FieldTree';
    $Self->{CacheTTL} = 10000;
	$Self->{TTL} = 10000;
    
    return $Self;
}

=item ClassList()

return an array reference of all general catalog classes

    my $ArrayRef = $FieldTreeObject->ClassList();

=cut

sub ClassList {
    my ( $Self, %Param ) = @_;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # ask database
    $DBObject->Prepare(
        SQL => 'SELECT DISTINCT(field_tree_class) '
            . 'FROM field_tree ORDER BY field_tree_class',
    );

    # fetch the result
    my @ClassList;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @ClassList, $Row[0];
    }

    return \@ClassList;
}

=item ClassRename()

rename a general catalog class

    my $True = $FieldTreeObject->ClassRename(
        ClassOld => 'ITSM::ConfigItem::State',
        ClassNew => 'ITSM::ConfigItem::DeploymentState',
    );

=cut

sub ClassRename {
    my ( $Self, %Param ) = @_;
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    # check needed stuff
    for my $Argument (qw(ClassOld ClassNew)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # cleanup given params
    my $CheckItem = $Kernel::OM->Get('Kernel::System::CheckItem');
    for my $Argument (qw(ClassOld ClassNew)) {
        $CheckItem->StringClean(
            StringRef         => \$Param{$Argument},
            RemoveAllNewlines => 1,
            RemoveAllTabs     => 1,
            RemoveAllSpaces   => 1,
        );
    }

    return 1 if $Param{ClassNew} eq $Param{ClassOld};

    # check if new class name already exists
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM field_tree WHERE field_tree_class = ?',
        Bind  => [ \$Param{ClassNew} ],
        Limit => 1,
    );

    # fetch the result
    my $AlreadyExists = 0;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $AlreadyExists = 1;
    }

    if ($AlreadyExists) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Can't rename class $Param{ClassOld}! New classname already exists."
        );
        return;
    }

    # reset cache
    delete $Self->{Cache}->{ItemGet}->{Class}->{ $Param{ClassOld} };
    delete $Self->{Cache}->{ItemGet}->{Class}->{ $Param{ClassNew} };
    delete $Self->{Cache}->{ItemGet}->{ItemID};
    delete $Self->{Cache}->{ItemList};

    # rename general catalog class
    return $DBObject->Do(
        SQL => 'UPDATE field_tree SET field_tree_class = ? '
            . 'WHERE field_tree_class = ?',
        Bind => [ \$Param{ClassNew}, \$Param{ClassOld} ],
    );
}

=item ItemList()

return a hash reference of one field tree class

    my $HashRef = $FieldTreeObject->ItemList(
        Class    => 'ITSM::Service::Type',
        ParentID => 53, # (optional) return children of specified item
        Valid    => 0,  # (optional) default 1
        UseFriendlyName => 1, # (optional) return friendly names instead of simple names (default 0)
    );

=cut

sub ItemList {
    my ( $Self, %Param ) = @_;


    # set default value
    if ( !defined $Param{Valid} ) {
        $Param{Valid} = 1;
    }
    $Param{UseFriendlyName} = $Param{UseFriendlyName} || 0;
 
    # create sql string
    my $SQL  = "SELECT id, name, friendly_name FROM field_tree WHERE TRUE ";
    my @BIND = ( );

    # create cache key
    my $CacheKey =  $Param{UseFriendlyName} . '#' . $Param{Valid} . '####';

    # add valid string to sql string
    if ( $Param{Valid} ) {
        $SQL .= 'AND valid_id = 1 ';
    }

    if ( $Param{ParentID} ) {
        $SQL .= 'AND parent_id = ? ';
        push @BIND, ( \$Param{ParentID} );
        $CacheKey .= $Param{ParentID}.'####';
    }

    if ( $Param{Class} ) {
        $SQL .= 'AND field_tree_class = ? ';
        push @BIND, ( \$Param{Class} );
        $CacheKey .= $Param{Class}.'####';
    }

    $SQL .= ' ORDER BY position ASC';


    # check if result is already cached
    return $Self->{Cache}->{ItemList}->{$CacheKey}
        if (exists $Self->{Cache}->{ItemList}->{$CacheKey});

    # ask database
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    $DBObject->Prepare(
        SQL  => $SQL,
        Bind => \@BIND,
    );

    # fetch the result
    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        my $Name = $Row[1];
        $Name = $Row[2] if ( $Param{UseFriendlyName} && $Row[2] );
        $Data{ $Row[0] } = $Name;
    }

    # check item
 #   if ( !%Data ) {
 #       $Kernel::OM->Get('Kernel::System::Log')->Log(
 #           Priority => 'error',
 #           Message  => 'Class not found in database!',
 #       );
 #      return;
 #   }

    # cache the result
    $Self->{Cache}->{ItemList}->{$CacheKey} = \%Data;

    return \%Data;
}

# same as ItemList, but returns array instead of hashref
# items are sorted by Position field (ascending)
sub ItemListSorted {
    my ( $Self, %Param ) = @_;


    # set default value
    if ( !defined $Param{Valid} ) {
        $Param{Valid} = 1;
    }
    $Param{UseFriendlyName} = $Param{UseFriendlyName} || 0;

    # create sql string
    my $SQL  = "SELECT id, name, friendly_name FROM field_tree WHERE TRUE ";
    my @BIND = ( );

    # create cache key
    my $CacheKey =  $Param{UseFriendlyName} . '#' . $Param{Valid} . '####';

    # add valid string to sql string
    if ( $Param{Valid} ) {
        $SQL .= 'AND valid_id = 1 ';
    }

    if ( $Param{ParentID} ) {
        $SQL .= 'AND parent_id = ? ';
        push @BIND, ( \$Param{ParentID} );
        $CacheKey .= $Param{ParentID}.'####';
    }

    if ( $Param{Class} ) {
        $SQL .= 'AND field_tree_class = ? ';
        push @BIND, ( \$Param{Class} );
        $CacheKey .= $Param{Class}.'####';
    }

    $SQL .= ' ORDER BY position ASC';


    # check if result is already cached
    return $Self->{Cache}->{ItemListSorted}->{$CacheKey}
        if (exists $Self->{Cache}->{ItemListSorted}->{$CacheKey});

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    # ask database
    $DBObject->Prepare(
        SQL  => $SQL,
        Bind => \@BIND,
    );

    # fetch the result
    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        my $Name = $Row[1];
        $Name = $Row[2] if ( $Param{UseFriendlyName} && $Row[2] );
        $Data{ $Row[0] } = $Name;
    }

 # check item
 #   if ( !%Data ) {
 #       $Kernel::OM->Get('Kernel::System::Log')->Log(
 #           Priority => 'error',
 #           Message  => 'Class not found in database!',
 #       );
 #      return;
 #   }

    # cache the result
    $Self->{Cache}->{ItemListSorted}->{$CacheKey} = \%Data;

    return \%Data;
}

=item ItemGet()

get a fieldtree item

Return
    $ItemData{ItemID}
    $ItemData{Class}
    $ItemData{Name}
    $ItemDate{FriendlyName}
    $ItemData{ParentID}
    $ItemData{ValidID}
    $ItemDate{CssClass}
    $ItemData{Comment}
    $ItemData{CreateTime}
    $ItemData{CreateBy}
    $ItemData{ChangeTime}
    $ItemData{ChangeBy}

    By ID:
    my $ItemDataRef = $FieldTreeObject->ItemGet(
        ItemID  => 3,
    );

    or

    By Class, Name and ParentID (equals -1 if ommited)
    my $ItemDataRef = $FieldTreeObject->ItemGet(
        Class => 'ITSM::Service::Type',
        Name  => 'Item Name',
        ParentID => -1,
    );

=cut

sub ItemGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ItemID} && ( !$Param{Class} || !$Param{Name} ) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ItemID OR Class and Name!'.Dumper(\%Param),
        );
        return;
    }

    # create sql string
    my $SQL = 'SELECT id, field_tree_class, name, friendly_name, parent_id, '
        . 'valid_id, css_class, comments, '
        . 'create_time, create_by, change_time, change_by, position FROM field_tree WHERE ';
    my @BIND;

    # add options to sql string
    if ( $Param{Class} && $Param{Name} ) {
        $Param{ParentID} = -1 if !$Param{ParentID};
        # check if result is already cached
        return $Self->{Cache}->{ItemGet}->{Class}->{ $Param{Class} }->{ $Param{ParentID} }->{ $Param{Name} }
            if (exists $Self->{Cache}->{ItemGet}->{Class}->{ $Param{Class} }->{ $Param{ParentID} }->{ $Param{Name} });

        # add class and name to sql string
        $SQL .= 'field_tree_class = ? AND name = ? AND parent_id = ?';
        push @BIND, ( \$Param{Class}, \$Param{Name}, \$Param{ParentID} );
    }
    else {
        # check if result is already cached
        return $Self->{Cache}->{ItemGet}->{ItemID}->{ $Param{ItemID} }
            if (exists $Self->{Cache}->{ItemGet}->{ItemID}->{ $Param{ItemID} });

        # add item id to sql string
        $SQL .= 'id = ?';
        push @BIND, \$Param{ItemID};
    }

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');    
    # ask database
    $DBObject->Prepare(
        SQL   => $SQL,
        Bind  => \@BIND,
        Limit => 1,
    );

    # fetch the result
    my %ItemData;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ItemData{ItemID}        = $Row[0];
        $ItemData{Class}         = $Row[1];
        $ItemData{Name}          = $Row[2];
        $ItemData{FriendlyName}  = $Row[3];
        $ItemData{ParentID} 	   = $Row[4];
        $ItemData{ValidID}       = $Row[5];
        $ItemData{CssClass}      = $Row[6];
        $ItemData{Comment}       = $Row[7] || '';
        $ItemData{CreateTime}    = $Row[8];
        $ItemData{CreateBy}      = $Row[9];
        $ItemData{ChangeTime}    = $Row[10];
        $ItemData{ChangeBy}      = $Row[11];
        $ItemData{Position}      = $Row[12];
    }

    # check item
    if ( !$ItemData{ItemID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Item not found in database!',
        );
        return;
    }

    # cache the result
    $Self->{Cache}->{ItemGet}->{Class}->{ $ItemData{Class} }->{ $ItemData{ParentID} }->{ $ItemData{Name} } = \%ItemData;
    $Self->{Cache}->{ItemGet}->{ItemID}->{ $ItemData{ItemID} } = \%ItemData;

    return \%ItemData;
}

=item ItemAdd()

add a new general catalog item

    my $ItemID = $FieldTreeObject->ItemAdd(
        Class         => 'ITSM::Service::Type',
        Name          => 'Item Name',
        FriendlyName  => 'Friendly Item Name',
        ParentID => 59,                
        ValidID       => 1,
        CssClass      => '',
        Comment       => 'Comment',              # (optional)
        UserID        => 1,
    );

=cut

sub ItemAdd {
    my ( $Self, %Param ) = @_;

    # if ($Self->{CacheObject}) {
    # 	$Self->{CacheObject}->CleanUp(
    # 		Type	=> 'FieldTree',
    # 	);
    # }

    # check needed stuff
    for my $Argument (qw(Class Name ValidID UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # set default values
    for my $Argument (qw(Comment)) {
        $Param{$Argument} ||= '';
    }

    for my $Argument (qw(Position)) {
        $Param{$Argument} ||= 0;
    }

    # cleanup given params
    
# Justinas FIXME FIXME FIXME: Required Server-side validation for the ParentID integer
    my $CheckItem = $Kernel::OM->Get('Kernel::System::CheckItem');
    for my $Argument (qw(Class)) {
        $CheckItem->StringClean(
            StringRef         => \$Param{$Argument},
            RemoveAllNewlines => 1,
            RemoveAllTabs     => 1,
            RemoveAllSpaces   => 1,
        );
    }
    for my $Argument (qw(Name Comment)) {
        $CheckItem->StringClean(
            StringRef         => \$Param{$Argument},
            RemoveAllNewlines => 1,
            RemoveAllTabs     => 1,
        );
    }
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    # find exiting item with same name
    $DBObject->Prepare(
        SQL => 'SELECT id FROM field_tree '
            . 'WHERE field_tree_class = ? AND name = ? AND parent_id = ?',
        Bind => [ \$Param{Class}, \$Param{Name} , \$Param{ParentID} ],
        Limit => 1,
    );

    # fetch the result
    my $NoAdd;
    while ( $DBObject->FetchrowArray() ) {
        $NoAdd = 1;
    }
    

    # abort insert of new item, if item name already exists
    if ($NoAdd) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message =>
                "Can't add new item! FieldTree item with same name already exists in this class and level.",
        );
        return;
    }

    # reset cache
    delete $Self->{Cache}->{ItemList};

    # insert new item
    return if !$DBObject->Do(
        SQL => 'INSERT INTO field_tree '
            . '(field_tree_class, name, friendly_name, parent_id, valid_id, '
            . 'css_class, comments, '
            . 'create_time, create_by, change_time, change_by, position) VALUES '
            . '(?, ?, ?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?, ?)',
        Bind => [
            \$Param{Class},         \$Param{Name},
            \$Param{FriendlyName},  \$Param{ParentID},
            \$Param{ValidID},       \$Param{CssClass},
            \$Param{Comment},       \$Param{UserID},
            \$Param{UserID},		\$Param{Position},
        ],
    );

    # find id of new item
    $DBObject->Prepare(
        SQL => 'SELECT id FROM field_tree '
            . 'WHERE field_tree_class = ? AND name = ?',
        Bind => [ \$Param{Class}, \$Param{Name} ],
        Limit => 1,
    );

    # fetch the result
    my $ItemID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ItemID = $Row[0];
    }

    return $ItemID;
}


sub FieldTreesRecursiveIDs {
   my ( $Self, %Param ) = @_;
   
	#check needed stuff
    for my $Argument (qw(ItemID Separator)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }
    
    my $Result = "";
    
    my $ItemID = $Param{ItemID};
              
   	while (defined($ItemID) && $ItemID ne "-1" && $ItemID ne "" && $ItemID ne $Param{RootID} && $ItemID gt 0) 
	{
		if($Result ne "")
		{
			$Result = "$Param{Separator}$Result";
		}
			
		$Result = "$ItemID$Result";
		
		my $Item = $Self->ItemGet(
			ItemID => $ItemID,
		);
		
		
		$ItemID = $Item->{ParentID};
	}
    
	return $Result;
}

=item ItemRecursiveName()

Return field tree item name with all parent names 

    my $True = $FieldTreeObject->ItemRecursiveName(
        ItemID        => 123,
        Class => 'XY',
    );

=cut

sub ItemRecursiveName {
   my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ItemID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }
    my $Result = "";
   #  if ($Self->{CacheObject}) {
   #  	$Result = $Self->{CacheObject}->Get(
   #  		Type	=> 'FieldTree',
			# Key => 'RecursiveName_'.$Param{ItemID},    		
   #  	);
   #  }
    if ($Result) {
    	return $Result;
    }
    
    my $ItemID = $Param{ItemID};
    my $Name = '';
	while (defined($ItemID) && $ItemID ne "-1" && $ItemID ne "" && $ItemID gt 0) 
	{
		my $Item = $Self->ItemGet(
			ItemID => $ItemID,
		);
		my $b = $ItemID;
		if (defined($Item->{ParentID}) && $Item->{ParentID} gt 0) {
			$Name = (defined($Item->{Name}) ?$Item->{Name} : '|') . ($ItemID+0 == -1 || $ItemID eq $Param{ItemID} ? '' : ' - ').$Name;
		}
		$ItemID = $Item->{ParentID};
		if (!$ItemID) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Bad parent item ID: $ItemID".Dumper($Item),
            );
        }
          
		
	}
   #  if ($Self->{CacheObject}) {
   #  	$Result = $Self->{CacheObject}->Set(
   #  		Type  => 'FieldTree',
			# Key   => 'RecursiveName_'.$Param{ItemID},
			# Value => $Name,
			# TTL   => 60 * 60 * 24, # 1 day
   #  	);
   #  }
	return $Name;
}


# Returns field tree item name with all parent names in hash 
sub ItemRecursiveNamesHash {
   my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ItemID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }
    
    my $Result;
   #  if ($Self->{CacheObject}) {
   #  	$Result = $Self->{CacheObject}->Get(
   #  		Type	=> 'FieldTree',
			# Key => 'RecursiveNameHash_'.$Param{ItemID},    		
   #  	);
   #  }
   #  if ($Result) {
   #  	return $Result;
   #  }

    my $ItemID = $Param{ItemID};
    my $Name = '';
    my @Names = ();
    my $Counter = 0;
	while (defined($ItemID) && $ItemID ne "-1" && $ItemID ne "" && $ItemID gt 0) 
	{
		my $Item = $Self->ItemGet(
			ItemID => $ItemID,
		);
		my $b = $ItemID;
		if (defined($Item->{ParentID}) && $Item->{ParentID} gt 0) {
			#$Name = (defined($Item->{Name}) ?$Item->{Name} : '|') . ($ItemID+0 == -1 || $ItemID eq $Param{ItemID} ? '' : ' - ').$Name;
			if (defined($Item->{Name})) {
			    $Names[$Counter] = $Item->{Name};
			    $Counter++;
			}
		}
		$ItemID = $Item->{ParentID};
		if (!$ItemID) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Bad parent item ID: $ItemID".Dumper($Item),
            );
        }
          
		
	};
	
	my $i;
	my $Counter2 = 1;
	my %NamesHash = ();
	for ($i = $Counter-1; $i >= 0; $i--) {
	    $NamesHash{"Label".$Counter2} = $Names[$i];
	    $Counter2++;
	}
   #  if ($Self->{CacheObject}) {
   #  	$Self->{CacheObject}->Set(
   #  		Type  => 'FieldTree',
			# Key   => 'RecursiveNameHash_'.$Param{ItemID},
			# Value => \%NamesHash,
			# TTL   => 60 * 60 * 24, # 1 day		
   #  	);
   #  }
	
	return \%NamesHash;
}


=item ItemUpdate()

update a existing general catalog item

    my $True = $FieldTreeObject->ItemUpdate(
        ItemID        => 123,
        Name          => 'Item Name',
        FriendlyName  => 'Very friendly name',
        ParentID => 69,      
        ValidID       => 1,
        CssClass      => 'very-red',
        Comment       => 'Comment',    # (optional)
        UserID        => 1,
    );

=cut
sub ItemUpdate {
    my ( $Self, %Param ) = @_;

    # if ($Self->{CacheObject}) {
    # 	$Self->{CacheObject}->CleanUp(
    # 		Type	=> 'FieldTree',
    # 	);
    # }
    	
    # check needed stuff
    for my $Argument (qw(ItemID Name ValidID UserID ParentID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # set default values
    for my $Argument (qw(Comment FriendlyName CssClass)) {
        $Param{$Argument} ||= '';
    }
    my $CheckItem = $Kernel::OM->Get('Kernel::System::CheckItem');

    # cleanup given params
    for my $Argument (qw(Class)) {
        $CheckItem->StringClean(
            StringRef         => \$Param{$Argument},
            RemoveAllNewlines => 1,
            RemoveAllTabs     => 1,
            RemoveAllSpaces   => 1,
        );
    }
    for my $Argument (qw(Name Comment)) {
        $CheckItem->StringClean(
            StringRef         => \$Param{$Argument},
            RemoveAllNewlines => 1,
            RemoveAllTabs     => 1,
        );
    }
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    # get class of item
    $DBObject->Prepare(
        SQL   => 'SELECT field_tree_class FROM field_tree WHERE id = ?',
        Bind  => [ \$Param{ItemID} ],
        Limit => 1,
    );

    # fetch the result
    my $Class;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Class = $Row[0];
    }

	if ( !$Class ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "Can't update item! FieldTree item not found in this class.",
        );
        return;
    }

    # find exiting item with same name
    $DBObject->Prepare(
        SQL   => 'SELECT id FROM field_tree WHERE field_tree_class = ? AND name = ? AND parent_id = ?',
        Bind  => [ \$Class, \$Param{Name}, \$Param{ParentID} ],
        Limit => 1,
    );

    # fetch the result
    my $Update = 1;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        if ( $Param{ItemID} ne $Row[0] ) {
            $Update = 0;
        }
    }

    if ( !$Update ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message =>
                "Can't update item! General catalog item with same name already exists in this class.",
        );
        return;
    }


	# reset cache
    delete $Self->{Cache}->{ItemGet}->{Class}->{$Class}->{ $Param{ParentID} }->{ $Param{Name} };
    delete $Self->{Cache}->{ItemGet}->{ItemID}->{ $Param{ItemID} };
    delete $Self->{Cache}->{ItemList};

    return $DBObject->Do(
        SQL => 'UPDATE field_tree SET '
            . 'name = ?, friendly_name = ?, '
            . 'valid_id = ?, css_class = ?, comments = ?, '
            . 'change_time = current_timestamp, change_by = ? '
            . 'WHERE id = ?',
        Bind => [
            \$Param{Name},    \$Param{FriendlyName},
            \$Param{ValidID}, 
            \$Param{CssClass},\$Param{Comment},
            \$Param{UserID},  \$Param{ItemID},
        ],
    );
}


=item FieldAdd()

add a new field to tree leaf

    my $ItemID = $FieldTreeObject->FieldAdd(
    	FieldTreeID        => 15,  			#Item leaf ftom field tree structure
        FieldType         => 'Text',
        Name          => 'Item Name',
        FriendlyName  => 'Friendly name',
        Required => true/false,                
        Template => 'Default value',
        Target => '159',
        Position => 16,
        ValidID       => 1,
        Hidden        => 0,
        Comment       => 'Comment',              # (optional)
        UserID        => 1,
    );

=cut

sub FieldAdd {
    my ( $Self, %Param ) = @_;

    # if ($Self->{CacheObject}) {
    # 	$Self->{CacheObject}->CleanUp(
    # 		Type	=> 'FieldTree',
    # 	);
    # }

    # check needed stuff
    for my $Argument (qw(FieldTreeID FieldType Name ValidID UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # set default values
    for my $Argument (qw(FriendlyName Comment Template Target)) {
        $Param{$Argument} ||= '';
    }

    for my $Argument (qw(Required Position Hidden)) {
        $Param{$Argument} ||= 0;
    }

    # cleanup given params
    my $CheckItem = $Kernel::OM->Get('Kernel::System::CheckItem');

# Justinas FIXME FIXME FIXME: Required Server-side validation for the FieldTreeID integer
    for my $Argument (qw(FieldType)) {
        $CheckItem->StringClean(
            StringRef         => \$Param{$Argument},
            RemoveAllNewlines => 1,
            RemoveAllTabs     => 1,
            RemoveAllSpaces   => 1,
        );
    }
    for my $Argument (qw(Name Comment)) {
        $CheckItem->StringClean(
            StringRef         => \$Param{$Argument},
            RemoveAllNewlines => 1,
            RemoveAllTabs     => 1,
        );
    }
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    # find exiting item with same name
    $DBObject->Prepare(
        SQL => 'SELECT id FROM field_tree_field '
            . 'WHERE name = ? AND field_tree_id = ?',
        Bind => [ \$Param{Name} , \$Param{FieldTreeID} ],
        Limit => 1,
    );

    # fetch the result
    my $NoAdd;
    while ( $DBObject->FetchrowArray() ) {
        $NoAdd = 1;
    }

    # abort insert of new item, if item name already exists
    if ($NoAdd) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message =>
                "Can't add new field! FieldTree field with same name already exists in this level.",
        );
        return;
    }

    # reset cache
    delete $Self->{Cache}->{FieldList};

    # insert new item
    return if !$DBObject->Do(
        SQL => 'INSERT INTO field_tree_field '
            . '(field_type, name, friendly_name, required, field_tree_id, template, target, position, valid_id, comments, '
            . 'hidden, create_time, create_by, change_time, change_by) VALUES '
            . '(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{FieldType},   \$Param{Name},         \$Param{FriendlyName},
            \$Param{Required},	    \$Param{FieldTreeID},	\$Param{Template},
            \$Param{Target},		\$Param{Position}, 	\$Param{ValidID},
            \$Param{Comment},     \$Param{Hidden},      \$Param{UserID},
            \$Param{UserID},
        ],
    );

# FIXME: SITAIP RASYT NEGALIMA! Nereikia SQL'o jokio kad gaut naujai sukurto iraso ID
    # find id of new item
    $DBObject->Prepare(
        SQL => 'SELECT id FROM field_tree_field '
            . 'WHERE field_type = ? AND name = ? AND field_tree_id = ?',
        Bind => [ \$Param{FieldType}, \$Param{Name}, \$Param{FieldTreeID} ],
        Limit => 1,
    );

    # fetch the result
    my $ItemID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ItemID = $Row[0];
    }

    return $ItemID;
}

=item FieldUpdate()

update a existing field

    my $True = $FieldTreeObject->ItemUpdate(
        FieldID        => 123,
        Type 		  => Text,
        Name          => 'Item Name',
        FriendlyName  => 'Friendly name',
        FieldType	  => 'Text',
        Required	 => [true/false],
        ValidID       => 1,
        Hidden        => 0,
        Comment       => 'Comment',    # (optional)
        UserID        => 1,
    );

=cut

sub FieldUpdate {
    my ( $Self, %Param ) = @_;
    # if ($Self->{CacheObject}) {
    # 	$Self->{CacheObject}->CleanUp(
    # 		Type	=> 'FieldTree',
    # 	);
    # }

    # check needed stuff
    for my $Argument (qw(FieldID FieldType Name ValidID UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }
    
    # set default values
    for my $Argument (qw(FriendlyName Comment Template Target)) {
        $Param{$Argument} ||= '';
    }
    
    for my $Argument (qw(Required Position Hidden)) {
        $Param{$Argument} ||= 0;
    }
    my $CheckItem = $Kernel::OM->Get('Kernel::System::CheckItem');

    # cleanup given params
    for my $Argument (qw(FieldType)) {
        $CheckItem->StringClean(
            StringRef         => \$Param{$Argument},
            RemoveAllNewlines => 1,
            RemoveAllTabs     => 1,
            RemoveAllSpaces   => 1,
        );
    }
    for my $Argument (qw(Name Comment)) {
        $CheckItem->StringClean(
            StringRef         => \$Param{$Argument},
            RemoveAllNewlines => 1,
            RemoveAllTabs     => 1,
        );
    }
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    # get class of item
    $DBObject->Prepare(
        SQL   => 'SELECT field_tree_id FROM field_tree_field WHERE id = ?',
        Bind  => [ \$Param{FieldID} ],
        Limit => 1,
    );

    # fetch the result
    my $FieldTreeID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $FieldTreeID = $Row[0];
    }

    if ( !$FieldTreeID ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Can't update item! Field not found.",
        );
        return;
    }

    # reset cache
    delete $Self->{Cache}->{FieldGet}->{FieldTreeID}->{$FieldTreeID}; # we don't know if Name was changed so we delete all fields with same FieldTreeID in the cache
    delete $Self->{Cache}->{FieldGet}->{FieldID}->{ $Param{FieldID} };
    delete $Self->{Cache}->{FieldList};

    return $DBObject->Do(
        SQL => 'UPDATE field_tree_field SET '
            . 'name = ?, friendly_name = ?, required = ?, field_type = ?, '
            . 'template = ?, target = ?, position = ?, '
            . 'valid_id = ?, hidden = ?, comments = ?, '
            . 'change_time = current_timestamp, change_by = ? '
            . 'WHERE id = ?',
        Bind => [
            \$Param{Name}, \$Param{FriendlyName}, \$Param{Required}, 
            \$Param{FieldType},\$Param{Template}, \$Param{Target}, 
            \$Param{Position}, \$Param{ValidID}, \$Param{Hidden},
            \$Param{Comment},  \$Param{UserID},  \$Param{FieldID},
        ],
    );
}



=item FieldList()

return a list as hash reference of one general catalog class

    my $HashRef = $FieldTreeObject->FieldList(
        FieldTreeID => 53,               # (optional) string or array reference
    );

=cut

sub FieldList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{FieldTreeID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need FieldTreeID!'
        );
        return;
    }

    # set default value
    if ( !defined $Param{Valid} ) {
        $Param{Valid} = 1;
    }

    # create sql string
    my $SQL  = 'SELECT id, name, position FROM field_tree_field WHERE true ';
    my @BIND = (  );

    # create cache key
    my $CacheKey = '';

    # add valid string to sql string
    if ( $Param{Valid} ) {
        $SQL .= 'AND valid_id = 1 ';
    }

    if ( $Param{FieldTreeID} ) {
        $SQL .= 'AND field_tree_id = ? ';
        push @BIND, ( \$Param{FieldTreeID} );
        $CacheKey .= $Param{FieldTreeID}.'####';
    }



    # check if result is already cached
    return $Self->{Cache}->{FieldList}->{$CacheKey}
        if (exists $Self->{Cache}->{FieldList}->{$CacheKey});
        
    $SQL .= ' ORDER BY position ASC';

    # ask database
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    $DBObject->Prepare(
        SQL  => $SQL,
        Bind => \@BIND,
    );

    # fetch the result
    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{ $Row[0] } = $Row[1].'_'.$Row[2];
    }
 #   check item
 #   if ( !%Data ) {
 #       $Kernel::OM->Get('Kernel::System::Log')->Log(
 #           Priority => 'error',
 #           Message  => 'Class not found in database!',
 #       );
 #      return;
 #   }

    # cache the result
    $Self->{Cache}->{FieldList}->{$CacheKey} = \%Data;

    return \%Data;
}

=item FieldGet()

get a tree field item

Return

    my $ItemDataRef = $FieldTreeObject->FieldGet(
        FieldID  => 3,
    );

    or

    my $ItemDataRef = $FieldTreeObject->FieldGet(
        FieldTreeID => 6,
        Name => 'FieldName',
    );

=cut

sub FieldGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{FieldID} && ( !$Param{FieldTreeID} || !$Param{Name} ) ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need ItemID OR FieldTreeID and Name!'
        );
        return;
    }

    # create sql string
    my $SQL = 'SELECT id, field_type, name, friendly_name, required, '
        . 'field_tree_id, template, target, position, valid_id, hidden, comments, '
        . 'create_time, create_by, change_time, change_by FROM field_tree_field WHERE ';
    my @BIND;

    # add options to sql string
    if ( $Param{FieldTreeID} && $Param{Name} ) {

        # check if result is already cached
        return $Self->{Cache}->{FieldGet}->{FieldTreeID}->{ $Param{FieldTreeID} }->{ $Param{Name} }  
            if (exists $Self->{Cache}->{FieldGet}->{FieldTreeID}->{ $Param{FieldTreeID} }->{ $Param{Name} });

        # add class and name to sql string
        $SQL .= 'field_tree_id = ? and name = ? ';
        push @BIND, ( \$Param{FieldTreeID}, \$Param{Name} );
    }
	else {

        # check if result is already cached
        return $Self->{Cache}->{FieldGet}->{FieldID}->{ $Param{FieldID} }
            if (exists $Self->{Cache}->{FieldGet}->{FieldID}->{ $Param{FieldID} });

        # add item id to sql string
        $SQL .= 'id = ? ';
        push @BIND, \$Param{FieldID};
    }
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    # ask database
    $DBObject->Prepare(
        SQL   => $SQL,
        Bind  => \@BIND,
        Limit => 1,
    );

    # fetch the result
    my %ItemData;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ItemData{FieldID}       = $Row[0];
        $ItemData{FieldType}     = $Row[1];
        $ItemData{Name}          = $Row[2];
        $ItemData{FriendlyName}  = $Row[3];
        $ItemData{Required} 	   = $Row[4];
        $ItemData{FieldTreeID}   = $Row[5];
        $ItemData{Template}      = $Row[6]  || '';;
        $ItemData{Target}        = $Row[7]  || '';;
        $ItemData{Position}      = $Row[8];
        $ItemData{ValidID}       = $Row[9];
        $ItemData{Hidden}        = $Row[10];
        $ItemData{Comment}       = $Row[11] || '';
        $ItemData{CreateTime}    = $Row[12];
        $ItemData{CreateBy}      = $Row[13];
        $ItemData{ChangeTime}    = $Row[14];
        $ItemData{ChangeBy}      = $Row[15];
    }

    # check item
    if ( !$ItemData{FieldID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Item not found in database! Params: '.Dumper(\%Param),
        );
        return;
    }

    # cache the result
    $Self->{Cache}->{FieldGet}->{FieldTreeID}->{ $ItemData{FieldTreeID} }->{ $ItemData{Name} } = \%ItemData;
    $Self->{Cache}->{FieldGet}->{FieldID}->{ $ItemData{FieldID} } = \%ItemData;

    return \%ItemData;
}

=item ValueSetAdd()
update a valueset for a field list

Return

    my $ValueSetID = $FieldTreeObject->ValueSetAdd(
        Data => %ref
    );

=cut
sub ValueSetAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(Data)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }
    
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    $DBObject->Do(SQL => 'INSERT INTO field_tree_value_sets (id) VALUES (default)');
    
    # get inserted ID
    #FIXED FROM HERE && NEEDS SEQUENCE FOR SOME REASON
    my $id = $DBObject->{dbh}->last_insert_id(undef, undef, 'field_tree_value_sets', undef);    
    #UP TO HERE
    my $Data = $Param{Data};    
   	my $FieldDBTypes = $Self->FieldTypeDBTypes();

    my @HistoryLines;
    my $ProblemType = '';
    
    foreach my $FieldID ( sort keys %{$Data}) {
    	my $Field = $Self->FieldGet(
			FieldID => $FieldID
		);
    	   		
    	my $FieldDBType = $FieldDBTypes->{$Field->{FieldType}};
    	if (defined($FieldDBType) && $FieldDBType ne 'none') {
    	    
	    	$DBObject->Do(
    	        SQL  => 'INSERT INTO field_tree_value (field_id, field_tree_id, '
    	        	   .' value_set_id, value_'.$FieldDBType.') VALUES (?, ?, ?, ?)',
    	        Bind => [
    	            \$FieldID, \$Field->{FieldTreeID}, \$id, \$Data->{$FieldID},
	            ],
	        );
		       
	        if (($Field->{FieldType} eq "Select") && ($Data->{$FieldID} =~ /^-?\d+$/)) {
        	my $Item = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemGet(
	                ItemID  => $Data->{$FieldID},
	            );
	            push @HistoryLines, "\%\%$Field->{Name}\%\%$Item->{Name}";
	        }
	        else {
	            push @HistoryLines, "\%\%$Field->{Name}\%\%$Data->{$FieldID}";
	        }
	        
	        $ProblemType = $Field->{FieldTreeID};
		}
    }
    
    push @HistoryLines, "\%\%Problem Type\%\%" . $ProblemType;

    # find existing item with same name

	my $Result = {
	 	HistoryLines => \@HistoryLines,
	 	ValueSetID => $id,
        ValueSet => $Data,
	};
 	
    # reset cache
    delete $Self->{Cache}->{ValueSetGet}->{ValueSetID}->{ $Result->{ValueSetID} } if $Self->{Cache}->{ValueSetGet}->{ValueSetID}->{ $Result->{ValueSetID} };
    delete $Self->{Cache}->{ValueSetList} if $Self->{Cache}->{ValueSetList};
    
	return $Result;
}


sub GetFieldsValues {
	my ( $Self, %Param ) = @_;
	
	my $FieldTreeID = $Param{FieldTreeID};
    
   	my $FieldDBTypes = $Self->FieldTypeDBTypes();
   	my $FieldIDList = $Self->FieldList(
        FieldTreeID => $FieldTreeID,
        Valid => 1,
    );
    
	my $Result = { };
    
    for my $FieldID ( keys %{$FieldIDList} ) {
		$Result->{$FieldID} = $Param{ParamObject}->GetParam(Param => $Param{Prefix} . '_Field_' . $FieldID);
    }
	
	return $Result; 
}

=item ValueSetFromPOST()
process POST and do something (update or create)
returns new/old ValueSetID

Return

    my $ValueSetID = $FieldTreeObject->ValueSetUpdate(
        Param => %Param,
    );

=cut

sub ValueSetFromPOST {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( (!$Param{ValueSetID} &&  !$Param{OnlyReturnData})  || !$Param{FieldTreeID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ValueSetID/OnlyReturnData AND FieldTreeID!'.Dumper(\%Param),
        );
        return;
    }

    my $FieldTreeID = $Param{FieldTreeID};
   	my $FieldDBTypes = $Self->FieldTypeDBTypes();
	my $FieldIDList = $Self->FieldList(
               FieldTreeID => $FieldTreeID,
               Valid => 1,
    );
          		
	my $Data = { }; # Populate data from provided param;
	for my $FieldID ( keys %{$FieldIDList} ) {
			
		my $Field = $Self->FieldGet(
        	FieldID => $FieldID,
		);
			
		if ($Field->{FieldType} eq 'DateTime') {
			my @Date =() ;
			for (qw[Year Month Day Hour Minute]) {
				push @Date, $Param{ParamObject}->GetParam( Param => $Param{Prefix}.$FieldID.$_ );
			}
		
    		$Data->{$FieldID} = sprintf("%04d-%02d-%02d %02d:%02d", @Date).":59";
		}
		elsif ($FieldDBTypes->{$Field->{FieldType}} eq 'none') {
		}
		else {
			$Data->{$FieldID} = $Param{ParamObject}->GetParam( Param => $Param{Prefix}.$FieldID );
		}
	}
 
     # save to database
     if ($Param{OnlyReturnData}) {
     	return $Data;
     }
     my $Result;
     if ( $Param{ValueSetID} eq 'NEW' ) {
         $Result = $Self->ValueSetAdd(
             Data => $Data,
         );
     }
     else {
        $Result = $Self->ValueSetUpdate(
    	     Data => $Data,
	         ValueSetID => $Param{ValueSetID},
        );
     }

	return $Result;

}


sub ValueSetValidate {
    my ( $Self, %Param ) = @_;


    my $FieldTreeID = $Param{FieldTreeID};
    my $Error = "";
    if (!$FieldTreeID) {
    	$Error .= 'FieldTree not set';
    }
   	my $FieldDBTypes = $Self->FieldTypeDBTypes();
	my $FieldIDList = $Self->FieldList(
               FieldTreeID => $FieldTreeID,
               Valid => 1,
           );
          		
	my $Data = { }; # Populate data from provided param;
	for my $FieldID ( keys %{$FieldIDList} ) {
			
			my $Field = $Self->FieldGet(
                FieldID => $FieldID,
			);
			
			if ($Field->{Required}) {
                if ($Field->{FieldType} eq 'DateTime') {
                    my $Month = $Self->{ParamObject}->GetParam( Param => $Param{Prefix}.$FieldID.'Month' );
                    my $Day = $Self->{ParamObject}->GetParam( Param => $Param{Prefix}.$FieldID.'Day' );
                    my $Year = $Self->{ParamObject}->GetParam( Param => $Param{Prefix}.$FieldID.'Year' );
                    my %DaysCount = (
                        0 => {1 => 31, 2 => 29, 3 => 31, 4 => 30, 5 => 31, 6 => 30, 7 => 31, 8 => 31, 9 =>30, 10 => 31, 11 => 30, 12 => 31,},
                        1 => {1 => 31, 2 => 28, 3 => 31, 4 => 30, 5 => 31, 6 => 30, 7 => 31, 8 => 31, 9 =>30, 10 => 31, 11 => 30, 12 => 31,},
                        2 => {1 => 31, 2 => 28, 3 => 31, 4 => 30, 5 => 31, 6 => 30, 7 => 31, 8 => 31, 9 =>30, 10 => 31, 11 => 30, 12 => 31,},
                        3 => {1 => 31, 2 => 28, 3 => 31, 4 => 30, 5 => 31, 6 => 30, 7 => 31, 8 => 31, 9 =>30, 10 => 31, 11 => 30, 12 => 31,},                         
                    );                    
                    if ($Day > $DaysCount{$Year % 4}{$Month}) {
                        $Error .= "Field $Field->{Name} has invalid date! ";
                    }
                    
                } else {
                    if ($Self->{ParamObject}->GetParam( Param => $Param{Prefix}.$FieldID ) eq "") {
                        $Error .= "Field $Field->{Name} is required! ";
                    }
                }
			}
	}
 
	return $Error;

}


=item ValueSetUpdate()
update a valueset for a field list

Return

    my $Success = $FieldTreeObject->ValueSetUpdate(
        ValueSetID => 15,
        Data => %ref
    );

=cut
sub ValueSetUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ValueSetID Data)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }
    
    my $Data = $Param{Data};
    my $Result;
   	my $FieldDBTypes = $Self->FieldTypeDBTypes();

    my $ValueSet = $Self->ValueSetGet(
    	ValueSetID => $Param{ValueSetID},
    );
    
    my @HistoryLines;
    my $ProblemType = '';
        
    my $Changed = 0;
    
    foreach  ( sort keys %{$Data}) {
    	if ($ValueSet->{$_} ne $Data->{$_}) {
    		$Changed = 1;
    	}
    }
    foreach  ( sort keys %{$ValueSet}) {
    	if ($ValueSet->{$_} ne $Data->{$_}) {
    		$Changed = 1;
    	}
    }
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
	if ($Changed) {
	   	$DBObject->Do(
			        SQL => 'DELETE FROM field_tree_value WHERE value_set_id = ?',
			        Bind => [
			            \$Param{ValueSetID}
			        ]);
	    foreach my $FieldID ( sort keys %{$Data}) {
			my $Field = $Self->FieldGet(
	            FieldID => $FieldID,
			);
	    	my $FieldDBType = $FieldDBTypes->{$Field->{FieldType}};
	    	if (defined($FieldDBType) && $FieldDBType ne 'none')	{
		    	$DBObject->Do(
			        SQL => 'INSERT INTO field_tree_value (field_id, field_tree_id, '.
			        			' value_set_id, value_'.$FieldDBType.') VALUES (?, ?, ?, ?)',
			        Bind => [
			            \$FieldID, \$Field->{FieldTreeID}, \$Param{ValueSetID}, \$Data->{$FieldID},
			        ]);
			    if (!exists $ValueSet->{$FieldID} || $ValueSet->{$FieldID} ne $Data->{$FieldID}) {
			    	if (($Field->{FieldType} eq "Select") && ($Data->{$FieldID} =~ /^-?\d+$/)) {
		                my $Item = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemGet(
		                    ItemID  => $Data->{$FieldID},
		                );        
		                push @HistoryLines, "\%\%$Field->{Name}\%\%$Item->{Name}";
		            } else {
		                push @HistoryLines, "\%\%$Field->{Name}\%\%$Data->{$FieldID}";
		            }
		            $ProblemType = $Field->{FieldTreeID};         
		       	}
			}
	    }
	    if ($ProblemType) { 
	    	push @HistoryLines, "\%\%Problem Type\%\%" . $ProblemType; 
	    }
	}

	$Result = {
	 	HistoryLines => \@HistoryLines,
	 	ValueSetID =>  $Param{ValueSetID},
        ValueSet => $Data,
	};

    # reset cache
    delete $Self->{Cache}->{ValueSetGet}->{ValueSetID}->{ $Param{ValueSetID} };
    delete $Self->{Cache}->{ValueSetList};
    
	return $Result;
}



=item ValueSetGet()
update a valueset for a field list

Return

    my $ValueSetData = $FieldTreeObject->ValueSetAdd(
        ValueSetID  => 3,
    );

=cut

sub ValueSetGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ValueSetID} )  {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ValueSetID!'
        );
        return;
    }
    
    return if $Param{ValueSetID} =~ /new/i;
    
    if (exists $Self->{Cache}->{ValueSetGet}->{ValueSetID}->{ $Param{ValueSetID} }) {
    	return  $Self->{Cache}->{ValueSetGet}->{ValueSetID}->{ $Param{ValueSetID} };
    }


    # create sql string
    my $SQL = 'SELECT fv.* FROM field_tree_value fv, field_tree_field ff WHERE value_set_id = ? AND fv.field_id = ff.id ORDER BY ff.position DESC';
    my @BIND = ( \$Param{ValueSetID} );

    # ask database
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    $DBObject->Prepare(
        SQL   => $SQL,
        Bind  => \@BIND,
    );

    # fetch the result
    my $Data;
    my $Field;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        my $D = $Row[4] ? $Row[4] : $Row[5] ? $Row[5] : $Row[6] ? $Row[6] : $Row[7] ? $Row[7] : $Row[8] ? $Row[8] : '';
        $Data->{$Row[1]} = $D;
    }

    # cache the result
    $Self->{Cache}->{ValueSetGet}->{ValueSetID}->{ $Param{ValueSetID} } = $Data;

    return $Data;
}

=item ValueSetGetFieldTreeID()
Get FieldTree branch depending to ValueSetID

Return

    my $ValueSetData = $FieldTreeObject->ValueSetGetFieldTreeID(
        ValueSetID  => 3,
    );

=cut

sub ValueSetGetFieldTreeID {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ValueSetID})  {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ValueSetID!'
        );
        return;
    }
    
    if (exists $Self->{Cache}->{ValueSetGetFieldTreeID}->{FieldTree}->{ $Param{ValueSetID} }) {
    	return  $Self->{Cache}->{ValueSetGetFieldTreeID}->{FieldTree}->{ $Param{ValueSetID} };
    }


    # create sql string
    my $SQL = 'SELECT field_tree_id FROM field_tree_value  WHERE value_set_id = ?';
    my @BIND = ( \$Param{ValueSetID} );

    # ask database
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    $DBObject->Prepare(
        SQL   => $SQL,
        Bind  => \@BIND,
        Limit => 1,
    );

    # fetch the result
    my $Data;
    my $Field;
    while ( my @Row = $DBObject->FetchrowArray() ) {
	    $Self->{Cache}->{ValueSetGetFieldTreeID}->{FieldTreeID}->{ $Param{ValueSetID} } = $Row[0];
        $Data = $Row[0];
    }

    # cache the result

    return $Data;
}

=item TreeValueSetAdd()
update a valueset for a field list

Return

    my $ValueSetID = $FieldTreeObject->TreeValueSetAdd(
        Data => %ref
    );

=cut
sub TreeValueSetAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(Data)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }
    
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    $DBObject->Do(SQL => 'INSERT INTO field_tree_value_sets VALUES (DEFAULT)'); #FIXED WAS MISING DEFAULT
    # get inserted ID
    my $id = $DBObject->{dbh}->last_insert_id(undef, undef, 'field_tree_value_sets', undef); #FIXED WAS MISING TABLE NAME
    
    # EPIC FAIL !
    #$DBObject->Prepare(
	#   SQL   => 'SELECT MAX(value_set_id) FROM field_tree_value WHERE 1 ',
	#);
    #my $id;
    #while ( my @Row = $DBObject->FetchrowArray() ) {
    #      $id= $Row[0];
    #}
    #$id++;
    
    my $Data = $Param{Data};
    my $BranchList = $Self->ItemList(
    	Class => $Param{Class},
    );
   	my $FieldDBTypes = $Self->FieldTypeDBTypes();
   	my $HistoryName = '';

	#PROBABLY UNNECESSERY
	#$DBObject->Do(
	#	        SQL => 'INSERT INTO field_tree_value ('.
	#	        			' value_set_id) VALUES (?)',
	#	        Bind => [
	#	            \$id, 
	#	        ]);

    foreach my $FieldTreeID ( sort keys %{$BranchList}) {
    	my $FieldDBType = 'int';
    	if ($Data->{$FieldTreeID}) {
	    	$DBObject->Do(
		        SQL => 'INSERT INTO field_tree_value (field_tree_id, '.
		        			' value_set_id, value_'.$FieldDBType.') VALUES (?, ?, 1)',
		        Bind => [
		            \$FieldTreeID, 
		            \$id, 
		        ]);
		   	$HistoryName .= $FieldTreeID.',';
		}
    }

	my @HistoryLines= ("\%\%Problem Source\%\%$HistoryName");

    # find existing item with same name

	my $Result = {
	 	HistoryLines => \@HistoryLines,
	 	ValueSetID => $id,
	};

    # reset cache
    delete $Self->{Cache}->{ValueSetList};
    
	return $Result;
}


=item TreeValueSetFromPOST()
process POST and do something (update or create)
returns new/old ValueSetID

Return

    my $ValueSetID = $FieldTreeObject->ValueSetUpdate(
        Param => %Param,
    );

=cut

sub TreeValueSetFromPOST {
    my ( $Self, %Param ) = @_;
    # check needed stuff
    for my $Argument (qw(ValueSetID Prefix Class)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "TreeValueSetFromPOST: Need $Argument!",
            );
            return;
        }
    }

	my $ItemList = $Self->ItemList(
               Class => $Param{Class},
               Valid => 1,
           );

	my $Data; # Populate data from provided param;
	my $FieldTreeLoaded = 0;
	for my $ItemID ( sort { $ItemList->{$a} cmp $ItemList->{$b} } keys %{$ItemList} ) {
			$Data->{$ItemID} = $Param{ParamObject}->GetParam( Param => $Param{Prefix}.$ItemID ); #FIXED $Self-> CHANGED TO $Param 
			if (defined $Param{ParamObject}->GetParam( Param => $Param{Prefix}.$ItemID )) { #FIXED $Self-> CHANGED TO $Param 			
				$FieldTreeLoaded = 1;
			}
		}

     # save to database
    my $Result;
    if ($FieldTreeLoaded || $Param{ValueSetID} eq 'NEW' ) { # save /modify only if the tree was loaded
	     if ( $Param{ValueSetID} eq 'NEW' ) {
	         $Result = $Self->TreeValueSetAdd(
	             Data 	=> $Data,
				 Class 	=> $Param{Class}, #FIXED NEEDED CLASS
	         );
	     }
	     else {
	        $Result = $Self->TreeValueSetUpdate(
	          Data => $Data,
	          ValueSetID => $Param{ValueSetID},
	        );
	     }
    }
    else {
    	 $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "TreeValueSetFromPOST: Tree was not loaded!",
            );
    }
	return $Result;
}


=item TreeValueSetUpdate()
update a valueset for a field list

Return

    my $Success = $FieldTreeObject->ValueSetUpdate(
        ValueSetID => 15,
        Data => %ref
    );

=cut
sub TreeValueSetUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ValueSetID Data)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }
    my $CurrentMaxID = $Param{ValueSetID};
    my $Data = $Param{Data};
   	my $FieldDBTypes = $Self->FieldTypeDBTypes();
   	my @HistoryLines= ();
    
   	my $HistoryName = '';

    my $ValueSet = $Self->TreeValueSetGet(
    	ValueSetID => $Param{ValueSetID},
    );
    
    my $Changed = 0;

    
    foreach ( sort keys %{$Data}) {
    	if (($ValueSet->{$_} && !$Data->{$_}) || (!$ValueSet->{$_} && $Data->{$_}) ) {
    		$Changed = 1;
    	}
    }
    foreach ( sort keys %{$ValueSet}) {
    	if (($ValueSet->{$_} && !$Data->{$_}) || (!$ValueSet->{$_} && $Data->{$_}) ) {
    		$Changed = 1;
    	}
    }
    
    

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
	if ($Changed) {
	   	$DBObject->Do(
			        SQL => 'DELETE FROM field_tree_value WHERE value_set_id = ?',
			        Bind => [
			            \$CurrentMaxID, 
			        ]);
	   	$DBObject->Do(
			        SQL => 'INSERT INTO field_tree_value ('.
			        			' value_set_id) VALUES (?)',
			        Bind => [
			            \$CurrentMaxID, 
			        ]);
	
	    foreach my $FieldTreeID ( sort keys %{$Data}) {
	    	my $FieldDBType = 'int';
	    	if ($Data->{$FieldTreeID}) {
		    	$DBObject->Do(
			        SQL => 'INSERT INTO field_tree_value (field_tree_id, '.
			        			' value_set_id, value_'.$FieldDBType.') VALUES (?, ?, 1)',
			        Bind => [
			            \$FieldTreeID, 
			            \$CurrentMaxID, 
			        ]);
			   	$HistoryName .= $FieldTreeID.',';
			}
	    }
		@HistoryLines = ("\%\%Problem Reason\%\%$HistoryName");         
	    delete $Self->{Cache}->{ValueSetGet}->{ValueSetID}->{ $Param{ValueSetID} };
	    delete $Self->{Cache}->{ValueSetList};
	}
		    
	
	my $Result = {
	 	HistoryLines => \@HistoryLines,
	 	ValueSetID => $CurrentMaxID,
	};

    # find existing item with same name


    # reset cache
    
	return $Result;
}

=item ValueSetCopy()
copy data from one valueset to another. This works both with normal valuesets as well as
tree valuesets. If TicketID parameter is provided, history entries are added for each
field in valueset.

Return

    my $Success = $FieldTreeObject->ValueSetCopy(
        SourceValueSetID  => 3,
        TargetValueSetID  => 4,
        TicketID => 3, # optional (useful for ticket containing target valueset)
        UserID => 1,
    );

=cut
sub ValueSetCopy {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(SourceValueSetID TargetValueSetID UserID)) {
        if ( !$Param{$Argument} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    if ( $Param{SourceValueSetID} == $Param{TargetValueSetID} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "ValueSetCopy called with SourceValueSetID==TargetValueSetID. "
                       ."Valueset cannot be copied to itself!",
        );
        return;
    }
	
    # cleanup any existing data in target valueset
	my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    return if !$DBObject->Do(
        SQL => 'DELETE FROM field_tree_value WHERE value_set_id = ?',
        Bind => [ \$Param{TargetValueSetID}, ], 
    );
    # copy values
    return if !$DBObject->Do(
        SQL => 'INSERT INTO field_tree_value (value_set_id, field_id, field_tree_id, '
               .' value_int, value_char, value_text, value_double, value_datetime)' 
               .' SELECT ?, field_id, field_tree_id, value_int, value_char, value_text,'
               .' value_double, value_datetime FROM field_tree_value'
               .' WHERE value_set_id = ?',
        Bind => [ \$Param{TargetValueSetID}, \$Param{SourceValueSetID} ],
    );
    
    if ( $Param{TicketID} ) {
        # despite our super efficient value copying, we still have to generate history lines
        $DBObject->Prepare(
            SQL => 'SELECT ftv.value_int, ftv.value_char, ftv.value_text,'
                   .' ftv.value_double, ftv.value_datetime, ff.field_type, ff.name'
                   .' FROM field_tree_value ftv, field_tree_field ff'
                   .' WHERE ftv.value_set_id = ? AND ftv.field_id=ff.id',
            Bind => [ \$Param{SourceValueSetID} ],
        );
        my @HistoryLines;
        my @Rows;
        while ( my @Row = $Self->{DBObject}->FetchrowArray() ) { #some nice workarounds for stupid OTRS
            push @Rows, \@Row;
        }
        for (@Rows) {
            my @Row = @$_;
            my $Value = $Row[0] || $Row[3] || $Row[4] || $Row[1] || $Row[2] || '';
            my $FieldType = $Row[5];
            my $FieldName = $Row[6];
            if ($FieldType eq "Select" && $Value) {
                my $Item = $Self->{GeneralCatalogObject}->ItemGet(
                    ItemID  => $Value,
                );        
                push @HistoryLines, "\%\%$FieldName\%\%$Item->{Name}";
            } else {
                push @HistoryLines, "\%\%$FieldName\%\%$Value";
            }
        }

        for (@HistoryLines) {
			my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
            $TicketObject->HistoryAdd(
                TicketID     => $Param{TicketID},
                CreateUserID => $Param{UserID},
                HistoryType  => 'ProblemTicketUpdate',
                Name         => $_,
            );
        }
    }

    return 1;
}

=item TreeValueSetData()
update a valueset for a field list

Return

    my $ValueSetData = $FieldTreeObject->ValueSetAdd(
        ValueSetID  => 3,
    );

=cut
# Deprecated or smth
#sub RulesPreProcess {
#    my ( $Self, %Param ) = @_;
#	
#
#    # check needed stuff
#    for my $Argument (qw(TicketData)) {
#        if ( !$Param{$Argument} ) {
#            $Kernel::OM->Get('Kernel::System::Log')->Log(
#                Priority => 'error',
#                Message  => "Need $Argument!",
#            );
#            return;
#        }
#    }
#    my $TicketData = $Param{TicketData};
#    
#    my $Rules = $Self->FieldList(
#    	FieldTreeID => $TicketData->{ProblemTypeID},
#    	Valid => 1,
#    	Class => $Self->{ConfigObject}->Get("FieldTree::ProblemReasonClass"),
#    );
#    
#    foreach my $RuleID ( sort keys %{$Rules}) {
#    	my $Rule = $Self->FieldGet(
#    		FieldID =>$RuleID
#    	);
#        # Although we set QueueID throgh JavaScript (for AKSProblemTicketProblem view),
#        # this might also be used from cron script for processing webcare tickets,
#        # so we make sure that we always set correct QueueID here too    	
#    	if ($Rule->{FieldType} eq "RuleEscalateTo") {
#    		$TicketData->{QueueID} = $Rule->{Template};
#    	}
#    	elsif ($Rule->{FieldType} eq "RuleSLA") {
#    		$TicketData->{SLAID} = $Rule->{Template};
#    	}
#    }
#    
#    
#    return $TicketData;
#    
#}	

sub RulesPostProcess {
    my ( $Self, %Param ) = @_;
	
    # check needed stuff
    for my $Argument (qw(TicketID UserID ValueSetID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }
    my $Rules;
    $Rules = $Self->FieldList(
    	FieldTreeID => $Self->ValueSetGetFieldTreeID( ValueSetID => $Param{ValueSetID} ),
    	Valid => 1,
    );
	my $ValueSet = $Self->ValueSetGet(
		ValueSetID => $Param{ValueSetID},
	);
    
    foreach my $RuleID ( sort keys %{$Rules} ) {
    	my $Rule = $Self->FieldGet(
    		FieldID => $RuleID
    	);
    	
    	#implement any rules here
    	if ($Rule->{FieldType} eq 'SomeRule') {
        }
    }
    
    return 1;    
}	

sub TreeValueSetGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ValueSetID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ValueSetID!'.$Param{ValueSetID}
        );
        return;
    }
    
    if (exists $Self->{Cache}->{ValueSetGet}->{ValueSetID}->{ $Param{ValueSetID} }) {
    	return  $Self->{Cache}->{ValueSetGet}->{ValueSetID}->{ $Param{ValueSetID} };
    }

    # create sql string
    my $SQL = 'SELECT * FROM field_tree_value WHERE value_set_id = ? and field_tree_id IS NOT NULL';
    my @BIND = ( \$Param{ValueSetID} );

    # ask database
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    $DBObject->Prepare(
        SQL   => $SQL,
        Bind  => \@BIND,
        Limit => 100_000_000,
    );

    # fetch the result
    my $Data;
    my $Field;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        my $D = $Row[4] ? $Row[4] : $Row[5] ? $Row[5] : $Row[6] ? $Row[6] : $Row[7] ? $Row[7] : '';
        $Data->{$Row[2]} = $D;
    }

    # cache the result
    $Self->{Cache}->{ValueSetGet}->{ValueSetID}->{ $Param{ValueSetID} } = $Data;

    return $Data;
}


sub OpenedItemsList {
    my ( $Self, %Param ) = @_;
   # check needed stuff
    for my $Argument (qw(ValueSetID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }
   # create sql string
    my $SQL = 'SELECT DISTINCT field_tree_id FROM field_tree_value WHERE value_set_id = ?';
    my @BIND = ( \$Param{ValueSetID} );

    # ask database
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    $DBObject->Prepare(
        SQL   => $SQL,
        Bind  => \@BIND,
        Limit => 100_000_000,
    );

    my @Data;
    my $DataHref;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        my $ID = $Row[0];
        if ($ID) {
	        my @parents = @{$Self->ItemParentsList(
	        	ItemID => $ID,
	        )};
	        push (@Data, @parents);
	    }
    }

	for my $CycleID ( @Data ) {
		$DataHref->{$CycleID} = 1;
	}
	
	return $DataHref;
}

sub TreeOpenedItemsList {
    my ( $Self, %Param ) = @_;
 
   # check needed stuff
    for my $Argument (qw(ValueSetID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }
   # create sql string
    my $SQL = 'SELECT DISTINCT field_tree_id FROM field_tree_value WHERE value_set_id = ? AND value_int = 1';
    my @BIND = ( \$Param{ValueSetID} );

    # ask database
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
    $DBObject->Prepare(
        SQL   => $SQL,
        Bind  => \@BIND,
        Limit => 100_000_000,
    );

    my @Data;
    my $DataHref;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        my $ID = $Row[0];
        my @parents = @{$Self->ItemParentsList(
        	ItemID => $ID,
        )};
        push (@Data, @parents);
    }

	for my $CycleID ( @Data ) {
		$DataHref->{$CycleID} = 1;
	}
	
	return $DataHref;
}

sub ItemParentsList {
    my ( $Self, %Param ) = @_;
	my @dat = ();
   # check needed stuff
    for my $Argument (qw(ItemID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }
    my $ItemID = $Param{ItemID};
	my $Item = $Self->ItemGet(
		ItemID => $ItemID,
	);
	if ($Item->{ParentID} > 0) {
	    @dat = @{$Self->ItemParentsList(
	    	ItemID => $Item->{ParentID},
	    )};
	}
   
 	push @dat, $ItemID;
 	return \@dat;
}

# Mixin for functions which require Class and ItemID
# If only ItemID is provided, Class is item's class
# If only Class is provided, ItemID is id of the first item in the first level (parentID = -1)
# Usage (after other parameter checks):
# $Self->_ClassOrItemIDMixin (
#   Param => \%Param
# )
sub _ClassOrItemIDMixin {
    my ( $Self, %Params ) = @_;
    my $Param = $Params{Param};

	my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    if (!$Param->{Class} && !$Param->{ItemID}) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Need Class or ItemID!",
        );
        return;
    }
    if (!$Param->{Class}) {
        my $Item = $Self->ItemGet(
            ItemID => $Param->{ItemID},
        );
        if (!$Item) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Fieldtree item (id=$Param->{ItemID}) not found!",
            );
            return;
        }
        $Param->{Class} = $Item->{Class};
    }
    elsif (!$Param->{ItemID}) {
        my $FirstLvlItems = $Self->ItemList(
            Class    => $Param->{Class},
            ParentID => -1,
        );
        my @FirstLvl = keys(%$FirstLvlItems);
        if (!scalar(@FirstLvl)) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "No Fieldtree items in first level with class='$Param->{Class}'",
            );
            return;
        }
        $Param->{ItemID} = $FirstLvl[0];
    }
}

# exports one Tree (Fieldtree item and it's children) as a sorted array of hashrefs
# which can be used for outputing JSON 
# Class - Fieldtree class (optional: if Class is not provided, Class of ItemID is used)
# ItemID - Fieldtree item ID (optional: if ItemID is not provided, first child of Class is used)
# ValueSetID - Fieldtree valueset
sub JSON {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ValueSetID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }
    
    $Self->_ClassOrItemIDMixin( Param => \%Param );
    
    my $OpenedItems = {};

    if (defined($Param{OpenedItems})) {
    	$OpenedItems = $Param{OpenedItems};
    }
    elsif (defined($Param{ValueSetID}) && $Param{ValueSetID} ne "NEW") {
    	$OpenedItems = $Self->OpenedItemsList(
    		ValueSetID => $Param{ValueSetID},
    	);
    	if ($Param{FieldTreeID}){
    		for (@{$Self->ItemParentsList( ItemID => $Param{FieldTreeID})}) {
		    	$OpenedItems->{$_} = 1;
		    }
    	}
    }

	my $ItemsOn = $Self->_JSONInternal(	%Param );
	$Self->_TreeWalker(
		Items => $ItemsOn,
		OpenedItems => $OpenedItems,
		ShowAllCheckboxes => $Param{ShowAllCheckboxes},			
	);
	
	return  @$ItemsOn;
}


# Function to generate JSON output for chechbox-only tree
# Class - Fieldtree class (optional: if Class is not provided, Class of ItemID is used)
# ItemID - Fieldtree item ID (optional: if ItemID is not provided, first child of Class is used)
# ValueSetID or ValueSet - Fieldtree valueset id or valueset hashref
sub TreeJSON {
    my ( $Self, %Param ) = @_;

   # check needed stuff
    $Self->_ClassOrItemIDMixin( Param => \%Param );

	my $ValueSet;
    if (defined($Param{ValueSet})) {
    	$ValueSet = $Param{ValueSet};
    }
    if (defined($Param{ValueSetID})) {

   		
   		$ValueSet = $Self->TreeValueSetGet(
   			ValueSetID => $Param{ValueSetID}
   		);

    }
    
    my $OpenedItems;
    if (defined($Param{OpenedItems})) {
    	$OpenedItems = $Param{OpenedItems};
    }
    else {
    	$OpenedItems = $Self->TreeOpenedItemsList(
    		ValueSetID => $Param{ValueSetID},
    	);
    }

	my $ItemsOn = $Self->_JSONInternal(	%Param );
	$Self->_TreeWalker(
		Items => $ItemsOn,
		OpenedItems => $OpenedItems,
		ValueSet => $ValueSet, 
		ShowAllCheckboxes => 0,			
	);
	
	return @$ItemsOn;
}

# Generated html <select> tag for provided 'checkbox-only' fieldtree
# Class - Fieldtree class (optional: if Class is not provided, Class of ItemID is used)
# ItemID - Fieldtree item ID (optional: if ItemID is not provided, first child of Class is used)
# ValueSetID or ValueSet - Fieldtree valueset id or valueset hashref
sub TreeAsSelection {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(Name)) {
        if ( !$Param{$Argument} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }
    $Self->_ClassOrItemIDMixin( Param => \%Param );

    my $ValueSet;
    if (defined($Param{ValueSet})) {
    	$ValueSet = $Param{ValueSet};
    }
    if (defined($Param{ValueSetID})) {
   		$ValueSet = $Self->TreeValueSetGet(
   			ValueSetID => $Param{ValueSetID}
   		);
    }
    # figure out selected value (can be only one)
    for (keys %$ValueSet) {
        if ($ValueSet->{$_}) {
            $Param{SelectedValue} = $_;
            last;
        }
    }

    my $Items = $Self->_JSONInternal( %Param );
    my $AttrRef = { # select attributes (semi-hardcoded for now) 
        name => $Param{Name},
        id   => $Param{Name},
    };
    my $Output = '<select ';
    for (keys %$AttrRef) {
        $Output .= $_.'="'.$AttrRef->{$_}.'" ';
    }
    $Output .= ">\n";
    $Output .= '<option value="">--</option>'."\n";
    $Output .= $Self->_BuildOptionTree( 
        Items         => $Items,
        SelectedValue => $Param{SelectedValue} || 0,
    );
    $Output .= "</select>\n";
    return $Output;
}

sub _BuildOptionTree {
    my ( $Self, %Param ) = @_;
    
    my $Output = '';
    $Param{Indent} = $Param{Indent} || '&nbsp;&nbsp;&nbsp;&nbsp;';
    $Param{Level} = $Param{Level} || 0;
    $Param{SelectedValue} = $Param{SelectedValue} || 0;
    for ( @{$Param{Items}} ) {
        my $Label = $Param{Indent} x $Param{Level}.$_->{txt};
        if ( $_->{canhavechildren} ) {
            $Output .= '<optgroup label="'.$Label.'">';
            $Output .= "</optgroup>\n";
            $Output .= $Self->_BuildOptionTree(
                Indent => $Param{Indent},
                Level => $Param{Level}+1,
                Items => $_->{items},
                SelectedValue => $Param{SelectedValue},
            );
        }
        else {
            my $Selected = $Param{SelectedValue} == $_->{id} ? 'selected' : '';
            $Output .= '<option value="'.$_->{id}.'" '.$Selected.'>'.$Label."</option>\n";
        }
    }
    return $Output;
}

# Recursive tree walker, that walks through cached recursive array of hashes
sub _TreeWalker {
    my ( $Self, %Param ) = @_;
	foreach (@{$Param{Items}}) {
		$_->{open} = $Param{OpenedItems}->{$_->{id}} ? "true" : "";
		$_->{checkbox} = (($_->{canhavechildren}) && !$Param{ShowAllCheckboxes})  ? "" : "true";
		if ($Param{ValueSet}) {
   			$_->{check} = $Param{ValueSet}->{$_->{id}} ? "1" : "0";
		}
		$Self->_TreeWalker(
			Items => $_->{items},
			ValueSet => $Param{ValueSet},
			OpenedItems => $Param{OpenedItems},
			ShowAllCheckboxes => $Param{ShowAllCheckboxes},			
		);
	}
}


# Internal fuction  to retrieve recursive tree with caching abilities
sub _JSONInternal { 
    my ( $Self, %Param ) = @_;

    # check needed stuff
	my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    for my $Argument (qw(Class ItemID)) {
            if ( !$Param{$Argument} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }
    $Param{UseHash} = $Param{UseHash} || 0; # output hash (ItemID as keys) instead of array
    $Param{UseFriendlyName} = $Param{UseFriendlyName} || 0; # get friendly names instead of simple ones

  	my $Result;
    my $CacheKey = "JSON_$Param{ItemID}_$Param{Class}_$Param{UseHash}";
    if ($Self->{CacheObject}  && !defined($Param{DoNotCache})) {
    	$Result = $Self->{CacheObject}->Get(
    		Type => 'FieldTree',
			Key  => $CacheKey,
    	);
        return $Result if $Result;
    }
    $Result = $Param{UseHash} ? {} : [];

    my $ItemID = $Param{ItemID};
    my $Class = $Param{Class};

    my $ItemIDList  = $Self->ItemList(
        Valid => 1,
        Class => $Class,
        ParentID => $ItemID,
        UseFriendlyName => $Param{UseFriendlyName},
    );
    
    my @Iterator = keys %{$ItemIDList};
    if ( !$Param{UseHash} ) {
        @Iterator = sort { $ItemIDList->{$a} cmp $ItemIDList->{$b} } @Iterator;
    };
    for my $CycleID ( @Iterator ) {
            
        my $Children = $Self->_JSONInternal(
            ItemID => $CycleID,
            Class => $Class,
            UseHash => $Param{UseHash},
            UseFriendlyName => $Param{UseFriendlyName},
            DoNotCache => 1, #Do not cache lower hierarchy
        );
        my $ChildrenCount = scalar( $Param{UseHash} ? keys(%$Children) : @$Children );
        my $Item = {
            txt =>	$ItemIDList->{$CycleID},
            id => $CycleID,
            canhavechildren => $ChildrenCount ? "true" : "",
            items => $Children,
            acceptdrop => "false",
        };
        if ( $Param{UseHash} ) {
            $Result->{$CycleID} = $Item;
        }
        else {
            push @$Result, $Item;
        }
    }

    if ($Self->{CacheObject} && !defined($Param{DoNotCache})) {
        $Self->{CacheObject}->Set(
            Type  => 'FieldTree',
            Key   => $CacheKey,
            Value => $Result,    		
        );
    }
    
    return $Result;
}
    



sub FieldTypes {
    my $Self = shift;
    

    my %FieldTypes = (
        Information => 'Information field',
        Text => 'Text field',
        Phone => 'Phone field',
        Money => 'Money field',
        Integer => 'Integer field',
        Double => 'Double field',
        Boolean => 'Boolean',
        MultiText => 'Multi text field',
        Select => 'Select from options',
        DateTime => 'Date and time',
        EMail => 'E-mail',
#        UserInfoFetcher => 'User info fetcher',
#        RuleEscalateTo => 'Rule - escalate to',
#        RuleSLA  => 'Rule - set SLA',
        RuleRedmineProjectID => 'Rule - set Redmine Project ID',
    );
    return \%FieldTypes;
}

sub FieldTypeDBTypes {
    my $Self = shift;

    my %FieldTypes = (
        Information => 'none',
        Text => 'char',
        Phone => 'char',
        Money => 'char',
        Integer => 'int',
        Double => 'double',
        Boolean => 'int',
        MultiText => 'text',
        DateTime => 'datetime',
        EMail => 'text',
        Select => 'text',
 #       RuleEscalateTo => 'none',
 #       RuleSLA  => 'none',
        RuleRedmineProjectID => 'int',
    );
    return \%FieldTypes;
}

sub ChildItemList {

   my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ItemID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }
    
    
    my $ItemID = $Param{ItemID};
    my @IDs = ($ItemID);
    my $ChildIDs;
    
    my $Childs = $Self->ItemList(
    	ParentID => $ItemID,
    );

    foreach my $ChildID ( sort keys %{$Childs}) {
    	$ChildIDs = $Self->ChildItemList(
			ItemID => $ChildID,
		);
		push (@IDs, @{$ChildIDs});
	}
	return \@IDs;
}

1; 
